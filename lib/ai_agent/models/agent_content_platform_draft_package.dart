import '../constants/agent_content_draft_package_constants.dart';
import 'agent_content_video_scene_plan.dart';

class AgentContentPlatformDraftPackage {
  AgentContentPlatformDraftPackage({
    required this.status,
    required this.requestId,
    required this.draftType,
    required this.platform,
    required this.problem,
    required this.solution,
    required this.benefit,
    required this.hookType,
    required this.hookText,
    required this.primaryText,
    required this.cta,
    required List<AgentContentVideoScenePlan> scenes,
    required List<String> visualSources,
    required this.ownerWhatsAppReviewEligible,
    required List<String> reasonCodes,
  }) : scenes = List<AgentContentVideoScenePlan>.unmodifiable(scenes),
       visualSources = List<String>.unmodifiable(visualSources),
       reasonCodes = List<String>.unmodifiable(reasonCodes);

  final String status;
  final String requestId;
  final String draftType;
  final String platform;
  final String problem;
  final String solution;
  final String benefit;
  final String hookType;
  final String hookText;
  final String primaryText;
  final String cta;
  final List<AgentContentVideoScenePlan> scenes;
  final List<String> visualSources;
  final bool ownerWhatsAppReviewEligible;
  final List<String> reasonCodes;

  bool get readyForHumanReview =>
      status == AgentContentDraftPackageStatus.readyForHumanReview;

  bool get draftOnly => true;
  bool get humanReviewRequired => true;
  bool get problemSolutionBenefitRequired => true;
  bool get ethicalHookRequired => true;
  bool get verifiedClaimsRequired => true;
  bool get realVisualPriority => true;
  bool get aiVisualsSupplementaryOnly => true;
  bool get aiVisualsMayRepresentRealProof => false;
  bool get allowsFakeClickbait => false;
  bool get allowsFakeUrgency => false;
  bool get allowsFakeStatistics => false;
  bool get allowsFearManipulation => false;
  bool get allowsMisleadingThumbnail => false;
  bool get allowsRageBait => false;
  bool get autoPublishes => false;
  bool get autoSchedules => false;
  bool get postsSocialMedia => false;
  bool get sendsWhatsApp => false;
  bool get invokesProvider => false;
  bool get recordsVideo => false;
  bool get editsVideo => false;
  bool get uploadsMedia => false;
  bool get executesBusinessAction => false;
  bool get grantsAuthority => false;
  bool get writesBusinessData => false;
  bool get persistsPackage => false;

  Map<String, dynamic> toOwnerReviewSummary() {
    return Map<String, dynamic>.unmodifiable(<String, dynamic>{
      'requestId': requestId,
      'draftType': draftType,
      'platform': platform,
      'problem': problem,
      'solution': solution,
      'benefit': benefit,
      'hookType': hookType,
      'hookText': hookText,
      'cta': cta,
      'sceneCount': scenes.length,
      'visualSources': visualSources,
      'ownerWhatsAppReviewEligible': ownerWhatsAppReviewEligible,
      'humanReviewRequired': true,
      'autoPublishes': false,
      'sendsWhatsApp': false,
      'containsSourcePayload': false,
      'containsSecrets': false,
    });
  }

  void validateStructure() {
    if (!AgentContentDraftPackageStatus.values.contains(status)) {
      throw const AgentContentPlatformDraftPackageException(
        'Draft package status is invalid.',
      );
    }

    if (requestId.trim().isEmpty || requestId.length > 180) {
      throw const AgentContentPlatformDraftPackageException(
        'Draft package request ID is invalid.',
      );
    }

    if (readyForHumanReview) {
      if (!_safeRequired(problem, AgentContentPackageLimits.problemMax) ||
          !_safeRequired(solution, AgentContentPackageLimits.solutionMax) ||
          !_safeRequired(benefit, AgentContentPackageLimits.benefitMax) ||
          !_safeRequired(hookText, AgentContentPackageLimits.hookMax) ||
          !_safeRequired(
            primaryText,
            AgentContentPackageLimits.primaryTextMax,
          ) ||
          !_safeRequired(cta, AgentContentPackageLimits.ctaMax)) {
        throw const AgentContentPlatformDraftPackageException(
          'Draft package creative structure is invalid.',
        );
      }

      if (!AgentContentHookType.values.contains(hookType)) {
        throw const AgentContentPlatformDraftPackageException(
          'Draft package hook type is invalid.',
        );
      }

      if (visualSources.isEmpty) {
        throw const AgentContentPlatformDraftPackageException(
          'Draft package needs an authentic visual plan.',
        );
      }

      for (final String source in visualSources) {
        if (!AgentContentVisualSource.values.contains(source)) {
          throw const AgentContentPlatformDraftPackageException(
            'Draft package visual source is invalid.',
          );
        }
      }

      if (!visualSources.any(
        AgentContentVisualSource.realOrApproved.contains,
      )) {
        throw const AgentContentPlatformDraftPackageException(
          'AI-only visual plan cannot be treated as authentic proof.',
        );
      }

      if (scenes.length > AgentContentPackageLimits.sceneCountMax) {
        throw const AgentContentPlatformDraftPackageException(
          'Too many video scenes.',
        );
      }

      for (final AgentContentVideoScenePlan scene in scenes) {
        scene.validateStructure();
      }
    }

    if (reasonCodes.isEmpty || reasonCodes.length > 12) {
      throw const AgentContentPlatformDraftPackageException(
        'Draft package reasons are invalid.',
      );
    }
  }

  bool _safeRequired(String value, int maxLength) {
    final String trimmed = value.trim();

    return trimmed.isNotEmpty &&
        trimmed.length <= maxLength &&
        !RegExp(r'[\u0000-\u001F]').hasMatch(trimmed);
  }
}

class AgentContentPlatformDraftPackageException implements Exception {
  const AgentContentPlatformDraftPackageException(this.message);

  final String message;

  @override
  String toString() => 'AgentContentPlatformDraftPackageException: $message';
}
