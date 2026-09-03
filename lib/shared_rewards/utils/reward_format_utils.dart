// =============================================================
// SWAT RIDE - GLOBAL LOYALTY, REWARDS & PROMO ENGINE
// File: lib/shared_rewards/utils/reward_format_utils.dart
//
// Dependency-free display formatting shared by User and Admin screens.
// =============================================================

class RewardFormatUtils {
  const RewardFormatUtils._();

  static String points(
    num value, {
    bool signed = false,
    bool includeLabel = true,
    bool compact = false,
  }) {
    final rounded = value.round();
    final number = compact
        ? compactNumber(rounded)
        : integer(rounded, signed: signed);

    if (!includeLabel) {
      return number;
    }

    return '$number ${rounded.abs() == 1 ? 'Point' : 'Points'}';
  }

  static String pkr(
    num value, {
    bool signed = false,
    bool showDecimals = false,
    bool compact = false,
    String symbol = 'PKR',
  }) {
    final amount = value.toDouble();
    final sign = signed && amount > 0 ? '+' : '';
    final formatted = compact
        ? compactNumber(amount)
        : decimal(
            amount,
            decimalPlaces: showDecimals ? 2 : 0,
          );

    return '$sign$symbol $formatted';
  }

  static String integer(num value, {bool signed = false}) {
    final rounded = value.round();
    final sign = rounded < 0
        ? '-'
        : signed && rounded > 0
            ? '+'
            : '';
    return '$sign${groupDigits(rounded.abs().toString())}';
  }

  static String decimal(
    num value, {
    int decimalPlaces = 2,
    bool signed = false,
    bool removeTrailingZeros = false,
  }) {
    final places = decimalPlaces.clamp(0, 10).toInt();
    final number = value.toDouble();

    if (!number.isFinite) {
      return '0';
    }

    final sign = number < 0
        ? '-'
        : signed && number > 0
            ? '+'
            : '';
    var fixed = number.abs().toStringAsFixed(places);

    if (removeTrailingZeros && fixed.contains('.')) {
      fixed = fixed.replaceFirst(RegExp(r'\.?0+$'), '');
    }

    final parts = fixed.split('.');
    final whole = groupDigits(parts.first);
    final fraction = parts.length > 1 ? '.${parts.last}' : '';
    return '$sign$whole$fraction';
  }

