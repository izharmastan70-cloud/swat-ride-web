import '../constants/agent_guardian_observability_constants.dart';

class AgentGuardianMonitoringAssessment {
  AgentGuardianMonitoringAssessment({
    required this.status,
    required this.assessmentId,
    required this.snapshotId,
    required this.handoffId,
    required this.envelopeId,
    required this.correlationId,
    required this.pseudonymousSubjectRef,
    required this.severity,
    required this.failClosedRecommended,
    required this.humanSecurityReviewRequired,
    required this.authoritativeChecksStillPending,
    required List<String> reasonCodes,
    required List<String> unhealthyRequiredControls,
    required List<String> unknownRequiredControls,
    required this.generatedAt,
  }) : reasonCodes = List<String>.unmodifiable(reasonCodes),
       unhealthyRequiredControls = List<String>.unmodifiable(
         unhealthyRequiredControls,
       ),
       unknownRequiredControls = List<String>.unmodifiable(
         unknownRequiredControls,
       );

  final String status;
  final String assessmentId;
  final String snapshotId;
  final String handoffId;
  final String envelopeId;
  final String correlationId;
  final String pseudonymousSubjectRef;
  final String severity;

  final bool failClosedRecommended;
  final bool humanSecurityReviewRequired;
  final bool authoritativeChecksStillPending;

  final List<String> reasonCodes;
  final List<String> unhealthyRequiredControls;
  final List<String> unknownRequiredControls;
  final DateTime generatedAt;

  bool get healthy => status == AgentGuardianMonitoringStatus.healthy;

  bool get degraded => status == AgentGuardianMonitoringStatus.degraded;

  bool get failClosed =>
      status == AgentGuardianMonitoringStatus.failClosedRecommended;

  bool get recommendationOnly => true;
  bool get safeEvidenceOnly => true;
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
  bool get persistsAssessment => false;

  Map<String, dynamic> toSafeMap() {
    return Map<String, dynamic>.unmodifiable(<String, dynamic>{
      'status': status,
      'assessmentId': assessmentId,
      'snapshotId': snapshotId,
      'handoffId': handoffId,
      'envelopeId': envelopeId,
      'correlationId': correlationId,
      'pseudonymousSubjectRef': pseudonymousSubjectRef,
      'severity': severity,
      'failClosedRecommended': failClosedRecommended,
      'humanSecurityReviewRequired': humanSecurityReviewRequired,
      'authoritativeChecksStillPending': authoritativeChecksStillPending,
      'reasonCodes': List<String>.unmodifiable(reasonCodes),
      'unhealthyRequiredControls': List<String>.unmodifiable(
        unhealthyRequiredControls,
      ),
      'unknownRequiredControls': List<String>.unmodifiable(
        unknownRequiredControls,
      ),
      'generatedAt': generatedAt.toUtc().toIso8601String(),
      'rawEvidencePayloadIncluded': false,
      'recommendationOnly': true,
      'safeEvidenceOnly': true,
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
      'persistsAssessment': false,
    });
  }
}
