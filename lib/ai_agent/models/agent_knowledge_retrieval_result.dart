import '../constants/agent_knowledge_retrieval_constants.dart';

class AgentKnowledgeRankedReference {
  const AgentKnowledgeRankedReference({
    required this.itemId,
    required this.contentReferenceId,
    required this.revision,
    required this.sourceVersion,
    required this.rankingScore,
  });

  final String itemId;
  final String contentReferenceId;
  final int revision;
  final String sourceVersion;

  /// Retrieval priority only. Never truth probability.
  final double rankingScore;

  bool get containsRawKnowledgeContent => false;
  bool get rankingScoreIsNotTruthProbability => true;
  bool get grantsAuthority => false;
  bool get executesBusinessAction => false;
}

class AgentKnowledgeRetrievalResult {
  AgentKnowledgeRetrievalResult({
    required this.status,
    required this.requestId,
    required List<AgentKnowledgeRankedReference> references,
    required List<String> reasonCodes,
  }) : references = List<AgentKnowledgeRankedReference>.unmodifiable(
         references,
       ),
       reasonCodes = List<String>.unmodifiable(reasonCodes);

  final String status;
  final String requestId;
  final List<AgentKnowledgeRankedReference> references;
  final List<String> reasonCodes;

  bool get ready =>
      status == AgentKnowledgeRetrievalStatus.readyWithGroundedReferences &&
      references.isNotEmpty;

  bool get noAnswerRequired => !ready;

  bool get mayProceedToGroundingProjection => ready;
  bool get conversationGroundingRequired => true;
  bool get responseGuardRequired => true;
  bool get noAnswerMustNotGuess => true;
  bool get referencesAreMetadataOnly => true;
  bool get referencesDoNotGrantAuthority => true;
  bool get scopeWasFilteredBeforeRanking => true;
  bool get rankingScoreIsNotTruthProbability => true;

  bool get performsDatabaseSearch => false;
  bool get retrievesRawContent => false;
  bool get invokesProvider => false;
  bool get grantsPermission => false;
  bool get expandsScope => false;
  bool get consumesApproval => false;
  bool get executesBusinessAction => false;
  bool get writesBusinessData => false;
  bool get persistsResult => false;

  void validateStructure() {
    if (!AgentKnowledgeRetrievalStatus.values.contains(status) ||
        requestId.trim().isEmpty ||
        reasonCodes.isEmpty ||
        reasonCodes.length > AgentKnowledgeRetrievalLimits.maxReasonCodes) {
      throw const FormatException('Invalid knowledge retrieval result.');
    }

    if (ready && references.isEmpty) {
      throw const FormatException(
        'Ready retrieval result requires references.',
      );
    }

    if (!ready && references.isNotEmpty) {
      throw const FormatException(
        'No-answer retrieval result cannot expose references.',
      );
    }
  }
}
