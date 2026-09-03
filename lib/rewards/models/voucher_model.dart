// =============================================================
// SWAT RIDE - GLOBAL LOYALTY, REWARDS & PROMO ENGINE
// File: lib/rewards/models/voucher_model.dart
//
// Birthday, anniversary, festival, loyalty, compensation
// and manually assigned vouchers for all SWAT RIDE modules.
// =============================================================

import 'reward_point_model.dart';

enum VoucherType {
  birthday,
  anniversary,
  festival,
  loyalty,
  compensation,
  campaign,
  manual,
}

enum VoucherBenefitType {
  percentageDiscount,
  fixedDiscount,
  freeDelivery,
  rewardPoints,
}

enum VoucherStatus {
  active,
  redeemed,
  expired,
  cancelled,
}

class VoucherModel {
  final String id;
  final String code;
  final String title;
  final String description;

  final VoucherType type;
  final VoucherBenefitType benefitType;
  final VoucherStatus status;

  /// Percentage, PKR discount, delivery fee or reward points.
  final double benefitValue;

  final double minimumAmount;
  final double? maximumDiscount;

  /// User receiving this voucher.
  /// Null means it is not assigned to a specific user yet.
  final String? assignedUserId;

  /// Modules selected by Admin.
  final List<RewardModule> supportedModules;

  final bool isActive;
  final bool singleUse;

  final bool allowRewardRedemption;
  final bool allowPromoStacking;
  final bool allowCouponStacking;
  final bool allowCashback;

  final DateTime validFrom;
  final DateTime expiryDate;

  final DateTime? redeemedAt;
  final String? redeemedSourceId;
  final RewardModule? redeemedModule;

  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  final Map<String, dynamic> metadata;

