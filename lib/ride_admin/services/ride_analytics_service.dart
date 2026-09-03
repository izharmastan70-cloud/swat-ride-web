import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ride_analytics_summary.dart';

class RideAnalyticsService {
  RideAnalyticsService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _rides =>
      _firestore.collection('rides');

  Future<RideAnalyticsSummary> getSummary({
    required RideAnalyticsDateRange range,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _rides
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(range.start),
        )
        .where('createdAt', isLessThan: Timestamp.fromDate(range.end))
        .orderBy('createdAt', descending: false)
        .get();

    return _buildSummary(documents: snapshot.docs, range: range);
  }

  Future<RideAnalyticsSummary> getToday() {
    return getSummary(range: RideAnalyticsDateRange.today());
  }

  Future<RideAnalyticsSummary> getLast7Days() {
    return getSummary(range: RideAnalyticsDateRange.last7Days());
  }

  Future<RideAnalyticsSummary> getLast30Days() {
    return getSummary(range: RideAnalyticsDateRange.last30Days());
  }

  RideAnalyticsSummary _buildSummary({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
    required RideAnalyticsDateRange range,
  }) {
    int completedRides = 0;
    int cancelledRides = 0;
    int activeRides = 0;
    int searchingRides = 0;

    double grossBookingValue = 0;
    double platformCommission = 0;
    double driverEarnings = 0;

    final Set<String> activeDrivers = <String>{};

    final Map<String, RideAnalyticsBucket> paymentMethods =
        <String, RideAnalyticsBucket>{};

    final Map<String, RideAnalyticsBucket> vehicleCategories =
        <String, RideAnalyticsBucket>{};

    final Map<String, int> cancellations = <String, int>{};

    final Map<String, int> driverRideBreakdown = <String, int>{};

    for (final QueryDocumentSnapshot<Map<String, dynamic>> document
        in documents) {
      final Map<String, dynamic> data = document.data();

      final String status = _text(data['status'], fallback: 'unknown');

      final double fare = _effectiveFare(data);

      final double commission = _number(data['commissionAmount']);

      final double driverEarning = _effectiveDriverEarning(
        data,
        fare: fare,
        commission: commission,
      );

      final String paymentMethod = _normalizeKey(
        _text(data['paymentMethod'], fallback: 'unknown'),
      );

      final String vehicleCategory = _vehicleCategory(data);

      final String driverId = _text(data['driverId']);

      if (status == 'completed') {
        completedRides++;

        grossBookingValue += fare;
        platformCommission += commission;
        driverEarnings += driverEarning;

        _addBucket(paymentMethods, key: paymentMethod, amount: fare);

        _addBucket(vehicleCategories, key: vehicleCategory, amount: fare);

        if (driverId.isNotEmpty) {
          activeDrivers.add(driverId);

          driverRideBreakdown.update(
            driverId,
            (int value) => value + 1,
            ifAbsent: () => 1,
          );
        }

        continue;
      }

      if (status == 'cancelled') {
        cancelledRides++;

        final String reason = _cancellationReason(data);

        cancellations.update(
          reason,
          (int value) => value + 1,
          ifAbsent: () => 1,
        );

        continue;
      }

      if (status == 'searching') {
        searchingRides++;
      } else {
        activeRides++;
      }

      if (driverId.isNotEmpty) {
        activeDrivers.add(driverId);
      }
    }

    return RideAnalyticsSummary(
      startDate: range.start,
      endDate: range.end,
      totalRides: documents.length,
      completedRides: completedRides,
      cancelledRides: cancelledRides,
      activeRides: activeRides,
      searchingRides: searchingRides,
      grossBookingValue: grossBookingValue,
      platformCommission: platformCommission,
      driverEarnings: driverEarnings,
      uniqueActiveDrivers: activeDrivers.length,
      paymentMethodBreakdown: Map<String, RideAnalyticsBucket>.unmodifiable(
        paymentMethods,
      ),
      vehicleCategoryBreakdown: Map<String, RideAnalyticsBucket>.unmodifiable(
        vehicleCategories,
      ),
      cancellationBreakdown: Map<String, int>.unmodifiable(cancellations),
      driverRideBreakdown: Map<String, int>.unmodifiable(driverRideBreakdown),
    );
  }

  void _addBucket(
    Map<String, RideAnalyticsBucket> target, {
    required String key,
    required double amount,
  }) {
    final RideAnalyticsBucket current =
        target[key] ?? const RideAnalyticsBucket(count: 0, amount: 0);

    target[key] = current.add(count: 1, amount: amount);
  }

  double _effectiveFare(Map<String, dynamic> data) {
    final double finalFare = _number(data['finalFare']);

    if (finalFare > 0) {
      return finalFare;
    }

    return _number(data['estimatedFare']);
  }

  double _effectiveDriverEarning(
    Map<String, dynamic> data, {
    required double fare,
    required double commission,
  }) {
    final double stored = _number(data['driverEarning']);

    if (stored > 0) {
      return stored;
    }

    final double calculated = fare - commission;

    return calculated > 0 ? calculated : 0;
  }

  String _vehicleCategory(Map<String, dynamic> data) {
    final String vehicleName = _text(data['vehicleName']);

    if (vehicleName.isNotEmpty) {
      return _normalizeKey(vehicleName);
    }

    final String vehicleId = _text(data['vehicleId']);

    if (vehicleId.isNotEmpty) {
      return _normalizeKey(vehicleId);
    }

    final String driverVehicleType = _text(data['driverVehicleType']);

    if (driverVehicleType.isNotEmpty) {
      return _normalizeKey(driverVehicleType);
    }

    return 'unknown';
  }

  String _cancellationReason(Map<String, dynamic> data) {
    const List<String> keys = <String>[
      'cancellationReason',
      'cancelReason',
      'cancelledReason',
      'adminCancellationReason',
    ];

    for (final String key in keys) {
      final String value = _text(data[key]);

      if (value.isNotEmpty) {
        return _normalizeKey(value);
      }
    }

    final String cancelledBy = _text(data['cancelledBy']);

    if (cancelledBy.isNotEmpty) {
      return 'cancelled_by_${_normalizeKey(cancelledBy)}';
    }

    return 'unspecified';
  }

  String _normalizeKey(String value) {
    final String normalized = value.trim().toLowerCase();

    if (normalized.isEmpty) {
      return 'unknown';
    }

    return normalized.replaceAll(RegExp(r'\s+'), '_').replaceAll('-', '_');
  }

  String _text(dynamic value, {String fallback = ''}) {
    final String text = value?.toString().trim() ?? '';

    return text.isEmpty ? fallback : text;
  }

  double _number(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
