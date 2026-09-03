import '../models/agent_role.dart';
import '../models/agent_security_incident_persisted_role_resolution_result.dart';
import '../models/agent_security_incident_role_inventory_revision_design.dart';
import 'agent_role_service.dart';

/// Phase 66 Step1I-T-I.
///
/// Read-only resolver for the proposed persisted Security Incident role.
///
/// This closes the caller-supplied AgentRole authority gap at the T-B boundary:
/// execution/preflight authority may come only from AgentRoleService.getRole()
/// for the exact versioned role id.
///
/// The resolver never calls AgentRoleService mutation APIs.
class AgentSecurityIncidentPersistedRoleResolver {
  AgentSecurityIncidentPersistedRoleResolver({required this.roleService});

  final AgentRoleService roleService;

  Future<AgentSecurityIncidentPersistedRoleResolutionResult> resolve() async {
    final AgentRole? role = await roleService.getRole(
      AgentSecurityIncidentRoleInventoryRevisionDesign.dedicatedRoleId,
    );

    if (role == null) {
      return AgentSecurityIncidentPersistedRoleResolutionResult.blocked(
        AgentSecurityIncidentPersistedRoleResolutionReason.missing,
      );
    }

    if (role.isFailClosed) {
      return AgentSecurityIncidentPersistedRoleResolutionResult.blocked(
        AgentSecurityIncidentPersistedRoleResolutionReason.failClosed,
      );
    }

    if (!role.isValid) {
      return AgentSecurityIncidentPersistedRoleResolutionResult.blocked(
        AgentSecurityIncidentPersistedRoleResolutionReason.invalid,
      );
    }

    if (role.roleId !=
        AgentSecurityIncidentRoleInventoryRevisionDesign.dedicatedRoleId) {
      return AgentSecurityIncidentPersistedRoleResolutionResult.blocked(
        AgentSecurityIncidentPersistedRoleResolutionReason.roleIdMismatch,
      );
    }

    if (role.module !=
        AgentSecurityIncidentRoleInventoryRevisionDesign.dedicatedModule) {
      return AgentSecurityIncidentPersistedRoleResolutionResult.blocked(
        AgentSecurityIncidentPersistedRoleResolutionReason.moduleMismatch,
      );
    }

    if (!role.enabled) {
      return AgentSecurityIncidentPersistedRoleResolutionResult.blocked(
        AgentSecurityIncidentPersistedRoleResolutionReason.disabled,
      );
    }

    if (!role.isOperational) {
      return AgentSecurityIncidentPersistedRoleResolutionResult.blocked(
        AgentSecurityIncidentPersistedRoleResolutionReason.nonOperational,
      );
    }

    if (role.mode !=
        AgentSecurityIncidentRoleInventoryRevisionDesign
            .proposedStoredRoleMode) {
      return AgentSecurityIncidentPersistedRoleResolutionResult.blocked(
        AgentSecurityIncidentPersistedRoleResolutionReason.modeMismatch,
      );
    }

    if (!_exactStringList(
      role.allowedActions,
      AgentSecurityIncidentRoleInventoryRevisionDesign.proposedAllowedActions,
    )) {
      return AgentSecurityIncidentPersistedRoleResolutionResult.blocked(
        AgentSecurityIncidentPersistedRoleResolutionReason
            .allowedActionsMismatch,
      );
    }

    if (!_exactStringList(
      role.approvalRequiredActions,
      AgentSecurityIncidentRoleInventoryRevisionDesign
          .proposedApprovalRequiredActions,
    )) {
      return AgentSecurityIncidentPersistedRoleResolutionResult.blocked(
        AgentSecurityIncidentPersistedRoleResolutionReason
            .approvalActionsMismatch,
      );
    }

    if (role.forbiddenActions.contains(
      AgentSecurityIncidentRoleInventoryRevisionDesign.attachRuntimeActionId,
    )) {
      return AgentSecurityIncidentPersistedRoleResolutionResult.blocked(
        AgentSecurityIncidentPersistedRoleResolutionReason.actionForbidden,
      );
    }

    return AgentSecurityIncidentPersistedRoleResolutionResult.allowed(role);
  }

  bool _exactStringList(List<String> actual, List<String> expected) {
    if (actual.length != expected.length) {
      return false;
    }

    for (int index = 0; index < expected.length; index++) {
      if (actual[index] != expected[index]) {
        return false;
      }
    }

    return true;
  }

  bool get readOnlyResolution => true;
  bool get callerSuppliedRoleAccepted => false;
  bool get syntheticRoleAuthorityAccepted => false;

  bool get createsRole => false;
  bool get syncsRolePermissions => false;
  bool get updatesRoleMode => false;
  bool get updatesRoleEnabled => false;

  bool get consumesApproval => false;
  bool get attachesRuntime => false;
  bool get armsRepository => false;
  bool get writesIncident => false;
  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;
}
