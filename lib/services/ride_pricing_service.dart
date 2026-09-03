import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/location_model.dart';
import '../models/osrm_route_model.dart';
import '../models/ride_pricing_model.dart';
import '../models/vehicle_model.dart';
import 'osrm_routing_service.dart';

class RidePricingService {
  RidePricingService({
    FirebaseFirestore? firestore,
    OsrmRoutingService? routingService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _routingService = routingService ?? OsrmRoutingService();

  final FirebaseFirestore _firestore;
  final OsrmRoutingService _routingService;

  static const double defaultPerMinuteRate = 15;

  /// Straight-line distance is multiplied to approximate normal road curves.
  static const double testingRoadDistanceMultiplier = 1.25;
  static const double testingAverageSpeedKmPerHour = 25;

  CollectionReference<Map<String, dynamic>> get _pricingCollection =>
      _firestore.collection('normal_ride_pricing');

  Future<RidePricingModel> getVehiclePricing(VehicleModel vehicle) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> document =
          await _pricingCollection.doc(vehicle.id).get();

      if (document.exists && document.data() != null) {
        final RidePricingModel pricing = RidePricingModel.fromMap(
          <String, dynamic>{
            ...document.data()!,
            'vehicleId': document.data()!['vehicleId'] ?? document.id,
            'vehicleName': document.data()!['vehicleName'] ?? vehicle.name,
          },
        );
        return _withSafeVehicleFallbacks(pricing, vehicle);
      }
    } on FirebaseException {
      // Offline, missing permission or missing Admin configuration falls back
      // to the bundled vehicle rates so the booking page does not crash.
    }

    return defaultPricing(vehicle);
  }

  Stream<RidePricingModel> watchVehiclePricing(VehicleModel vehicle) {
    return _pricingCollection.doc(vehicle.id).snapshots().map(
      (DocumentSnapshot<Map<String, dynamic>> document) {
        if (!document.exists || document.data() == null) {
          return defaultPricing(vehicle);
        }
        return _withSafeVehicleFallbacks(
          RidePricingModel.fromMap(<String, dynamic>{
            ...document.data()!,
            'vehicleId': document.data()!['vehicleId'] ?? document.id,
            'vehicleName': document.data()!['vehicleName'] ?? vehicle.name,
          }),
          vehicle,
        );
      },
    );
  }

  RidePricingModel defaultPricing(VehicleModel vehicle) {
    final double safeBaseFare = math.max(0, vehicle.baseFare).toDouble();
    final double safePerKm = math.max(0, vehicle.perKm).toDouble();

    return RidePricingModel(
      vehicleId: vehicle.id,
      vehicleName: vehicle.name,
      isEnabled: vehicle.id != 'other_vehicle',
      baseFare: safeBaseFare,
      perKilometerRate: safePerKm,
      perMinuteRate: defaultPerMinuteRate,
      minimumFare: safeBaseFare,
      bookingFee: 0,
      surgeMultiplier: 1,
      adminCommissionPercentage: 0,
      taxPercentage: 0,
      roundingUnit: 1,
    );
  }

  Future<RideFareEstimate> estimateFare({
    required LocationModel pickup,
    required LocationModel destination,
    required VehicleModel vehicle,
  }) async {
    final RidePricingModel pricing = await getVehiclePricing(vehicle);
    if (!pricing.isEnabled) {
      throw Exception('${pricing.vehicleName} is currently disabled by Admin.');
    }

    late _RouteMetrics route;
    try {
      final OsrmRoute osrmRoute = await _routingService.getDrivingRoute(
        pickup: pickup,
        destination: destination,
      );
      route = _RouteMetrics(
        distanceKm: osrmRoute.distanceKm,
        estimatedMinutes: osrmRoute.estimatedMinutes,
        geometry: osrmRoute.geometry,
        usedFallback: false,
      );
    } on OsrmRoutingException {
      route = _getTestingRoute(pickup, destination);
    }

    return calculateFare(
      distanceKm: route.distanceKm,
      estimatedMinutes: route.estimatedMinutes,
      pricing: pricing,
      usedFallback: route.usedFallback,
      routeGeometry: route.geometry,
    );
  }

