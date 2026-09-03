import '../constants/agent_knowledge_library_contract_constants.dart';
import '../constants/agent_knowledge_retrieval_constants.dart';

class AgentKnowledgeRetrievalRequest {
  AgentKnowledgeRetrievalRequest({
    required this.requestId,
    required this.module,
    required this.topic,
    required this.language,
    required Set<String> allowedScopes,
    required this.scopeAuthorizationVerified,
    this.maxResults = 5,
    this.minimumScore = AgentKnowledgeRetrievalLimits.defaultMinimumScore,
  }) : allowedScopes = Set<String>.unmodifiable(allowedScopes);

  final String requestId;
  final String module;
  final String topic;
  final String language;
  final Set<String> allowedScopes;
  final bool scopeAuthorizationVerified;
  final int maxResults;
  final double minimumScore;

  bool get containsRawUserMessage => false;
  bool get containsRawConversation => false;
  bool get containsRawPrompt => false;
  bool get containsPhone => false;
  bool get containsEmail => false;
  bool get containsCnic => false;
  bool get containsAuthToken => false;
  bool get containsPaymentData => false;

  bool get allowedScopesAreConsumedNotGranted => true;
  bool get grantsScope => false;
  bool get expandsScope => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get executesBusinessAction => false;
  bool get performsDatabaseSearch => false;
  bool get invokesProvider => false;
  bool get persistsRequest => false;

  void validateStructure() {
    if (!_validId(requestId)) {
      throw const FormatException('Invalid knowledge retrieval request ID.');
    }

    if (module.trim().isEmpty ||
        module.length > AgentKnowledgeRetrievalLimits.moduleMax ||
        topic.trim().isEmpty ||
        topic.length > AgentKnowledgeRetrievalLimits.topicMax) {
      throw const FormatException('Invalid knowledge retrieval module/topic.');
    }

    if (!AgentKnowledgeLanguage.values.contains(language)) {
      throw const FormatException('Unsupported knowledge retrieval language.');
    }

    if (allowedScopes.isEmpty ||
        allowedScopes.length > AgentKnowledgeRetrievalLimits.maxAllowedScopes ||
        allowedScopes.any(
          (String scope) => !AgentKnowledgeScope.values.contains(scope),
        )) {
      throw const FormatException('Invalid pre-authorized knowledge scopes.');
    }

    if (maxResults <= 0 ||
        maxResults > AgentKnowledgeRetrievalLimits.maxResults ||
        minimumScore.isNaN ||
        minimumScore.isInfinite ||
        minimumScore < 0 ||
        minimumScore > 1) {
      throw const FormatException('Invalid knowledge retrieval limits.');
    }
  }

  bool _validId(String value) {
    final String trimmed = value.trim();

    return trimmed.isNotEmpty &&
        trimmed.length <= AgentKnowledgeRetrievalLimits.idMax &&
        RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(trimmed);
  }
}
