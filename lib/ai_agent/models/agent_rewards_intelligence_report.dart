import 'agent_rewards_intelligence_assessment.dart';

// =========================================================
// AI AGENT - REWARDS INTELLIGENCE ADMIN REPORT
// =========================================================
//
// Phase 31 Step 5.
//
// Consolidates Rewards/Promo intelligence assessments into
// an Admin/Super Admin review report.
//
// REPORT / RECOMMENDATION ONLY.
//
// NO FIRESTORE WRITE.
// NO REWARD BALANCE CHANGE.
// NO WALLET MUTATION.
// NO COUPON/PROMO VALUE CHANGE.
// NO CASHBACK CHANGE.
// NO REFERRAL REWARD CHANGE.
// NO LOYALTY LEVEL CHANGE.
// NO ACCOUNT ACTION.

class AgentRewardsIntelligenceReport {
  final List<AgentRewardsIntelligenceAssessment>
      assessments;

  final int totalRewardTransactions;
  final int totalRewardEarnEvents;
  final int totalRewardRedeemEvents;

  final int totalCouponAttempts;
  final int totalCouponSuccesses;

  final int totalPromoAttempts;
  final int totalPromoSuccesses;

  final int totalReferrals;
  final int suspiciousReferrals;
  final int manualReviewReferrals;

  final int totalCashbackEligibleEvents;
  final int totalCashbackAwardedEvents;
  final double totalCashbackValueRs;

  final int totalLoyaltyUsersObserved;
  final int totalLoyaltyUpgrades;
  final int totalLoyaltyDowngrades;

  final int infoCount;
  final int warningCount;
  final int highCount;
  final int criticalCount;

  final List<String> findings;
  final List<String> recommendations;

  const AgentRewardsIntelligenceReport({
    required this.assessments,
    required this.totalRewardTransactions,
    required this.totalRewardEarnEvents,
    required this.totalRewardRedeemEvents,
    required this.totalCouponAttempts,
    required this.totalCouponSuccesses,
    required this.totalPromoAttempts,
    required this.totalPromoSuccesses,
    required this.totalReferrals,
    required this.suspiciousReferrals,
    required this.manualReviewReferrals,
    required this.totalCashbackEligibleEvents,
    required this.totalCashbackAwardedEvents,
    required this.totalCashbackValueRs,
    required this.totalLoyaltyUsersObserved,
    required this.totalLoyaltyUpgrades,
    required this.totalLoyaltyDowngrades,
    required this.infoCount,
    required this.warningCount,
    required this.highCount,
    required this.criticalCount,
    required this.findings,
    required this.recommendations,
  });

  bool get requiresAdminReview =>
      warningCount > 0 ||
      highCount > 0 ||
      criticalCount > 0 ||
      manualReviewReferrals > 0;

  bool get requiresSuperAdminReview =>
      criticalCount > 0;

  bool get hasReferralRisk =>
      suspiciousReferrals > 0 ||
      manualReviewReferrals > 0;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'totalRewardTransactions':
          totalRewardTransactions,
      'totalRewardEarnEvents':
          totalRewardEarnEvents,
      'totalRewardRedeemEvents':
          totalRewardRedeemEvents,
      'totalCouponAttempts':
          totalCouponAttempts,
      'totalCouponSuccesses':
          totalCouponSuccesses,
      'totalPromoAttempts':
          totalPromoAttempts,
      'totalPromoSuccesses':
          totalPromoSuccesses,
      'totalReferrals':
          totalReferrals,
      'suspiciousReferrals':
          suspiciousReferrals,
      'manualReviewReferrals':
          manualReviewReferrals,
      'totalCashbackEligibleEvents':
          totalCashbackEligibleEvents,
      'totalCashbackAwardedEvents':
          totalCashbackAwardedEvents,
      'totalCashbackValueRs':
          totalCashbackValueRs,
      'totalLoyaltyUsersObserved':
          totalLoyaltyUsersObserved,
      'totalLoyaltyUpgrades':
          totalLoyaltyUpgrades,
      'totalLoyaltyDowngrades':
          totalLoyaltyDowngrades,
      'infoCount': infoCount,
      'warningCount': warningCount,
      'highCount': highCount,
      'criticalCount': criticalCount,
      'requiresAdminReview':
          requiresAdminReview,
      'requiresSuperAdminReview':
          requiresSuperAdminReview,
      'hasReferralRisk':
          hasReferralRisk,
      'findings':
          List<String>.from(findings),
      'recommendations':
          List<String>.from(recommendations),
      'assessments': assessments
          .map(
            (AgentRewardsIntelligenceAssessment item) =>
                item.toMap(),
          )
          .toList(growable: false),
    };
  }
}

class AgentRewardsIntelligenceReportService {
  const AgentRewardsIntelligenceReportService();

