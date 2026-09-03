import 'agent_call_ride_booking_draft.dart';

class AgentCallRideBookingExecutionMode {
  AgentCallRideBookingExecutionMode._();

  static const String test = 'TEST';
  static const String production = 'PRODUCTION';

  static const Set<String> values = <String>{test, production};
}

class AgentCallRideFareVerification {
  const AgentCallRideFareVerification({
    required this.pickupReferenceId,
    required this.destinationReferenceId,
    required this.vehicleId,
    required this.vehicleType,
    required this.distanceKm,
    required this.estimatedMinutes,
    required this.baseFare,
    required this.estimatedFare,
    required this.adminCommissionAmount,
    required this.driverAvailable,
    required this.rideServiceAvailable,
    required this.usedTestingRouteBypass,
    required this.verifiedAt,
    required this.expiresAt,
  });

  final String pickupReferenceId;
  final String destinationReferenceId;
  final String vehicleId;
  final String vehicleType;

  final double distanceKm;
  final int estimatedMinutes;
  final double baseFare;
  final double estimatedFare;
  final double adminCommissionAmount;

  final bool driverAvailable;
  final bool rideServiceAvailable;

  /// True means the current temporary straight-line/testing route estimate
  /// was used. It may be displayed in test mode, but it must not authorize
  /// a production Call Agent booking.
  final bool usedTestingRouteBypass;

  final DateTime verifiedAt;
  final DateTime expiresAt;

  bool isFreshAt(DateTime now) =>
      expiresAt.toUtc().isAfter(now.toUtc()) &&
      !verifiedAt.toUtc().isAfter(now.toUtc());

  bool get hasResolvedRoute =>
      pickupReferenceId.trim().isNotEmpty &&
      destinationReferenceId.trim().isNotEmpty;

  bool get hasVehicleBinding =>
      vehicleId.trim().isNotEmpty && vehicleType.trim().isNotEmpty;

  bool get hasSafeAmounts =>
      distanceKm >= 0 &&
      estimatedMinutes >= 0 &&
      baseFare >= 0 &&
      estimatedFare >= 0 &&
      adminCommissionAmount >= 0;

  void validate() {
    if (!hasResolvedRoute) {
      throw const AgentCallRideBookingContractException(
        'Resolved pickup and destination references are required.',
      );
    }

    if (!hasVehicleBinding) {
      throw const AgentCallRideBookingContractException(
        'Exact vehicle ID and vehicle type are required.',
      );
    }

    if (!hasSafeAmounts) {
      throw const AgentCallRideBookingContractException(
        'Fare, distance, time and commission values cannot be negative.',
      );
    }

    if (!expiresAt.toUtc().isAfter(verifiedAt.toUtc())) {
      throw const AgentCallRideBookingContractException(
        'Fare verification expiry must be after verification time.',
      );
    }
  }
}

class AgentCallRideBookingAuthorization {
  const AgentCallRideBookingAuthorization({
    required this.callAgentMasterEnabled,
    required this.runtimeAllowed,
    required this.permissionAllowed,
    required this.dedicatedBookingActionAllowed,
    required this.trustedCallerBound,
    required this.trustedContactBound,
    required this.idempotencyKeyReserved,
    required this.reason,
  });

  final bool callAgentMasterEnabled;
  final bool runtimeAllowed;
  final bool permissionAllowed;

  /// Must come from a future dedicated Call Ride Booking write action.
  /// Query text / voice alone can never set this authoritatively.
  final bool dedicatedBookingActionAllowed;

  final bool trustedCallerBound;
  final bool trustedContactBound;

  /// Must be reserved by a trusted execution boundary before a real write.
  final bool idempotencyKeyReserved;

  final String reason;

  bool get baseAuthorityAllowed =>
      callAgentMasterEnabled &&
      runtimeAllowed &&
      permissionAllowed &&
      dedicatedBookingActionAllowed &&
      trustedCallerBound &&
      trustedContactBound &&
      idempotencyKeyReserved;

  void validate() {
    if (!baseAuthorityAllowed && reason.trim().isEmpty) {
      throw const AgentCallRideBookingContractException(
        'Blocked booking authorization requires a reason.',
      );
    }
  }
}

