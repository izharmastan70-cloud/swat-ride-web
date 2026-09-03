import '../models/agent_rewards_intelligence_assessment.dart';

// =========================================================
// AI AGENT - REWARDS/PROMO INTELLIGENCE SERVICE
// =========================================================
//
// Phase 31 Step 3.
//
// ANALYSIS / RECOMMENDATION ONLY.
//
// Calculates:
// - reward redemption rate
// - coupon success rate
// - promo success rate
// - suspicious referral rate
// - cashback effectiveness
// - loyalty trend
// - severity
// - findings
// - recommendations
//
// NO FIRESTORE WRITE.
// NO REWARD VALUE CHANGE.
// NO WALLET MUTATION.
// NO COUPON/PROMO CHANGE.
// NO CASHBACK CHANGE.
// NO REFERRAL REWARD CHANGE.
// NO LOYALTY LEVEL CHANGE.

class AgentRewardsIntelligenceService {
  const AgentRewardsIntelligenceService();

  AgentRewardsIntelligenceAssessment assess({
    required String assessmentId,
    required DateTime periodStart,
    required DateTime periodEnd,

    required int rewardTransactions,
    required int rewardEarnEvents,
    required int rewardRedeemEvents,

    required int couponAttempts,
    required int couponSuccesses,

    required int promoAttempts,
    required int promoSuccesses,

    required int referralCount,
    required int suspiciousReferralCount,
    required int manualReviewReferralCount,

    required int cashbackEligibleEvents,
    required int cashbackAwardedEvents,
    required double cashbackValueRs,

    required int loyaltyUsersObserved,
    required int loyaltyUpgradeCount,
    required int loyaltyDowngradeCount,

    double referralWarningPercent = 5,
    double referralHighPercent = 15,
    double referralCriticalPercent = 30,

    double lowCouponSuccessPercent = 25,
    double lowPromoSuccessPercent = 25,
    double lowCashbackAwardPercent = 25,
  }) {
    _validateCounters(
      <int>[
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
      ],
    );

    if (couponSuccesses > couponAttempts) {
      throw const AgentRewardsIntelligenceServiceException(
        'couponSuccesses cannot exceed couponAttempts.',
      );
    }

    if (promoSuccesses > promoAttempts) {
      throw const AgentRewardsIntelligenceServiceException(
        'promoSuccesses cannot exceed promoAttempts.',
      );
    }

    if (suspiciousReferralCount > referralCount ||
        manualReviewReferralCount > referralCount) {
      throw const AgentRewardsIntelligenceServiceException(
        'Referral risk counters cannot exceed referralCount.',
      );
    }

    if (cashbackAwardedEvents >
        cashbackEligibleEvents) {
      throw const AgentRewardsIntelligenceServiceException(
        'cashbackAwardedEvents cannot exceed cashbackEligibleEvents.',
      );
    }

    if (cashbackValueRs < 0) {
      throw const AgentRewardsIntelligenceServiceException(
        'cashbackValueRs cannot be negative.',
      );
    }

    _validateThreshold(
      referralWarningPercent,
      'referralWarningPercent',
    );

    _validateThreshold(
      referralHighPercent,
      'referralHighPercent',
    );

    _validateThreshold(
      referralCriticalPercent,
      'referralCriticalPercent',
    );

    _validateThreshold(
      lowCouponSuccessPercent,
      'lowCouponSuccessPercent',
    );

    _validateThreshold(
      lowPromoSuccessPercent,
      'lowPromoSuccessPercent',
    );

    _validateThreshold(
      lowCashbackAwardPercent,
      'lowCashbackAwardPercent',
    );

    if (!(referralWarningPercent <=
            referralHighPercent &&
        referralHighPercent <=
            referralCriticalPercent)) {
      throw const AgentRewardsIntelligenceServiceException(
        'Referral severity thresholds must be ordered warning <= high <= critical.',
      );
    }

    final double rewardRedemptionRate =
        _percent(
      rewardRedeemEvents,
      rewardEarnEvents,
    );

    final double couponSuccessRate =
        _percent(
      couponSuccesses,
      couponAttempts,
    );

    final double promoSuccessRate =
        _percent(
      promoSuccesses,
      promoAttempts,
    );

    final double suspiciousReferralRate =
        _percent(
      suspiciousReferralCount,
      referralCount,
    );

    final double cashbackAwardRate =
        _percent(
      cashbackAwardedEvents,
      cashbackEligibleEvents,
    );

    final String loyaltyTrend =
        _loyaltyTrend(
      upgrades: loyaltyUpgradeCount,
      downgrades: loyaltyDowngradeCount,
      observedUsers: loyaltyUsersObserved,
    );

    final String severity =
        _severity(
      suspiciousReferralRate:
          suspiciousReferralRate,
      manualReviewReferralCount:
          manualReviewReferralCount,
      couponAttempts: couponAttempts,
      couponSuccessRate:
          couponSuccessRate,
      promoAttempts: promoAttempts,
      promoSuccessRate:
          promoSuccessRate,
      cashbackEligibleEvents:
          cashbackEligibleEvents,
      cashbackAwardRate:
          cashbackAwardRate,
      loyaltyTrend: loyaltyTrend,
      referralWarningPercent:
          referralWarningPercent,
      referralHighPercent:
          referralHighPercent,
      referralCriticalPercent:
          referralCriticalPercent,
      lowCouponSuccessPercent:
          lowCouponSuccessPercent,
      lowPromoSuccessPercent:
          lowPromoSuccessPercent,
      lowCashbackAwardPercent:
          lowCashbackAwardPercent,
    );

    final List<String> findings =
        _findings(
      rewardRedemptionRate:
          rewardRedemptionRate,
      couponAttempts:
          couponAttempts,
      couponSuccessRate:
          couponSuccessRate,
      promoAttempts:
          promoAttempts,
      promoSuccessRate:
          promoSuccessRate,
      referralCount:
          referralCount,
      suspiciousReferralCount:
          suspiciousReferralCount,
      suspiciousReferralRate:
          suspiciousReferralRate,
      manualReviewReferralCount:
          manualReviewReferralCount,
      cashbackEligibleEvents:
          cashbackEligibleEvents,
      cashbackAwardRate:
          cashbackAwardRate,
      loyaltyTrend:
          loyaltyTrend,
      lowCouponSuccessPercent:
          lowCouponSuccessPercent,
      lowPromoSuccessPercent:
          lowPromoSuccessPercent,
      lowCashbackAwardPercent:
          lowCashbackAwardPercent,
    );

    final List<String> recommendations =
        _recommendations(
      severity: severity,
      couponAttempts:
          couponAttempts,
      couponSuccessRate:
          couponSuccessRate,
      promoAttempts:
          promoAttempts,
      promoSuccessRate:
          promoSuccessRate,
      suspiciousReferralCount:
          suspiciousReferralCount,
      manualReviewReferralCount:
          manualReviewReferralCount,
      cashbackEligibleEvents:
          cashbackEligibleEvents,
      cashbackAwardRate:
          cashbackAwardRate,
      loyaltyTrend:
          loyaltyTrend,
      lowCouponSuccessPercent:
          lowCouponSuccessPercent,
      lowPromoSuccessPercent:
          lowPromoSuccessPercent,
      lowCashbackAwardPercent:
          lowCashbackAwardPercent,
    );

    final AgentRewardsIntelligenceAssessment result =
        AgentRewardsIntelligenceAssessment(
      assessmentId:
          assessmentId,
      periodStart:
          periodStart,
      periodEnd:
          periodEnd,
      rewardTransactions:
          rewardTransactions,
      rewardEarnEvents:
          rewardEarnEvents,
      rewardRedeemEvents:
          rewardRedeemEvents,
      rewardRedemptionRatePercent:
          rewardRedemptionRate,
      couponAttempts:
          couponAttempts,
      couponSuccesses:
          couponSuccesses,
      couponSuccessRatePercent:
          couponSuccessRate,
      promoAttempts:
          promoAttempts,
      promoSuccesses:
          promoSuccesses,
      promoSuccessRatePercent:
          promoSuccessRate,
      referralCount:
          referralCount,
      suspiciousReferralCount:
          suspiciousReferralCount,
      manualReviewReferralCount:
          manualReviewReferralCount,
      suspiciousReferralRatePercent:
          suspiciousReferralRate,
      cashbackEligibleEvents:
          cashbackEligibleEvents,
      cashbackAwardedEvents:
          cashbackAwardedEvents,
      cashbackAwardRatePercent:
          cashbackAwardRate,
      cashbackValueRs:
          cashbackValueRs,
      loyaltyUsersObserved:
          loyaltyUsersObserved,
      loyaltyUpgradeCount:
          loyaltyUpgradeCount,
      loyaltyDowngradeCount:
          loyaltyDowngradeCount,
      loyaltyTrend:
          loyaltyTrend,
      severity:
          severity,
      findings:
          findings,
      recommendations:
          recommendations,
    );

    result.validate();

    return result;
  }

