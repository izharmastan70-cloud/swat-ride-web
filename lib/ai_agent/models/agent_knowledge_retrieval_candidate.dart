import '../constants/agent_knowledge_library_contract_constants.dart';

class AgentKnowledgeRetrievalCandidate {
  AgentKnowledgeRetrievalCandidate({
    required this.itemId,
    required this.contentReferenceId,
    required this.module,
    required this.topic,
    required this.language,
    required Set<String> scopes,
    required this.revision,
    required this.sourceVersion,
    required this.indexedSnapshotTrusted,
    required this.approvedActive,
    required this.sourceVerified,
    required this.sourceApproved,
    required this.sourceActive,
    required this.sourceFresh,
    required this.relevanceScore,
    required this.authorityScore,
    required this.freshnessScore,
  }) : scopes = Set<String>.unmodifiable(scopes);

  final String itemId;
  final String contentReferenceId;
  final String module;
  final String topic;
  final String language;
  final Set<String> scopes;
  final int revision;
  final String sourceVersion;

  final bool indexedSnapshotTrusted;
  final bool approvedActive;
  final bool sourceVerified;
  final bool sourceApproved;
  final bool sourceActive;
  final bool sourceFresh;

  final double relevanceScore;
  final double authorityScore;
  final double freshnessScore;

  bool get metadataOnly => true;
  bool get containsRawKnowledgeContent => false;
  bool get containsRawPrompt => false;
  bool get containsPrivatePayload => false;

  bool get hasPublicPrivilegedScopeConflict =>
      scopes.contains(AgentKnowledgeScope.public) &&
      scopes.any(AgentKnowledgeScope.privileged.contains);

  bool get trustEligible =>
      indexedSnapshotTrusted &&
      approvedActive &&
      sourceVerified &&
      sourceApproved &&
      sourceActive &&
      sourceFresh &&
      !hasPublicPrivilegedScopeConflict;

  bool get grantsPermission => false;
  bool get expandsScope => false;
  bool get executesBusinessAction => false;
  bool get retrievesRawContentHere => false;
  bool get invokesProvider => false;
  bool get persistsCandidate => false;

  void validateStructure() {
    if (!_validId(itemId) ||
        !_validId(contentReferenceId) ||
        !_validId(sourceVersion)) {
      throw const FormatException(
        'Invalid knowledge retrieval candidate identifiers.',
      );
    }

    if (module.trim().isEmpty ||
        topic.trim().isEmpty ||
        !AgentKnowledgeLanguage.values.contains(language) ||
        scopes.isEmpty ||
        scopes.any(
          (String scope) => !AgentKnowledgeScope.values.contains(scope),
        ) ||
        revision <= 0) {
      throw const FormatException(
        'Invalid knowledge retrieval candidate metadata.',
      );
    }

    for (final double score in <double>[
      relevanceScore,
      authorityScore,
      freshnessScore,
    ]) {
      if (score.isNaN || score.isInfinite || score < 0 || score > 1) {
        throw const FormatException('Invalid retrieval ranking score.');
      }
    }
  }

  bool _validId(String value) {
    final String trimmed = value.trim();

    return trimmed.isNotEmpty &&
        trimmed.length <= 180 &&
        RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(trimmed);
  }
}
