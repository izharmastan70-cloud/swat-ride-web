// =========================================================
// AI AGENT — SUPPORT CONSTANTS
// =========================================================

class AgentSupportIntent {
  AgentSupportIntent._();

  static const String faq = 'FAQ';
  static const String rideStatus = 'RIDE_STATUS';
  static const String foodStatus = 'FOOD_STATUS';
  static const String hotelStatus = 'HOTEL_STATUS';
  static const String tourStatus = 'TOUR_STATUS';
  static const String rewardsHelp = 'REWARDS_HELP';
  static const String accountHelp = 'ACCOUNT_HELP';
  static const String paymentDispute = 'PAYMENT_DISPUTE';
  static const String refundRequest = 'REFUND_REQUEST';
  static const String fraud = 'FRAUD';
  static const String safety = 'SAFETY';
  static const String legal = 'LEGAL';
  static const String abuse = 'ABUSE';
  static const String unknown = 'UNKNOWN';

  static const Set<String> values = <String>{
    faq,
    rideStatus,
    foodStatus,
    hotelStatus,
    tourStatus,
    rewardsHelp,
    accountHelp,
    paymentDispute,
    refundRequest,
    fraud,
    safety,
    legal,
    abuse,
    unknown,
  };
}

class AgentSupportPriority {
  AgentSupportPriority._();

  static const String normal = 'NORMAL';
  static const String high = 'HIGH';
  static const String urgent = 'URGENT';
  static const String critical = 'CRITICAL';
}

class AgentSupportEscalation {
  AgentSupportEscalation._();

  static const String none = 'NONE';
  static const String humanSupport = 'HUMAN_SUPPORT';
  static const String manager = 'MANAGER';
  static const String owner = 'OWNER';
  static const String safetyHuman = 'SAFETY_HUMAN';
}

class AgentSupportDraftStatus {
  AgentSupportDraftStatus._();

  static const String ready = 'READY';
  static const String needsContext = 'NEEDS_CONTEXT';
  static const String escalationRequired = 'ESCALATION_REQUIRED';
  static const String unavailable = 'UNAVAILABLE';
}
