import '../constants/agent_knowledge_conflict_resolution_constants.dart';
import '../constants/agent_knowledge_library_contract_constants.dart';

class AgentKnowledgeConflictCandidate {
  const AgentKnowledgeConflictCandidate({
    required this.itemId,
    required this.sourceId,
    required this.sourceReferenceId,
    required this.contentReferenceId,
    required this.claimKey,
    required this.claimValueBinding,
    required this.sourceType,
    required this.authorityClass,
    required this.revision,
    required this.sourceVersion,
    required this.retrievalScore,
    required this.citationEligible,
    required this.trustedScopeFilteredSnapshot,
  });

  final String itemId;
  final String sourceId;
  final String sourceReferenceId;
  final String contentReferenceId;
  final String claimKey;
  final String claimValueBinding;
  final String sourceType;
  final String authorityClass;
  final int revision;
  final String sourceVersion;

  /// Retrieval priority/tie-break metadata only.
  /// Never truth probability and never authority.
  final double retrievalScore;

  final bool citationEligible;

  /// Must already represent the Step 1D trusted + scope-filtered boundary.
  final bool trustedScopeFilteredSnapshot;

  bool get metadataOnly => true;
  bool get containsRawKnowledgeContent => false;
  bool get containsRawSourcePayload => false;
  bool get containsRawPrompt => false;
  bool get containsPrivatePayload => false;
  bool get retrievalScoreIsNotTruthProbability => true;
  bool get retrievalScoreDoesNotGrantAuthority => true;

  bool get grantsPermission => false;
  bool get expandsScope => false;
  bool get consumesApproval => false;
  bool get executesBusinessAction => false;
  bool get retrievesRawContentHere => false;
  bool get invokesProvider => false;
  bool get persistsCandidate => false;

  int get precedenceScore {
    final int? authorityScore =
        AgentKnowledgePrecedence.authority[authorityClass];

    final int? sourceScore = AgentKnowledgePrecedence.sourceType[sourceType];

    if (authorityScore == null || sourceScore == null) {
      return -1;
    }

    return (authorityScore * 1000) + sourceScore;
  }

  void validateStructure() {
    for (final String value in <String>[
      itemId,
      sourceId,
      sourceReferenceId,
      contentReferenceId,
      claimKey,
      claimValueBinding,
      sourceVersion,
    ]) {
      if (!_validId(value)) {
        throw const FormatException(
          'Invalid knowledge conflict candidate identifier.',
        );
      }
    }

    if (!AgentKnowledgeSourceType.values.contains(sourceType) ||
        !AgentKnowledgeAuthorityClass.values.contains(authorityClass) ||
        revision <= 0 ||
        retrievalScore.isNaN ||
        retrievalScore.isInfinite ||
        retrievalScore < 0 ||
        retrievalScore > 1 ||
        precedenceScore < 0) {
      throw const FormatException(
        'Invalid knowledge conflict candidate metadata.',
      );
    }
  }

  bool _validId(String value) {
    final String trimmed = value.trim();

    return trimmed.isNotEmpty &&
        trimmed.length <= AgentKnowledgeConflictLimits.idMax &&
        RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(trimmed);
  }
}
