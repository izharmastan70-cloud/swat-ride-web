import '../constants/agent_guardian_security_constants.dart';
import '../models/agent_guardian_risk_decision.dart';
import '../models/agent_guardian_security_event.dart';

class AgentGuardianRiskClassifier {
  const AgentGuardianRiskClassifier();

  AgentGuardianRiskDecision classify(AgentGuardianSecurityEvent event) {
    try {
      event.validateStructure();
    } on AgentGuardianSecurityEventException {
      return AgentGuardianRiskDecision(
        status: AgentGuardianRiskDecisionStatus.blockedInvalidEvent,
        eventId: event.eventId,
        category: event.category,
        severity: AgentGuardianSeverity.high,
        evidenceConfidence: AgentGuardianEvidenceConfidence.low,
        recommendedDisposition:
            AgentGuardianRecommendedDisposition.reviewAndEscalate,
        reasonCodes: const <String>[AgentGuardianRiskReason.invalidEvent],
        existingAuthoritativeGateBlocked:
            event.existingAuthoritativeGateBlocked,
      );
    }

    String severity = _baseSeverity(event.category);
    final List<String> reasons = <String>[
      AgentGuardianRiskReason.baseCategorySeverity,
    ];

    final int strongIndicatorCount = <bool>[
      event.highImpactActionTargeted,
      event.repeatedWithinWindow,
      event.activeExploitEvidence,
    ].where((bool value) => value).length;

    if (event.highImpactActionTargeted &&
        severity == AgentGuardianSeverity.medium) {
      severity = AgentGuardianSeverity.high;
      reasons.add(AgentGuardianRiskReason.highImpactTargetElevation);
    }

    if (event.repeatedWithinWindow &&
        (severity == AgentGuardianSeverity.low ||
            severity == AgentGuardianSeverity.medium)) {
      severity = AgentGuardianSeverity.high;
      reasons.add(AgentGuardianRiskReason.repeatedPatternElevation);
    }

    if (event.activeExploitEvidence && severity == AgentGuardianSeverity.high) {
      severity = AgentGuardianSeverity.critical;
      reasons.add(AgentGuardianRiskReason.activeExploitElevation);
    }

    if (strongIndicatorCount >= 2 && severity == AgentGuardianSeverity.high) {
      severity = AgentGuardianSeverity.critical;
      reasons.add(AgentGuardianRiskReason.multipleStrongIndicatorsElevation);
    }

    final String evidenceConfidence = _evidenceConfidence(event.evidenceTrust);

    reasons.add(_evidenceReason(event.evidenceTrust));

    final String disposition = _recommendedDisposition(
      severity: severity,
      evidenceConfidence: evidenceConfidence,
    );

    return AgentGuardianRiskDecision(
      status: AgentGuardianRiskDecisionStatus.classified,
      eventId: event.eventId,
      category: event.category,
      severity: severity,
      evidenceConfidence: evidenceConfidence,
      recommendedDisposition: disposition,
      reasonCodes: reasons,
      existingAuthoritativeGateBlocked: event.existingAuthoritativeGateBlocked,
    );
  }

  String _baseSeverity(String category) {
    switch (category) {
      case AgentGuardianRiskCategory.suspiciousInputPattern:
        return AgentGuardianSeverity.low;

      case AgentGuardianRiskCategory.promptInjectionAttempt:
      case AgentGuardianRiskCategory.identityMismatch:
      case AgentGuardianRiskCategory.replayOrContinuityViolation:
        return AgentGuardianSeverity.medium;

      case AgentGuardianRiskCategory.permissionBypassAttempt:
      case AgentGuardianRiskCategory.approvalBypassAttempt:
      case AgentGuardianRiskCategory.runtimeGateBypassAttempt:
      case AgentGuardianRiskCategory.crossSubjectContextAttempt:
      case AgentGuardianRiskCategory.ownerCustomerBoundaryViolation:
      case AgentGuardianRiskCategory.emergencyContextIsolationViolation:
      case AgentGuardianRiskCategory.unauthorizedProviderExecutionAttempt:
      case AgentGuardianRiskCategory.unauthorizedBusinessWriteAttempt:
        return AgentGuardianSeverity.high;

      case AgentGuardianRiskCategory.emergencyStopBypassAttempt:
      case AgentGuardianRiskCategory.secretOrCredentialExposureAttempt:
      case AgentGuardianRiskCategory.securityControlTamperAttempt:
        return AgentGuardianSeverity.critical;

      default:
        return AgentGuardianSeverity.high;
    }
  }

  String _evidenceConfidence(String evidenceTrust) {
    switch (evidenceTrust) {
      case AgentGuardianEvidenceTrust.verifiedSecurityControl:
      case AgentGuardianEvidenceTrust.verifiedSystem:
        return AgentGuardianEvidenceConfidence.high;

      case AgentGuardianEvidenceTrust.verifiedIdentityBound:
      case AgentGuardianEvidenceTrust.heuristic:
        return AgentGuardianEvidenceConfidence.medium;

      case AgentGuardianEvidenceTrust.userReported:
      case AgentGuardianEvidenceTrust.untrustedExternal:
        return AgentGuardianEvidenceConfidence.low;

      default:
        return AgentGuardianEvidenceConfidence.low;
    }
  }

  String _evidenceReason(String evidenceTrust) {
    switch (evidenceTrust) {
      case AgentGuardianEvidenceTrust.verifiedSecurityControl:
      case AgentGuardianEvidenceTrust.verifiedSystem:
        return AgentGuardianRiskReason.verifiedEvidence;

      case AgentGuardianEvidenceTrust.verifiedIdentityBound:
      case AgentGuardianEvidenceTrust.heuristic:
        return AgentGuardianRiskReason.heuristicEvidence;

      case AgentGuardianEvidenceTrust.userReported:
      case AgentGuardianEvidenceTrust.untrustedExternal:
        return AgentGuardianRiskReason.unverifiedEvidence;

      default:
        return AgentGuardianRiskReason.unverifiedEvidence;
    }
  }

  String _recommendedDisposition({
    required String severity,
    required String evidenceConfidence,
  }) {
    if (severity == AgentGuardianSeverity.critical) {
      if (evidenceConfidence == AgentGuardianEvidenceConfidence.high) {
        return AgentGuardianRecommendedDisposition.blockAndEscalateRecommended;
      }

      return AgentGuardianRecommendedDisposition.reviewAndEscalate;
    }

    if (severity == AgentGuardianSeverity.high) {
      if (evidenceConfidence == AgentGuardianEvidenceConfidence.high) {
        return AgentGuardianRecommendedDisposition.blockRecommended;
      }

      return AgentGuardianRecommendedDisposition.reviewAndEscalate;
    }

    if (severity == AgentGuardianSeverity.medium) {
      return AgentGuardianRecommendedDisposition.review;
    }

    return AgentGuardianRecommendedDisposition.observe;
  }

  bool get recommendationOnly => true;
  bool get guardianIsFinalEnforcer => false;
  bool get invokesPermissionEngine => false;
  bool get invokesApprovalEngine => false;
  bool get invokesRuntimeGate => false;
  bool get invokesEmergencyStop => false;
  bool get executesBlock => false;
  bool get executesEscalation => false;
  bool get createsIncident => false;
  bool get implementsIncidentResponse => false;
  bool get mutatesSecurityControls => false;
  bool get invokesProvider => false;
  bool get invokesTargetAgent => false;
  bool get writesBusinessData => false;
  bool get persistsEventOrDecision => false;
}
