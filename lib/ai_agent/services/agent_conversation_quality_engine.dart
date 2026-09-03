import '../constants/agent_conversation_quality_constants.dart';
import '../models/agent_conversation_quality_decision.dart';

/// Pure signals used by the deterministic Phase 43 conversation-quality engine.
///
/// These signals are descriptive only. They do not call a provider, fetch
/// Firestore, consume approvals, or execute runtime actions.
class AgentConversationQualityInput {
  const AgentConversationQualityInput({
    required this.knowledgeState,
    required this.risk,
    required this.confidence,
    required this.evidenceRefs,
    this.requestAllowed = true,
    this.requiresHumanJudgment = false,
    this.userInputAmbiguous = false,
    this.freshnessRequired = false,
    this.canVerifyFresh = true,
    this.safeFallbackAvailable = true,
    this.reason = 'conversation_quality_deterministic_decision',
  });

  final String knowledgeState;
  final String risk;
  final double confidence;
  final List<AgentConversationEvidenceRef> evidenceRefs;

  final bool requestAllowed;
  final bool requiresHumanJudgment;
  final bool userInputAmbiguous;
  final bool freshnessRequired;
  final bool canVerifyFresh;
  final bool safeFallbackAvailable;
  final String reason;

  bool get hasVerifiedEvidence =>
      evidenceRefs.any((AgentConversationEvidenceRef value) => value.verified);

  void validate() {
    if (!AgentConversationKnowledgeState.values.contains(knowledgeState)) {
      throw AgentConversationQualityException(
        'Invalid input knowledge state "$knowledgeState".',
      );
    }

    if (!AgentConversationRisk.values.contains(risk)) {
      throw AgentConversationQualityException('Invalid input risk "$risk".');
    }

    if (confidence < 0 || confidence > 1) {
      throw const AgentConversationQualityException(
        'Input confidence must be between 0.0 and 1.0.',
      );
    }

    if (reason.trim().isEmpty) {
      throw const AgentConversationQualityException(
        'Input reason cannot be empty.',
      );
    }

    for (final AgentConversationEvidenceRef evidence in evidenceRefs) {
      evidence.validate();
    }
  }
}

/// Deterministic anti-wrong-answer engine.
///
/// Precedence:
/// 1. REFUSE disallowed requests.
/// 2. ESCALATE required human judgment.
/// 3. CLARIFY ambiguous user input.
/// 4. VERIFY stale/conflicting/unverified/unsupported evidence when possible.
/// 5. ANSWER only with sufficient verified evidence + confidence threshold.
/// 6. SAFE_FALLBACK when evidence remains insufficient.
/// 7. ESCALATE when no safe fallback is available.
///
/// This engine cannot execute the chosen action. It only returns a decision.
class AgentConversationQualityEngine {
  const AgentConversationQualityEngine();

  static const double normalAnswerThreshold = 0.80;
  static const double highRiskAnswerThreshold = 0.95;

  bool get providerExecutionAllowed => false;
  bool get firestoreReadAllowed => false;
  bool get firestoreWriteAllowed => false;
  bool get runtimeActionAllowed => false;
  bool get permissionGrantAllowed => false;
  bool get approvalConsumptionAllowed => false;
  bool get promptMutationAllowed => false;
  bool get modelTrainingAllowed => false;
  bool get deploymentAllowed => false;

  AgentConversationQualityDecision decide(AgentConversationQualityInput input) {
    input.validate();

    if (!input.requestAllowed) {
      return _decision(
        input: input,
        action: AgentConversationQualityAction.refuse,
        mustDiscloseUncertainty: _knowledgeNeedsDisclosure(
          input.knowledgeState,
        ),
      );
    }

    if (input.requiresHumanJudgment) {
      return _decision(
        input: input,
        action: AgentConversationQualityAction.escalate,
        requiresHumanEscalation: true,
        mustDiscloseUncertainty: true,
      );
    }

    if (input.userInputAmbiguous) {
      return _decision(
        input: input,
        action: AgentConversationQualityAction.clarify,
        requiresClarification: true,
        mustDiscloseUncertainty: true,
      );
    }

    final bool knowledgeNeedsVerification =
        input.knowledgeState == AgentConversationKnowledgeState.conflicting ||
        input.knowledgeState == AgentConversationKnowledgeState.unverified;

    final double answerThreshold = _isHighRisk(input.risk)
        ? highRiskAnswerThreshold
        : normalAnswerThreshold;

    final bool directAnswerEvidenceReady =
        input.knowledgeState == AgentConversationKnowledgeState.sufficient &&
        input.hasVerifiedEvidence &&
        input.confidence >= answerThreshold &&
        !input.freshnessRequired;

    if (directAnswerEvidenceReady) {
      return _decision(
        input: input,
        action: AgentConversationQualityAction.answer,
        mustDiscloseUncertainty: false,
      );
    }

    final bool answerNeedsVerification =
        input.freshnessRequired ||
        knowledgeNeedsVerification ||
        (input.knowledgeState == AgentConversationKnowledgeState.sufficient &&
            (!input.hasVerifiedEvidence || input.confidence < answerThreshold));

    if (answerNeedsVerification && input.canVerifyFresh) {
      return _decision(
        input: input,
        action: AgentConversationQualityAction.verify,
        requiresFreshVerification: true,
        mustDiscloseUncertainty: true,
      );
    }

    if (input.safeFallbackAvailable) {
      return _decision(
        input: input,
        action: AgentConversationQualityAction.safeFallback,
        mustDiscloseUncertainty: true,
      );
    }

    return _decision(
      input: input,
      action: AgentConversationQualityAction.escalate,
      requiresHumanEscalation: true,
      mustDiscloseUncertainty: true,
    );
  }

  AgentConversationQualityDecision _decision({
    required AgentConversationQualityInput input,
    required String action,
    bool requiresFreshVerification = false,
    bool requiresClarification = false,
    bool requiresHumanEscalation = false,
    bool mustDiscloseUncertainty = false,
  }) {
    final AgentConversationQualityDecision decision =
        AgentConversationQualityDecision(
          action: action,
          knowledgeState: input.knowledgeState,
          risk: input.risk,
          confidence: input.confidence,
          reason: input.reason,
          evidenceRefs: List<AgentConversationEvidenceRef>.unmodifiable(
            input.evidenceRefs,
          ),
          requiresFreshVerification: requiresFreshVerification,
          requiresClarification: requiresClarification,
          requiresHumanEscalation: requiresHumanEscalation,
          mustDiscloseUncertainty: mustDiscloseUncertainty,
          mustNotInvent: true,
        );

    decision.validate();
    return decision;
  }

  bool _isHighRisk(String risk) =>
      risk == AgentConversationRisk.high ||
      risk == AgentConversationRisk.critical;

  bool _knowledgeNeedsDisclosure(String knowledgeState) =>
      knowledgeState == AgentConversationKnowledgeState.missing ||
      knowledgeState == AgentConversationKnowledgeState.conflicting ||
      knowledgeState == AgentConversationKnowledgeState.unverified;
}
