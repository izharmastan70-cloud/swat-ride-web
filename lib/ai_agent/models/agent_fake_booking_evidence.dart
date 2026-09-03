// =========================================================
// AI AGENT - FAKE BOOKING / REPEATED ABUSE EVIDENCE
// =========================================================
//
// Phase 32 Step 5B.
//
// IMPORTANT:
//
// One cancellation != fake booking.
// One no-show != fake booking.
// One payment failure != fraud.
//
// Evidence must be multi-signal and reviewable.
//
// This model has NO enforcement authority.

class AgentFakeBookingEvidenceStatus {
  AgentFakeBookingEvidenceStatus._();

  static const String noMaterialPattern =
      'NO_MATERIAL_PATTERN';

  static const String monitor =
      'MONITOR';

  static const String adminReview =
      'ADMIN_REVIEW';

  static const String strongIndicators =
      'STRONG_INDICATORS';

  static const String insufficientEvidence =
      'INSUFFICIENT_EVIDENCE';

  static const Set<String> values =
      <String>{
    noMaterialPattern,
    monitor,
    adminReview,
    strongIndicators,
    insufficientEvidence,
  };

  static bool isValid(String value) =>
      values.contains(value);
}

class AgentFakeBookingEvidence {
  final String evidenceId;
  final String subjectId;
  final String subjectType;
  final String module;

  final int bookingsObserved;
  final int cancellations;
  final int verifiedNoShows;
  final int paymentFailures;
  final int unreachableEvents;

  final bool duplicateBookingPattern;
  final bool multiAccountPattern;
  final bool promoAbuseIndicator;
  final bool referralAbuseIndicator;
  final bool possibleCollusionIndicator;

  final List<String> evidenceRefs;

  final int independentSignalCount;
  final String status;
  final String reason;

  final bool requiresAdminReview;
  final bool requiresSuperAdminReview;

  final DateTime createdAt;

  const AgentFakeBookingEvidence({
    required this.evidenceId,
    required this.subjectId,
    required this.subjectType,
    required this.module,
    required this.bookingsObserved,
    required this.cancellations,
    required this.verifiedNoShows,
    required this.paymentFailures,
    required this.unreachableEvents,
    required this.duplicateBookingPattern,
    required this.multiAccountPattern,
    required this.promoAbuseIndicator,
    required this.referralAbuseIndicator,
    required this.possibleCollusionIndicator,
    this.evidenceRefs = const <String>[],
    required this.independentSignalCount,
    required this.status,
    required this.reason,
    required this.requiresAdminReview,
    required this.requiresSuperAdminReview,
    required this.createdAt,
  });

  bool get hasStrongIndicators =>
      status ==
      AgentFakeBookingEvidenceStatus
          .strongIndicators;

  void validate() {
    if (evidenceId.trim().isEmpty ||
        subjectId.trim().isEmpty ||
        subjectType.trim().isEmpty ||
        module.trim().isEmpty) {
      throw const AgentFakeBookingEvidenceException(
        'Identity/module fields cannot be empty.',
      );
    }

    final List<int> counters = <int>[
      bookingsObserved,
      cancellations,
      verifiedNoShows,
      paymentFailures,
      unreachableEvents,
      independentSignalCount,
    ];

    if (counters.any(
      (int value) => value < 0,
    )) {
      throw const AgentFakeBookingEvidenceException(
        'Evidence counters cannot be negative.',
      );
    }

    if (cancellations > bookingsObserved ||
        verifiedNoShows > bookingsObserved ||
        paymentFailures > bookingsObserved ||
        unreachableEvents > bookingsObserved) {
      throw const AgentFakeBookingEvidenceException(
        'Event counts cannot exceed bookingsObserved.',
      );
    }

    if (!AgentFakeBookingEvidenceStatus
        .isValid(status)) {
      throw AgentFakeBookingEvidenceException(
        'Invalid fake-booking evidence status "$status".',
      );
    }

    if (reason.trim().isEmpty) {
      throw const AgentFakeBookingEvidenceException(
        'reason cannot be empty.',
      );
    }

    if (requiresSuperAdminReview &&
        !requiresAdminReview) {
      throw const AgentFakeBookingEvidenceException(
        'Super Admin review also requires Admin review.',
      );
    }

    if (hasStrongIndicators &&
        !requiresAdminReview) {
      throw const AgentFakeBookingEvidenceException(
        'Strong indicators must require Admin review.',
      );
    }
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'evidenceId': evidenceId,
      'subjectId': subjectId,
      'subjectType': subjectType,
      'module': module,
      'bookingsObserved': bookingsObserved,
      'cancellations': cancellations,
      'verifiedNoShows': verifiedNoShows,
      'paymentFailures': paymentFailures,
      'unreachableEvents': unreachableEvents,
      'duplicateBookingPattern':
          duplicateBookingPattern,
      'multiAccountPattern':
          multiAccountPattern,
      'promoAbuseIndicator':
          promoAbuseIndicator,
      'referralAbuseIndicator':
          referralAbuseIndicator,
      'possibleCollusionIndicator':
          possibleCollusionIndicator,
      'evidenceRefs':
          List<String>.from(evidenceRefs),
      'independentSignalCount':
          independentSignalCount,
      'status': status,
      'reason': reason,
      'requiresAdminReview':
          requiresAdminReview,
      'requiresSuperAdminReview':
          requiresSuperAdminReview,
      'createdAt':
          createdAt.toIso8601String(),
    };
  }
}

class AgentFakeBookingEvidenceException
    implements Exception {
  final String message;

  const AgentFakeBookingEvidenceException(
    this.message,
  );

  @override
  String toString() =>
      'AgentFakeBookingEvidenceException: $message';
}