// =========================================================
// AI AGENT â€” CALL AGENT CONSTANTS
// =========================================================

class AgentCallMode {
  AgentCallMode._();

  static const String test = 'TEST';
  static const String live = 'LIVE';
}

class AgentCallIntent {
  AgentCallIntent._();

  static const String rideBooking = 'RIDE_BOOKING';
  static const String rideStatus = 'RIDE_STATUS';
  static const String cancellation = 'CANCELLATION';
  static const String driverEta = 'DRIVER_ETA';
  static const String support = 'SUPPORT';
  static const String emergency = 'EMERGENCY';
  static const String paymentDispute = 'PAYMENT_DISPUTE';
  static const String legal = 'LEGAL';
  static const String fraud = 'FRAUD';
  static const String foodOrder = 'FOOD_ORDER';
  static const String foodOrderStatus = 'FOOD_ORDER_STATUS';

  static const String hotelBooking = 'HOTEL_BOOKING';
  static const String hotelBookingStatus = 'HOTEL_BOOKING_STATUS';

  static const String tourBooking = 'TOUR_BOOKING';
  static const String tourBookingStatus = 'TOUR_BOOKING_STATUS';

  static const String unknown = 'UNKNOWN';
}

class AgentCallEscalationLevel {
  AgentCallEscalationLevel._();

  static const String ai = 'AI';
  static const String humanSupport = 'HUMAN_SUPPORT';
  static const String managerAdmin = 'MANAGER_ADMIN';
  static const String owner = 'OWNER';
}

class AgentCallSessionStatus {
  AgentCallSessionStatus._();

  static const String active = 'ACTIVE';
  static const String awaitingConfirmation = 'AWAITING_CONFIRMATION';
  static const String escalated = 'ESCALATED';
  static const String completed = 'COMPLETED';
  static const String failed = 'FAILED';
}
