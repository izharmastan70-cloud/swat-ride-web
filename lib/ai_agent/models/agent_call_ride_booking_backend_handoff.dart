import '../constants/agent_action_ids.dart';
import 'agent_call_ride_booking_customer_confirmation.dart';
import 'agent_call_ride_booking_execution_contract.dart';

class AgentCallRideBookingBackendHandoffStatus {
  AgentCallRideBookingBackendHandoffStatus._();

  static const String ready = 'READY_FOR_TRUSTED_BACKEND';
  static const String blocked = 'BLOCKED';
}

/// Privacy-minimized envelope for a future trusted Ride-booking backend.
///
/// IMPORTANT:
/// - This envelope is DATA, never authority.
/// - The trusted backend must independently enforce server-side identity,
///   idempotency, confirmation-consumption and Ride-write rules.
/// - No raw phone secret, transcript, provider credential or client signing
///   secret belongs here.
class AgentCallRideBookingBackendHandoffEnvelope {
  const AgentCallRideBookingBackendHandoffEnvelope({
    required this.envelopeId,
    required this.actionId,
    required this.roleId,
    required this.module,
    required this.callSessionId,
    required this.requestedBy,
    required this.executionId,
    required this.idempotencyKey,
    required this.trustedCallerReferenceId,
    required this.trustedContactReferenceId,
    required this.confirmationTokenReferenceId,
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
    required this.fareVerifiedAt,
    required this.fareExpiresAt,
    required this.createdAt,
  });

  static const String expectedRoleId = 'call_agent';
  static const String expectedModule = 'call';

  final String envelopeId;
  final String actionId;
  final String roleId;
  final String module;

  final String callSessionId;
  final String requestedBy;
  final String executionId;
  final String idempotencyKey;

  final String trustedCallerReferenceId;
  final String trustedContactReferenceId;
  final String confirmationTokenReferenceId;

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
  final bool usedTestingRouteBypass;

  final DateTime fareVerifiedAt;
  final DateTime fareExpiresAt;
  final DateTime createdAt;

  factory AgentCallRideBookingBackendHandoffEnvelope.fromVerifiedScope({
    required String envelopeId,
    required AgentCallRideBookingCustomerConfirmationScope scope,
    required String confirmationTokenReferenceId,
    required DateTime createdAt,
  }) {
    return AgentCallRideBookingBackendHandoffEnvelope(
      envelopeId: envelopeId.trim(),
      actionId: scope.actionId,
      roleId: expectedRoleId,
      module: expectedModule,
      callSessionId: scope.callSessionId,
      requestedBy: scope.requestedBy,
      executionId: scope.executionId,
      idempotencyKey: scope.idempotencyKey,
      trustedCallerReferenceId: scope.trustedCallerReferenceId,
      trustedContactReferenceId: scope.trustedContactReferenceId,
      confirmationTokenReferenceId: confirmationTokenReferenceId.trim(),
      pickupReferenceId: scope.pickupReferenceId,
      destinationReferenceId: scope.destinationReferenceId,
      vehicleId: scope.vehicleId,
      vehicleType: scope.vehicleType,
      distanceKm: scope.distanceKm,
      estimatedMinutes: scope.estimatedMinutes,
      baseFare: scope.baseFare,
      estimatedFare: scope.estimatedFare,
      adminCommissionAmount: scope.adminCommissionAmount,
      driverAvailable: scope.driverAvailable,
      rideServiceAvailable: scope.rideServiceAvailable,
      usedTestingRouteBypass: scope.usedTestingRouteBypass,
      fareVerifiedAt: scope.fareVerifiedAt.toUtc(),
      fareExpiresAt: scope.fareExpiresAt.toUtc(),
      createdAt: createdAt.toUtc(),
    );
  }

  AgentCallRideBookingCustomerConfirmationScope toConfirmationScope() {
    return AgentCallRideBookingCustomerConfirmationScope(
      actionId: actionId,
      callSessionId: callSessionId,
      executionId: executionId,
      requestedBy: requestedBy,
      trustedCallerReferenceId: trustedCallerReferenceId,
      trustedContactReferenceId: trustedContactReferenceId,
      idempotencyKey: idempotencyKey,
      pickupReferenceId: pickupReferenceId,
      destinationReferenceId: destinationReferenceId,
      vehicleId: vehicleId,
      vehicleType: vehicleType,
      distanceKm: distanceKm,
      estimatedMinutes: estimatedMinutes,
      baseFare: baseFare,
      estimatedFare: estimatedFare,
      adminCommissionAmount: adminCommissionAmount,
      driverAvailable: driverAvailable,
      rideServiceAvailable: rideServiceAvailable,
      usedTestingRouteBypass: usedTestingRouteBypass,
      fareVerifiedAt: fareVerifiedAt,
      fareExpiresAt: fareExpiresAt,
    );
  }

