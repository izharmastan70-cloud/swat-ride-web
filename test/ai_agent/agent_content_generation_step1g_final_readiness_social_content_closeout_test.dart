import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_content_intelligence_closeout_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_content_intelligence_closeout_models.dart';
import 'package:swat_ride/ai_agent/services/agent_content_final_readiness_service.dart';
import 'package:swat_ride/ai_agent/services/agent_content_intelligence_closeout_policy.dart';

void main() {
  const AgentContentIntelligenceCloseoutPolicy policy =
      AgentContentIntelligenceCloseoutPolicy();

  const AgentContentFinalReadinessService readiness =
      AgentContentFinalReadinessService();

  AgentContentCommentSignal signal({
    String category = AgentContentCommentCategory.faq,
    String risk = AgentContentCommentRisk.low,
    bool privateData = false,
    bool ownerPolicy = true,
    String approvedReference = 'approved_faq:ride_001',
  }) {
    return AgentContentCommentSignal(
      commentId: 'comment_001',
      category: category,
      risk: risk,
      hasPrivateData: privateData,
      ownerAutoReplyPolicyEnabled: ownerPolicy,
      approvedResponseReferenceId: approvedReference,
    );
  }

  AgentContentPerformanceSnapshot performance({
    bool verified = true,
    bool sufficient = true,
  }) {
    return AgentContentPerformanceSnapshot(
      contentId: 'content_001',
      platform: 'instagram',
      verifiedMetrics: verified,
      sampleSufficient: sufficient,
      views: 1000,
      reach: 800,
      watchTimeSeconds: 9000,
      averageWatchTimeSeconds: 9,
      likes: 100,
      comments: 20,
      shares: 15,
      saves: 10,
      clicks: 30,
      attributedConversions: 4,
    );
  }

  group('Phase 56 Step 1G final closeout', () {
    test('15 comment categories are locked', () {
      expect(AgentContentCommentCategory.values.length, 15);
    });

    test('low-risk approved FAQ may be auto-reply eligible draft only', () {
      final result = policy.routeComment(signal());

      expect(result.route, AgentContentCommentRoute.autoReplyEligibleDraftOnly);
      expect(result.autoReplyEligible, true);
      expect(result.humanReviewRequired, true);
      expect(result.sendsReply, false);
    });

    test('low-risk auto-reply requires Owner policy', () {
      final result = policy.routeComment(signal(ownerPolicy: false));

      expect(result.autoReplyEligible, false);
      expect(result.route, AgentContentCommentRoute.humanReviewRequired);
    });

    test('low-risk auto-reply requires approved response reference', () {
      final result = policy.routeComment(signal(approvedReference: ''));

      expect(result.autoReplyEligible, false);
    });

    test('medium complaint routes to controlled draft', () {
      final result = policy.routeComment(
        signal(
          category: AgentContentCommentCategory.complaint,
          risk: AgentContentCommentRisk.medium,
        ),
      );

      expect(result.route, AgentContentCommentRoute.controlledDraftRequired);
      expect(result.autoReplyEligible, false);
    });

    test('high-risk payment goes private support', () {
      final result = policy.routeComment(
        signal(
          category: AgentContentCommentCategory.payment,
          risk: AgentContentCommentRisk.high,
        ),
      );

      expect(result.route, AgentContentCommentRoute.privateSupportRequired);
      expect(result.publicDetailedReplyAllowed, false);
      expect(result.privateSupportRequired, true);
    });

    test('refund never executes from public comment', () {
      final result = policy.routeComment(
        signal(
          category: AgentContentCommentCategory.refund,
          risk: AgentContentCommentRisk.high,
        ),
      );

      expect(result.performsRefund, false);
      expect(result.mutatesWallet, false);
      expect(result.executesBusinessAction, false);
    });

    test('SOS routes to emergency escalation without public detail', () {
      final result = policy.routeComment(
        signal(
          category: AgentContentCommentCategory.sos,
          risk: AgentContentCommentRisk.high,
        ),
      );

      expect(
        result.route,
        AgentContentCommentRoute.emergencyEscalationRequired,
      );
      expect(result.emergencyEscalationRequired, true);
      expect(result.publicDetailedReplyAllowed, false);
      expect(result.sendsReply, false);
    });

    test('spam and toxic signals are blocked from learning/reply route', () {
      final spam = policy.routeComment(
        signal(category: AgentContentCommentCategory.spam),
      );
      final toxic = policy.routeComment(
        signal(category: AgentContentCommentCategory.toxic),
      );

      expect(spam.route, AgentContentCommentRoute.blockedSpamOrToxic);
      expect(toxic.route, AgentContentCommentRoute.blockedSpamOrToxic);
    });

    test('private data flag forces private support', () {
      final result = policy.routeComment(signal(privateData: true));

      expect(result.route, AgentContentCommentRoute.privateSupportRequired);
      expect(result.exposesPrivateData, false);
    });

    test('comment signal stores no raw/private identifiers', () {
      final value = signal();

      expect(value.containsRawCommentText, false);
      expect(value.containsPhone, false);
      expect(value.containsEmail, false);
      expect(value.containsCnic, false);
      expect(value.containsPaymentData, false);
      expect(value.grantsAuthority, false);
      expect(value.executesReply, false);
      expect(value.executesBusinessAction, false);
      expect(value.persistsSignal, false);
    });

    test('verified sufficient performance may inform next content', () {
      final result = policy.evaluatePerformance(performance());

      expect(result.evidenceSufficient, true);
      expect(result.mayInformNextContent, true);
      expect(result.mayDeclareWinner, true);
      expect(result.platformSpecific, true);
      expect(
        result.suggestedExperimentDimensions.toSet(),
        AgentContentPerformanceExperimentDimension.values,
      );
    });

    test('unverified metrics cannot inform learning', () {
      final result = policy.evaluatePerformance(performance(verified: false));

      expect(result.evidenceSufficient, false);
      expect(result.mayInformNextContent, false);
      expect(result.mayDeclareWinner, false);
    });

    test('small/noisy sample cannot declare winner', () {
      final result = policy.evaluatePerformance(performance(sufficient: false));

      expect(result.evidenceSufficient, false);
      expect(result.mayDeclareWinner, false);
    });

    test('performance recommendation never self-trains/deploys', () {
      final result = policy.evaluatePerformance(performance());

      expect(result.controlledImprovementOnly, true);
      expect(result.selfTraining, false);
      expect(result.selfDeployment, false);
      expect(result.securityRuleChange, false);
      expect(result.permissionChange, false);
      expect(result.providerPolicyChange, false);
      expect(result.costLimitChange, false);
      expect(result.autoPublishes, false);
      expect(result.persistsRecommendation, false);
    });

    test(
      'performance snapshot treats conversions as attribution not guarantee',
      () {
        final value = performance();

        expect(value.usesVerifiedMetricsOnlyForLearning, true);
        expect(value.conversionsAreAttributionNotGuarantee, true);
        expect(value.autoTrainsModel, false);
        expect(value.changesProductionBehavior, false);
        expect(value.persistsSnapshot, false);
      },
    );

    test('service rotation recommends enabled non-recent service first', () {
      final context = AgentContentRotationContext(
        enabledServices: const <String>['ride', 'food', 'hotel'],
        recentServices: const <String>['ride', 'food'],
        recentContentFingerprints: const <String>[],
      );

      expect(policy.nextRotationService(context), 'hotel');
      expect(
        policy.canRecommendService(context: context, service: 'ride'),
        false,
      );
      expect(
        policy.canRecommendService(context: context, service: 'hotel'),
        true,
      );
    });

    test('disabled service cannot enter rotation', () {
      final context = AgentContentRotationContext(
        enabledServices: const <String>['ride'],
        recentServices: const <String>[],
        recentContentFingerprints: const <String>[],
      );

      expect(
        policy.canRecommendService(context: context, service: 'food'),
        false,
      );
    });

    test('recent fingerprint blocks repeated content', () {
      final context = AgentContentRotationContext(
        enabledServices: const <String>['ride'],
        recentServices: const <String>[],
        recentContentFingerprints: const <String>['fingerprint_001'],
      );

      expect(
        policy.isDuplicateContent(
          context: context,
          candidateFingerprint: 'fingerprint_001',
        ),
        true,
      );
    });

    test('verified fresh relevant safe trend is proposal only', () {
      const candidate = AgentContentTrendCandidate(
        trendId: 'trend_001',
        verifiedData: true,
        sourceFresh: true,
        relevantToEnabledService: true,
        brandSafe: true,
        serviceEnabled: true,
      );

      expect(
        policy.evaluateTrend(candidate),
        AgentContentTrendDecision.proposeForOwnerReview,
      );
      expect(candidate.ownerApprovalRequired, true);
      expect(candidate.autoPublishes, false);
      expect(candidate.autoChangesStrategy, false);
    });

    test('unverified trend is blocked', () {
      const candidate = AgentContentTrendCandidate(
        trendId: 'trend_002',
        verifiedData: false,
        sourceFresh: true,
        relevantToEnabledService: true,
        brandSafe: true,
        serviceEnabled: true,
      );

      expect(
        policy.evaluateTrend(candidate),
        AgentContentTrendDecision.blockedUnverified,
      );
    });

    test('stale trend is blocked', () {
      const candidate = AgentContentTrendCandidate(
        trendId: 'trend_003',
        verifiedData: true,
        sourceFresh: false,
        relevantToEnabledService: true,
        brandSafe: true,
        serviceEnabled: true,
      );

      expect(
        policy.evaluateTrend(candidate),
        AgentContentTrendDecision.blockedStale,
      );
    });

    test('brand-unsafe trend is blocked', () {
      const candidate = AgentContentTrendCandidate(
        trendId: 'trend_004',
        verifiedData: true,
        sourceFresh: true,
        relevantToEnabledService: true,
        brandSafe: false,
        serviceEnabled: true,
      );

      expect(
        policy.evaluateTrend(candidate),
        AgentContentTrendDecision.blockedBrandUnsafe,
      );
    });

    test('disabled-service trend is blocked', () {
      const candidate = AgentContentTrendCandidate(
        trendId: 'trend_005',
        verifiedData: true,
        sourceFresh: true,
        relevantToEnabledService: true,
        brandSafe: true,
        serviceEnabled: false,
      );

      expect(
        policy.evaluateTrend(candidate),
        AgentContentTrendDecision.blockedServiceDisabled,
      );
    });

    test('Owner WhatsApp intelligence projection is visibility only', () {
      final projection = policy.buildOwnerWhatsAppProjection(
        requestId: 'content_001',
        commentSummary: '2 FAQ, 1 complaint.',
        performanceSummary: 'Verified retention improved.',
        nextContentSuggestion: 'Try shorter opening hook.',
        warnings: const <String>['No causal claim.'],
      );

      expect(projection.reviewVisibilityOnly, true);
      expect(projection.containsRawComments, false);
      expect(projection.containsRawPrompt, false);
      expect(projection.containsRawSourcePayload, false);
      expect(projection.containsPhone, false);
      expect(projection.containsEmail, false);
      expect(projection.containsCnic, false);
      expect(projection.containsPaymentData, false);
      expect(projection.containsSecrets, false);
      expect(projection.sendsWhatsApp, false);
      expect(projection.executesApproval, false);
      expect(projection.publishesContent, false);
      expect(projection.schedulesContent, false);
      expect(projection.executesBusinessAction, false);
      expect(projection.grantsAuthority, false);
      expect(projection.persistsProjection, false);
    });

    test('policy locks social intelligence safety', () {
      expect(policy.lowRiskAutoReplyRequiresOwnerPolicy, true);
      expect(policy.lowRiskAutoReplyRequiresApprovedReference, true);
      expect(policy.autoReplyEligibilityDoesNotSend, true);
      expect(policy.mediumRiskUsesControlledDraft, true);
      expect(policy.highRiskMovesToPrivateSupport, true);
      expect(policy.sosMovesToEmergencyEscalation, true);
      expect(policy.publicCommentCannotRefund, true);
      expect(policy.publicCommentCannotBook, true);
      expect(policy.publicCommentCannotMutateWallet, true);
      expect(policy.publicCommentCannotChangePrice, true);
      expect(policy.publicCommentCannotExecuteAdminAction, true);
      expect(policy.publicCommentCannotExposePrivateData, true);
    });

    test('policy locks evidence-based controlled learning', () {
      expect(policy.verifiedMetricsRequiredForLearning, true);
      expect(policy.sampleSufficiencyRequiredForWinnerClaim, true);
      expect(policy.abDimensionsLocked, true);
      expect(policy.platformSpecificPerformanceProfile, true);
      expect(policy.noGuaranteedCausalAttribution, true);
      expect(policy.controlledImprovementOnly, true);
      expect(policy.noSelfTraining, true);
      expect(policy.noSelfDeployment, true);
      expect(policy.noSecurityRuleMutation, true);
      expect(policy.noPermissionMutation, true);
      expect(policy.noProviderPolicyMutation, true);
      expect(policy.noCostLimitMutation, true);
    });

    test('policy locks rotation/repetition/trend gates', () {
      expect(policy.enabledServicesOnly, true);
      expect(policy.antiRepetitionEnabled, true);
      expect(policy.recentServiceRotationEnabled, true);
      expect(policy.contentFingerprintDuplicateGuard, true);
      expect(policy.trendsRequireVerifiedData, true);
      expect(policy.trendsRequireFreshSource, true);
      expect(policy.trendsRequireEnabledService, true);
      expect(policy.trendsRequireRelevance, true);
      expect(policy.trendsRequireBrandSafety, true);
      expect(policy.trendsRequireOwnerReview, true);
    });

    test('policy itself executes nothing external', () {
      expect(policy.ownerWhatsAppVisibilityOnly, true);
      expect(policy.ownerWhatsAppNoRawComments, true);
      expect(policy.ownerWhatsAppNoPrivateData, true);
      expect(policy.ownerWhatsAppNoSendExecution, true);
      expect(policy.invokesProvider, false);
      expect(policy.sendsReply, false);
      expect(policy.sendsWhatsApp, false);
      expect(policy.publishesContent, false);
      expect(policy.schedulesContent, false);
      expect(policy.executesApproval, false);
      expect(policy.executesBusinessAction, false);
      expect(policy.writesBusinessData, false);
      expect(policy.persistsIntelligence, false);
    });

    test('final readiness reports foundation ready not production active', () {
      expect(
        readiness.readinessStatus,
        AgentContentCloseoutReadinessStatus.foundationReadyNotProductionActive,
      );
    });

    test('final readiness confirms all Phase 56 foundation capabilities', () {
      expect(readiness.step1ARequestBoundaryPresent, true);
      expect(readiness.step1BRequestSafetyPresent, true);
      expect(readiness.step1CPlatformCreativePackagePresent, true);
      expect(readiness.step1DGroundingGatePresent, true);
      expect(readiness.step1EHumanReviewLifecyclePresent, true);
      expect(readiness.step1FProviderCostPrivacySafetyPresent, true);
      expect(readiness.step1GCommentIntelligencePresent, true);
      expect(readiness.step1GPerformanceLearningPresent, true);
      expect(readiness.step1GRotationAntiRepetitionPresent, true);
      expect(readiness.step1GTrendProposalGatePresent, true);
      expect(readiness.step1GOwnerWhatsAppVisibilityPresent, true);
    });

    test('final readiness preserves core content truth/review boundaries', () {
      expect(readiness.problemSolutionBenefitRequired, true);
      expect(readiness.ethicalHookContractPresent, true);
      expect(readiness.realVisualPriorityPresent, true);
      expect(readiness.aiVisualSupplementaryOnly, true);
      expect(readiness.verifiedFeatureAndServiceStateRequired, true);
      expect(readiness.humanReviewRequired, true);
      expect(readiness.approvalReadyIsNotApproval, true);
      expect(readiness.approvalReadyIsNotPublished, true);
    });

    test('final readiness preserves Free-First paid-cost policy', () {
      expect(readiness.templateCodeFirst, true);
      expect(readiness.freeAiFirst, true);
      expect(readiness.localAiOptional, true);
      expect(readiness.paidAiLast, true);
      expect(readiness.paidAiOnOffRequired, true);
      expect(readiness.askBeforePaidSupported, true);
      expect(readiness.paidCostLimitsRequired, true);
      expect(readiness.paidCostLogsRequired, true);
      expect(readiness.paidBudgetExhaustionStopsPaidOnly, true);
    });

    test('final readiness preserves controlled learning/rotation/trends', () {
      expect(readiness.commentsAreSignalsNotAuthority, true);
      expect(readiness.autoReplyIsEligibilityOnly, true);
      expect(readiness.performanceUsesVerifiedEvidence, true);
      expect(readiness.noisySampleCannotClaimWinner, true);
      expect(readiness.controlledImprovementNoSelfTraining, true);
      expect(readiness.enabledServiceRotationOnly, true);
      expect(readiness.antiRepetitionPresent, true);
      expect(readiness.trendsNeedOwnerReview, true);
    });

    test('production execution/connectors remain deliberately inactive', () {
      expect(readiness.ownerWhatsAppReviewVisibilityOnly, true);
      expect(readiness.ownerWhatsAppNoRawPrivatePayload, true);
      expect(readiness.ownerWhatsAppSendExecutionImplemented, false);
      expect(readiness.providerExecutionImplemented, false);
      expect(readiness.socialPublishExecutionImplemented, false);
      expect(readiness.autoReplySendExecutionImplemented, false);
      expect(readiness.analyticsPlatformConnectorImplemented, false);
      expect(readiness.socialCommentConnectorImplemented, false);
      expect(readiness.socialAccountAuthorizationImplemented, false);
      expect(readiness.trustedBackendPersistenceImplemented, false);
    });

    test('Phase ownership remains separate', () {
      expect(readiness.phase55VideoCatalogSeparate, true);
      expect(readiness.phase57KnowledgeLibrarySeparate, true);
      expect(readiness.phase62SafeTrainingDeploymentSeparate, true);
      expect(readiness.phase63PrivacyRetentionUiSeparate, true);
    });

    test('external failures cannot break SWAT RIDE core app', () {
      expect(readiness.providerFailureBreaksCoreApp, false);
      expect(readiness.aiFailureBreaksCoreApp, false);
      expect(readiness.socialPlatformFailureBreaksCoreApp, false);
      expect(readiness.commentConnectorFailureBreaksCoreApp, false);
    });

    test('final readiness grants no production authority', () {
      expect(readiness.grantsPermission, false);
      expect(readiness.consumesApproval, false);
      expect(readiness.marksRuntimeAllowed, false);
      expect(readiness.executesBusinessAction, false);
      expect(readiness.writesBusinessData, false);
      expect(readiness.publishesContent, false);
      expect(readiness.schedulesContent, false);
      expect(readiness.sendsWhatsApp, false);
      expect(readiness.sendsSocialReply, false);
      expect(readiness.selfTrains, false);
      expect(readiness.selfDeploys, false);
    });
  });
}
