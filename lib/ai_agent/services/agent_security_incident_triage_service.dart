import '../constants/agent_guardian_security_constants.dart';
import '../constants/agent_incident_response_constants.dart';
import '../models/agent_guardian_risk_aggregate.dart';
import '../models/agent_security_incident_record.dart';
import '../models/agent_security_incident_triage_decision.dart';

class AgentSecurityIncidentTriageService {
  const AgentSecurityIncidentTriageService();

  AgentSecurityIncidentRecord createRecordFromGuardian({
    required String incidentId,
    required AgentGuardianRiskAggregate aggregate,
    required DateTime createdAt,
    required List<String> evidenceReferenceCodes,
  }) {
    final String severity = aggregate.blocked
        ? _maxSeverity(aggregate.severity, AgentGuardianSeverity.high)
        : aggregate.severity;

    final String confidence = aggregate.evidenceConfidence;

    final AgentSecurityIncidentRecord record = AgentSecurityIncidentRecord(
      incidentId: incidentId,
      source: AgentSecurityIncidentSource.guardian,
      sourceReferenceId: aggregate.correlationId,
      pseudonymousSubjectRef: aggregate.pseudonymousSubjectRef,
      status: AgentSecurityIncidentStatus.open,
      severity: severity,
      evidenceConfidence: confidence,
      createdAt: createdAt,
      updatedAt: createdAt,
      evidenceReferenceCodes: evidenceReferenceCodes,
    );

    record.validateStructure();
    return record;
  }

  AgentSecurityIncidentTriageDecision triageFromGuardian({
    required AgentSecurityIncidentRecord record,
    required AgentGuardianRiskAggregate aggregate,
    required DateTime generatedAt,
  }) {
    record.validateStructure();

    if (record.source != AgentSecurityIncidentSource.guardian ||
        record.sourceReferenceId != aggregate.correlationId ||
        record.pseudonymousSubjectRef != aggregate.pseudonymousSubjectRef) {
      throw const AgentSecurityIncidentTriageServiceException(
        'Incident record is not bound to the supplied Guardian aggregate.',
      );
    }

    final String incidentSeverity = _maxSeverity(
      record.severity,
      aggregate.severity,
    );

    final bool high = incidentSeverity == AgentGuardianSeverity.high;

    final bool critical = incidentSeverity == AgentGuardianSeverity.critical;

    final bool blockLike =
        aggregate.recommendedDisposition ==
            AgentGuardianRecommendedDisposition.blockRecommended ||
        aggregate.recommendedDisposition ==
            AgentGuardianRecommendedDisposition.blockAndEscalateRecommended;

    final bool escalationLike =
        aggregate.recommendedDisposition ==
            AgentGuardianRecommendedDisposition.reviewAndEscalate ||
        aggregate.recommendedDisposition ==
            AgentGuardianRecommendedDisposition.blockAndEscalateRecommended;

    final bool humanReviewRequired =
        aggregate.blocked || high || critical || blockLike || escalationLike;

    final bool failClosedRecommended =
        aggregate.blocked || critical || blockLike;

    final String status = aggregate.blocked
        ? AgentSecurityIncidentTriageStatus.failClosedReviewRequired
        : humanReviewRequired
        ? AgentSecurityIncidentTriageStatus.humanReviewRequired
        : AgentSecurityIncidentTriageStatus.readyForResponsePlanning;

    final List<String> reasons = <String>[
      AgentSecurityIncidentReason.guardianSeverityInherited,
      AgentSecurityIncidentReason.authoritativeChecksStillRequired,
      AgentSecurityIncidentReason.privacyMinimizedEvidence,
      AgentSecurityIncidentReason.responsePlanningOnly,
      if (aggregate.blocked)
        AgentSecurityIncidentReason.guardianAggregateBlocked,
      if (high) AgentSecurityIncidentReason.highRiskHumanReview,
      if (critical) AgentSecurityIncidentReason.criticalRiskHumanReview,
      if (blockLike) AgentSecurityIncidentReason.blockLikeGuardianDisposition,
      if (escalationLike)
        AgentSecurityIncidentReason.escalationLikeGuardianDisposition,
    ];

    final AgentSecurityIncidentTriageDecision decision =
        AgentSecurityIncidentTriageDecision(
          status: status,
          incidentId: record.incidentId,
          sourceReferenceId: record.sourceReferenceId,
          inheritedGuardianSeverity: aggregate.severity,
          incidentSeverity: incidentSeverity,
          evidenceConfidence: aggregate.evidenceConfidence,
          humanReviewRequired: humanReviewRequired,
          responderAssignmentRequired: humanReviewRequired,
          failClosedRecommended: failClosedRecommended,
          authoritativeChecksStillRequired: true,
          responsePlanningAllowed: !aggregate.blocked,
          generatedAt: generatedAt,
          reasonCodes: reasons,
        );

    decision.validateStructure();
    return decision;
  }

  bool canTransition({
    required String currentStatus,
    required String nextStatus,
  }) {
    if (!AgentSecurityIncidentStatus.values.contains(currentStatus) ||
        !AgentSecurityIncidentStatus.values.contains(nextStatus)) {
      return false;
    }

    const Map<String, Set<String>> allowed = <String, Set<String>>{
      AgentSecurityIncidentStatus.detected: <String>{
        AgentSecurityIncidentStatus.open,
      },
      AgentSecurityIncidentStatus.open: <String>{
        AgentSecurityIncidentStatus.acknowledged,
        AgentSecurityIncidentStatus.triaged,
      },
      AgentSecurityIncidentStatus.acknowledged: <String>{
        AgentSecurityIncidentStatus.triaged,
      },
      AgentSecurityIncidentStatus.triaged: <String>{
        AgentSecurityIncidentStatus.containmentRecommended,
        AgentSecurityIncidentStatus.resolved,
      },
      AgentSecurityIncidentStatus.containmentRecommended: <String>{
        AgentSecurityIncidentStatus.remediationRecommended,
      },
      AgentSecurityIncidentStatus.remediationRecommended: <String>{
        AgentSecurityIncidentStatus.recoveryMonitoring,
      },
      AgentSecurityIncidentStatus.recoveryMonitoring: <String>{
        AgentSecurityIncidentStatus.resolved,
      },
      AgentSecurityIncidentStatus.resolved: <String>{
        AgentSecurityIncidentStatus.closed,
      },
      AgentSecurityIncidentStatus.closed: <String>{},
    };

    return allowed[currentStatus]!.contains(nextStatus);
  }

  String _maxSeverity(String a, String b) {
    return _severityRank(a) >= _severityRank(b) ? a : b;
  }

  int _severityRank(String severity) {
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

  bool get triageAndLifecycleOnly => true;
  bool get guardianDetectionDuplicated => false;
  bool get guardianSeverityCanBeDowngraded => false;
  bool get finalEnforcer => false;
  bool get invokesPermissionEngine => false;
  bool get invokesApprovalEngine => false;
  bool get invokesRuntimeGate => false;
  bool get invokesEmergencyStop => false;
  bool get bypassesAuthoritativeControls => false;
  bool get executesContainment => false;
  bool get executesRemediation => false;
  bool get executesRecoveryAction => false;
  bool get createsProviderAction => false;
  bool get invokesTargetAgent => false;
  bool get writesBusinessData => false;
  bool get persistsIncident => false;
  bool get implementsPhase63PrivacyUi => false;
}

class AgentSecurityIncidentTriageServiceException implements Exception {
  const AgentSecurityIncidentTriageServiceException(this.message);

  final String message;

  @override
  String toString() => 'AgentSecurityIncidentTriageServiceException: $message';
}