  static String percentage(
    num value, {
    int decimalPlaces = 1,
    bool signed = false,
  }) {
    return '${decimal(
      value,
      decimalPlaces: decimalPlaces,
      signed: signed,
      removeTrailingZeros: true,
    )}%';
  }

  static String multiplier(num value) {
    return '${decimal(
      value,
      decimalPlaces: 2,
      removeTrailingZeros: true,
    )}x';
  }

  static String compactNumber(num value, {int decimalPlaces = 1}) {
    final number = value.toDouble();

    if (!number.isFinite) {
      return '0';
    }

    final absolute = number.abs();
    String suffix;
    double divisor;

    if (absolute >= 1000000000) {
      suffix = 'B';
      divisor = 1000000000;
    } else if (absolute >= 1000000) {
      suffix = 'M';
      divisor = 1000000;
    } else if (absolute >= 1000) {
      suffix = 'K';
      divisor = 1000;
    } else {
      return integer(value);
    }

    return '${decimal(
      number / divisor,
      decimalPlaces: decimalPlaces,
      removeTrailingZeros: true,
    )}$suffix';
  }

  static String groupDigits(String digits) {
    if (digits.length <= 3) {
      return digits;
    }

    final buffer = StringBuffer();

    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        buffer.write(',');
      }

      buffer.write(digits[index]);
    }

    return buffer.toString();
  }

  static String date(
    DateTime? value, {
    String emptyText = '—',
    bool monthName = false,
  }) {
    if (value == null) {
      return emptyText;
    }

    final local = value.toLocal();

    if (monthName) {
      return '${local.day.toString().padLeft(2, '0')} '
          '${shortMonth(local.month)} ${local.year}';
    }

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
  }

  static String time(
    DateTime? value, {
    String emptyText = '—',
    bool twelveHour = true,
  }) {
    if (value == null) {
      return emptyText;
    }

    final local = value.toLocal();

    if (!twelveHour) {
      return '${local.hour.toString().padLeft(2, '0')}:'
          '${local.minute.toString().padLeft(2, '0')}';
    }

    final period = local.hour >= 12 ? 'PM' : 'AM';
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    return '${hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')} $period';
  }

  static String dateTime(
    DateTime? value, {
    String emptyText = '—',
    bool monthName = false,
    bool twelveHour = true,
  }) {
    if (value == null) {
      return emptyText;
    }

    return '${date(value, monthName: monthName)} '
        '${time(value, twelveHour: twelveHour)}';
  }

  static String dateRange(
    DateTime? start,
    DateTime? end, {
    String emptyText = 'All dates',
  }) {
    if (start == null && end == null) {
      return emptyText;
    }

    if (start != null && end == null) {
      return 'From ${date(start, monthName: true)}';
    }

    if (start == null && end != null) {
      return 'Until ${date(end, monthName: true)}';
    }

    return '${date(start, monthName: true)} — '
        '${date(end, monthName: true)}';
  }

  static String relativeDate(DateTime? value, {DateTime? now}) {
    if (value == null) {
      return '—';
    }

    final current = now ?? DateTime.now();
    final difference = current.difference(value);

    if (difference.isNegative) {
      return futureRelativeDate(value, now: current);
    }

    if (difference.inSeconds < 60) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    }

    return date(value, monthName: true);
  }

  static String futureRelativeDate(DateTime value, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final difference = value.difference(current);

    if (difference.isNegative) {
      return relativeDate(value, now: current);
    }

    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes < 1 ? 1 : difference.inMinutes;
      return 'In $minutes ${minutes == 1 ? 'minute' : 'minutes'}';
    }

    if (difference.inHours < 24) {
      return 'In ${difference.inHours} '
          '${difference.inHours == 1 ? 'hour' : 'hours'}';
    }

    return 'In ${difference.inDays} '
        '${difference.inDays == 1 ? 'day' : 'days'}';
  }

  static String remainingDays(int? days) {
    if (days == null) {
      return 'Never expires';
    }

    if (days < 0) {
      return 'Expired';
    }

    if (days == 0) {
      return 'Expires today';
    }

    if (days == 1) {
      return '1 day remaining';
    }

    return '$days days remaining';
  }

  static String titleCase(String value) {
    final words = value
        .trim()
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (match) => '${match.group(1)} ${match.group(2)}',
        )
        .replaceAll(RegExp(r'[_\-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .split(' ')
        .where((word) => word.isNotEmpty);

    return words.map((word) {
      if (word.length == 1) {
        return word.toUpperCase();
      }

      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    }).join(' ');
  }

  static String transactionLabel(dynamic value) {
    final normalized = value
        ?.toString()
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');

    switch (normalized) {
      case 'earned':
        return 'Points Earned';
      case 'redeemed':
        return 'Points Redeemed';
      case 'signupbonus':
        return 'Signup Bonus';
      case 'firstbookingbonus':
        return 'First Booking Bonus';
      case 'referralbonus':
        return 'Referral Bonus';
      case 'campaignbonus':
        return 'Campaign Bonus';
      case 'manualcredit':
        return 'Admin Credit';
      case 'manualdebit':
        return 'Admin Debit';
      case 'expired':
        return 'Points Expired';
      case 'reversed':
        return 'Transaction Reversed';
      case 'refundadjustment':
        return 'Refund Adjustment';
      default:
        return titleCase(value?.toString() ?? 'Unknown');
    }
  }

  static String statusLabel(dynamic value) {
    final text = value?.toString() ?? '';
    return text.trim().isEmpty ? 'Unknown' : titleCase(text);
  }

  static String code(String? value, {String emptyText = '—'}) {
    final normalized = value?.trim().toUpperCase() ?? '';
    return normalized.isEmpty ? emptyText : normalized;
  }

  static String maskId(
    String? value, {
    int visibleStart = 4,
    int visibleEnd = 4,
    String mask = '••••',
  }) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return '—';
    }

    final startCount = visibleStart.clamp(0, text.length).toInt();
    final remaining = text.length - startCount;
    final endCount = visibleEnd.clamp(0, remaining).toInt();

    if (startCount + endCount >= text.length) {
      return text;
    }

    return '${text.substring(0, startCount)}$mask'
        '${text.substring(text.length - endCount)}';
  }

  static String shortMonth(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    if (month < 1 || month > 12) {
      return '';
    }

    return months[month - 1];
  }
}
