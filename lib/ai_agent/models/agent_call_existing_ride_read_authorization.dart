class AgentCallExistingRideReadAuthorization {
  const AgentCallExistingRideReadAuthorization({
    required this.permissionAllowed,
    required this.runtimeAllowed,
    required this.trustedContextBound,
    required this.exactRoleBound,
    required this.exactModuleBound,
    required this.exactActionBound,
    required this.approvalFreeRead,
    required this.reason,
  });

  final bool permissionAllowed;
  final bool runtimeAllowed;
  final bool trustedContextBound;
  final bool exactRoleBound;
  final bool exactModuleBound;
  final bool exactActionBound;
  final bool approvalFreeRead;
  final String reason;

  bool get isAllowed =>
      permissionAllowed &&
      runtimeAllowed &&
      trustedContextBound &&
      exactRoleBound &&
      exactModuleBound &&
      exactActionBound &&
      approvalFreeRead;

  void validate() {
    if (!isAllowed && reason.trim().isEmpty) {
      throw const AgentCallExistingRideReadAuthorizationException(
        'Blocked existing-Ride read authorization requires a reason.',
      );
    }
  }

  Map<String, dynamic> toSafeMap() {
    return <String, dynamic>{
      'permissionAllowed': permissionAllowed,
      'runtimeAllowed': runtimeAllowed,
      'trustedContextBound': trustedContextBound,
      'exactRoleBound': exactRoleBound,
      'exactModuleBound': exactModuleBound,
      'exactActionBound': exactActionBound,
      'approvalFreeRead': approvalFreeRead,
      'isAllowed': isAllowed,
      'reason': reason,
      'rawPhoneAuthority': false,
      'transcriptAuthority': false,
      'voiceAuthority': false,
      'firebaseUserAuthority': false,
      'rideWriteAuthority': false,
    };
  }
}

class AgentCallExistingRideReadAuthorizationException implements Exception {
  const AgentCallExistingRideReadAuthorizationException(this.message);

  final String message;

  @override
  String toString() =>
      'AgentCallExistingRideReadAuthorizationException: $message';
}
