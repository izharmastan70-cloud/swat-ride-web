import '../models/cargo_pricing_model.dart';

class CargoPricingService {
  const CargoPricingService();

  CargoFareBreakdown calculateFare({
    required CargoPricingModel pricing,
    required double distanceKm,
    required double estimatedMinutes,
    double weightKg = 0,
    bool includeLoading = false,
    bool includeUnloading = false,
  }) {
    final double safeDistance = _nonNegative(distanceKm);
    final double safeMinutes = _nonNegative(estimatedMinutes);
    final double safeWeight = _nonNegative(weightKg);

    final double baseFare = _nonNegative(pricing.baseFare);

    final double distanceFare = safeDistance * _nonNegative(pricing.perKmRate);

    final double timeFare = safeMinutes * _nonNegative(pricing.perMinuteRate);

    final double weightCharge =
        safeWeight * _nonNegative(pricing.weightChargePerKg);

    final double loadingCharge = includeLoading
        ? _nonNegative(pricing.loadingCharge)
        : 0;

    final double unloadingCharge = includeUnloading
        ? _nonNegative(pricing.unloadingCharge)
        : 0;

    final double subtotal =
        baseFare +
        distanceFare +
        timeFare +
        weightCharge +
        loadingCharge +
        unloadingCharge;

    final double multiplier = pricing.surgeEnabled
        ? _validSurge(pricing.surgeMultiplier)
        : 1;

    final double surgedTotal = subtotal * multiplier;

    final double surgeAmount = surgedTotal - subtotal;

    final double totalFare = _roundMoney(surgedTotal);

    final double commissionPercentage = _validCommission(
      pricing.adminCommissionPercentage,
    );

    final double commissionAmount = _roundMoney(
      totalFare * (commissionPercentage / 100),
    );

    final double driverNetEarning = _roundMoney(totalFare - commissionAmount);

    return CargoFareBreakdown(
      baseFare: _roundMoney(baseFare),
      distanceFare: _roundMoney(distanceFare),
      timeFare: _roundMoney(timeFare),
      weightCharge: _roundMoney(weightCharge),
      loadingCharge: _roundMoney(loadingCharge),
      unloadingCharge: _roundMoney(unloadingCharge),
      subtotal: _roundMoney(subtotal),
      surgeAmount: _roundMoney(surgeAmount),
      totalFare: totalFare,
      commissionPercentage: commissionPercentage,
      commissionAmount: commissionAmount,
      driverNetEarning: driverNetEarning,
    );
  }

  double calculateRequiredAdvance({
    required double expectedItemAmount,
    required double deliveryFare,
    required double advancePercentage,
    bool includeDeliveryFareInAdvance = false,
  }) {
    final double itemAmount = _nonNegative(expectedItemAmount);

    final double fare = _nonNegative(deliveryFare);

    final double percentage = _validAdvancePercentage(advancePercentage);

    final double advanceBase = includeDeliveryFareInAdvance
        ? itemAmount + fare
        : itemAmount;

    return _roundMoney(advanceBase * (percentage / 100));
  }

  double calculateOutstandingCashCommission({
    required double previousOutstanding,
    required double commissionAmount,
  }) {
    return _roundMoney(
      _nonNegative(previousOutstanding) + _nonNegative(commissionAmount),
    );
  }

  static double _nonNegative(double value) {
    if (!value.isFinite || value < 0) {
      return 0;
    }

    return value;
  }

  static double _validCommission(double value) {
    if (!value.isFinite) {
      return 0;
    }

    return value.clamp(0, 100).toDouble();
  }

  static double _validAdvancePercentage(double value) {
    if (!value.isFinite) {
      return 0;
    }

    return value.clamp(0, 100).toDouble();
  }

  static double _validSurge(double value) {
    if (!value.isFinite || value < 1) {
      return 1;
    }

    return value;
  }

  static double _roundMoney(double value) {
    return (value * 100).roundToDouble() / 100;
  }
}
