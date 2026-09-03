// =============================================================
// SWAT RIDE - GLOBAL LOYALTY, REWARDS & PROMO ENGINE
// File: lib/rewards/models/reward_settings_model.dart
//
// Global and module-wise Admin controls for rewards, promos,
// coupons, vouchers, cashback, referrals and loyalty.
// =============================================================

import 'reward_point_model.dart';

enum RewardExpiryPolicy {
  never,
  customDays,
}

class RewardSettingsModel {
  final String id;

  // -----------------------------------------------------------
  // GLOBAL MASTER CONTROLS
  // -----------------------------------------------------------

  final bool rewardsEnabled;
  final bool promoEnabled;
  final bool couponEnabled;
  final bool voucherEnabled;
  final bool cashbackEnabled;
  final bool referralEnabled;
  final bool loyaltyEnabled;

  // -----------------------------------------------------------
  // MODULE-WISE CONTROLS
  //
  // Example:
  // {
  //   'ride': true,
  //   'food': true,
  //   'hotel': false,
  // }
  //
  // If a module is missing, the 'all' value is used.
  // -----------------------------------------------------------

  final Map<String, bool> moduleRewardEnabled;
  final Map<String, bool> modulePromoEnabled;
  final Map<String, bool> moduleCouponEnabled;
  final Map<String, bool> moduleVoucherEnabled;
  final Map<String, bool> moduleCashbackEnabled;
  final Map<String, bool> moduleReferralEnabled;
  final Map<String, bool> moduleLoyaltyEnabled;

  // -----------------------------------------------------------
  // SIGNUP BONUS
  // -----------------------------------------------------------

  final bool signupBonusEnabled;
  final int signupBonusPoints;
  final String? signupBonusCouponId;
  final String? signupBonusVoucherId;

  // -----------------------------------------------------------
  // FIRST BOOKING BONUS
  // -----------------------------------------------------------

  final bool firstBookingBonusEnabled;
  final int firstBookingBonusPoints;
  final String? firstBookingBonusCouponId;
  final String? firstBookingBonusVoucherId;

  // -----------------------------------------------------------
  // POINT VALUE AND REDEMPTION
  // -----------------------------------------------------------

  /// PKR value of one reward point during redemption.
  /// Example: 1 point = 1 PKR.
  final double pkrValuePerPoint;

  final int minimumRedeemPoints;
  final int? maximumRedeemPointsPerBooking;

  /// Maximum percentage of booking amount payable with points.
  final double maximumRedeemPercentage;

  // -----------------------------------------------------------
  // EARNING LIMITS
  // -----------------------------------------------------------

  final int? maximumEarnPointsPerBooking;
  final int? dailyEarnPointsLimit;
  final int? monthlyEarnPointsLimit;
  final int? yearlyEarnPointsLimit;

  // -----------------------------------------------------------
  // REDEMPTION LIMITS
  // -----------------------------------------------------------

  final int? dailyRedeemPointsLimit;
  final int? monthlyRedeemPointsLimit;
  final int? yearlyRedeemPointsLimit;

  // -----------------------------------------------------------
  // REWARD EXPIRY
  // -----------------------------------------------------------

  final RewardExpiryPolicy expiryPolicy;

  /// Used only when expiryPolicy is customDays.
  final int? rewardExpiryDays;

  final int expiryReminderDays;

  // -----------------------------------------------------------
  // STACKING RULES
  // -----------------------------------------------------------

  final bool allowPromoWithRewards;
  final bool allowCouponWithRewards;
  final bool allowVoucherWithRewards;
  final bool allowCashbackWithRewards;

  final bool allowPromoWithCoupon;
  final bool allowPromoWithVoucher;
  final bool allowCouponWithVoucher;

  // -----------------------------------------------------------
  // BOOKING AND PAYMENT SAFETY
  // -----------------------------------------------------------

  /// Rewards are earned only after booking/order completion.
  final bool requireCompletedBooking;

  /// Rewards are earned only after successful payment.
  final bool requireSuccessfulPayment;

