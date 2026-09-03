import '../constants/help_video_education_contract_constants.dart';
import '../models/help_video_education_catalog_decision.dart';
import '../models/help_video_tutorial_model.dart';

class HelpVideoEducationCatalogContractService {
  const HelpVideoEducationCatalogContractService();

  HelpVideoEducationCatalogDecision evaluateTutorial(
    HelpVideoTutorialModel tutorial,
  ) {
    return evaluateMetadata(
      tutorialId: tutorial.id,
      title: tutorial.title,
      module: tutorial.module,
      feature: tutorial.feature,
      audience: tutorial.audience,
      language: tutorial.language,
      keywords: tutorial.keywords,
      intents: tutorial.intents,
    );
  }

  HelpVideoEducationCatalogDecision evaluateMetadata({
    required String tutorialId,
    required String title,
    required String module,
    required String feature,
    required String audience,
    required String language,
    required List<String> keywords,
    required List<String> intents,
  }) {
    final String normalizedAudience = normalizeAudience(audience);
    final String normalizedLanguage = normalizeLanguage(language);

    final bool validMetadata =
        _validRequiredText(tutorialId, maxLength: 180) &&
        _validRequiredText(title, maxLength: 180) &&
        _validRequiredText(module, maxLength: 100) &&
        _validRequiredText(feature, maxLength: 120) &&
        _validBoundedTerms(keywords) &&
        _validBoundedTerms(intents);

    if (!validMetadata) {
      return _decision(
        status: HelpVideoEducationCatalogStatus.blockedInvalidMetadata,
        tutorialId: _safeTutorialId(tutorialId),
        audience: _fallbackAudience(normalizedAudience),
        language: _fallbackLanguage(normalizedLanguage),
        reasons: const <String>[
          HelpVideoEducationCatalogReason.existingTutorialModelReused,
          HelpVideoEducationCatalogReason.invalidMetadata,
          HelpVideoEducationCatalogReason.catalogOnly,
          HelpVideoEducationCatalogReason.nonAuthoritativeContent,
        ],
      );
    }

    if (!HelpVideoEducationAudience.values.contains(normalizedAudience)) {
      return _decision(
        status: HelpVideoEducationCatalogStatus.blockedUnsupportedAudience,
        tutorialId: tutorialId.trim(),
        audience: HelpVideoEducationAudience.all,
        language: _fallbackLanguage(normalizedLanguage),
        reasons: const <String>[
          HelpVideoEducationCatalogReason.existingTutorialModelReused,
          HelpVideoEducationCatalogReason.unsupportedAudience,
          HelpVideoEducationCatalogReason.catalogOnly,
          HelpVideoEducationCatalogReason.nonAuthoritativeContent,
        ],
      );
    }

    if (!HelpVideoEducationLanguage.values.contains(normalizedLanguage)) {
      return _decision(
        status: HelpVideoEducationCatalogStatus.blockedUnsupportedLanguage,
        tutorialId: tutorialId.trim(),
        audience: normalizedAudience,
        language: HelpVideoEducationLanguage.unspecified,
        reasons: const <String>[
          HelpVideoEducationCatalogReason.existingTutorialModelReused,
          HelpVideoEducationCatalogReason.audienceSupported,
          HelpVideoEducationCatalogReason.unsupportedLanguage,
          HelpVideoEducationCatalogReason.catalogOnly,
          HelpVideoEducationCatalogReason.nonAuthoritativeContent,
        ],
      );
    }

    if (normalizedLanguage == HelpVideoEducationLanguage.unspecified) {
      return _decision(
        status: HelpVideoEducationCatalogStatus.eligibleLanguageFallback,
        tutorialId: tutorialId.trim(),
        audience: normalizedAudience,
        language: normalizedLanguage,
        reasons: const <String>[
          HelpVideoEducationCatalogReason.existingTutorialModelReused,
          HelpVideoEducationCatalogReason.metadataValidated,
          HelpVideoEducationCatalogReason.audienceSupported,
          HelpVideoEducationCatalogReason.languageFallbackRequired,
          HelpVideoEducationCatalogReason.catalogOnly,
          HelpVideoEducationCatalogReason.nonAuthoritativeContent,
        ],
      );
    }

    return _decision(
      status: HelpVideoEducationCatalogStatus.eligible,
      tutorialId: tutorialId.trim(),
      audience: normalizedAudience,
      language: normalizedLanguage,
      reasons: const <String>[
        HelpVideoEducationCatalogReason.existingTutorialModelReused,
        HelpVideoEducationCatalogReason.metadataValidated,
        HelpVideoEducationCatalogReason.audienceSupported,
        HelpVideoEducationCatalogReason.languageSupported,
        HelpVideoEducationCatalogReason.catalogOnly,
        HelpVideoEducationCatalogReason.nonAuthoritativeContent,
      ],
    );
  }

