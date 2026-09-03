// =============================================================
// SWAT RIDE - GLOBAL LOYALTY, REWARDS & PROMO ENGINE
// File: lib/shared_rewards/helpers/reward_booking_helper.dart
//
// Shared booking/order context and safety helpers for every module.
// This helper never applies a discount or completes a payment itself.
// =============================================================

import '../../rewards/models/reward_point_model.dart';
import 'reward_module_helper.dart';

enum RewardBookingStatus {
  draft,
  awaitingConfirmation,
  paymentPending,
  confirmed,
  inProgress,
  completed,
  cancelled,
  refunded,
  failed,
}

enum RewardBookingAction {
  promoCheck,
  couponCheck,
  voucherCheck,
  rewardRedemption,
  cashbackCheck,
  payment,
  rewardEarning,
  walletUpdate,
  notification,
  aiSummary,
}

class RewardBookingContext {
  final String bookingId;
  final String userId;
  final RewardModule module;
  final RewardBookingStatus status;

  /// Original booking/order total before any benefit.
  final double grossAmount;

  /// Amounts which are not eligible for reward calculation.
  final double taxAmount;
  final double tipAmount;
  final double deliveryFee;
  final double serviceFee;

  /// Confirmed discounts only. Recommendations are not stored here.
  final double promoDiscount;
  final double couponDiscount;
  final double voucherDiscount;
  final double rewardRedemptionAmount;

  final String paymentMethod;
  final bool paymentConfirmed;
  final bool userConfirmedBenefits;
  final bool adminConfirmedOverride;

  final DateTime createdAt;
  final DateTime? completedAt;

  final Map<String, dynamic> metadata;

  const RewardBookingContext({
    required this.bookingId,
    required this.userId,
    required this.module,
    this.status = RewardBookingStatus.draft,
    required this.grossAmount,
    this.taxAmount = 0,
    this.tipAmount = 0,
    this.deliveryFee = 0,
    this.serviceFee = 0,
    this.promoDiscount = 0,
    this.couponDiscount = 0,
    this.voucherDiscount = 0,
    this.rewardRedemptionAmount = 0,
    this.paymentMethod = '',
    this.paymentConfirmed = false,
    this.userConfirmedBenefits = false,
    this.adminConfirmedOverride = false,
    required this.createdAt,
    this.completedAt,
    this.metadata = const {},
  });

  double get totalDiscount {
    return promoDiscount +
        couponDiscount +
        voucherDiscount +
        rewardRedemptionAmount;
  }

  double get payableAmount {
    return RewardBookingHelper.nonNegative(grossAmount - totalDiscount);
  }

  double get eligibleRewardAmount {
    final excluded = taxAmount + tipAmount + deliveryFee + serviceFee;
    return RewardBookingHelper.nonNegative(payableAmount - excluded);
  }

  bool get isCompleted {
    return status == RewardBookingStatus.completed;
  }

  bool get isCancelledOrRefunded {
    return status == RewardBookingStatus.cancelled ||
        status == RewardBookingStatus.refunded;
  }

  bool get hasAnyDiscount => totalDiscount > 0;

  RewardBookingContext copyWith({
    String? bookingId,
    String? userId,
    RewardModule? module,
    RewardBookingStatus? status,
    double? grossAmount,
    double? taxAmount,
    double? tipAmount,
    double? deliveryFee,
    double? serviceFee,
    double? promoDiscount,
    double? couponDiscount,
    double? voucherDiscount,
    double? rewardRedemptionAmount,
    String? paymentMethod,
    bool? paymentConfirmed,
    bool? userConfirmedBenefits,
    bool? adminConfirmedOverride,
    DateTime? createdAt,
    DateTime? completedAt,
    bool removeCompletedAt = false,
    Map<String, dynamic>? metadata,
  }) {
    return RewardBookingContext(
      bookingId: bookingId ?? this.bookingId,
      userId: userId ?? this.userId,
      module: module ?? this.module,
      status: status ?? this.status,
      grossAmount: grossAmount ?? this.grossAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      tipAmount: tipAmount ?? this.tipAmount,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      serviceFee: serviceFee ?? this.serviceFee,
      promoDiscount: promoDiscount ?? this.promoDiscount,
      couponDiscount: couponDiscount ?? this.couponDiscount,
      voucherDiscount: voucherDiscount ?? this.voucherDiscount,
      rewardRedemptionAmount:
          rewardRedemptionAmount ?? this.rewardRedemptionAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentConfirmed: paymentConfirmed ?? this.paymentConfirmed,
      userConfirmedBenefits:
          userConfirmedBenefits ?? this.userConfirmedBenefits,
      adminConfirmedOverride:
          adminConfirmedOverride ?? this.adminConfirmedOverride,
      createdAt: createdAt ?? this.createdAt,
      completedAt:
          removeCompletedAt ? null : completedAt ?? this.completedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'userId': userId,
      'module': module.name,
      'status': status.name,
      'grossAmount': grossAmount,
      'taxAmount': taxAmount,
      'tipAmount': tipAmount,
      'deliveryFee': deliveryFee,
      'serviceFee': serviceFee,
      'promoDiscount': promoDiscount,
      'couponDiscount': couponDiscount,
      'voucherDiscount': voucherDiscount,
      'rewardRedemptionAmount': rewardRedemptionAmount,
      'totalDiscount': totalDiscount,
      'payableAmount': payableAmount,
      'eligibleRewardAmount': eligibleRewardAmount,
      'paymentMethod': paymentMethod,
      'paymentConfirmed': paymentConfirmed,
      'userConfirmedBenefits': userConfirmedBenefits,
      'adminConfirmedOverride': adminConfirmedOverride,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'metadata': metadata,
    };
  }