  bool isFreshAt(DateTime now) {
    final DateTime utcNow = now.toUtc();

    return !createdAt.toUtc().isAfter(utcNow) &&
        fareExpiresAt.toUtc().isAfter(utcNow);
  }

  void validate() {
    if (actionId != AgentActionId.createCallRideBooking ||
        roleId != expectedRoleId ||
        module != expectedModule) {
      throw const AgentCallRideBookingBackendHandoffException(
        'Handoff must be exactly bound to call_agent/call/create_ride_booking.',
      );
    }

    if (envelopeId.trim().isEmpty ||
        callSessionId.trim().isEmpty ||
        requestedBy.trim().isEmpty ||
        executionId.trim().isEmpty ||
        idempotencyKey.trim().isEmpty ||
        trustedCallerReferenceId.trim().isEmpty ||
        trustedContactReferenceId.trim().isEmpty ||
        confirmationTokenReferenceId.trim().isEmpty ||
        pickupReferenceId.trim().isEmpty ||
        destinationReferenceId.trim().isEmpty ||
        vehicleId.trim().isEmpty ||
        vehicleType.trim().isEmpty) {
      throw const AgentCallRideBookingBackendHandoffException(
        'Complete trusted backend handoff binding is required.',
      );
    }

    if (pickupReferenceId == destinationReferenceId) {
      throw const AgentCallRideBookingBackendHandoffException(
        'Pickup and destination references must differ.',
      );
    }

    if (distanceKm < 0 ||
        estimatedMinutes < 0 ||
        baseFare < 0 ||
        estimatedFare < 0 ||
        adminCommissionAmount < 0) {
      throw const AgentCallRideBookingBackendHandoffException(
        'Handoff fare values cannot be negative.',
      );
    }

    if (!driverAvailable || !rideServiceAvailable) {
      throw const AgentCallRideBookingBackendHandoffException(
        'Handoff requires verified ride service and driver availability.',
      );
    }

    if (usedTestingRouteBypass) {
      throw const AgentCallRideBookingBackendHandoffException(
        'Production handoff cannot contain testing-route fare provenance.',
      );
    }

    if (!fareExpiresAt.toUtc().isAfter(fareVerifiedAt.toUtc()) ||
        createdAt.toUtc().isBefore(fareVerifiedAt.toUtc()) ||
        !fareExpiresAt.toUtc().isAfter(createdAt.toUtc())) {
      throw const AgentCallRideBookingBackendHandoffException(
        'Handoff time must be inside the verified fare window.',
      );
    }

    toConfirmationScope().validate();
  }

  bool exactlyMatchesExecution(AgentCallRideBookingExecutionRequest request) {
    final fare = request.fareVerification;

    return executionId == request.executionId.trim() &&
        idempotencyKey == request.idempotencyKey.trim() &&
        trustedCallerReferenceId == request.trustedCallerReferenceId.trim() &&
        trustedContactReferenceId == request.trustedContactReferenceId.trim() &&
        pickupReferenceId == fare.pickupReferenceId.trim() &&
        destinationReferenceId == fare.destinationReferenceId.trim() &&
        vehicleId == fare.vehicleId.trim() &&
        vehicleType == fare.vehicleType.trim() &&
        distanceKm == fare.distanceKm &&
        estimatedMinutes == fare.estimatedMinutes &&
        baseFare == fare.baseFare &&
        estimatedFare == fare.estimatedFare &&
        adminCommissionAmount == fare.adminCommissionAmount &&
        driverAvailable == fare.driverAvailable &&
        rideServiceAvailable == fare.rideServiceAvailable &&
        usedTestingRouteBypass == fare.usedTestingRouteBypass &&
        fareVerifiedAt.toUtc() == fare.verifiedAt.toUtc() &&
        fareExpiresAt.toUtc() == fare.expiresAt.toUtc();
  }

  Map<String, dynamic> toSanitizedMap() {
    return <String, dynamic>{
      'envelopeId': envelopeId,
      'actionId': actionId,
      'roleId': roleId,
      'module': module,
      'callSessionId': callSessionId,
      'requestedBy': requestedBy,
      'executionId': executionId,
      'idempotencyKey': idempotencyKey,
      'trustedCallerReferenceId': trustedCallerReferenceId,
      'trustedContactReferenceId': trustedContactReferenceId,
      'confirmationTokenReferenceId': confirmationTokenReferenceId,
      'pickupReferenceId': pickupReferenceId,
      'destinationReferenceId': destinationReferenceId,
      'vehicleId': vehicleId,
      'vehicleType': vehicleType,
      'distanceKm': distanceKm,
      'estimatedMinutes': estimatedMinutes,
      'baseFare': baseFare,
      'estimatedFare': estimatedFare,
      'adminCommissionAmount': adminCommissionAmount,
      'driverAvailable': driverAvailable,
      'rideServiceAvailable': rideServiceAvailable,
      'usedTestingRouteBypass': usedTestingRouteBypass,
      'fareVerifiedAt': fareVerifiedAt.toUtc().toIso8601String(),
      'fareExpiresAt': fareExpiresAt.toUtc().toIso8601String(),
      'createdAt': createdAt.toUtc().toIso8601String(),
      'rawPhoneIncluded': false,
      'transcriptIncluded': false,
      'providerSecretIncluded': false,
      'clientSigningSecretIncluded': false,
    };
  }
}

