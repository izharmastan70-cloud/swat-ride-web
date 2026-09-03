import '../models/agent_no_show_evidence.dart';

// =========================================================
// AI AGENT - NO-SHOW EVIDENCE VERIFIER
// =========================================================
//
// Phase 32 Step 4.
//
// Evidence-first verifier.
//
// Genuine no-show requires:
// - arrival/location evidence
// - arrival within required radius
// - acceptable location accuracy
// - minimum wait time
// - contact attempts
// - no confirmed customer response
//
// A disputed claim is NEVER auto-resolved.
//
// NO Firestore write.
// NO markNoShow call.
// NO fee.
// NO wallet action.
// NO suspension/ban.

class AgentNoShowEvidenceVerifier {
  const AgentNoShowEvidenceVerifier();

  AgentNoShowEvidence verify({
    required String evidenceId,
    required String module,
    required String bookingId,
    required String claimantRole,
    required String claimantId,

    required bool arrivalLocationAvailable,
    required bool withinRequiredArrivalRadius,
    required double arrivalAccuracyMeters,

    required int waitedSeconds,
    required int requiredWaitSeconds,

    required int callAttempts,
    required int messageAttempts,

    required bool customerResponded,
    required bool oppositePartyDisputesClaim,

    Iterable<String> evidenceRefs =
        const <String>[],

    double maximumAcceptedAccuracyMeters = 100,
    int minimumContactAttempts = 1,

    DateTime? createdAt,
  }) {
    if (maximumAcceptedAccuracyMeters <= 0) {
      throw const AgentNoShowEvidenceVerifierException(
        'maximumAcceptedAccuracyMeters must be greater than zero.',
      );
    }

    if (minimumContactAttempts < 0) {
      throw const AgentNoShowEvidenceVerifierException(
        'minimumContactAttempts cannot be negative.',
      );
    }

    final List<String> cleanEvidenceRefs =
        evidenceRefs
            .map(
              (String value) =>
                  value.trim(),
            )
            .where(
              (String value) =>
                  value.isNotEmpty,
            )
            .toSet()
            .toList(growable: false);

    final int totalContactAttempts =
        callAttempts + messageAttempts;

    final bool accurateLocation =
        arrivalLocationAvailable &&
        arrivalAccuracyMeters >= 0 &&
        arrivalAccuracyMeters <=
            maximumAcceptedAccuracyMeters;

    final bool arrivalVerified =
        accurateLocation &&
        withinRequiredArrivalRadius;

    final bool waitVerified =
        requiredWaitSeconds > 0 &&
        waitedSeconds >= requiredWaitSeconds;

    final bool contactVerified =
        totalContactAttempts >=
            minimumContactAttempts;

    String status;
    String reason;
    bool requiresAdminReview = false;

    if (oppositePartyDisputesClaim) {
      status =
          AgentNoShowEvidenceStatus.disputed;

      reason =
          'No-show claim is disputed. Admin must review both parties and evidence before any fee or account action.';

      requiresAdminReview = true;
    } else if (customerResponded) {
      status =
          AgentNoShowEvidenceStatus.rejected;

      reason =
          'No-show claim is not supported because the customer responded during the verification sequence.';

      requiresAdminReview = false;
    } else if (!arrivalVerified) {
      status =
          AgentNoShowEvidenceStatus.insufficient;

      reason =
          'Arrival/location evidence is missing, outside the required radius, or not accurate enough.';

      requiresAdminReview = true;
    } else if (!waitVerified) {
      status =
          AgentNoShowEvidenceStatus.insufficient;

      reason =
          'Required waiting period was not completed.';

      requiresAdminReview = true;
    } else if (!contactVerified) {
      status =
          AgentNoShowEvidenceStatus.insufficient;

      reason =
          'Required customer contact attempts were not completed.';

      requiresAdminReview = true;
    } else if (cleanEvidenceRefs.isEmpty) {
      status =
          AgentNoShowEvidenceStatus.insufficient;

      reason =
          'Verification conditions appear satisfied but immutable evidence references are missing.';

      requiresAdminReview = true;
    } else {
      status =
          AgentNoShowEvidenceStatus.verified;

      reason =
          'Arrival, location accuracy, wait time and contact-attempt evidence satisfy the no-show verification requirements.';

      requiresAdminReview = true;
    }

    final AgentNoShowEvidence result =
        AgentNoShowEvidence(
      evidenceId: evidenceId.trim(),
      module: module.trim(),
      bookingId: bookingId.trim(),
      claimantRole: claimantRole.trim(),
      claimantId: claimantId.trim(),
      arrivalLocationAvailable:
          arrivalLocationAvailable,
      withinRequiredArrivalRadius:
          withinRequiredArrivalRadius,
      arrivalAccuracyMeters:
          arrivalAccuracyMeters,
      waitedSeconds: waitedSeconds,
      requiredWaitSeconds:
          requiredWaitSeconds,
      callAttempts: callAttempts,
      messageAttempts: messageAttempts,
      customerResponded:
          customerResponded,
      oppositePartyDisputesClaim:
          oppositePartyDisputesClaim,
      evidenceRefs: cleanEvidenceRefs,
      verificationStatus: status,
      reason: reason,
      requiresAdminReview:
          requiresAdminReview,
      createdAt: createdAt ?? DateTime.now(),
    );

    result.validate();

    return result;
  }
}

class AgentNoShowEvidenceVerifierException
    implements Exception {
  final String message;

  const AgentNoShowEvidenceVerifierException(
    this.message,
  );

  @override
  String toString() =>
      'AgentNoShowEvidenceVerifierException: $message';
}