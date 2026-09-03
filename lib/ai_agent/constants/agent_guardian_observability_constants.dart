class AgentGuardianMonitoringStatus {
  AgentGuardianMonitoringStatus._();

  static const String healthy = 'HEALTHY';
  static const String degraded = 'DEGRADED';
  static const String failClosedRecommended = 'FAIL_CLOSED_RECOMMENDED';

  static const Set<String> values = <String>{
    healthy,
    degraded,
    failClosedRecommended,
  };
}

class AgentGuardianMonitoringReason {
  AgentGuardianMonitoringReason._();

  static const String requiredPermissionEngineUnhealthy =
      'required_permission_engine_unhealthy';

  static const String requiredPermissionEngineUnknown =
      'required_permission_engine_unknown';

  static const String requiredApprovalEngineUnhealthy =
      'required_approval_engine_unhealthy';

  static const String requiredApprovalEngineUnknown =
      'required_approval_engine_unknown';

  static const String requiredRuntimeGateUnhealthy =
      'required_runtime_gate_unhealthy';

  static const String requiredRuntimeGateUnknown =
      'required_runtime_gate_unknown';

  static const String requiredEmergencyReviewUnhealthy =
      'required_emergency_review_unhealthy';

  static const String requiredEmergencyReviewUnknown =
      'required_emergency_review_unknown';

  static const String requiredHumanReviewUnavailable =
      'required_human_review_unavailable';

  static const String requiredHumanReviewUnknown =
      'required_human_review_unknown';

  static const String nonRequiredControlDegraded =
      'non_required_control_degraded';

  static const String policyHandoffBlocked = 'policy_handoff_blocked';

  static const String policyEnvelopeBlocked = 'policy_envelope_blocked';

  static const String invalidObservabilitySnapshot =
      'invalid_observability_snapshot';

  static const String authoritativeChecksStillPending =
      'authoritative_checks_still_pending';

  static const String safeEvidenceOnly = 'safe_evidence_only';

  static const Set<String> values = <String>{
    requiredPermissionEngineUnhealthy,
    requiredPermissionEngineUnknown,
    requiredApprovalEngineUnhealthy,
    requiredApprovalEngineUnknown,
    requiredRuntimeGateUnhealthy,
    requiredRuntimeGateUnknown,
    requiredEmergencyReviewUnhealthy,
    requiredEmergencyReviewUnknown,
    requiredHumanReviewUnavailable,
    requiredHumanReviewUnknown,
    nonRequiredControlDegraded,
    policyHandoffBlocked,
    policyEnvelopeBlocked,
    invalidObservabilitySnapshot,
    authoritativeChecksStillPending,
    safeEvidenceOnly,
  };
}
