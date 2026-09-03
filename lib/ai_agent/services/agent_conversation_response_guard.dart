import '../constants/agent_conversation_quality_constants.dart';
import '../models/agent_conversation_response_guard_result.dart';
import 'agent_conversation_quality_pipeline.dart';

class AgentConversationResponseGuard {
  const AgentConversationResponseGuard();

  static const String modeAnswer = 'ANSWER';
  static const String modeVerify = 'VERIFY';
  static const String modeClarify = 'CLARIFY';
  static const String modeSafeFallback = 'SAFE_FALLBACK';
  static const String modeEscalate = 'ESCALATE';
  static const String modeRefuse = 'REFUSE';

  bool get providerExecutionAllowed => false;
  bool get firestoreReadAllowed => false;
  bool get firestoreWriteAllowed => false;
  bool get runtimeActionAllowed => false;
  bool get permissionGrantAllowed => false;
  bool get approvalConsumptionAllowed => false;
  bool get promptMutationAllowed => false;
  bool get modelTrainingAllowed => false;
  bool get deploymentAllowed => false;

  AgentConversationResponseGuardResult guard({
    required AgentConversationQualityPipelineResult qualityResult,
    required String proposedAnswer,
  }) {
    qualityResult.validate();

    final String action = qualityResult.decision.action;

    if (action == AgentConversationQualityAction.answer) {
      if (!qualityResult.decision.mayAnswerDirectly) {
        throw const AgentConversationResponseGuardException(
          'ANSWER action is invalid unless mayAnswerDirectly=true.',
        );
      }

      if (proposedAnswer.trim().isEmpty) {
        throw const AgentConversationResponseGuardException(
          'Direct answer text cannot be empty.',
        );
      }

      return _result(
        responseMode: modeAnswer,
        allowProposedAnswer: true,
        visibleAnswerText: proposedAnswer.trim(),
        safeInstruction: 'Surface only the verified evidence-supported answer.',
        mustDiscloseUncertainty: qualityResult.decision.mustDiscloseUncertainty,
      );
    }

    if (action == AgentConversationQualityAction.verify) {
      return _result(
        responseMode: modeVerify,
        safeInstruction:
            'State that the fact needs verification before giving a factual answer.',
        mustDiscloseUncertainty: true,
        mustStateVerificationNeeded: true,
      );
    }

    if (action == AgentConversationQualityAction.clarify) {
      return _result(
        responseMode: modeClarify,
        safeInstruction:
            'Ask for the missing clarification and do not guess the intended meaning.',
        mustDiscloseUncertainty: true,
        mustRequestClarification: true,
      );
    }

    if (action == AgentConversationQualityAction.safeFallback) {
      return _result(
        responseMode: modeSafeFallback,
        safeInstruction:
            'Use a safe fallback that states the information is not sufficiently supported.',
        mustDiscloseUncertainty: true,
        mustUseSafeFallback: true,
      );
    }

    if (action == AgentConversationQualityAction.escalate) {
      return _result(
        responseMode: modeEscalate,
        safeInstruction:
            'State that human review is required and escalate without inventing an answer.',
        mustDiscloseUncertainty: true,
        mustEscalate: true,
      );
    }

    if (action == AgentConversationQualityAction.refuse) {
      return _result(
        responseMode: modeRefuse,
        safeInstruction:
            'Refuse the disallowed request without revealing blocked answer content.',
        mustDiscloseUncertainty: qualityResult.decision.mustDiscloseUncertainty,
        mustRefuse: true,
      );
    }

    throw AgentConversationResponseGuardException(
      'Unsupported quality action "$action".',
    );
  }

  AgentConversationResponseGuardResult _result({
    required String responseMode,
    required String safeInstruction,
    bool allowProposedAnswer = false,
    String visibleAnswerText = '',
    bool mustDiscloseUncertainty = false,
    bool mustRequestClarification = false,
    bool mustStateVerificationNeeded = false,
    bool mustEscalate = false,
    bool mustRefuse = false,
    bool mustUseSafeFallback = false,
  }) {
    final AgentConversationResponseGuardResult result =
        AgentConversationResponseGuardResult(
          responseMode: responseMode,
          allowProposedAnswer: allowProposedAnswer,
          visibleAnswerText: visibleAnswerText,
          safeInstruction: safeInstruction,
          mustDiscloseUncertainty: mustDiscloseUncertainty,
          mustRequestClarification: mustRequestClarification,
          mustStateVerificationNeeded: mustStateVerificationNeeded,
          mustEscalate: mustEscalate,
          mustRefuse: mustRefuse,
          mustUseSafeFallback: mustUseSafeFallback,
          mustNotInvent: true,
        );

    result.validate();
    return result;
  }
}
