// =============================================================
// SWAT RIDE - GLOBAL LOYALTY, REWARDS & PROMO ENGINE
// File: lib/shared_rewards/utils/reward_validation_utils.dart
//
// Shared validation for User, Admin, booking and service inputs.
// =============================================================

import '../../rewards/models/reward_point_model.dart';
import '../helpers/reward_module_helper.dart';
import 'reward_date_utils.dart';

class RewardValidationResult {
  final bool isValid;
  final String message;
  final List<String> errors;

  const RewardValidationResult({
    required this.isValid,
    required this.message,
    this.errors = const [],
  });

  const RewardValidationResult.valid([this.message = 'Valid'])
      : isValid = true,
        errors = const [];

  const RewardValidationResult.invalid(
    this.message, [
    this.errors = const [],
  ]) : isValid = false;

  static RewardValidationResult combine(
    Iterable<RewardValidationResult> results, {
    String validMessage = 'All values are valid.',
  }) {
    final errors = <String>[];

    for (final result in results) {
      if (!result.isValid) {
        if (result.errors.isNotEmpty) {
          errors.addAll(result.errors);
        } else if (result.message.trim().isNotEmpty) {
          errors.add(result.message);
        }
      }
    }

    final uniqueErrors = errors.toSet().toList();

    if (uniqueErrors.isEmpty) {
      return RewardValidationResult.valid(validMessage);
    }

    return RewardValidationResult.invalid(
      uniqueErrors.first,
      List.unmodifiable(uniqueErrors),
    );
  }
}

class RewardValidationUtils {
  const RewardValidationUtils._();

