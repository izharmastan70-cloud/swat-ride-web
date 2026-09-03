import 'agent_guardian_security_policy_envelope.dart';

class AgentGuardianAuthoritativeGateHandoffStatus {
  AgentGuardianAuthoritativeGateHandoffStatus._();

  static const String prepared = 'PREPARED';
  static const String blocked = 'BLOCKED';
}

class AgentGuardianAuthoritativeGateHandoff {
  AgentGuardianAuthoritativeGateHandoff({
    required this.status,
    required this.handoffId,
    required this.envelope,
    required this.permissionEngineRequired,
    required this.approvalEngineRequired,
    required this.runtimeGateRequired,
    required this.emergencySecurityReviewRequired,
    required this.humanSecurityReviewRequired,
    required this.failClosedRecommended,
    required this.authoritativeChecksStillPending,
  });

  final String status;
  final String handoffId;
  final AgentGuardianSecurityPolicyEnvelope envelope;

  final bool permissionEngineRequired;
  final bool approvalEngineRequired;
  final bool runtimeGateRequired;
  final bool emergencySecurityReviewRequired;
  final bool humanSecurityReviewRequired;
  final bool failClosedRecommended;

  /// Guardian cannot mark authoritative checks as complete.
  final bool authoritativeChecksStillPending;

  bool get prepared =>
      status == AgentGuardianAuthoritativeGateHandoffStatus.prepared;

  bool get blocked =>
      status == AgentGuardianAuthoritativeGateHandoffStatus.blocked;

  bool get recommendationOnly => true;
  bool get guardianIsFinalEnforcer => false;
  bool get grantsAuthority => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get marksPermissionApproved => false;
  bool get marksApprovalConsumed => false;
  bool get marksRuntimeAllowed => false;
  bool get invokesPermissionEngine => false;
  bool get invokesApprovalEngine => false;
  bool get invokesRuntimeGate => false;
  bool get invokesEmergencyStop => false;
  bool get executesBlock => false;
  bool get executesEscalation => false;
  bool get createsIncident => false;
  bool get mutatesSecurityControls => false;
  bool get invokesProvider => false;
  bool get invokesTargetAgent => false;
  bool get writesBusinessData => false;
  bool get persistsHandoff => false;

  Map<String, dynamic> toSafeMap() {
    return Map<String, dynamic>.unmodifiable(<String, dynamic>{
      'status': status,
      'handoffId': handoffId,
      'envelopeId': envelope.envelopeId,
      'correlationId': envelope.correlationId,
      'pseudonymousSubjectRef': envelope.pseudonymousSubjectRef,
      'permissionEngineRequired': permissionEngineRequired,
      'approvalEngineRequired': approvalEngineRequired,
      'runtimeGateRequired': runtimeGateRequired,
      'emergencySecurityReviewRequired': emergencySecurityReviewRequired,
      'humanSecurityReviewRequired': humanSecurityReviewRequired,
      'failClosedRecommended': failClosedRecommended,
      'authoritativeChecksStillPending': authoritativeChecksStillPending,
      'recommendationOnly': true,
      'guardianIsFinalEnforcer': false,
      'grantsAuthority': false,
      'grantsPermission': false,
      'consumesApproval': false,
      'marksPermissionApproved': false,
      'marksApprovalConsumed': false,
      'marksRuntimeAllowed': false,
      'invokesPermissionEngine': false,
      'invokesApprovalEngine': false,
      'invokesRuntimeGate': false,
      'invokesEmergencyStop': false,
      'executesBlock': false,
      'executesEscalation': false,
      'createsIncident': false,
      'mutatesSecurityControls': false,
      'invokesProvider': false,
      'invokesTargetAgent': false,
      'writesBusinessData': false,
      'persistsHandoff': false,
    });
  }
}
