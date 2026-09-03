import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_content_draft_package_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_content_generation_contract_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_content_grounding_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_content_generation_request.dart';
import 'package:swat_ride/ai_agent/models/agent_content_platform_draft_package.dart';
import 'package:swat_ride/ai_agent/models/agent_content_verified_grounding_snapshot.dart';
import 'package:swat_ride/ai_agent/models/agent_content_video_scene_plan.dart';
import 'package:swat_ride/ai_agent/services/agent_content_generation_request_policy.dart';
import 'package:swat_ride/ai_agent/services/agent_content_grounding_gate.dart';
import 'package:swat_ride/ai_agent/services/agent_content_platform_draft_package_policy.dart';

void main() {
  const AgentContentGenerationRequestPolicy requestPolicy =
      AgentContentGenerationRequestPolicy();

  const AgentContentPlatformDraftPackagePolicy packagePolicy =
      AgentContentPlatformDraftPackagePolicy();

  const AgentContentGroundingGate groundingGate = AgentContentGroundingGate();

  AgentContentGenerationRequest request({
    String reviewChannel = AgentContentReviewChannel.inApp,
  }) {
    return AgentContentGenerationRequest(
      requestId: 'content_grounding_001',
      draftType: AgentContentDraftType.reelScript,
      platform: AgentContentPlatform.instagram,
      module: 'ride',
      feature: 'normal_ride',
      audience: AgentContentAudience.customer,
      language: AgentContentLanguage.urdu,
      purpose: 'Explain verified ride availability and app flow.',
      brief: 'Use only verified structured facts.',
      sourceReferenceIds: const <String>['verified_feature:ride'],
      requestedMaxOutputChars: 2200,
      reviewChannel: reviewChannel,
      createdAt: DateTime.utc(2026, 8, 19, 18),
    );
  }

  AgentContentPlatformDraftPackage readyPackage({
    AgentContentGenerationRequest? contentRequest,
  }) {
    final AgentContentGenerationRequest req = contentRequest ?? request();

    return packagePolicy.evaluate(
      request: req,
      requestDecision: requestPolicy.evaluate(req),
      problem: 'Customer ko local ride option chahiye.',
      solution: 'Verified SWAT RIDE ride flow available hai.',
      benefit: 'Customer app se ride request flow use kar sakta hai.',
      hookType: AgentContentHookType.problem,
      hookText: 'Swat mein ride chahiye?',
      primaryText:
          'Sirf verified ride feature aur service state explain karein.',
      cta: 'SWAT RIDE ke verified ride options dekhein.',
      scenes: const <AgentContentVideoScenePlan>[
        AgentContentVideoScenePlan(
          order: 1,
          shotType: AgentContentShotType.phoneAppDemo,
          visualSource: AgentContentVisualSource.realAppUi,
          objective: 'Show verified ride UI.',
          voiceover: 'Verified ride flow dikhayein.',
          onScreenText: 'Ride',
          durationSeconds: 5,
        ),
      ],
      visualSources: const <String>[AgentContentVisualSource.realAppUi],
    );
  }

  AgentContentVerifiedGroundingSnapshot snapshot({
    bool featureVerified = true,
    bool featureStable = true,
    bool approvedForCommunication = true,
    bool serviceEnabled = true,
    bool sourceFresh = true,
    List<String> sourceReferenceIds = const <String>[
      'verified_service_state:ride',
      'verified_feature:ride',
    ],
    Set<String> verifiedClaimKeys = const <String>{
      AgentContentVerifiedClaimKey.featureExists,
      AgentContentVerifiedClaimKey.featureEnabled,
      AgentContentVerifiedClaimKey.serviceEnabled,
      AgentContentVerifiedClaimKey.serviceAvailability,
    },
  }) {
    return AgentContentVerifiedGroundingSnapshot(
      module: 'ride',
      feature: 'normal_ride',
      featureVerified: featureVerified,
      featureStable: featureStable,
      approvedForCommunication: approvedForCommunication,
      serviceEnabled: serviceEnabled,
      sourceFresh: sourceFresh,
      sourceReferenceIds: sourceReferenceIds,
      verifiedClaimKeys: verifiedClaimKeys,
      verifiedAt: DateTime.utc(2026, 8, 19, 18),
    );
  }

  group('Phase 56 Step 1D grounding / anti-hallucination gate', () {
    test('13 supported verified claim keys are locked', () {
      expect(AgentContentVerifiedClaimKey.values.length, 13);
    });

    test('9 high-sensitivity claim categories require verification', () {
      expect(AgentContentVerifiedClaimKey.highSensitivity.length, 9);
    });

    test('fully verified content becomes grounded ready for review', () {
      final result = groundingGate.evaluate(
        draftPackage: readyPackage(),
        snapshot: snapshot(),
        declaredClaimKeys: const <String>{
          AgentContentVerifiedClaimKey.featureExists,
          AgentContentVerifiedClaimKey.serviceEnabled,
          AgentContentVerifiedClaimKey.serviceAvailability,
        },
      );

      expect(result.grounded, isTrue);
      expect(
        result.status,
        AgentContentGroundingStatus.groundedReadyForHumanReview,
      );
      expect(result.humanReviewRequired, isTrue);
      expect(result.autoPublishes, isFalse);
    });

    test('unverified feature is blocked', () {
      final result = groundingGate.evaluate(
        draftPackage: readyPackage(),
        snapshot: snapshot(featureVerified: false),
        declaredClaimKeys: const <String>{
          AgentContentVerifiedClaimKey.featureExists,
        },
      );

      expect(
        result.status,
        AgentContentGroundingStatus.blockedUnverifiedFeature,
      );
    });

    test('unstable development feature is blocked', () {
      final result = groundingGate.evaluate(
        draftPackage: readyPackage(),
        snapshot: snapshot(featureStable: false),
        declaredClaimKeys: const <String>{
          AgentContentVerifiedClaimKey.featureExists,
        },
      );

      expect(result.status, AgentContentGroundingStatus.blockedUnstableFeature);
    });

    test('feature not approved for communication is blocked', () {
      final result = groundingGate.evaluate(
        draftPackage: readyPackage(),
        snapshot: snapshot(approvedForCommunication: false),
        declaredClaimKeys: const <String>{
          AgentContentVerifiedClaimKey.featureExists,
        },
      );

      expect(
        result.status,
        AgentContentGroundingStatus.blockedUnapprovedFeature,
      );
    });

    test('disabled service cannot be promoted', () {
      final result = groundingGate.evaluate(
        draftPackage: readyPackage(),
        snapshot: snapshot(serviceEnabled: false),
        declaredClaimKeys: const <String>{
          AgentContentVerifiedClaimKey.serviceEnabled,
        },
      );

      expect(result.status, AgentContentGroundingStatus.blockedServiceDisabled);
    });

    test('stale verified source is blocked', () {
      final result = groundingGate.evaluate(
        draftPackage: readyPackage(),
        snapshot: snapshot(sourceFresh: false),
        declaredClaimKeys: const <String>{
          AgentContentVerifiedClaimKey.serviceEnabled,
        },
      );

      expect(result.status, AgentContentGroundingStatus.blockedSourceStale);
    });

    test('missing source reference returns NEEDS_SOURCE', () {
      final result = groundingGate.evaluate(
        draftPackage: readyPackage(),
        snapshot: snapshot(sourceReferenceIds: const <String>[]),
        declaredClaimKeys: const <String>{
          AgentContentVerifiedClaimKey.serviceEnabled,
        },
      );

      expect(result.status, AgentContentGroundingStatus.needsSource);
    });

    test('empty declared factual claims returns NEEDS_SOURCE', () {
      final result = groundingGate.evaluate(
        draftPackage: readyPackage(),
        snapshot: snapshot(),
        declaredClaimKeys: const <String>{},
      );

      expect(result.status, AgentContentGroundingStatus.needsSource);
    });

    test('unsupported claim key is blocked', () {
      final result = groundingGate.evaluate(
        draftPackage: readyPackage(),
        snapshot: snapshot(),
        declaredClaimKeys: const <String>{'made_up_claim'},
      );

      expect(
        result.status,
        AgentContentGroundingStatus.blockedUnsupportedClaim,
      );
    });

    test('unverified price claim returns NEEDS_SOURCE', () {
      final result = groundingGate.evaluate(
        draftPackage: readyPackage(),
        snapshot: snapshot(),
        declaredClaimKeys: const <String>{AgentContentVerifiedClaimKey.price},
      );

      expect(result.status, AgentContentGroundingStatus.needsSource);
    });

    test('verified price claim may proceed to human review', () {
      final result = groundingGate.evaluate(
        draftPackage: readyPackage(),
        snapshot: snapshot(
          verifiedClaimKeys: const <String>{
            AgentContentVerifiedClaimKey.featureExists,
            AgentContentVerifiedClaimKey.serviceEnabled,
            AgentContentVerifiedClaimKey.price,
          },
        ),
        declaredClaimKeys: const <String>{AgentContentVerifiedClaimKey.price},
      );

      expect(result.grounded, isTrue);
      expect(result.humanReviewRequired, isTrue);
    });

    test('unverified discount/offer claim returns NEEDS_SOURCE', () {
      final result = groundingGate.evaluate(
        draftPackage: readyPackage(),
        snapshot: snapshot(),
        declaredClaimKeys: const <String>{
          AgentContentVerifiedClaimKey.discountOffer,
        },
      );

      expect(result.status, AgentContentGroundingStatus.needsSource);
    });

    test('unverified safety claim returns NEEDS_SOURCE', () {
      final result = groundingGate.evaluate(
        draftPackage: readyPackage(),
        snapshot: snapshot(),
        declaredClaimKeys: const <String>{
          AgentContentVerifiedClaimKey.safetyFeature,
        },
      );

      expect(result.status, AgentContentGroundingStatus.needsSource);
    });

    test('unverified policy claim returns NEEDS_SOURCE', () {
      final result = groundingGate.evaluate(
        draftPackage: readyPackage(),
        snapshot: snapshot(),
        declaredClaimKeys: const <String>{AgentContentVerifiedClaimKey.policy},
      );

      expect(result.status, AgentContentGroundingStatus.needsSource);
    });

    test('unverified statistic claim returns NEEDS_SOURCE', () {
      final result = groundingGate.evaluate(
        draftPackage: readyPackage(),
        snapshot: snapshot(),
        declaredClaimKeys: const <String>{
          AgentContentVerifiedClaimKey.statistic,
        },
      );

      expect(result.status, AgentContentGroundingStatus.needsSource);
    });

    test('unverified driver earnings claim returns NEEDS_SOURCE', () {
      final result = groundingGate.evaluate(
        draftPackage: readyPackage(),
        snapshot: snapshot(),
        declaredClaimKeys: const <String>{
          AgentContentVerifiedClaimKey.driverEarnings,
        },
      );

      expect(result.status, AgentContentGroundingStatus.needsSource);
    });

    test(
      'Owner WhatsApp review eligibility is preserved only after grounding',
      () {
        final req = request(
          reviewChannel: AgentContentReviewChannel.ownerWhatsApp,
        );

        final grounded = groundingGate.evaluate(
          draftPackage: readyPackage(contentRequest: req),
          snapshot: snapshot(),
          declaredClaimKeys: const <String>{
            AgentContentVerifiedClaimKey.featureExists,
            AgentContentVerifiedClaimKey.serviceEnabled,
          },
        );

        expect(grounded.grounded, isTrue);
        expect(grounded.ownerWhatsAppReviewEligible, isTrue);

        final summary = grounded.toOwnerReviewSummary();

        expect(summary['ownerWhatsAppReviewEligible'], isTrue);
        expect(summary['containsRawSourcePayload'], isFalse);
        expect(summary['containsSecrets'], isFalse);
        expect(summary['autoPublishes'], isFalse);
        expect(summary['sendsWhatsApp'], isFalse);
      },
    );

    test('blocked grounding removes Owner WhatsApp review eligibility', () {
      final req = request(
        reviewChannel: AgentContentReviewChannel.ownerWhatsApp,
      );

      final blocked = groundingGate.evaluate(
        draftPackage: readyPackage(contentRequest: req),
        snapshot: snapshot(serviceEnabled: false),
        declaredClaimKeys: const <String>{
          AgentContentVerifiedClaimKey.serviceEnabled,
        },
      );

      expect(blocked.grounded, isFalse);
      expect(blocked.ownerWhatsAppReviewEligible, isFalse);
    });

    test(
      'grounding snapshot never treats generated text as source of truth',
      () {
        final value = snapshot();

        expect(value.structuredVerifiedDataOnly, isTrue);
        expect(value.generatedTextIsSourceOfTruth, isFalse);
        expect(value.rawPromptIsSourceOfTruth, isFalse);
        expect(value.providerOutputIsSourceOfTruth, isFalse);
        expect(value.grantsAuthority, isFalse);
        expect(value.writesBusinessData, isFalse);
        expect(value.persistsSnapshot, isFalse);
      },
    );

    test('grounding gate reuses existing quality safety foundations', () {
      expect(groundingGate.reusesExistingConversationGrounding, isTrue);
      expect(groundingGate.reusesExistingConversationQuality, isTrue);
      expect(groundingGate.reusesExistingResponseGuard, isTrue);
      expect(groundingGate.duplicatesGroundingEngine, isFalse);
    });

    test('grounding gate enforces verified-state rules', () {
      expect(groundingGate.verifiedStructuredSourcesRequired, isTrue);
      expect(groundingGate.featureMustBeVerified, isTrue);
      expect(groundingGate.featureMustBeStable, isTrue);
      expect(groundingGate.featureMustBeApprovedForCommunication, isTrue);
      expect(groundingGate.disabledServicePromotionBlocked, isTrue);
      expect(groundingGate.staleSourceBlocked, isTrue);
      expect(groundingGate.unsupportedClaimBlocked, isTrue);
      expect(groundingGate.unverifiedClaimNeedsSource, isTrue);
      expect(groundingGate.highSensitivityClaimsRequireVerification, isTrue);
      expect(groundingGate.generatedTextIsNeverFactAuthority, isTrue);
      expect(groundingGate.humanReviewAlwaysRequired, isTrue);
      expect(groundingGate.ownerWhatsAppReviewOnlyAfterGrounding, isTrue);
    });

    test('grounding gate cannot publish/send/execute authority', () {
      expect(groundingGate.autoPublishes, isFalse);
      expect(groundingGate.autoSchedules, isFalse);
      expect(groundingGate.postsSocialMedia, isFalse);
      expect(groundingGate.sendsWhatsApp, isFalse);
      expect(groundingGate.invokesProvider, isFalse);
      expect(groundingGate.executesApproval, isFalse);
      expect(groundingGate.executesBusinessAction, isFalse);
      expect(groundingGate.grantsAuthority, isFalse);
      expect(groundingGate.grantsPermission, isFalse);
      expect(groundingGate.consumesApproval, isFalse);
      expect(groundingGate.marksRuntimeAllowed, isFalse);
      expect(groundingGate.writesBusinessData, isFalse);
      expect(groundingGate.persistsGrounding, isFalse);
    });

    test('Phase 57 62 63 ownership remains separate', () {
      expect(groundingGate.implementsPhase57KnowledgeLibrary, isFalse);
      expect(groundingGate.implementsPhase62SelfDeployment, isFalse);
      expect(groundingGate.implementsPhase63PrivacyUi, isFalse);
    });
  });
}
