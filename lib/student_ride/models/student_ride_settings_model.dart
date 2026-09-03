enum StudentRideBillingMode {
  monthly,
  daily,
  routeBased,
}

enum StudentRideCommissionType {
  percentage,
  fixedAmount,
}

class StudentRideSettingsModel {
  final bool moduleEnabled;

  // Service options
  final bool morningServiceEnabled;
  final bool afternoonServiceEnabled;
  final bool oneWayPackageEnabled;
  final bool twoWayPackageEnabled;
  final bool dailyBookingEnabled;
  final bool monthlyPackageEnabled;
  final bool routeBasedPricingEnabled;
  final bool siblingDiscountEnabled;
  final bool doorToDoorEnabled;
  final bool waitlistEnabled;
  final bool absenceReportingEnabled;
  final bool temporaryRouteChangeEnabled;

  // Payments
  final bool cashEnabled;
  final bool walletEnabled;
  final bool easypaisaEnabled;
  final bool jazzCashEnabled;
  final bool cardPaymentEnabled;

  // Pricing
  final StudentRideBillingMode defaultBillingMode;
  final double monthlyBasePrice;
  final double dailyBasePrice;
  final double routeBasePrice;
  final double perKmPrice;
  final double morningOnlyMultiplier;
  final double afternoonOnlyMultiplier;
  final double twoWayMultiplier;
  final double doorToDoorCharge;
  final double registrationFee;
  final double siblingDiscountPercent;

  // Commission
  final StudentRideCommissionType commissionType;
  final double commissionValue;

  // Billing and operational rules
  final int paymentDueDay;
  final int paymentGraceDays;
  final int renewalReminderDays;
  final int absenceCutoffMinutes;
  final int routeChangeCutoffHours;
  final int maximumStudentsPerVehicle;

  // Admin messages and audit
  final String disabledMessage;
  final String currencyCode;
  final DateTime? updatedAt;
  final String updatedBy;

  const StudentRideSettingsModel({
    required this.moduleEnabled,
    required this.morningServiceEnabled,
    required this.afternoonServiceEnabled,
    required this.oneWayPackageEnabled,
    required this.twoWayPackageEnabled,
    required this.dailyBookingEnabled,
    required this.monthlyPackageEnabled,
    required this.routeBasedPricingEnabled,
    required this.siblingDiscountEnabled,
    required this.doorToDoorEnabled,
    required this.waitlistEnabled,
    required this.absenceReportingEnabled,
    required this.temporaryRouteChangeEnabled,
    required this.cashEnabled,
    required this.walletEnabled,
    required this.easypaisaEnabled,
    required this.jazzCashEnabled,
    required this.cardPaymentEnabled,
    required this.defaultBillingMode,
    required this.monthlyBasePrice,
    required this.dailyBasePrice,
    required this.routeBasePrice,
    required this.perKmPrice,
    required this.morningOnlyMultiplier,
    required this.afternoonOnlyMultiplier,
    required this.twoWayMultiplier,
    required this.doorToDoorCharge,
    required this.registrationFee,
    required this.siblingDiscountPercent,
    required this.commissionType,
    required this.commissionValue,
    required this.paymentDueDay,
    required this.paymentGraceDays,
    required this.renewalReminderDays,
    required this.absenceCutoffMinutes,
    required this.routeChangeCutoffHours,
    required this.maximumStudentsPerVehicle,
    required this.disabledMessage,
    required this.currencyCode,
    required this.updatedAt,
    required this.updatedBy,
  });

  factory StudentRideSettingsModel.defaults() {
    return const StudentRideSettingsModel(
      moduleEnabled: true,
      morningServiceEnabled: true,
      afternoonServiceEnabled: true,
      oneWayPackageEnabled: true,
      twoWayPackageEnabled: true,
      dailyBookingEnabled: false,
      monthlyPackageEnabled: true,
      routeBasedPricingEnabled: true,
      siblingDiscountEnabled: false,
      doorToDoorEnabled: true,
      waitlistEnabled: true,
      absenceReportingEnabled: true,
      temporaryRouteChangeEnabled: false,
      cashEnabled: true,
      walletEnabled: false,
      easypaisaEnabled: false,
      jazzCashEnabled: false,
      cardPaymentEnabled: false,
      defaultBillingMode: StudentRideBillingMode.monthly,
      monthlyBasePrice: 0,
      dailyBasePrice: 0,
      routeBasePrice: 0,
      perKmPrice: 0,
      morningOnlyMultiplier: 1,
      afternoonOnlyMultiplier: 1,
      twoWayMultiplier: 1,
      doorToDoorCharge: 0,
      registrationFee: 0,
      siblingDiscountPercent: 0,
      commissionType: StudentRideCommissionType.percentage,
      commissionValue: 0,
      paymentDueDay: 5,
      paymentGraceDays: 3,
      renewalReminderDays: 7,
      absenceCutoffMinutes: 60,
      routeChangeCutoffHours: 24,
      maximumStudentsPerVehicle: 1,
      disabledMessage: 'Student Ride is temporarily unavailable.',
      currencyCode: 'PKR',
      updatedAt: null,
      updatedBy: '',
    );
  }

