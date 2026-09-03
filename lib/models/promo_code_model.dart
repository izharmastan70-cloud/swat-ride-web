class PromoCodeModel {
  final String id;
  final String code;
  final bool isActive;

  // Discount settings
  final bool isPercentage;
  final double discountValue;
  final double? maxDiscount;
  final double? minimumRideAmount;

  // Usage settings
  final int? usageLimit;
  final int usedCount;

  // Date settings
  final DateTime? startDate;
  final DateTime? expiryDate;

  const PromoCodeModel({
    required this.id,
    required this.code,
    required this.isActive,
    required this.isPercentage,
    required this.discountValue,
    this.maxDiscount,
    this.minimumRideAmount,
    this.usageLimit,
    this.usedCount = 0,
    this.startDate,
    this.expiryDate,
  });

  bool get isCurrentlyValid {
    final now = DateTime.now();

    if (!isActive) {
      return false;
    }

    if (startDate != null && now.isBefore(startDate!)) {
      return false;
    }

    if (expiryDate != null && now.isAfter(expiryDate!)) {
      return false;
    }

    if (usageLimit != null && usedCount >= usageLimit!) {
      return false;
    }

    return true;
  }

  double calculateDiscount(double rideAmount) {
    if (!isCurrentlyValid) {
      return 0;
    }

    if (minimumRideAmount != null &&
        rideAmount < minimumRideAmount!) {
      return 0;
    }

    double discount;

    if (isPercentage) {
      discount = rideAmount * (discountValue / 100);

      if (maxDiscount != null &&
          discount > maxDiscount!) {
        discount = maxDiscount!;
      }
    } else {
      discount = discountValue;
    }

    if (discount > rideAmount) {
      discount = rideAmount;
    }

    return discount;
  }
}