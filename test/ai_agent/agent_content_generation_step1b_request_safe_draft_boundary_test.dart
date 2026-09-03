import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_content_generation_contract_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_content_generation_request.dart';
import 'package:swat_ride/ai_agent/models/agent_content_owner_whatsapp_review_projection.dart';
import 'package:swat_ride/ai_agent/services/agent_content_generation_request_policy.dart';

void main() {
  const AgentContentGenerationRequestPolicy policy =
      AgentContentGenerationRequestPolicy();

  AgentContentGenerationRequest request({
    String requestId = 'content_req_001',
    String draftType = AgentContentDraftType.socialPost,
    String platform = AgentContentPlatform.instagram,
    String module = 'ride',
    String feature = 'normal_ride',
    String audience = AgentContentAudience.customer,
    String language = AgentContentLanguage.urdu,
    String purpose = 'Explain a verified SWAT RIDE benefit.',
    String brief =
        'Create a truthful problem-solution draft for customer review.',
    List<String> sourceReferenceIds = const <String>['verified_feature:ride'],
    int requestedMaxOutputChars = 1500,
    String reviewChannel = AgentContentReviewChannel.inApp,
  }) {
    return AgentContentGenerationRequest(
      requestId: requestId,
      draftType: draftType,
      platform: platform,
      module: module,
      feature: feature,
      audience: audience,
      language: language,
      purpose: purpose,
      brief: brief,
      sourceReferenceIds: sourceReferenceIds,
      requestedMaxOutputChars: requestedMaxOutputChars,
      reviewChannel: reviewChannel,
      createdAt: DateTime.utc(2026, 8, 19, 16),
    );
  }

  group('Phase 56 Step 1B request + safe draft boundary', () {
    test('20 approved draft types are locked', () {
      expect(AgentContentDraftType.values.length, 20);
    });

    test('Facebook Instagram TikTok YouTube are supported', () {
      expect(
        AgentContentPlatform.values,
        containsAll(<String>[
          AgentContentPlatform.facebook,
          AgentContentPlatform.instagram,
          AgentContentPlatform.tiktok,
          AgentContentPlatform.youtube,
        ]),
      );
    });

    test('Urdu Pashto English are supported', () {
      expect(AgentContentLanguage.values, <String>{'ur', 'ps', 'en'});
    });

    test('safe social post request is accepted draft-only', () {
      final decision = policy.evaluate(request());
      expect(decision.accepted, isTrue);
      expect(decision.status, AgentContentRequestStatus.acceptedDraftOnly);
      expect(decision.reviewRequired, isTrue);
      expect(decision.publishesContent, isFalse);
    });

    test('social content requires explicit social platform', () {
      final decision = policy.evaluate(
        request(platform: AgentContentPlatform.none),
      );
      expect(
        decision.status,
        AgentContentRequestStatus.blockedMissingSocialPlatform,
      );
    });

    test('generic video script may use no platform', () {
      final decision = policy.evaluate(
        request(
          draftType: AgentContentDraftType.videoScript,
          platform: AgentContentPlatform.none,
        ),
      );
      expect(decision.accepted, isTrue);
    });

    test('email draft is draft-only and does not send email', () {
      final decision = policy.evaluate(
        request(
          draftType: AgentContentDraftType.emailDraft,
          platform: AgentContentPlatform.none,
        ),
      );
      expect(decision.accepted, isTrue);
      expect(decision.sendsEmail, isFalse);
    });

    test('WhatsApp draft is draft-only and does not send WhatsApp', () {
      final decision = policy.evaluate(
        request(
          draftType: AgentContentDraftType.whatsappDraft,
          platform: AgentContentPlatform.none,
        ),
      );
      expect(decision.accepted, isTrue);
      expect(decision.sendsWhatsApp, isFalse);
    });

    test('oversized brief is blocked as invalid request', () {
      final decision = policy.evaluate(request(brief: 'x' * 2001));
      expect(decision.status, AgentContentRequestStatus.blockedInvalidRequest);
    });

    test('too many source references are blocked', () {
      final refs = List<String>.generate(21, (int index) => 'source:$index');
      final decision = policy.evaluate(request(sourceReferenceIds: refs));
      expect(decision.status, AgentContentRequestStatus.blockedInvalidRequest);
    });

    test('direct refund execution intent is blocked', () {
      final decision = policy.evaluate(
        request(brief: 'Execute refund now for this user.'),
      );
      expect(
        decision.status,
        AgentContentRequestStatus.blockedSensitiveExecutionIntent,
      );
    });

    test('direct fare change intent is blocked', () {
      final decision = policy.evaluate(
        request(brief: 'Change fare for this service.'),
      );
      expect(
        decision.status,
        AgentContentRequestStatus.blockedSensitiveExecutionIntent,
      );
    });

    test('direct publish-now intent is blocked', () {
      final decision = policy.evaluate(
        request(brief: 'Publish now on Instagram.'),
      );
      expect(
        decision.status,
        AgentContentRequestStatus.blockedSensitiveExecutionIntent,
      );
    });

    test('Owner WhatsApp review channel becomes visibility-eligible', () {
      final contentRequest = request(
        reviewChannel: AgentContentReviewChannel.ownerWhatsApp,
      );
      final decision = policy.evaluate(contentRequest);

      expect(decision.accepted, isTrue);
      expect(decision.ownerWhatsAppReviewEligible, isTrue);

      final projection = AgentContentOwnerWhatsAppReviewProjection.fromRequest(
        request: contentRequest,
        decision: decision,
      );

      expect(projection.ownerOrAuthorizedAdminOnly, isTrue);
      expect(projection.requiresVerifiedWhatsAppIdentity, isTrue);
      expect(projection.requiresRoleAuthorization, isTrue);
      expect(projection.reviewVisibilityOnly, isTrue);
    });

    test('Owner WhatsApp projection excludes raw/private payload', () {
      final contentRequest = request(
        reviewChannel: AgentContentReviewChannel.ownerWhatsApp,
      );
      final projection = AgentContentOwnerWhatsAppReviewProjection.fromRequest(
        request: contentRequest,
        decision: policy.evaluate(contentRequest),
      );

      expect(projection.containsRawPrompt, isFalse);
      expect(projection.containsSourcePayload, isFalse);
      expect(projection.containsSecrets, isFalse);
      expect(projection.containsPaymentData, isFalse);
      expect(projection.containsPrivateAccountData, isFalse);
      expect(projection.sendsWhatsAppMessage, isFalse);
      expect(projection.executesApproval, isFalse);
      expect(projection.publishesContent, isFalse);
    });

    test('in-app request cannot be projected as Owner WhatsApp review', () {
      final contentRequest = request(
        reviewChannel: AgentContentReviewChannel.inApp,
      );

      expect(
        () => AgentContentOwnerWhatsAppReviewProjection.fromRequest(
          request: contentRequest,
          decision: policy.evaluate(contentRequest),
        ),
        throwsA(isA<AgentContentOwnerWhatsAppReviewProjectionException>()),
      );
    });

    test('request model itself grants no authority', () {
      final contentRequest = request();
      expect(contentRequest.draftOnly, isTrue);
      expect(contentRequest.rawPromptIsAuthority, isFalse);
      expect(contentRequest.sourceReferencesAreAuthority, isFalse);
      expect(contentRequest.publishesContent, isFalse);
      expect(contentRequest.schedulesContent, isFalse);
      expect(contentRequest.sendsEmail, isFalse);
      expect(contentRequest.sendsWhatsApp, isFalse);
      expect(contentRequest.postsSocialMedia, isFalse);
      expect(contentRequest.executesBusinessAction, isFalse);
      expect(contentRequest.grantsAuthority, isFalse);
      expect(contentRequest.grantsPermission, isFalse);
      expect(contentRequest.consumesApproval, isFalse);
      expect(contentRequest.marksRuntimeAllowed, isFalse);
      expect(contentRequest.writesBusinessData, isFalse);
      expect(contentRequest.invokesProvider, isFalse);
      expect(contentRequest.persistsRequest, isFalse);
    });

    test('policy reuses security and does not duplicate transport', () {
      expect(policy.draftOnly, isTrue);
      expect(policy.supportsOwnerAdminWhatsAppReviewVisibility, isTrue);
      expect(policy.reusesExistingOwnerWhatsAppSecurity, isTrue);
      expect(policy.reusesExistingApprovalArchitecture, isTrue);
      expect(policy.reusesExistingGroundingArchitecture, isTrue);
      expect(policy.duplicatesEmailTransport, isFalse);
      expect(policy.duplicatesWhatsAppTransport, isFalse);
    });

    test('policy cannot publish send or execute authority', () {
      expect(policy.autoPublishes, isFalse);
      expect(policy.autoSchedules, isFalse);
      expect(policy.sendsWhatsApp, isFalse);
      expect(policy.sendsEmail, isFalse);
      expect(policy.postsSocialMedia, isFalse);
      expect(policy.executesApproval, isFalse);
      expect(policy.executesBusinessAction, isFalse);
      expect(policy.grantsAuthority, isFalse);
      expect(policy.grantsPermission, isFalse);
      expect(policy.consumesApproval, isFalse);
      expect(policy.marksRuntimeAllowed, isFalse);
      expect(policy.invokesProvider, isFalse);
      expect(policy.writesBusinessData, isFalse);
      expect(policy.persistsRequest, isFalse);
    });

    test('future Phase 57 62 63 ownership remains separate', () {
      expect(policy.implementsPhase57KnowledgeLibrary, isFalse);
      expect(policy.implementsPhase62SelfDeployment, isFalse);
      expect(policy.implementsPhase63PrivacyUi, isFalse);
    });
  });
}
