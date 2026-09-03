import '../models/agent_call_ride_booking_backend_handoff.dart';

/// Trusted backend implementation contract.
///
/// No default Flutter/client implementation is provided.
///
/// The backend must persist completion state atomically with the idempotency
/// key. First successful completion locks exactly one Ride ID.
/// Replays may return the SAME Ride ID only.
/// A different Ride ID for the same logical booking must fail closed.
abstract class AgentCallRideBookingExactlyOnceCompletionGateway {
  Future<AgentCallRideBookingBackendCompletionReceipt> completeExactlyOnce({
    required AgentCallRideBookingBackendHandoffEnvelope envelope,
  });
}

/// Pure validator for completion receipts returned by a trusted backend.
///
/// `previousAcceptedRideId` represents trusted backend persistent state.
/// Passing null means this is the first accepted completion.
/// This class does not itself persist anything.
class AgentCallRideBookingExactlyOnceCompletionContract {
  const AgentCallRideBookingExactlyOnceCompletionContract();

  AgentCallRideBookingBackendCompletionReceipt validateReceipt({
    required AgentCallRideBookingBackendHandoffEnvelope envelope,
    required AgentCallRideBookingBackendCompletionReceipt receipt,
    required String? previousAcceptedRideId,
  }) {
    envelope.validate();
    receipt.validate();

    if (!receipt.isSuccessfulCompletion) {
      throw const AgentCallRideBookingBackendHandoffException(
        'Blocked backend receipt cannot complete a booking.',
      );
    }

    if (receipt.idempotencyKey.trim() != envelope.idempotencyKey.trim()) {
      throw const AgentCallRideBookingBackendHandoffException(
        'Backend completion idempotency binding mismatch.',
      );
    }

    final String? previous = previousAcceptedRideId?.trim();

    final String? receiptPrevious = receipt
        .previousAcceptedRideIdBeforeCompletion
        ?.trim();

    final String normalizedPrevious = (previous == null || previous.isEmpty)
        ? ''
        : previous;

    final String normalizedReceiptPrevious =
        (receiptPrevious == null || receiptPrevious.isEmpty)
        ? ''
        : receiptPrevious;

    if (normalizedPrevious != normalizedReceiptPrevious) {
      throw const AgentCallRideBookingBackendHandoffException(
        'RECEIPT_PREVIOUS_RIDE_EVIDENCE_MISMATCH',
      );
    }

    if (previous == null || previous.isEmpty) {
      if (receipt.status !=
              AgentCallRideBookingBackendCompletionReceipt.created ||
          receipt.reusedExistingCompletion) {
        throw const AgentCallRideBookingBackendHandoffException(
          'First completion must be a new CREATED receipt.',
        );
      }

      return receipt;
    }

    if (receipt.rideId.trim() != previous) {
      throw const AgentCallRideBookingBackendHandoffException(
        'Exactly-once violation: idempotency key cannot bind another Ride ID.',
      );
    }

    if (receipt.status !=
            AgentCallRideBookingBackendCompletionReceipt.alreadyCompleted ||
        !receipt.reusedExistingCompletion) {
      throw const AgentCallRideBookingBackendHandoffException(
        'Replay must return ALREADY_COMPLETED for the same Ride ID.',
      );
    }

    return receipt;
  }

  bool get requiresTrustedPersistentState => true;
  bool get firstCompletionLocksOneRideId => true;
  bool get sameRideReplayAllowed => true;
  bool get differentRideReplayAllowed => false;
  bool get clientMemoryIsTrustedCompletionState => false;
  bool get completionReceiptIsAuthentication => false;
  bool get writesRide => false;
  bool get writesFirestore => false;
}
