import '../constants/help_video_education_recommendation_constants.dart';

class HelpVideoEducationRecommendationDecision {
  HelpVideoEducationRecommendationDecision({
    required this.status,
    required this.tutorialId,
    required this.normalizedAudience,
    required this.normalizedLanguage,
    required this.matchedModule,
    required this.matchedFeature,
    required this.intentMatchCount,
    required List<String> reasonCodes,
  }) : reasonCodes = List<String>.unmodifiable(reasonCodes);

  final String status;
  final String tutorialId;
  final String normalizedAudience;
  final String normalizedLanguage;
  final bool matchedModule;
  final bool matchedFeature;
  final int intentMatchCount;
  final List<String> reasonCodes;

  bool get canRecommend =>
      status == HelpVideoEducationRecommendationStatus.recommended ||
      status ==
          HelpVideoEducationRecommendationStatus.recommendedLanguageFallback;

  bool get recommendationOnly => true;
  bool get executesTutorial => false;
  bool get opensExternalUrl => false;
  bool get generatesContent => false;
  bool get grantsAuthority => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get marksRuntimeAllowed => false;
  bool get invokesProvider => false;
  bool get writesBusinessData => false;
  bool get persistsDecision => false;

  void validateStructure() {
    if (!HelpVideoEducationRecommendationStatus.values.contains(status)) {
      throw const HelpVideoEducationRecommendationDecisionException(
        'Video education recommendation status is invalid.',
      );
    }

    if (tutorialId.trim().isEmpty || tutorialId.length > 180) {
      throw const HelpVideoEducationRecommendationDecisionException(
        'Video education recommendation tutorial ID is invalid.',
      );
    }

    if (intentMatchCount < 0 || intentMatchCount > 24) {
      throw const HelpVideoEducationRecommendationDecisionException(
        'Video education intent match count is invalid.',
      );
    }

    if (reasonCodes.isEmpty || reasonCodes.length > 10) {
      throw const HelpVideoEducationRecommendationDecisionException(
        'Video education recommendation reason codes are invalid.',
      );
    }

    for (final String reason in reasonCodes) {
      if (!HelpVideoEducationRecommendationReason.values.contains(reason)) {
        throw const HelpVideoEducationRecommendationDecisionException(
          'Video education recommendation reason code is invalid.',
        );
      }
    }
  }
}

class HelpVideoEducationRecommendationDecisionException implements Exception {
  const HelpVideoEducationRecommendationDecisionException(this.message);

  final String message;

  @override
  String toString() =>
      'HelpVideoEducationRecommendationDecisionException: $message';
}
