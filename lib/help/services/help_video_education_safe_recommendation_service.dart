import '../constants/help_video_education_contract_constants.dart';
import '../constants/help_video_education_recommendation_constants.dart';
import '../models/help_video_education_recommendation_decision.dart';
import '../models/help_video_tutorial_model.dart';
import 'help_video_education_catalog_contract_service.dart';

class HelpVideoEducationSafeRecommendationService {
  const HelpVideoEducationSafeRecommendationService({
    HelpVideoEducationCatalogContractService? catalogContractService,
  }) : _catalogContractService =
           catalogContractService ??
           const HelpVideoEducationCatalogContractService();

  final HelpVideoEducationCatalogContractService _catalogContractService;

  HelpVideoEducationRecommendationDecision evaluateTutorial({
    required HelpVideoTutorialModel tutorial,
    required String requestedAudience,
    required String requestedLanguage,
    required String requestedModule,
    required String requestedFeature,
    required List<String> requestedIntents,
  }) {
    return evaluateCandidateMetadata(
      tutorialId: tutorial.id,
      title: tutorial.title,
      module: tutorial.module,
      feature: tutorial.feature,
      audience: tutorial.audience,
      language: tutorial.language,
      keywords: tutorial.keywords,
      intents: tutorial.intents,
      requestedAudience: requestedAudience,
      requestedLanguage: requestedLanguage,
      requestedModule: requestedModule,
      requestedFeature: requestedFeature,
      requestedIntents: requestedIntents,
    );
  }

  HelpVideoEducationRecommendationDecision evaluateCandidateMetadata({
    required String tutorialId,
    required String title,
    required String module,
    required String feature,
    required String audience,
    required String language,
    required List<String> keywords,
    required List<String> intents,
    required String requestedAudience,
    required String requestedLanguage,
    required String requestedModule,
    required String requestedFeature,
    required List<String> requestedIntents,
  }) {
    final String normalizedRequestedAudience = _catalogContractService
        .normalizeAudience(requestedAudience);

    final String normalizedRequestedLanguage = _catalogContractService
        .normalizeLanguage(requestedLanguage);

    final String normalizedRequestedModule = _normalize(requestedModule);

    final String normalizedRequestedFeature = _normalize(requestedFeature);

    final Set<String> normalizedRequestedIntents = requestedIntents
        .map(_normalize)
        .where((String value) => value.isNotEmpty)
        .take(24)
        .toSet();

    final bool validRequest =
        HelpVideoEducationAudience.values.contains(
          normalizedRequestedAudience,
        ) &&
        HelpVideoEducationLanguage.values.contains(
          normalizedRequestedLanguage,
        ) &&
        (normalizedRequestedModule.isNotEmpty ||
            normalizedRequestedFeature.isNotEmpty ||
            normalizedRequestedIntents.isNotEmpty);

    if (!validRequest) {
      return _decision(
        status: HelpVideoEducationRecommendationStatus.blockedInvalidRequest,
        tutorialId: _safeTutorialId(tutorialId),
        audience: _safeAudience(normalizedRequestedAudience),
        language: _safeLanguage(normalizedRequestedLanguage),
        matchedModule: false,
        matchedFeature: false,
        intentMatchCount: 0,
        reasons: const <String>[
          HelpVideoEducationRecommendationReason
              .existingContextualRankingReused,
          HelpVideoEducationRecommendationReason.invalidRequest,
          HelpVideoEducationRecommendationReason.recommendationOnly,
          HelpVideoEducationRecommendationReason.nonAuthoritativeContent,
        ],
      );
    }

    final catalogDecision = _catalogContractService.evaluateMetadata(
      tutorialId: tutorialId,
      title: title,
      module: module,
      feature: feature,
      audience: audience,
      language: language,
      keywords: keywords,
      intents: intents,
    );

    if (!catalogDecision.catalogEligible) {
      return _decision(
        status: HelpVideoEducationRecommendationStatus.blockedCatalog,
        tutorialId: catalogDecision.tutorialId,
        audience: normalizedRequestedAudience,
        language: normalizedRequestedLanguage,
        matchedModule: false,
        matchedFeature: false,
        intentMatchCount: 0,
        reasons: const <String>[
          HelpVideoEducationRecommendationReason
              .existingContextualRankingReused,
          HelpVideoEducationRecommendationReason.catalogBlocked,
          HelpVideoEducationRecommendationReason.recommendationOnly,
          HelpVideoEducationRecommendationReason.nonAuthoritativeContent,
        ],
      );
    }

    final bool audienceMatches =
        catalogDecision.normalizedAudience == HelpVideoEducationAudience.all ||
        normalizedRequestedAudience == HelpVideoEducationAudience.all ||
        catalogDecision.normalizedAudience == normalizedRequestedAudience;

    if (!audienceMatches) {
      return _decision(
        status: HelpVideoEducationRecommendationStatus.blockedAudienceMismatch,
        tutorialId: catalogDecision.tutorialId,
        audience: normalizedRequestedAudience,
        language: normalizedRequestedLanguage,
        matchedModule: false,
        matchedFeature: false,
        intentMatchCount: 0,
        reasons: const <String>[
          HelpVideoEducationRecommendationReason
              .existingContextualRankingReused,
          HelpVideoEducationRecommendationReason.candidateCatalogEligible,
          HelpVideoEducationRecommendationReason.audienceMismatch,
          HelpVideoEducationRecommendationReason.recommendationOnly,
          HelpVideoEducationRecommendationReason.nonAuthoritativeContent,
        ],
      );
    }

    final bool candidateLanguageUnspecified =
        catalogDecision.normalizedLanguage ==
        HelpVideoEducationLanguage.unspecified;

    final bool requestedLanguageUnspecified =
        normalizedRequestedLanguage == HelpVideoEducationLanguage.unspecified;

    final bool languageMatches =
        candidateLanguageUnspecified ||
        requestedLanguageUnspecified ||
        catalogDecision.normalizedLanguage == normalizedRequestedLanguage;

    if (!languageMatches) {
      return _decision(
        status: HelpVideoEducationRecommendationStatus.blockedLanguageMismatch,
        tutorialId: catalogDecision.tutorialId,
        audience: normalizedRequestedAudience,
        language: normalizedRequestedLanguage,
        matchedModule: false,
        matchedFeature: false,
        intentMatchCount: 0,
        reasons: const <String>[
          HelpVideoEducationRecommendationReason
              .existingContextualRankingReused,
          HelpVideoEducationRecommendationReason.candidateCatalogEligible,
          HelpVideoEducationRecommendationReason.audienceMatched,
          HelpVideoEducationRecommendationReason.languageMismatch,
          HelpVideoEducationRecommendationReason.recommendationOnly,
          HelpVideoEducationRecommendationReason.nonAuthoritativeContent,
        ],
      );
    }

    final String candidateModule = _normalize(module);
    final String candidateFeature = _normalize(feature);

    final Set<String> candidateIntents = <String>{
      ...intents.map(_normalize),
      ...keywords.map(_normalize),
    }..removeWhere((String value) => value.isEmpty);

    final bool matchedModule =
        normalizedRequestedModule.isNotEmpty &&
        candidateModule == normalizedRequestedModule;

    final bool matchedFeature =
        normalizedRequestedFeature.isNotEmpty &&
        candidateFeature == normalizedRequestedFeature;

    final int intentMatchCount = candidateIntents
        .intersection(normalizedRequestedIntents)
        .length;

    final bool contextMatches =
        matchedModule || matchedFeature || intentMatchCount > 0;

    if (!contextMatches) {
      return _decision(
        status: HelpVideoEducationRecommendationStatus.blockedContextMismatch,
        tutorialId: catalogDecision.tutorialId,
        audience: normalizedRequestedAudience,
        language: normalizedRequestedLanguage,
        matchedModule: matchedModule,
        matchedFeature: matchedFeature,
        intentMatchCount: intentMatchCount,
        reasons: const <String>[
          HelpVideoEducationRecommendationReason
              .existingContextualRankingReused,
          HelpVideoEducationRecommendationReason.candidateCatalogEligible,
          HelpVideoEducationRecommendationReason.audienceMatched,
          HelpVideoEducationRecommendationReason.contextMismatch,
          HelpVideoEducationRecommendationReason.recommendationOnly,
          HelpVideoEducationRecommendationReason.nonAuthoritativeContent,
        ],
      );
    }

    final bool languageFallback =
        candidateLanguageUnspecified || requestedLanguageUnspecified;

    return _decision(
      status: languageFallback
          ? HelpVideoEducationRecommendationStatus.recommendedLanguageFallback
          : HelpVideoEducationRecommendationStatus.recommended,
      tutorialId: catalogDecision.tutorialId,
      audience: normalizedRequestedAudience,
      language: normalizedRequestedLanguage,
      matchedModule: matchedModule,
      matchedFeature: matchedFeature,
      intentMatchCount: intentMatchCount,
      reasons: <String>[
        HelpVideoEducationRecommendationReason.existingContextualRankingReused,
        HelpVideoEducationRecommendationReason.candidateCatalogEligible,
        HelpVideoEducationRecommendationReason.audienceMatched,
        if (languageFallback)
          HelpVideoEducationRecommendationReason.languageFallbackUsed
        else
          HelpVideoEducationRecommendationReason.languageMatched,
        if (matchedModule) HelpVideoEducationRecommendationReason.moduleMatched,
        if (matchedFeature)
          HelpVideoEducationRecommendationReason.featureMatched,
        if (intentMatchCount > 0)
          HelpVideoEducationRecommendationReason.intentMatched,
        HelpVideoEducationRecommendationReason.recommendationOnly,
        HelpVideoEducationRecommendationReason.nonAuthoritativeContent,
      ],
    );
  }

