import 'package:cloud_firestore/cloud_firestore.dart';

import 'osrm_route_model.dart';

class RidePricingModel {
  const RidePricingModel({
    required this.vehicleId,
    required this.vehicleName,
    required this.isEnabled,
    required this.baseFare,
    required this.perKilometerRate,
    required this.perMinuteRate,
    required this.minimumFare,
    this.bookingFee = 0,
    this.surgeMultiplier = 1,
    this.adminCommissionPercentage = 0,
    this.taxPercentage = 0,
    this.roundingUnit = 1,
    this.updatedAt,
  });

  final String vehicleId;
  final String vehicleName;
  final bool isEnabled;
  final double baseFare;
  final double perKilometerRate;
  final double perMinuteRate;
  final double minimumFare;
  final double bookingFee;
  final double surgeMultiplier;
  final double adminCommissionPercentage;
  final double taxPercentage;
  final double roundingUnit;
  final DateTime? updatedAt;

  RidePricingModel copyWith({
    String? vehicleId,
    String? vehicleName,
    bool? isEnabled,
    double? baseFare,
    double? perKilometerRate,
    double? perMinuteRate,
    double? minimumFare,
    double? bookingFee,
    double? surgeMultiplier,
    double? adminCommissionPercentage,
    double? taxPercentage,
    double? roundingUnit,
    DateTime? updatedAt,
  }) {
    return RidePricingModel(
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleName: vehicleName ?? this.vehicleName,
      isEnabled: isEnabled ?? this.isEnabled,
      baseFare: baseFare ?? this.baseFare,
      perKilometerRate: perKilometerRate ?? this.perKilometerRate,
      perMinuteRate: perMinuteRate ?? this.perMinuteRate,
      minimumFare: minimumFare ?? this.minimumFare,
      bookingFee: bookingFee ?? this.bookingFee,
      surgeMultiplier: surgeMultiplier ?? this.surgeMultiplier,
      adminCommissionPercentage:
          adminCommissionPercentage ?? this.adminCommissionPercentage,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      roundingUnit: roundingUnit ?? this.roundingUnit,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'vehicleId': vehicleId,
      'vehicleName': vehicleName,
      'isEnabled': isEnabled,
      'baseFare': baseFare,
      'perKilometerRate': perKilometerRate,
      'perMinuteRate': perMinuteRate,
      'minimumFare': minimumFare,
      'bookingFee': bookingFee,
      'surgeMultiplier': surgeMultiplier,
      'adminCommissionPercentage': adminCommissionPercentage,
      'taxPercentage': taxPercentage,
      'roundingUnit': roundingUnit,
      'updatedAt':
          updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  factory RidePricingModel.fromMap(Map<String, dynamic> map) {
    return RidePricingModel(
      vehicleId: map['vehicleId']?.toString().trim() ?? '',
      vehicleName: map['vehicleName']?.toString().trim() ?? '',
      isEnabled: map['isEnabled'] as bool? ?? true,
      baseFare: _number(map['baseFare']),
      perKilometerRate: _number(
        map['perKilometerRate'] ?? map['perKm'],
      ),
      perMinuteRate: _number(map['perMinuteRate']),
      minimumFare: _number(map['minimumFare'] ?? map['minFare']),
      bookingFee: _number(map['bookingFee']),
      surgeMultiplier: _positiveNumber(map['surgeMultiplier'], fallback: 1),
      adminCommissionPercentage:
          _percentage(map['adminCommissionPercentage']),
      taxPercentage: _percentage(map['taxPercentage']),
      roundingUnit: _positiveNumber(map['roundingUnit'], fallback: 1),
      updatedAt: _date(map['updatedAt']),
    );
  }

  static double _number(dynamic value) {
    if (value is num) {
      return value.toDouble().clamp(0, double.infinity).toDouble();
    }
    return (double.tryParse(value?.toString() ?? '') ?? 0)
        .clamp(0, double.infinity)
        .toDouble();
  }

  static double _positiveNumber(dynamic value, {required double fallback}) {
    final double parsed = _number(value);
    return parsed > 0 ? parsed : fallback;
  }

  static double _percentage(dynamic value) {
    return _number(value).clamp(0, 100).toDouble();
  }

  static DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

class RideFareEstimate {
  const RideFareEstimate({
    required this.distanceKm,
    required this.estimatedMinutes,
    required this.baseFare,
    required this.distanceFare,
    required this.timeFare,
    required this.bookingFee,
    required this.surgeAmount,
    required this.taxAmount,
    required this.estimatedFare,
    required this.adminCommissionAmount,
    required this.driverEstimatedEarning,
    required this.usedTestingRouteBypass,
    this.routeGeometry = const <RouteCoordinate>[],
  });

  final double distanceKm;
  final int estimatedMinutes;
  final double baseFare;
  final double distanceFare;
  final double timeFare;
  final double bookingFee;
  final double surgeAmount;
  final double taxAmount;
  final double estimatedFare;
  final double adminCommissionAmount;
  final double driverEstimatedEarning;

  /// True means straight-line distance/estimated road factor was used.
  /// False will be used after real Google Directions billing is enabled.
  final bool usedTestingRouteBypass;
  final List<RouteCoordinate> routeGeometry;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'distanceKm': distanceKm,
      'estimatedMinutes': estimatedMinutes,
      'baseFare': baseFare,
      'distanceFare': distanceFare,
      'timeFare': timeFare,
      'bookingFee': bookingFee,
      'surgeAmount': surgeAmount,
      'taxAmount': taxAmount,
      'estimatedFare': estimatedFare,
      'adminCommissionAmount': adminCommissionAmount,
      'driverEstimatedEarning': driverEstimatedEarning,
      'usedTestingRouteBypass': usedTestingRouteBypass,
    };
  }
}
