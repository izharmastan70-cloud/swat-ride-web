import '../constants/agent_content_grounding_constants.dart';

class AgentContentGroundingDecision {
  AgentContentGroundingDecision({
    required this.status,
    required this.requestId,
    required this.module,
    required this.feature,
    required this.humanReviewRequired,
    required this.ownerWhatsAppReviewEligible,
    required Set<String> verifiedClaimKeys,
    required List<String> sourceReferenceIds,
    required List<String> reasonCodes,
  }) : verifiedClaimKeys = Set<String>.unmodifiable(verifiedClaimKeys),
       sourceReferenceIds = List<String>.unmodifiable(sourceReferenceIds),
       reasonCodes = List<String>.unmodifiable(reasonCodes);

  final String status;
  final String requestId;
  final String module;
  final String feature;
  final bool humanReviewRequired;
  final bool ownerWhatsAppReviewEligible;
  final Set<String> verifiedClaimKeys;
  final List<String> sourceReferenceIds;
  final List<String> reasonCodes;

  bool get grounded =>
      status == AgentContentGroundingStatus.groundedReadyForHumanReview;

  bool get draftOnly => true;
  bool get generatedFactsAreAuthority => false;
  bool get sourceReferencesAreAuthority => false;
  bool get autoPublishes => false;
  bool get autoSchedules => false;
  bool get sendsWhatsApp => false;
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

  Map<String, dynamic> toOwnerReviewSummary() {
    return Map<String, dynamic>.unmodifiable(<String, dynamic>{
      'requestId': requestId,
      'status': status,
      'module': module,
      'feature': feature,
      'grounded': grounded,
      'humanReviewRequired': humanReviewRequired,
      'ownerWhatsAppReviewEligible': ownerWhatsAppReviewEligible && grounded,
      'verifiedClaimKeys': verifiedClaimKeys.toList()..sort(),
      'sourceReferenceIds': sourceReferenceIds,
      'containsRawSourcePayload': false,
      'containsSecrets': false,
      'autoPublishes': false,
      'sendsWhatsApp': false,
    });
  }

  void validateStructure() {
    if (!AgentContentGroundingStatus.values.contains(status)) {
      throw const AgentContentGroundingDecisionException(
        'Content grounding status is invalid.',
      );
    }

    if (requestId.trim().isEmpty || requestId.length > 180) {
      throw const AgentContentGroundingDecisionException(
        'Content grounding request ID is invalid.',
      );
    }

    if (reasonCodes.isEmpty || reasonCodes.length > 16) {
      throw const AgentContentGroundingDecisionException(
        'Content grounding reasons are invalid.',
      );
    }

    for (final String reason in reasonCodes) {
      if (!AgentContentGroundingReason.values.contains(reason)) {
        throw const AgentContentGroundingDecisionException(
          'Content grounding reason is invalid.',
        );
      }
    }

    if (grounded && !humanReviewRequired) {
      throw const AgentContentGroundingDecisionException(
        'Grounded content must still require human review.',
      );
    }
  }
}

class AgentContentGroundingDecisionException implements Exception {
  const AgentContentGroundingDecisionException(this.message);

  final String message;

  @override
  String toString() => 'AgentContentGroundingDecisionException: $message';
}
