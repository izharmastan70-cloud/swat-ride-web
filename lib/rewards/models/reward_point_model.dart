// =============================================================
// SWAT RIDE - GLOBAL LOYALTY, REWARDS & PROMO ENGINE
// File: lib/rewards/models/reward_point_model.dart
//
// Reward points earning rule for every SWAT RIDE module.
// Existing modules will be connected after app completion.
// =============================================================

enum RewardModule {
  ride,
  rideDriver,

  studentRide,
  studentDriver,

  food,
  foodDeliveryRider,
  restaurantPartner,

  hotel,
  hotelOwner,

  tourism,
  tourismDriver,
  tourGuide,

  cargo,
  cargoDriver,

  parcel,
  parcelDriver,

  wallet,

  all,
  future,
}

class RewardPointModel {
  final String id;
  final String name;
  final String description;

  /// The app module or role where this rule is valid.
  final RewardModule module;

  /// Admin-controlled ON/OFF setting.
  final bool isActive;

  /// Example:
  /// pkrPerPoint = 100
  /// pointsPerUnit = 1
  ///
  /// Customer earns 1 point after spending every 100 PKR.
  final double pkrPerPoint;
  final int pointsPerUnit;

  /// Minimum eligible booking/order amount.
  final double minimumSpend;

  /// Optional maximum earning from one booking/order.
  final int? maximumPointsPerBooking;

  /// Optional campaign start and expiry.
  final DateTime? startDate;
  final DateTime? expiryDate;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Future Admin settings without changing the core model.
  final Map<String, dynamic> metadata;

  const RewardPointModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.module,
    this.isActive = true,
    this.pkrPerPoint = 100,
    this.pointsPerUnit = 1,
    this.minimumSpend = 0,
    this.maximumPointsPerBooking,
    this.startDate,
    this.expiryDate,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  bool get isCurrentlyValid {
    final now = DateTime.now();

    if (!isActive) {
      return false;
    }

    if (pkrPerPoint <= 0 || pointsPerUnit <= 0) {
      return false;
    }

    if (minimumSpend < 0) {
      return false;
    }

    if (maximumPointsPerBooking != null &&
        maximumPointsPerBooking! < 0) {
      return false;
    }

    if (startDate != null && now.isBefore(startDate!)) {
      return false;
    }

    if (expiryDate != null && now.isAfter(expiryDate!)) {
      return false;
    }

    if (startDate != null &&
        expiryDate != null &&
        expiryDate!.isBefore(startDate!)) {
      return false;
    }

    return true;
  }

  bool supportsModule(RewardModule selectedModule) {
    return module == RewardModule.all || module == selectedModule;
  }

  int calculatePoints({
    required double eligibleAmount,
    required RewardModule selectedModule,
  }) {
    if (!isCurrentlyValid) {
      return 0;
    }

    if (!supportsModule(selectedModule)) {
      return 0;
    }

    if (eligibleAmount <= 0 || eligibleAmount < minimumSpend) {
      return 0;
    }

    final completedUnits = (eligibleAmount / pkrPerPoint).floor();
    var calculatedPoints = completedUnits * pointsPerUnit;

    if (maximumPointsPerBooking != null &&
        calculatedPoints > maximumPointsPerBooking!) {
      calculatedPoints = maximumPointsPerBooking!;
    }

    return calculatedPoints < 0 ? 0 : calculatedPoints;
  }

  RewardPointModel copyWith({
    String? id,
    String? name,
    String? description,
    RewardModule? module,
    bool? isActive,
    double? pkrPerPoint,
    int? pointsPerUnit,
    double? minimumSpend,
    int? maximumPointsPerBooking,
    bool removeMaximumPointsPerBooking = false,
    DateTime? startDate,
    bool removeStartDate = false,
    DateTime? expiryDate,
    bool removeExpiryDate = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return RewardPointModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      module: module ?? this.module,
      isActive: isActive ?? this.isActive,
      pkrPerPoint: pkrPerPoint ?? this.pkrPerPoint,
      pointsPerUnit: pointsPerUnit ?? this.pointsPerUnit,
      minimumSpend: minimumSpend ?? this.minimumSpend,
      maximumPointsPerBooking: removeMaximumPointsPerBooking
          ? null
          : maximumPointsPerBooking ?? this.maximumPointsPerBooking,
      startDate: removeStartDate ? null : startDate ?? this.startDate,
      expiryDate: removeExpiryDate ? null : expiryDate ?? this.expiryDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'module': module.name,
      'isActive': isActive,
      'pkrPerPoint': pkrPerPoint,
      'pointsPerUnit': pointsPerUnit,
      'minimumSpend': minimumSpend,
      'maximumPointsPerBooking': maximumPointsPerBooking,
      'startDate': startDate?.millisecondsSinceEpoch,
      'expiryDate': expiryDate?.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'metadata': metadata,
    };
  }

  factory RewardPointModel.fromMap(Map<String, dynamic> map) {
    return RewardPointModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      module: _moduleFromString(map['module']?.toString()),
      isActive: map['isActive'] as bool? ?? true,
      pkrPerPoint: (map['pkrPerPoint'] as num?)?.toDouble() ?? 100,
      pointsPerUnit: (map['pointsPerUnit'] as num?)?.toInt() ?? 1,
      minimumSpend: (map['minimumSpend'] as num?)?.toDouble() ?? 0,
      maximumPointsPerBooking:
          (map['maximumPointsPerBooking'] as num?)?.toInt(),
      startDate: _dateFromValue(map['startDate']),
      expiryDate: _dateFromValue(map['expiryDate']),
      createdAt: _dateFromValue(map['createdAt']) ?? DateTime.now(),
      updatedAt: _dateFromValue(map['updatedAt']) ?? DateTime.now(),
      metadata: Map<String, dynamic>.from(
        map['metadata'] as Map? ?? const {},
      ),
    );
  }

  static RewardModule _moduleFromString(String? value) {
    return RewardModule.values.firstWhere(
      (module) => module.name == value,
      orElse: () => RewardModule.all,
    );
  }

  static DateTime? _dateFromValue(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }

    return DateTime.tryParse(value.toString());
  }
}