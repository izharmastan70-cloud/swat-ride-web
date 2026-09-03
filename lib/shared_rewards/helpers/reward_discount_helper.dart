// =============================================================
// SWAT RIDE - GLOBAL LOYALTY, REWARDS & PROMO ENGINE
// File: lib/shared_rewards/helpers/reward_discount_helper.dart
//
// Compares discounts and validates Admin-controlled stacking rules.
// It never applies a discount or finalizes payment automatically.
// =============================================================

import '../../rewards/models/reward_point_model.dart';
import 'reward_module_helper.dart';

enum RewardBenefitType {
  promo,
  coupon,
  voucher,
  rewardRedemption,
  cashback,
}

enum RewardDiscountValueType {
  percentage,
  fixedAmount,
}

class RewardDiscountCandidate {
  final String id;
  final String code;
  final String title;
  final RewardBenefitType type;
  final RewardDiscountValueType valueType;
  final double value;
  final double minimumAmount;
  final double? maximumDiscount;
  final List<RewardModule> supportedModules;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? expiryDate;
  final int priority;
  final Map<String, dynamic> metadata;

  const RewardDiscountCandidate({
    required this.id,
    this.code = '',
    required this.title,
    required this.type,
    required this.valueType,
    required this.value,
    this.minimumAmount = 0,
    this.maximumDiscount,
    this.supportedModules = const [RewardModule.all],
    this.isActive = true,
    this.startDate,
    this.expiryDate,
    this.priority = 0,
    this.metadata = const {},
  });

  bool isValidFor({
    required double eligibleAmount,
    required RewardModule module,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();

    if (!isActive || id.trim().isEmpty || title.trim().isEmpty) {
      return false;
    }

    if (!value.isFinite || value <= 0 || minimumAmount < 0) {
      return false;
    }

    if (valueType == RewardDiscountValueType.percentage && value > 100) {
      return false;
    }

    if (maximumDiscount != null && maximumDiscount! < 0) {
      return false;
    }

    if (eligibleAmount <= 0 || eligibleAmount < minimumAmount) {
      return false;
    }

    if (!RewardModuleHelper.supportsModule(
      supportedModules: supportedModules,
      selectedModule: module,
    )) {
      return false;
    }

    if (startDate != null && currentTime.isBefore(startDate!)) {
      return false;
    }

    if (expiryDate != null && currentTime.isAfter(expiryDate!)) {
      return false;
    }

    if (startDate != null &&
        expiryDate != null &&
        expiryDate!.isBefore(startDate!)) {
      return false;
    }

    return true;
  }

  double calculate({
    required double eligibleAmount,
    required RewardModule module,
    DateTime? now,
  }) {
    if (!isValidFor(
      eligibleAmount: eligibleAmount,
      module: module,
      now: now,
    )) {
      return 0;
    }

    var discount = valueType == RewardDiscountValueType.percentage
        ? eligibleAmount * (value / 100)
        : value;

    if (maximumDiscount != null && discount > maximumDiscount!) {
      discount = maximumDiscount!;
    }

    if (discount > eligibleAmount) {
      discount = eligibleAmount;
    }

    return RewardDiscountHelper.money(discount);
  }
}

class RewardStackingPolicy {
  final bool allowPromoWithCoupon;
  final bool allowPromoWithVoucher;
  final bool allowPromoWithRewardRedemption;
  final bool allowCouponWithVoucher;
  final bool allowCouponWithRewardRedemption;
  final bool allowVoucherWithRewardRedemption;
  final bool allowCashbackWithPromo;
  final bool allowCashbackWithCoupon;
  final bool allowCashbackWithVoucher;
  final bool allowCashbackWithRewardRedemption;
  final int maximumBenefitsPerBooking;
  final double? maximumTotalDiscount;
  final double? maximumDiscountPercentage;

  const RewardStackingPolicy({
    this.allowPromoWithCoupon = false,
    this.allowPromoWithVoucher = false,
    this.allowPromoWithRewardRedemption = false,
    this.allowCouponWithVoucher = false,
    this.allowCouponWithRewardRedemption = false,
    this.allowVoucherWithRewardRedemption = false,
    this.allowCashbackWithPromo = true,
    this.allowCashbackWithCoupon = true,
    this.allowCashbackWithVoucher = true,
    this.allowCashbackWithRewardRedemption = false,
    this.maximumBenefitsPerBooking = 1,
    this.maximumTotalDiscount,
    this.maximumDiscountPercentage,
  });

