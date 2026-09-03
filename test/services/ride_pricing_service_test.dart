import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/models/ride_pricing_model.dart';
import 'package:swat_ride/services/ride_pricing_service.dart';

const RidePricingModel _pricing = RidePricingModel(
  vehicleId: 'rickshaw',
  vehicleName: 'Rickshaw',
  isEnabled: true,
  baseFare: 120,
  perKilometerRate: 35,
  perMinuteRate: 15,
  minimumFare: 160,
  bookingFee: 20,
  roundingUnit: 1,
);

void main() {
  test('calculates PKR base, distance and per-minute charges', () {
    final RideFareEstimate fare = RidePricingService.calculateFare(
      distanceKm: 4.25,
      estimatedMinutes: 13,
      pricing: _pricing,
      usedFallback: false,
    );

    expect(fare.distanceFare, 148.75);
    expect(fare.timeFare, 195);
    expect(fare.estimatedFare, 484);
    expect(fare.usedTestingRouteBypass, isFalse);
  });

  test('applies the configured minimum fare to short trips', () {
    final RideFareEstimate fare = RidePricingService.calculateFare(
      distanceKm: 0.1,
      estimatedMinutes: 1,
      pricing: _pricing,
      usedFallback: true,
    );

    expect(fare.estimatedFare, 160);
    expect(fare.usedTestingRouteBypass, isTrue);
  });
}