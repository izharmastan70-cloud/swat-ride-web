import '../constants/agent_guardian_security_constants.dart';
import '../constants/agent_incident_response_constants.dart';

class AgentSecurityIncidentTriageDecision {
  AgentSecurityIncidentTriageDecision({
    required this.status,
    required this.incidentId,
    required this.sourceReferenceId,
    required this.inheritedGuardianSeverity,
    required this.incidentSeverity,
    required this.evidenceConfidence,
    required this.humanReviewRequired,
    required this.responderAssignmentRequired,
    required this.failClosedRecommended,
    required this.authoritativeChecksStillRequired,
    required this.responsePlanningAllowed,
    required this.generatedAt,
    required List<String> reasonCodes,
  }) : reasonCodes = List<String>.unmodifiable(reasonCodes);

  final String status;
  final String incidentId;
  final String sourceReferenceId;

  final String inheritedGuardianSeverity;
  final String incidentSeverity;
  final String evidenceConfidence;

  final bool humanReviewRequired;
  final bool responderAssignmentRequired;
  final bool failClosedRecommended;
  final bool authoritativeChecksStillRequired;
  final bool responsePlanningAllowed;

  final DateTime generatedAt;
  final List<String> reasonCodes;

  bool get triageOnly => true;
  bool get guardianSeverityCanBeDowngraded => false;
  bool get finalEnforcer => false;
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
  bool get createsProviderAction => false;
  bool get writesBusinessData => false;
  bool get persistsDecision => false;

  void validateStructure() {
    if (!AgentSecurityIncidentTriageStatus.values.contains(status)) {
      throw const AgentSecurityIncidentTriageDecisionException(
        'Incident triage status is invalid.',
      );
    }

    if (!AgentGuardianSeverity.values.contains(inheritedGuardianSeverity) ||
        !AgentGuardianSeverity.values.contains(incidentSeverity)) {
      throw const AgentSecurityIncidentTriageDecisionException(
        'Incident triage severity is invalid.',
      );
    }

    if (!AgentGuardianEvidenceConfidence.values.contains(evidenceConfidence)) {
      throw const AgentSecurityIncidentTriageDecisionException(
        'Incident triage evidence confidence is invalid.',
      );
    }

    if (_severityRank(incidentSeverity) <
        _severityRank(inheritedGuardianSeverity)) {
      throw const AgentSecurityIncidentTriageDecisionException(
        'Incident triage cannot downgrade Guardian severity.',
      );
    }

    if (!authoritativeChecksStillRequired) {
      throw const AgentSecurityIncidentTriageDecisionException(
        'Incident triage cannot remove authoritative checks.',
      );
    }

    if (reasonCodes.isEmpty || reasonCodes.length > 12) {
      throw const AgentSecurityIncidentTriageDecisionException(
        'Incident triage requires 1 to 12 reason codes.',
      );
    }

    final RegExp safeReason = RegExp(r'^[A-Za-z0-9._:-]{1,120}$');

    for (final String reason in reasonCodes) {
      if (!safeReason.hasMatch(reason)) {
        throw const AgentSecurityIncidentTriageDecisionException(
          'Incident triage reason code is invalid.',
        );
      }
    }
  }

  static int _severityRank(String severity) {
    switch (severity) {
      case AgentGuardianSeverity.low:
        return 0;
      case AgentGuardianSeverity.medium:
        return 1;
      case AgentGuardianSeverity.high:
        return 2;
      case AgentGuardianSeverity.critical:
        return 3;
      default:
        return -1;
    }
  }

  Map<String, dynamic> toSafeMap() {
    validateStructure();

    return Map<String, dynamic>.unmodifiable(<String, dynamic>{
      'status': status,
      'incidentId': incidentId,
      'sourceReferenceId': sourceReferenceId,
      'inheritedGuardianSeverity': inheritedGuardianSeverity,
      'incidentSeverity': incidentSeverity,
      'evidenceConfidence': evidenceConfidence,
      'humanReviewRequired': humanReviewRequired,
      'responderAssignmentRequired': responderAssignmentRequired,
      'failClosedRecommended': failClosedRecommended,
      'authoritativeChecksStillRequired': authoritativeChecksStillRequired,
      'responsePlanningAllowed': responsePlanningAllowed,
      'generatedAt': generatedAt.toUtc().toIso8601String(),
      'reasonCodes': List<String>.unmodifiable(reasonCodes),
      'triageOnly': true,
      'guardianSeverityCanBeDowngraded': false,
      'finalEnforcer': false,
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
      'createsProviderAction': false,
      'writesBusinessData': false,
      'persistsDecision': false,
    });
  }
}

class AgentSecurityIncidentTriageDecisionException implements Exception {
  const AgentSecurityIncidentTriageDecisionException(this.message);

  final String message;

  @override
  String toString() => 'AgentSecurityIncidentTriageDecisionException: $message';
}
