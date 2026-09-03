class HelpVideoEducationAdversarialStatus {
  HelpVideoEducationAdversarialStatus._();

  static const String safeToSurface = 'SAFE_TO_SURFACE';
  static const String blockedUnsafeAvailability = 'BLOCKED_UNSAFE_AVAILABILITY';
  static const String blockedBadLink = 'BLOCKED_BAD_LINK';
  static const String blockedTelemetry = 'BLOCKED_TELEMETRY';
  static const String failClosedDependencyFailure =
      'FAIL_CLOSED_DEPENDENCY_FAILURE';

  static const Set<String> values = <String>{
    safeToSurface,
    blockedUnsafeAvailability,
    blockedBadLink,
    blockedTelemetry,
    failClosedDependencyFailure,
  };
}

class HelpVideoEducationTelemetryEventType {
  HelpVideoEducationTelemetryEventType._();

  static const String surfaceAllowed = 'SURFACE_ALLOWED';
  static const String surfaceBlocked = 'SURFACE_BLOCKED';
  static const String openRequested = 'OPEN_REQUESTED';
  static const String completed = 'COMPLETED';
  static const String failureObserved = 'FAILURE_OBSERVED';

  static const Set<String> values = <String>{
    surfaceAllowed,
    surfaceBlocked,
    openRequested,
    completed,
    failureObserved,
  };
}

class HelpVideoEducationAdversarialReason {
  HelpVideoEducationAdversarialReason._();

  static const String existingSafeUrlPolicyReused =
      'existing_safe_url_policy_reused';
  static const String existingPlaybackPolicyReused =
      'existing_playback_policy_reused';
  static const String existingAnalyticsFoundationReused =
      'existing_analytics_foundation_reused';
  static const String step1eAvailabilityRequired =
      'step1e_availability_required';
  static const String safeUrlVerified = 'safe_url_verified';
  static const String badLinkBlocked = 'bad_link_blocked';
  static const String dependencyFailureIsolated = 'dependency_failure_isolated';
  static const String telemetryMetadataOnly = 'telemetry_metadata_only';
  static const String rawPrivateDataForbidden = 'raw_private_data_forbidden';
  static const String telemetryValidationPassed = 'telemetry_validation_passed';
  static const String telemetryValidationBlocked =
      'telemetry_validation_blocked';
  static const String noProviderExecution = 'no_provider_execution';
  static const String nonAuthoritativeContent = 'non_authoritative_content';

  static const Set<String> values = <String>{
    existingSafeUrlPolicyReused,
    existingPlaybackPolicyReused,
    existingAnalyticsFoundationReused,
    step1eAvailabilityRequired,
    safeUrlVerified,
    badLinkBlocked,
    dependencyFailureIsolated,
    telemetryMetadataOnly,
    rawPrivateDataForbidden,
    telemetryValidationPassed,
    telemetryValidationBlocked,
    noProviderExecution,
    nonAuthoritativeContent,
  };
}

class HelpVideoEducationAdversarialScenario {
  HelpVideoEducationAdversarialScenario._();

  static const String javascriptUrl = 'javascript_url';
  static const String dataUrl = 'data_url';
  static const String malformedUrl = 'malformed_url';
  static const String disabledCandidate = 'disabled_candidate';
  static const String unapprovedCandidate = 'unapproved_candidate';
  static const String outdatedCandidate = 'outdated_candidate';
  static const String unsafeRecommendationCandidate =
      'unsafe_recommendation_candidate';
  static const String providerFailure = 'provider_failure';
  static const String analyticsFailure = 'analytics_failure';
  static const String rawMessageTelemetry = 'raw_message_telemetry';
  static const String phoneTelemetry = 'phone_telemetry';
  static const String emailTelemetry = 'email_telemetry';
  static const String authTokenTelemetry = 'auth_token_telemetry';
  static const String paymentSecretTelemetry = 'payment_secret_telemetry';

  static const Set<String> values = <String>{
    javascriptUrl,
    dataUrl,
    malformedUrl,
    disabledCandidate,
    unapprovedCandidate,
    outdatedCandidate,
    unsafeRecommendationCandidate,
    providerFailure,
    analyticsFailure,
    rawMessageTelemetry,
    phoneTelemetry,
    emailTelemetry,
    authTokenTelemetry,
    paymentSecretTelemetry,
  };
}
