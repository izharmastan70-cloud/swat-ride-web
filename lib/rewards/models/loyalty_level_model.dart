// =============================================================
// SWAT RIDE - GLOBAL LOYALTY, REWARDS & PROMO ENGINE
// File: lib/rewards/models/loyalty_level_model.dart
//
// Admin-controlled Bronze, Silver, Gold, Diamond, VIP
// and custom loyalty levels for all SWAT RIDE modules.
// =============================================================

import 'reward_point_model.dart';

class LoyaltyLevelModel {
  final String id;
  final String name;
  final String description;

  /// Lower number appears first.
  final int displayOrder;

  /// Lifetime points required to enter this level.
  final int minimumLifetimePoints;

  /// Optional upper boundary.
  /// Null means there is no maximum.
  final int? maximumLifetimePoints;

  /// Optional completed bookings/orders required.
  final int minimumCompletedBookings;

  /// Example:
  /// 1.0 = normal points
  /// 1.5 = 50% extra points
  /// 2.0 = double points
  final double pointsEarningMultiplier;

  /// Additional cashback percentage for this level.
  final double cashbackBonusPercentage;

  /// Optional automatic discount available to this level.
  final double levelDiscountPercentage;
  final double? maximumLevelDiscount;

  /// Modules in which this level's benefits are valid.
  final List<RewardModule> supportedModules;

  /// Admin-defined benefit labels.
  /// Example: Priority Support, Free Delivery, Special Offers.
  final List<String> benefits;

  /// UI values stored without depending on Flutter classes.
  final String badgeName;
  final String badgeIconUrl;
  final String colorHex;

  final bool isActive;
  final bool isDefaultLevel;
  final bool prioritySupportEnabled;
  final bool freeDeliveryEnabled;
  final bool exclusiveOffersEnabled;

  final DateTime createdAt;
  final DateTime updatedAt;

  final Map<String, dynamic> metadata;

  const LoyaltyLevelModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.displayOrder,
    required this.minimumLifetimePoints,
    this.maximumLifetimePoints,
    this.minimumCompletedBookings = 0,
    this.pointsEarningMultiplier = 1,
    this.cashbackBonusPercentage = 0,
    this.levelDiscountPercentage = 0,
    this.maximumLevelDiscount,
    this.supportedModules = const [RewardModule.all],
    this.benefits = const [],
    this.badgeName = '',
    this.badgeIconUrl = '',
    this.colorHex = '#CD7F32',
    this.isActive = true,
    this.isDefaultLevel = false,
    this.prioritySupportEnabled = false,
    this.freeDeliveryEnabled = false,
    this.exclusiveOffersEnabled = false,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  bool get hasValidConfiguration {
    if (id.trim().isEmpty || name.trim().isEmpty) {
      return false;
    }

    if (displayOrder < 0 ||
        minimumLifetimePoints < 0 ||
        minimumCompletedBookings < 0) {
      return false;
    }

    if (maximumLifetimePoints != null &&
        maximumLifetimePoints! < minimumLifetimePoints) {
      return false;
    }

    if (pointsEarningMultiplier <= 0) {
      return false;
    }

    if (cashbackBonusPercentage < 0 ||
        cashbackBonusPercentage > 100) {
      return false;
    }

    if (levelDiscountPercentage < 0 ||
        levelDiscountPercentage > 100) {
      return false;
    }

    if (maximumLevelDiscount != null &&
        maximumLevelDiscount! < 0) {
      return false;
    }

    return true;
  }

  bool supportsModule(RewardModule module) {
    return supportedModules.contains(RewardModule.all) ||
        supportedModules.contains(module);
  }

  bool qualifiesUser({
    required int lifetimePoints,
    required int completedBookings,
  }) {
    if (!isActive || !hasValidConfiguration) {
      return false;
    }

    if (lifetimePoints < minimumLifetimePoints) {
      return false;
    }

    if (maximumLifetimePoints != null &&
        lifetimePoints > maximumLifetimePoints!) {
      return false;
    }

    if (completedBookings < minimumCompletedBookings) {
      return false;
    }

    return true;
  }

  int calculateLevelPoints(int basePoints) {
    if (!isActive || basePoints <= 0) {
      return 0;
    }

    return (basePoints * pointsEarningMultiplier).floor();
  }

  double calculateLevelDiscount(double eligibleAmount) {
    if (!isActive ||
        eligibleAmount <= 0 ||
        levelDiscountPercentage <= 0) {
      return 0;
    }

    var discount =
        eligibleAmount * (levelDiscountPercentage / 100);

    if (maximumLevelDiscount != null &&
        discount > maximumLevelDiscount!) {
      discount = maximumLevelDiscount!;
    }

    if (discount > eligibleAmount) {
      discount = eligibleAmount;
    }

    return discount < 0 ? 0 : discount;
  }

