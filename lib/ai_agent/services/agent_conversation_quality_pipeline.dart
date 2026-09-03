import '../constants/agent_conversation_quality_constants.dart';
import '../models/agent_conversation_grounding_assessment.dart';
import '../models/agent_conversation_quality_decision.dart';
import 'agent_conversation_grounding_service.dart';
import 'agent_conversation_quality_engine.dart';

class AgentConversationQualityPipelineInput {
  const AgentConversationQualityPipelineInput({
    required this.sources,
    required this.risk,
    this.requiredVerifiedSourceCount = 1,
    this.freshnessRequired = false,
    this.requestAllowed = true,
    this.requiresHumanJudgment = false,
    this.userInputAmbiguous = false,
    this.canVerifyFresh = true,
    this.safeFallbackAvailable = true,
    this.reason = 'conversation_quality_grounding_pipeline',
  });

  final List<AgentConversationGroundingSource> sources;
  final String risk;
  final int requiredVerifiedSourceCount;
  final bool freshnessRequired;
  final bool requestAllowed;
  final bool requiresHumanJudgment;
  final bool userInputAmbiguous;
  final bool canVerifyFresh;
  final bool safeFallbackAvailable;
  final String reason;
}

class AgentConversationQualityPipelineResult {
  const AgentConversationQualityPipelineResult({
    required this.grounding,
    required this.decision,
  });

  final AgentConversationGroundingAssessment grounding;
  final AgentConversationQualityDecision decision;

  bool get mayGrantPermission => false;
  bool get mayConsumeApproval => false;
  bool get mayWriteBusinessData => false;
  bool get mayCallProvider => false;
  bool get mayChangePrompt => false;
  bool get mayTrainModel => false;
  bool get mayDeploy => false;

  void validate() {
    grounding.validate();
    decision.validate();

    if (decision.knowledgeState != grounding.knowledgeState) {
      throw const AgentConversationQualityPipelineException(
        'Decision knowledge state must come from grounding assessment.',
      );
    }

    if (decision.evidenceRefs.length != grounding.evidenceRefs.length) {
      throw const AgentConversationQualityPipelineException(
        'Decision evidence must come from grounding assessment.',
      );
    }

    if (grounding.requiresVerification &&
        decision.action == AgentConversationQualityAction.answer) {
      throw const AgentConversationQualityPipelineException(
        'Grounding requiring verification cannot produce direct ANSWER.',
      );
    }

    if (grounding.mustDiscloseUncertainty &&
        !decision.mustDiscloseUncertainty) {
      throw const AgentConversationQualityPipelineException(
        'Grounding uncertainty disclosure cannot be removed.',
      );
    }
  }
}

class AgentConversationQualityPipeline {
  const AgentConversationQualityPipeline({
    this._groundingService = const AgentConversationGroundingService(),
    this._qualityEngine = const AgentConversationQualityEngine(),
  });

  final AgentConversationGroundingService _groundingService;
  final AgentConversationQualityEngine _qualityEngine;

  bool get providerExecutionAllowed => false;
  bool get firestoreReadAllowed => false;
  bool get firestoreWriteAllowed => false;
  bool get runtimeActionAllowed => false;
  bool get permissionGrantAllowed => false;
  bool get approvalConsumptionAllowed => false;
  bool get promptMutationAllowed => false;
  bool get modelTrainingAllowed => false;
  bool get deploymentAllowed => false;

  AgentConversationQualityPipelineResult evaluate(
    AgentConversationQualityPipelineInput input,
  ) {
    if (!AgentConversationRisk.values.contains(input.risk)) {
      throw AgentConversationQualityPipelineException(
        'Invalid conversation risk "${input.risk}".',
      );
    }

    if (input.reason.trim().isEmpty) {
      throw const AgentConversationQualityPipelineException(
        'Pipeline reason cannot be empty.',
      );
    }

    final AgentConversationGroundingAssessment grounding = _groundingService
        .assess(
          sources: input.sources,
          requiredVerifiedSourceCount: input.requiredVerifiedSourceCount,
          freshnessRequired: input.freshnessRequired,
        );

    final AgentConversationQualityDecision decision = _qualityEngine.decide(
      AgentConversationQualityInput(
        knowledgeState: grounding.knowledgeState,
        risk: input.risk,
        confidence: grounding.confidence,
        evidenceRefs: grounding.evidenceRefs,
        requestAllowed: input.requestAllowed,
        requiresHumanJudgment: input.requiresHumanJudgment,
        userInputAmbiguous: input.userInputAmbiguous,
        freshnessRequired:
            input.freshnessRequired || grounding.requiresVerification,
        canVerifyFresh: input.canVerifyFresh,
        safeFallbackAvailable: input.safeFallbackAvailable,
        reason: input.reason,
      ),
    );

    final AgentConversationQualityPipelineResult result =
        AgentConversationQualityPipelineResult(
          grounding: grounding,
          decision: decision,
        );

    result.validate();
    return result;
  }
}

class AgentConversationQualityPipelineException implements Exception {
  const AgentConversationQualityPipelineException(this.message);

  final String message;

  @override
  String toString() => 'AgentConversationQualityPipelineException: $message';
}
