import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_content_draft_package_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_content_generation_contract_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_content_generation_request.dart';
import 'package:swat_ride/ai_agent/models/agent_content_generation_request_decision.dart';
import 'package:swat_ride/ai_agent/models/agent_content_platform_draft_package.dart';
import 'package:swat_ride/ai_agent/models/agent_content_video_scene_plan.dart';
import 'package:swat_ride/ai_agent/services/agent_content_generation_request_policy.dart';
import 'package:swat_ride/ai_agent/services/agent_content_platform_draft_package_policy.dart';

void main() {
  const AgentContentGenerationRequestPolicy requestPolicy =
      AgentContentGenerationRequestPolicy();

  const AgentContentPlatformDraftPackagePolicy packagePolicy =
      AgentContentPlatformDraftPackagePolicy();

  AgentContentGenerationRequest request({
    String draftType = AgentContentDraftType.reelScript,
    String platform = AgentContentPlatform.instagram,
    String reviewChannel = AgentContentReviewChannel.inApp,
  }) {
    return AgentContentGenerationRequest(
      requestId: 'content_req_1c_001',
      draftType: draftType,
      platform: platform,
      module: 'ride',
      feature: 'normal_ride',
      audience: AgentContentAudience.customer,
      language: AgentContentLanguage.urdu,
      purpose: 'Explain a verified SWAT RIDE customer benefit.',
      brief: 'Create a truthful problem-solution social draft.',
      sourceReferenceIds: const <String>['verified_feature:ride'],
      requestedMaxOutputChars: 2500,
      reviewChannel: reviewChannel,
      createdAt: DateTime.utc(2026, 8, 19, 17),
    );
  }

  AgentContentVideoScenePlan scene({
    int order = 1,
    String shotType = AgentContentShotType.phoneAppDemo,
    String visualSource = AgentContentVisualSource.realAppUi,
  }) {
    return AgentContentVideoScenePlan(
      order: order,
      shotType: shotType,
      visualSource: visualSource,
      objective: 'Show the real app booking flow.',
      voiceover: 'Apni ride request app mein asani se start karein.',
      onScreenText: 'SWAT RIDE',
      durationSeconds: 5,
    );
  }

  AgentContentPlatformDraftPackage evaluate({
    AgentContentGenerationRequest? contentRequest,
    AgentContentGenerationRequestDecision? decision,
    String problem = 'Swat mein convenient local ride ki zarurat.',
    String solution = 'SWAT RIDE app se ride request ka clear flow.',
    String benefit = 'Customer ko convenient booking flow milta hai.',
    String hookType = AgentContentHookType.problem,
    String hookText = 'Sawari dhoondne mein waqt lag raha hai?',
    String primaryText =
        'Problem ko explain karein, phir verified SWAT RIDE ride flow dikhayein.',
    String cta = 'SWAT RIDE ke verified ride options dekhein.',
    List<AgentContentVideoScenePlan>? scenes,
    List<String>? visualSources,
  }) {
    final AgentContentGenerationRequest req = contentRequest ?? request();

    return packagePolicy.evaluate(
      request: req,
      requestDecision: decision ?? requestPolicy.evaluate(req),
      problem: problem,
      solution: solution,
      benefit: benefit,
      hookType: hookType,
      hookText: hookText,
      primaryText: primaryText,
      cta: cta,
      scenes: scenes ?? <AgentContentVideoScenePlan>[scene()],
      visualSources:
          visualSources ??
          const <String>[
            AgentContentVisualSource.realAppUi,
            AgentContentVisualSource.realSwatLocation,
          ],
    );
  }

  group('Phase 56 Step 1C platform package / hooks / video plan', () {
    test('8 ethical hook types are locked', () {
      expect(AgentContentHookType.values.length, 8);
    });

    test('11 camera/shot types are locked', () {
      expect(AgentContentShotType.values.length, 11);
    });

    test('real and approved visual sources are prioritized', () {
      expect(
        AgentContentVisualSource.realOrApproved,
        containsAll(<String>[
          AgentContentVisualSource.realAppUi,
          AgentContentVisualSource.realVehicle,
          AgentContentVisualSource.realSwatLocation,
          AgentContentVisualSource.approvedPartnerAsset,
          AgentContentVisualSource.approvedCompanyAsset,
          AgentContentVisualSource.realServiceFootage,
          AgentContentVisualSource.screenRecording,
        ]),
      );
    });

    test('Instagram reel package is ready for human review', () {
      final result = evaluate();

      expect(result.readyForHumanReview, isTrue);
      expect(result.status, AgentContentDraftPackageStatus.readyForHumanReview);
      expect(result.platform, AgentContentPlatform.instagram);
      expect(result.draftOnly, isTrue);
      expect(result.humanReviewRequired, isTrue);
    });

    test('TikTok short script is supported', () {
      expect(
        packagePolicy.supportsPlatformDraftType(
          platform: AgentContentPlatform.tiktok,
          draftType: AgentContentDraftType.shortScript,
        ),
        isTrue,
      );
    });

    test('YouTube video script is supported', () {
      expect(
        packagePolicy.supportsPlatformDraftType(
          platform: AgentContentPlatform.youtube,
          draftType: AgentContentDraftType.videoScript,
        ),
        isTrue,
      );
    });

    test('TikTok admin announcement draft is rejected by profile', () {
      final req = request(
        draftType: AgentContentDraftType.adminAnnouncementDraft,
        platform: AgentContentPlatform.tiktok,
      );

      final result = evaluate(contentRequest: req);

      expect(
        result.status,
        AgentContentDraftPackageStatus.blockedPlatformDraftMismatch,
      );
    });

    test('platform-specific package requires actual platform', () {
      final req = request(
        draftType: AgentContentDraftType.videoScript,
        platform: AgentContentPlatform.none,
      );

      final result = evaluate(contentRequest: req);

      expect(
        result.status,
        AgentContentDraftPackageStatus.blockedPlatformRequired,
      );
    });

    test('Step 1B rejected request cannot become package', () {
      final req = request();
      final rejected = AgentContentGenerationRequestDecision(
        status: AgentContentRequestStatus.blockedSensitiveExecutionIntent,
        requestId: req.requestId,
        normalizedDraftType: req.draftType,
        normalizedPlatform: req.platform,
        reviewRequired: false,
        ownerWhatsAppReviewEligible: false,
        reasonCodes: const <String>['sensitive_execution_intent_blocked'],
      );

      final result = evaluate(contentRequest: req, decision: rejected);

      expect(
        result.status,
        AgentContentDraftPackageStatus.blockedRequestNotAccepted,
      );
    });

    test('AI-only visuals cannot be treated as authentic proof', () {
      final result = evaluate(
        visualSources: const <String>[AgentContentVisualSource.aiSupplementary],
      );

      expect(
        result.status,
        AgentContentDraftPackageStatus.blockedNoAuthenticVisualPlan,
      );
    });

    test('AI supplementary visual may accompany real approved visual', () {
      final result = evaluate(
        visualSources: const <String>[
          AgentContentVisualSource.realAppUi,
          AgentContentVisualSource.aiSupplementary,
        ],
      );

      expect(result.readyForHumanReview, isTrue);
      expect(result.aiVisualsSupplementaryOnly, isTrue);
      expect(result.aiVisualsMayRepresentRealProof, isFalse);
    });

    test('fake reviews marketing intent is blocked', () {
      final result = evaluate(
        primaryText: 'Add fake reviews to make this look popular.',
      );

      expect(
        result.status,
        AgentContentDraftPackageStatus.blockedUnsafeMarketingIntent,
      );
    });

    test('fabricated statistics marketing intent is blocked', () {
      final result = evaluate(
        hookText: 'Use a fabricated statistic for attention.',
      );

      expect(
        result.status,
        AgentContentDraftPackageStatus.blockedUnsafeMarketingIntent,
      );
    });

    test('guaranteed earnings marketing intent is blocked', () {
      final result = evaluate(benefit: 'Guaranteed earnings for every driver.');

      expect(
        result.status,
        AgentContentDraftPackageStatus.blockedUnsafeMarketingIntent,
      );
    });

    test('misleading thumbnail marketing intent is blocked', () {
      final result = evaluate(
        primaryText: 'Use a misleading thumbnail to increase clicks.',
      );

      expect(
        result.status,
        AgentContentDraftPackageStatus.blockedUnsafeMarketingIntent,
      );
    });

    test('video scene is planning-only', () {
      final value = scene();

      value.validateStructure();

      expect(value.planningOnly, isTrue);
      expect(value.recordsVideo, isFalse);
      expect(value.editsVideo, isFalse);
      expect(value.uploadsMedia, isFalse);
      expect(value.invokesProvider, isFalse);
    });

    test('invalid scene duration blocks creative structure', () {
      final badScene = AgentContentVideoScenePlan(
        order: 1,
        shotType: AgentContentShotType.wide,
        visualSource: AgentContentVisualSource.realSwatLocation,
        objective: 'Establish Swat location.',
        voiceover: '',
        onScreenText: '',
        durationSeconds: 181,
      );

      final result = evaluate(scenes: <AgentContentVideoScenePlan>[badScene]);

      expect(
        result.status,
        AgentContentDraftPackageStatus.blockedInvalidCreativeStructure,
      );
    });

    test('Owner WhatsApp review eligibility flows from Step 1B', () {
      final req = request(
        reviewChannel: AgentContentReviewChannel.ownerWhatsApp,
      );

      final result = evaluate(contentRequest: req);

      expect(result.readyForHumanReview, isTrue);
      expect(result.ownerWhatsAppReviewEligible, isTrue);

      final summary = result.toOwnerReviewSummary();

      expect(summary['ownerWhatsAppReviewEligible'], isTrue);
      expect(summary['humanReviewRequired'], isTrue);
      expect(summary['autoPublishes'], isFalse);
      expect(summary['sendsWhatsApp'], isFalse);
      expect(summary['containsSourcePayload'], isFalse);
      expect(summary['containsSecrets'], isFalse);
    });

    test('package prohibits deceptive and authority behaviors', () {
      final result = evaluate();

      expect(result.verifiedClaimsRequired, isTrue);
      expect(result.realVisualPriority, isTrue);
      expect(result.aiVisualsSupplementaryOnly, isTrue);
      expect(result.allowsFakeClickbait, isFalse);
      expect(result.allowsFakeUrgency, isFalse);
      expect(result.allowsFakeStatistics, isFalse);
      expect(result.allowsFearManipulation, isFalse);
      expect(result.allowsMisleadingThumbnail, isFalse);
      expect(result.allowsRageBait, isFalse);
      expect(result.autoPublishes, isFalse);
      expect(result.autoSchedules, isFalse);
      expect(result.postsSocialMedia, isFalse);
      expect(result.sendsWhatsApp, isFalse);
      expect(result.executesBusinessAction, isFalse);
      expect(result.grantsAuthority, isFalse);
      expect(result.writesBusinessData, isFalse);
    });

    test('policy stays planning-only and no execution', () {
      expect(packagePolicy.consumesOnlyStep1BAcceptedRequests, isTrue);
      expect(packagePolicy.platformSpecificDraftShape, isTrue);
      expect(packagePolicy.problemSolutionBenefitRequired, isTrue);
      expect(packagePolicy.ethicalHooksOnly, isTrue);
      expect(packagePolicy.verifiedClaimsRequired, isTrue);
      expect(packagePolicy.realVisualPriority, isTrue);
      expect(packagePolicy.aiVisualsSupplementaryOnly, isTrue);
      expect(packagePolicy.aiVisualsMayRepresentRealProof, isFalse);
      expect(packagePolicy.cameraShotPlanningOnly, isTrue);
      expect(packagePolicy.smartEditingPlanningOnly, isTrue);
      expect(packagePolicy.autoPublishes, isFalse);
      expect(packagePolicy.autoSchedules, isFalse);
      expect(packagePolicy.postsSocialMedia, isFalse);
      expect(packagePolicy.sendsWhatsApp, isFalse);
      expect(packagePolicy.invokesProvider, isFalse);
      expect(packagePolicy.recordsVideo, isFalse);
      expect(packagePolicy.editsVideo, isFalse);
      expect(packagePolicy.uploadsMedia, isFalse);
      expect(packagePolicy.executesApproval, isFalse);
      expect(packagePolicy.executesBusinessAction, isFalse);
      expect(packagePolicy.grantsAuthority, isFalse);
      expect(packagePolicy.writesBusinessData, isFalse);
      expect(packagePolicy.persistsPackage, isFalse);
    });

    test('Phase 55 57 62 63 boundaries remain separate', () {
      expect(packagePolicy.implementsPhase55VideoCatalog, isFalse);
      expect(packagePolicy.implementsPhase57KnowledgeLibrary, isFalse);
      expect(packagePolicy.implementsPhase62SelfDeployment, isFalse);
      expect(packagePolicy.implementsPhase63PrivacyUi, isFalse);
    });
  });
}
