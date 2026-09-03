import '../constants/agent_action_ids.dart';
import '../models/agent_action_definition.dart';
import '../models/agent_master_settings.dart';
import '../models/agent_read_only_payload.dart';
import '../models/agent_role.dart';
import '../models/agent_tool_request.dart';
import '../models/agent_voice_super_admin_authorization.dart';
import '../models/agent_voice_super_admin_foundation.dart';
import '../models/agent_voice_super_admin_source_acquisition_request.dart';
import '../models/agent_voice_super_admin_source_readiness.dart';
import '../models/agent_voice_super_admin_verified_section.dart';
import 'agent_action_registry.dart';
import 'agent_read_only_connector.dart';
import 'agent_read_only_connector_registry.dart';
import 'agent_read_only_sanitizer.dart';
import 'agent_voice_super_admin_authorization_broker.dart';

/// Phase 48 authorized read-source bridge.
///
/// SECURITY ORDER:
/// 1. Re-run the dedicated Voice Super Admin authorization broker.
/// 2. Require REGISTRY_READY source readiness.
/// 3. Map only a small allowlisted Voice read kind to an EXISTING read-only
///    connector action.
/// 4. Fetch that connector only through AgentReadOnlyConnectorRegistry.
/// 5. Pass exact ID-only scope required by the connector.
/// 6. Validate returned action/module binding.
/// 7. Sanitize payload.
/// 8. Convert to AgentVoiceSuperAdminVerifiedSection.
///
/// IMPORTANT:
/// - Voice role is never granted Ride/Driver/Food/etc Permission Engine actions.
/// - AgentReadOnlyExecutor is intentionally NOT used with the Voice role,
///   because its module isolation would correctly deny foreign-module actions.
/// - A successful Voice authorization allows only this narrow registered-source
///   acquisition path; it never allows a business/admin write.
class AgentVoiceSuperAdminAuthorizedSourceAcquisition {
  AgentVoiceSuperAdminAuthorizedSourceAcquisition({
    required this.authorizationBroker,
    AgentReadOnlyConnectorRegistry? connectorRegistry,
    AgentReadOnlySanitizer? sanitizer,
  }) : connectorRegistry =
           connectorRegistry ?? AgentReadOnlyConnectorRegistry(),
       sanitizer = sanitizer ?? const AgentReadOnlySanitizer();

  final AgentVoiceSuperAdminAuthorizationBroker authorizationBroker;
  final AgentReadOnlyConnectorRegistry connectorRegistry;
  final AgentReadOnlySanitizer sanitizer;

