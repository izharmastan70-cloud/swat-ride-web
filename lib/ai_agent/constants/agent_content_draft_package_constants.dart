class AgentContentHookType {
  AgentContentHookType._();

  static const String problem = 'problem';
  static const String question = 'question';
  static const String curiosity = 'curiosity';
  static const String benefit = 'benefit';
  static const String localRelevance = 'local_relevance';
  static const String featureDemonstration = 'feature_demonstration';
  static const String story = 'story';
  static const String truthfulBeforeAfter = 'truthful_before_after';

  static const Set<String> values = <String>{
    problem,
    question,
    curiosity,
    benefit,
    localRelevance,
    featureDemonstration,
    story,
    truthfulBeforeAfter,
  };
}

class AgentContentShotType {
  AgentContentShotType._();

  static const String wide = 'wide';
  static const String establishing = 'establishing';
  static const String medium = 'medium';
  static const String closeUp = 'close_up';
  static const String pov = 'pov';
  static const String vehicleService = 'vehicle_service';
  static const String location = 'location';
  static const String foodDetail = 'food_detail';
  static const String hotelTour = 'hotel_tour';
  static const String phoneAppDemo = 'phone_app_demo';
  static const String screenRecording = 'screen_recording';

  static const Set<String> values = <String>{
    wide,
    establishing,
    medium,
    closeUp,
    pov,
    vehicleService,
    location,
    foodDetail,
    hotelTour,
    phoneAppDemo,
    screenRecording,
  };
}

class AgentContentVisualSource {
  AgentContentVisualSource._();

  static const String realAppUi = 'real_app_ui';
  static const String realVehicle = 'real_vehicle';
  static const String realSwatLocation = 'real_swat_location';
  static const String approvedPartnerAsset = 'approved_partner_asset';
  static const String approvedCompanyAsset = 'approved_company_asset';
  static const String realServiceFootage = 'real_service_footage';
  static const String screenRecording = 'screen_recording';
  static const String aiSupplementary = 'ai_supplementary';

  static const Set<String> values = <String>{
    realAppUi,
    realVehicle,
    realSwatLocation,
    approvedPartnerAsset,
    approvedCompanyAsset,
    realServiceFootage,
    screenRecording,
    aiSupplementary,
  };

  static const Set<String> realOrApproved = <String>{
    realAppUi,
    realVehicle,
    realSwatLocation,
    approvedPartnerAsset,
    approvedCompanyAsset,
    realServiceFootage,
    screenRecording,
  };
}

class AgentContentDraftPackageStatus {
  AgentContentDraftPackageStatus._();

  static const String readyForHumanReview = 'READY_FOR_HUMAN_REVIEW';
  static const String blockedRequestNotAccepted =
      'BLOCKED_REQUEST_NOT_ACCEPTED';
  static const String blockedPlatformRequired = 'BLOCKED_PLATFORM_REQUIRED';
  static const String blockedPlatformDraftMismatch =
      'BLOCKED_PLATFORM_DRAFT_MISMATCH';
  static const String blockedInvalidCreativeStructure =
      'BLOCKED_INVALID_CREATIVE_STRUCTURE';
  static const String blockedUnsafeMarketingIntent =
      'BLOCKED_UNSAFE_MARKETING_INTENT';
  static const String blockedNoAuthenticVisualPlan =
      'BLOCKED_NO_AUTHENTIC_VISUAL_PLAN';

  static const Set<String> values = <String>{
    readyForHumanReview,
    blockedRequestNotAccepted,
    blockedPlatformRequired,
    blockedPlatformDraftMismatch,
    blockedInvalidCreativeStructure,
    blockedUnsafeMarketingIntent,
    blockedNoAuthenticVisualPlan,
  };
}

class AgentContentPackageLimits {
  AgentContentPackageLimits._();

  static const int problemMax = 500;
  static const int solutionMax = 700;
  static const int benefitMax = 500;
  static const int hookMax = 300;
  static const int primaryTextMax = 12000;
  static const int ctaMax = 300;
  static const int sceneCountMax = 16;
  static const int sceneTextMax = 700;
  static const int sceneDurationSecondsMax = 180;
}
