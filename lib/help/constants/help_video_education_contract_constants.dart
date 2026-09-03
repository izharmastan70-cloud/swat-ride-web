class HelpVideoEducationAudience {
  HelpVideoEducationAudience._();

  static const String all = 'all';
  static const String customer = 'customer';
  static const String driver = 'driver';
  static const String partner = 'partner';
  static const String owner = 'owner';
  static const String admin = 'admin';
  static const String superAdmin = 'super_admin';
  static const String support = 'support';
  static const String staff = 'staff';
  static const String restaurantPartner = 'restaurant_partner';
  static const String foodRider = 'food_rider';
  static const String hotelPartner = 'hotel_partner';
  static const String tourismDriver = 'tourism_driver';
  static const String tourGuide = 'tour_guide';
  static const String studentParent = 'student_parent';
  static const String cargoDriver = 'cargo_driver';
  static const String parcelDriver = 'parcel_driver';

  static const Set<String> values = <String>{
    all,
    customer,
    driver,
    partner,
    owner,
    admin,
    superAdmin,
    support,
    staff,
    restaurantPartner,
    foodRider,
    hotelPartner,
    tourismDriver,
    tourGuide,
    studentParent,
    cargoDriver,
    parcelDriver,
  };
}

class HelpVideoEducationLanguage {
  HelpVideoEducationLanguage._();

  static const String urdu = 'ur';
  static const String pashto = 'ps';
  static const String english = 'en';
  static const String unspecified = 'und';

  static const Set<String> values = <String>{
    urdu,
    pashto,
    english,
    unspecified,
  };
}

class HelpVideoEducationCatalogStatus {
  HelpVideoEducationCatalogStatus._();

  static const String eligible = 'ELIGIBLE';

  static const String eligibleLanguageFallback = 'ELIGIBLE_LANGUAGE_FALLBACK';

  static const String blockedInvalidMetadata = 'BLOCKED_INVALID_METADATA';

  static const String blockedUnsupportedAudience =
      'BLOCKED_UNSUPPORTED_AUDIENCE';

  static const String blockedUnsupportedLanguage =
      'BLOCKED_UNSUPPORTED_LANGUAGE';

  static const Set<String> values = <String>{
    eligible,
    eligibleLanguageFallback,
    blockedInvalidMetadata,
    blockedUnsupportedAudience,
    blockedUnsupportedLanguage,
  };
}

class HelpVideoEducationCatalogReason {
  HelpVideoEducationCatalogReason._();

  static const String existingTutorialModelReused =
      'existing_tutorial_model_reused';

  static const String metadataValidated = 'metadata_validated';

  static const String audienceSupported = 'audience_supported';

  static const String languageSupported = 'language_supported';

  static const String languageFallbackRequired = 'language_fallback_required';

  static const String invalidMetadata = 'invalid_metadata';

  static const String unsupportedAudience = 'unsupported_audience';

  static const String unsupportedLanguage = 'unsupported_language';

  static const String catalogOnly = 'catalog_only';

  static const String nonAuthoritativeContent = 'non_authoritative_content';

  static const Set<String> values = <String>{
    existingTutorialModelReused,
    metadataValidated,
    audienceSupported,
    languageSupported,
    languageFallbackRequired,
    invalidMetadata,
    unsupportedAudience,
    unsupportedLanguage,
    catalogOnly,
    nonAuthoritativeContent,
  };
}
