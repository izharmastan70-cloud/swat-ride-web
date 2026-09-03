import '../constants/agent_knowledge_conflict_resolution_constants.dart';
import 'agent_knowledge_citation_reference.dart';

class AgentKnowledgeConflictResolutionResult {
  AgentKnowledgeConflictResolutionResult({
    required this.status,
    required this.claimKey,
    required this.selectedClaimValueBinding,
    required List<AgentKnowledgeCitationReference> citations,
    required List<String> reasonCodes,
  }) : citations = List<AgentKnowledgeCitationReference>.unmodifiable(
         citations,
       ),
       reasonCodes = List<String>.unmodifiable(reasonCodes);

  final String status;
  final String claimKey;
  final String selectedClaimValueBinding;
  final List<AgentKnowledgeCitationReference> citations;
  final List<String> reasonCodes;

  bool get ready =>
      status == AgentKnowledgeConflictStatus.readyForGrounding &&
      selectedClaimValueBinding.isNotEmpty &&
      citations.isNotEmpty;

  bool get noAnswerRequired => !ready;
  bool get noAnswerMustNotGuess => true;

  bool get mayProceedToConversationGrounding => ready;
  bool get conversationGroundingRequired => true;
  bool get responseGuardRequired => true;

  bool get citationsRequiredForGroundedClaim => true;
  bool get citationsAreMetadataOnly => true;
  bool get citationProjectionDoesNotExposeRawContent => true;
  bool get conflictResolutionDoesNotCreateTruth => true;
  bool get selectedBindingIsNotUserVisibleClaimText => true;

  bool get grantsPermission => false;
  bool get expandsScope => false;
  bool get consumesApproval => false;
  bool get executesBusinessAction => false;
  bool get writesBusinessData => false;
  bool get retrievesRawContent => false;
  bool get invokesProvider => false;
  bool get persistsResult => false;

  void validateStructure() {
    if (!AgentKnowledgeConflictStatus.values.contains(status) ||
        claimKey.trim().isEmpty ||
        reasonCodes.isEmpty ||
        reasonCodes.length > AgentKnowledgeConflictLimits.maxReasonCodes ||
        citations.length > AgentKnowledgeConflictLimits.maxCitations) {
      throw const FormatException(
        'Invalid knowledge conflict resolution result.',
      );
    }

    if (ready && (selectedClaimValueBinding.isEmpty || citations.isEmpty)) {
      throw const FormatException(
        'Ready conflict resolution requires claim binding and citations.',
      );
    }

    if (!ready &&
        (selectedClaimValueBinding.isNotEmpty || citations.isNotEmpty)) {
      throw const FormatException(
        'No-answer conflict resolution cannot expose selected binding/citations.',
      );
    }
  }
}
