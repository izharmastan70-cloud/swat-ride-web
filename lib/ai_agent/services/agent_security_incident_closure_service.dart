import '../constants/agent_guardian_security_constants.dart';
import '../constants/agent_incident_response_closure_constants.dart';
import '../constants/agent_incident_response_constants.dart';
import '../constants/agent_incident_response_plan_constants.dart';
import '../models/agent_security_incident_authoritative_handoff.dart';
import '../models/agent_security_incident_closure_assessment.dart';
import '../models/agent_security_incident_record.dart';
import '../models/agent_security_incident_recovery_evidence.dart';
import '../models/agent_security_incident_response_plan.dart';

class AgentSecurityIncidentClosureService {
  const AgentSecurityIncidentClosureService();

  AgentSecurityIncidentClosureAssessment assessClosure({
    required String assessmentId,
    required AgentSecurityIncidentRecord incident,
    required AgentSecurityIncidentResponsePlan plan,
    required AgentSecurityIncidentAuthoritativeHandoff handoff,
    required AgentSecurityIncidentRecoveryEvidence evidence,
    required DateTime assessedAt,
  }) {
    incident.validateStructure();
    plan.validateStructure();
    handoff.validateStructure();
    evidence.validateStructure();

    if (incident.incidentId != plan.incidentId ||
        incident.incidentId != handoff.plan.incidentId ||
        incident.incidentId != evidence.incidentId ||
        plan.planId != handoff.plan.planId) {
      throw const AgentSecurityIncidentClosureServiceException(
        'Closure inputs are not bound to one incident response chain.',
      );
    }

    final bool incidentResolved =
        incident.status == AgentSecurityIncidentStatus.resolved;

    final bool upstreamReady =
        !plan.blocked &&
        handoff.status ==
            AgentSecurityIncidentAuthoritativeHandoffStatus.prepared;

    final bool permissionVerified =
        !handoff.permissionEngineRequired || evidence.permissionReviewVerified;

    final bool approvalVerified =
        !handoff.approvalEngineRequired || evidence.approvalReviewVerified;

    final bool runtimeVerified =
        !handoff.runtimeGateRequired || evidence.runtimeReviewVerified;

    final bool emergencyVerified =
        !handoff.emergencySecurityReviewRequired ||
        evidence.emergencyReviewVerified;

    final bool humanVerified =
        !handoff.humanSecurityReviewRequired ||
        evidence.humanSecurityReviewVerified;

    final bool authoritativeVerificationComplete =
        permissionVerified &&
        approvalVerified &&
        runtimeVerified &&
        emergencyVerified &&
        humanVerified;

    final bool highOrCritical =
        plan.severity == AgentGuardianSeverity.high ||
        plan.severity == AgentGuardianSeverity.critical;

    final bool responseEvidenceComplete =
        !highOrCritical ||
        (evidence.containmentVerified && evidence.remediationVerified);

    final bool requiredVerificationComplete =
        upstreamReady &&
        authoritativeVerificationComplete &&
        responseEvidenceComplete;

    final String status;

    if (!incidentResolved) {
      status = AgentSecurityIncidentClosureAssessmentStatus
          .blockedIncidentNotResolved;
    } else if (!upstreamReady) {
      status = AgentSecurityIncidentClosureAssessmentStatus
          .blockedResponsePlanOrHandoff;
    } else if (!evidence.recoveryStable) {
      status = AgentSecurityIncidentClosureAssessmentStatus
          .recoveryMonitoringRequired;
    } else if (!requiredVerificationComplete) {
      status = AgentSecurityIncidentClosureAssessmentStatus
          .blockedMissingRequiredVerification;
    } else {
      status = AgentSecurityIncidentClosureAssessmentStatus
          .readyForAuthoritativeClosureReview;
    }

    final List<String> reasons = <String>[
      AgentSecurityIncidentClosureReason.incidentResolvedStateRequired,
      AgentSecurityIncidentClosureReason.responsePlanAndHandoffBound,
      AgentSecurityIncidentClosureReason.closureRecommendationOnly,
      AgentSecurityIncidentClosureReason.finalClosureAuthorityExternal,
      if (evidence.recoveryStable)
        AgentSecurityIncidentClosureReason.recoveryStableVerified,
      if (evidence.containmentVerified)
        AgentSecurityIncidentClosureReason.containmentEvidenceVerified,
      if (evidence.remediationVerified)
        AgentSecurityIncidentClosureReason.remediationEvidenceVerified,
      if (requiredVerificationComplete)
        AgentSecurityIncidentClosureReason.requiredAuthoritativeReviewsVerified,
      if (!requiredVerificationComplete)
        AgentSecurityIncidentClosureReason.requiredVerificationMissing,
      if (!evidence.recoveryStable)
        AgentSecurityIncidentClosureReason.recoveryMonitoringStillRequired,
    ];

    final AgentSecurityIncidentClosureAssessment assessment =
        AgentSecurityIncidentClosureAssessment(
          status: status,
          assessmentId: assessmentId,
          incidentId: incident.incidentId,
          recoveryEvidenceId: evidence.evidenceId,
          recoveryStable: evidence.recoveryStable,
          requiredVerificationComplete: requiredVerificationComplete,
          finalClosureAuthorityStillRequired: true,
          assessedAt: assessedAt,
          reasonCodes: reasons,
        );

    assessment.validateStructure();
    return assessment;
  }

  bool canRecommendClosure(AgentSecurityIncidentClosureAssessment assessment) {
    assessment.validateStructure();

    return assessment.closureEligibleForAuthoritativeReview;
  }

  bool get closureAssessmentOnly => true;
  bool get finalClosureAuthorityExternal => true;
  bool get autoClosesIncident => false;
  bool get marksIncidentResolved => false;
  bool get marksIncidentClosed => false;
  bool get invokesPermissionEngine => false;
  bool get invokesApprovalEngine => false;
  bool get invokesRuntimeGate => false;
  bool get invokesEmergencyStop => false;
  bool get bypassesAuthoritativeControls => false;
  bool get consumesApproval => false;
  bool get grantsPermission => false;
  bool get marksRuntimeAllowed => false;
  bool get executesContainment => false;
  bool get executesRemediation => false;
  bool get executesRecoveryAction => false;
  bool get invokesProvider => false;
  bool get invokesTargetAgent => false;
  bool get writesBusinessData => false;
  bool get persistsEvidence => false;
  bool get persistsAssessment => false;
  bool get implementsPhase63PrivacyUi => false;
}

class AgentSecurityIncidentClosureServiceException implements Exception {
  const AgentSecurityIncidentClosureServiceException(this.message);

  final String message;

  @override
  String toString() => 'AgentSecurityIncidentClosureServiceException: $message';
}
