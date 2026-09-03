// =========================================================
// AI AGENT - NO-SHOW EVIDENCE
// =========================================================
//
// Phase 32 Step 4.
//
// Evidence model for genuine no-show / false no-show review.
//
// IMPORTANT:
// No-show claim != verified no-show.
//
// This model does NOT:
// - mark booking no-show
// - charge fee
// - debit wallet
// - restrict account
// - punish rider/driver
//
// It only represents evidence for later human/admin review.

class AgentNoShowEvidenceStatus {
  AgentNoShowEvidenceStatus._();

  static const String verified = 'VERIFIED';
  static const String insufficient =
      'INSUFFICIENT_EVIDENCE';
  static const String disputed = 'DISPUTED';
  static const String rejected =
      'CLAIM_NOT_SUPPORTED';

  static const Set<String> values = <String>{
    verified,
    insufficient,
    disputed,
    rejected,
  };

  static bool isValid(String value) =>
      values.contains(value);
}

class AgentNoShowEvidence {
  final String evidenceId;
  final String module;
  final String bookingId;

  final String claimantRole;
  final String claimantId;

  final bool arrivalLocationAvailable;
  final bool withinRequiredArrivalRadius;
  final double arrivalAccuracyMeters;

  final int waitedSeconds;
  final int requiredWaitSeconds;

  final int callAttempts;
  final int messageAttempts;

  final bool customerResponded;
  final bool oppositePartyDisputesClaim;

  final List<String> evidenceRefs;

  final String verificationStatus;
  final String reason;

  final bool requiresAdminReview;
  final DateTime createdAt;

  const AgentNoShowEvidence({
    required this.evidenceId,
    required this.module,
    required this.bookingId,
    required this.claimantRole,
    required this.claimantId,
    required this.arrivalLocationAvailable,
    required this.withinRequiredArrivalRadius,
    required this.arrivalAccuracyMeters,
    required this.waitedSeconds,
    required this.requiredWaitSeconds,
    required this.callAttempts,
    required this.messageAttempts,
    required this.customerResponded,
    required this.oppositePartyDisputesClaim,
    this.evidenceRefs = const <String>[],
    required this.verificationStatus,
    required this.reason,
    required this.requiresAdminReview,
    required this.createdAt,
  });

  int get totalContactAttempts =>
      callAttempts + messageAttempts;

  bool get waitRequirementMet =>
      requiredWaitSeconds > 0 &&
      waitedSeconds >= requiredWaitSeconds;

  bool get hasArrivalEvidence =>
      arrivalLocationAvailable &&
      withinRequiredArrivalRadius;

  bool get isVerified =>
      verificationStatus ==
      AgentNoShowEvidenceStatus.verified;

  void validate() {
    if (evidenceId.trim().isEmpty) {
      throw const AgentNoShowEvidenceException(
        'evidenceId cannot be empty.',
      );
    }

    if (module.trim().isEmpty) {
      throw const AgentNoShowEvidenceException(
        'module cannot be empty.',
      );
    }

    if (bookingId.trim().isEmpty) {
      throw const AgentNoShowEvidenceException(
        'bookingId cannot be empty.',
      );
    }

    if (claimantRole.trim().isEmpty ||
        claimantId.trim().isEmpty) {
      throw const AgentNoShowEvidenceException(
        'claimantRole and claimantId are required.',
      );
    }

    if (arrivalAccuracyMeters < 0) {
      throw const AgentNoShowEvidenceException(
        'arrivalAccuracyMeters cannot be negative.',
      );
    }

    if (waitedSeconds < 0 ||
        requiredWaitSeconds < 0 ||
        callAttempts < 0 ||
        messageAttempts < 0) {
      throw const AgentNoShowEvidenceException(
        'No-show evidence counters cannot be negative.',
      );
    }

    if (!AgentNoShowEvidenceStatus.isValid(
      verificationStatus,
    )) {
      throw AgentNoShowEvidenceException(
        'Invalid verificationStatus "$verificationStatus".',
      );
    }

    if (reason.trim().isEmpty) {
      throw const AgentNoShowEvidenceException(
        'reason cannot be empty.',
      );
    }

    if (oppositePartyDisputesClaim &&
        !requiresAdminReview) {
      throw const AgentNoShowEvidenceException(
        'Disputed no-show claim must require Admin review.',
      );
    }
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'evidenceId': evidenceId,
      'module': module,
      'bookingId': bookingId,
      'claimantRole': claimantRole,
      'claimantId': claimantId,
      'arrivalLocationAvailable':
          arrivalLocationAvailable,
      'withinRequiredArrivalRadius':
          withinRequiredArrivalRadius,
      'arrivalAccuracyMeters':
          arrivalAccuracyMeters,
      'waitedSeconds': waitedSeconds,
      'requiredWaitSeconds':
          requiredWaitSeconds,
      'callAttempts': callAttempts,
      'messageAttempts': messageAttempts,
      'totalContactAttempts':
          totalContactAttempts,
      'customerResponded': customerResponded,
      'oppositePartyDisputesClaim':
          oppositePartyDisputesClaim,
      'evidenceRefs':
          List<String>.from(evidenceRefs),
      'verificationStatus':
          verificationStatus,
      'reason': reason,
      'requiresAdminReview':
          requiresAdminReview,
      'createdAt':
          createdAt.toIso8601String(),
    };
  }
}

class AgentNoShowEvidenceException
    implements Exception {
  final String message;

  const AgentNoShowEvidenceException(
    this.message,
  );

  @override
  String toString() =>
      'AgentNoShowEvidenceException: $message';
}