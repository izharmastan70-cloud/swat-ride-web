class HelpVideoEducationAvailabilityStatus {
  HelpVideoEducationAvailabilityStatus._();

  static const String available = 'AVAILABLE';
  static const String blockedRecommendation = 'BLOCKED_RECOMMENDATION';
  static const String blockedDisabled = 'BLOCKED_DISABLED';
  static const String blockedUnapproved = 'BLOCKED_UNAPPROVED';
  static const String blockedUnsafe = 'BLOCKED_UNSAFE';
  static const String blockedOutdated = 'BLOCKED_OUTDATED';

  static const Set<String> values = <String>{
    available,
    blockedRecommendation,
    blockedDisabled,
    blockedUnapproved,
    blockedUnsafe,
    blockedOutdated,
  };
}

class HelpVideoEducationAvailabilityReason {
  HelpVideoEducationAvailabilityReason._();

  static const String existingAdminControlReused =
      'existing_admin_control_reused';

  static const String existingVersionAwarenessReused =
      'existing_version_awareness_reused';

  static const String existingMaintenanceWorkflowReused =
      'existing_maintenance_workflow_reused';

  static const String step1cRecommendationRequired =
      'step1c_recommendation_required';

  static const String adminEnabled = 'admin_enabled';

  static const String adminDisabled = 'admin_disabled';

  static const String approvalVerified = 'approval_verified';

  static const String approvalMissing = 'approval_missing';

  static const String recommendationSafetyVerified =
      'recommendation_safety_verified';

  static const String recommendationSafetyBlocked =
      'recommendation_safety_blocked';

  static const String versionCurrent = 'version_current';

  static const String versionOutdated = 'version_outdated';

  static const String maintenanceReviewRequired = 'maintenance_review_required';

  static const String availabilityPolicyOnly = 'availability_policy_only';

  static const String nonAuthoritativeContent = 'non_authoritative_content';

  static const Set<String> values = <String>{
    existingAdminControlReused,
    existingVersionAwarenessReused,
    existingMaintenanceWorkflowReused,
    step1cRecommendationRequired,
    adminEnabled,
    adminDisabled,
    approvalVerified,
    approvalMissing,
    recommendationSafetyVerified,
    recommendationSafetyBlocked,
    versionCurrent,
    versionOutdated,
    maintenanceReviewRequired,
    availabilityPolicyOnly,
    nonAuthoritativeContent,
  };
}