  double _percent(
    int numerator,
    int denominator,
  ) {
    if (denominator <= 0) {
      return 0;
    }

    return (numerator / denominator) * 100;
  }

  String _loyaltyTrend({
    required int upgrades,
    required int downgrades,
    required int observedUsers,
  }) {
    if (observedUsers <= 0) {
      return AgentRewardsTrend.unknown;
    }

    if (upgrades > downgrades) {
      return AgentRewardsTrend.improving;
    }

    if (downgrades > upgrades) {
      return AgentRewardsTrend.declining;
    }

    return AgentRewardsTrend.stable;
  }

  String _severity({
    required double suspiciousReferralRate,
    required int manualReviewReferralCount,
    required int couponAttempts,
    required double couponSuccessRate,
    required int promoAttempts,
    required double promoSuccessRate,
    required int cashbackEligibleEvents,
    required double cashbackAwardRate,
    required String loyaltyTrend,
    required double referralWarningPercent,
    required double referralHighPercent,
    required double referralCriticalPercent,
    required double lowCouponSuccessPercent,
    required double lowPromoSuccessPercent,
    required double lowCashbackAwardPercent,
  }) {
    if (suspiciousReferralRate >=
        referralCriticalPercent) {
      return AgentRewardsInsightSeverity.critical;
    }

    if (suspiciousReferralRate >=
            referralHighPercent ||
        manualReviewReferralCount >= 5) {
      return AgentRewardsInsightSeverity.high;
    }

    if (suspiciousReferralRate >=
            referralWarningPercent ||
        (couponAttempts > 0 &&
            couponSuccessRate <
                lowCouponSuccessPercent) ||
        (promoAttempts > 0 &&
            promoSuccessRate <
                lowPromoSuccessPercent) ||
        (cashbackEligibleEvents > 0 &&
            cashbackAwardRate <
                lowCashbackAwardPercent) ||
        loyaltyTrend ==
            AgentRewardsTrend.declining) {
      return AgentRewardsInsightSeverity.warning;
    }

    return AgentRewardsInsightSeverity.info;
  }