  const VoucherModel({
    required this.id,
    required this.code,
    required this.title,
    this.description = '',
    required this.type,
    required this.benefitType,
    this.status = VoucherStatus.active,
    required this.benefitValue,
    this.minimumAmount = 0,
    this.maximumDiscount,
    this.assignedUserId,
    this.supportedModules = const [RewardModule.all],
    this.isActive = true,
    this.singleUse = true,
    this.allowRewardRedemption = false,
    this.allowPromoStacking = false,
    this.allowCouponStacking = false,
    this.allowCashback = true,
    required this.validFrom,
    required this.expiryDate,
    this.redeemedAt,
    this.redeemedSourceId,
    this.redeemedModule,
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

    if (status != VoucherStatus.active) {
      return false;
    }

    if (benefitValue <= 0 || minimumAmount < 0) {
      return false;
    }

    if (benefitType == VoucherBenefitType.percentageDiscount &&
        benefitValue > 100) {
      return false;
    }

    if (maximumDiscount != null && maximumDiscount! < 0) {
      return false;
    }

    if (expiryDate.isBefore(validFrom)) {
      return false;
    }

    if (now.isBefore(validFrom) || now.isAfter(expiryDate)) {
      return false;
    }

    if (singleUse && redeemedAt != null) {
      return false;
    }

    return true;
  }

  bool supportsModule(RewardModule module) {
    return supportedModules.contains(RewardModule.all) ||
        supportedModules.contains(module);
  }

  bool isAssignedToUser(String userId) {
    return assignedUserId == null || assignedUserId == userId;
  }

  bool canUserApply({
    required String userId,
    required RewardModule module,
    required double eligibleAmount,
  }) {
    if (!isCurrentlyValid) {
      return false;
    }

    if (!isAssignedToUser(userId)) {
      return false;
    }

    if (!supportsModule(module)) {
      return false;
    }

    if (eligibleAmount < minimumAmount) {
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

    switch (benefitType) {
      case VoucherBenefitType.percentageDiscount:
        discount = eligibleAmount * (benefitValue / 100);
        break;

      case VoucherBenefitType.fixedDiscount:
        discount = benefitValue;
        break;

      case VoucherBenefitType.freeDelivery:
        discount = benefitValue;
        break;

      case VoucherBenefitType.rewardPoints:
        return 0;
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

  int get rewardPoints {
    if (benefitType != VoucherBenefitType.rewardPoints) {
      return 0;
    }

    return benefitValue.floor();
  }

  VoucherModel copyWith({
    String? id,
    String? code,
    String? title,
    String? description,
    VoucherType? type,
    VoucherBenefitType? benefitType,
    VoucherStatus? status,
    double? benefitValue,
    double? minimumAmount,
    double? maximumDiscount,
    bool removeMaximumDiscount = false,
    String? assignedUserId,
    bool removeAssignedUserId = false,
    List<RewardModule>? supportedModules,
    bool? isActive,
    bool? singleUse,
    bool? allowRewardRedemption,
    bool? allowPromoStacking,
    bool? allowCouponStacking,
    bool? allowCashback,
    DateTime? validFrom,
    DateTime? expiryDate,
    DateTime? redeemedAt,
    bool removeRedeemedAt = false,
    String? redeemedSourceId,
    bool removeRedeemedSourceId = false,
    RewardModule? redeemedModule,
    bool removeRedeemedModule = false,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return VoucherModel(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      benefitType: benefitType ?? this.benefitType,
      status: status ?? this.status,
      benefitValue: benefitValue ?? this.benefitValue,
      minimumAmount: minimumAmount ?? this.minimumAmount,
      maximumDiscount: removeMaximumDiscount
          ? null
          : maximumDiscount ?? this.maximumDiscount,
      assignedUserId: removeAssignedUserId
          ? null
          : assignedUserId ?? this.assignedUserId,
      supportedModules:
          supportedModules ?? this.supportedModules,
      isActive: isActive ?? this.isActive,
      singleUse: singleUse ?? this.singleUse,
      allowRewardRedemption:
          allowRewardRedemption ?? this.allowRewardRedemption,
      allowPromoStacking:
          allowPromoStacking ?? this.allowPromoStacking,
      allowCouponStacking:
          allowCouponStacking ?? this.allowCouponStacking,
      allowCashback: allowCashback ?? this.allowCashback,
      validFrom: validFrom ?? this.validFrom,
      expiryDate: expiryDate ?? this.expiryDate,
      redeemedAt: removeRedeemedAt
          ? null
          : redeemedAt ?? this.redeemedAt,
      redeemedSourceId: removeRedeemedSourceId
          ? null
          : redeemedSourceId ?? this.redeemedSourceId,
      redeemedModule: removeRedeemedModule
          ? null
          : redeemedModule ?? this.redeemedModule,
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
      'type': type.name,
      'benefitType': benefitType.name,
      'status': status.name,
      'benefitValue': benefitValue,
      'minimumAmount': minimumAmount,
      'maximumDiscount': maximumDiscount,
      'assignedUserId': assignedUserId,
      'supportedModules': supportedModules
          .map((module) => module.name)
          .toList(),
      'isActive': isActive,
      'singleUse': singleUse,
      'allowRewardRedemption': allowRewardRedemption,
      'allowPromoStacking': allowPromoStacking,
      'allowCouponStacking': allowCouponStacking,
      'allowCashback': allowCashback,
      'validFrom': validFrom.millisecondsSinceEpoch,
      'expiryDate': expiryDate.millisecondsSinceEpoch,
      'redeemedAt': redeemedAt?.millisecondsSinceEpoch,
      'redeemedSourceId': redeemedSourceId,
      'redeemedModule': redeemedModule?.name,
      'createdBy': createdBy,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'metadata': metadata,
    };
  }

  factory VoucherModel.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();

    return VoucherModel(
      id: map['id']?.toString() ?? '',
      code: map['code']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      type: _voucherTypeFromString(map['type']?.toString()),
      benefitType: _benefitTypeFromString(
        map['benefitType']?.toString(),
      ),
      status: _statusFromString(map['status']?.toString()),
      benefitValue:
          (map['benefitValue'] as num?)?.toDouble() ?? 0,
      minimumAmount:
          (map['minimumAmount'] as num?)?.toDouble() ?? 0,
      maximumDiscount:
          (map['maximumDiscount'] as num?)?.toDouble(),
      assignedUserId: map['assignedUserId']?.toString(),
      supportedModules:
          _modulesFromValue(map['supportedModules']),
      isActive: map['isActive'] as bool? ?? true,
      singleUse: map['singleUse'] as bool? ?? true,
      allowRewardRedemption:
          map['allowRewardRedemption'] as bool? ?? false,
      allowPromoStacking:
          map['allowPromoStacking'] as bool? ?? false,
      allowCouponStacking:
          map['allowCouponStacking'] as bool? ?? false,
      allowCashback:
          map['allowCashback'] as bool? ?? true,
      validFrom: _dateFromValue(map['validFrom']) ?? now,
      expiryDate: _dateFromValue(map['expiryDate']) ?? now,
      redeemedAt: _dateFromValue(map['redeemedAt']),
      redeemedSourceId:
          map['redeemedSourceId']?.toString(),
      redeemedModule:
          _optionalModuleFromString(map['redeemedModule']),
      createdBy: map['createdBy']?.toString() ?? '',
      createdAt:
          _dateFromValue(map['createdAt']) ?? now,
      updatedAt:
          _dateFromValue(map['updatedAt']) ?? now,
      metadata: Map<String, dynamic>.from(
        map['metadata'] as Map? ?? const {},
      ),
    );
  }

  static VoucherType _voucherTypeFromString(String? value) {
    return VoucherType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => VoucherType.manual,
    );
  }

  static VoucherBenefitType _benefitTypeFromString(
    String? value,
  ) {
    return VoucherBenefitType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => VoucherBenefitType.fixedDiscount,
    );
  }

  static VoucherStatus _statusFromString(String? value) {
    return VoucherStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => VoucherStatus.active,
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

  static RewardModule? _optionalModuleFromString(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    return RewardModule.values.firstWhere(
      (module) => module.name == value.toString(),
      orElse: () => RewardModule.future,
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
      return DateTime.fromMillisecondsSinceEpoch(
        value.toInt(),
      );
    }

    return DateTime.tryParse(value.toString());
  }
}