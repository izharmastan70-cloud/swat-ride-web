import '../models/agent_monetization_opportunity.dart';
import '../models/agent_monetization_read_only_snapshot.dart';
import 'agent_monetization_intelligence_service.dart';

/// Converts observed monetization evidence into safe recommendations.
///
/// IMPORTANT:
/// - No Firestore access.
/// - No commission/pricing mutation.
/// - No promo/reward mutation.
/// - No wallet/payment mutation.
/// - Missing metrics produce NO invented recommendation.
/// - Revenue alone must never override user benefit/risk.
class AgentMonetizationOpportunityPlanner {
  final AgentMonetizationIntelligenceService intelligence;

  const AgentMonetizationOpportunityPlanner({
    this.intelligence = const AgentMonetizationIntelligenceService(),
  });

  List<AgentMonetizationOpportunity> buildOpportunities({
    required AgentMonetizationReadOnlySnapshot snapshot,
  }) {
    snapshot.validate();

    final opportunities = <AgentMonetizationOpportunity>[];

    _addCommissionOpportunities(snapshot, opportunities);

    _addPartnerPackageOpportunities(snapshot, opportunities);

    _addSponsoredListingOpportunities(snapshot, opportunities);

    _addPromoOpportunities(snapshot, opportunities);

    _addReferralOpportunities(snapshot, opportunities);

    _addWebsiteOpportunities(snapshot, opportunities);

    _addB2bOpportunities(snapshot, opportunities);

    return intelligence.rankOpportunities(opportunities);
  }

  void _addCommissionOpportunities(
    AgentMonetizationReadOnlySnapshot snapshot,
    List<AgentMonetizationOpportunity> output,
  ) {
    final modules = snapshot.metrics.map((item) => item.module).toSet();

    for (final module in modules) {
      final commission = snapshot.findMetric(
        module: module,
        metric: AgentMonetizationMetricName.commissionPercent,
      );

      final revenue = snapshot.findMetric(
        module: module,
        metric: AgentMonetizationMetricName.grossRevenue,
      );

      // Need BOTH metrics.
      // Missing data must not be guessed.
      if (commission == null || revenue == null) {
        continue;
      }

      if (commission.value <= 0 || revenue.value <= 0) {
        continue;
      }

      final risk = commission.value >= 25
          ? 70.0
          : commission.value >= 15
          ? 45.0
          : 25.0;

      final userBenefit = commission.value >= 25 ? 45.0 : 60.0;

      output.add(
        intelligence.assessOpportunity(
          type: AgentMonetizationOpportunityType.commissionOptimization,
          module: module,
          title: '$module commission review',
          reason:
              'Observed commission is ${commission.value.toStringAsFixed(2)}% with gross revenue evidence available.',
          recommendation:
              'Review commission sustainability and partner/user impact. Do not change the percentage without Super Admin approval.',
          revenuePotentialScore: 65,
          userBenefitScore: userBenefit,
          confidenceScore: 80,
          implementationRiskScore: risk,
        ),
      );
    }
  }

  void _addPromoOpportunities(
    AgentMonetizationReadOnlySnapshot snapshot,
    List<AgentMonetizationOpportunity> output,
  ) {
    final modules = snapshot.metrics.map((item) => item.module).toSet();

    for (final module in modules) {
      final attempts = snapshot.findMetric(
        module: module,
        metric: AgentMonetizationMetricName.promoAttempts,
      );

      final successes = snapshot.findMetric(
        module: module,
        metric: AgentMonetizationMetricName.promoSuccesses,
      );

      if (attempts == null || successes == null || attempts.value <= 0) {
        continue;
      }

      if (successes.value > attempts.value) {
        continue;
      }

      final successRate = (successes.value / attempts.value) * 100;

      if (successRate >= 40) {
        continue;
      }

      output.add(
        intelligence.assessOpportunity(
          type: AgentMonetizationOpportunityType.promotion,
          module: module,
          title: '$module promotion performance review',
          reason:
              'Observed promo success rate is ${successRate.toStringAsFixed(1)}%.',
          recommendation:
              'Review promo targeting, eligibility and customer value before changing any discount amount.',
          revenuePotentialScore: 55,
          userBenefitScore: 70,
          confidenceScore: 85,
          implementationRiskScore: 35,
        ),
      );
    }
  }

