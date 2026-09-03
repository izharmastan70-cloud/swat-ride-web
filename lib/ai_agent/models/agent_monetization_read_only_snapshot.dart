class AgentMonetizationMetricName {
  AgentMonetizationMetricName._();

  static const String commissionPercent = 'commission_percent';

  static const String grossRevenue = 'gross_revenue';

  static const String netRevenue = 'net_revenue';

  static const String refundedAmount = 'refunded_amount';

  static const String settlementAmount = 'settlement_amount';

  static const String averageOrderValue = 'average_order_value';

  static const String bookingCount = 'booking_count';

  static const String orderCount = 'order_count';

  static const String promoAttempts = 'promo_attempts';

  static const String promoSuccesses = 'promo_successes';

  static const String referralAttempts = 'referral_attempts';

  static const String referralSuccesses = 'referral_successes';

  static const String cashbackAmount = 'cashback_amount';

  static const String partnerCount = 'partner_count';

  static const String activePartnerCount = 'active_partner_count';

  static const String sponsoredListingCount = 'sponsored_listing_count';

  static const String websiteVisits = 'website_visits';

  static const String websiteConversions = 'website_conversions';

  static const String b2bLeadCount = 'b2b_lead_count';

  static const Set<String> values = <String>{
    commissionPercent,
    grossRevenue,
    netRevenue,
    refundedAmount,
    settlementAmount,
    averageOrderValue,
    bookingCount,
    orderCount,
    promoAttempts,
    promoSuccesses,
    referralAttempts,
    referralSuccesses,
    cashbackAmount,
    partnerCount,
    activePartnerCount,
    sponsoredListingCount,
    websiteVisits,
    websiteConversions,
    b2bLeadCount,
  };
}

class AgentMonetizationObservedMetric {
  final String source;
  final String module;
  final String metric;
  final double value;
  final String unit;
  final DateTime observedAt;

  const AgentMonetizationObservedMetric({
    required this.source,
    required this.module,
    required this.metric,
    required this.value,
    required this.unit,
    required this.observedAt,
  });

  void validate() {
    if (source.trim().isEmpty) {
      throw const AgentMonetizationSnapshotException(
        'Metric source is required.',
      );
    }

    if (module.trim().isEmpty) {
      throw const AgentMonetizationSnapshotException(
        'Metric module is required.',
      );
    }

    if (!AgentMonetizationMetricName.values.contains(metric)) {
      throw AgentMonetizationSnapshotException(
        'Unsupported monetization metric: $metric',
      );
    }

    if (!value.isFinite) {
      throw const AgentMonetizationSnapshotException(
        'Metric value must be finite.',
      );
    }

    if (unit.trim().isEmpty) {
      throw const AgentMonetizationSnapshotException(
        'Metric unit is required.',
      );
    }
  }

  Map<String, dynamic> toMap() {
    validate();

    return <String, dynamic>{
      'source': source,
      'module': module,
      'metric': metric,
      'value': value,
      'unit': unit,
      'observedAt': observedAt.toIso8601String(),
    };
  }
}

class AgentMonetizationReadOnlySnapshot {
  final List<AgentMonetizationObservedMetric> metrics;
  final DateTime generatedAt;

  const AgentMonetizationReadOnlySnapshot({
    required this.metrics,
    required this.generatedAt,
  });

  bool get isEmpty => metrics.isEmpty;

  Iterable<AgentMonetizationObservedMetric> forModule(String module) {
    final normalized = module.trim().toLowerCase();

    return metrics.where(
      (item) => item.module.trim().toLowerCase() == normalized,
    );
  }

  AgentMonetizationObservedMetric? findMetric({
    required String module,
    required String metric,
  }) {
    for (final item in metrics) {
      if (item.module.trim().toLowerCase() == module.trim().toLowerCase() &&
          item.metric == metric) {
        return item;
      }
    }

    return null;
  }

  void validate() {
    final keys = <String>{};

    for (final metric in metrics) {
      metric.validate();

      final key = '${metric.module.trim().toLowerCase()}::${metric.metric}';

      if (!keys.add(key)) {
        throw AgentMonetizationSnapshotException(
          'Duplicate module/metric observation: $key',
        );
      }
    }
  }

  Map<String, dynamic> toMap() {
    validate();

    return <String, dynamic>{
      'metrics': metrics.map((item) => item.toMap()).toList(growable: false),
      'generatedAt': generatedAt.toIso8601String(),
    };
  }
}

class AgentMonetizationSnapshotException implements Exception {
  final String message;

  const AgentMonetizationSnapshotException(this.message);

  @override
  String toString() => 'AgentMonetizationSnapshotException: $message';
}