  Future<AgentVoiceSuperAdminVerifiedSection> acquire({
    required AgentMasterSettings settings,
    required AgentRole role,
    required AgentVoiceSuperAdminSessionBinding session,
    required AgentVoiceSuperAdminAuthorizationRequest authorizationRequest,
    required AgentVoiceSuperAdminSourceAcquisitionRequest sourceRequest,
    required DateTime now,
  }) async {
    final AgentVoiceSuperAdminAuthorizationResult authorization =
        await authorizationBroker.evaluate(
          settings: settings,
          role: role,
          session: session,
          request: authorizationRequest,
          now: now,
        );

    if (!authorization.mayAcquireVerifiedSections) {
      return _unavailable(
        sourceRequest: sourceRequest,
        now: now,
        sourceId: 'voice_super_admin.authorization',
        reason:
            'Voice Super Admin authorization did not permit verified source acquisition.',
      );
    }

    if (role.roleId != AgentVoiceSuperAdminFoundation.roleId ||
        role.module != AgentVoiceSuperAdminFoundation.module) {
      return _unavailable(
        sourceRequest: sourceRequest,
        now: now,
        sourceId: 'voice_super_admin.role',
        reason:
            'Only the isolated Voice Super Admin role may acquire Voice report sources.',
      );
    }

    if (!sourceRequest.hasStructurallyValidModuleAndKind ||
        !sourceRequest.referenceIdWithinLimit) {
      return _unavailable(
        sourceRequest: sourceRequest,
        now: now,
        sourceId: 'voice_super_admin.request',
        reason: 'Voice Super Admin source request is invalid or out of scope.',
      );
    }

    final AgentVoiceSuperAdminSourceReadiness readiness =
        AgentVoiceSuperAdminInitialSourceReadiness.forModule(
          sourceRequest.moduleId,
        );

    if (!readiness.mayExecuteThroughExistingReadPath) {
      return _unavailable(
        sourceRequest: sourceRequest,
        now: now,
        sourceId: 'voice_super_admin.readiness',
        reason:
            'Verified source is not connected to an approved active read-only registry path.',
      );
    }

    final _AgentVoiceSuperAdminConnectorPlan? plan = _plan(sourceRequest);

    if (plan == null) {
      return _unavailable(
        sourceRequest: sourceRequest,
        now: now,
        sourceId: 'voice_super_admin.plan',
        reason:
            'Requested Voice Super Admin source/read kind is not connected.',
      );
    }

    final String referenceId = sourceRequest.referenceId.trim();

    if (plan.scopeKey != null && referenceId.isEmpty) {
      return _unavailable(
        sourceRequest: sourceRequest,
        now: now,
        sourceId: 'voice_super_admin.scope',
        reason:
            'Exact existing identifier required by the verified connector was not supplied.',
      );
    }

    if (plan.scopeKey == null && referenceId.isNotEmpty) {
      return _unavailable(
        sourceRequest: sourceRequest,
        now: now,
        sourceId: 'voice_super_admin.scope',
        reason:
            'This verified Core/System source does not accept a business reference identifier.',
      );
    }

    final AgentActionDefinition? targetAction = AgentActionRegistry.get(
      plan.actionId,
    );

    if (targetAction == null ||
        !targetAction.readOnly ||
        targetAction.alwaysRequiresApproval ||
        targetAction.module != plan.module) {
      return _unavailable(
        sourceRequest: sourceRequest,
        now: now,
        sourceId: 'voice_super_admin.action_registry',
        reason:
            'Target connector action is not an approved pure read-only action.',
      );
    }

    final AgentReadOnlyConnector? connector = connectorRegistry.connectorFor(
      module: targetAction.module,
      actionId: targetAction.actionId,
    );

    if (connector == null) {
      return _unavailable(
        sourceRequest: sourceRequest,
        now: now,
        sourceId: 'voice_super_admin.registry',
        reason: 'Approved registered read-only connector is unavailable.',
      );
    }

    final Map<String, dynamic> scope = plan.scopeKey == null
        ? <String, dynamic>{}
        : <String, dynamic>{plan.scopeKey!: referenceId};

    final AgentToolRequest connectorRequest = AgentToolRequest(
      requestId:
          'voice_super_admin_verified_${now.microsecondsSinceEpoch}_${sourceRequest.moduleId.toLowerCase()}',
      roleId: role.roleId,
      actionId: targetAction.actionId,
      toolId: 'tool.${targetAction.actionId}',
      requestedBy: authorizationRequest.actorId.trim(),
      actionScope: scope,
      createdAt: now,
    );

    try {
      connectorRequest.validate();

      final AgentReadOnlyPayload payload = await connector.executeReadOnly(
        connectorRequest,
      );

      if (payload.actionId != targetAction.actionId ||
          payload.module != targetAction.module) {
        return _unavailable(
          sourceRequest: sourceRequest,
          now: now,
          sourceId: connector.connectorId,
          reason:
              'Registered connector returned a payload outside its approved action/module scope.',
        );
      }

      final Map<String, dynamic> safeData = sanitizer.sanitizeMap(payload.data);

      final AgentVoiceSuperAdminVerifiedSection
      section = AgentVoiceSuperAdminVerifiedSection.verified(
        moduleId: sourceRequest.moduleId,
        sourceId: connector.connectorId,
        summaryText:
            'Verified sanitized ${sourceRequest.moduleId} source data acquired successfully.',
        facts: Map<String, Object?>.from(safeData),
        verifiedAt: payload.generatedAt,
      );

      section.validate();
      return section;
    } catch (_) {
      return _unavailable(
        sourceRequest: sourceRequest,
        now: now,
        sourceId: connector.connectorId,
        reason: 'Verified registered read-only connector failed safely.',
      );
    }
  }

