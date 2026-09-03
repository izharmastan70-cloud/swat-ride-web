class AgentContentDraftType {
  AgentContentDraftType._();

  static const String socialPost = 'social_post';
  static const String socialCaption = 'social_caption';
  static const String reelScript = 'reel_script';
  static const String shortScript = 'short_script';
  static const String storyScript = 'story_script';
  static const String videoScript = 'video_script';
  static const String videoShotPlan = 'video_shot_plan';
  static const String hookSet = 'hook_set';
  static const String carouselConcept = 'carousel_concept';
  static const String thumbnailConcept = 'thumbnail_concept';
  static const String educationalDraft = 'educational_draft';
  static const String promotionalDraft = 'promotional_draft';
  static const String serviceExplainer = 'service_explainer';
  static const String featureAnnouncement = 'feature_announcement';
  static const String localSeasonalCampaign = 'local_seasonal_campaign';
  static const String faqHelpDraft = 'faq_help_draft';
  static const String pushNotificationDraft = 'push_notification_draft';
  static const String emailDraft = 'email_draft';
  static const String whatsappDraft = 'whatsapp_draft';
  static const String adminAnnouncementDraft = 'admin_announcement_draft';

  static const Set<String> values = <String>{
    socialPost,
    socialCaption,
    reelScript,
    shortScript,
    storyScript,
    videoScript,
    videoShotPlan,
    hookSet,
    carouselConcept,
    thumbnailConcept,
    educationalDraft,
    promotionalDraft,
    serviceExplainer,
    featureAnnouncement,
    localSeasonalCampaign,
    faqHelpDraft,
    pushNotificationDraft,
    emailDraft,
    whatsappDraft,
    adminAnnouncementDraft,
  };

  static const Set<String> socialPlatformRequired = <String>{
    socialPost,
    socialCaption,
    reelScript,
    shortScript,
    storyScript,
    carouselConcept,
    thumbnailConcept,
  };
}

class AgentContentPlatform {
  AgentContentPlatform._();

  static const String none = 'none';
  static const String facebook = 'facebook';
  static const String instagram = 'instagram';
  static const String tiktok = 'tiktok';
  static const String youtube = 'youtube';

  static const Set<String> values = <String>{
    none,
    facebook,
    instagram,
    tiktok,
    youtube,
  };
}

class AgentContentLanguage {
  AgentContentLanguage._();

  static const String urdu = 'ur';
  static const String pashto = 'ps';
  static const String english = 'en';

  static const Set<String> values = <String>{urdu, pashto, english};
}

class AgentContentAudience {
  AgentContentAudience._();

  static const String customer = 'customer';
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
  static const String generalPublic = 'general_public';

  static const Set<String> values = <String>{
    customer,
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
    generalPublic,
  };
}

class AgentContentRequestStatus {
  AgentContentRequestStatus._();

  static const String acceptedDraftOnly = 'ACCEPTED_DRAFT_ONLY';
  static const String blockedInvalidRequest = 'BLOCKED_INVALID_REQUEST';
  static const String blockedUnsupportedDraftType =
      'BLOCKED_UNSUPPORTED_DRAFT_TYPE';
  static const String blockedUnsupportedPlatform =
      'BLOCKED_UNSUPPORTED_PLATFORM';
  static const String blockedUnsupportedAudience =
      'BLOCKED_UNSUPPORTED_AUDIENCE';
  static const String blockedUnsupportedLanguage =
      'BLOCKED_UNSUPPORTED_LANGUAGE';
  static const String blockedMissingSocialPlatform =
      'BLOCKED_MISSING_SOCIAL_PLATFORM';
  static const String blockedSensitiveExecutionIntent =
      'BLOCKED_SENSITIVE_EXECUTION_INTENT';

  static const Set<String> values = <String>{
    acceptedDraftOnly,
    blockedInvalidRequest,
    blockedUnsupportedDraftType,
    blockedUnsupportedPlatform,
    blockedUnsupportedAudience,
    blockedUnsupportedLanguage,
    blockedMissingSocialPlatform,
    blockedSensitiveExecutionIntent,
  };
}

class AgentContentReviewChannel {
  AgentContentReviewChannel._();

  static const String inApp = 'in_app';
  static const String ownerWhatsApp = 'owner_whatsapp';

  static const Set<String> values = <String>{inApp, ownerWhatsApp};
}

class AgentContentReviewState {
  AgentContentReviewState._();

  static const String requestReceived = 'REQUEST_RECEIVED';
  static const String draftPending = 'DRAFT_PENDING';
  static const String reviewRequired = 'REVIEW_REQUIRED';

  static const Set<String> values = <String>{
    requestReceived,
    draftPending,
    reviewRequired,
  };
}

class AgentContentContractLimits {
  AgentContentContractLimits._();

  static const int requestIdMax = 180;
  static const int moduleMax = 100;
  static const int featureMax = 120;
  static const int purposeMax = 500;
  static const int briefMax = 2000;
  static const int sourceReferenceMax = 20;
  static const int sourceReferenceLengthMax = 180;
  static const int requestedMaxOutputChars = 12000;
}
