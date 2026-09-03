// =============================================================
// SWAT RIDE - GLOBAL LOYALTY, REWARDS & PROMO ENGINE
// File: lib/shared_rewards/utils/reward_date_utils.dart
//
// Shared date, validity and expiry utilities for all reward modules.
// =============================================================

enum RewardExpiryPreset {
  never,
  thirtyDays,
  ninetyDays,
  oneHundredEightyDays,
  oneYear,
  custom,
}

enum RewardExpiryState {
  neverExpires,
  notStarted,
  active,
  expiringSoon,
  expiresToday,
  expired,
  invalid,
}

class RewardDateRangeValidation {
  final bool isValid;
  final String message;

  const RewardDateRangeValidation({
    required this.isValid,
    required this.message,
  });

  const RewardDateRangeValidation.valid()
      : isValid = true,
        message = 'Date range is valid.';

  const RewardDateRangeValidation.invalid(this.message) : isValid = false;
}

class RewardExpiryInfo {
  final RewardExpiryState state;
  final DateTime? expiryDate;
  final Duration? remaining;
  final int? remainingDays;
  final String message;

  const RewardExpiryInfo({
    required this.state,
    required this.expiryDate,
    required this.remaining,
    required this.remainingDays,
    required this.message,
  });

  bool get isExpired => state == RewardExpiryState.expired;

  bool get isActive =>
      state == RewardExpiryState.active ||
      state == RewardExpiryState.expiringSoon ||
      state == RewardExpiryState.expiresToday ||
      state == RewardExpiryState.neverExpires;

  bool get shouldNotify =>
      state == RewardExpiryState.expiringSoon ||
      state == RewardExpiryState.expiresToday;
}

class RewardDateUtils {
  const RewardDateUtils._();

  static const int defaultWarningDays = 7;

  static int? daysForPreset(RewardExpiryPreset preset) {
    switch (preset) {
      case RewardExpiryPreset.never:
        return null;
      case RewardExpiryPreset.thirtyDays:
        return 30;
      case RewardExpiryPreset.ninetyDays:
        return 90;
      case RewardExpiryPreset.oneHundredEightyDays:
        return 180;
      case RewardExpiryPreset.oneYear:
        return 365;
      case RewardExpiryPreset.custom:
        return null;
    }
  }

  static RewardExpiryPreset presetFromDays(int? days) {
    switch (days) {
      case null:
      case 0:
        return RewardExpiryPreset.never;
      case 30:
        return RewardExpiryPreset.thirtyDays;
      case 90:
        return RewardExpiryPreset.ninetyDays;
      case 180:
        return RewardExpiryPreset.oneHundredEightyDays;
      case 365:
        return RewardExpiryPreset.oneYear;
      default:
        return RewardExpiryPreset.custom;
    }
  }

  static RewardExpiryPreset presetFromValue(dynamic value) {
    if (value is RewardExpiryPreset) {
      return value;
    }

    if (value is num) {
      return presetFromDays(value.toInt());
    }

    final normalized = value
        ?.toString()
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');

    switch (normalized) {
      case 'never':
      case 'neverexpire':
      case 'noexpiry':
      case '0':
        return RewardExpiryPreset.never;
      case '30':
      case '30days':
      case 'thirtydays':
        return RewardExpiryPreset.thirtyDays;
      case '90':
      case '90days':
      case 'ninetydays':
        return RewardExpiryPreset.ninetyDays;
      case '180':
      case '180days':
      case 'onehundredeightydays':
        return RewardExpiryPreset.oneHundredEightyDays;
      case '365':
      case '365days':
      case '1year':
      case 'oneyear':
        return RewardExpiryPreset.oneYear;
      default:
        return RewardExpiryPreset.custom;
    }
  }

  static DateTime? calculateExpiryDate({
    required DateTime earnedAt,
    required RewardExpiryPreset preset,
    int? customDays,
    bool endOfDay = true,
  }) {
    final days = preset == RewardExpiryPreset.custom
        ? customDays
        : daysForPreset(preset);

    if (preset == RewardExpiryPreset.never || days == null || days <= 0) {
      return null;
    }

    final expiry = addCalendarDays(earnedAt, days);
    return endOfDay ? endOfLocalDay(expiry) : expiry;
  }

  static DateTime addCalendarDays(DateTime date, int days) {
    if (date.isUtc) {
      return DateTime.utc(
        date.year,
        date.month,
        date.day + days,
        date.hour,
        date.minute,
        date.second,
        date.millisecond,
        date.microsecond,
      );
    }

    return DateTime(
      date.year,
      date.month,
      date.day + days,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }

  static DateTime startOfLocalDay(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static DateTime endOfLocalDay(DateTime date) {
    final local = date.toLocal();
    return DateTime(
      local.year,
      local.month,
      local.day,
      23,
      59,
      59,
      999,
      999,
    );
  }

  static DateTime startOfMonth(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month);
  }

  static DateTime endOfMonth(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month + 1)
        .subtract(const Duration(microseconds: 1));
  }

