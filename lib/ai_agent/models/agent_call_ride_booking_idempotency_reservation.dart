class AgentCallRideBookingIdempotencyReservationStatus {
  AgentCallRideBookingIdempotencyReservationStatus._();

  static const String reserved = 'RESERVED';
  static const String completed = 'COMPLETED';
}

class AgentCallRideBookingIdempotencyReservation {
  const AgentCallRideBookingIdempotencyReservation({
    required this.reservationId,
    required this.idempotencyKey,
    required this.roleId,
    required this.actionId,
    required this.requestedBy,
    required this.trustedCallerReferenceId,
    required this.trustedContactReferenceId,
    required this.status,
    required this.createdAt,
    required this.reusedExistingReservation,
  });

  final String reservationId;
  final String idempotencyKey;
  final String roleId;
  final String actionId;
  final String requestedBy;
  final String trustedCallerReferenceId;
  final String trustedContactReferenceId;
  final String status;
  final DateTime createdAt;

  /// True means the exact same logical request was already reserved.
  /// This is safe idempotent reuse, not a second booking authorization.
  final bool reusedExistingReservation;

  bool get isReserved =>
      status == AgentCallRideBookingIdempotencyReservationStatus.reserved ||
      status == AgentCallRideBookingIdempotencyReservationStatus.completed;

  bool matchesBinding({
    required String roleId,
    required String actionId,
    required String requestedBy,
    required String trustedCallerReferenceId,
    required String trustedContactReferenceId,
  }) {
    return this.roleId == roleId.trim() &&
        this.actionId == actionId.trim() &&
        this.requestedBy == requestedBy.trim() &&
        this.trustedCallerReferenceId == trustedCallerReferenceId.trim() &&
        this.trustedContactReferenceId == trustedContactReferenceId.trim();
  }

  AgentCallRideBookingIdempotencyReservation copyWith({
    String? status,
    bool? reusedExistingReservation,
  }) {
    return AgentCallRideBookingIdempotencyReservation(
      reservationId: reservationId,
      idempotencyKey: idempotencyKey,
      roleId: roleId,
      actionId: actionId,
      requestedBy: requestedBy,
      trustedCallerReferenceId: trustedCallerReferenceId,
      trustedContactReferenceId: trustedContactReferenceId,
      status: status ?? this.status,
      createdAt: createdAt,
      reusedExistingReservation:
          reusedExistingReservation ?? this.reusedExistingReservation,
    );
  }

  void validate() {
    if (reservationId.trim().isEmpty ||
        idempotencyKey.trim().isEmpty ||
        roleId.trim().isEmpty ||
        actionId.trim().isEmpty ||
        requestedBy.trim().isEmpty ||
        trustedCallerReferenceId.trim().isEmpty ||
        trustedContactReferenceId.trim().isEmpty) {
      throw const AgentCallRideBookingIdempotencyException(
        'Complete idempotency reservation binding is required.',
      );
    }

    if (idempotencyKey.length > 200) {
      throw const AgentCallRideBookingIdempotencyException(
        'Idempotency key is too long.',
      );
    }

    if (status != AgentCallRideBookingIdempotencyReservationStatus.reserved &&
        status != AgentCallRideBookingIdempotencyReservationStatus.completed) {
      throw const AgentCallRideBookingIdempotencyException(
        'Invalid idempotency reservation status.',
      );
    }
  }
}

class AgentCallRideBookingIdempotencyException implements Exception {
  const AgentCallRideBookingIdempotencyException(this.message);

  final String message;

  @override
  String toString() => 'AgentCallRideBookingIdempotencyException: $message';
}
