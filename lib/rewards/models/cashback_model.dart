// =============================================================
// SWAT RIDE - GLOBAL LOYALTY, REWARDS & PROMO ENGINE
// File: lib/rewards/models/cashback_model.dart
//
// Admin-controlled cashback rules for every SWAT RIDE module.
// =============================================================

import 'reward_point_model.dart';

enum CashbackType {
  percentage,
  fixedAmount,
}

enum CashbackDestination {
  rewardWallet,
  paymentWallet,
}

class CashbackModel {
  final String id;
  final String name;
  final String description;

  final CashbackType type;
  final CashbackDestination destination;

  /// Percentage or fixed PKR cashback value.
  final double cashbackValue;

  final double minimumBookingAmount;
  final double? maximumCashbackPerBooking;

  /// For conversion when destination is rewardWallet.
  /// Example: 1 PKR cashback = 1 reward point.
  final double rewardPointsPerPkr;

  /// Modules selected by Admin.
  final List<RewardModule> supportedModules;

  /// Empty means every enabled payment method is accepted.
  final List<String> supportedPaymentMethods;

  final bool isActive;

  final bool allowWithPromo;
  final bool allowWithCoupon;
  final bool allowWithVoucher;
  final bool allowWithRewardRedemption;

  /// Cashback remains pending for these days.
  final int pendingDays;

  /// Cashback expires after these days.
  /// Null means it never expires.
  final int? expiryDays;

  final double? dailyCashbackLimit;
  final double? monthlyCashbackLimit;
  final double? yearlyCashbackLimit;

  final int? totalUsageLimit;
  final int? usageLimitPerUser;
  final int usedCount;

  final DateTime? startDate;
  final DateTime? expiryDate;

  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  final Map<String, dynamic> metadata;

