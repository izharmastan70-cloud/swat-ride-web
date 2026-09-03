class AgentSecurityIncidentAdversarialScenario {
  AgentSecurityIncidentAdversarialScenario._();

  static const String duplicateIncidentIntake = 'DUPLICATE_INCIDENT_INTAKE';

  static const String duplicateResponderAssignment =
      'DUPLICATE_RESPONDER_ASSIGNMENT';

  static const String duplicateTimelineEvent = 'DUPLICATE_TIMELINE_EVENT';

  static const String duplicateResponsePlan = 'DUPLICATE_RESPONSE_PLAN';

  static const String duplicateAuthoritativeHandoff =
      'DUPLICATE_AUTHORITATIVE_HANDOFF';

  static const String duplicateRecoveryEvidence = 'DUPLICATE_RECOVERY_EVIDENCE';

  static const String duplicateClosureAssessment =
      'DUPLICATE_CLOSURE_ASSESSMENT';

  static const String idempotencyKeyCollision = 'IDEMPOTENCY_KEY_COLLISION';

  static const String staleReplayEvidence = 'STALE_REPLAY_EVIDENCE';

  static const String crossIncidentBindingAttempt =
      'CROSS_INCIDENT_BINDING_ATTEMPT';

  static const String missingHumanAcknowledgement =
      'MISSING_HUMAN_ACKNOWLEDGEMENT';

  static const String missingAuthoritativeVerification =
      'MISSING_AUTHORITATIVE_VERIFICATION';

  static const String unstableRecoveryClosureAttempt =
      'UNSTABLE_RECOVERY_CLOSURE_ATTEMPT';

  static const String observerFailureIsolation = 'OBSERVER_FAILURE_ISOLATION';

  static const Set<String> values = <String>{
    duplicateIncidentIntake,
    duplicateResponderAssignment,
    duplicateTimelineEvent,
    duplicateResponsePlan,
    duplicateAuthoritativeHandoff,
    duplicateRecoveryEvidence,
    duplicateClosureAssessment,
    idempotencyKeyCollision,
    staleReplayEvidence,
    crossIncidentBindingAttempt,
    missingHumanAcknowledgement,
    missingAuthoritativeVerification,
    unstableRecoveryClosureAttempt,
    observerFailureIsolation,
  };
}

class AgentSecurityIncidentAdversarialOutcome {
  AgentSecurityIncidentAdversarialOutcome._();

  static const String duplicateSuppressed = 'DUPLICATE_SUPPRESSED';

  static const String failClosed = 'FAIL_CLOSED';

  static const String staleReplayRejected = 'STALE_REPLAY_REJECTED';

  static const String crossIncidentRejected = 'CROSS_INCIDENT_REJECTED';

  static const String humanReviewRequired = 'HUMAN_REVIEW_REQUIRED';

  static const String verificationRequired = 'VERIFICATION_REQUIRED';

  static const String recoveryMonitoringRequired =
      'RECOVERY_MONITORING_REQUIRED';

  static const String failureIsolated = 'FAILURE_ISOLATED';

  static const Set<String> values = <String>{
    duplicateSuppressed,
    failClosed,
    staleReplayRejected,
    crossIncidentRejected,
    humanReviewRequired,
    verificationRequired,
    recoveryMonitoringRequired,
    failureIsolated,
  };
}

class AgentSecurityIncidentIdempotencyDecision {
  AgentSecurityIncidentIdempotencyDecision._();

  static const String accepted = 'ACCEPTED';

  static const String duplicateSuppressed = 'DUPLICATE_SUPPRESSED';

  static const String collisionFailClosed = 'COLLISION_FAIL_CLOSED';

  static const String invalidFailClosed = 'INVALID_FAIL_CLOSED';

  static const Set<String> values = <String>{
    accepted,
    duplicateSuppressed,
    collisionFailClosed,
    invalidFailClosed,
  };
}
