class AgentMonetizationRisk {
  AgentMonetizationRisk._();

  static const String low = 'low';
  static const String medium = 'medium';
  static const String high = 'high';
  static const String critical = 'critical';

  static const Set<String> values = <String>{low, medium, high, critical};
}

class AgentMonetizationAction {
  AgentMonetizationAction._();

  static const String observe = 'observe';
  static const String recommend = 'recommend';
  static const String proposeChange = 'propose_change';

  static const String changeCommission = 'change_commission';
  static const String changePricing = 'change_pricing';
  static const String changeDiscount = 'change_discount';
  static const String changeReward = 'change_reward';

  static const String walletCredit = 'wallet_credit';
  static const String walletDebit = 'wallet_debit';
  static const String payout = 'payout';
  static const String withdrawal = 'withdrawal';
  static const String settlement = 'settlement';
  static const String refund = 'refund';
}

class AgentMonetizationAssessment {
  final String module;
  final String subject;
  final String summary;
  final String recommendation;
  final String riskLevel;

  final double? currentValue;
  final double? proposedValue;

  final bool requiresAdminReview;
  final bool requiresSuperAdminReview;
  final bool financialWriteRequested;

  final DateTime createdAt;

  const AgentMonetizationAssessment({
    required this.module,
    required this.subject,
    required this.summary,
    required this.recommendation,
    required this.riskLevel,
    required this.requiresAdminReview,
    required this.requiresSuperAdminReview,
    required this.financialWriteRequested,
    required this.createdAt,
    this.currentValue,
    this.proposedValue,
  });

  bool get isHighRisk =>
      riskLevel == AgentMonetizationRisk.high ||
      riskLevel == AgentMonetizationRisk.critical;

  bool get canAutoExecute =>
      !financialWriteRequested &&
      !requiresAdminReview &&
      !requiresSuperAdminReview &&
      !isHighRisk;

  void validate() {
    if (module.trim().isEmpty) {
      throw const AgentMonetizationValidationException('module is required');
    }

    if (subject.trim().isEmpty) {
      throw const AgentMonetizationValidationException('subject is required');
    }

    if (summary.trim().isEmpty) {
      throw const AgentMonetizationValidationException('summary is required');
    }

    if (recommendation.trim().isEmpty) {
      throw const AgentMonetizationValidationException(
        'recommendation is required',
      );
    }

    if (!AgentMonetizationRisk.values.contains(riskLevel)) {
      throw AgentMonetizationValidationException(
        'Unsupported risk level: $riskLevel',
      );
    }

    if (financialWriteRequested &&
        !requiresAdminReview &&
        !requiresSuperAdminReview) {
      throw const AgentMonetizationValidationException(
        'Financial writes cannot bypass human review.',
      );
    }
  }

  Map<String, dynamic> toMap() {
    validate();

    return <String, dynamic>{
      'module': module,
      'subject': subject,
      'summary': summary,
      'recommendation': recommendation,
      'riskLevel': riskLevel,
      'currentValue': currentValue,
      'proposedValue': proposedValue,
      'requiresAdminReview': requiresAdminReview,
      'requiresSuperAdminReview': requiresSuperAdminReview,
      'financialWriteRequested': financialWriteRequested,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class AgentMonetizationValidationException implements Exception {
  final String message;

  const AgentMonetizationValidationException(this.message);

  @override
  String toString() => 'AgentMonetizationValidationException: $message';
}
