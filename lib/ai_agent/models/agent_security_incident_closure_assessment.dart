import '../constants/agent_incident_response_closure_constants.dart';

class AgentSecurityIncidentClosureAssessment {
  AgentSecurityIncidentClosureAssessment({
    required this.status,
    required this.assessmentId,
    required this.incidentId,
    required this.recoveryEvidenceId,
    required this.recoveryStable,
    required this.requiredVerificationComplete,
    required this.finalClosureAuthorityStillRequired,
    required this.assessedAt,
    required List<String> reasonCodes,
  }) : reasonCodes = List<String>.unmodifiable(reasonCodes);

  final String status;
  final String assessmentId;
  final String incidentId;
  final String recoveryEvidenceId;

  final bool recoveryStable;
  final bool requiredVerificationComplete;
  final bool finalClosureAuthorityStillRequired;

  final DateTime assessedAt;
  final List<String> reasonCodes;

  bool get closureRecommendationOnly => true;
  bool get closureEligibleForAuthoritativeReview =>
      status ==
      AgentSecurityIncidentClosureAssessmentStatus
          .readyForAuthoritativeClosureReview;

  bool get grantsAuthority => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get marksRuntimeAllowed => false;
  bool get marksIncidentResolved => false;
  bool get marksIncidentClosed => false;
  bool get invokesPermissionEngine => false;
  bool get invokesApprovalEngine => false;
  bool get invokesRuntimeGate => false;
  bool get invokesEmergencyStop => false;
  bool get executesContainment => false;
  bool get executesRemediation => false;
  bool get executesRecoveryAction => false;
  bool get invokesProvider => false;
  bool get writesBusinessData => false;
  bool get persistsAssessment => false;

  void validateStructure() {
    final RegExp safeId = RegExp(r'^[A-Za-z0-9._:-]{1,160}$');

    if (!safeId.hasMatch(assessmentId) ||
        !safeId.hasMatch(incidentId) ||
        !safeId.hasMatch(recoveryEvidenceId)) {
      throw const AgentSecurityIncidentClosureAssessmentException(
        'Incident closure assessment identifiers are invalid.',
      );
    }

    if (!AgentSecurityIncidentClosureAssessmentStatus.values.contains(status)) {
      throw const AgentSecurityIncidentClosureAssessmentException(
        'Incident closure assessment status is invalid.',
      );
    }

    if (!finalClosureAuthorityStillRequired) {
      throw const AgentSecurityIncidentClosureAssessmentException(
        'Closure assessment cannot remove final closure authority.',
      );
    }

    if (reasonCodes.isEmpty || reasonCodes.length > 10) {
      throw const AgentSecurityIncidentClosureAssessmentException(
        'Closure assessment requires 1 to 10 reason codes.',
      );
    }

    for (final String reason in reasonCodes) {
      if (!AgentSecurityIncidentClosureReason.values.contains(reason)) {
        throw const AgentSecurityIncidentClosureAssessmentException(
          'Closure assessment reason code is invalid.',
        );
      }
    }

    if (closureEligibleForAuthoritativeReview &&
        (!recoveryStable || !requiredVerificationComplete)) {
      throw const AgentSecurityIncidentClosureAssessmentException(
        'Closure review readiness requires stable recovery and verification.',
      );
    }
  }

  Map<String, dynamic> toSafeMap() {
    validateStructure();

    return Map<String, dynamic>.unmodifiable(<String, dynamic>{
      'status': status,
      'assessmentId': assessmentId,
      'incidentId': incidentId,
      'recoveryEvidenceId': recoveryEvidenceId,
      'recoveryStable': recoveryStable,
      'requiredVerificationComplete': requiredVerificationComplete,
      'finalClosureAuthorityStillRequired': finalClosureAuthorityStillRequired,
      'assessedAt': assessedAt.toUtc().toIso8601String(),
      'reasonCodes': List<String>.unmodifiable(reasonCodes),
      'closureRecommendationOnly': true,
      'closureEligibleForAuthoritativeReview':
          closureEligibleForAuthoritativeReview,
      'grantsAuthority': false,
      'grantsPermission': false,
      'consumesApproval': false,
      'marksRuntimeAllowed': false,
      'marksIncidentResolved': false,
      'marksIncidentClosed': false,
      'invokesPermissionEngine': false,
      'invokesApprovalEngine': false,
      'invokesRuntimeGate': false,
      'invokesEmergencyStop': false,
      'executesContainment': false,
      'executesRemediation': false,
      'executesRecoveryAction': false,
      'invokesProvider': false,
      'writesBusinessData': false,
      'persistsAssessment': false,
    });
  }
}

class AgentSecurityIncidentClosureAssessmentException implements Exception {
  const AgentSecurityIncidentClosureAssessmentException(this.message);

  final String message;

  @override
  String toString() =>
      'AgentSecurityIncidentClosureAssessmentException: $message';
}
