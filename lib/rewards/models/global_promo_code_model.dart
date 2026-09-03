// =============================================================
// SWAT RIDE - GLOBAL LOYALTY, REWARDS & PROMO ENGINE
// File: lib/rewards/models/global_promo_code_model.dart
//
// Global promo codes for Ride, Student Ride, Food, Hotel,
// Tourism, Cargo, Parcel, drivers, partners and future modules.
// =============================================================

import 'reward_point_model.dart';

enum GlobalPromoDiscountType {
  percentage,
  fixedAmount,
  freeDelivery,
}

class GlobalPromoCodeModel {
  final String id;
  final String code;
  final String title;
  final String description;

  final GlobalPromoDiscountType discountType;
  final double discountValue;

  final double minimumAmount;
  final double? maximumDiscount;

  /// Promo modules selected by Admin.
  final List<RewardModule> supportedModules;

  /// Empty list means every enabled payment method is supported.
  final List<String> supportedPaymentMethods;

  final bool isActive;
  final bool firstBookingOnly;
  final bool newUsersOnly;
  final bool singleUsePerUser;

  /// Controls whether this promo can be combined with other benefits.
  final bool allowRewardRedemption;
  final bool allowCouponStacking;
  final bool allowVoucherStacking;
  final bool allowCashback;

  final int? totalUsageLimit;
  final int? usageLimitPerUser;
  final int usedCount;

  final DateTime? startDate;
  final DateTime? expiryDate;

  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  final Map<String, dynamic> metadata;

