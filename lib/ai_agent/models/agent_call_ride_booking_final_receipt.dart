import 'agent_call_ride_booking_backend_handoff.dart';

class AgentCallRideBookingFinalStatus {
  AgentCallRideBookingFinalStatus._();

  /// May be presented to the customer as a successful booking.
  static const String booked = 'BOOKED';

  /// Backend was never invoked because the handoff was not execution-ready.
  static const String notBooked = 'NOT_BOOKED';

  /// Backend was invoked, but trustworthy final state could not be proven.
  static const String bookingStatusUnknown = 'BOOKING_STATUS_UNKNOWN';
}

/// Truthful customer-facing final booking receipt.
///
/// The Call Agent may state "ride booked" ONLY when [canStateRideBooked] is
/// true. Preflight, authorization, confirmation and handoff readiness are not
/// booking success.
class AgentCallRideBookingFinalReceipt {
  const AgentCallRideBookingFinalReceipt({
    required this.status,
    required this.code,
    required this.customerMessage,
    required this.createdAt,
    required this.backendInvoked,
    required this.validatedExactlyOnce,
    required this.reusedExistingCompletion,
    this.rideId,
    this.backendExecutionReferenceId,
    this.completionSource,
  });

  final String status;
  final String code;
  final String customerMessage;
  final DateTime createdAt;

  final bool backendInvoked;
  final bool validatedExactlyOnce;
  final bool reusedExistingCompletion;

  final String? rideId;
  final String? backendExecutionReferenceId;
  final String? completionSource;

  bool get isBooked => status == AgentCallRideBookingFinalStatus.booked;

  bool get canStateRideBooked =>
      isBooked &&
      backendInvoked &&
      validatedExactlyOnce &&
      (rideId?.trim().isNotEmpty ?? false) &&
      (backendExecutionReferenceId?.trim().isNotEmpty ?? false) &&
      completionSource ==
          AgentCallRideBookingBackendCompletionReceipt.trustedBackendSource;

  bool get realRideIdProven =>
      canStateRideBooked && (rideId?.trim().isNotEmpty ?? false);

  void validate() {
    if (status != AgentCallRideBookingFinalStatus.booked &&
        status != AgentCallRideBookingFinalStatus.notBooked &&
        status != AgentCallRideBookingFinalStatus.bookingStatusUnknown) {
      throw const AgentCallRideBookingFinalReceiptException(
        'Invalid final booking status.',
      );
    }

    if (code.trim().isEmpty || customerMessage.trim().isEmpty) {
      throw const AgentCallRideBookingFinalReceiptException(
        'Final booking code and customer message are required.',
      );
    }

    if (isBooked && !canStateRideBooked) {
      throw const AgentCallRideBookingFinalReceiptException(
        'BOOKED final receipt requires validated trusted backend Ride evidence.',
      );
    }

    if (!isBooked && (rideId?.trim().isNotEmpty ?? false)) {
      throw const AgentCallRideBookingFinalReceiptException(
        'Non-BOOKED final receipt cannot expose an unproven Ride ID.',
      );
    }

    if (status == AgentCallRideBookingFinalStatus.notBooked && backendInvoked) {
      throw const AgentCallRideBookingFinalReceiptException(
        'NOT_BOOKED is reserved for requests where backend was not invoked.',
      );
    }

    if (status == AgentCallRideBookingFinalStatus.bookingStatusUnknown &&
        !backendInvoked) {
      throw const AgentCallRideBookingFinalReceiptException(
        'BOOKING_STATUS_UNKNOWN requires an attempted backend execution.',
      );
    }
  }

  Map<String, dynamic> toCustomerSafeMap() {
    return <String, dynamic>{
      'status': status,
      'code': code,
      'customerMessage': customerMessage,
      'rideId': canStateRideBooked ? rideId!.trim() : null,
      'backendInvoked': backendInvoked,
      'validatedExactlyOnce': validatedExactlyOnce,
      'reusedExistingCompletion': reusedExistingCompletion,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'rawPhoneIncluded': false,
      'transcriptIncluded': false,
      'providerSecretIncluded': false,
    };
  }
}

class AgentCallRideBookingFinalReceiptException implements Exception {
  const AgentCallRideBookingFinalReceiptException(this.message);

  final String message;

  @override
  String toString() => 'AgentCallRideBookingFinalReceiptException: $message';
}