  List<String> _findings({
    required double rewardRedemptionRate,
    required int couponAttempts,
    required double couponSuccessRate,
    required int promoAttempts,
    required double promoSuccessRate,
    required int referralCount,
    required int suspiciousReferralCount,
    required double suspiciousReferralRate,
    required int manualReviewReferralCount,
    required int cashbackEligibleEvents,
    required double cashbackAwardRate,
    required String loyaltyTrend,
    required double lowCouponSuccessPercent,
    required double lowPromoSuccessPercent,
    required double lowCashbackAwardPercent,
  }) {
    final List<String> findings =
        <String>[];

    findings.add(
      'Reward redemption rate: '
      '${rewardRedemptionRate.toStringAsFixed(1)}%.',
    );

    if (couponAttempts > 0 &&
        couponSuccessRate <
            lowCouponSuccessPercent) {
      findings.add(
        'Coupon success rate is low at '
        '${couponSuccessRate.toStringAsFixed(1)}%.',
      );
    }

    if (promoAttempts > 0 &&
        promoSuccessRate <
            lowPromoSuccessPercent) {
      findings.add(
        'Promo success rate is low at '
        '${promoSuccessRate.toStringAsFixed(1)}%.',
      );
    }

    if (referralCount > 0 &&
        suspiciousReferralCount > 0) {
      findings.add(
        'Suspicious referrals: '
        '$suspiciousReferralCount '
        '(${suspiciousReferralRate.toStringAsFixed(1)}%).',
      );
    }

    if (manualReviewReferralCount > 0) {
      findings.add(
        '$manualReviewReferralCount referrals require manual review.',
      );
    }

    if (cashbackEligibleEvents > 0 &&
        cashbackAwardRate <
            lowCashbackAwardPercent) {
      findings.add(
        'Cashback award rate is low at '
        '${cashbackAwardRate.toStringAsFixed(1)}%.',
      );
    }

    if (loyaltyTrend ==
        AgentRewardsTrend.declining) {
      findings.add(
        'Loyalty pattern is declining.',
      );
    }

    if (findings.length == 1) {
      findings.add(
        'No major Rewards/Promo intelligence issue detected.',
      );
    }

    return findings;
  }

