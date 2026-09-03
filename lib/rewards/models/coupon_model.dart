// =============================================================
// SWAT RIDE - GLOBAL LOYALTY, REWARDS & PROMO ENGINE
// File: lib/rewards/models/coupon_model.dart
//
// Admin-controlled coupons for all SWAT RIDE modules.
// =============================================================

import 'global_promo_code_model.dart';
import 'reward_point_model.dart';

enum CouponDistributionType {
  public,
  selectedUsers,
  loyaltyLevel,
  firstBooking,
  manual,
}

class CouponModel {
  final String id;
  final String code;
  final String title;
  final String description;

  final GlobalPromoDiscountType discountType;
  final double discountValue;
  final double minimumAmount;
  final double? maximumDiscount;

  /// Modules selected by Admin.
  final List<RewardModule> supportedModules;

  /// Controls who can use or receive this coupon.
  final CouponDistributionType distributionType;

  /// Used when distributionType is selectedUsers.
  final List<String> assignedUserIds;

  /// Used when distributionType is loyaltyLevel.
  final List<String> requiredLoyaltyLevelIds;

  final bool isActive;
  final bool singleUsePerUser;

  final bool allowRewardRedemption;
  final bool allowPromoStacking;
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

  const CouponModel({
    required this.id,
    required this.code,
    required this.title,
    this.description = '',
    required this.discountType,
    required this.discountValue,
    this.minimumAmount = 0,
    this.maximumDiscount,
    this.supportedModules = const [RewardModule.all],
    this.distributionType = CouponDistributionType.public,
    this.assignedUserIds = const [],
    this.requiredLoyaltyLevelIds = const [],
    this.isActive = true,
    this.singleUsePerUser = true,
    this.allowRewardRedemption = false,
    this.allowPromoStacking = false,
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

  bool isAvailableForUser({
    required String userId,
    required String loyaltyLevelId,
    required bool isFirstBooking,
  }) {
    switch (distributionType) {
      case CouponDistributionType.public:
        return true;

      case CouponDistributionType.selectedUsers:
        return assignedUserIds.contains(userId);

      case CouponDistributionType.loyaltyLevel:
        return requiredLoyaltyLevelIds.contains(loyaltyLevelId);

      case CouponDistributionType.firstBooking:
        return isFirstBooking;

      case CouponDistributionType.manual:
        return assignedUserIds.contains(userId);
    }
  }

  bool canUserApply({
    required String userId,
    required String loyaltyLevelId,
    required RewardModule module,
    required double eligibleAmount,
    required int userUsageCount,
    required bool isFirstBooking,
  }) {
    if (!isCurrentlyValid) {
      return false;
    }

    if (!supportsModule(module)) {
      return false;
    }

    if (eligibleAmount < minimumAmount) {
      return false;
    }

    if (!isAvailableForUser(
      userId: userId,
      loyaltyLevelId: loyaltyLevelId,
      isFirstBooking: isFirstBooking,
    )) {
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
    if (!isCurrentlyValid ||
        eligibleAmount <= 0 ||
        eligibleAmount < minimumAmount) {
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
      'distributionType': distributionType.name,
      'assignedUserIds': assignedUserIds,
      'requiredLoyaltyLevelIds': requiredLoyaltyLevelIds,
      'isActive': isActive,
      'singleUsePerUser': singleUsePerUser,
      'allowRewardRedemption': allowRewardRedemption,
      'allowPromoStacking': allowPromoStacking,
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

  factory CouponModel.fromMap(Map<String, dynamic> map) {
    return CouponModel(
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
      distributionType: _distributionTypeFromString(
        map['distributionType']?.toString(),
      ),
      assignedUserIds:
          _stringListFromValue(map['assignedUserIds']),
      requiredLoyaltyLevelIds: _stringListFromValue(
        map['requiredLoyaltyLevelIds'],
      ),
      isActive: map['isActive'] as bool? ?? true,
      singleUsePerUser:
          map['singleUsePerUser'] as bool? ?? true,
      allowRewardRedemption:
          map['allowRewardRedemption'] as bool? ?? false,
      allowPromoStacking:
          map['allowPromoStacking'] as bool? ?? false,
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

  static CouponDistributionType _distributionTypeFromString(
    String? value,
  ) {
    return CouponDistributionType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => CouponDistributionType.public,
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