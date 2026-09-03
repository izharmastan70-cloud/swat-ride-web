import 'agent_role.dart';

abstract final class AgentSecurityIncidentPersistedRoleResolutionReason {
  static const String verified = 'persisted_security_incident_role_verified';

  static const String missing = 'persisted_security_incident_role_missing';
  static const String failClosed =
      'persisted_security_incident_role_fail_closed';
  static const String invalid = 'persisted_security_incident_role_invalid';
  static const String roleIdMismatch =
      'persisted_security_incident_role_id_mismatch';
  static const String moduleMismatch =
      'persisted_security_incident_role_module_mismatch';
  static const String disabled = 'persisted_security_incident_role_disabled';
  static const String nonOperational =
      'persisted_security_incident_role_non_operational';
  static const String modeMismatch =
      'persisted_security_incident_role_mode_mismatch';
  static const String allowedActionsMismatch =
      'persisted_security_incident_allowed_actions_mismatch';
  static const String approvalActionsMismatch =
      'persisted_security_incident_approval_actions_mismatch';
  static const String actionForbidden =
      'persisted_security_incident_attach_action_forbidden';
}

class AgentSecurityIncidentPersistedRoleResolutionResult {
  const AgentSecurityIncidentPersistedRoleResolutionResult._({
    required this.verified,
    required this.reasonCode,
    required this.role,
  });

  factory AgentSecurityIncidentPersistedRoleResolutionResult.allowed(
    AgentRole role,
  ) {
    return AgentSecurityIncidentPersistedRoleResolutionResult._(
      verified: true,
      reasonCode: AgentSecurityIncidentPersistedRoleResolutionReason.verified,
      role: role,
    );
  }

  factory AgentSecurityIncidentPersistedRoleResolutionResult.blocked(
    String reasonCode,
  ) {
    return AgentSecurityIncidentPersistedRoleResolutionResult._(
      verified: false,
      reasonCode: reasonCode,
      role: null,
    );
  }

  final bool verified;
  final String reasonCode;

  /// Non-null only after the role was read from AgentRoleService and passed the
  /// exact persisted-role policy.
  final AgentRole? role;

  bool get callerSuppliedRoleAccepted => false;
  bool get syntheticRoleAuthorityAccepted => false;
  bool get mutatesRole => false;
  bool get writesFirestore => false;
  bool get consumesApproval => false;
  bool get attachesRuntime => false;
  bool get armsRepository => false;
  bool get writesIncident => false;
  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;
}