  bool get hasEnabledPaymentMethod {
    return cashEnabled ||
        walletEnabled ||
        easypaisaEnabled ||
        jazzCashEnabled ||
        cardPaymentEnabled;
  }

  factory StudentRideSettingsModel.fromMap(Map<String, dynamic> map) {
    final defaults = StudentRideSettingsModel.defaults();

    return StudentRideSettingsModel(
      moduleEnabled:
          _readBool(map['moduleEnabled'], defaults.moduleEnabled),
      morningServiceEnabled: _readBool(
        map['morningServiceEnabled'],
        defaults.morningServiceEnabled,
      ),
      afternoonServiceEnabled: _readBool(
        map['afternoonServiceEnabled'],
        defaults.afternoonServiceEnabled,
      ),
      oneWayPackageEnabled: _readBool(
        map['oneWayPackageEnabled'],
        defaults.oneWayPackageEnabled,
      ),
      twoWayPackageEnabled: _readBool(
        map['twoWayPackageEnabled'],
        defaults.twoWayPackageEnabled,
      ),
      dailyBookingEnabled: _readBool(
        map['dailyBookingEnabled'],
        defaults.dailyBookingEnabled,
      ),
      monthlyPackageEnabled: _readBool(
        map['monthlyPackageEnabled'],
        defaults.monthlyPackageEnabled,
      ),
      routeBasedPricingEnabled: _readBool(
        map['routeBasedPricingEnabled'],
        defaults.routeBasedPricingEnabled,
      ),
      siblingDiscountEnabled: _readBool(
        map['siblingDiscountEnabled'],
        defaults.siblingDiscountEnabled,
      ),
      doorToDoorEnabled:
          _readBool(map['doorToDoorEnabled'], defaults.doorToDoorEnabled),
      waitlistEnabled:
          _readBool(map['waitlistEnabled'], defaults.waitlistEnabled),
      absenceReportingEnabled: _readBool(
        map['absenceReportingEnabled'],
        defaults.absenceReportingEnabled,
      ),
      temporaryRouteChangeEnabled: _readBool(
        map['temporaryRouteChangeEnabled'],
        defaults.temporaryRouteChangeEnabled,
      ),
      cashEnabled: _readBool(map['cashEnabled'], defaults.cashEnabled),
      walletEnabled: _readBool(map['walletEnabled'], defaults.walletEnabled),
      easypaisaEnabled:
          _readBool(map['easypaisaEnabled'], defaults.easypaisaEnabled),
      jazzCashEnabled:
          _readBool(map['jazzCashEnabled'], defaults.jazzCashEnabled),
      cardPaymentEnabled: _readBool(
        map['cardPaymentEnabled'],
        defaults.cardPaymentEnabled,
      ),
      defaultBillingMode: _billingModeFromString(
        map['defaultBillingMode']?.toString(),
      ),
      monthlyBasePrice: _readDouble(
        map['monthlyBasePrice'],
        defaults.monthlyBasePrice,
      ),
      dailyBasePrice:
          _readDouble(map['dailyBasePrice'], defaults.dailyBasePrice),
      routeBasePrice:
          _readDouble(map['routeBasePrice'], defaults.routeBasePrice),
      perKmPrice: _readDouble(map['perKmPrice'], defaults.perKmPrice),
      morningOnlyMultiplier: _readDouble(
        map['morningOnlyMultiplier'],
        defaults.morningOnlyMultiplier,
      ),
      afternoonOnlyMultiplier: _readDouble(
        map['afternoonOnlyMultiplier'],
        defaults.afternoonOnlyMultiplier,
      ),
      twoWayMultiplier: _readDouble(
        map['twoWayMultiplier'],
        defaults.twoWayMultiplier,
      ),
      doorToDoorCharge: _readDouble(
        map['doorToDoorCharge'],
        defaults.doorToDoorCharge,
      ),
      registrationFee: _readDouble(
        map['registrationFee'],
        defaults.registrationFee,
      ),
      siblingDiscountPercent: _readDouble(
        map['siblingDiscountPercent'],
        defaults.siblingDiscountPercent,
      ),
      commissionType: _commissionTypeFromString(
        map['commissionType']?.toString(),
      ),
      commissionValue: _readDouble(
        map['commissionValue'],
        defaults.commissionValue,
      ),
      paymentDueDay:
          _readInt(map['paymentDueDay'], defaults.paymentDueDay),
      paymentGraceDays:
          _readInt(map['paymentGraceDays'], defaults.paymentGraceDays),
      renewalReminderDays: _readInt(
        map['renewalReminderDays'],
        defaults.renewalReminderDays,
      ),
      absenceCutoffMinutes: _readInt(
        map['absenceCutoffMinutes'],
        defaults.absenceCutoffMinutes,
      ),
      routeChangeCutoffHours: _readInt(
        map['routeChangeCutoffHours'],
        defaults.routeChangeCutoffHours,
      ),
      maximumStudentsPerVehicle: _readInt(
        map['maximumStudentsPerVehicle'],
        defaults.maximumStudentsPerVehicle,
      ),
      disabledMessage:
          map['disabledMessage']?.toString() ?? defaults.disabledMessage,
      currencyCode:
          map['currencyCode']?.toString() ?? defaults.currencyCode,
      updatedAt: _readDateTime(map['updatedAt']),
      updatedBy: map['updatedBy']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'moduleEnabled': moduleEnabled,
      'morningServiceEnabled': morningServiceEnabled,
      'afternoonServiceEnabled': afternoonServiceEnabled,
      'oneWayPackageEnabled': oneWayPackageEnabled,
      'twoWayPackageEnabled': twoWayPackageEnabled,
      'dailyBookingEnabled': dailyBookingEnabled,
      'monthlyPackageEnabled': monthlyPackageEnabled,
      'routeBasedPricingEnabled': routeBasedPricingEnabled,
      'siblingDiscountEnabled': siblingDiscountEnabled,
      'doorToDoorEnabled': doorToDoorEnabled,
      'waitlistEnabled': waitlistEnabled,
      'absenceReportingEnabled': absenceReportingEnabled,
      'temporaryRouteChangeEnabled': temporaryRouteChangeEnabled,
      'cashEnabled': cashEnabled,
      'walletEnabled': walletEnabled,
      'easypaisaEnabled': easypaisaEnabled,
      'jazzCashEnabled': jazzCashEnabled,
      'cardPaymentEnabled': cardPaymentEnabled,
      'defaultBillingMode': defaultBillingMode.name,
      'monthlyBasePrice': monthlyBasePrice,
      'dailyBasePrice': dailyBasePrice,
      'routeBasePrice': routeBasePrice,
      'perKmPrice': perKmPrice,
      'morningOnlyMultiplier': morningOnlyMultiplier,
      'afternoonOnlyMultiplier': afternoonOnlyMultiplier,
      'twoWayMultiplier': twoWayMultiplier,
      'doorToDoorCharge': doorToDoorCharge,
      'registrationFee': registrationFee,
      'siblingDiscountPercent': siblingDiscountPercent,
      'commissionType': commissionType.name,
      'commissionValue': commissionValue,
      'paymentDueDay': paymentDueDay,
      'paymentGraceDays': paymentGraceDays,
      'renewalReminderDays': renewalReminderDays,
      'absenceCutoffMinutes': absenceCutoffMinutes,
      'routeChangeCutoffHours': routeChangeCutoffHours,
      'maximumStudentsPerVehicle': maximumStudentsPerVehicle,
      'disabledMessage': disabledMessage,
      'currencyCode': currencyCode,
      'updatedAt': updatedAt?.toIso8601String(),
      'updatedBy': updatedBy,
    };
  }

  static StudentRideBillingMode _billingModeFromString(String? value) {
    return StudentRideBillingMode.values.firstWhere(
      (item) => item.name == value,
      orElse: () => StudentRideBillingMode.monthly,
    );
  }

  static StudentRideCommissionType _commissionTypeFromString(String? value) {
    return StudentRideCommissionType.values.firstWhere(
      (item) => item.name == value,
      orElse: () => StudentRideCommissionType.percentage,
    );
  }

  static bool _readBool(dynamic value, bool fallback) {
    return value is bool ? value : fallback;
  }

  static double _readDouble(dynamic value, double fallback) {
    return value is num ? value.toDouble() : fallback;
  }

  static int _readInt(dynamic value, int fallback) {
    return value is num ? value.toInt() : fallback;
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;

    try {
      final dynamic converted = value.toDate();
      if (converted is DateTime) return converted;
    } catch (_) {
      // Supports Firestore Timestamp without importing cloud_firestore.
    }

    return DateTime.tryParse(value.toString());
  }
}

