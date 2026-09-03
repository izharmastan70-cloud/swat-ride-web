import '../constants/agent_knowledge_ingestion_gate_constants.dart';

class AgentKnowledgeIngestionReviewEvidence {
  const AgentKnowledgeIngestionReviewEvidence({
    required this.approvalReferenceId,
    required this.reviewerRole,
    required this.reviewerBinding,
    required this.identityVerified,
    required this.roleAuthorized,
    required this.approvedForIngestion,
    required this.reviewedItemId,
    required this.reviewedRevision,
    required this.reviewedSourceVersion,
    required this.reviewedContentBinding,
    required this.reviewedAt,
  });

  final String approvalReferenceId;
  final String reviewerRole;
  final String reviewerBinding;
  final bool identityVerified;
  final bool roleAuthorized;
  final bool approvedForIngestion;
  final String reviewedItemId;
  final int reviewedRevision;
  final String reviewedSourceVersion;
  final String reviewedContentBinding;
  final DateTime reviewedAt;

  bool get approvalEvidenceIsReadOnlyMetadata => true;
  bool get evidenceDoesNotGrantApproval => true;
  bool get containsPhone => false;
  bool get containsEmail => false;
  bool get containsCnic => false;
  bool get containsAuthToken => false;
  bool get containsSecret => false;
  bool get executesApproval => false;
  bool get grantsPermission => false;
  bool get marksRuntimeAllowed => false;
  bool get executesBusinessAction => false;
  bool get persistsEvidence => false;

  bool isStaleAt(
    DateTime now, {
    Duration maxAge = AgentKnowledgeIngestionLimits.maxApprovalAge,
  }) {
    if (reviewedAt.isAfter(now)) {
      return true;
    }

    return now.difference(reviewedAt) > maxAge;
  }

  void validateStructure() {
    if (!_validId(approvalReferenceId) ||
        !_validId(reviewerBinding) ||
        !_validId(reviewedItemId) ||
        !_validId(reviewedSourceVersion) ||
        !_validId(reviewedContentBinding)) {
      throw const FormatException(
        'Invalid knowledge ingestion review evidence identifiers.',
      );
    }

    if (!AgentKnowledgeIngestionReviewerRole.values.contains(reviewerRole)) {
      throw const FormatException(
        'Unsupported knowledge ingestion reviewer role.',
      );
    }

    if (reviewedRevision <= 0) {
      throw const FormatException('Invalid reviewed knowledge revision.');
    }
  }

  bool _validId(String value) {
    final String trimmed = value.trim();

    return trimmed.isNotEmpty &&
        trimmed.length <= AgentKnowledgeIngestionLimits.bindingMax &&
        RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(trimmed);
  }
}