  String normalizeAudience(String value) {
    final String normalized = value.trim().toLowerCase().replaceAll(
      RegExp(r'[\s-]+'),
      '_',
    );

    const Map<String, String> aliases = <String, String>{
      'rider': HelpVideoEducationAudience.customer,
      'user': HelpVideoEducationAudience.customer,
      'restaurant_owner': HelpVideoEducationAudience.restaurantPartner,
      'food_delivery_rider': HelpVideoEducationAudience.foodRider,
      'hotel_owner': HelpVideoEducationAudience.hotelPartner,
      'tourism_driver': HelpVideoEducationAudience.tourismDriver,
      'tour_guide': HelpVideoEducationAudience.tourGuide,
      'parent': HelpVideoEducationAudience.studentParent,
      'guardian': HelpVideoEducationAudience.studentParent,
      'superadmin': HelpVideoEducationAudience.superAdmin,
      'support_agent': HelpVideoEducationAudience.support,
    };

    return aliases[normalized] ?? normalized;
  }

  String normalizeLanguage(String value) {
    final String normalized = value.trim().toLowerCase().replaceAll('_', '-');

    const Map<String, String> aliases = <String, String>{
      'ur': HelpVideoEducationLanguage.urdu,
      'urdu': HelpVideoEducationLanguage.urdu,
      'ur-pk': HelpVideoEducationLanguage.urdu,
      'ps': HelpVideoEducationLanguage.pashto,
      'pashto': HelpVideoEducationLanguage.pashto,
      'pushto': HelpVideoEducationLanguage.pashto,
      'ps-pk': HelpVideoEducationLanguage.pashto,
      'en': HelpVideoEducationLanguage.english,
      'english': HelpVideoEducationLanguage.english,
      'en-us': HelpVideoEducationLanguage.english,
      'en-gb': HelpVideoEducationLanguage.english,
      'und': HelpVideoEducationLanguage.unspecified,
      'unknown': HelpVideoEducationLanguage.unspecified,
      'unspecified': HelpVideoEducationLanguage.unspecified,
      '': HelpVideoEducationLanguage.unspecified,
    };

    return aliases[normalized] ?? normalized;
  }

  HelpVideoEducationCatalogDecision _decision({
    required String status,
    required String tutorialId,
    required String audience,
    required String language,
    required List<String> reasons,
  }) {
    final HelpVideoEducationCatalogDecision decision =
        HelpVideoEducationCatalogDecision(
          status: status,
          tutorialId: tutorialId,
          normalizedAudience: audience,
          normalizedLanguage: language,
          reasonCodes: reasons,
        );

    decision.validateStructure();
    return decision;
  }

  bool _validRequiredText(String value, {required int maxLength}) {
    final String trimmed = value.trim();

    if (trimmed.isEmpty || trimmed.length > maxLength) {
      return false;
    }

    return !RegExp(r'[\u0000-\u001F]').hasMatch(trimmed);
  }

  bool _validBoundedTerms(List<String> values) {
    if (values.length > 24) {
      return false;
    }

    for (final String value in values) {
      final String trimmed = value.trim();

      if (trimmed.isEmpty ||
          trimmed.length > 80 ||
          RegExp(r'[\u0000-\u001F]').hasMatch(trimmed)) {
        return false;
      }
    }

    return true;
  }

  String _safeTutorialId(String value) {
    final String trimmed = value.trim();

    if (trimmed.isEmpty) {
      return 'invalid_tutorial';
    }

    if (trimmed.length <= 180) {
      return trimmed;
    }

    return trimmed.substring(0, 180);
  }

  String _fallbackAudience(String value) {
    if (HelpVideoEducationAudience.values.contains(value)) {
      return value;
    }

    return HelpVideoEducationAudience.all;
  }

  String _fallbackLanguage(String value) {
    if (HelpVideoEducationLanguage.values.contains(value)) {
      return value;
    }

    return HelpVideoEducationLanguage.unspecified;
  }

  bool get reusesExistingTutorialModel => true;
  bool get createsDuplicateVideoItemModel => false;
  bool get catalogMetadataOnly => true;
  bool get performsRecommendationRanking => false;
  bool get generatesContent => false;
  bool get invokesProvider => false;
  bool get grantsAuthority => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get marksRuntimeAllowed => false;
  bool get invokesPermissionEngine => false;
  bool get invokesApprovalEngine => false;
  bool get invokesRuntimeGate => false;
  bool get invokesEmergencyStop => false;
  bool get writesBusinessData => false;
  bool get persistsCatalogDecision => false;
  bool get implementsPhase56ContentGeneration => false;
  bool get implementsPhase57KnowledgeLibrary => false;
  bool get implementsPhase63PrivacyUi => false;
}