  void _addReferralOpportunities(
    AgentMonetizationReadOnlySnapshot snapshot,
    List<AgentMonetizationOpportunity> output,
  ) {
    final modules = snapshot.metrics.map((item) => item.module).toSet();

    for (final module in modules) {
      final attempts = snapshot.findMetric(
        module: module,
        metric: AgentMonetizationMetricName.referralAttempts,
      );

      final successes = snapshot.findMetric(
        module: module,
        metric: AgentMonetizationMetricName.referralSuccesses,
      );

      if (attempts == null || successes == null || attempts.value <= 0) {
        continue;
      }

      if (successes.value > attempts.value) {
        continue;
      }

      final conversion = (successes.value / attempts.value) * 100;

      if (conversion >= 30) {
        continue;
      }

      output.add(
        intelligence.assessOpportunity(
          type: AgentMonetizationOpportunityType.referralCampaign,
          module: module,
          title: '$module referral improvement',
          reason:
              'Observed referral conversion is ${conversion.toStringAsFixed(1)}%.',
          recommendation:
              'Review referral messaging, fraud controls and customer benefit. Reward values remain Admin-controlled.',
          revenuePotentialScore: 60,
          userBenefitScore: 65,
          confidenceScore: 80,
          implementationRiskScore: 40,
        ),
      );
    }
  }

  /// Partner-package opportunity is recommendation-only.
  ///
  /// Phase 33 does not create a subscription, charge a partner,
  /// change commission, or enroll anyone automatically.
  ///
  /// Both partnerCount and activePartnerCount are required so
  /// missing analytics can never be guessed.
  void _addPartnerPackageOpportunities(
    AgentMonetizationReadOnlySnapshot snapshot,
    List<AgentMonetizationOpportunity> output,
  ) {
    final modules = snapshot.metrics.map((item) => item.module).toSet();

    for (final module in modules) {
      final partners = snapshot.findMetric(
        module: module,
        metric: AgentMonetizationMetricName.partnerCount,
      );

      final activePartners = snapshot.findMetric(
        module: module,
        metric: AgentMonetizationMetricName.activePartnerCount,
      );

      if (partners == null ||
          activePartners == null ||
          partners.value <= 0 ||
          activePartners.value <= 0) {
        continue;
      }

      if (activePartners.value > partners.value) {
        continue;
      }

      // Avoid recommending a package for very small datasets.
      if (partners.value < 5 || activePartners.value < 3) {
        continue;
      }

      final activeRate = (activePartners.value / partners.value) * 100;

      // A package opportunity needs meaningful partner activity.
      if (activeRate < 50) {
        continue;
      }

      output.add(
        intelligence.assessOpportunity(
          type: AgentMonetizationOpportunityType.partnerPackage,
          module: module,
          title: '$module partner package opportunity',
          reason:
              '${activePartners.value.toInt()} of '
              '${partners.value.toInt()} observed partners are active '
              '(${activeRate.toStringAsFixed(1)}%).',
          recommendation:
              'Consider an optional partner package with clear partner '
              'benefits. Do not auto-enroll partners, change commission, '
              'or create recurring charges without Owner approval and a '
              'separate approved business implementation.',
          revenuePotentialScore: 65,
          userBenefitScore: 70,
          confidenceScore: 80,
          implementationRiskScore: 40,
        ),
      );
    }
  }

