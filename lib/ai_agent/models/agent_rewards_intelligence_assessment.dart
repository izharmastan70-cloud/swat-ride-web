// =========================================================
// AI AGENT - REWARDS/PROMO INTELLIGENCE ASSESSMENT
// =========================================================
//
// Phase 31 Step 2.
//
// Pure intelligence/reporting model.
//
// Tracks:
// - reward usage
// - coupon/promo success
// - referral abuse indicators
// - cashback effectiveness
// - loyalty patterns
//
// IMPORTANT:
// - recommendation/monitoring only
// - no reward balance mutation
// - no coupon/promo value mutation
// - no cashback percentage mutation
// - no referral reward mutation
// - no loyalty level mutation
// - no Firestore access

class AgentRewardsInsightSeverity {
  AgentRewardsInsightSeverity._();

  static const String info = 'INFO';
  static const String warning = 'WARNING';
  static const String high = 'HIGH';
  static const String critical = 'CRITICAL';

  static const Set<String> values = <String>{
    info,
    warning,
    high,
    critical,
  };

  static bool isValid(String value) =>
      values.contains(value);
}

class AgentRewardsTrend {
  AgentRewardsTrend._();

  static const String improving = 'IMPROVING';
  static const String stable = 'STABLE';
  static const String declining = 'DECLINING';
  static const String unknown = 'UNKNOWN';

  static const Set<String> values = <String>{
    improving,
    stable,
    declining,
    unknown,
  };

  static bool isValid(String value) =>
      values.contains(value);
}

class AgentRewardsIntelligenceAssessment {
  final String assessmentId;
  final DateTime periodStart;
  final DateTime periodEnd;

  // Reward usage
  final int rewardTransactions;
  final int rewardEarnEvents;
  final int rewardRedeemEvents;
  final double rewardRedemptionRatePercent;

  // Coupon / Promo performance
  final int couponAttempts;
  final int couponSuccesses;
  final double couponSuccessRatePercent;

  final int promoAttempts;
  final int promoSuccesses;
  final double promoSuccessRatePercent;

  // Referral risk
  final int referralCount;
  final int suspiciousReferralCount;
  final int manualReviewReferralCount;
  final double suspiciousReferralRatePercent;

  // Cashback effectiveness
  final int cashbackEligibleEvents;
  final int cashbackAwardedEvents;
  final double cashbackAwardRatePercent;
  final double cashbackValueRs;

  // Loyalty
  final int loyaltyUsersObserved;
  final int loyaltyUpgradeCount;
  final int loyaltyDowngradeCount;
  final String loyaltyTrend;

  // Overall intelligence
  final String severity;
  final List<String> findings;
  final List<String> recommendations;

  const AgentRewardsIntelligenceAssessment({
    required this.assessmentId,
    required this.periodStart,
    required this.periodEnd,
    required this.rewardTransactions,
    required this.rewardEarnEvents,
    required this.rewardRedeemEvents,
    required this.rewardRedemptionRatePercent,
    required this.couponAttempts,
    required this.couponSuccesses,
    required this.couponSuccessRatePercent,
    required this.promoAttempts,
    required this.promoSuccesses,
    required this.promoSuccessRatePercent,
    required this.referralCount,
    required this.suspiciousReferralCount,
    required this.manualReviewReferralCount,
    required this.suspiciousReferralRatePercent,
    required this.cashbackEligibleEvents,
    required this.cashbackAwardedEvents,
    required this.cashbackAwardRatePercent,
    required this.cashbackValueRs,
    required this.loyaltyUsersObserved,
    required this.loyaltyUpgradeCount,
    required this.loyaltyDowngradeCount,
    required this.loyaltyTrend,
    required this.severity,
    this.findings = const <String>[],
    this.recommendations = const <String>[],
  });

  bool get hasReferralRisk =>
      suspiciousReferralCount > 0 ||
      manualReviewReferralCount > 0;

  bool get hasLowCouponPerformance =>
      couponAttempts > 0 &&
      couponSuccessRatePercent < 25;

  bool get hasLowPromoPerformance =>
      promoAttempts > 0 &&
      promoSuccessRatePercent < 25;

  bool get loyaltyDeclining =>
      loyaltyTrend == AgentRewardsTrend.declining;

  bool get requiresAdminAttention =>
      severity == AgentRewardsInsightSeverity.high ||
      severity == AgentRewardsInsightSeverity.critical;