  bool allowsPair(RewardBenefitType first, RewardBenefitType second) {
    if (first == second) {
      return false;
    }

    final pair = {first, second};

    if (pair.contains(RewardBenefitType.promo) &&
        pair.contains(RewardBenefitType.coupon)) {
      return allowPromoWithCoupon;
    }

    if (pair.contains(RewardBenefitType.promo) &&
        pair.contains(RewardBenefitType.voucher)) {
      return allowPromoWithVoucher;
    }

    if (pair.contains(RewardBenefitType.promo) &&
        pair.contains(RewardBenefitType.rewardRedemption)) {
      return allowPromoWithRewardRedemption;
    }

    if (pair.contains(RewardBenefitType.coupon) &&
        pair.contains(RewardBenefitType.voucher)) {
      return allowCouponWithVoucher;
    }

    if (pair.contains(RewardBenefitType.coupon) &&
        pair.contains(RewardBenefitType.rewardRedemption)) {
      return allowCouponWithRewardRedemption;
    }

    if (pair.contains(RewardBenefitType.voucher) &&
        pair.contains(RewardBenefitType.rewardRedemption)) {
      return allowVoucherWithRewardRedemption;
    }

    if (pair.contains(RewardBenefitType.cashback)) {
      final other = pair.firstWhere(
        (type) => type != RewardBenefitType.cashback,
        orElse: () => RewardBenefitType.cashback,
      );

      switch (other) {
        case RewardBenefitType.promo:
          return allowCashbackWithPromo;
        case RewardBenefitType.coupon:
          return allowCashbackWithCoupon;
        case RewardBenefitType.voucher:
          return allowCashbackWithVoucher;
        case RewardBenefitType.rewardRedemption:
          return allowCashbackWithRewardRedemption;
        case RewardBenefitType.cashback:
          return false;
      }
    }

    return false;
  }

  double maximumAllowedDiscount(double eligibleAmount) {
    var maximum = eligibleAmount < 0 ? 0.0 : eligibleAmount;

    if (maximumDiscountPercentage != null) {
      final percentage =
          maximumDiscountPercentage!.clamp(0, 100).toDouble();
      final percentageLimit = eligibleAmount * (percentage / 100);

      if (percentageLimit < maximum) {
        maximum = percentageLimit;
      }
    }

    if (maximumTotalDiscount != null && maximumTotalDiscount! < maximum) {
      maximum = maximumTotalDiscount!.clamp(0, eligibleAmount).toDouble();
    }

    return RewardDiscountHelper.money(maximum);
  }
}

class RewardDiscountSelection {
  final RewardDiscountCandidate candidate;
  final double calculatedAmount;

  const RewardDiscountSelection({
    required this.candidate,
    required this.calculatedAmount,
  });
}

class RewardDiscountRecommendation {
  final List<RewardDiscountSelection> selections;
  final double eligibleAmount;
  final double totalDiscount;
  final double payableAmount;
  final String message;
  final bool requiresUserConfirmation;
  final bool requiresAdminConfirmation;
  final List<String> warnings;

  const RewardDiscountRecommendation({
    required this.selections,
    required this.eligibleAmount,
    required this.totalDiscount,
    required this.payableAmount,
    required this.message,
    this.requiresUserConfirmation = true,
    this.requiresAdminConfirmation = false,
    this.warnings = const [],
  });

  bool get hasBenefit => selections.isNotEmpty && totalDiscount > 0;

  /// This object is a recommendation only and is never auto-approved.
  bool get canAutoApply => false;
}

class RewardDiscountValidationResult {
  final bool isValid;
  final String message;
  final List<String> errors;

  const RewardDiscountValidationResult({
    required this.isValid,
    required this.message,
    this.errors = const [],
  });

  const RewardDiscountValidationResult.valid()
      : isValid = true,
        message = 'Selected benefits are valid.',
        errors = const [];

  const RewardDiscountValidationResult.invalid(
    this.message,
    this.errors,
  ) : isValid = false;
}

class RewardDiscountHelper {
  const RewardDiscountHelper._();

  static List<RewardDiscountSelection> validSelections({
    required Iterable<RewardDiscountCandidate> candidates,
    required double eligibleAmount,
    required RewardModule module,
    DateTime? now,
  }) {
    final selections = <RewardDiscountSelection>[];

    for (final candidate in candidates) {
      final amount = candidate.calculate(
        eligibleAmount: eligibleAmount,
        module: module,
        now: now,
      );

      if (amount > 0) {
        selections.add(
          RewardDiscountSelection(
            candidate: candidate,
            calculatedAmount: amount,
          ),
        );
      }
    }

    selections.sort((first, second) {
      final amountComparison =
          second.calculatedAmount.compareTo(first.calculatedAmount);

      if (amountComparison != 0) {
        return amountComparison;
      }

      return second.candidate.priority.compareTo(first.candidate.priority);
    });

    return selections;
  }

