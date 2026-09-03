class AgentKnowledgeSourceType {
  AgentKnowledgeSourceType._();

  static const String helpFaq = 'help_faq';
  static const String policy = 'policy';
  static const String verifiedFeatureState = 'verified_feature_state';
  static const String serviceReference = 'service_reference';
  static const String safetyGuidance = 'safety_guidance';
  static const String partnerRoleGuidance = 'partner_role_guidance';
  static const String pricingPaymentReference = 'pricing_payment_reference';
  static const String videoEducationReference = 'video_education_reference';
  static const String approvedTrainingReference = 'approved_training_reference';
  static const String ownerAdminInternalReference =
      'owner_admin_internal_reference';
  static const String trustedExternalReference = 'trusted_external_reference';

  static const Set<String> values = <String>{
    helpFaq,
    policy,
    verifiedFeatureState,
    serviceReference,
    safetyGuidance,
    partnerRoleGuidance,
    pricingPaymentReference,
    videoEducationReference,
    approvedTrainingReference,
    ownerAdminInternalReference,
    trustedExternalReference,
  };
}

class AgentKnowledgeAuthorityClass {
  AgentKnowledgeAuthorityClass._();

  static const String systemVerified = 'system_verified';
  static const String ownerApproved = 'owner_approved';
  static const String adminApproved = 'admin_approved';
  static const String curatedInternal = 'curated_internal';
  static const String verifiedExternal = 'verified_external';

  static const Set<String> values = <String>{
    systemVerified,
    ownerApproved,
    adminApproved,
    curatedInternal,
    verifiedExternal,
  };
}

class AgentKnowledgeScope {
  AgentKnowledgeScope._();

  static const String public = 'public';
  static const String authenticatedCustomer = 'authenticated_customer';
  static const String driver = 'driver';
  static const String foodRider = 'food_rider';
  static const String restaurantPartner = 'restaurant_partner';
  static const String hotelPartner = 'hotel_partner';
  static const String tourismDriver = 'tourism_driver';
  static const String tourGuide = 'tour_guide';
  static const String studentParent = 'student_parent';
  static const String cargoDriver = 'cargo_driver';
  static const String parcelDriver = 'parcel_driver';
  static const String owner = 'owner';
  static const String admin = 'admin';
  static const String superAdmin = 'super_admin';
  static const String safetyRestricted = 'safety_restricted';
  static const String internalOnly = 'internal_only';

  static const Set<String> values = <String>{
    public,
    authenticatedCustomer,
    driver,
    foodRider,
    restaurantPartner,
    hotelPartner,
    tourismDriver,
    tourGuide,
    studentParent,
    cargoDriver,
    parcelDriver,
    owner,
    admin,
    superAdmin,
    safetyRestricted,
    internalOnly,
  };

  static const Set<String> privileged = <String>{
    owner,
    admin,
    superAdmin,
    safetyRestricted,
    internalOnly,
  };
}

class AgentKnowledgeLanguage {
  AgentKnowledgeLanguage._();

  static const String urdu = 'ur';
  static const String pashto = 'ps';
  static const String english = 'en';

  static const Set<String> values = <String>{urdu, pashto, english};
}

class AgentKnowledgeItemStatus {
  AgentKnowledgeItemStatus._();

  static const String draft = 'draft';
  static const String reviewRequired = 'review_required';
  static const String approvedActive = 'approved_active';
  static const String deprecated = 'deprecated';
  static const String rejected = 'rejected';
  static const String expired = 'expired';

  static const Set<String> values = <String>{
    draft,
    reviewRequired,
    approvedActive,
    deprecated,
    rejected,
    expired,
  };
}

class AgentKnowledgeContractStatus {
  AgentKnowledgeContractStatus._();

  static const String eligibleForLibraryIndexing =
      'ELIGIBLE_FOR_LIBRARY_INDEXING';
  static const String blockedInvalidStructure = 'BLOCKED_INVALID_STRUCTURE';
  static const String blockedUnverifiedSource = 'BLOCKED_UNVERIFIED_SOURCE';
  static const String blockedUnapprovedSource = 'BLOCKED_UNAPPROVED_SOURCE';
  static const String blockedInactiveSource = 'BLOCKED_INACTIVE_SOURCE';
  static const String blockedStaleSource = 'BLOCKED_STALE_SOURCE';
  static const String blockedItemNotApproved = 'BLOCKED_ITEM_NOT_APPROVED';
  static const String blockedVersionMismatch = 'BLOCKED_VERSION_MISMATCH';
  static const String blockedScopeConflict = 'BLOCKED_SCOPE_CONFLICT';
  static const String blockedNotEffective = 'BLOCKED_NOT_EFFECTIVE';
  static const String blockedExpired = 'BLOCKED_EXPIRED';

  static const Set<String> values = <String>{
    eligibleForLibraryIndexing,
    blockedInvalidStructure,
    blockedUnverifiedSource,
    blockedUnapprovedSource,
    blockedInactiveSource,
    blockedStaleSource,
    blockedItemNotApproved,
    blockedVersionMismatch,
    blockedScopeConflict,
    blockedNotEffective,
    blockedExpired,
  };
}

class AgentKnowledgeContractLimits {
  AgentKnowledgeContractLimits._();

  static const int idMax = 180;
  static const int titleMax = 300;
  static const int moduleMax = 120;
  static const int topicMax = 180;
  static const int versionMax = 1000000;
  static const int maxScopes = 16;
  static const int maxReasonCodes = 16;
}
