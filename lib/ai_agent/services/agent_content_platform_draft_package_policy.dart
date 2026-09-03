import '../constants/agent_content_draft_package_constants.dart';
import '../constants/agent_content_generation_contract_constants.dart';
import '../models/agent_content_generation_request.dart';
import '../models/agent_content_generation_request_decision.dart';
import '../models/agent_content_platform_draft_package.dart';
import '../models/agent_content_video_scene_plan.dart';

class AgentContentPlatformDraftPackagePolicy {
  const AgentContentPlatformDraftPackagePolicy();

  static const Map<String, Set<String>> _platformDraftTypes =
      <String, Set<String>>{
        AgentContentPlatform.facebook: <String>{
          AgentContentDraftType.socialPost,
          AgentContentDraftType.socialCaption,
          AgentContentDraftType.reelScript,
          AgentContentDraftType.storyScript,
          AgentContentDraftType.videoScript,
          AgentContentDraftType.videoShotPlan,
          AgentContentDraftType.hookSet,
          AgentContentDraftType.carouselConcept,
          AgentContentDraftType.thumbnailConcept,
          AgentContentDraftType.educationalDraft,
          AgentContentDraftType.promotionalDraft,
          AgentContentDraftType.serviceExplainer,
          AgentContentDraftType.featureAnnouncement,
          AgentContentDraftType.localSeasonalCampaign,
        },
        AgentContentPlatform.instagram: <String>{
          AgentContentDraftType.socialPost,
          AgentContentDraftType.socialCaption,
          AgentContentDraftType.reelScript,
          AgentContentDraftType.storyScript,
          AgentContentDraftType.videoScript,
          AgentContentDraftType.videoShotPlan,
          AgentContentDraftType.hookSet,
          AgentContentDraftType.carouselConcept,
          AgentContentDraftType.thumbnailConcept,
          AgentContentDraftType.educationalDraft,
          AgentContentDraftType.promotionalDraft,
          AgentContentDraftType.serviceExplainer,
          AgentContentDraftType.featureAnnouncement,
          AgentContentDraftType.localSeasonalCampaign,
        },
        AgentContentPlatform.tiktok: <String>{
          AgentContentDraftType.socialCaption,
          AgentContentDraftType.reelScript,
          AgentContentDraftType.shortScript,
          AgentContentDraftType.videoScript,
          AgentContentDraftType.videoShotPlan,
          AgentContentDraftType.hookSet,
          AgentContentDraftType.thumbnailConcept,
          AgentContentDraftType.educationalDraft,
          AgentContentDraftType.promotionalDraft,
          AgentContentDraftType.serviceExplainer,
          AgentContentDraftType.localSeasonalCampaign,
        },
        AgentContentPlatform.youtube: <String>{
          AgentContentDraftType.socialCaption,
          AgentContentDraftType.shortScript,
          AgentContentDraftType.videoScript,
          AgentContentDraftType.videoShotPlan,
          AgentContentDraftType.hookSet,
          AgentContentDraftType.thumbnailConcept,
          AgentContentDraftType.educationalDraft,
          AgentContentDraftType.promotionalDraft,
          AgentContentDraftType.serviceExplainer,
          AgentContentDraftType.featureAnnouncement,
          AgentContentDraftType.localSeasonalCampaign,
        },
      };

