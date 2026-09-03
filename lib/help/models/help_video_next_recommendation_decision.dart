import '../constants/help_video_education_progress_constants.dart';

class HelpVideoNextRecommendationDecision {
  HelpVideoNextRecommendationDecision({
    required this.status,
    required this.currentTutorialId,
    required this.candidateTutorialId,
    required List<String> reasonCodes,
  }) : reasonCodes = List<String>.unmodifiable(reasonCodes);

  final String status;
  final String currentTutorialId;
  final String candidateTutorialId;
  final List<String> reasonCodes;

  bool get canRecommendNext =>
      status == HelpVideoNextRecommendationStatus.recommendNext;

  bool get shouldResumeCurrent =>
      status == HelpVideoNextRecommendationStatus.resumeCurrent;

  bool get recommendationOnly => true;
  bool get autoOpensVideo => false;
  bool get autoMarksComplete => false;
  bool get generatesContent => false;
  bool get grantsAuthority => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get marksRuntimeAllowed => false;
  bool get invokesProvider => false;
  bool get writesBusinessData => false;
  bool get persistsDecision => false;

  void validateStructure() {
    if (!HelpVideoNextRecommendationStatus.values.contains(status)) {
      throw const HelpVideoNextRecommendationDecisionException(
        'Next-video recommendation status is invalid.',
      );
    }

    if (currentTutorialId.trim().isEmpty || currentTutorialId.length > 180) {
      throw const HelpVideoNextRecommendationDecisionException(
        'Current tutorial ID is invalid.',
      );
    }

    if (candidateTutorialId.length > 180) {
      throw const HelpVideoNextRecommendationDecisionException(
        'Candidate tutorial ID is invalid.',
      );
    }

    if (reasonCodes.isEmpty || reasonCodes.length > 8) {
      throw const HelpVideoNextRecommendationDecisionException(
        'Next-video recommendation reasons are invalid.',
      );
    }

    for (final String reason in reasonCodes) {
      if (!HelpVideoLearningProgressReason.values.contains(reason)) {
        throw const HelpVideoNextRecommendationDecisionException(
          'Next-video recommendation reason is invalid.',
        );
      }
    }

    if (canRecommendNext && candidateTutorialId.trim().isEmpty) {
      throw const HelpVideoNextRecommendationDecisionException(
        'RECOMMEND_NEXT requires a candidate tutorial.',
      );
    }
  }
}

class HelpVideoNextRecommendationDecisionException implements Exception {
  const HelpVideoNextRecommendationDecisionException(this.message);

  final String message;

  @override
  String toString() => 'HelpVideoNextRecommendationDecisionException: $message';
}
