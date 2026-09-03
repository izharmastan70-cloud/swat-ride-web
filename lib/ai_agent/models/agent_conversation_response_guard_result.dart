/// Pure response-output gate result for Phase 43.
///
/// This result does not execute, send, persist, or publish a response.
/// It only states whether proposed factual answer text is safe to surface.
class AgentConversationResponseGuardResult {
  const AgentConversationResponseGuardResult({
    required this.responseMode,
    required this.allowProposedAnswer,
    required this.visibleAnswerText,
    required this.safeInstruction,
    required this.mustDiscloseUncertainty,
    required this.mustRequestClarification,
    required this.mustStateVerificationNeeded,
    required this.mustEscalate,
    required this.mustRefuse,
    required this.mustUseSafeFallback,
    required this.mustNotInvent,
  });

  final String responseMode;
  final bool allowProposedAnswer;

  /// Proposed answer is only copied here when the quality pipeline explicitly
  /// allows a direct answer. Otherwise this MUST remain empty.
  final String visibleAnswerText;

  /// Deterministic safe response instruction for downstream presentation.
  final String safeInstruction;

  final bool mustDiscloseUncertainty;
  final bool mustRequestClarification;
  final bool mustStateVerificationNeeded;
  final bool mustEscalate;
  final bool mustRefuse;
  final bool mustUseSafeFallback;
  final bool mustNotInvent;

  bool get mayGrantPermission => false;
  bool get mayConsumeApproval => false;
  bool get mayWriteBusinessData => false;
  bool get mayCallProvider => false;
  bool get mayChangePrompt => false;
  bool get mayTrainModel => false;
  bool get mayDeploy => false;

  void validate() {
    if (responseMode.trim().isEmpty || safeInstruction.trim().isEmpty) {
      throw const AgentConversationResponseGuardException(
        'Response guard mode/instruction cannot be empty.',
      );
    }

    if (!mustNotInvent) {
      throw const AgentConversationResponseGuardException(
        'Response guard must always enforce mustNotInvent=true.',
      );
    }

    if (allowProposedAnswer && visibleAnswerText.trim().isEmpty) {
      throw const AgentConversationResponseGuardException(
        'Allowed proposed answer must include visible answer text.',
      );
    }

    if (!allowProposedAnswer && visibleAnswerText.isNotEmpty) {
      throw const AgentConversationResponseGuardException(
        'Blocked proposed answer must not leak visible answer text.',
      );
    }

    final int activeBlockingModes = <bool>[
      mustRequestClarification,
      mustStateVerificationNeeded,
      mustEscalate,
      mustRefuse,
      mustUseSafeFallback,
    ].where((bool value) => value).length;

    if (allowProposedAnswer && activeBlockingModes > 0) {
      throw const AgentConversationResponseGuardException(
        'Direct answer cannot retain a blocking response mode.',
      );
    }

    if (!allowProposedAnswer && activeBlockingModes != 1) {
      throw const AgentConversationResponseGuardException(
        'Blocked answer must select exactly one deterministic response mode.',
      );
    }
  }
}

class AgentConversationResponseGuardException implements Exception {
  const AgentConversationResponseGuardException(this.message);

  final String message;

  @override
  String toString() => 'AgentConversationResponseGuardException: $message';
}