  static RewardValidationResult requiredText(
    String? value, {
    String fieldName = 'Value',
    int minimumLength = 1,
    int? maximumLength,
  }) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return RewardValidationResult.invalid('$fieldName is required.');
    }

    if (text.length < minimumLength) {
      return RewardValidationResult.invalid(
        '$fieldName must contain at least $minimumLength characters.',
      );
    }

    if (maximumLength != null && text.length > maximumLength) {
      return RewardValidationResult.invalid(
        '$fieldName cannot exceed $maximumLength characters.',
      );
    }

    return RewardValidationResult.valid('$fieldName is valid.');
  }

  static RewardValidationResult id(
    String? value, {
    String fieldName = 'ID',
    int maximumLength = 200,
  }) {
    final required = requiredText(
      value,
      fieldName: fieldName,
      maximumLength: maximumLength,
    );

    if (!required.isValid) {
      return required;
    }

    final text = value!.trim();

    if (RegExp(r'[\x00-\x1F]').hasMatch(text)) {
      return RewardValidationResult.invalid(
        '$fieldName contains invalid characters.',
      );
    }

    return RewardValidationResult.valid('$fieldName is valid.');
  }

  static RewardValidationResult promoCode(
    String? value, {
    int minimumLength = 3,
    int maximumLength = 30,
  }) {
    final text = normalizeCode(value);

    if (text.isEmpty) {
      return const RewardValidationResult.invalid(
        'Promo/coupon code is required.',
      );
    }

    if (text.length < minimumLength || text.length > maximumLength) {
      return RewardValidationResult.invalid(
        'Code must contain $minimumLength to $maximumLength characters.',
      );
    }

    if (!RegExp(r'^[A-Z0-9_-]+$').hasMatch(text)) {
      return const RewardValidationResult.invalid(
        'Code may only contain letters, numbers, hyphen and underscore.',
      );
    }

    return const RewardValidationResult.valid('Code is valid.');
  }

  static RewardValidationResult amount(
    num? value, {
    String fieldName = 'Amount',
    bool allowZero = true,
    double? minimum,
    double? maximum,
  }) {
    if (value == null || !value.toDouble().isFinite) {
      return RewardValidationResult.invalid('$fieldName is invalid.');
    }

    final number = value.toDouble();

    if (number < 0 || (!allowZero && number == 0)) {
      return RewardValidationResult.invalid(
        allowZero
            ? '$fieldName cannot be negative.'
            : '$fieldName must be greater than zero.',
      );
    }

    if (minimum != null && number < minimum) {
      return RewardValidationResult.invalid(
        '$fieldName cannot be below $minimum.',
      );
    }

    if (maximum != null && number > maximum) {
      return RewardValidationResult.invalid(
        '$fieldName cannot exceed $maximum.',
      );
    }

    return RewardValidationResult.valid('$fieldName is valid.');
  }

  static RewardValidationResult percentage(
    num? value, {
    String fieldName = 'Percentage',
    bool allowZero = true,
    double maximum = 100,
  }) {
    return amount(
      value,
      fieldName: fieldName,
      allowZero: allowZero,
      minimum: allowZero ? 0 : double.minPositive,
      maximum: maximum,
    );
  }

  static RewardValidationResult points(
    int? value, {
    String fieldName = 'Points',
    bool allowZero = true,
    int? maximum,
  }) {
    if (value == null) {
      return RewardValidationResult.invalid('$fieldName is required.');
    }

    if (value < 0 || (!allowZero && value == 0)) {
      return RewardValidationResult.invalid(
        allowZero
            ? '$fieldName cannot be negative.'
            : '$fieldName must be greater than zero.',
      );
    }

    if (maximum != null && value > maximum) {
      return RewardValidationResult.invalid(
        '$fieldName cannot exceed $maximum.',
      );
    }

    return RewardValidationResult.valid('$fieldName is valid.');
  }

  static RewardValidationResult multiplier(
    num? value, {
    double maximum = 100,
  }) {
    return amount(
      value,
      fieldName: 'Points multiplier',
      allowZero: false,
      maximum: maximum,
    );
  }

  static RewardValidationResult usageLimit(
    int? value, {
    String fieldName = 'Usage limit',
    bool optional = true,
  }) {
    if (value == null && optional) {
      return RewardValidationResult.valid('$fieldName is unlimited.');
    }

    return points(
      value,
      fieldName: fieldName,
      allowZero: false,
    );
  }

  static RewardValidationResult rewardConversion({
    required num? pkrPerPoint,
    required int? pointsPerUnit,
  }) {
    return RewardValidationResult.combine(
      [
        amount(
          pkrPerPoint,
          fieldName: 'PKR per point unit',
          allowZero: false,
        ),
        points(
          pointsPerUnit,
          fieldName: 'Points per unit',
          allowZero: false,
        ),
      ],
      validMessage: 'Reward conversion is valid.',
    );
  }

  static RewardValidationResult discountConfiguration({
    required bool isPercentage,
    required num? discountValue,
    num? minimumAmount,
    num? maximumDiscount,
  }) {
    final results = <RewardValidationResult>[
      isPercentage
          ? percentage(
              discountValue,
              fieldName: 'Discount percentage',
              allowZero: false,
            )
          : amount(
              discountValue,
              fieldName: 'Discount amount',
              allowZero: false,
            ),
    ];

    if (minimumAmount != null) {
      results.add(
        amount(minimumAmount, fieldName: 'Minimum booking amount'),
      );
    }

    if (maximumDiscount != null) {
      results.add(
        amount(maximumDiscount, fieldName: 'Maximum discount'),
      );
    }

    return RewardValidationResult.combine(
      results,
      validMessage: 'Discount configuration is valid.',
    );
  }

  static RewardValidationResult modules(
    Iterable<RewardModule>? values, {
    bool allowAll = true,
    bool allowFuture = false,
  }) {
    if (values == null || values.isEmpty) {
      return const RewardValidationResult.invalid(
        'Select at least one reward module.',
      );
    }

    final modules = values.toSet();

    if (!allowAll && modules.contains(RewardModule.all)) {
      return const RewardValidationResult.invalid(
        'All Modules is not allowed here.',
      );
    }

    if (!allowFuture && modules.contains(RewardModule.future)) {
      return const RewardValidationResult.invalid(
        'Future Module cannot be selected for an active rule.',
      );
    }

    if (modules.contains(RewardModule.all) && modules.length > 1) {
      return const RewardValidationResult.invalid(
        'Select All Modules alone or select individual modules.',
      );
    }

    return const RewardValidationResult.valid('Module selection is valid.');
  }

  static RewardValidationResult moduleValue(
    dynamic value, {
    bool allowAll = false,
    bool allowFuture = false,
  }) {
    final module = RewardModuleHelper.fromValue(value);

    if (!allowAll && module == RewardModule.all) {
      return const RewardValidationResult.invalid(
        'A specific module is required.',
      );
    }

    if (!allowFuture && module == RewardModule.future) {
      return const RewardValidationResult.invalid(
        'Unknown or future module is not allowed.',
      );
    }

    return const RewardValidationResult.valid('Module is valid.');
  }

  static RewardValidationResult dateRange({
    DateTime? startDate,
    DateTime? expiryDate,
    DateTime? createdAt,
  }) {
    final result = RewardDateUtils.validateRange(
      startDate: startDate,
      expiryDate: expiryDate,
      createdAt: createdAt,
    );

    return result.isValid
        ? const RewardValidationResult.valid('Date range is valid.')
        : RewardValidationResult.invalid(result.message);
  }

  static RewardValidationResult expiryDays(
    int? value, {
    bool allowNever = true,
    int maximumDays = 3650,
  }) {
    if (value == null || value == 0) {
      return allowNever
          ? const RewardValidationResult.valid('Reward never expires.')
          : const RewardValidationResult.invalid(
              'Reward expiry is required.',
            );
    }

    if (value < 0) {
      return const RewardValidationResult.invalid(
        'Expiry days cannot be negative.',
      );
    }

    if (value > maximumDays) {
      return RewardValidationResult.invalid(
        'Expiry cannot exceed $maximumDays days.',
      );
    }

    return const RewardValidationResult.valid('Expiry is valid.');
  }

  static RewardValidationResult periodLimits({
    num? daily,
    num? monthly,
    num? yearly,
    String unitName = 'limit',
  }) {
    final results = <RewardValidationResult>[];

    if (daily != null) {
      results.add(amount(daily, fieldName: 'Daily $unitName'));
    }

    if (monthly != null) {
      results.add(amount(monthly, fieldName: 'Monthly $unitName'));
    }

    if (yearly != null) {
      results.add(amount(yearly, fieldName: 'Yearly $unitName'));
    }

    if (daily != null && monthly != null && daily > monthly) {
      results.add(
        RewardValidationResult.invalid(
          'Daily $unitName cannot exceed monthly $unitName.',
        ),
      );
    }

    if (monthly != null && yearly != null && monthly > yearly) {
      results.add(
        RewardValidationResult.invalid(
          'Monthly $unitName cannot exceed yearly $unitName.',
        ),
      );
    }

    return RewardValidationResult.combine(
      results,
      validMessage: 'Period limits are valid.',
    );
  }

  static RewardValidationResult pointBalance({
    required int availablePoints,
    required int requestedPoints,
    int minimumRedeem = 1,
    int? maximumRedeem,
  }) {
    final errors = <String>[];

    if (availablePoints < 0) {
      errors.add('Available points cannot be negative.');
    }

    if (requestedPoints <= 0) {
      errors.add('Requested points must be greater than zero.');
    }

    if (requestedPoints < minimumRedeem) {
      errors.add('Minimum redemption is $minimumRedeem points.');
    }

    if (maximumRedeem != null && requestedPoints > maximumRedeem) {
      errors.add('Maximum redemption is $maximumRedeem points.');
    }

    if (requestedPoints > availablePoints) {
      errors.add('Insufficient reward points.');
    }

    if (errors.isEmpty) {
      return const RewardValidationResult.valid(
        'Point balance is sufficient.',
      );
    }

    return RewardValidationResult.invalid(
      errors.first,
      List.unmodifiable(errors),
    );
  }

  static RewardValidationResult metadata(
    Map<String, dynamic>? value, {
    int maximumEntries = 100,
  }) {
    if (value == null || value.isEmpty) {
      return const RewardValidationResult.valid('Metadata is empty.');
    }

    if (value.length > maximumEntries) {
      return RewardValidationResult.invalid(
        'Metadata cannot exceed $maximumEntries entries.',
      );
    }

    if (value.keys.any((key) => key.trim().isEmpty)) {
      return const RewardValidationResult.invalid(
        'Metadata keys cannot be empty.',
      );
    }

    return const RewardValidationResult.valid('Metadata is valid.');
  }

  static double? parseAmount(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      final result = value.toDouble();
      return result.isFinite ? result : null;
    }

    final normalized = value
        .toString()
        .trim()
        .replaceAll(',', '')
        .replaceAll(RegExp(r'pkr|rs\.?', caseSensitive: false), '')
        .trim();
    final result = double.tryParse(normalized);
    return result != null && result.isFinite ? result : null;
  }

  static int? parsePoints(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    final normalized = value
        ?.toString()
        .trim()
        .replaceAll(',', '')
        .replaceAll(RegExp(r'points?', caseSensitive: false), '')
        .trim();
    return int.tryParse(normalized ?? '');
  }

  static String normalizeCode(String? value) {
    return value?.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '') ?? '';
  }
}