  const GlobalPromoCodeModel({
    required this.id,
    required this.code,
    required this.title,
    this.description = '',
    required this.discountType,
    required this.discountValue,
    this.minimumAmount = 0,
    this.maximumDiscount,
    this.supportedModules = const [RewardModule.all],
    this.supportedPaymentMethods = const [],
    this.isActive = true,
    this.firstBookingOnly = false,
    this.newUsersOnly = false,
    this.singleUsePerUser = true,
    this.allowRewardRedemption = false,
    this.allowCouponStacking = false,
    this.allowVoucherStacking = false,
    this.allowCashback = true,
    this.totalUsageLimit,
    this.usageLimitPerUser = 1,
    this.usedCount = 0,
    this.startDate,
    this.expiryDate,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  String get normalizedCode {
    return code.trim().toUpperCase();
  }

  bool get isCurrentlyValid {
    final now = DateTime.now();

    if (!isActive || normalizedCode.isEmpty) {
      return false;
    }

    if (discountValue < 0 || minimumAmount < 0) {
      return false;
    }

    if (discountType == GlobalPromoDiscountType.percentage &&
        discountValue > 100) {
      return false;
    }

    if (maximumDiscount != null && maximumDiscount! < 0) {
      return false;
    }

    if (totalUsageLimit != null &&
        usedCount >= totalUsageLimit!) {
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

  bool supportsModule(RewardModule module) {
    return supportedModules.contains(RewardModule.all) ||
        supportedModules.contains(module);
  }

  bool supportsPaymentMethod(String paymentMethod) {
    if (supportedPaymentMethods.isEmpty) {
      return true;
    }

    final normalizedMethod = paymentMethod.trim().toLowerCase();

    return supportedPaymentMethods.any(
      (method) => method.trim().toLowerCase() == normalizedMethod,
    );
  }

  bool canUserApply({
    required RewardModule module,
    required double eligibleAmount,
    required int userUsageCount,
    required bool isFirstBooking,
    required bool isNewUser,
    required String paymentMethod,
  }) {
    if (!isCurrentlyValid) {
      return false;
    }

    if (!supportsModule(module)) {
      return false;
    }

    if (!supportsPaymentMethod(paymentMethod)) {
      return false;
    }

    if (eligibleAmount < minimumAmount) {
      return false;
    }

    if (firstBookingOnly && !isFirstBooking) {
      return false;
    }

    if (newUsersOnly && !isNewUser) {
      return false;
    }

    if (singleUsePerUser && userUsageCount > 0) {
      return false;
    }

    if (usageLimitPerUser != null &&
        userUsageCount >= usageLimitPerUser!) {
      return false;
    }

    return true;
  }

  double calculateDiscount(double eligibleAmount) {
    if (!isCurrentlyValid || eligibleAmount <= 0) {
      return 0;
    }

    if (eligibleAmount < minimumAmount) {
      return 0;
    }

    double discount;

    switch (discountType) {
      case GlobalPromoDiscountType.percentage:
        discount = eligibleAmount * (discountValue / 100);
        break;

      case GlobalPromoDiscountType.fixedAmount:
        discount = discountValue;
        break;

      case GlobalPromoDiscountType.freeDelivery:
        discount = discountValue;
        break;
    }

    if (maximumDiscount != null &&
        discount > maximumDiscount!) {
      discount = maximumDiscount!;
    }

    if (discount > eligibleAmount) {
      discount = eligibleAmount;
    }

    return discount < 0 ? 0 : discount;
  }

  GlobalPromoCodeModel copyWith({
    String? id,
    String? code,
    String? title,
    String? description,
    GlobalPromoDiscountType? discountType,
    double? discountValue,
    double? minimumAmount,
    double? maximumDiscount,
    bool removeMaximumDiscount = false,
    List<RewardModule>? supportedModules,
    List<String>? supportedPaymentMethods,
    bool? isActive,
    bool? firstBookingOnly,
    bool? newUsersOnly,
    bool? singleUsePerUser,
    bool? allowRewardRedemption,
    bool? allowCouponStacking,
    bool? allowVoucherStacking,
    bool? allowCashback,
    int? totalUsageLimit,
    bool removeTotalUsageLimit = false,
    int? usageLimitPerUser,
    bool removeUsageLimitPerUser = false,
    int? usedCount,
    DateTime? startDate,
    bool removeStartDate = false,
    DateTime? expiryDate,
    bool removeExpiryDate = false,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return GlobalPromoCodeModel(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      minimumAmount: minimumAmount ?? this.minimumAmount,
      maximumDiscount: removeMaximumDiscount
          ? null
          : maximumDiscount ?? this.maximumDiscount,
      supportedModules:
          supportedModules ?? this.supportedModules,
      supportedPaymentMethods:
          supportedPaymentMethods ?? this.supportedPaymentMethods,
      isActive: isActive ?? this.isActive,
      firstBookingOnly:
          firstBookingOnly ?? this.firstBookingOnly,
      newUsersOnly: newUsersOnly ?? this.newUsersOnly,
      singleUsePerUser:
          singleUsePerUser ?? this.singleUsePerUser,
      allowRewardRedemption:
          allowRewardRedemption ?? this.allowRewardRedemption,
      allowCouponStacking:
          allowCouponStacking ?? this.allowCouponStacking,
      allowVoucherStacking:
          allowVoucherStacking ?? this.allowVoucherStacking,
      allowCashback: allowCashback ?? this.allowCashback,
      totalUsageLimit: removeTotalUsageLimit
          ? null
          : totalUsageLimit ?? this.totalUsageLimit,
      usageLimitPerUser: removeUsageLimitPerUser
          ? null
          : usageLimitPerUser ?? this.usageLimitPerUser,
      usedCount: usedCount ?? this.usedCount,
      startDate:
          removeStartDate ? null : startDate ?? this.startDate,
      expiryDate:
          removeExpiryDate ? null : expiryDate ?? this.expiryDate,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': normalizedCode,
      'title': title,
      'description': description,
      'discountType': discountType.name,
      'discountValue': discountValue,
      'minimumAmount': minimumAmount,
      'maximumDiscount': maximumDiscount,
      'supportedModules': supportedModules
          .map((module) => module.name)
          .toList(),
      'supportedPaymentMethods': supportedPaymentMethods,
      'isActive': isActive,
      'firstBookingOnly': firstBookingOnly,
      'newUsersOnly': newUsersOnly,
      'singleUsePerUser': singleUsePerUser,
      'allowRewardRedemption': allowRewardRedemption,
      'allowCouponStacking': allowCouponStacking,
      'allowVoucherStacking': allowVoucherStacking,
      'allowCashback': allowCashback,
      'totalUsageLimit': totalUsageLimit,
      'usageLimitPerUser': usageLimitPerUser,
      'usedCount': usedCount,
      'startDate': startDate?.millisecondsSinceEpoch,
      'expiryDate': expiryDate?.millisecondsSinceEpoch,
      'createdBy': createdBy,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'metadata': metadata,
    };
  }

  factory GlobalPromoCodeModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return GlobalPromoCodeModel(
      id: map['id']?.toString() ?? '',
      code: map['code']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      discountType: _discountTypeFromString(
        map['discountType']?.toString(),
      ),
      discountValue:
          (map['discountValue'] as num?)?.toDouble() ?? 0,
      minimumAmount:
          (map['minimumAmount'] as num?)?.toDouble() ?? 0,
      maximumDiscount:
          (map['maximumDiscount'] as num?)?.toDouble(),
      supportedModules:
          _modulesFromValue(map['supportedModules']),
      supportedPaymentMethods: _stringListFromValue(
        map['supportedPaymentMethods'],
      ),
      isActive: map['isActive'] as bool? ?? true,
      firstBookingOnly:
          map['firstBookingOnly'] as bool? ?? false,
      newUsersOnly: map['newUsersOnly'] as bool? ?? false,
      singleUsePerUser:
          map['singleUsePerUser'] as bool? ?? true,
      allowRewardRedemption:
          map['allowRewardRedemption'] as bool? ?? false,
      allowCouponStacking:
          map['allowCouponStacking'] as bool? ?? false,
      allowVoucherStacking:
          map['allowVoucherStacking'] as bool? ?? false,
      allowCashback:
          map['allowCashback'] as bool? ?? true,
      totalUsageLimit:
          (map['totalUsageLimit'] as num?)?.toInt(),
      usageLimitPerUser:
          (map['usageLimitPerUser'] as num?)?.toInt(),
      usedCount: (map['usedCount'] as num?)?.toInt() ?? 0,
      startDate: _dateFromValue(map['startDate']),
      expiryDate: _dateFromValue(map['expiryDate']),
      createdBy: map['createdBy']?.toString() ?? '',
      createdAt:
          _dateFromValue(map['createdAt']) ?? DateTime.now(),
      updatedAt:
          _dateFromValue(map['updatedAt']) ?? DateTime.now(),
      metadata: Map<String, dynamic>.from(
        map['metadata'] as Map? ?? const {},
      ),
    );
  }

  static GlobalPromoDiscountType _discountTypeFromString(
    String? value,
  ) {
    return GlobalPromoDiscountType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => GlobalPromoDiscountType.fixedAmount,
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