class AgentCallRideBookingBackendHandoffResult {
  const AgentCallRideBookingBackendHandoffResult({
    required this.status,
    required this.code,
    required this.createdAt,
    this.envelope,
  });

  final String status;
  final String code;
  final DateTime createdAt;
  final AgentCallRideBookingBackendHandoffEnvelope? envelope;

  bool get isReady =>
      status == AgentCallRideBookingBackendHandoffStatus.ready &&
      envelope != null;

  bool get isBlocked =>
      status == AgentCallRideBookingBackendHandoffStatus.blocked;

  bool get realRideWritePerformed => false;
}

class AgentCallRideBookingBackendCompletionReceipt {
  const AgentCallRideBookingBackendCompletionReceipt({
    required this.status,
    required this.code,
    required this.idempotencyKey,
    required this.rideId,
    required this.backendExecutionReferenceId,
    required this.completionSource,
    required this.completedAt,
    required this.reusedExistingCompletion,
    this.previousAcceptedRideIdBeforeCompletion,
    this.rideRecordPersisted = false,
    this.rideIdEvidenceSource = '',
  });

  static const String created = 'CREATED';
  static const String alreadyCompleted = 'ALREADY_COMPLETED';
  static const String blocked = 'BLOCKED';

  static const String trustedBackendSource =
      'TRUSTED_BACKEND_RIDE_BOOKING_EXECUTOR';

  static const String trustedRideIdEvidenceSource =
      'TRUSTED_BACKEND_PERSISTED_RIDE_RECORD';

  final String status;
  final String code;
  final String idempotencyKey;
  final String rideId;
  final String backendExecutionReferenceId;
  final String completionSource;
  final DateTime completedAt;
  final bool reusedExistingCompletion;

  /// Trusted backend state immediately BEFORE this completion attempt.
  /// null means this was the first completion attempt accepted by backend state.
  final String? previousAcceptedRideIdBeforeCompletion;

  /// True only when the trusted backend has persisted the returned Ride ID
  /// as a real Ride record. A locally invented/placeholder ID is not evidence.
  final bool rideRecordPersisted;

  /// Exact trusted backend evidence source for the persisted Ride ID.
  final String rideIdEvidenceSource;

  bool get isSuccessfulCompletion =>
      status == created || status == alreadyCompleted;

  void validate() {
    if (status != created && status != alreadyCompleted && status != blocked) {
      throw const AgentCallRideBookingBackendHandoffException(
        'Invalid backend completion status.',
      );
    }

    if (code.trim().isEmpty || idempotencyKey.trim().isEmpty) {
      throw const AgentCallRideBookingBackendHandoffException(
        'Completion code and idempotency key are required.',
      );
    }

    if (isSuccessfulCompletion) {
      if (rideId.trim().isEmpty ||
          backendExecutionReferenceId.trim().isEmpty ||
          completionSource != trustedBackendSource ||
          !rideRecordPersisted ||
          rideIdEvidenceSource != trustedRideIdEvidenceSource) {
        throw const AgentCallRideBookingBackendHandoffException(
          'Successful completion requires trusted backend Ride evidence.',
        );
      }
    }

    if (status == created && reusedExistingCompletion) {
      throw const AgentCallRideBookingBackendHandoffException(
        'New CREATED completion cannot be marked as reused.',
      );
    }

    final String? previous = previousAcceptedRideIdBeforeCompletion?.trim();

    if (status == created && previous != null && previous.isNotEmpty) {
      throw const AgentCallRideBookingBackendHandoffException(
        'New CREATED completion cannot have a previous accepted Ride ID.',
      );
    }

    if (status == alreadyCompleted && !reusedExistingCompletion) {
      throw const AgentCallRideBookingBackendHandoffException(
        'ALREADY_COMPLETED must be marked as reused.',
      );
    }

    if (status == alreadyCompleted &&
        (previous == null || previous.isEmpty || previous != rideId.trim())) {
      throw const AgentCallRideBookingBackendHandoffException(
        'ALREADY_COMPLETED must prove the same previously accepted Ride ID.',
      );
    }
  }
}

class AgentCallRideBookingBackendHandoffException implements Exception {
  const AgentCallRideBookingBackendHandoffException(this.message);

  final String message;

  @override
  String toString() => 'AgentCallRideBookingBackendHandoffException: $message';
}