  /// Points/cashback are reversed after cancellation/refund.
  final bool reverseRewardOnCancellation;
  final bool reverseRewardOnRefund;

  /// Wallet must never go below zero.
  final bool preventNegativeRewardBalance;

  /// Duplicate source/booking reward must be blocked.
  final bool duplicateRewardProtectionEnabled;

  // -----------------------------------------------------------
  // NOTIFICATIONS AND AI
  // -----------------------------------------------------------

  final bool rewardNotificationsEnabled;
  final bool expiryNotificationsEnabled;
  final bool loyaltyUpgradeNotificationsEnabled;

  /// AI can only recommend; it cannot finalize discounts.
  final bool aiRecommendationsEnabled;
  final bool aiAutoApplyEnabled;

  // -----------------------------------------------------------
  // ADMIN AUDIT
  // -----------------------------------------------------------

  final String updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Increased on every Admin settings update.
  final int version;

  final Map<String, dynamic> metadata;

  const RewardSettingsModel({
    required this.id,
    this.rewardsEnabled = false,
    this.promoEnabled = false,
    this.couponEnabled = false,
    this.voucherEnabled = false,
    this.cashbackEnabled = false,
    this.referralEnabled = false,
    this.loyaltyEnabled = false,
    this.moduleRewardEnabled = const {'all': false},
    this.modulePromoEnabled = const {'all': false},
    this.moduleCouponEnabled = const {'all': false},
    this.moduleVoucherEnabled = const {'all': false},
    this.moduleCashbackEnabled = const {'all': false},
    this.moduleReferralEnabled = const {'all': false},
    this.moduleLoyaltyEnabled = const {'all': false},
    this.signupBonusEnabled = false,
    this.signupBonusPoints = 0,
    this.signupBonusCouponId,
    this.signupBonusVoucherId,
    this.firstBookingBonusEnabled = false,
    this.firstBookingBonusPoints = 0,
    this.firstBookingBonusCouponId,
    this.firstBookingBonusVoucherId,
    this.pkrValuePerPoint = 1,
    this.minimumRedeemPoints = 0,
    this.maximumRedeemPointsPerBooking,
    this.maximumRedeemPercentage = 100,
    this.maximumEarnPointsPerBooking,
    this.dailyEarnPointsLimit,
    this.monthlyEarnPointsLimit,
    this.yearlyEarnPointsLimit,
    this.dailyRedeemPointsLimit,
    this.monthlyRedeemPointsLimit,
    this.yearlyRedeemPointsLimit,
    this.expiryPolicy = RewardExpiryPolicy.never,
    this.rewardExpiryDays,
    this.expiryReminderDays = 7,
    this.allowPromoWithRewards = false,
    this.allowCouponWithRewards = false,
    this.allowVoucherWithRewards = false,
    this.allowCashbackWithRewards = true,
    this.allowPromoWithCoupon = false,
    this.allowPromoWithVoucher = false,
    this.allowCouponWithVoucher = false,
    this.requireCompletedBooking = true,
    this.requireSuccessfulPayment = true,
    this.reverseRewardOnCancellation = true,
    this.reverseRewardOnRefund = true,
    this.preventNegativeRewardBalance = true,
    this.duplicateRewardProtectionEnabled = true,
    this.rewardNotificationsEnabled = true,
    this.expiryNotificationsEnabled = true,
    this.loyaltyUpgradeNotificationsEnabled = true,
    this.aiRecommendationsEnabled = false,
    this.aiAutoApplyEnabled = false,
    required this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
    this.version = 0,
    this.metadata = const {},
  });