  HelpVideoEducationRecommendationDecision _decision({
    required String status,
    required String tutorialId,
    required String audience,
    required String language,
    required bool matchedModule,
    required bool matchedFeature,
    required int intentMatchCount,
    required List<String> reasons,
  }) {
    final HelpVideoEducationRecommendationDecision decision =
        HelpVideoEducationRecommendationDecision(
          status: status,
          tutorialId: tutorialId,
          normalizedAudience: audience,
          normalizedLanguage: language,
          matchedModule: matchedModule,
          matchedFeature: matchedFeature,
          intentMatchCount: intentMatchCount,
          reasonCodes: reasons,
        );

    decision.validateStructure();
    return decision;
  }

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_');
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

  String _safeAudience(String value) {
    if (HelpVideoEducationAudience.values.contains(value)) {
      return value;
    }

    return HelpVideoEducationAudience.all;
  }

  String _safeLanguage(String value) {
    if (HelpVideoEducationLanguage.values.contains(value)) {
      return value;
    }

    return HelpVideoEducationLanguage.unspecified;
  }

  bool get reusesExistingContextualVideoGuideService => true;
  bool get implementsDuplicateScoringEngine => false;
  bool get recommendationSafetyGateOnly => true;
  bool get executesTutorial => false;
  bool get opensExternalUrl => false;
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
  bool get persistsRecommendation => false;
  bool get implementsPhase56ContentGeneration => false;
  bool get implementsPhase57KnowledgeLibrary => false;
  bool get implementsPhase63PrivacyUi => false;
}
