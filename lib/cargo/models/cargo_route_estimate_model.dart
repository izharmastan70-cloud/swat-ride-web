class CargoRouteEstimateModel {
  const CargoRouteEstimateModel({
    required this.distanceKm,
    required this.estimatedMinutes,
    required this.source,
    required this.isBillableRoute,
    this.pickupLatitude,
    this.pickupLongitude,
    this.dropLatitude,
    this.dropLongitude,
  });

  /// Route distance in KM.
  final double distanceKm;

  /// Estimated route duration in minutes.
  final double estimatedMinutes;

  /// map_api, gps_fallback, manual, unavailable
  final String source;

  /// True only when distance/duration came from an approved
  /// road-routing source that may be used for fare calculation.
  final bool isBillableRoute;

  final double? pickupLatitude;
  final double? pickupLongitude;
  final double? dropLatitude;
  final double? dropLongitude;

  static const String mapApi = 'map_api';
  static const String gpsFallback = 'gps_fallback';
  static const String manual = 'manual';
  static const String unavailableSource = 'unavailable';

  factory CargoRouteEstimateModel.unavailable() {
    return const CargoRouteEstimateModel(
      distanceKm: 0,
      estimatedMinutes: 0,
      source: unavailableSource,
      isBillableRoute: false,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'distanceKm': distanceKm,
      'estimatedMinutes': estimatedMinutes,
      'source': source,
      'isBillableRoute': isBillableRoute,
      'pickupLatitude': pickupLatitude,
      'pickupLongitude': pickupLongitude,
      'dropLatitude': dropLatitude,
      'dropLongitude': dropLongitude,
    };
  }

  factory CargoRouteEstimateModel.fromMap(Map<String, dynamic> map) {
    return CargoRouteEstimateModel(
      distanceKm: _nonNegative(map['distanceKm']),
      estimatedMinutes: _nonNegative(map['estimatedMinutes']),
      source: _text(map['source'], unavailableSource),
      isBillableRoute: map['isBillableRoute'] == true,
      pickupLatitude: _nullableNumber(map['pickupLatitude']),
      pickupLongitude: _nullableNumber(map['pickupLongitude']),
      dropLatitude: _nullableNumber(map['dropLatitude']),
      dropLongitude: _nullableNumber(map['dropLongitude']),
    );
  }

  static String _text(dynamic value, [String fallback = '']) {
    final String result = value?.toString().trim() ?? '';

    return result.isEmpty ? fallback : result;
  }

  static double _nonNegative(dynamic value) {
    final double result = _nullableNumber(value) ?? 0;

    if (!result.isFinite || result < 0) {
      return 0;
    }

    return result;
  }

  static double? _nullableNumber(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }
}
