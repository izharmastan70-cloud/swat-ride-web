// =========================================================
// AI AGENT — CALL RIDE BOOKING DRAFT
// =========================================================
//
// Phase 17 only collects/validates a booking draft.
// It does NOT write a real Ride document.

class AgentCallRideBookingDraft {
  final String customerName;
  final String contactPhoneMasked;
  final String pickup;
  final String destination;
  final String vehicleType;
  final bool customerConfirmed;

  const AgentCallRideBookingDraft({
    required this.customerName,
    required this.contactPhoneMasked,
    required this.pickup,
    required this.destination,
    required this.vehicleType,
    required this.customerConfirmed,
  });

  bool get isComplete =>
      customerName.trim().isNotEmpty &&
      pickup.trim().isNotEmpty &&
      destination.trim().isNotEmpty &&
      vehicleType.trim().isNotEmpty;

  bool get canSubmit => isComplete && customerConfirmed;
}
