import '../constants/agent_action_ids.dart';
import '../constants/agent_customer_whatsapp_constants.dart';
import '../models/agent_action_definition.dart';
import '../models/agent_customer_whatsapp_verified_read.dart';
import '../models/agent_master_settings.dart';
import '../models/agent_permission_decision.dart';
import '../models/agent_read_only_payload.dart';
import '../models/agent_role.dart';
import '../models/agent_tool_request.dart';
import 'agent_action_registry.dart';
import 'agent_permission_engine.dart';
import 'agent_read_only_connector.dart';
import 'agent_read_only_connector_registry.dart';
import 'agent_read_only_sanitizer.dart';
import 'agent_runtime_gate.dart';

/// Phase 45 narrow verified-read broker.
///
/// SECURITY MODEL:
/// 1. Customer WhatsApp Agent is authorized ONLY for its own
///    `customer_whatsapp.read_verified_data` action.
/// 2. Permission Engine module isolation is NOT weakened.
/// 3. This broker maps a small allowlisted WhatsApp read kind to an
///    EXISTING read-only business connector.
/// 4. Target action must exist and be readOnly.
/// 5. Target connector must already be registered in the central
///    AgentReadOnlyConnectorRegistry.
/// 6. Exact ID-only scope is passed to the connector.
/// 7. Payload is sanitized again before it can become WhatsApp reply data.
/// 8. No business write, provider network call, or direct Firestore primitive
///    exists here.
class AgentCustomerWhatsAppExistingConnectorSource
    implements AgentCustomerWhatsAppVerifiedReadSource {
  AgentCustomerWhatsAppExistingConnectorSource({
    required this.service,
    required this.settings,
    required this.role,
    required this.requestedBy,
    AgentPermissionEngine? permissionEngine,
    AgentRuntimeGate? runtimeGate,
    AgentReadOnlyConnectorRegistry? connectorRegistry,
    AgentReadOnlySanitizer? sanitizer,
  }) : permissionEngine = permissionEngine ?? const AgentPermissionEngine(),
       runtimeGate = runtimeGate ?? const AgentRuntimeGate(),
       connectorRegistry =
           connectorRegistry ?? AgentReadOnlyConnectorRegistry(),
       sanitizer = sanitizer ?? const AgentReadOnlySanitizer();

  final String service;
  final AgentMasterSettings settings;
  final AgentRole role;
  final String requestedBy;
  final AgentPermissionEngine permissionEngine;
  final AgentRuntimeGate runtimeGate;
  final AgentReadOnlyConnectorRegistry connectorRegistry;
  final AgentReadOnlySanitizer sanitizer;

  bool get usesCentralConnectorRegistry => true;
  bool get preservesPermissionModuleIsolation => true;
  bool get directFirestoreAllowed => false;
  bool get businessWriteAllowed => false;
  bool get providerNetworkAllowed => false;
  bool get ownerAuthorityAllowed => false;
  bool get emergencyAuthorityAllowed => false;

  @override
  Future<AgentCustomerWhatsAppVerifiedReadResult> readVerified(
    AgentCustomerWhatsAppVerifiedReadRequest request,
  ) async {
    request.validate();

    if (request.service != service) {
      return AgentCustomerWhatsAppVerifiedReadResult.denied(
        'WHATSAPP_SOURCE_SERVICE_MISMATCH',
        requiresHumanEscalation: true,
      );
    }

    if (role.roleId != 'customer_whatsapp_agent' ||
        role.module != 'customer_whatsapp') {
      return AgentCustomerWhatsAppVerifiedReadResult.denied(
        'WHATSAPP_ROLE_MISMATCH',
        requiresHumanEscalation: true,
      );
    }

    // Authorize the CUSTOMER WHATSAPP action, not a foreign module action.
    final AgentPermissionDecision permission = permissionEngine.evaluate(
      role: role,
      actionId: AgentActionId.readCustomerWhatsAppVerifiedData,
    );

    final AgentPermissionDecision gated = runtimeGate.apply(
      settings: settings,
      role: role,
      permissionDecision: permission,
    );

    if (gated.isDenied) {
      return AgentCustomerWhatsAppVerifiedReadResult.denied(
        'WHATSAPP_RUNTIME_DENIED',
        requiresHumanEscalation: true,
      );
    }

    if (gated.needsApproval) {
      return AgentCustomerWhatsAppVerifiedReadResult.denied(
        'WHATSAPP_READ_APPROVAL_REQUIRED',
        requiresHumanEscalation: true,
      );
    }

    final _AgentCustomerWhatsAppConnectorPlan? plan = _plan(request);

    if (plan == null) {
      return AgentCustomerWhatsAppVerifiedReadResult.denied(
        'VERIFIED_READ_KIND_NOT_CONNECTED',
        requiresHumanEscalation: true,
      );
    }

    final String referenceId = request.referenceId.trim();

    if (referenceId.isEmpty || referenceId.length > 200) {
      return AgentCustomerWhatsAppVerifiedReadResult.denied(
        'VALID_REFERENCE_ID_REQUIRED',
        requiresHumanEscalation: true,
      );
    }

    final AgentActionDefinition? targetAction = AgentActionRegistry.get(
      plan.actionId,
    );

    if (targetAction == null || !targetAction.readOnly) {
      return AgentCustomerWhatsAppVerifiedReadResult.denied(
        'TARGET_ACTION_NOT_READ_ONLY',
        requiresHumanEscalation: true,
      );
    }

    if (targetAction.module != plan.module) {
      return AgentCustomerWhatsAppVerifiedReadResult.denied(
        'TARGET_ACTION_MODULE_MISMATCH',
        requiresHumanEscalation: true,
      );
    }

    final AgentReadOnlyConnector? connector = connectorRegistry.connectorFor(
      module: targetAction.module,
      actionId: targetAction.actionId,
    );

    if (connector == null) {
      return AgentCustomerWhatsAppVerifiedReadResult.denied(
        'VERIFIED_BACKEND_CONNECTOR_UNAVAILABLE',
        requiresHumanEscalation: true,
      );
    }

    final AgentToolRequest connectorRequest = AgentToolRequest(
      requestId:
          'customer_whatsapp_verified_${DateTime.now().microsecondsSinceEpoch}',
      roleId: role.roleId,
      actionId: targetAction.actionId,
      toolId: 'tool.${targetAction.actionId}',
      requestedBy: requestedBy.trim().isEmpty
          ? 'customer_whatsapp_agent'
          : requestedBy.trim(),
      actionScope: <String, dynamic>{plan.scopeKey: referenceId},
      createdAt: DateTime.now(),
    );

    try {
      final AgentReadOnlyPayload payload = await connector.executeReadOnly(
        connectorRequest,
      );

      if (payload.actionId != targetAction.actionId ||
          payload.module != targetAction.module) {
        return AgentCustomerWhatsAppVerifiedReadResult.denied(
          'CONNECTOR_PAYLOAD_SCOPE_MISMATCH',
          requiresHumanEscalation: true,
        );
      }

      final Map<String, dynamic> safeData = sanitizer.sanitizeMap(payload.data);

      return AgentCustomerWhatsAppVerifiedReadResult(
        ok: true,
        backendVerified: true,
        code: 'VERIFIED_EXISTING_SWAT_RIDE_CONNECTOR',
        safeData: safeData,
      );
    } catch (_) {
      return AgentCustomerWhatsAppVerifiedReadResult.denied(
        'VERIFIED_BACKEND_CONNECTOR_FAILED',
        requiresHumanEscalation: true,
      );
    }
  }

  _AgentCustomerWhatsAppConnectorPlan? _plan(
    AgentCustomerWhatsAppVerifiedReadRequest request,
  ) {
    switch (request.service) {
      case AgentCustomerWhatsAppService.ride:
        if (request.kind == AgentCustomerWhatsAppReadKind.bookingStatus ||
            request.kind == AgentCustomerWhatsAppReadKind.driverStatus) {
          return const _AgentCustomerWhatsAppConnectorPlan(
            module: 'ride',
            actionId: AgentActionId.readRideStatus,
            scopeKey: 'rideId',
          );
        }

        if (request.kind == AgentCustomerWhatsAppReadKind.fare) {
          return const _AgentCustomerWhatsAppConnectorPlan(
            module: 'ride',
            actionId: AgentActionId.readRide,
            scopeKey: 'rideId',
          );
        }

        return null;

      case AgentCustomerWhatsAppService.food:
        if (request.kind == AgentCustomerWhatsAppReadKind.bookingStatus ||
            request.kind == AgentCustomerWhatsAppReadKind.paymentStatus) {
          return const _AgentCustomerWhatsAppConnectorPlan(
            module: 'food',
            actionId: AgentActionId.readFoodOrder,
            scopeKey: 'orderId',
          );
        }

        return null;

      case AgentCustomerWhatsAppService.hotel:
        if (request.kind == AgentCustomerWhatsAppReadKind.bookingStatus) {
          return const _AgentCustomerWhatsAppConnectorPlan(
            module: 'hotel',
            actionId: AgentActionId.readHotelBooking,
            scopeKey: 'bookingId',
          );
        }

        return null;

      case AgentCustomerWhatsAppService.tour:
        if (request.kind == AgentCustomerWhatsAppReadKind.bookingStatus) {
          return const _AgentCustomerWhatsAppConnectorPlan(
            module: 'tour',
            actionId: AgentActionId.readTourBooking,
            scopeKey: 'bookingId',
          );
        }

        return null;

      case AgentCustomerWhatsAppService.cargo:
        if (request.kind == AgentCustomerWhatsAppReadKind.bookingStatus) {
          return const _AgentCustomerWhatsAppConnectorPlan(
            module: 'cargo',
            actionId: AgentActionId.readCargoStatus,
            scopeKey: 'bookingId',
          );
        }

        return null;

      default:
        return null;
    }
  }
}

class _AgentCustomerWhatsAppConnectorPlan {
  const _AgentCustomerWhatsAppConnectorPlan({
    required this.module,
    required this.actionId,
    required this.scopeKey,
  });

  final String module;
  final String actionId;
  final String scopeKey;
}
