import '../constants/agent_knowledge_answer_context_constants.dart';
import '../constants/agent_knowledge_library_contract_constants.dart';

class AgentKnowledgeAnswerContextRequest {
  AgentKnowledgeAnswerContextRequest({
    required this.requestId,
    required this.module,
    required this.topic,
    required this.requestedLanguage,
    required this.sourceLanguage,
    required this.targetScope,
    required this.scopeAuthorizationVerified,
    required Set<String> privacyRiskFlags,
  }) : privacyRiskFlags = Set<String>.unmodifiable(privacyRiskFlags);

  final String requestId;
  final String module;
  final String topic;
  final String requestedLanguage;
  final String sourceLanguage;
  final String targetScope;
  final bool scopeAuthorizationVerified;
  final Set<String> privacyRiskFlags;

  bool get exactLanguageMatch => requestedLanguage == sourceLanguage;

  bool get privacySafe => privacyRiskFlags
      .intersection(AgentKnowledgeAnswerPrivacyRisk.blocked)
      .isEmpty;

  bool get containsRawUserMessage => false;
  bool get containsRawConversation => false;
  bool get containsRawPrompt => false;
  bool get containsPhone => false;
  bool get containsEmail => false;
  bool get containsCnic => false;
  bool get containsAuthToken => false;
  bool get containsPassword => false;
  bool get containsPaymentCard => false;
  bool get containsCvv => false;
  bool get containsPin => false;
  bool get containsPreciseSensitiveLocation => false;
  bool get containsPrivateComplaintEvidence => false;
  bool get containsSecret => false;

  bool get automaticTranslationAllowed => false;
  bool get targetScopeConsumedNotGranted => true;
  bool get grantsScope => false;
  bool get expandsScope => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get executesBusinessAction => false;
  bool get invokesProvider => false;
  bool get persistsRequest => false;

  void validateStructure() {
    if (!_validId(requestId) ||
        module.trim().isEmpty ||
        topic.trim().isEmpty ||
        !AgentKnowledgeLanguage.values.contains(requestedLanguage) ||
        !AgentKnowledgeLanguage.values.contains(sourceLanguage) ||
        !AgentKnowledgeScope.values.contains(targetScope) ||
        privacyRiskFlags.length >
            AgentKnowledgeAnswerContextLimits.maxPrivacyFlags) {
      throw const FormatException('Invalid knowledge answer context request.');
    }
  }

  bool _validId(String value) {
    final String trimmed = value.trim();

    return trimmed.isNotEmpty &&
        trimmed.length <= AgentKnowledgeAnswerContextLimits.idMax &&
        RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(trimmed);
  }
}