  AgentContentPlatformDraftPackage evaluate({
    required AgentContentGenerationRequest request,
    required AgentContentGenerationRequestDecision requestDecision,
    required String problem,
    required String solution,
    required String benefit,
    required String hookType,
    required String hookText,
    required String primaryText,
    required String cta,
    required List<AgentContentVideoScenePlan> scenes,
    required List<String> visualSources,
  }) {
    try {
      request.validateStructure();
      requestDecision.validateStructure();
    } catch (_) {
      return _blocked(
        status: AgentContentDraftPackageStatus.blockedRequestNotAccepted,
        request: request,
        reasons: const <String>[
          'step1b_request_validation_required',
          'draft_only',
          'human_review_required',
        ],
      );
    }

    if (!requestDecision.accepted ||
        requestDecision.requestId != request.requestId) {
      return _blocked(
        status: AgentContentDraftPackageStatus.blockedRequestNotAccepted,
        request: request,
        reasons: const <String>[
          'step1b_accepted_request_required',
          'draft_only',
          'human_review_required',
        ],
      );
    }

    if (request.platform == AgentContentPlatform.none) {
      return _blocked(
        status: AgentContentDraftPackageStatus.blockedPlatformRequired,
        request: request,
        reasons: const <String>[
          'platform_specific_package_requires_platform',
          'draft_only',
          'human_review_required',
        ],
      );
    }

    final Set<String>? allowed = _platformDraftTypes[request.platform];

    if (allowed == null || !allowed.contains(request.draftType)) {
      return _blocked(
        status: AgentContentDraftPackageStatus.blockedPlatformDraftMismatch,
        request: request,
        reasons: const <String>[
          'platform_draft_type_mismatch',
          'platform_specific_shape_required',
          'draft_only',
          'human_review_required',
        ],
      );
    }

    if (_containsUnsafeMarketingIntent(
      '$problem $solution $benefit $hookText $primaryText $cta',
    )) {
      return _blocked(
        status: AgentContentDraftPackageStatus.blockedUnsafeMarketingIntent,
        request: request,
        reasons: const <String>[
          'unsafe_marketing_intent_blocked',
          'truthful_marketing_required',
          'draft_only',
          'human_review_required',
        ],
      );
    }

    final bool hasRealOrApprovedVisual = visualSources.any(
      AgentContentVisualSource.realOrApproved.contains,
    );

    if (!hasRealOrApprovedVisual) {
      return _blocked(
        status: AgentContentDraftPackageStatus.blockedNoAuthenticVisualPlan,
        request: request,
        reasons: const <String>[
          'real_or_approved_visual_required',
          'ai_visual_supplementary_only',
          'draft_only',
          'human_review_required',
        ],
      );
    }

    final AgentContentPlatformDraftPackage package =
        AgentContentPlatformDraftPackage(
          status: AgentContentDraftPackageStatus.readyForHumanReview,
          requestId: request.requestId,
          draftType: request.draftType,
          platform: request.platform,
          problem: problem.trim(),
          solution: solution.trim(),
          benefit: benefit.trim(),
          hookType: hookType,
          hookText: hookText.trim(),
          primaryText: primaryText.trim(),
          cta: cta.trim(),
          scenes: scenes,
          visualSources: visualSources,
          ownerWhatsAppReviewEligible:
              requestDecision.ownerWhatsAppReviewEligible,
          reasonCodes: const <String>[
            'step1b_accepted_request_reused',
            'problem_solution_benefit_structured',
            'ethical_hook_required',
            'platform_specific_shape',
            'real_visual_priority',
            'human_review_required',
            'draft_only',
            'no_publish_authority',
          ],
        );

    try {
      package.validateStructure();
      return package;
    } catch (_) {
      return _blocked(
        status: AgentContentDraftPackageStatus.blockedInvalidCreativeStructure,
        request: request,
        reasons: const <String>[
          'invalid_creative_structure',
          'platform_specific_shape_required',
          'draft_only',
          'human_review_required',
        ],
      );
    }
  }

  AgentContentPlatformDraftPackage _blocked({
    required String status,
    required AgentContentGenerationRequest request,
    required List<String> reasons,
  }) {
    final AgentContentPlatformDraftPackage package =
        AgentContentPlatformDraftPackage(
          status: status,
          requestId: _safeId(request.requestId),
          draftType: request.draftType.trim(),
          platform: request.platform.trim(),
          problem: '',
          solution: '',
          benefit: '',
          hookType: '',
          hookText: '',
          primaryText: '',
          cta: '',
          scenes: const <AgentContentVideoScenePlan>[],
          visualSources: const <String>[],
          ownerWhatsAppReviewEligible: false,
          reasonCodes: reasons,
        );

    package.validateStructure();
    return package;
  }

  bool _containsUnsafeMarketingIntent(String value) {
    final String normalized = value.toLowerCase();

    const List<String> blocked = <String>[
      'fake review',
      'fake reviews',
      'fake customer',
      'fake downloads',
      'fake users',
      'fake discount',
      'fake offer',
      'fake availability',
      'fabricated statistic',
      'guaranteed earnings',
      'guaranteed income',
      'cheapest in pakistan',
      'safest in pakistan',
      'best in pakistan',
      'limited time hurry',
      'fear them',
      'rage bait',
      'ragebait',
      'misleading thumbnail',
      'clickbait lie',
      'pretend this happened',
    ];

    return blocked.any(normalized.contains);
  }

  bool supportsPlatformDraftType({
    required String platform,
    required String draftType,
  }) {
    return _platformDraftTypes[platform]?.contains(draftType) ?? false;
  }

  String _safeId(String value) {
    final String trimmed = value.trim();

    if (trimmed.isEmpty) {
      return 'invalid_request';
    }

    if (trimmed.length <= 180) {
      return trimmed;
    }

    return trimmed.substring(0, 180);
  }

  bool get consumesOnlyStep1BAcceptedRequests => true;
  bool get platformSpecificDraftShape => true;
  bool get problemSolutionBenefitRequired => true;
  bool get ethicalHooksOnly => true;
  bool get verifiedClaimsRequired => true;
  bool get realVisualPriority => true;
  bool get aiVisualsSupplementaryOnly => true;
  bool get aiVisualsMayRepresentRealProof => false;
  bool get cameraShotPlanningOnly => true;
  bool get smartEditingPlanningOnly => true;
  bool get autoPublishes => false;
  bool get autoSchedules => false;
  bool get postsSocialMedia => false;
  bool get sendsWhatsApp => false;
  bool get invokesProvider => false;
  bool get recordsVideo => false;
  bool get editsVideo => false;
  bool get uploadsMedia => false;
  bool get executesApproval => false;
  bool get executesBusinessAction => false;
  bool get grantsAuthority => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get marksRuntimeAllowed => false;
  bool get writesBusinessData => false;
  bool get persistsPackage => false;
  bool get implementsPhase55VideoCatalog => false;
  bool get implementsPhase57KnowledgeLibrary => false;
  bool get implementsPhase62SelfDeployment => false;
  bool get implementsPhase63PrivacyUi => false;
}