  bool get hasValidConfiguration {
    if (pkrValuePerPoint <= 0) {
      return false;
    }

    if (minimumRedeemPoints < 0) {
      return false;
    }

    if (maximumRedeemPointsPerBooking != null &&
        maximumRedeemPointsPerBooking! < 0) {
      return false;
    }

    if (maximumRedeemPercentage < 0 ||
        maximumRedeemPercentage > 100) {
      return false;
    }

    if (signupBonusPoints < 0 ||
        firstBookingBonusPoints < 0) {
      return false;
    }

    if (expiryReminderDays < 0) {
      return false;
    }

    if (expiryPolicy == RewardExpiryPolicy.customDays &&
        (rewardExpiryDays == null || rewardExpiryDays! <= 0)) {
      return false;
    }

    return true;
  }

  bool isRewardEnabledForModule(RewardModule module) {
    return rewardsEnabled &&
        _isModuleEnabled(moduleRewardEnabled, module);
  }

  bool isPromoEnabledForModule(RewardModule module) {
    return promoEnabled &&
        _isModuleEnabled(modulePromoEnabled, module);
  }

  bool isCouponEnabledForModule(RewardModule module) {
    return couponEnabled &&
        _isModuleEnabled(moduleCouponEnabled, module);
  }

  bool isVoucherEnabledForModule(RewardModule module) {
    return voucherEnabled &&
        _isModuleEnabled(moduleVoucherEnabled, module);
  }

  bool isCashbackEnabledForModule(RewardModule module) {
    return cashbackEnabled &&
        _isModuleEnabled(moduleCashbackEnabled, module);
  }

  bool isReferralEnabledForModule(RewardModule module) {
    return referralEnabled &&
        _isModuleEnabled(moduleReferralEnabled, module);
  }

  bool isLoyaltyEnabledForModule(RewardModule module) {
    return loyaltyEnabled &&
        _isModuleEnabled(moduleLoyaltyEnabled, module);
  }

  bool _isModuleEnabled(
    Map<String, bool> settings,
    RewardModule module,
  ) {
    if (settings.containsKey(module.name)) {
      return settings[module.name] ?? false;
    }

    return settings[RewardModule.all.name] ?? false;
  }

  bool canRedeemPoints({
    required RewardModule module,
    required int requestedPoints,
    required int availablePoints,
    required int redeemedToday,
    required int redeemedThisMonth,
    required int redeemedThisYear,
  }) {
    if (!isRewardEnabledForModule(module)) {
      return false;
    }

    if (!hasValidConfiguration) {
      return false;
    }

    if (requestedPoints <= 0 ||
        requestedPoints < minimumRedeemPoints) {
      return false;
    }

    if (availablePoints < requestedPoints) {
      return false;
    }

    if (maximumRedeemPointsPerBooking != null &&
        requestedPoints > maximumRedeemPointsPerBooking!) {
      return false;
    }

    if (dailyRedeemPointsLimit != null &&
        redeemedToday + requestedPoints >
            dailyRedeemPointsLimit!) {
      return false;
    }

    if (monthlyRedeemPointsLimit != null &&
        redeemedThisMonth + requestedPoints >
            monthlyRedeemPointsLimit!) {
      return false;
    }

    if (yearlyRedeemPointsLimit != null &&
        redeemedThisYear + requestedPoints >
            yearlyRedeemPointsLimit!) {
      return false;
    }

    return true;
  }

  int applyEarnLimits({
    required int calculatedPoints,
    required int earnedToday,
    required int earnedThisMonth,
    required int earnedThisYear,
  }) {
    if (calculatedPoints <= 0) {
      return 0;
    }

    var allowedPoints = calculatedPoints;

    if (maximumEarnPointsPerBooking != null &&
        allowedPoints > maximumEarnPointsPerBooking!) {
      allowedPoints = maximumEarnPointsPerBooking!;
    }

    if (dailyEarnPointsLimit != null) {
      final remaining =
          dailyEarnPointsLimit! - earnedToday;

      if (remaining <= 0) {
        return 0;
      }

      if (allowedPoints > remaining) {
        allowedPoints = remaining;
      }
    }

    if (monthlyEarnPointsLimit != null) {
      final remaining =
          monthlyEarnPointsLimit! - earnedThisMonth;

      if (remaining <= 0) {
        return 0;
      }

      if (allowedPoints > remaining) {
        allowedPoints = remaining;
      }
    }

    if (yearlyEarnPointsLimit != null) {
      final remaining =
          yearlyEarnPointsLimit! - earnedThisYear;

      if (remaining <= 0) {
        return 0;
      }

      if (allowedPoints > remaining) {
        allowedPoints = remaining;
      }
    }

    return allowedPoints < 0 ? 0 : allowedPoints;
  }

