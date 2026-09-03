enum StudentRidePackageTripType {
  morningOnly,
  afternoonOnly,
  twoWay,
}

enum StudentRidePackagePriceMode {
  fixedMonthly,
  daily,
  routeBased,
  distanceBased,
}

class StudentRidePackageModel {
  final String packageId;
  final String name;
  final String description;
  final bool isEnabled;

  // Service
  final StudentRidePackageTripType tripType;
  final StudentRidePackagePriceMode priceMode;
  final bool doorToDoor;
  final bool sharedVehicle;
  final bool siblingDiscountAllowed;

  // Availability
  final List<String> schoolIds;
  final List<String> routeIds;
  final List<String> vehicleTypes;
  final List<int> operatingWeekdays;

  // Pricing
  final double basePrice;
  final double perKmPrice;
  final double perDayPrice;
  final double doorToDoorCharge;
  final double registrationFee;
  final double siblingDiscountPercent;
  final double maximumDiscountAmount;
  final String currencyCode;

  // Package rules
  final int minimumDays;
  final int maximumStudents;
  final int paymentDueDay;
  final int paymentGraceDays;
  final bool autoRenewAllowed;
  final bool pauseAllowed;
  final bool cancellationAllowed;

  // Admin
  final int displayOrder;
  final String disabledMessage;
  final String createdBy;
  final String updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StudentRidePackageModel({
    required this.packageId,
    required this.name,
    required this.description,
    required this.isEnabled,
    required this.tripType,
    required this.priceMode,
    required this.doorToDoor,
    required this.sharedVehicle,
    required this.siblingDiscountAllowed,
    required this.schoolIds,
    required this.routeIds,
    required this.vehicleTypes,
    required this.operatingWeekdays,
    required this.basePrice,
    required this.perKmPrice,
    required this.perDayPrice,
    required this.doorToDoorCharge,
    required this.registrationFee,
    required this.siblingDiscountPercent,
    required this.maximumDiscountAmount,
    required this.currencyCode,
    required this.minimumDays,
    required this.maximumStudents,
    required this.paymentDueDay,
    required this.paymentGraceDays,
    required this.autoRenewAllowed,
    required this.pauseAllowed,
    required this.cancellationAllowed,
    required this.displayOrder,
    required this.disabledMessage,
    required this.createdBy,
    required this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  bool supportsSchool(String schoolId) {
    return schoolIds.isEmpty || schoolIds.contains(schoolId);
  }

  bool supportsRoute(String routeId) {
    return routeIds.isEmpty || routeIds.contains(routeId);
  }

  bool supportsVehicle(String vehicleType) {
    return vehicleTypes.isEmpty ||
        vehicleTypes.contains(vehicleType);
  }

  factory StudentRidePackageModel.fromMap(
    Map<String, dynamic> map, {
    String documentId = '',
  }) {
    return StudentRidePackageModel(
      packageId: documentId.isNotEmpty
          ? documentId
          : map['packageId']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      isEnabled: map['isEnabled'] != false,
      tripType: _tripTypeFromString(
        map['tripType']?.toString(),
      ),
      priceMode: _priceModeFromString(
        map['priceMode']?.toString(),
      ),
      doorToDoor: map['doorToDoor'] == true,
      sharedVehicle: map['sharedVehicle'] != false,
      siblingDiscountAllowed:
          map['siblingDiscountAllowed'] == true,
      schoolIds: _readStringList(map['schoolIds']),
      routeIds: _readStringList(map['routeIds']),
      vehicleTypes: _readStringList(map['vehicleTypes']),
      operatingWeekdays:
          _readIntList(map['operatingWeekdays']),
      basePrice: _readDouble(map['basePrice']),
      perKmPrice: _readDouble(map['perKmPrice']),
      perDayPrice: _readDouble(map['perDayPrice']),
      doorToDoorCharge:
          _readDouble(map['doorToDoorCharge']),
      registrationFee: _readDouble(map['registrationFee']),
      siblingDiscountPercent:
          _readDouble(map['siblingDiscountPercent']),
      maximumDiscountAmount:
          _readDouble(map['maximumDiscountAmount']),
      currencyCode: map['currencyCode']?.toString() ?? 'PKR',
      minimumDays:
          _readInt(map['minimumDays'], fallback: 1),
      maximumStudents:
          _readInt(map['maximumStudents'], fallback: 1),
      paymentDueDay:
          _readInt(map['paymentDueDay'], fallback: 5),
      paymentGraceDays:
          _readInt(map['paymentGraceDays'], fallback: 3),
      autoRenewAllowed: map['autoRenewAllowed'] != false,
      pauseAllowed: map['pauseAllowed'] == true,
      cancellationAllowed:
          map['cancellationAllowed'] != false,
      displayOrder:
          _readInt(map['displayOrder'], fallback: 0),
      disabledMessage: map['disabledMessage']?.toString() ??
          'This Student Ride package is unavailable.',
      createdBy: map['createdBy']?.toString() ?? '',
      updatedBy: map['updatedBy']?.toString() ?? '',
      createdAt: _readDateTime(map['createdAt']),
      updatedAt: _readDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'packageId': packageId,
      'name': name,
      'description': description,
      'isEnabled': isEnabled,
      'tripType': tripType.name,
      'priceMode': priceMode.name,
      'doorToDoor': doorToDoor,
      'sharedVehicle': sharedVehicle,
      'siblingDiscountAllowed': siblingDiscountAllowed,
      'schoolIds': schoolIds,
      'routeIds': routeIds,
      'vehicleTypes': vehicleTypes,
      'operatingWeekdays': operatingWeekdays,
      'basePrice': basePrice,
      'perKmPrice': perKmPrice,
      'perDayPrice': perDayPrice,
      'doorToDoorCharge': doorToDoorCharge,
      'registrationFee': registrationFee,
      'siblingDiscountPercent': siblingDiscountPercent,
      'maximumDiscountAmount': maximumDiscountAmount,
      'currencyCode': currencyCode,
      'minimumDays': minimumDays,
      'maximumStudents': maximumStudents,
      'paymentDueDay': paymentDueDay,
      'paymentGraceDays': paymentGraceDays,
      'autoRenewAllowed': autoRenewAllowed,
      'pauseAllowed': pauseAllowed,
      'cancellationAllowed': cancellationAllowed,
      'displayOrder': displayOrder,
      'disabledMessage': disabledMessage,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static StudentRidePackageTripType _tripTypeFromString(
    String? value,
  ) {
    return StudentRidePackageTripType.values.firstWhere(
      (item) => item.name == value,
      orElse: () => StudentRidePackageTripType.twoWay,
    );
  }

  static StudentRidePackagePriceMode _priceModeFromString(
    String? value,
  ) {
    return StudentRidePackagePriceMode.values.firstWhere(
      (item) => item.name == value,
      orElse: () =>
          StudentRidePackagePriceMode.fixedMonthly,
    );
  }

  static double _readDouble(dynamic value) {
    return value is num ? value.toDouble() : 0;
  }

  static int _readInt(dynamic value, {required int fallback}) {
    return value is num ? value.toInt() : fallback;
  }

  static List<String> _readStringList(dynamic value) {
    if (value is! List) return const [];

    return value
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static List<int> _readIntList(dynamic value) {
    if (value is! List) {
      return const [1, 2, 3, 4, 5];
    }

    return value
        .whereType<num>()
        .map((item) => item.toInt())
        .where((item) => item >= 1 && item <= 7)
        .toSet()
        .toList()
      ..sort();
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
