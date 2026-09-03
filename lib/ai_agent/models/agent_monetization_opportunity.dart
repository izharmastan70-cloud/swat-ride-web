class AgentMonetizationOpportunityType {
  AgentMonetizationOpportunityType._();

  static const String commissionOptimization = 'commission_optimization';

  static const String partnerPackage = 'partner_package';

  static const String sponsoredListing = 'sponsored_listing';

  static const String websiteMonetization = 'website_monetization';

  static const String referralCampaign = 'referral_campaign';

  static const String promotion = 'promotion';

  static const String b2bOpportunity = 'b2b_opportunity';

  static const Set<String> values = <String>{
    commissionOptimization,
    partnerPackage,
    sponsoredListing,
    websiteMonetization,
    referralCampaign,
    promotion,
    b2bOpportunity,
  };
}

class AgentMonetizationOpportunity {
  final String type;
  final String module;
  final String title;
  final String reason;
  final String recommendation;

  /// Normalized 0..100 signals.
  final double revenuePotentialScore;
  final double userBenefitScore;
  final double confidenceScore;
  final double implementationRiskScore;

  final bool requiresAdminReview;
  final bool requiresSuperAdminReview;

  final DateTime createdAt;

  const AgentMonetizationOpportunity({
    required this.type,
    required this.module,
    required this.title,
    required this.reason,
    required this.recommendation,
    required this.revenuePotentialScore,
    required this.userBenefitScore,
    required this.confidenceScore,
    required this.implementationRiskScore,
    required this.requiresAdminReview,
    required this.requiresSuperAdminReview,
    required this.createdAt,
  });

  double get priorityScore {
    final value =
        (revenuePotentialScore * 0.35) +
        (userBenefitScore * 0.30) +
        (confidenceScore * 0.25) -
        (implementationRiskScore * 0.10);

    return value.clamp(0.0, 100.0).toDouble();
  }

  bool get isSuitableForRecommendation =>
      confidenceScore >= 50 &&
      userBenefitScore >= 40 &&
      implementationRiskScore <= 80;

  void validate() {
    if (!AgentMonetizationOpportunityType.values.contains(type)) {
      throw AgentMonetizationOpportunityValidationException(
        'Unsupported opportunity type: $type',
      );
    }

    if (module.trim().isEmpty) {
      throw const AgentMonetizationOpportunityValidationException(
        'module is required',
      );
    }

    if (title.trim().isEmpty) {
      throw const AgentMonetizationOpportunityValidationException(
        'title is required',
      );
    }

    if (reason.trim().isEmpty) {
      throw const AgentMonetizationOpportunityValidationException(
        'reason is required',
      );
    }

    if (recommendation.trim().isEmpty) {
      throw const AgentMonetizationOpportunityValidationException(
        'recommendation is required',
      );
    }

    _validateScore(revenuePotentialScore, 'revenuePotentialScore');

    _validateScore(userBenefitScore, 'userBenefitScore');

    _validateScore(confidenceScore, 'confidenceScore');

    _validateScore(implementationRiskScore, 'implementationRiskScore');
  }

  void _validateScore(double value, String field) {
    if (value < 0 || value > 100) {
      throw AgentMonetizationOpportunityValidationException(
        '$field must be between 0 and 100',
      );
    }
  }

  Map<String, dynamic> toMap() {
    validate();

    return <String, dynamic>{
      'type': type,
      'module': module,
      'title': title,
      'reason': reason,
      'recommendation': recommendation,
      'revenuePotentialScore': revenuePotentialScore,
      'userBenefitScore': userBenefitScore,
      'confidenceScore': confidenceScore,
      'implementationRiskScore': implementationRiskScore,
      'priorityScore': priorityScore,
      'requiresAdminReview': requiresAdminReview,
      'requiresSuperAdminReview': requiresSuperAdminReview,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class AgentMonetizationOpportunityValidationException implements Exception {
  final String message;

  const AgentMonetizationOpportunityValidationException(this.message);

  @override
  String toString() =>
      'AgentMonetizationOpportunityValidationException: $message';
}
