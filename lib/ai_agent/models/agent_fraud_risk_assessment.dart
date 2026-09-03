// =========================================================
// AI AGENT - FRAUD / RISK ASSESSMENT
// =========================================================
//
// Phase 32 Fraud/Risk foundation.
//
// Supports future intelligence for:
// - fake bookings
// - rider no-show abuse
// - driver false no-show claims
// - GPS/location anomalies
// - account farming
// - promo/referral abuse
// - payment risk
// - driver/rider collusion
//
// IMPORTANT:
// Risk flag != guilt.
//
// This model has NO authority to:
// - suspend/ban anyone
// - debit wallet
// - refund money
// - charge no-show fees
// - change booking status
// - reveal CNIC/home address
// - modify Firestore security
//
// Human/Admin approval remains authoritative.

class AgentFraudRiskLevel {
  AgentFraudRiskLevel._();

  static const String low = 'LOW';
  static const String moderate = 'MODERATE';
  static const String high = 'HIGH';
  static const String critical = 'CRITICAL';

  static const Set<String> values = <String>{
    low,
    moderate,
    high,
    critical,
  };

  static bool isValid(String value) =>
      values.contains(value);
}

class AgentFraudSubjectType {
  AgentFraudSubjectType._();

  static const String rider = 'RIDER';
  static const String driver = 'DRIVER';
  static const String booking = 'BOOKING';
  static const String payment = 'PAYMENT';
  static const String promo = 'PROMO';
  static const String account = 'ACCOUNT';

  static const Set<String> values = <String>{
    rider,
    driver,
    booking,
    payment,
    promo,
    account,
  };

  static bool isValid(String value) =>
      values.contains(value);
}

class AgentFraudSignalType {
  AgentFraudSignalType._();

  static const String verifiedNoShow =
      'VERIFIED_NO_SHOW';

  static const String falseNoShowClaim =
      'FALSE_NO_SHOW_CLAIM';

  static const String repeatedNoShow =
      'REPEATED_NO_SHOW';

  static const String unreachablePattern =
      'UNREACHABLE_PATTERN';

  static const String fakeBooking =
      'FAKE_BOOKING';

  static const String gpsAnomaly =
      'GPS_ANOMALY';

  static const String arrivalSpoof =
      'ARRIVAL_SPOOF';

  static const String multiAccountPattern =
      'MULTI_ACCOUNT_PATTERN';

  static const String promoAbuse =
      'PROMO_ABUSE';

  static const String referralAbuse =
      'REFERRAL_ABUSE';

  static const String paymentRisk =
      'PAYMENT_RISK';

  static const String possibleCollusion =
      'POSSIBLE_COLLUSION';

  static const Set<String> values = <String>{
    verifiedNoShow,
    falseNoShowClaim,
    repeatedNoShow,
    unreachablePattern,
    fakeBooking,
    gpsAnomaly,
    arrivalSpoof,
    multiAccountPattern,
    promoAbuse,
    referralAbuse,
    paymentRisk,
    possibleCollusion,
  };

  static bool isValid(String value) =>
      values.contains(value);
}

class AgentFraudRiskAssessment {
  final String assessmentId;
  final String module;

  final String subjectType;
  final String subjectId;

  final int riskScore;
  final String riskLevel;

  final List<String> signals;
  final List<String> evidenceRefs;

  final String recommendation;
  final bool requiresAdminReview;
  final bool requiresSuperAdminReview;

  final DateTime createdAt;

  const AgentFraudRiskAssessment({
    required this.assessmentId,
    required this.module,
    required this.subjectType,
    required this.subjectId,
    required this.riskScore,
    required this.riskLevel,
    this.signals = const <String>[],
    this.evidenceRefs = const <String>[],
    required this.recommendation,
    required this.requiresAdminReview,
    required this.requiresSuperAdminReview,
    required this.createdAt,
  });

  bool get hasRiskSignals =>
      signals.isNotEmpty;

  bool get isHighOrCritical =>
      riskLevel == AgentFraudRiskLevel.high ||
      riskLevel ==
          AgentFraudRiskLevel.critical;

  void validate() {
    if (assessmentId.trim().isEmpty) {
      throw const AgentFraudRiskAssessmentException(
        'assessmentId cannot be empty.',
      );
    }

    if (module.trim().isEmpty) {
      throw const AgentFraudRiskAssessmentException(
        'module cannot be empty.',
      );
    }

    if (!AgentFraudSubjectType.isValid(
      subjectType,
    )) {
      throw AgentFraudRiskAssessmentException(
        'Invalid fraud subject type "$subjectType".',
      );
    }

    if (subjectId.trim().isEmpty) {
      throw const AgentFraudRiskAssessmentException(
        'subjectId cannot be empty.',
      );
    }

    if (riskScore < 0 || riskScore > 100) {
      throw const AgentFraudRiskAssessmentException(
        'riskScore must be between 0 and 100.',
      );
    }

    if (!AgentFraudRiskLevel.isValid(
      riskLevel,
    )) {
      throw AgentFraudRiskAssessmentException(
        'Invalid risk level "$riskLevel".',
      );
    }

    for (final String signal in signals) {
      if (!AgentFraudSignalType.isValid(
        signal,
      )) {
        throw AgentFraudRiskAssessmentException(
          'Invalid fraud signal "$signal".',
        );
      }
    }

    if (recommendation.trim().isEmpty) {
      throw const AgentFraudRiskAssessmentException(
        'recommendation cannot be empty.',
      );
    }

    if (riskLevel ==
            AgentFraudRiskLevel.critical &&
        !requiresAdminReview) {
      throw const AgentFraudRiskAssessmentException(
        'Critical risk must require Admin review.',
      );
    }

    if (requiresSuperAdminReview &&
        !requiresAdminReview) {
      throw const AgentFraudRiskAssessmentException(
        'Super Admin review also requires Admin review.',
      );
    }
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'assessmentId': assessmentId,
      'module': module,
      'subjectType': subjectType,
      'subjectId': subjectId,
      'riskScore': riskScore,
      'riskLevel': riskLevel,
      'signals':
          List<String>.from(signals),
      'evidenceRefs':
          List<String>.from(evidenceRefs),
      'recommendation': recommendation,
      'requiresAdminReview':
          requiresAdminReview,
      'requiresSuperAdminReview':
          requiresSuperAdminReview,
      'createdAt':
          createdAt.toIso8601String(),
    };
  }
}

class AgentFraudRiskAssessmentException
    implements Exception {
  final String message;

  const AgentFraudRiskAssessmentException(
    this.message,
  );

  @override
  String toString() =>
      'AgentFraudRiskAssessmentException: $message';
}