class AgentCallRideBookingExecutionRequest {
  const AgentCallRideBookingExecutionRequest({
    required this.executionId,
    required this.idempotencyKey,
    required this.mode,
    required this.trustedCallerReferenceId,
    required this.trustedContactReferenceId,
    required this.draft,
    required this.fareVerification,
    required this.authorization,
    required this.createdAt,
  });

  final String executionId;
  final String idempotencyKey;
  final String mode;

  /// Stable trusted references only. Raw phone secrets are not stored here.
  final String trustedCallerReferenceId;
  final String trustedContactReferenceId;

  final AgentCallRideBookingDraft draft;
  final AgentCallRideFareVerification fareVerification;
  final AgentCallRideBookingAuthorization authorization;
  final DateTime createdAt;

  bool get customerExplicitlyConfirmed => draft.customerConfirmed;

  bool mayCreateRealRideAt(DateTime now) {
    if (mode != AgentCallRideBookingExecutionMode.production) {
      return false;
    }

    return authorization.baseAuthorityAllowed &&
        customerExplicitlyConfirmed &&
        fareVerification.rideServiceAvailable &&
        fareVerification.driverAvailable &&
        fareVerification.isFreshAt(now) &&
        !fareVerification.usedTestingRouteBypass;
  }

  void validate() {
    if (executionId.trim().isEmpty ||
        idempotencyKey.trim().isEmpty ||
        trustedCallerReferenceId.trim().isEmpty ||
        trustedContactReferenceId.trim().isEmpty) {
      throw const AgentCallRideBookingContractException(
        'Execution, idempotency, caller and contact references are required.',
      );
    }

    if (!AgentCallRideBookingExecutionMode.values.contains(mode)) {
      throw const AgentCallRideBookingContractException(
        'Invalid Call Ride Booking execution mode.',
      );
    }

    if (draft.customerName.trim().isEmpty ||
        draft.contactPhoneMasked.trim().isEmpty ||
        draft.pickup.trim().isEmpty ||
        draft.destination.trim().isEmpty ||
        draft.vehicleType.trim().isEmpty) {
      throw const AgentCallRideBookingContractException(
        'Complete Call Ride Booking draft is required.',
      );
    }

    if (draft.vehicleType.trim() != fareVerification.vehicleType.trim()) {
      throw const AgentCallRideBookingContractException(
        'Draft vehicle type must match verified fare vehicle type.',
      );
    }

    fareVerification.validate();
    authorization.validate();
  }
}

class AgentCallRideBookingExecutionResult {
  const AgentCallRideBookingExecutionResult({
    required this.status,
    required this.code,
    required this.executionId,
    required this.idempotencyKey,
    required this.createdAt,
    this.rideId,
  });

  static const String readyForTrustedBackend = 'READY_FOR_TRUSTED_BACKEND';
  static const String blocked = 'BLOCKED';

  final String status;
  final String code;
  final String executionId;
  final String idempotencyKey;
  final String? rideId;
  final DateTime createdAt;

  bool get isReadyForTrustedBackend => status == readyForTrustedBackend;
  bool get isBlocked => status == blocked;

  /// Step 1B never performs the actual Ride write.
  bool get realRideWritePerformed => false;

  /// A non-null ride ID in this Step 1B result would be a contract violation.
  void validate() {
    if (status != readyForTrustedBackend && status != blocked) {
      throw const AgentCallRideBookingContractException(
        'Invalid Call Ride Booking execution result status.',
      );
    }

    if (executionId.trim().isEmpty || idempotencyKey.trim().isEmpty) {
      throw const AgentCallRideBookingContractException(
        'Execution result requires execution and idempotency IDs.',
      );
    }

    if (rideId != null) {
      throw const AgentCallRideBookingContractException(
        'Step 1B contract cannot claim a real Ride ID.',
      );
    }
  }
}

class AgentCallRideBookingContractException implements Exception {
  const AgentCallRideBookingContractException(this.message);

  final String message;

  @override
  String toString() => 'AgentCallRideBookingContractException: $message';
}