  factory RewardBookingContext.fromMap(Map<String, dynamic> map) {
    return RewardBookingContext(
      bookingId: map['bookingId']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      module: RewardModuleHelper.fromValue(map['module']),
      status: RewardBookingHelper.statusFromValue(map['status']),
      grossAmount: (map['grossAmount'] as num?)?.toDouble() ?? 0,
      taxAmount: (map['taxAmount'] as num?)?.toDouble() ?? 0,
      tipAmount: (map['tipAmount'] as num?)?.toDouble() ?? 0,
      deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 0,
      serviceFee: (map['serviceFee'] as num?)?.toDouble() ?? 0,
      promoDiscount: (map['promoDiscount'] as num?)?.toDouble() ?? 0,
      couponDiscount: (map['couponDiscount'] as num?)?.toDouble() ?? 0,
      voucherDiscount:
          (map['voucherDiscount'] as num?)?.toDouble() ?? 0,
      rewardRedemptionAmount:
          (map['rewardRedemptionAmount'] as num?)?.toDouble() ?? 0,
      paymentMethod: map['paymentMethod']?.toString() ?? '',
      paymentConfirmed: map['paymentConfirmed'] as bool? ?? false,
      userConfirmedBenefits:
          map['userConfirmedBenefits'] as bool? ?? false,
      adminConfirmedOverride:
          map['adminConfirmedOverride'] as bool? ?? false,
      createdAt:
          RewardBookingHelper.dateFromValue(map['createdAt']) ?? DateTime.now(),
      completedAt: RewardBookingHelper.dateFromValue(map['completedAt']),
      metadata: Map<String, dynamic>.from(
        map['metadata'] as Map? ?? const {},
      ),
    );
  }
}

class RewardBookingValidationResult {
  final bool isValid;
  final String message;
  final List<String> errors;

  const RewardBookingValidationResult({
    required this.isValid,
    required this.message,
    this.errors = const [],
  });

  const RewardBookingValidationResult.valid()
      : isValid = true,
        message = 'Booking is eligible for reward processing.',
        errors = const [];

  const RewardBookingValidationResult.invalid(
    this.message,
    this.errors,
  ) : isValid = false;
}

class RewardBookingHelper {
  const RewardBookingHelper._();

  /// Required processing order. Payment remains behind explicit confirmation.
  static const List<RewardBookingAction> processingOrder = [
    RewardBookingAction.promoCheck,
    RewardBookingAction.couponCheck,
    RewardBookingAction.voucherCheck,
    RewardBookingAction.rewardRedemption,
    RewardBookingAction.cashbackCheck,
    RewardBookingAction.payment,
    RewardBookingAction.rewardEarning,
    RewardBookingAction.walletUpdate,
    RewardBookingAction.notification,
    RewardBookingAction.aiSummary,
  ];

  static RewardBookingValidationResult validate(
    RewardBookingContext context, {
    bool requireCompletedBooking = false,
    bool requireConfirmedPayment = false,
  }) {
    final errors = <String>[];

    if (context.bookingId.trim().isEmpty) {
      errors.add('Booking/order ID is required.');
    }

    if (context.userId.trim().isEmpty) {
      errors.add('User ID is required.');
    }

    if (context.module == RewardModule.all ||
        context.module == RewardModule.future) {
      errors.add('A real booking module is required.');
    }

    if (!context.grossAmount.isFinite || context.grossAmount < 0) {
      errors.add('Gross amount must be a valid non-negative value.');
    }

    final amounts = <String, double>{
      'Tax': context.taxAmount,
      'Tip': context.tipAmount,
      'Delivery fee': context.deliveryFee,
      'Service fee': context.serviceFee,
      'Promo discount': context.promoDiscount,
      'Coupon discount': context.couponDiscount,
      'Voucher discount': context.voucherDiscount,
      'Reward redemption': context.rewardRedemptionAmount,
    };

    for (final entry in amounts.entries) {
      if (!entry.value.isFinite || entry.value < 0) {
        errors.add('${entry.key} cannot be negative or invalid.');
      }
    }

    if (context.totalDiscount > context.grossAmount) {
      errors.add('Total discount cannot exceed the booking total.');
    }

    if (context.hasAnyDiscount &&
        !context.userConfirmedBenefits &&
        !context.adminConfirmedOverride) {
      errors.add('Discount/reward use requires user or Admin confirmation.');
    }

    if (requireCompletedBooking && !context.isCompleted) {
      errors.add('Booking/order must be completed before earning rewards.');
    }

    if (requireConfirmedPayment && !context.paymentConfirmed) {
      errors.add('Payment must be confirmed before reward processing.');
    }

    if (context.isCancelledOrRefunded) {
      errors.add('Cancelled or refunded booking cannot earn new rewards.');
    }

    if (context.completedAt != null &&
        context.completedAt!.isBefore(context.createdAt)) {
      errors.add('Completion time cannot be before creation time.');
    }

    if (errors.isEmpty) {
      return const RewardBookingValidationResult.valid();
    }

    return RewardBookingValidationResult.invalid(
      errors.first,
      List.unmodifiable(errors),
    );
  }

