import '../constants/agent_content_intelligence_closeout_constants.dart';
import '../models/agent_content_intelligence_closeout_models.dart';

class AgentContentIntelligenceCloseoutPolicy {
  const AgentContentIntelligenceCloseoutPolicy();

  AgentContentCommentRouteDecision routeComment(
    AgentContentCommentSignal signal,
  ) {
    signal.validateStructure();

    if (signal.category == AgentContentCommentCategory.spam ||
        signal.category == AgentContentCommentCategory.toxic) {
      return _commentDecision(
        route: AgentContentCommentRoute.blockedSpamOrToxic,
        autoReplyEligible: false,
        publicDetailedReplyAllowed: false,
        privateSupportRequired: false,
        emergencyEscalationRequired: false,
      );
    }

    if (signal.category == AgentContentCommentCategory.sos) {
      return _commentDecision(
        route: AgentContentCommentRoute.emergencyEscalationRequired,
        autoReplyEligible: false,
        publicDetailedReplyAllowed: false,
        privateSupportRequired: true,
        emergencyEscalationRequired: true,
      );
    }

    if (signal.risk == AgentContentCommentRisk.high ||
        signal.hasPrivateData ||
        signal.category == AgentContentCommentCategory.payment ||
        signal.category == AgentContentCommentCategory.refund ||
        signal.category == AgentContentCommentCategory.legal ||
        signal.category == AgentContentCommentCategory.fraud ||
        signal.category == AgentContentCommentCategory.privateData) {
      return _commentDecision(
        route: AgentContentCommentRoute.privateSupportRequired,
        autoReplyEligible: false,
        publicDetailedReplyAllowed: false,
        privateSupportRequired: true,
        emergencyEscalationRequired: false,
      );
    }

    if (signal.risk == AgentContentCommentRisk.medium ||
        signal.category == AgentContentCommentCategory.complaint ||
        signal.category == AgentContentCommentCategory.confusion) {
      return _commentDecision(
        route: AgentContentCommentRoute.controlledDraftRequired,
        autoReplyEligible: false,
        publicDetailedReplyAllowed: false,
        privateSupportRequired: false,
        emergencyEscalationRequired: false,
      );
    }

    final bool lowRiskCategory =
        signal.category == AgentContentCommentCategory.greeting ||
        signal.category == AgentContentCommentCategory.faq ||
        signal.category == AgentContentCommentCategory.question ||
        signal.category == AgentContentCommentCategory.interest ||
        signal.category == AgentContentCommentCategory.positive;

    final bool hasApprovedReference = signal.approvedResponseReferenceId
        .trim()
        .isNotEmpty;

    if (signal.risk == AgentContentCommentRisk.low &&
        lowRiskCategory &&
        signal.ownerAutoReplyPolicyEnabled &&
        hasApprovedReference) {
      return _commentDecision(
        route: AgentContentCommentRoute.autoReplyEligibleDraftOnly,
        autoReplyEligible: true,
        publicDetailedReplyAllowed: true,
        privateSupportRequired: false,
        emergencyEscalationRequired: false,
      );
    }

    return _commentDecision(
      route: AgentContentCommentRoute.humanReviewRequired,
      autoReplyEligible: false,
      publicDetailedReplyAllowed: false,
      privateSupportRequired: false,
      emergencyEscalationRequired: false,
    );
  }

  AgentContentCommentRouteDecision _commentDecision({
    required String route,
    required bool autoReplyEligible,
    required bool publicDetailedReplyAllowed,
    required bool privateSupportRequired,
    required bool emergencyEscalationRequired,
  }) {
    final AgentContentCommentRouteDecision decision =
        AgentContentCommentRouteDecision(
          route: route,
          autoReplyEligible: autoReplyEligible,
          publicDetailedReplyAllowed: publicDetailedReplyAllowed,
          privateSupportRequired: privateSupportRequired,
          emergencyEscalationRequired: emergencyEscalationRequired,
          humanReviewRequired: true,
        );

    decision.validateStructure();
    return decision;
  }

  AgentContentPerformanceRecommendation evaluatePerformance(
    AgentContentPerformanceSnapshot snapshot,
  ) {
    snapshot.validateStructure();

    final bool sufficient =
        snapshot.verifiedMetrics && snapshot.sampleSufficient;

    return AgentContentPerformanceRecommendation(
      evidenceSufficient: sufficient,
      mayInformNextContent: sufficient,
      mayDeclareWinner: sufficient,
      platformSpecific: true,
      suggestedExperimentDimensions: sufficient
          ? AgentContentPerformanceExperimentDimension.values.toList()
          : const <String>[],
    );
  }

