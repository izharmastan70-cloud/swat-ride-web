// =========================================================
// AI AGENT — FINANCE CONSTANTS
// =========================================================

class AgentFinanceRecordType {
  AgentFinanceRecordType._();

  static const String rideEarning = 'RIDE_EARNING';
  static const String foodEarning = 'FOOD_EARNING';
  static const String hotelEarning = 'HOTEL_EARNING';
  static const String tourEarning = 'TOUR_EARNING';
  static const String commission = 'COMMISSION';
  static const String settlement = 'SETTLEMENT';
  static const String refund = 'REFUND';
  static const String withdrawal = 'WITHDRAWAL';
  static const String adjustment = 'ADJUSTMENT';

  static const Set<String> values = <String>{
    rideEarning,
    foodEarning,
    hotelEarning,
    tourEarning,
    commission,
    settlement,
    refund,
    withdrawal,
    adjustment,
  };

  static bool isValid(String value) => values.contains(value);
}

class AgentFinanceStatus {
  AgentFinanceStatus._();

  static const String pending = 'PENDING';
  static const String prepared = 'PREPARED';
  static const String approved = 'APPROVED';
  static const String rejected = 'REJECTED';
  static const String settled = 'SETTLED';
  static const String failed = 'FAILED';
}

class AgentFinanceRisk {
  AgentFinanceRisk._();

  static const String low = 'LOW';
  static const String medium = 'MEDIUM';
  static const String high = 'HIGH';
  static const String critical = 'CRITICAL';
}
