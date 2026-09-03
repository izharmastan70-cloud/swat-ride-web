class AgentContentGroundingStatus {
  AgentContentGroundingStatus._();

  static const String groundedReadyForHumanReview =
      'GROUNDED_READY_FOR_HUMAN_REVIEW';
  static const String blockedStep1CPackage = 'BLOCKED_STEP1C_PACKAGE';
  static const String blockedUnverifiedFeature = 'BLOCKED_UNVERIFIED_FEATURE';
  static const String blockedUnstableFeature = 'BLOCKED_UNSTABLE_FEATURE';
  static const String blockedUnapprovedFeature = 'BLOCKED_UNAPPROVED_FEATURE';
  static const String blockedServiceDisabled = 'BLOCKED_SERVICE_DISABLED';
  static const String blockedSourceStale = 'BLOCKED_SOURCE_STALE';
  static const String needsSource = 'NEEDS_SOURCE';
  static const String blockedUnsupportedClaim = 'BLOCKED_UNSUPPORTED_CLAIM';

  static const Set<String> values = <String>{
    groundedReadyForHumanReview,
    blockedStep1CPackage,
    blockedUnverifiedFeature,
    blockedUnstableFeature,
    blockedUnapprovedFeature,
    blockedServiceDisabled,
    blockedSourceStale,
    needsSource,
    blockedUnsupportedClaim,
  };
}

class AgentContentVerifiedClaimKey {
  AgentContentVerifiedClaimKey._();

  static const String featureExists = 'feature_exists';
  static const String featureEnabled = 'feature_enabled';
  static const String serviceEnabled = 'service_enabled';
  static const String serviceAvailability = 'service_availability';
  static const String serviceArea = 'service_area';
  static const String price = 'price';
  static const String discountOffer = 'discount_offer';
  static const String paymentMethod = 'payment_method';
  static const String safetyFeature = 'safety_feature';
  static const String policy = 'policy';
  static const String statistic = 'statistic';
  static const String driverEarnings = 'driver_earnings';
  static const String partnerBenefit = 'partner_benefit';

  static const Set<String> values = <String>{
    featureExists,
    featureEnabled,
    serviceEnabled,
    serviceAvailability,
    serviceArea,
    price,
    discountOffer,
    paymentMethod,
    safetyFeature,
    policy,
    statistic,
    driverEarnings,
    partnerBenefit,
  };

  static const Set<String> highSensitivity = <String>{
    serviceAvailability,
    serviceArea,
    price,
    discountOffer,
    paymentMethod,
    safetyFeature,
    policy,
    statistic,
    driverEarnings,
  };
}

class AgentContentGroundingLimits {
  AgentContentGroundingLimits._();

  static const int sourceReferenceMax = 20;
  static const int sourceReferenceLengthMax = 180;
  static const int claimCountMax = 20;
}

class AgentContentGroundingReason {
  AgentContentGroundingReason._();

  static const String step1CReadyRequired = 'step1c_ready_required';
  static const String verifiedFeatureRequired = 'verified_feature_required';
  static const String stableFeatureRequired = 'stable_feature_required';
  static const String communicationApprovalRequired =
      'communication_approval_required';
  static const String enabledServiceRequired = 'enabled_service_required';
  static const String freshSourceRequired = 'fresh_source_required';
  static const String verifiedSourceReferenceRequired =
      'verified_source_reference_required';
  static const String declaredClaimsRequired = 'declared_claims_required';
  static const String allClaimsMustBeVerified = 'all_claims_must_be_verified';
  static const String unsupportedClaimBlocked = 'unsupported_claim_blocked';
  static const String existingGroundingReused = 'existing_grounding_reused';
  static const String existingQualityReused = 'existing_quality_reused';
  static const String existingResponseGuardReused =
      'existing_response_guard_reused';
  static const String humanReviewRequired = 'human_review_required';
  static const String noGeneratedFactAuthority = 'no_generated_fact_authority';
  static const String noPublishAuthority = 'no_publish_authority';

  static const Set<String> values = <String>{
    step1CReadyRequired,
    verifiedFeatureRequired,
    stableFeatureRequired,
    communicationApprovalRequired,
    enabledServiceRequired,
    freshSourceRequired,
    verifiedSourceReferenceRequired,
    declaredClaimsRequired,
    allClaimsMustBeVerified,
    unsupportedClaimBlocked,
    existingGroundingReused,
    existingQualityReused,
    existingResponseGuardReused,
    humanReviewRequired,
    noGeneratedFactAuthority,
    noPublishAuthority,
  };
}
