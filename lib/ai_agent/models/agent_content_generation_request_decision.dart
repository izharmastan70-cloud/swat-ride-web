import '../constants/agent_content_generation_contract_constants.dart';

class AgentContentGenerationRequestDecision {
  AgentContentGenerationRequestDecision({
    required this.status,
    required this.requestId,
    required this.normalizedDraftType,
    required this.normalizedPlatform,
    required this.reviewRequired,
    required this.ownerWhatsAppReviewEligible,
    required List<String> reasonCodes,
  }) : reasonCodes = List<String>.unmodifiable(reasonCodes);

  final String status;
  final String requestId;
  final String normalizedDraftType;
  final String normalizedPlatform;
  final bool reviewRequired;
  final bool ownerWhatsAppReviewEligible;
  final List<String> reasonCodes;

  bool get accepted => status == AgentContentRequestStatus.acceptedDraftOnly;

  bool get draftOnly => true;
  bool get reviewVisibilityOnly => true;
  bool get publishesContent => false;
  bool get schedulesContent => false;
  bool get sendsWhatsApp => false;
  bool get sendsEmail => false;
  bool get postsSocialMedia => false;
  bool get executesApproval => false;
  bool get executesBusinessAction => false;
  bool get grantsAuthority => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get marksRuntimeAllowed => false;
  bool get invokesProvider => false;
  bool get writesBusinessData => false;
  bool get persistsDecision => false;

  void validateStructure() {
    if (!AgentContentRequestStatus.values.contains(status)) {
      throw const AgentContentGenerationRequestDecisionException(
        'Content request decision status is invalid.',
      );
    }
    if (requestId.trim().isEmpty || requestId.length > 180) {
      throw const AgentContentGenerationRequestDecisionException(
        'Content request decision ID is invalid.',
      );
    }
    if (reasonCodes.isEmpty || reasonCodes.length > 12) {
      throw const AgentContentGenerationRequestDecisionException(
        'Content request decision reasons are invalid.',
      );
    }
    if (accepted && !reviewRequired) {
      throw const AgentContentGenerationRequestDecisionException(
        'Accepted content request must require review.',
      );
    }
  }
}

class AgentContentGenerationRequestDecisionException implements Exception {
  const AgentContentGenerationRequestDecisionException(this.message);
  final String message;

  @override
  String toString() =>
      'AgentContentGenerationRequestDecisionException: $message';
}
