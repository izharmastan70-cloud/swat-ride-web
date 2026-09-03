class AgentCallRideBookingCentralAuthorizationDecision {
  const AgentCallRideBookingCentralAuthorizationDecision({
    required this.roleId,
    required this.actionId,
    required this.module,
    required this.requestedBy,
    required this.permissionAllowed,
    required this.runtimeAllowed,
    required this.trustedAuthorityContextBound,
    required this.permissionDecisionSource,
    required this.runtimeDecisionSource,
    required this.reason,
  });

  final String roleId;
  final String actionId;
  final String module;
  final String requestedBy;

  final bool permissionAllowed;
  final bool runtimeAllowed;
  final bool trustedAuthorityContextBound;

  final String permissionDecisionSource;
  final String runtimeDecisionSource;
  final String reason;

  bool get isAllowed =>
      permissionAllowed &&
      runtimeAllowed &&
      trustedAuthorityContextBound &&
      permissionDecisionSource == 'AgentPermissionEngine' &&
      runtimeDecisionSource == 'AgentRuntimeGate';

  void validate() {
    if (roleId.trim().isEmpty ||
        actionId.trim().isEmpty ||
        module.trim().isEmpty ||
        requestedBy.trim().isEmpty) {
      throw const AgentCallRideBookingAuthorizationException(
        'Role, action, module and requestedBy are required.',
      );
    }

    if (permissionDecisionSource.trim().isEmpty ||
        runtimeDecisionSource.trim().isEmpty) {
      throw const AgentCallRideBookingAuthorizationException(
        'Central permission/runtime decision sources are required.',
      );
    }

    if (!isAllowed && reason.trim().isEmpty) {
      throw const AgentCallRideBookingAuthorizationException(
        'Blocked central authorization decision requires a reason.',
      );
    }
  }
}

class AgentCallRideBookingAuthorizationException implements Exception {
  const AgentCallRideBookingAuthorizationException(this.message);

  final String message;

  @override
  String toString() => 'AgentCallRideBookingAuthorizationException: $message';
}
