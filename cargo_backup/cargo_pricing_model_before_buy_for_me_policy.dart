class CargoPricingModel {
  const CargoPricingModel({
    required this.baseFare,
    required this.perKmRate,
    required this.perMinuteRate,
    required this.weightChargePerKg,
    required this.loadingCharge,
    required this.unloadingCharge,
    required this.adminCommissionPercentage,
    required this.surgeMultiplier,
    required this.surgeEnabled,
    required this.cashEnabled,
    required this.walletEnabled,
    required this.jazzCashEnabled,
    required this.easypaisaEnabled,
  });

  final double baseFare;
  final double perKmRate;
  final double perMinuteRate;

  final double weightChargePerKg;
  final double loadingCharge;
  final double unloadingCharge;

  final double adminCommissionPercentage;

  final double surgeMultiplier;
  final bool surgeEnabled;

  final bool cashEnabled;
  final bool walletEnabled;
  final bool jazzCashEnabled;
  final bool easypaisaEnabled;

  factory CargoPricingModel.defaults() {
    return const CargoPricingModel(
      baseFare: 0,
      perKmRate: 0,
      perMinuteRate: 0,
      weightChargePerKg: 0,
      loadingCharge: 0,
      unloadingCharge: 0,
      adminCommissionPercentage: 0,
      surgeMultiplier: 1,
      surgeEnabled: false,
      cashEnabled: true,
      walletEnabled: true,
      jazzCashEnabled: false,
      easypaisaEnabled: false,
    );
  }

  factory CargoPricingModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return CargoPricingModel(
      baseFare: _number(map['baseFare']),
      perKmRate: _number(map['perKmRate']),
      perMinuteRate: _number(map['perMinuteRate']),
      weightChargePerKg:
          _number(map['weightChargePerKg']),
      loadingCharge:
          _number(map['loadingCharge']),
      unloadingCharge:
          _number(map['unloadingCharge']),
      adminCommissionPercentage:
          _number(map['adminCommissionPercentage']),
      surgeMultiplier:
          _number(map['surgeMultiplier'], fallback: 1),
      surgeEnabled:
          map['surgeEnabled'] == true,
      cashEnabled:
          map['cashEnabled'] != false,
      walletEnabled:
          map['walletEnabled'] != false,
      jazzCashEnabled:
          map['jazzCashEnabled'] == true,
      easypaisaEnabled:
          map['easypaisaEnabled'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'baseFare': baseFare,
      'perKmRate': perKmRate,
      'perMinuteRate': perMinuteRate,
      'weightChargePerKg': weightChargePerKg,
      'loadingCharge': loadingCharge,
      'unloadingCharge': unloadingCharge,
      'adminCommissionPercentage':
          adminCommissionPercentage,
      'surgeMultiplier': surgeMultiplier,
      'surgeEnabled': surgeEnabled,
      'cashEnabled': cashEnabled,
      'walletEnabled': walletEnabled,
      'jazzCashEnabled': jazzCashEnabled,
      'easypaisaEnabled': easypaisaEnabled,
    };
  }

  static double _number(
    dynamic value, {
    double fallback = 0,
  }) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? fallback;
    }

    return fallback;
  }
}

class CargoFareBreakdown {
  const CargoFareBreakdown({
    required this.baseFare,
    required this.distanceFare,
    required this.timeFare,
    required this.weightCharge,
    required this.loadingCharge,
    required this.unloadingCharge,
    required this.subtotal,
    required this.surgeAmount,
    required this.totalFare,
    required this.commissionPercentage,
    required this.commissionAmount,
    required this.driverNetEarning,
  });

  final double baseFare;
  final double distanceFare;
  final double timeFare;
  final double weightCharge;
  final double loadingCharge;
  final double unloadingCharge;

  final double subtotal;
  final double surgeAmount;
  final double totalFare;

  final double commissionPercentage;
  final double commissionAmount;

  final double driverNetEarning;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'baseFare': baseFare,
      'distanceFare': distanceFare,
      'timeFare': timeFare,
      'weightCharge': weightCharge,
      'loadingCharge': loadingCharge,
      'unloadingCharge': unloadingCharge,
      'subtotal': subtotal,
      'surgeAmount': surgeAmount,
      'totalFare': totalFare,
      'commissionPercentage':
          commissionPercentage,
      'commissionAmount': commissionAmount,
      'driverNetEarning': driverNetEarning,
    };
  }
}