  _AgentVoiceSuperAdminConnectorPlan? _plan(
    AgentVoiceSuperAdminSourceAcquisitionRequest request,
  ) {
    switch (request.moduleId) {
      case 'NORMAL_RIDE':
        if (request.readKind == AgentVoiceSuperAdminSourceReadKind.status) {
          return const _AgentVoiceSuperAdminConnectorPlan(
            module: 'ride',
            actionId: AgentActionId.readRideStatus,
            scopeKey: 'rideId',
          );
        }

        if (request.readKind == AgentVoiceSuperAdminSourceReadKind.details) {
          return const _AgentVoiceSuperAdminConnectorPlan(
            module: 'ride',
            actionId: AgentActionId.readRide,
            scopeKey: 'rideId',
          );
        }

        return null;

      case 'DRIVER':
        if (request.readKind == AgentVoiceSuperAdminSourceReadKind.status) {
          return const _AgentVoiceSuperAdminConnectorPlan(
            module: 'driver',
            actionId: AgentActionId.readDriverStatus,
            scopeKey: 'driverId',
          );
        }

        if (request.readKind == AgentVoiceSuperAdminSourceReadKind.details) {
          return const _AgentVoiceSuperAdminConnectorPlan(
            module: 'driver',
            actionId: AgentActionId.readDriver,
            scopeKey: 'driverId',
          );
        }

        return null;

      case 'FOOD':
        if (request.readKind == AgentVoiceSuperAdminSourceReadKind.status ||
            request.readKind == AgentVoiceSuperAdminSourceReadKind.details) {
          return const _AgentVoiceSuperAdminConnectorPlan(
            module: 'food',
            actionId: AgentActionId.readFoodOrder,
            scopeKey: 'orderId',
          );
        }

        return null;

      case 'RESTAURANT':
        if (request.readKind == AgentVoiceSuperAdminSourceReadKind.status ||
            request.readKind == AgentVoiceSuperAdminSourceReadKind.details) {
          return const _AgentVoiceSuperAdminConnectorPlan(
            module: 'restaurant',
            actionId: AgentActionId.readRestaurant,
            scopeKey: 'restaurantId',
          );
        }

        return null;

      case 'SYSTEM_HEALTH':
        if (request.readKind == AgentVoiceSuperAdminSourceReadKind.status ||
            request.readKind == AgentVoiceSuperAdminSourceReadKind.details) {
          return const _AgentVoiceSuperAdminConnectorPlan(
            module: 'core',
            actionId: AgentActionId.readSystemHealth,
            scopeKey: null,
          );
        }

        if (request.readKind ==
            AgentVoiceSuperAdminSourceReadKind.dailySummary) {
          return const _AgentVoiceSuperAdminConnectorPlan(
            module: 'core',
            actionId: AgentActionId.readDailySummary,
            scopeKey: null,
          );
        }

        return null;

      default:
        return null;
    }
  }

  AgentVoiceSuperAdminVerifiedSection _unavailable({
    required AgentVoiceSuperAdminSourceAcquisitionRequest sourceRequest,
    required DateTime now,
    required String sourceId,
    required String reason,
  }) {
    return AgentVoiceSuperAdminVerifiedSection.unavailable(
      moduleId: sourceRequest.moduleId.trim().isEmpty
          ? 'UNKNOWN'
          : sourceRequest.moduleId.trim(),
      sourceId: sourceId,
      reason: reason,
      verifiedAt: now,
    );
  }

  bool get usesDedicatedVoiceAuthorizationBroker => true;
  bool get usesCentralConnectorRegistry => true;
  bool get usesExistingReadOnlySanitizer => true;
  bool get preservesPermissionModuleIsolation => true;
  bool get usesReadOnlyExecutorWithVoiceRole => false;

  bool get grantsPermission => false;
  bool get createsApproval => false;
  bool get consumesApproval => false;
  bool get directFirestoreAllowed => false;
  bool get businessWriteAllowed => false;
  bool get safetyMutationAllowed => false;
  bool get providerNetworkAllowed => false;
  bool get speechTransportAllowed => false;
  bool get deployAllowed => false;
}

class _AgentVoiceSuperAdminConnectorPlan {
  const _AgentVoiceSuperAdminConnectorPlan({
    required this.module,
    required this.actionId,
    required this.scopeKey,
  });

  final String module;
  final String actionId;
  final String? scopeKey;
}