  AgentRewardsIntelligenceReport build({
    required Iterable<
            AgentRewardsIntelligenceAssessment>
        assessments,
  }) {
    final List<AgentRewardsIntelligenceAssessment>
        items =
        assessments.toList(growable: false);

    int totalRewardTransactions = 0;
    int totalRewardEarnEvents = 0;
    int totalRewardRedeemEvents = 0;

    int totalCouponAttempts = 0;
    int totalCouponSuccesses = 0;

    int totalPromoAttempts = 0;
    int totalPromoSuccesses = 0;

    int totalReferrals = 0;
    int suspiciousReferrals = 0;
    int manualReviewReferrals = 0;

    int totalCashbackEligibleEvents = 0;
    int totalCashbackAwardedEvents = 0;
    double totalCashbackValueRs = 0;

    int totalLoyaltyUsersObserved = 0;
    int totalLoyaltyUpgrades = 0;
    int totalLoyaltyDowngrades = 0;

    int infoCount = 0;
    int warningCount = 0;
    int highCount = 0;
    int criticalCount = 0;

    final Set<String> findings = <String>{};
    final Set<String> recommendations = <String>{};

    for (final AgentRewardsIntelligenceAssessment item
        in items) {
      item.validate();

      totalRewardTransactions +=
          item.rewardTransactions;

      totalRewardEarnEvents +=
          item.rewardEarnEvents;

      totalRewardRedeemEvents +=
          item.rewardRedeemEvents;

      totalCouponAttempts +=
          item.couponAttempts;

      totalCouponSuccesses +=
          item.couponSuccesses;

      totalPromoAttempts +=
          item.promoAttempts;

      totalPromoSuccesses +=
          item.promoSuccesses;

      totalReferrals +=
          item.referralCount;

      suspiciousReferrals +=
          item.suspiciousReferralCount;

      manualReviewReferrals +=
          item.manualReviewReferralCount;

      totalCashbackEligibleEvents +=
          item.cashbackEligibleEvents;

      totalCashbackAwardedEvents +=
          item.cashbackAwardedEvents;

      totalCashbackValueRs +=
          item.cashbackValueRs;

      totalLoyaltyUsersObserved +=
          item.loyaltyUsersObserved;

      totalLoyaltyUpgrades +=
          item.loyaltyUpgradeCount;

      totalLoyaltyDowngrades +=
          item.loyaltyDowngradeCount;

      switch (item.severity) {
        case AgentRewardsInsightSeverity.info:
          infoCount++;
          break;

        case AgentRewardsInsightSeverity.warning:
          warningCount++;
          break;

        case AgentRewardsInsightSeverity.high:
          highCount++;
          break;

        case AgentRewardsInsightSeverity.critical:
          criticalCount++;
          break;
      }

      findings.addAll(item.findings);
      recommendations.addAll(
        item.recommendations,
      );
    }

    if (criticalCount > 0) {
      recommendations.add(
        'Critical Rewards/Promo intelligence requires Super Admin review before any configuration or reward-value change.',
      );
    } else if (highCount > 0 ||
        manualReviewReferrals > 0) {
      recommendations.add(
        'Admin review is required before any Rewards/Promo intervention.',
      );
    }

    if (suspiciousReferrals > 0) {
      recommendations.add(
        'Use existing referral fraud/manual-review evidence. Do not suspend, ban, reject or issue rewards automatically.',
      );
    }

    if (recommendations.isEmpty) {
      recommendations.add(
        'Continue monitoring Rewards/Promo performance. No immediate Admin intervention is required.',
      );
    }

    return AgentRewardsIntelligenceReport(
      assessments:
          List<AgentRewardsIntelligenceAssessment>
              .unmodifiable(items),
      totalRewardTransactions:
          totalRewardTransactions,
      totalRewardEarnEvents:
          totalRewardEarnEvents,
      totalRewardRedeemEvents:
          totalRewardRedeemEvents,
      totalCouponAttempts:
          totalCouponAttempts,
      totalCouponSuccesses:
          totalCouponSuccesses,
      totalPromoAttempts:
          totalPromoAttempts,
      totalPromoSuccesses:
          totalPromoSuccesses,
      totalReferrals:
          totalReferrals,
      suspiciousReferrals:
          suspiciousReferrals,
      manualReviewReferrals:
          manualReviewReferrals,
      totalCashbackEligibleEvents:
          totalCashbackEligibleEvents,
      totalCashbackAwardedEvents:
          totalCashbackAwardedEvents,
      totalCashbackValueRs:
          totalCashbackValueRs,
      totalLoyaltyUsersObserved:
          totalLoyaltyUsersObserved,
      totalLoyaltyUpgrades:
          totalLoyaltyUpgrades,
      totalLoyaltyDowngrades:
          totalLoyaltyDowngrades,
      infoCount:
          infoCount,
      warningCount:
          warningCount,
      highCount:
          highCount,
      criticalCount:
          criticalCount,
      findings:
          List<String>.unmodifiable(
        findings,
      ),
      recommendations:
          List<String>.unmodifiable(
        recommendations,
      ),
    );
  }
}