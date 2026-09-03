import '../models/agent_fake_booking_evidence.dart';

// =========================================================
// AI AGENT - FAKE BOOKING EVIDENCE VERIFIER
// =========================================================
//
// False-positive protection:
//
// - single cancellation does NOT establish fraud
// - single no-show does NOT establish fraud
// - single payment failure does NOT establish fraud
// - strong result requires multiple independent indicators
// - enforcement never happens here
//
// Daily-life / genuine-user protection is intentional.

class AgentFakeBookingEvidenceVerifier {
  const AgentFakeBookingEvidenceVerifier();

  AgentFakeBookingEvidence verify({
    required String evidenceId,
    required String subjectId,
    required String subjectType,
    required String module,

    required int bookingsObserved,
    required int cancellations,
    required int verifiedNoShows,
    required int paymentFailures,
    required int unreachableEvents,

    required bool duplicateBookingPattern,
    required bool multiAccountPattern,
    required bool promoAbuseIndicator,
    required bool referralAbuseIndicator,
    required bool possibleCollusionIndicator,

    Iterable<String> evidenceRefs =
        const <String>[],

    DateTime? createdAt,
  }) {
    if (bookingsObserved < 0 ||
        cancellations < 0 ||
        verifiedNoShows < 0 ||
        paymentFailures < 0 ||
        unreachableEvents < 0) {
      throw const AgentFakeBookingEvidenceVerifierException(
        'Evidence counters cannot be negative.',
      );
    }

    if (cancellations > bookingsObserved ||
        verifiedNoShows > bookingsObserved ||
        paymentFailures > bookingsObserved ||
        unreachableEvents > bookingsObserved) {
      throw const AgentFakeBookingEvidenceVerifierException(
        'Evidence event counts cannot exceed bookingsObserved.',
      );
    }

    final List<String> cleanEvidence =
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

    int independentSignalCount = 0;

    final bool repeatedCancellationPattern =
        bookingsObserved >= 3 &&
        cancellations >= 3;

    final bool repeatedNoShowPattern =
        bookingsObserved >= 2 &&
        verifiedNoShows >= 2;

    final bool repeatedPaymentFailurePattern =
        bookingsObserved >= 3 &&
        paymentFailures >= 3;

    final bool repeatedUnreachablePattern =
        bookingsObserved >= 2 &&
        unreachableEvents >= 2;

    final List<bool> independentSignals =
        <bool>[
      repeatedCancellationPattern,
      repeatedNoShowPattern,
      repeatedPaymentFailurePattern,
      repeatedUnreachablePattern,
      duplicateBookingPattern,
      multiAccountPattern,
      promoAbuseIndicator,
      referralAbuseIndicator,
      possibleCollusionIndicator,
    ];

    independentSignalCount =
        independentSignals
            .where((bool value) => value)
            .length;

    String status;
    String reason;
    bool requiresAdminReview = false;
    bool requiresSuperAdminReview = false;

    if (bookingsObserved == 0) {
      status =
          AgentFakeBookingEvidenceStatus
              .noMaterialPattern;

      reason =
          'No booking history was supplied, so no fake-booking conclusion can be made.';
    } else if (independentSignalCount == 0) {
      status =
          AgentFakeBookingEvidenceStatus
              .noMaterialPattern;

      reason =
          'No material repeated-abuse pattern was detected. Isolated cancellation, no-show or payment failure is not treated as fraud.';
    } else if (cleanEvidence.isEmpty) {
      status =
          AgentFakeBookingEvidenceStatus
              .insufficientEvidence;

      reason =
          'Potential pattern exists, but immutable evidence references are missing. Do not take enforcement action.';

      requiresAdminReview = true;
    } else if (independentSignalCount == 1) {
      status =
          AgentFakeBookingEvidenceStatus
              .monitor;

      reason =
          'One independent risk pattern was detected. Monitor and collect more evidence; do not classify the user as fraudulent.';

      requiresAdminReview = false;
    } else if (independentSignalCount == 2) {
      status =
          AgentFakeBookingEvidenceStatus
              .adminReview;

      reason =
          'Multiple independent risk patterns were detected. Admin evidence review is required before any restriction, fee or account action.';

      requiresAdminReview = true;
    } else {
      status =
          AgentFakeBookingEvidenceStatus
              .strongIndicators;

      reason =
          'Several independent risk indicators were detected. This is still not proof of fraud; Admin review is mandatory before any action.';

      requiresAdminReview = true;

      requiresSuperAdminReview =
          independentSignalCount >= 4 &&
          cleanEvidence.length >= 2;
    }

    final AgentFakeBookingEvidence result =
        AgentFakeBookingEvidence(
      evidenceId: evidenceId.trim(),
      subjectId: subjectId.trim(),
      subjectType: subjectType.trim(),
      module: module.trim(),
      bookingsObserved:
          bookingsObserved,
      cancellations:
          cancellations,
      verifiedNoShows:
          verifiedNoShows,
      paymentFailures:
          paymentFailures,
      unreachableEvents:
          unreachableEvents,
      duplicateBookingPattern:
          duplicateBookingPattern,
      multiAccountPattern:
          multiAccountPattern,
      promoAbuseIndicator:
          promoAbuseIndicator,
      referralAbuseIndicator:
          referralAbuseIndicator,
      possibleCollusionIndicator:
          possibleCollusionIndicator,
      evidenceRefs:
          cleanEvidence,
      independentSignalCount:
          independentSignalCount,
      status:
          status,
      reason:
          reason,
      requiresAdminReview:
          requiresAdminReview,
      requiresSuperAdminReview:
          requiresSuperAdminReview,
      createdAt:
          createdAt ?? DateTime.now(),
    );

    result.validate();

    return result;
  }
}

class AgentFakeBookingEvidenceVerifierException
    implements Exception {
  final String message;

  const AgentFakeBookingEvidenceVerifierException(
    this.message,
  );

  @override
  String toString() =>
      'AgentFakeBookingEvidenceVerifierException: $message';
}