  const CashbackModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.type,
    required this.destination,
    required this.cashbackValue,
    this.minimumBookingAmount = 0,
    this.maximumCashbackPerBooking,
    this.rewardPointsPerPkr = 1,
    this.supportedModules = const [RewardModule.all],
    this.supportedPaymentMethods = const [],
    this.isActive = true,
    this.allowWithPromo = true,
    this.allowWithCoupon = true,
    this.allowWithVoucher = true,
    this.allowWithRewardRedemption = false,
    this.pendingDays = 0,
    this.expiryDays,
    this.dailyCashbackLimit,
    this.monthlyCashbackLimit,
    this.yearlyCashbackLimit,
    this.totalUsageLimit,
    this.usageLimitPerUser,
    this.usedCount = 0,
    this.startDate,
    this.expiryDate,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  bool get isCurrentlyValid {
    final now = DateTime.now();

    if (!isActive || id.trim().isEmpty || name.trim().isEmpty) {
      return false;
    }

    if (cashbackValue <= 0 || minimumBookingAmount < 0) {
      return false;
    }

    if (type == CashbackType.percentage &&
        cashbackValue > 100) {
      return false;
    }

    if (maximumCashbackPerBooking != null &&
        maximumCashbackPerBooking! < 0) {
      return false;
    }

    if (destination == CashbackDestination.rewardWallet &&
        rewardPointsPerPkr <= 0) {
      return false;
    }

    if (pendingDays < 0) {
      return false;
    }

    if (expiryDays != null && expiryDays! < 0) {
      return false;
    }

    if (dailyCashbackLimit != null &&
        dailyCashbackLimit! < 0) {
      return false;
    }

    if (monthlyCashbackLimit != null &&
        monthlyCashbackLimit! < 0) {
      return false;
    }

    if (yearlyCashbackLimit != null &&
        yearlyCashbackLimit! < 0) {
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

  bool canUserReceiveCashback({
    required RewardModule module,
    required String paymentMethod,
    required double eligibleAmount,
    required int userUsageCount,
    required double userDailyCashback,
    required double userMonthlyCashback,
    required double userYearlyCashback,
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

    if (eligibleAmount < minimumBookingAmount) {
      return false;
    }

    if (usageLimitPerUser != null &&
        userUsageCount >= usageLimitPerUser!) {
      return false;
    }

    if (dailyCashbackLimit != null &&
        userDailyCashback >= dailyCashbackLimit!) {
      return false;
    }

    if (monthlyCashbackLimit != null &&
        userMonthlyCashback >= monthlyCashbackLimit!) {
      return false;
    }

    if (yearlyCashbackLimit != null &&
        userYearlyCashback >= yearlyCashbackLimit!) {
      return false;
    }

    return true;
  }

  double calculateCashback(double eligibleAmount) {
    if (!isCurrentlyValid ||
        eligibleAmount <= 0 ||
        eligibleAmount < minimumBookingAmount) {
      return 0;
    }

    double cashback;

    switch (type) {
      case CashbackType.percentage:
        cashback = eligibleAmount * (cashbackValue / 100);
        break;

      case CashbackType.fixedAmount:
        cashback = cashbackValue;
        break;
    }

    if (maximumCashbackPerBooking != null &&
        cashback > maximumCashbackPerBooking!) {
      cashback = maximumCashbackPerBooking!;
    }

    if (cashback > eligibleAmount) {
      cashback = eligibleAmount;
    }

    return cashback < 0 ? 0 : cashback;
  }

  int calculateRewardPoints(double cashbackAmount) {
    if (destination != CashbackDestination.rewardWallet ||
        cashbackAmount <= 0 ||
        rewardPointsPerPkr <= 0) {
      return 0;
    }

    return (cashbackAmount * rewardPointsPerPkr).floor();
  }

  DateTime calculateAvailableAt(DateTime completedAt) {
    return completedAt.add(Duration(days: pendingDays));
  }

  DateTime? calculateCashbackExpiry(DateTime availableAt) {
    if (expiryDays == null) {
      return null;
    }

    return availableAt.add(Duration(days: expiryDays!));
  }

  CashbackModel copyWith({
    String? id,
    String? name,
    String? description,
    CashbackType? type,
    CashbackDestination? destination,
    double? cashbackValue,
    double? minimumBookingAmount,
    double? maximumCashbackPerBooking,
    bool removeMaximumCashbackPerBooking = false,
    double? rewardPointsPerPkr,
    List<RewardModule>? supportedModules,
    List<String>? supportedPaymentMethods,
    bool? isActive,
    bool? allowWithPromo,
    bool? allowWithCoupon,
    bool? allowWithVoucher,
    bool? allowWithRewardRedemption,
    int? pendingDays,
    int? expiryDays,
    bool removeExpiryDays = false,
    double? dailyCashbackLimit,
    bool removeDailyCashbackLimit = false,
    double? monthlyCashbackLimit,
    bool removeMonthlyCashbackLimit = false,
    double? yearlyCashbackLimit,
    bool removeYearlyCashbackLimit = false,
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
    return CashbackModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      destination: destination ?? this.destination,
      cashbackValue: cashbackValue ?? this.cashbackValue,
      minimumBookingAmount:
          minimumBookingAmount ?? this.minimumBookingAmount,
      maximumCashbackPerBooking:
          removeMaximumCashbackPerBooking
              ? null
              : maximumCashbackPerBooking ??
                  this.maximumCashbackPerBooking,
      rewardPointsPerPkr:
          rewardPointsPerPkr ?? this.rewardPointsPerPkr,
      supportedModules:
          supportedModules ?? this.supportedModules,
      supportedPaymentMethods:
          supportedPaymentMethods ??
              this.supportedPaymentMethods,
      isActive: isActive ?? this.isActive,
      allowWithPromo:
          allowWithPromo ?? this.allowWithPromo,
      allowWithCoupon:
          allowWithCoupon ?? this.allowWithCoupon,
      allowWithVoucher:
          allowWithVoucher ?? this.allowWithVoucher,
      allowWithRewardRedemption:
          allowWithRewardRedemption ??
              this.allowWithRewardRedemption,
      pendingDays: pendingDays ?? this.pendingDays,
      expiryDays: removeExpiryDays
          ? null
          : expiryDays ?? this.expiryDays,
      dailyCashbackLimit: removeDailyCashbackLimit
          ? null
          : dailyCashbackLimit ?? this.dailyCashbackLimit,
      monthlyCashbackLimit: removeMonthlyCashbackLimit
          ? null
          : monthlyCashbackLimit ??
              this.monthlyCashbackLimit,
      yearlyCashbackLimit: removeYearlyCashbackLimit
          ? null
          : yearlyCashbackLimit ?? this.yearlyCashbackLimit,
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
      'name': name,
      'description': description,
      'type': type.name,
      'destination': destination.name,
      'cashbackValue': cashbackValue,
      'minimumBookingAmount': minimumBookingAmount,
      'maximumCashbackPerBooking':
          maximumCashbackPerBooking,
      'rewardPointsPerPkr': rewardPointsPerPkr,
      'supportedModules': supportedModules
          .map((module) => module.name)
          .toList(),
      'supportedPaymentMethods': supportedPaymentMethods,
      'isActive': isActive,
      'allowWithPromo': allowWithPromo,
      'allowWithCoupon': allowWithCoupon,
      'allowWithVoucher': allowWithVoucher,
      'allowWithRewardRedemption':
          allowWithRewardRedemption,
      'pendingDays': pendingDays,
      'expiryDays': expiryDays,
      'dailyCashbackLimit': dailyCashbackLimit,
      'monthlyCashbackLimit': monthlyCashbackLimit,
      'yearlyCashbackLimit': yearlyCashbackLimit,
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

  factory CashbackModel.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();

    return CashbackModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      type: _typeFromString(map['type']?.toString()),
      destination: _destinationFromString(
        map['destination']?.toString(),
      ),
      cashbackValue:
          (map['cashbackValue'] as num?)?.toDouble() ?? 0,
      minimumBookingAmount:
          (map['minimumBookingAmount'] as num?)
                  ?.toDouble() ??
              0,
      maximumCashbackPerBooking:
          (map['maximumCashbackPerBooking'] as num?)
              ?.toDouble(),
      rewardPointsPerPkr:
          (map['rewardPointsPerPkr'] as num?)
                  ?.toDouble() ??
              1,
      supportedModules:
          _modulesFromValue(map['supportedModules']),
      supportedPaymentMethods: _stringListFromValue(
        map['supportedPaymentMethods'],
      ),
      isActive: map['isActive'] as bool? ?? true,
      allowWithPromo:
          map['allowWithPromo'] as bool? ?? true,
      allowWithCoupon:
          map['allowWithCoupon'] as bool? ?? true,
      allowWithVoucher:
          map['allowWithVoucher'] as bool? ?? true,
      allowWithRewardRedemption:
          map['allowWithRewardRedemption'] as bool? ?? false,
      pendingDays:
          (map['pendingDays'] as num?)?.toInt() ?? 0,
      expiryDays: (map['expiryDays'] as num?)?.toInt(),
      dailyCashbackLimit:
          (map['dailyCashbackLimit'] as num?)?.toDouble(),
      monthlyCashbackLimit:
          (map['monthlyCashbackLimit'] as num?)?.toDouble(),
      yearlyCashbackLimit:
          (map['yearlyCashbackLimit'] as num?)?.toDouble(),
      totalUsageLimit:
          (map['totalUsageLimit'] as num?)?.toInt(),
      usageLimitPerUser:
          (map['usageLimitPerUser'] as num?)?.toInt(),
      usedCount: (map['usedCount'] as num?)?.toInt() ?? 0,
      startDate: _dateFromValue(map['startDate']),
      expiryDate: _dateFromValue(map['expiryDate']),
      createdBy: map['createdBy']?.toString() ?? '',
      createdAt: _dateFromValue(map['createdAt']) ?? now,
      updatedAt: _dateFromValue(map['updatedAt']) ?? now,
      metadata: Map<String, dynamic>.from(
        map['metadata'] as Map? ?? const {},
      ),
    );
  }

  static CashbackType _typeFromString(String? value) {
    return CashbackType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => CashbackType.percentage,
    );
  }

  static CashbackDestination _destinationFromString(
    String? value,
  ) {
    return CashbackDestination.values.firstWhere(
      (destination) => destination.name == value,
      orElse: () => CashbackDestination.rewardWallet,
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