  static DateTime startOfYear(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year);
  }

  static DateTime endOfYear(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year + 1)
        .subtract(const Duration(microseconds: 1));
  }

  static RewardDateRangeValidation validateRange({
    DateTime? startDate,
    DateTime? expiryDate,
    DateTime? createdAt,
  }) {
    if (startDate != null &&
        expiryDate != null &&
        expiryDate.isBefore(startDate)) {
      return const RewardDateRangeValidation.invalid(
        'Expiry date cannot be before the start date.',
      );
    }

    if (createdAt != null &&
        expiryDate != null &&
        expiryDate.isBefore(createdAt)) {
      return const RewardDateRangeValidation.invalid(
        'Expiry date cannot be before the creation date.',
      );
    }

    return const RewardDateRangeValidation.valid();
  }

  static bool isWithinRange({
    required DateTime date,
    DateTime? startDate,
    DateTime? expiryDate,
    bool inclusive = true,
  }) {
    if (startDate != null) {
      final beforeStart = inclusive
          ? date.isBefore(startDate)
          : !date.isAfter(startDate);

      if (beforeStart) {
        return false;
      }
    }

    if (expiryDate != null) {
      final afterExpiry = inclusive
          ? date.isAfter(expiryDate)
          : !date.isBefore(expiryDate);

      if (afterExpiry) {
        return false;
      }
    }

    return true;
  }

  static RewardExpiryInfo expiryInfo({
    DateTime? startDate,
    DateTime? expiryDate,
    DateTime? now,
    int warningDays = defaultWarningDays,
  }) {
    final current = now ?? DateTime.now();

    if (startDate != null &&
        expiryDate != null &&
        expiryDate.isBefore(startDate)) {
      return RewardExpiryInfo(
        state: RewardExpiryState.invalid,
        expiryDate: expiryDate,
        remaining: null,
        remainingDays: null,
        message: 'Invalid reward date range.',
      );
    }

    if (startDate != null && current.isBefore(startDate)) {
      return RewardExpiryInfo(
        state: RewardExpiryState.notStarted,
        expiryDate: expiryDate,
        remaining: startDate.difference(current),
        remainingDays: daysUntil(startDate, now: current),
        message: 'Reward is not active yet.',
      );
    }

    if (expiryDate == null) {
      return const RewardExpiryInfo(
        state: RewardExpiryState.neverExpires,
        expiryDate: null,
        remaining: null,
        remainingDays: null,
        message: 'Reward never expires.',
      );
    }

    if (current.isAfter(expiryDate)) {
      return RewardExpiryInfo(
        state: RewardExpiryState.expired,
        expiryDate: expiryDate,
        remaining: Duration.zero,
        remainingDays: 0,
        message: 'Reward has expired.',
      );
    }

    final remaining = expiryDate.difference(current);
    final days = daysUntil(expiryDate, now: current);

    if (isSameLocalDay(current, expiryDate)) {
      return RewardExpiryInfo(
        state: RewardExpiryState.expiresToday,
        expiryDate: expiryDate,
        remaining: remaining,
        remainingDays: 0,
        message: 'Reward expires today.',
      );
    }

    if (days <= (warningDays < 0 ? 0 : warningDays)) {
      return RewardExpiryInfo(
        state: RewardExpiryState.expiringSoon,
        expiryDate: expiryDate,
        remaining: remaining,
        remainingDays: days,
        message: 'Reward expires in $days ${days == 1 ? 'day' : 'days'}.',
      );
    }

    return RewardExpiryInfo(
      state: RewardExpiryState.active,
      expiryDate: expiryDate,
      remaining: remaining,
      remainingDays: days,
      message: 'Reward is active.',
    );
  }

  static int daysUntil(DateTime target, {DateTime? now}) {
    final currentDay = startOfLocalDay(now ?? DateTime.now());
    final targetDay = startOfLocalDay(target);
    final difference = targetDay.difference(currentDay).inDays;
    return difference < 0 ? 0 : difference;
  }

  static int daysSince(DateTime date, {DateTime? now}) {
    final currentDay = startOfLocalDay(now ?? DateTime.now());
    final sourceDay = startOfLocalDay(date);
    final difference = currentDay.difference(sourceDay).inDays;
    return difference < 0 ? 0 : difference;
  }

  static bool isSameLocalDay(DateTime first, DateTime second) {
    final firstLocal = first.toLocal();
    final secondLocal = second.toLocal();

    return firstLocal.year == secondLocal.year &&
        firstLocal.month == secondLocal.month &&
        firstLocal.day == secondLocal.day;
  }

  static bool shouldSendExpiryReminder({
    required DateTime expiryDate,
    DateTime? lastReminderAt,
    DateTime? now,
    Iterable<int> reminderDays = const [30, 7, 3, 1, 0],
  }) {
    final current = now ?? DateTime.now();

    if (current.isAfter(expiryDate)) {
      return false;
    }

    if (lastReminderAt != null && isSameLocalDay(lastReminderAt, current)) {
      return false;
    }

    final remainingDays = daysUntil(expiryDate, now: current);
    return reminderDays.contains(remainingDays);
  }

  /// Supports DateTime, milliseconds, ISO string and Firestore-like Timestamp.
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

    try {
      final dynamic timestamp = value;
      final converted = timestamp.toDate();

      if (converted is DateTime) {
        return converted;
      }
    } catch (_) {
      // Value is not a Firestore Timestamp-like object.
    }

    return DateTime.tryParse(value.toString());
  }

  static int? millisecondsFromDate(DateTime? date) {
    return date?.millisecondsSinceEpoch;
  }

  static String presetLabel(RewardExpiryPreset preset) {
    switch (preset) {
      case RewardExpiryPreset.never:
        return 'Never expire';
      case RewardExpiryPreset.thirtyDays:
        return '30 days';
      case RewardExpiryPreset.ninetyDays:
        return '90 days';
      case RewardExpiryPreset.oneHundredEightyDays:
        return '180 days';
      case RewardExpiryPreset.oneYear:
        return '1 year';
      case RewardExpiryPreset.custom:
        return 'Custom';
    }
  }
}
