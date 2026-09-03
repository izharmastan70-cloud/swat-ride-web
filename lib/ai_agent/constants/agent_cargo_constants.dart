// =========================================================
// AI AGENT — CARGO CONSTANTS
// =========================================================

class AgentCargoStatus {
  AgentCargoStatus._();

  static const String draft = 'DRAFT';
  static const String requested = 'REQUESTED';
  static const String assigned = 'ASSIGNED';
  static const String pickedUp = 'PICKED_UP';
  static const String inTransit = 'IN_TRANSIT';
  static const String delivered = 'DELIVERED';
  static const String cancelled = 'CANCELLED';
  static const String unknown = 'UNKNOWN';

  static const Set<String> values = <String>{
    draft,
    requested,
    assigned,
    pickedUp,
    inTransit,
    delivered,
    cancelled,
    unknown,
  };
}

class AgentCargoRisk {
  AgentCargoRisk._();

  static const String normal = 'NORMAL';
  static const String highValue = 'HIGH_VALUE';
  static const String fragile = 'FRAGILE';
  static const String restricted = 'RESTRICTED';
  static const String unknown = 'UNKNOWN';
}

class AgentCargoIntent {
  AgentCargoIntent._();

  static const String bookingHelp = 'BOOKING_HELP';
  static const String statusCheck = 'STATUS_CHECK';
  static const String cancelRequest = 'CANCEL_REQUEST';
  static const String pricingHelp = 'PRICING_HELP';
  static const String unknown = 'UNKNOWN';
}
