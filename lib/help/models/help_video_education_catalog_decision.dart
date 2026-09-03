import '../constants/help_video_education_contract_constants.dart';

class HelpVideoEducationCatalogDecision {
  HelpVideoEducationCatalogDecision({
    required this.status,
    required this.tutorialId,
    required this.normalizedAudience,
    required this.normalizedLanguage,
    required List<String> reasonCodes,
  }) : reasonCodes = List<String>.unmodifiable(reasonCodes);

  final String status;
  final String tutorialId;
  final String normalizedAudience;
  final String normalizedLanguage;
  final List<String> reasonCodes;

  bool get catalogEligible =>
      status == HelpVideoEducationCatalogStatus.eligible ||
      status == HelpVideoEducationCatalogStatus.eligibleLanguageFallback;

  bool get requiresLanguageFallback =>
      status == HelpVideoEducationCatalogStatus.eligibleLanguageFallback;

  bool get catalogMetadataOnly => true;
  bool get performsRecommendationRanking => false;
  bool get generatesContent => false;
  bool get grantsAuthority => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get marksRuntimeAllowed => false;
  bool get invokesProvider => false;
  bool get writesBusinessData => false;
  bool get persistsDecision => false;

  void validateStructure() {
    if (!HelpVideoEducationCatalogStatus.values.contains(status)) {
      throw const HelpVideoEducationCatalogDecisionException(
        'Video education catalog status is invalid.',
      );
    }

    if (tutorialId.trim().isEmpty || tutorialId.length > 180) {
      throw const HelpVideoEducationCatalogDecisionException(
        'Video education tutorial ID is invalid.',
      );
    }

    if (!HelpVideoEducationAudience.values.contains(normalizedAudience)) {
      throw const HelpVideoEducationCatalogDecisionException(
        'Video education audience is invalid.',
      );
    }

    if (!HelpVideoEducationLanguage.values.contains(normalizedLanguage)) {
      throw const HelpVideoEducationCatalogDecisionException(
        'Video education language is invalid.',
      );
    }

    if (reasonCodes.isEmpty || reasonCodes.length > 8) {
      throw const HelpVideoEducationCatalogDecisionException(
        'Video education catalog reason codes are invalid.',
      );
    }

    for (final String reason in reasonCodes) {
      if (!HelpVideoEducationCatalogReason.values.contains(reason)) {
        throw const HelpVideoEducationCatalogDecisionException(
          'Video education catalog reason code is invalid.',
        );
      }
    }
  }
}

class HelpVideoEducationCatalogDecisionException implements Exception {
  const HelpVideoEducationCatalogDecisionException(this.message);

  final String message;

  @override
  String toString() => 'HelpVideoEducationCatalogDecisionException: $message';
}