  /// Sponsored-listing opportunity is recommendation-only.
  ///
  /// It never changes isFeatured/isSponsored, ranking, visibility,
  /// price, payment, or partner status.
  void _addSponsoredListingOpportunities(
    AgentMonetizationReadOnlySnapshot snapshot,
    List<AgentMonetizationOpportunity> output,
  ) {
    final modules = snapshot.metrics.map((item) => item.module).toSet();

    for (final module in modules) {
      final activePartners = snapshot.findMetric(
        module: module,
        metric: AgentMonetizationMetricName.activePartnerCount,
      );

      final sponsoredListings = snapshot.findMetric(
        module: module,
        metric: AgentMonetizationMetricName.sponsoredListingCount,
      );

      if (activePartners == null ||
          sponsoredListings == null ||
          activePartners.value <= 0 ||
          sponsoredListings.value < 0) {
        continue;
      }

      if (sponsoredListings.value > activePartners.value) {
        continue;
      }

      // A sponsored marketplace recommendation needs enough supply
      // to avoid creating a poor or misleading customer experience.
      if (activePartners.value < 5) {
        continue;
      }

      final sponsoredRate =
          (sponsoredListings.value / activePartners.value) * 100;

      // Do not push more sponsored placements if a large share of
      // active partners is already sponsored.
      if (sponsoredRate >= 25) {
        continue;
      }

      output.add(
        intelligence.assessOpportunity(
          type: AgentMonetizationOpportunityType.sponsoredListing,
          module: module,
          title: '$module sponsored listing opportunity',
          reason:
              '${sponsoredListings.value.toInt()} sponsored listing(s) '
              'were observed across '
              '${activePartners.value.toInt()} active partner(s) '
              '(${sponsoredRate.toStringAsFixed(1)}%).',
          recommendation:
              'Review an optional, clearly labelled sponsored-listing '
              'offering while preserving relevance and customer trust. '
              'Do not automatically change featured/sponsored status, '
              'ranking, pricing, or partner visibility.',
          revenuePotentialScore: 60,
          userBenefitScore: 60,
          confidenceScore: 75,
          implementationRiskScore: 45,
        ),
      );
    }
  }

  void _addWebsiteOpportunities(
    AgentMonetizationReadOnlySnapshot snapshot,
    List<AgentMonetizationOpportunity> output,
  ) {
    final visits = snapshot.findMetric(
      module: 'website',
      metric: AgentMonetizationMetricName.websiteVisits,
    );

    final conversions = snapshot.findMetric(
      module: 'website',
      metric: AgentMonetizationMetricName.websiteConversions,
    );

    if (visits == null ||
        conversions == null ||
        visits.value <= 0 ||
        conversions.value > visits.value) {
      return;
    }

    final conversionRate = (conversions.value / visits.value) * 100;

    if (conversionRate >= 5) {
      return;
    }

    output.add(
      intelligence.assessOpportunity(
        type: AgentMonetizationOpportunityType.websiteMonetization,
        module: 'website',
        title: 'Website conversion opportunity',
        reason:
            'Observed website conversion rate is ${conversionRate.toStringAsFixed(2)}%.',
        recommendation:
            'Improve useful service landing pages and conversion paths before considering monetization changes.',
        revenuePotentialScore: 70,
        userBenefitScore: 75,
        confidenceScore: 80,
        implementationRiskScore: 30,
      ),
    );
  }

  void _addB2bOpportunities(
    AgentMonetizationReadOnlySnapshot snapshot,
    List<AgentMonetizationOpportunity> output,
  ) {
    final leads = snapshot.findMetric(
      module: 'b2b',
      metric: AgentMonetizationMetricName.b2bLeadCount,
    );

    if (leads == null || leads.value <= 0) {
      return;
    }

    output.add(
      intelligence.assessOpportunity(
        type: AgentMonetizationOpportunityType.b2bOpportunity,
        module: 'b2b',
        title: 'B2B lead opportunity',
        reason:
            '${leads.value.toInt()} observed B2B lead(s) are available for review.',
        recommendation:
            'Review corporate transport, hotel, tourism, food or logistics package opportunities with Owner approval.',
        revenuePotentialScore: 75,
        userBenefitScore: 65,
        confidenceScore: 75,
        implementationRiskScore: 35,
      ),
    );
  }
}