  static RideFareEstimate calculateFare({
    required double distanceKm,
    required int estimatedMinutes,
    required RidePricingModel pricing,
    required bool usedFallback,
    List<RouteCoordinate> routeGeometry = const <RouteCoordinate>[],
  }) {
    final double safeDistanceKm = math.max(0, distanceKm).toDouble();
    final int safeEstimatedMinutes = math.max(0, estimatedMinutes);
    final double distanceFare = safeDistanceKm * pricing.perKilometerRate;
    final double timeFare = safeEstimatedMinutes * pricing.perMinuteRate;
    final double beforeSurge =
        pricing.baseFare + distanceFare + timeFare + pricing.bookingFee;
    final double afterSurge = beforeSurge * pricing.surgeMultiplier;
    final double surgeAmount = math.max(0, afterSurge - beforeSurge).toDouble();
    final double taxAmount = afterSurge * (pricing.taxPercentage / 100);
    final double beforeMinimum = afterSurge + taxAmount;
    final double minimumApplied =
        math.max(pricing.minimumFare, beforeMinimum).toDouble();
    final double estimatedFare = _roundUp(
      minimumApplied,
      pricing.roundingUnit,
    );
    final double commission = estimatedFare *
        (pricing.adminCommissionPercentage.clamp(0, 100).toDouble() / 100);

    return RideFareEstimate(
      distanceKm: _round(safeDistanceKm, 2),
      estimatedMinutes: safeEstimatedMinutes,
      baseFare: pricing.baseFare,
      distanceFare: _round(distanceFare, 2),
      timeFare: _round(timeFare, 2),
      bookingFee: pricing.bookingFee,
      surgeAmount: _round(surgeAmount, 2),
      taxAmount: _round(taxAmount, 2),
      estimatedFare: estimatedFare,
      adminCommissionAmount: _round(commission, 2),
      driverEstimatedEarning: _round(estimatedFare - commission, 2),
      usedTestingRouteBypass: usedFallback,
      routeGeometry: routeGeometry,
    );
  }

  /// Admin-only. Firestore Security Rules must enforce the Admin role.
  Future<void> setVehiclePricing(RidePricingModel pricing) async {
    if (pricing.vehicleId.trim().isEmpty) {
      throw Exception('Vehicle ID is required.');
    }

    await _pricingCollection.doc(pricing.vehicleId.trim()).set(
      <String, dynamic>{
        ...pricing.toMap(),
        'vehicleId': pricing.vehicleId.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  RidePricingModel _withSafeVehicleFallbacks(
    RidePricingModel pricing,
    VehicleModel vehicle,
  ) {
    return pricing.copyWith(
      vehicleId: pricing.vehicleId.isEmpty ? vehicle.id : pricing.vehicleId,
      vehicleName:
          pricing.vehicleName.isEmpty ? vehicle.name : pricing.vehicleName,
      baseFare: pricing.baseFare > 0 ? pricing.baseFare : vehicle.baseFare,
      perKilometerRate: pricing.perKilometerRate > 0
          ? pricing.perKilometerRate
          : vehicle.perKm,
        perMinuteRate: pricing.perMinuteRate > 0
          ? pricing.perMinuteRate
          : defaultPerMinuteRate,
      minimumFare: pricing.minimumFare > 0
          ? pricing.minimumFare
          : vehicle.baseFare,
    );
  }

  _RouteMetrics _getTestingRoute(
    LocationModel pickup,
    LocationModel destination,
  ) {
    final double straightLineKm = _haversineDistanceKm(
      pickup.latitude,
      pickup.longitude,
      destination.latitude,
      destination.longitude,
    );
    final double roadDistanceKm = math.max(
      0.5,
      straightLineKm * testingRoadDistanceMultiplier,
    ).toDouble();
    final int minutes = math.max(
      2,
      ((roadDistanceKm / testingAverageSpeedKmPerHour) * 60).ceil(),
    );

    return _RouteMetrics(
      distanceKm: roadDistanceKm,
      estimatedMinutes: minutes,
    );
  }

  double _haversineDistanceKm(
    double latitude1,
    double longitude1,
    double latitude2,
    double longitude2,
  ) {
    const double earthRadiusKm = 6371;
    final double lat1 = _degreesToRadians(latitude1);
    final double lat2 = _degreesToRadians(latitude2);
    final double deltaLat = _degreesToRadians(latitude2 - latitude1);
    final double deltaLng = _degreesToRadians(longitude2 - longitude1);
    final double a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLng / 2) *
            math.sin(deltaLng / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) => degrees * math.pi / 180;

  static double _roundUp(double value, double unit) {
    if (unit <= 0) return value;
    return (value / unit).ceil() * unit;
  }

  static double _round(double value, int decimals) {
    final num factor = math.pow(10, decimals);
    return (value * factor).round() / factor;
  }
}

class _RouteMetrics {
  const _RouteMetrics({
    required this.distanceKm,
    required this.estimatedMinutes,
    this.geometry = const <RouteCoordinate>[],
    this.usedFallback = true,
  });

  final double distanceKm;
  final int estimatedMinutes;
  final List<RouteCoordinate> geometry;
  final bool usedFallback;
}
