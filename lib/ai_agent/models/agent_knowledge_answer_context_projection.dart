import '../constants/agent_knowledge_answer_context_constants.dart';

class AgentKnowledgeAnswerCitationProjection {
  const AgentKnowledgeAnswerCitationProjection({
    required this.itemId,
    required this.sourceId,
    required this.sourceReferenceId,
    required this.contentReferenceId,
    required this.sourceType,
    required this.authorityClass,
    required this.revision,
    required this.sourceVersion,
    required this.claimKey,
  });

  final String itemId;
  final String sourceId;
  final String sourceReferenceId;
  final String contentReferenceId;
  final String sourceType;
  final String authorityClass;
  final int revision;
  final String sourceVersion;
  final String claimKey;

  bool get metadataOnly => true;
  bool get containsClaimValueBinding => false;
  bool get containsRawKnowledgeContent => false;
  bool get containsRawSourcePayload => false;
  bool get containsPrivatePayload => false;
  bool get grantsAuthority => false;
  bool get expandsScope => false;
  bool get executesBusinessAction => false;
}

class AgentKnowledgeAnswerContextProjection {
  AgentKnowledgeAnswerContextProjection({
    required this.status,
    required this.requestId,
    required this.module,
    required this.topic,
    required this.language,
    required this.targetScope,
    required this.claimKey,
    required this.selectedClaimValueBinding,
    required List<AgentKnowledgeAnswerCitationProjection> citations,
    required List<String> reasonCodes,
  }) : citations = List<AgentKnowledgeAnswerCitationProjection>.unmodifiable(
         citations,
       ),
       reasonCodes = List<String>.unmodifiable(reasonCodes);

  final String status;
  final String requestId;
  final String module;
  final String topic;
  final String language;
  final String targetScope;
  final String claimKey;

  /// Opaque reviewed binding only; not raw user-visible answer text.
  final String selectedClaimValueBinding;

  final List<AgentKnowledgeAnswerCitationProjection> citations;
  final List<String> reasonCodes;

  bool get ready =>
      status == AgentKnowledgeAnswerContextStatus.readyForGroundedAnswer &&
      selectedClaimValueBinding.isNotEmpty &&
      citations.isNotEmpty;

  bool get noAnswerRequired => !ready;
  bool get noAnswerMustNotGuess => true;

  bool get privacyMinimized => true;
  bool get exactLanguagePreserved => true;
  bool get automaticTranslationPerformed => false;
  bool get citationsMetadataOnly => true;
  bool get rawKnowledgeContentIncluded => false;
  bool get rawSourcePayloadIncluded => false;
  bool get rawConversationIncluded => false;
  bool get rawPromptIncluded => false;
  bool get privateIdentityIncluded => false;
  bool get paymentDataIncluded => false;
  bool get secretIncluded => false;

  bool get conversationGroundingRequired => true;
  bool get responseGuardRequired => true;
  bool get providerMayReceiveOnlyApprovedProjectionLater => true;

  bool get grantsPermission => false;
  bool get expandsScope => false;
  bool get consumesApproval => false;
  bool get executesBusinessAction => false;
  bool get writesBusinessData => false;
  bool get sendsWhatsApp => false;
  bool get invokesProvider => false;
  bool get persistsProjection => false;

  void validateStructure() {
    if (!AgentKnowledgeAnswerContextStatus.values.contains(status) ||
        requestId.trim().isEmpty ||
        reasonCodes.isEmpty ||
        reasonCodes.length > AgentKnowledgeAnswerContextLimits.maxReasonCodes ||
        citations.length >
            AgentKnowledgeAnswerContextLimits.maxCitationReferences) {
      throw const FormatException(
        'Invalid knowledge answer context projection.',
      );
    }

    if (ready &&
        (claimKey.trim().isEmpty ||
            selectedClaimValueBinding.isEmpty ||
            citations.isEmpty)) {
      throw const FormatException(
        'Ready knowledge answer context requires binding and citations.',
      );
    }

    if (!ready &&
        (selectedClaimValueBinding.isNotEmpty || citations.isNotEmpty)) {
      throw const FormatException(
        'No-context decision cannot expose binding/citations.',
      );
    }
  }
}
