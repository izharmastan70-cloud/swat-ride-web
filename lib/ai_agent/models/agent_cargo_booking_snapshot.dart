// =========================================================
// AI AGENT — CARGO BOOKING SNAPSHOT
// =========================================================
//
// Phase 19 standalone model only.
// It does NOT represent or write the real Cargo collection yet.

class AgentCargoBookingSnapshot {
  final String bookingId;
  final String customerAlias;
  final String pickup;
  final String destination;
  final String vehicleType;
  final String cargoDescription;
  final String status;
  final String risk;
  final int? estimatedPriceRs;
  final DateTime? scheduledAt;

  const AgentCargoBookingSnapshot({
    required this.bookingId,
    required this.customerAlias,
    required this.pickup,
    required this.destination,
    required this.vehicleType,
    required this.cargoDescription,
    required this.status,
    required this.risk,
    required this.estimatedPriceRs,
    required this.scheduledAt,
  });

  bool get hasMinimumBookingData =>
      pickup.trim().isNotEmpty &&
      destination.trim().isNotEmpty &&
      vehicleType.trim().isNotEmpty &&
      cargoDescription.trim().isNotEmpty;
}
