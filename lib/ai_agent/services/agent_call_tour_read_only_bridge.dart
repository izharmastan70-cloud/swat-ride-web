import '../models/agent_call_service_request_draft.dart';
import 'agent_tour_booking_read_only_connector.dart';

// =========================================================
// AI AGENT - CALL TOUR READ-ONLY BRIDGE
// =========================================================
//
// Converts already-sanitized Tour booking data into a
// customer-friendly Call Agent status draft.
//
// No booking write.
// No cancellation.
// No payment.
// No private identity exposure.

class AgentCallTourReadOnlyBridge {
  final AgentTourBookingReadOnlyConnector tourConnector;

  AgentCallTourReadOnlyBridge({
    AgentTourBookingReadOnlyConnector? tourConnector,
  }) : tourConnector =
            tourConnector ??
            AgentTourBookingReadOnlyConnector();

  AgentCallServiceRequestDraft
      buildBookingStatusDraft({
    required String customerName,
    required String contactPhoneMasked,
    required String bookingId,
    required Map<String, dynamic>
        sanitizedBookingData,
  }) {
    final String cleanBookingId =
        bookingId.trim();

    if (cleanBookingId.isEmpty) {
      throw const AgentCallTourReadOnlyBridgeException(
        'bookingId cannot be empty.',
      );
    }

    verifySanitizedPayload(
      sanitizedBookingData,
    );

    final String type =
        _text(
          sanitizedBookingData,
          'tourType',
          fallback: 'tour',
        );

    final String status =
        _text(
          sanitizedBookingData,
          'bookingStatus',
          fallback: 'unknown',
        );

    final String payment =
        _text(
          sanitizedBookingData,
          'paymentStatus',
          fallback: 'unknown',
        );

    final String assignment =
        _text(
          sanitizedBookingData,
          'assignmentStatus',
          fallback: 'unknown',
        );

    final AgentCallServiceRequestDraft result =
        AgentCallServiceRequestDraft(
      serviceType:
          AgentCallServiceType.tour,
      requestType:
          AgentCallServiceRequestType.status,
      customerName:
          customerName.trim(),
      contactPhoneMasked:
          contactPhoneMasked.trim(),
      referenceId:
          cleanBookingId,
      requestSummary:
          '$type booking $cleanBookingId, '
          'status: $status, '
          'payment: $payment, '
          'assignment: $assignment',
      customerConfirmed:
          false,
    );

    result.validate();

    return result;
  }

  void verifySanitizedPayload(
    Map<String, dynamic> data,
  ) {
    const Set<String> forbiddenKeys =
        <String>{
      'userId',
      'pickupLatitude',
      'pickupLongitude',
      'specialRequest',
      'totalAmount',
      'advanceAmount',
      'remainingAmount',
      'driverId',
      'guideId',
      'adminId',
      'partnerId',
      'phone',
      'cnic',
      'email',
    };

    for (final String key in forbiddenKeys) {
      if (data.containsKey(key)) {
        throw AgentCallTourReadOnlyBridgeException(
          'Sensitive Tour field is not allowed in Call bridge: $key',
        );
      }
    }
  }

  String _text(
    Map<String, dynamic> map,
    String key, {
    String fallback = '',
  }) {
    final dynamic value = map[key];

    if (value == null) {
      return fallback;
    }

    final String text =
        value.toString().trim();

    return text.isEmpty
        ? fallback
        : text;
  }
}

class AgentCallTourReadOnlyBridgeException
    implements Exception {
  final String message;

  const AgentCallTourReadOnlyBridgeException(
    this.message,
  );

  @override
  String toString() =>
      'AgentCallTourReadOnlyBridgeException: $message';
}