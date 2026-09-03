import '../constants/agent_knowledge_ingestion_gate_constants.dart';

class AgentKnowledgeIngestionDecision {
  AgentKnowledgeIngestionDecision({
    required this.status,
    required this.itemId,
    required this.revision,
    required this.trustedIndexWriteEligible,
    required this.humanReviewRequired,
    required List<String> reasonCodes,
  }) : reasonCodes = List<String>.unmodifiable(reasonCodes);

  final String status;
  final String itemId;
  final int revision;
  final bool trustedIndexWriteEligible;
  final bool humanReviewRequired;
  final List<String> reasonCodes;

  bool get eligible =>
      status == AgentKnowledgeIngestionStatus.eligibleForTrustedIndexWrite &&
      trustedIndexWriteEligible;

  bool get eligibilityIsNotIndexWrite => true;
  bool get approvalEvidenceIsNotApprovalExecution => true;
  bool get deprecationAcknowledgementIsNotDeprecationWrite => true;
  bool get knowledgeRemainsInformationOnly => true;
  bool get writesIndex => false;
  bool get writesFirestore => false;
  bool get executesApproval => false;
  bool get executesDeprecation => false;
  bool get grantsPermission => false;
  bool get marksRuntimeAllowed => false;
  bool get executesBusinessAction => false;
  bool get invokesProvider => false;
  bool get persistsDecision => false;

  void validateStructure() {
    if (!AgentKnowledgeIngestionStatus.values.contains(status)) {
      throw const FormatException('Invalid knowledge ingestion status.');
    }

    if (itemId.trim().isEmpty ||
        revision <= 0 ||
        reasonCodes.isEmpty ||
        reasonCodes.length > AgentKnowledgeIngestionLimits.maxReasonCodes) {
      throw const FormatException('Invalid knowledge ingestion decision.');
    }

    if (eligible && !humanReviewRequired) {
      throw const FormatException(
        'Knowledge ingestion remains human-review controlled.',
      );
    }
  }
}
