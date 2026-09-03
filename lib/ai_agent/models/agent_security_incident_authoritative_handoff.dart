import '../constants/agent_incident_response_plan_constants.dart';
import 'agent_security_incident_response_plan.dart';

class AgentSecurityIncidentAuthoritativeHandoff {
  AgentSecurityIncidentAuthoritativeHandoff({
    required this.status,
    required this.handoffId,
    required this.plan,
    required this.permissionEngineRequired,
    required this.approvalEngineRequired,
    required this.runtimeGateRequired,
    required this.emergencySecurityReviewRequired,
    required this.humanSecurityReviewRequired,
    required this.failClosedRecommended,
    required this.authoritativeChecksStillPending,
    required this.preparedAt,
  });

  final String status;
  final String handoffId;
  final AgentSecurityIncidentResponsePlan plan;

  final bool permissionEngineRequired;
  final bool approvalEngineRequired;
  final bool runtimeGateRequired;
  final bool emergencySecurityReviewRequired;
  final bool humanSecurityReviewRequired;
  final bool failClosedRecommended;
  final bool authoritativeChecksStillPending;

  final DateTime preparedAt;

  bool get handoffOnly => true;
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
  bool get executesContainment => false;
  bool get executesRemediation => false;
  bool get executesRecoveryAction => false;
  bool get invokesProvider => false;
  bool get invokesTargetAgent => false;
  bool get writesBusinessData => false;
  bool get persistsHandoff => false;

  void validateStructure() {
    final RegExp safeId = RegExp(r'^[A-Za-z0-9._:-]{1,160}$');

    if (!safeId.hasMatch(handoffId)) {
      throw const AgentSecurityIncidentAuthoritativeHandoffException(
        'Incident authoritative handoff id is invalid.',
      );
    }

    if (!AgentSecurityIncidentAuthoritativeHandoffStatus.values.contains(
      status,
    )) {
      throw const AgentSecurityIncidentAuthoritativeHandoffException(
        'Incident authoritative handoff status is invalid.',
      );
    }

    plan.validateStructure();

    if (!authoritativeChecksStillPending) {
      throw const AgentSecurityIncidentAuthoritativeHandoffException(
        'Incident authoritative handoff cannot mark checks complete.',
      );
    }

    if (status == AgentSecurityIncidentAuthoritativeHandoffStatus.prepared &&
        !(permissionEngineRequired ||
            approvalEngineRequired ||
            runtimeGateRequired ||
            emergencySecurityReviewRequired ||
            humanSecurityReviewRequired)) {
      throw const AgentSecurityIncidentAuthoritativeHandoffException(
        'Prepared handoff requires at least one authoritative review.',
      );
    }
  }

  Map<String, dynamic> toSafeMap() {
    validateStructure();

    return Map<String, dynamic>.unmodifiable(<String, dynamic>{
      'status': status,
      'handoffId': handoffId,
      'plan': plan.toSafeMap(),
      'permissionEngineRequired': permissionEngineRequired,
      'approvalEngineRequired': approvalEngineRequired,
      'runtimeGateRequired': runtimeGateRequired,
      'emergencySecurityReviewRequired': emergencySecurityReviewRequired,
      'humanSecurityReviewRequired': humanSecurityReviewRequired,
      'failClosedRecommended': failClosedRecommended,
      'authoritativeChecksStillPending': authoritativeChecksStillPending,
      'preparedAt': preparedAt.toUtc().toIso8601String(),
      'handoffOnly': true,
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
      'executesContainment': false,
      'executesRemediation': false,
      'executesRecoveryAction': false,
      'invokesProvider': false,
      'invokesTargetAgent': false,
      'writesBusinessData': false,
      'persistsHandoff': false,
    });
  }
}

class AgentSecurityIncidentAuthoritativeHandoffException implements Exception {
  const AgentSecurityIncidentAuthoritativeHandoffException(this.message);

  final String message;

  @override
  String toString() =>
      'AgentSecurityIncidentAuthoritativeHandoffException: $message';
}