  double calculatePointsDiscount({
    required int points,
    required double eligibleAmount,
  }) {
    if (points <= 0 || eligibleAmount <= 0) {
      return 0;
    }

    var discount = points * pkrValuePerPoint;

    final maximumAllowedDiscount =
        eligibleAmount * (maximumRedeemPercentage / 100);

    if (discount > maximumAllowedDiscount) {
      discount = maximumAllowedDiscount;
    }

    if (discount > eligibleAmount) {
      discount = eligibleAmount;
    }

    return discount < 0 ? 0 : discount;
  }

  DateTime? calculateRewardExpiry(DateTime earnedAt) {
    if (expiryPolicy == RewardExpiryPolicy.never) {
      return null;
    }

    if (rewardExpiryDays == null || rewardExpiryDays! <= 0) {
      return null;
    }

    return earnedAt.add(Duration(days: rewardExpiryDays!));
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rewardsEnabled': rewardsEnabled,
      'promoEnabled': promoEnabled,
      'couponEnabled': couponEnabled,
      'voucherEnabled': voucherEnabled,
      'cashbackEnabled': cashbackEnabled,
      'referralEnabled': referralEnabled,
      'loyaltyEnabled': loyaltyEnabled,
      'moduleRewardEnabled': moduleRewardEnabled,
      'modulePromoEnabled': modulePromoEnabled,
      'moduleCouponEnabled': moduleCouponEnabled,
      'moduleVoucherEnabled': moduleVoucherEnabled,
      'moduleCashbackEnabled': moduleCashbackEnabled,
      'moduleReferralEnabled': moduleReferralEnabled,
      'moduleLoyaltyEnabled': moduleLoyaltyEnabled,
      'signupBonusEnabled': signupBonusEnabled,
      'signupBonusPoints': signupBonusPoints,
      'signupBonusCouponId': signupBonusCouponId,
      'signupBonusVoucherId': signupBonusVoucherId,
      'firstBookingBonusEnabled':
          firstBookingBonusEnabled,
      'firstBookingBonusPoints':
          firstBookingBonusPoints,
      'firstBookingBonusCouponId':
          firstBookingBonusCouponId,
      'firstBookingBonusVoucherId':
          firstBookingBonusVoucherId,
      'pkrValuePerPoint': pkrValuePerPoint,
      'minimumRedeemPoints': minimumRedeemPoints,
      'maximumRedeemPointsPerBooking':
          maximumRedeemPointsPerBooking,
      'maximumRedeemPercentage':
          maximumRedeemPercentage,
      'maximumEarnPointsPerBooking':
          maximumEarnPointsPerBooking,
      'dailyEarnPointsLimit': dailyEarnPointsLimit,
      'monthlyEarnPointsLimit': monthlyEarnPointsLimit,
      'yearlyEarnPointsLimit': yearlyEarnPointsLimit,
      'dailyRedeemPointsLimit': dailyRedeemPointsLimit,
      'monthlyRedeemPointsLimit':
          monthlyRedeemPointsLimit,
      'yearlyRedeemPointsLimit':
          yearlyRedeemPointsLimit,
      'expiryPolicy': expiryPolicy.name,
      'rewardExpiryDays': rewardExpiryDays,
      'expiryReminderDays': expiryReminderDays,
      'allowPromoWithRewards': allowPromoWithRewards,
      'allowCouponWithRewards': allowCouponWithRewards,
      'allowVoucherWithRewards':
          allowVoucherWithRewards,
      'allowCashbackWithRewards':
          allowCashbackWithRewards,
      'allowPromoWithCoupon': allowPromoWithCoupon,
      'allowPromoWithVoucher': allowPromoWithVoucher,
      'allowCouponWithVoucher': allowCouponWithVoucher,
      'requireCompletedBooking': requireCompletedBooking,
      'requireSuccessfulPayment':
          requireSuccessfulPayment,
      'reverseRewardOnCancellation':
          reverseRewardOnCancellation,
      'reverseRewardOnRefund': reverseRewardOnRefund,
      'preventNegativeRewardBalance':
          preventNegativeRewardBalance,
      'duplicateRewardProtectionEnabled':
          duplicateRewardProtectionEnabled,
      'rewardNotificationsEnabled':
          rewardNotificationsEnabled,
      'expiryNotificationsEnabled':
          expiryNotificationsEnabled,
      'loyaltyUpgradeNotificationsEnabled':
          loyaltyUpgradeNotificationsEnabled,
      'aiRecommendationsEnabled':
          aiRecommendationsEnabled,
      'aiAutoApplyEnabled': aiAutoApplyEnabled,
      'updatedBy': updatedBy,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'version': version,
      'metadata': metadata,
    };
  }

  factory RewardSettingsModel.fromMap(
    Map<String, dynamic> map,
  ) {
    final now = DateTime.now();

    return RewardSettingsModel(
      id: map['id']?.toString() ?? 'global_rewards',
      rewardsEnabled:
          map['rewardsEnabled'] as bool? ?? false,
      promoEnabled:
          map['promoEnabled'] as bool? ?? false,
      couponEnabled:
          map['couponEnabled'] as bool? ?? false,
      voucherEnabled:
          map['voucherEnabled'] as bool? ?? false,
      cashbackEnabled:
          map['cashbackEnabled'] as bool? ?? false,
      referralEnabled:
          map['referralEnabled'] as bool? ?? false,
      loyaltyEnabled:
          map['loyaltyEnabled'] as bool? ?? false,
      moduleRewardEnabled:
          _boolMapFromValue(map['moduleRewardEnabled']),
      modulePromoEnabled:
          _boolMapFromValue(map['modulePromoEnabled']),
      moduleCouponEnabled:
          _boolMapFromValue(map['moduleCouponEnabled']),
      moduleVoucherEnabled:
          _boolMapFromValue(map['moduleVoucherEnabled']),
      moduleCashbackEnabled:
          _boolMapFromValue(map['moduleCashbackEnabled']),
      moduleReferralEnabled:
          _boolMapFromValue(map['moduleReferralEnabled']),
      moduleLoyaltyEnabled:
          _boolMapFromValue(map['moduleLoyaltyEnabled']),
      signupBonusEnabled:
          map['signupBonusEnabled'] as bool? ?? false,
      signupBonusPoints:
          (map['signupBonusPoints'] as num?)?.toInt() ?? 0,
      signupBonusCouponId:
          map['signupBonusCouponId']?.toString(),
      signupBonusVoucherId:
          map['signupBonusVoucherId']?.toString(),
      firstBookingBonusEnabled:
          map['firstBookingBonusEnabled'] as bool? ?? false,
      firstBookingBonusPoints:
          (map['firstBookingBonusPoints'] as num?)
                  ?.toInt() ??
              0,
      firstBookingBonusCouponId:
          map['firstBookingBonusCouponId']?.toString(),
      firstBookingBonusVoucherId:
          map['firstBookingBonusVoucherId']?.toString(),
      pkrValuePerPoint:
          (map['pkrValuePerPoint'] as num?)?.toDouble() ??
              1,
      minimumRedeemPoints:
          (map['minimumRedeemPoints'] as num?)?.toInt() ??
              0,
      maximumRedeemPointsPerBooking:
          (map['maximumRedeemPointsPerBooking'] as num?)
              ?.toInt(),
      maximumRedeemPercentage:
          (map['maximumRedeemPercentage'] as num?)
                  ?.toDouble() ??
              100,
      maximumEarnPointsPerBooking:
          (map['maximumEarnPointsPerBooking'] as num?)
              ?.toInt(),
      dailyEarnPointsLimit:
          (map['dailyEarnPointsLimit'] as num?)?.toInt(),
      monthlyEarnPointsLimit:
          (map['monthlyEarnPointsLimit'] as num?)?.toInt(),
      yearlyEarnPointsLimit:
          (map['yearlyEarnPointsLimit'] as num?)?.toInt(),
      dailyRedeemPointsLimit:
          (map['dailyRedeemPointsLimit'] as num?)?.toInt(),
      monthlyRedeemPointsLimit:
          (map['monthlyRedeemPointsLimit'] as num?)
              ?.toInt(),
      yearlyRedeemPointsLimit:
          (map['yearlyRedeemPointsLimit'] as num?)?.toInt(),
      expiryPolicy: _expiryPolicyFromString(
        map['expiryPolicy']?.toString(),
      ),
      rewardExpiryDays:
          (map['rewardExpiryDays'] as num?)?.toInt(),
      expiryReminderDays:
          (map['expiryReminderDays'] as num?)?.toInt() ?? 7,
      allowPromoWithRewards:
          map['allowPromoWithRewards'] as bool? ?? false,
      allowCouponWithRewards:
          map['allowCouponWithRewards'] as bool? ?? false,
      allowVoucherWithRewards:
          map['allowVoucherWithRewards'] as bool? ?? false,
      allowCashbackWithRewards:
          map['allowCashbackWithRewards'] as bool? ?? true,
      allowPromoWithCoupon:
          map['allowPromoWithCoupon'] as bool? ?? false,
      allowPromoWithVoucher:
          map['allowPromoWithVoucher'] as bool? ?? false,
      allowCouponWithVoucher:
          map['allowCouponWithVoucher'] as bool? ?? false,
      requireCompletedBooking:
          map['requireCompletedBooking'] as bool? ?? true,
      requireSuccessfulPayment:
          map['requireSuccessfulPayment'] as bool? ?? true,
      reverseRewardOnCancellation:
          map['reverseRewardOnCancellation'] as bool? ??
              true,
      reverseRewardOnRefund:
          map['reverseRewardOnRefund'] as bool? ?? true,
      preventNegativeRewardBalance:
          map['preventNegativeRewardBalance'] as bool? ??
              true,
      duplicateRewardProtectionEnabled:
          map['duplicateRewardProtectionEnabled'] as bool? ??
              true,
      rewardNotificationsEnabled:
          map['rewardNotificationsEnabled'] as bool? ?? true,
      expiryNotificationsEnabled:
          map['expiryNotificationsEnabled'] as bool? ?? true,
      loyaltyUpgradeNotificationsEnabled:
          map['loyaltyUpgradeNotificationsEnabled']
                  as bool? ??
              true,
      aiRecommendationsEnabled:
          map['aiRecommendationsEnabled'] as bool? ?? false,

      /// Safety rule: AI never automatically applies benefits.
      aiAutoApplyEnabled: false,
      updatedBy: map['updatedBy']?.toString() ?? '',
      createdAt: _dateFromValue(map['createdAt']) ?? now,
      updatedAt: _dateFromValue(map['updatedAt']) ?? now,
      version: (map['version'] as num?)?.toInt() ?? 0,
      metadata: Map<String, dynamic>.from(
        map['metadata'] as Map? ?? const {},
      ),
    );
  }

  static Map<String, bool> _boolMapFromValue(dynamic value) {
    if (value is! Map) {
      return const {'all': false};
    }

    final result = <String, bool>{};

    value.forEach((key, item) {
      result[key.toString()] = item == true;
    });

    if (result.isEmpty) {
      return const {'all': false};
    }

    return result;
  }

  static RewardExpiryPolicy _expiryPolicyFromString(
    String? value,
  ) {
    return RewardExpiryPolicy.values.firstWhere(
      (policy) => policy.name == value,
      orElse: () => RewardExpiryPolicy.never,
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