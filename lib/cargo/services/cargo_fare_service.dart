import '../models/cargo_pricing_model.dart';
import '../models/cargo_route_estimate_model.dart';
import 'cargo_booking_service.dart';
import 'cargo_pricing_service.dart';
import 'cargo_route_service.dart';

class CargoFareService {
  CargoFareService({
    CargoRouteService? routeService,
    CargoPricingService? pricingService,
    CargoBookingService? bookingService,
  }) : _routeService = routeService ?? const CargoRouteService(),
       _pricingService = pricingService ?? const CargoPricingService(),
       _bookingService = bookingService ?? CargoBookingService();

  final CargoRouteService _routeService;
  final CargoPricingService _pricingService;
  final CargoBookingService _bookingService;

  CargoFareBreakdown calculateBillableFare({
    required CargoRouteEstimateModel route,
    required CargoPricingModel pricing,
    double weightKg = 0,
    bool includeLoading = false,
    bool includeUnloading = false,
  }) {
    _routeService.validateForFare(route);

    return _pricingService.calculateFare(
      pricing: pricing,
      distanceKm: route.distanceKm,
      estimatedMinutes: route.estimatedMinutes,
      weightKg: weightKg,
      includeLoading: includeLoading,
      includeUnloading: includeUnloading,
    );
  }

  Future<CargoFareBreakdown> calculateAndSaveFare({
    required String bookingId,
    required CargoRouteEstimateModel route,
    required CargoPricingModel pricing,
    double weightKg = 0,
    bool includeLoading = false,
    bool includeUnloading = false,
  }) async {
    final CargoFareBreakdown fare = calculateBillableFare(
      route: route,
      pricing: pricing,
      weightKg: weightKg,
      includeLoading: includeLoading,
      includeUnloading: includeUnloading,
    );

    await _bookingService.updateFareSnapshot(
      bookingId: bookingId,
      distanceKm: route.distanceKm,
      estimatedMinutes: route.estimatedMinutes,
      baseFare: fare.baseFare,
      distanceFare: fare.distanceFare,
      timeFare: fare.timeFare,
      weightCharge: fare.weightCharge,
      loadingCharge: fare.loadingCharge,
      unloadingCharge: fare.unloadingCharge,
      surgeAmount: fare.surgeAmount,
      totalFare: fare.totalFare,
      adminCommissionPercentage: fare.commissionPercentage,
      commissionAmount: fare.commissionAmount,
      driverNetEarning: fare.driverNetEarning,
    );

    return fare;
  }
}