  static bool canEarnRewards(RewardBookingContext context) {
    return validate(
      context,
      requireCompletedBooking: true,
      requireConfirmedPayment: true,
    ).isValid;
  }

  static bool canPrepareRewardPreview(RewardBookingContext context) {
    return validate(context).isValid &&
        context.status != RewardBookingStatus.failed;
  }

  /// AI recommendations may be shown, but cannot silently apply a benefit.
  static bool canApplyConfirmedBenefits(RewardBookingContext context) {
    return context.userConfirmedBenefits || context.adminConfirmedOverride;
  }

  static String earningIdempotencyKey(RewardBookingContext context) {
    return buildIdempotencyKey(
      action: 'reward_earn',
      module: context.module,
      userId: context.userId,
      bookingId: context.bookingId,
    );
  }

  static String redemptionIdempotencyKey(RewardBookingContext context) {
    return buildIdempotencyKey(
      action: 'reward_redeem',
      module: context.module,
      userId: context.userId,
      bookingId: context.bookingId,
    );
  }

  static String cashbackIdempotencyKey(RewardBookingContext context) {
    return buildIdempotencyKey(
      action: 'cashback',
      module: context.module,
      userId: context.userId,
      bookingId: context.bookingId,
    );
  }

  static String reversalIdempotencyKey(
    RewardBookingContext context, {
    required String originalTransactionId,
  }) {
    return buildIdempotencyKey(
      action: 'reward_reverse_$originalTransactionId',
      module: context.module,
      userId: context.userId,
      bookingId: context.bookingId,
    );
  }

  static String buildIdempotencyKey({
    required String action,
    required RewardModule module,
    required String userId,
    required String bookingId,
  }) {
    final parts = [
      normalizeKey(action),
      normalizeKey(module.name),
      normalizeKey(userId),
      normalizeKey(bookingId),
    ];

    return parts.join(':');
  }

  static Map<String, dynamic> sourceMetadata(
    RewardBookingContext context,
  ) {
    return {
      'sourceId': context.bookingId,
      'sourceIdKey': RewardModuleHelper.sourceIdKey(context.module),
      'sourceType': RewardModuleHelper.bookingNoun(context.module),
      'module': context.module.name,
      'grossAmount': context.grossAmount,
      'payableAmount': context.payableAmount,
      'eligibleRewardAmount': context.eligibleRewardAmount,
      'paymentMethod': context.paymentMethod,
    };
  }

  static double nonNegative(double value) {
    if (!value.isFinite || value <= 0) {
      return 0;
    }

    return value;
  }

  static RewardBookingStatus statusFromValue(
    dynamic value, {
    RewardBookingStatus fallback = RewardBookingStatus.draft,
  }) {
    final normalized = normalizeKey(value?.toString() ?? '');

    for (final status in RewardBookingStatus.values) {
      if (normalizeKey(status.name) == normalized) {
        return status;
      }
    }

    return _statusAliases[normalized] ?? fallback;
  }

  static DateTime? dateFromValue(dynamic value) {
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

  static String normalizeKey(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');

    return normalized.replaceAll(RegExp(r'^_+|_+$'), '');
  }

  static const Map<String, RewardBookingStatus> _statusAliases = {
    'pending': RewardBookingStatus.paymentPending,
    'payment_pending': RewardBookingStatus.paymentPending,
    'booked': RewardBookingStatus.confirmed,
    'accepted': RewardBookingStatus.confirmed,
    'ongoing': RewardBookingStatus.inProgress,
    'in_progress': RewardBookingStatus.inProgress,
    'complete': RewardBookingStatus.completed,
    'cancelled_by_user': RewardBookingStatus.cancelled,
    'cancelled_by_admin': RewardBookingStatus.cancelled,
    'refund': RewardBookingStatus.refunded,
  };
}
