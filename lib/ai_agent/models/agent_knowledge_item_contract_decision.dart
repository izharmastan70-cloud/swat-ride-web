import '../constants/agent_knowledge_library_contract_constants.dart';

class AgentKnowledgeItemContractDecision {
  AgentKnowledgeItemContractDecision({
    required this.status,
    required this.itemId,
    required this.sourceId,
    required this.revision,
    required this.indexingEligible,
    required this.humanReviewRequired,
    required List<String> reasonCodes,
  }) : reasonCodes = List<String>.unmodifiable(reasonCodes);

  final String status;
  final String itemId;
  final String sourceId;
  final int revision;
  final bool indexingEligible;
  final bool humanReviewRequired;
  final List<String> reasonCodes;

  bool get eligible =>
      status == AgentKnowledgeContractStatus.eligibleForLibraryIndexing &&
      indexingEligible;

  bool get eligibilityIsNotIndexWrite => true;
  bool get approvalMetadataIsNotApprovalExecution => true;
  bool get knowledgeIsInformationOnly => true;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get marksRuntimeAllowed => false;
  bool get executesBusinessAction => false;
  bool get writesBusinessData => false;
  bool get indexesContent => false;
  bool get retrievesContent => false;
  bool get invokesProvider => false;
  bool get persistsDecision => false;

  void validateStructure() {
    if (!AgentKnowledgeContractStatus.values.contains(status)) {
      throw const FormatException(
        'Invalid knowledge contract decision status.',
      );
    }

    if (itemId.trim().isEmpty ||
        sourceId.trim().isEmpty ||
        revision <= 0 ||
        reasonCodes.isEmpty ||
        reasonCodes.length > AgentKnowledgeContractLimits.maxReasonCodes) {
      throw const FormatException('Invalid knowledge contract decision.');
    }

    if (eligible && !humanReviewRequired) {
      throw const FormatException(
        'Knowledge indexing eligibility remains review-controlled.',
      );
    }
  }
}