  List<String> _recommendations({
    required String severity,
    required int couponAttempts,
    required double couponSuccessRate,
    required int promoAttempts,
    required double promoSuccessRate,
    required int suspiciousReferralCount,
    required int manualReviewReferralCount,
    required int cashbackEligibleEvents,
    required double cashbackAwardRate,
    required String loyaltyTrend,
    required double lowCouponSuccessPercent,
    required double lowPromoSuccessPercent,
    required double lowCashbackAwardPercent,
  }) {
    final List<String> recommendations =
        <String>[];

    if (suspiciousReferralCount > 0 ||
        manualReviewReferralCount > 0) {
      recommendations.add(
        'Review suspicious referrals and existing fraud/manual-review evidence before issuing rewards. Do not ban users automatically.',
      );
    }

    if (couponAttempts > 0 &&
        couponSuccessRate <
            lowCouponSuccessPercent) {
      recommendations.add(
        'Review coupon eligibility, targeting and rejection reasons. Do not automatically increase coupon value.',
      );
    }

    if (promoAttempts > 0 &&
        promoSuccessRate <
            lowPromoSuccessPercent) {
      recommendations.add(
        'Review promo targeting, eligibility and usage friction. Do not automatically change promo discount.',
      );
    }

    if (cashbackEligibleEvents > 0 &&
        cashbackAwardRate <
            lowCashbackAwardPercent) {
      recommendations.add(
        'Review cashback eligibility and award completion flow. Do not automatically change cashback percentage.',
      );
    }

    if (loyaltyTrend ==
        AgentRewardsTrend.declining) {
      recommendations.add(
        'Review loyalty engagement and upgrade patterns; recommend changes for Admin review only.',
      );
    }

    if (severity ==
            AgentRewardsInsightSeverity.high ||
        severity ==
            AgentRewardsInsightSeverity.critical) {
      recommendations.add(
        'Escalate this Rewards intelligence report to Admin/Super Admin for review.',
      );
    }

    if (recommendations.isEmpty) {
      recommendations.add(
        'Continue monitoring Rewards/Promo performance; no immediate intervention is recommended.',
      );
    }

    return recommendations;
  }

  void _validateCounters(
    Iterable<int> counters,
  ) {
    if (counters.any((int value) => value < 0)) {
      throw const AgentRewardsIntelligenceServiceException(
        'Rewards intelligence counters cannot be negative.',
      );
    }
  }

  void _validateThreshold(
    double value,
    String name,
  ) {
    if (value < 0 || value > 100) {
      throw AgentRewardsIntelligenceServiceException(
        '$name must be between 0 and 100.',
      );
    }
  }
}

class AgentRewardsIntelligenceServiceException
    implements Exception {
  final String message;

  const AgentRewardsIntelligenceServiceException(
    this.message,
  );

  @override
  String toString() =>
      'AgentRewardsIntelligenceServiceException: $message';
}