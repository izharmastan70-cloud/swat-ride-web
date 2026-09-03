import '../constants/agent_guardian_security_constants.dart';
import '../constants/agent_incident_response_plan_constants.dart';

class AgentSecurityIncidentResponsePlan {
  AgentSecurityIncidentResponsePlan({
    required this.status,
    required this.planId,
    required this.incidentId,
    required this.severity,
    required this.failClosedRecommended,
    required this.humanReviewVerified,
    required this.authoritativeChecksStillRequired,
    required this.generatedAt,
    required List<String> recommendationTypes,
    required List<String> reasonCodes,
  }) : recommendationTypes = List<String>.unmodifiable(recommendationTypes),
       reasonCodes = List<String>.unmodifiable(reasonCodes);

  final String status;
  final String planId;
  final String incidentId;
  final String severity;

  final bool failClosedRecommended;
  final bool humanReviewVerified;
  final bool authoritativeChecksStillRequired;

  final DateTime generatedAt;
  final List<String> recommendationTypes;
  final List<String> reasonCodes;

  bool get recommendationOnly => true;
  bool get grantsAuthority => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
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
  bool get persistsPlan => false;

  bool get blocked =>
      status ==
      AgentSecurityIncidentResponsePlanStatus.blockedInsufficientHumanReview;

  void validateStructure() {
    final RegExp safeId = RegExp(r'^[A-Za-z0-9._:-]{1,160}$');

    if (!safeId.hasMatch(planId) || !safeId.hasMatch(incidentId)) {
      throw const AgentSecurityIncidentResponsePlanException(
        'Incident response plan identifiers are invalid.',
      );
    }

    if (!AgentSecurityIncidentResponsePlanStatus.values.contains(status)) {
      throw const AgentSecurityIncidentResponsePlanException(
        'Incident response plan status is invalid.',
      );
    }

    if (!AgentGuardianSeverity.values.contains(severity)) {
      throw const AgentSecurityIncidentResponsePlanException(
        'Incident response plan severity is invalid.',
      );
    }

    if (!authoritativeChecksStillRequired) {
      throw const AgentSecurityIncidentResponsePlanException(
        'Incident response plan cannot remove authoritative checks.',
      );
    }

    if (recommendationTypes.isEmpty || recommendationTypes.length > 10) {
      throw const AgentSecurityIncidentResponsePlanException(
        'Incident response plan must contain 1 to 10 recommendations.',
      );
    }

    if (reasonCodes.isEmpty || reasonCodes.length > 10) {
      throw const AgentSecurityIncidentResponsePlanException(
        'Incident response plan must contain 1 to 10 reason codes.',
      );
    }

    for (final String recommendation in recommendationTypes) {
      if (!AgentSecurityIncidentRecommendationType.values.contains(
        recommendation,
      )) {
        throw const AgentSecurityIncidentResponsePlanException(
          'Incident response recommendation is invalid.',
        );
      }
    }

    for (final String reason in reasonCodes) {
      if (!AgentSecurityIncidentResponseReason.values.contains(reason)) {
        throw const AgentSecurityIncidentResponsePlanException(
          'Incident response reason code is invalid.',
        );
      }
    }

    if ((severity == AgentGuardianSeverity.high ||
            severity == AgentGuardianSeverity.critical) &&
        !humanReviewVerified &&
        !blocked) {
      throw const AgentSecurityIncidentResponsePlanException(
        'HIGH/CRITICAL response plan requires verified human review.',
      );
    }
  }

  Map<String, dynamic> toSafeMap() {
    validateStructure();

    return Map<String, dynamic>.unmodifiable(<String, dynamic>{
      'status': status,
      'planId': planId,
      'incidentId': incidentId,
      'severity': severity,
      'failClosedRecommended': failClosedRecommended,
      'humanReviewVerified': humanReviewVerified,
      'authoritativeChecksStillRequired': authoritativeChecksStillRequired,
      'generatedAt': generatedAt.toUtc().toIso8601String(),
      'recommendationTypes': List<String>.unmodifiable(recommendationTypes),
      'reasonCodes': List<String>.unmodifiable(reasonCodes),
      'recommendationOnly': true,
      'grantsAuthority': false,
      'grantsPermission': false,
      'consumesApproval': false,
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
      'persistsPlan': false,
      'rawSensitiveEvidenceIncluded': false,
    });
  }
}

class AgentSecurityIncidentResponsePlanException implements Exception {
  const AgentSecurityIncidentResponsePlanException(this.message);

  final String message;

  @override
  String toString() => 'AgentSecurityIncidentResponsePlanException: $message';
}