  void validate() {
    if (assessmentId.trim().isEmpty) {
      throw const AgentRewardsIntelligenceValidationException(
        'assessmentId cannot be empty.',
      );
    }

    if (periodEnd.isBefore(periodStart)) {
      throw const AgentRewardsIntelligenceValidationException(
        'periodEnd cannot be before periodStart.',
      );
    }

    final List<int> counters = <int>[
      rewardTransactions,
      rewardEarnEvents,
      rewardRedeemEvents,
      couponAttempts,
      couponSuccesses,
      promoAttempts,
      promoSuccesses,
      referralCount,
      suspiciousReferralCount,
      manualReviewReferralCount,
      cashbackEligibleEvents,
      cashbackAwardedEvents,
      loyaltyUsersObserved,
      loyaltyUpgradeCount,
      loyaltyDowngradeCount,
    ];

    if (counters.any((int value) => value < 0)) {
      throw const AgentRewardsIntelligenceValidationException(
        'Rewards intelligence counters cannot be negative.',
      );
    }

    if (couponSuccesses > couponAttempts) {
      throw const AgentRewardsIntelligenceValidationException(
        'couponSuccesses cannot exceed couponAttempts.',
      );
    }

    if (promoSuccesses > promoAttempts) {
      throw const AgentRewardsIntelligenceValidationException(
        'promoSuccesses cannot exceed promoAttempts.',
      );
    }

    if (suspiciousReferralCount > referralCount) {
      throw const AgentRewardsIntelligenceValidationException(
        'suspiciousReferralCount cannot exceed referralCount.',
      );
    }

    if (manualReviewReferralCount > referralCount) {
      throw const AgentRewardsIntelligenceValidationException(
        'manualReviewReferralCount cannot exceed referralCount.',
      );
    }

    if (cashbackAwardedEvents >
        cashbackEligibleEvents) {
      throw const AgentRewardsIntelligenceValidationException(
        'cashbackAwardedEvents cannot exceed cashbackEligibleEvents.',
      );
    }

    _validatePercent(
      rewardRedemptionRatePercent,
      'rewardRedemptionRatePercent',
    );

    _validatePercent(
      couponSuccessRatePercent,
      'couponSuccessRatePercent',
    );

    _validatePercent(
      promoSuccessRatePercent,
      'promoSuccessRatePercent',
    );

    _validatePercent(
      suspiciousReferralRatePercent,
      'suspiciousReferralRatePercent',
    );

    _validatePercent(
      cashbackAwardRatePercent,
      'cashbackAwardRatePercent',
    );

    if (cashbackValueRs < 0) {
      throw const AgentRewardsIntelligenceValidationException(
        'cashbackValueRs cannot be negative.',
      );
    }

    if (!AgentRewardsTrend.isValid(loyaltyTrend)) {
      throw AgentRewardsIntelligenceValidationException(
        'Invalid loyalty trend "$loyaltyTrend".',
      );
    }

    if (!AgentRewardsInsightSeverity.isValid(
      severity,
    )) {
      throw AgentRewardsIntelligenceValidationException(
        'Invalid insight severity "$severity".',
      );
    }
  }

  void _validatePercent(
    double value,
    String field,
  ) {
    if (value < 0 || value > 100) {
      throw AgentRewardsIntelligenceValidationException(
        '$field must be between 0 and 100.',
      );
    }
  }

  bool get isValid {
    try {
      validate();
      return true;
    } on AgentRewardsIntelligenceValidationException {
      return false;
    }
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'assessmentId': assessmentId,
      'periodStart': periodStart.toIso8601String(),
      'periodEnd': periodEnd.toIso8601String(),
      'rewardTransactions': rewardTransactions,
      'rewardEarnEvents': rewardEarnEvents,
      'rewardRedeemEvents': rewardRedeemEvents,
      'rewardRedemptionRatePercent':
          rewardRedemptionRatePercent,
      'couponAttempts': couponAttempts,
      'couponSuccesses': couponSuccesses,
      'couponSuccessRatePercent':
          couponSuccessRatePercent,
      'promoAttempts': promoAttempts,
      'promoSuccesses': promoSuccesses,
      'promoSuccessRatePercent':
          promoSuccessRatePercent,
      'referralCount': referralCount,
      'suspiciousReferralCount':
          suspiciousReferralCount,
      'manualReviewReferralCount':
          manualReviewReferralCount,
      'suspiciousReferralRatePercent':
          suspiciousReferralRatePercent,
      'cashbackEligibleEvents':
          cashbackEligibleEvents,
      'cashbackAwardedEvents':
          cashbackAwardedEvents,
      'cashbackAwardRatePercent':
          cashbackAwardRatePercent,
      'cashbackValueRs': cashbackValueRs,
      'loyaltyUsersObserved':
          loyaltyUsersObserved,
      'loyaltyUpgradeCount':
          loyaltyUpgradeCount,
      'loyaltyDowngradeCount':
          loyaltyDowngradeCount,
      'loyaltyTrend': loyaltyTrend,
      'severity': severity,
      'hasReferralRisk': hasReferralRisk,
      'hasLowCouponPerformance':
          hasLowCouponPerformance,
      'hasLowPromoPerformance':
          hasLowPromoPerformance,
      'loyaltyDeclining': loyaltyDeclining,
      'requiresAdminAttention':
          requiresAdminAttention,
      'findings':
          List<String>.from(findings),
      'recommendations':
          List<String>.from(recommendations),
    };
  }
}

class AgentRewardsIntelligenceValidationException
    implements Exception {
  final String message;

  const AgentRewardsIntelligenceValidationException(
    this.message,
  );

  @override
  String toString() =>
      'AgentRewardsIntelligenceValidationException: $message';
}