class RideAnalyticsSummary {
  const RideAnalyticsSummary({
    required this.startDate,
    required this.endDate,
    required this.totalRides,
    required this.completedRides,
    required this.cancelledRides,
    required this.activeRides,
    required this.searchingRides,
    required this.grossBookingValue,
    required this.platformCommission,
    required this.driverEarnings,
    required this.uniqueActiveDrivers,
    required this.paymentMethodBreakdown,
    required this.vehicleCategoryBreakdown,
    required this.cancellationBreakdown,
    required this.driverRideBreakdown,
  });

  final DateTime startDate;
  final DateTime endDate;

  final int totalRides;
  final int completedRides;
  final int cancelledRides;
  final int activeRides;
  final int searchingRides;

  final double grossBookingValue;
  final double platformCommission;
  final double driverEarnings;

  final int uniqueActiveDrivers;

  final Map<String, RideAnalyticsBucket> paymentMethodBreakdown;

  final Map<String, RideAnalyticsBucket> vehicleCategoryBreakdown;

  final Map<String, int> cancellationBreakdown;

  final Map<String, int> driverRideBreakdown;

  double get completionRate {
    if (totalRides <= 0) {
      return 0;
    }

    return completedRides / totalRides;
  }

  double get cancellationRate {
    if (totalRides <= 0) {
      return 0;
    }

    return cancelledRides / totalRides;
  }

  double get averageCompletedFare {
    if (completedRides <= 0) {
      return 0;
    }

    return grossBookingValue / completedRides;
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'totalRides': totalRides,
      'completedRides': completedRides,
      'cancelledRides': cancelledRides,
      'activeRides': activeRides,
      'searchingRides': searchingRides,
      'grossBookingValue': grossBookingValue,
      'platformCommission': platformCommission,
      'driverEarnings': driverEarnings,
      'uniqueActiveDrivers': uniqueActiveDrivers,
      'completionRate': completionRate,
      'cancellationRate': cancellationRate,
      'averageCompletedFare': averageCompletedFare,
      'paymentMethodBreakdown': paymentMethodBreakdown.map(
        (String key, RideAnalyticsBucket value) =>
            MapEntry<String, dynamic>(key, value.toMap()),
      ),
      'vehicleCategoryBreakdown': vehicleCategoryBreakdown.map(
        (String key, RideAnalyticsBucket value) =>
            MapEntry<String, dynamic>(key, value.toMap()),
      ),
      'cancellationBreakdown': cancellationBreakdown,
      'driverRideBreakdown': driverRideBreakdown,
    };
  }
}

class RideAnalyticsBucket {
  const RideAnalyticsBucket({required this.count, required this.amount});

  final int count;
  final double amount;

  RideAnalyticsBucket add({int count = 0, double amount = 0}) {
    return RideAnalyticsBucket(
      count: this.count + count,
      amount: this.amount + amount,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{'count': count, 'amount': amount};
  }
}

enum RideAnalyticsPreset { today, last7Days, last30Days, custom }

class RideAnalyticsDateRange {
  const RideAnalyticsDateRange({required this.start, required this.end});

  final DateTime start;

  /// Exclusive end.
  final DateTime end;

  factory RideAnalyticsDateRange.today({DateTime? now}) {
    final DateTime current = now ?? DateTime.now();

    final DateTime start = DateTime(current.year, current.month, current.day);

    return RideAnalyticsDateRange(
      start: start,
      end: start.add(const Duration(days: 1)),
    );
  }

  factory RideAnalyticsDateRange.last7Days({DateTime? now}) {
    final DateTime current = now ?? DateTime.now();

    final DateTime today = DateTime(current.year, current.month, current.day);

    return RideAnalyticsDateRange(
      start: today.subtract(const Duration(days: 6)),
      end: today.add(const Duration(days: 1)),
    );
  }

  factory RideAnalyticsDateRange.last30Days({DateTime? now}) {
    final DateTime current = now ?? DateTime.now();

    final DateTime today = DateTime(current.year, current.month, current.day);

    return RideAnalyticsDateRange(
      start: today.subtract(const Duration(days: 29)),
      end: today.add(const Duration(days: 1)),
    );
  }

  factory RideAnalyticsDateRange.custom({
    required DateTime start,
    required DateTime endInclusive,
  }) {
    final DateTime normalizedStart = DateTime(
      start.year,
      start.month,
      start.day,
    );

    final DateTime normalizedEnd = DateTime(
      endInclusive.year,
      endInclusive.month,
      endInclusive.day,
    ).add(const Duration(days: 1));

    if (!normalizedEnd.isAfter(normalizedStart)) {
      throw ArgumentError(
        'Analytics end date must be on or after the start date.',
      );
    }

    return RideAnalyticsDateRange(start: normalizedStart, end: normalizedEnd);
  }
}