  static RewardDiscountRecommendation recommendBest({
    required Iterable<RewardDiscountCandidate> candidates,
    required double eligibleAmount,
    required RewardModule module,
    required RewardStackingPolicy policy,
    DateTime? now,
  }) {
    final warnings = <String>[];

    if (!eligibleAmount.isFinite || eligibleAmount <= 0) {
      return const RewardDiscountRecommendation(
        selections: [],
        eligibleAmount: 0,
        totalDiscount: 0,
        payableAmount: 0,
        message: 'No eligible amount is available for a benefit.',
        warnings: ['Eligible amount must be greater than zero.'],
      );
    }

    final available = validSelections(
      candidates: candidates,
      eligibleAmount: eligibleAmount,
      module: module,
      now: now,
    );

    if (available.isEmpty) {
      return RewardDiscountRecommendation(
        selections: const [],
        eligibleAmount: money(eligibleAmount),
        totalDiscount: 0,
        payableAmount: money(eligibleAmount),
        message: 'No valid benefit is available for this booking.',
      );
    }

    final maximumCount = policy.maximumBenefitsPerBooking < 1
        ? 1
        : policy.maximumBenefitsPerBooking;
    final selected = <RewardDiscountSelection>[];

    for (final option in available) {
      if (selected.length >= maximumCount) {
        break;
      }

      final compatible = selected.every(
        (current) => policy.allowsPair(
          current.candidate.type,
          option.candidate.type,
        ),
      );

      if (selected.isEmpty || compatible) {
        selected.add(option);
      }
    }

    final rawTotal = selected.fold<double>(
      0,
      (total, selection) => total + selection.calculatedAmount,
    );
    final maximumAllowed = policy.maximumAllowedDiscount(eligibleAmount);
    final total = rawTotal > maximumAllowed ? maximumAllowed : rawTotal;

    if (rawTotal > maximumAllowed) {
      warnings.add('Total benefit was capped by the Admin discount limit.');
    }

    final payable = money(eligibleAmount - total);

    return RewardDiscountRecommendation(
      selections: List.unmodifiable(selected),
      eligibleAmount: money(eligibleAmount),
      totalDiscount: money(total),
      payableAmount: payable < 0 ? 0 : payable,
      message: selected.length == 1
          ? '${selected.first.candidate.title} gives the best saving.'
          : '${selected.length} compatible benefits give the best saving.',
      warnings: List.unmodifiable(warnings),
    );
  }

  static RewardDiscountValidationResult validateSelection({
    required Iterable<RewardDiscountSelection> selections,
    required double eligibleAmount,
    required RewardStackingPolicy policy,
    required bool userConfirmed,
    required bool adminConfirmedOverride,
  }) {
    final selected = selections.toList();
    final errors = <String>[];

    if (!eligibleAmount.isFinite || eligibleAmount < 0) {
      errors.add('Eligible amount is invalid.');
    }

    if (selected.length > policy.maximumBenefitsPerBooking) {
      errors.add('Selected benefits exceed the Admin limit.');
    }

    for (var first = 0; first < selected.length; first++) {
      if (selected[first].calculatedAmount < 0) {
        errors.add('A selected discount amount is invalid.');
      }

      for (var second = first + 1; second < selected.length; second++) {
        if (!policy.allowsPair(
          selected[first].candidate.type,
          selected[second].candidate.type,
        )) {
          errors.add(
            '${label(selected[first].candidate.type)} cannot be used with '
            '${label(selected[second].candidate.type)}.',
          );
        }
      }
    }

    final total = selected.fold<double>(
      0,
      (sum, selection) => sum + selection.calculatedAmount,
    );

    if (total > policy.maximumAllowedDiscount(eligibleAmount)) {
      errors.add('Total discount exceeds the Admin limit.');
    }

    if (selected.isNotEmpty && !userConfirmed && !adminConfirmedOverride) {
      errors.add('User or Admin confirmation is required.');
    }

    if (errors.isEmpty) {
      return const RewardDiscountValidationResult.valid();
    }

    return RewardDiscountValidationResult.invalid(
      errors.first,
      List.unmodifiable(errors),
    );
  }

  static RewardDiscountSelection? bestOfType({
    required Iterable<RewardDiscountCandidate> candidates,
    required RewardBenefitType type,
    required double eligibleAmount,
    required RewardModule module,
    DateTime? now,
  }) {
    final matches = validSelections(
      candidates: candidates.where((candidate) => candidate.type == type),
      eligibleAmount: eligibleAmount,
      module: module,
      now: now,
    );

    return matches.isEmpty ? null : matches.first;
  }

  static double money(double value) {
    if (!value.isFinite || value <= 0) {
      return 0;
    }

    return (value * 100).round() / 100;
  }

  static String label(RewardBenefitType type) {
    switch (type) {
      case RewardBenefitType.promo:
        return 'Promo';
      case RewardBenefitType.coupon:
        return 'Coupon';
      case RewardBenefitType.voucher:
        return 'Voucher';
      case RewardBenefitType.rewardRedemption:
        return 'Reward Redemption';
      case RewardBenefitType.cashback:
        return 'Cashback';
    }
  }
}
