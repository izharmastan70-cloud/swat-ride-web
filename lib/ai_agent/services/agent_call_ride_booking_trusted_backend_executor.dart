import '../models/agent_call_ride_booking_backend_handoff.dart';
import '../models/agent_call_ride_booking_final_receipt.dart';
import 'agent_call_ride_booking_exactly_once_completion_contract.dart';

/// Phase 49 Step 1H execution coordinator.
///
/// This REUSES the Step 1G [AgentCallRideBookingExactlyOnceCompletionGateway].
/// There is intentionally no default Flutter implementation of that gateway.
///
/// Production backend transport / server Ride creation is still disconnected.
/// A future server-side implementation must create/reuse the Ride atomically
/// with the idempotency state and return truthful trusted evidence.
class AgentCallRideBookingTrustedBackendExecutor {
  const AgentCallRideBookingTrustedBackendExecutor({
    required this.completionGateway,
    this.completionContract =
        const AgentCallRideBookingExactlyOnceCompletionContract(),
  });

  final AgentCallRideBookingExactlyOnceCompletionGateway completionGateway;

  final AgentCallRideBookingExactlyOnceCompletionContract completionContract;

  Future<AgentCallRideBookingFinalReceipt> execute({
    required AgentCallRideBookingBackendHandoffResult handoffResult,
    required DateTime now,
  }) async {
    if (!handoffResult.isReady || handoffResult.envelope == null) {
      return _notBooked(code: 'TRUSTED_BACKEND_HANDOFF_REQUIRED', now: now);
    }

    final AgentCallRideBookingBackendHandoffEnvelope envelope =
        handoffResult.envelope!;

    try {
      envelope.validate();
    } catch (_) {
      return _notBooked(code: 'TRUSTED_BACKEND_HANDOFF_INVALID', now: now);
    }

    if (!envelope.isFreshAt(now)) {
      return _notBooked(code: 'TRUSTED_BACKEND_HANDOFF_EXPIRED', now: now);
    }

    AgentCallRideBookingBackendCompletionReceipt backendReceipt;

    try {
      backendReceipt = await completionGateway.completeExactlyOnce(
        envelope: envelope,
      );
    } catch (_) {
      return _unknown(code: 'TRUSTED_BACKEND_EXECUTION_FAILED', now: now);
    }

    AgentCallRideBookingBackendCompletionReceipt validatedReceipt;

    try {
      validatedReceipt = completionContract.validateReceipt(
        envelope: envelope,
        receipt: backendReceipt,
        previousAcceptedRideId:
            backendReceipt.previousAcceptedRideIdBeforeCompletion,
      );
    } catch (_) {
      return _unknown(code: 'TRUSTED_BACKEND_RECEIPT_NOT_PROVEN', now: now);
    }

    final AgentCallRideBookingFinalReceipt
    result = AgentCallRideBookingFinalReceipt(
      status: AgentCallRideBookingFinalStatus.booked,
      code:
          validatedReceipt.status ==
              AgentCallRideBookingBackendCompletionReceipt.alreadyCompleted
          ? 'RIDE_ALREADY_BOOKED_CONFIRMED'
          : 'RIDE_BOOKED_CONFIRMED',
      customerMessage:
          'Your ride is booked. Ride ID: ${validatedReceipt.rideId.trim()}.',
      rideId: validatedReceipt.rideId.trim(),
      backendExecutionReferenceId: validatedReceipt.backendExecutionReferenceId
          .trim(),
      completionSource: validatedReceipt.completionSource,
      backendInvoked: true,
      validatedExactlyOnce: true,
      reusedExistingCompletion: validatedReceipt.reusedExistingCompletion,
      createdAt: now.toUtc(),
    );

    result.validate();
    return result;
  }

  AgentCallRideBookingFinalReceipt _notBooked({
    required String code,
    required DateTime now,
  }) {
    final AgentCallRideBookingFinalReceipt
    result = AgentCallRideBookingFinalReceipt(
      status: AgentCallRideBookingFinalStatus.notBooked,
      code: code,
      customerMessage:
          'Your ride was not booked because the request was not ready for secure backend execution.',
      backendInvoked: false,
      validatedExactlyOnce: false,
      reusedExistingCompletion: false,
      createdAt: now.toUtc(),
    );

    result.validate();
    return result;
  }

  AgentCallRideBookingFinalReceipt _unknown({
    required String code,
    required DateTime now,
  }) {
    final AgentCallRideBookingFinalReceipt
    result = AgentCallRideBookingFinalReceipt(
      status: AgentCallRideBookingFinalStatus.bookingStatusUnknown,
      code: code,
      customerMessage:
          'The booking status could not be confirmed. Please do not assume a ride was booked.',
      backendInvoked: true,
      validatedExactlyOnce: false,
      reusedExistingCompletion: false,
      createdAt: now.toUtc(),
    );

    result.validate();
    return result;
  }

  bool get reusesStep1GExactlyOnceGateway => true;
  bool get hasDefaultProductionGateway => false;
  bool get canClaimSuccessFromHandoffOnly => false;
  bool get canClaimSuccessFromPreflightOnly => false;
  bool get canClaimSuccessFromCustomerBooleanOnly => false;
  bool get acceptsPlaceholderRideIdAsSuccess => false;
  bool get clientGeneratesRideId => false;
  bool get usesCurrentFirebaseUserAsCaller => false;

  bool get directlyWritesRide => false;
  bool get directlyWritesFirestore => false;
  bool get invokesHttpTransport => false;
  bool get invokesFirebaseFunctions => false;
  bool get invokesTelephonyProvider => false;
  bool get sendsSms => false;
}