  bool canRecommendService({
    required AgentContentRotationContext context,
    required String service,
  }) {
    if (!context.isEnabled(service)) {
      return false;
    }

    final bool alternativesExist = context.enabledServices.any(
      (String value) => value != service && !context.isRecent(value),
    );

    if (context.isRecent(service) && alternativesExist) {
      return false;
    }

    return true;
  }

  String? nextRotationService(AgentContentRotationContext context) {
    for (final String service in context.enabledServices) {
      if (!context.isRecent(service)) {
        return service;
      }
    }

    if (context.enabledServices.isEmpty) {
      return null;
    }

    return context.enabledServices.first;
  }

  bool isDuplicateContent({
    required AgentContentRotationContext context,
    required String candidateFingerprint,
  }) {
    return context.isDuplicateFingerprint(candidateFingerprint);
  }

  String evaluateTrend(AgentContentTrendCandidate candidate) {
    if (!candidate.verifiedData) {
      return AgentContentTrendDecision.blockedUnverified;
    }

    if (!candidate.sourceFresh) {
      return AgentContentTrendDecision.blockedStale;
    }

    if (!candidate.serviceEnabled) {
      return AgentContentTrendDecision.blockedServiceDisabled;
    }

    if (!candidate.relevantToEnabledService) {
      return AgentContentTrendDecision.blockedIrrelevant;
    }

    if (!candidate.brandSafe) {
      return AgentContentTrendDecision.blockedBrandUnsafe;
    }

    return AgentContentTrendDecision.proposeForOwnerReview;
  }

  AgentContentOwnerWhatsAppIntelligenceProjection buildOwnerWhatsAppProjection({
    required String requestId,
    required String commentSummary,
    required String performanceSummary,
    required String nextContentSuggestion,
    required List<String> warnings,
  }) {
    return AgentContentOwnerWhatsAppIntelligenceProjection(
      requestId: requestId,
      commentSummary: commentSummary,
      performanceSummary: performanceSummary,
      nextContentSuggestion: nextContentSuggestion,
      warnings: warnings,
    );
  }

  bool get lowRiskAutoReplyRequiresOwnerPolicy => true;
  bool get lowRiskAutoReplyRequiresApprovedReference => true;
  bool get autoReplyEligibilityDoesNotSend => true;
  bool get mediumRiskUsesControlledDraft => true;
  bool get highRiskMovesToPrivateSupport => true;
  bool get sosMovesToEmergencyEscalation => true;
  bool get publicCommentCannotRefund => true;
  bool get publicCommentCannotBook => true;
  bool get publicCommentCannotMutateWallet => true;
  bool get publicCommentCannotChangePrice => true;
  bool get publicCommentCannotExecuteAdminAction => true;
  bool get publicCommentCannotExposePrivateData => true;

  bool get verifiedMetricsRequiredForLearning => true;
  bool get sampleSufficiencyRequiredForWinnerClaim => true;
  bool get abDimensionsLocked => true;
  bool get platformSpecificPerformanceProfile => true;
  bool get noGuaranteedCausalAttribution => true;
  bool get controlledImprovementOnly => true;
  bool get noSelfTraining => true;
  bool get noSelfDeployment => true;
  bool get noSecurityRuleMutation => true;
  bool get noPermissionMutation => true;
  bool get noProviderPolicyMutation => true;
  bool get noCostLimitMutation => true;

  bool get enabledServicesOnly => true;
  bool get antiRepetitionEnabled => true;
  bool get recentServiceRotationEnabled => true;
  bool get contentFingerprintDuplicateGuard => true;

  bool get trendsRequireVerifiedData => true;
  bool get trendsRequireFreshSource => true;
  bool get trendsRequireEnabledService => true;
  bool get trendsRequireRelevance => true;
  bool get trendsRequireBrandSafety => true;
  bool get trendsRequireOwnerReview => true;

  bool get ownerWhatsAppVisibilityOnly => true;
  bool get ownerWhatsAppNoRawComments => true;
  bool get ownerWhatsAppNoPrivateData => true;
  bool get ownerWhatsAppNoSendExecution => true;

  bool get invokesProvider => false;
  bool get sendsReply => false;
  bool get sendsWhatsApp => false;
  bool get publishesContent => false;
  bool get schedulesContent => false;
  bool get executesApproval => false;
  bool get executesBusinessAction => false;
  bool get writesBusinessData => false;
  bool get persistsIntelligence => false;
}
