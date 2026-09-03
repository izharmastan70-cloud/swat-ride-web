import '../models/cargo_route_estimate_model.dart';

class CargoRouteService {
  const CargoRouteService();

  CargoRouteEstimateModel createMapRoute({
    required double distanceKm,
    required double estimatedMinutes,
    double? pickupLatitude,
    double? pickupLongitude,
    double? dropLatitude,
    double? dropLongitude,
  }) {
    final double safeDistance = _nonNegative(distanceKm);

    final double safeMinutes = _nonNegative(estimatedMinutes);

    if (safeDistance <= 0) {
      return CargoRouteEstimateModel.unavailable();
    }

    return CargoRouteEstimateModel(
      distanceKm: safeDistance,
      estimatedMinutes: safeMinutes,
      source: CargoRouteEstimateModel.mapApi,
      isBillableRoute: true,
      pickupLatitude: _validLatitude(pickupLatitude),
      pickupLongitude: _validLongitude(pickupLongitude),
      dropLatitude: _validLatitude(dropLatitude),
      dropLongitude: _validLongitude(dropLongitude),
    );
  }

  CargoRouteEstimateModel createGpsFallback({
    required double distanceKm,
    double estimatedMinutes = 0,
    double? pickupLatitude,
    double? pickupLongitude,
    double? dropLatitude,
    double? dropLongitude,
  }) {
    return CargoRouteEstimateModel(
      distanceKm: _nonNegative(distanceKm),
      estimatedMinutes: _nonNegative(estimatedMinutes),
      source: CargoRouteEstimateModel.gpsFallback,
      isBillableRoute: false,
      pickupLatitude: _validLatitude(pickupLatitude),
      pickupLongitude: _validLongitude(pickupLongitude),
      dropLatitude: _validLatitude(dropLatitude),
      dropLongitude: _validLongitude(dropLongitude),
    );
  }

  CargoRouteEstimateModel createManualEstimate({
    required double distanceKm,
    required double estimatedMinutes,
  }) {
    return CargoRouteEstimateModel(
      distanceKm: _nonNegative(distanceKm),
      estimatedMinutes: _nonNegative(estimatedMinutes),
      source: CargoRouteEstimateModel.manual,
      isBillableRoute: false,
    );
  }

  bool canCalculateBillableFare(CargoRouteEstimateModel route) {
    if (!route.isBillableRoute) {
      return false;
    }

    if (route.source != CargoRouteEstimateModel.mapApi) {
      return false;
    }

    if (route.distanceKm <= 0) {
      return false;
    }

    return true;
  }

  void validateForFare(CargoRouteEstimateModel route) {
    if (!canCalculateBillableFare(route)) {
      throw StateError('Cargo fare requires an approved billable road route.');
    }
  }

  static double _nonNegative(double value) {
    if (!value.isFinite || value < 0) {
      return 0;
    }

    return value;
  }

  static double? _validLatitude(double? value) {
    if (value == null || !value.isFinite || value < -90 || value > 90) {
      return null;
    }

    return value;
  }

  static double? _validLongitude(double? value) {
    if (value == null || !value.isFinite || value < -180 || value > 180) {
      return null;
    }

    return value;
  }
}