  LoyaltyLevelModel copyWith({
    String? id,
    String? name,
    String? description,
    int? displayOrder,
    int? minimumLifetimePoints,
    int? maximumLifetimePoints,
    bool removeMaximumLifetimePoints = false,
    int? minimumCompletedBookings,
    double? pointsEarningMultiplier,
    double? cashbackBonusPercentage,
    double? levelDiscountPercentage,
    double? maximumLevelDiscount,
    bool removeMaximumLevelDiscount = false,
    List<RewardModule>? supportedModules,
    List<String>? benefits,
    String? badgeName,
    String? badgeIconUrl,
    String? colorHex,
    bool? isActive,
    bool? isDefaultLevel,
    bool? prioritySupportEnabled,
    bool? freeDeliveryEnabled,
    bool? exclusiveOffersEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return LoyaltyLevelModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      displayOrder: displayOrder ?? this.displayOrder,
      minimumLifetimePoints:
          minimumLifetimePoints ?? this.minimumLifetimePoints,
      maximumLifetimePoints: removeMaximumLifetimePoints
          ? null
          : maximumLifetimePoints ?? this.maximumLifetimePoints,
      minimumCompletedBookings:
          minimumCompletedBookings ??
              this.minimumCompletedBookings,
      pointsEarningMultiplier:
          pointsEarningMultiplier ??
              this.pointsEarningMultiplier,
      cashbackBonusPercentage:
          cashbackBonusPercentage ??
              this.cashbackBonusPercentage,
      levelDiscountPercentage:
          levelDiscountPercentage ??
              this.levelDiscountPercentage,
      maximumLevelDiscount: removeMaximumLevelDiscount
          ? null
          : maximumLevelDiscount ?? this.maximumLevelDiscount,
      supportedModules:
          supportedModules ?? this.supportedModules,
      benefits: benefits ?? this.benefits,
      badgeName: badgeName ?? this.badgeName,
      badgeIconUrl: badgeIconUrl ?? this.badgeIconUrl,
      colorHex: colorHex ?? this.colorHex,
      isActive: isActive ?? this.isActive,
      isDefaultLevel:
          isDefaultLevel ?? this.isDefaultLevel,
      prioritySupportEnabled:
          prioritySupportEnabled ??
              this.prioritySupportEnabled,
      freeDeliveryEnabled:
          freeDeliveryEnabled ?? this.freeDeliveryEnabled,
      exclusiveOffersEnabled:
          exclusiveOffersEnabled ??
              this.exclusiveOffersEnabled,
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
      'displayOrder': displayOrder,
      'minimumLifetimePoints': minimumLifetimePoints,
      'maximumLifetimePoints': maximumLifetimePoints,
      'minimumCompletedBookings': minimumCompletedBookings,
      'pointsEarningMultiplier': pointsEarningMultiplier,
      'cashbackBonusPercentage': cashbackBonusPercentage,
      'levelDiscountPercentage': levelDiscountPercentage,
      'maximumLevelDiscount': maximumLevelDiscount,
      'supportedModules': supportedModules
          .map((module) => module.name)
          .toList(),
      'benefits': benefits,
      'badgeName': badgeName,
      'badgeIconUrl': badgeIconUrl,
      'colorHex': colorHex,
      'isActive': isActive,
      'isDefaultLevel': isDefaultLevel,
      'prioritySupportEnabled': prioritySupportEnabled,
      'freeDeliveryEnabled': freeDeliveryEnabled,
      'exclusiveOffersEnabled': exclusiveOffersEnabled,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'metadata': metadata,
    };
  }

  factory LoyaltyLevelModel.fromMap(
    Map<String, dynamic> map,
  ) {
    final now = DateTime.now();

    return LoyaltyLevelModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      displayOrder:
          (map['displayOrder'] as num?)?.toInt() ?? 0,
      minimumLifetimePoints:
          (map['minimumLifetimePoints'] as num?)?.toInt() ??
              0,
      maximumLifetimePoints:
          (map['maximumLifetimePoints'] as num?)?.toInt(),
      minimumCompletedBookings:
          (map['minimumCompletedBookings'] as num?)
                  ?.toInt() ??
              0,
      pointsEarningMultiplier:
          (map['pointsEarningMultiplier'] as num?)
                  ?.toDouble() ??
              1,
      cashbackBonusPercentage:
          (map['cashbackBonusPercentage'] as num?)
                  ?.toDouble() ??
              0,
      levelDiscountPercentage:
          (map['levelDiscountPercentage'] as num?)
                  ?.toDouble() ??
              0,
      maximumLevelDiscount:
          (map['maximumLevelDiscount'] as num?)?.toDouble(),
      supportedModules:
          _modulesFromValue(map['supportedModules']),
      benefits: _stringListFromValue(map['benefits']),
      badgeName: map['badgeName']?.toString() ?? '',
      badgeIconUrl: map['badgeIconUrl']?.toString() ?? '',
      colorHex: map['colorHex']?.toString() ?? '#CD7F32',
      isActive: map['isActive'] as bool? ?? true,
      isDefaultLevel:
          map['isDefaultLevel'] as bool? ?? false,
      prioritySupportEnabled:
          map['prioritySupportEnabled'] as bool? ?? false,
      freeDeliveryEnabled:
          map['freeDeliveryEnabled'] as bool? ?? false,
      exclusiveOffersEnabled:
          map['exclusiveOffersEnabled'] as bool? ?? false,
      createdAt: _dateFromValue(map['createdAt']) ?? now,
      updatedAt: _dateFromValue(map['updatedAt']) ?? now,
      metadata: Map<String, dynamic>.from(
        map['metadata'] as Map? ?? const {},
      ),
    );
  }

  static List<RewardModule> _modulesFromValue(dynamic value) {
    if (value is! List) {
      return const [RewardModule.all];
    }

    final modules = value
        .map(
          (item) => RewardModule.values.firstWhere(
            (module) => module.name == item.toString(),
            orElse: () => RewardModule.future,
          ),
        )
        .toList();

    return modules.isEmpty
        ? const [RewardModule.all]
        : modules;
  }

  static List<String> _stringListFromValue(dynamic value) {
    if (value is! List) {
      return [];
    }

    return value.map((item) => item.toString()).toList();
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
      return DateTime.fromMillisecondsSinceEpoch(
        value.toInt(),
      );
    }

    return DateTime.tryParse(value.toString());
  }
}