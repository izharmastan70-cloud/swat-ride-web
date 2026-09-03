import '../models/agent_call_service_request_draft.dart';
import 'agent_hotel_booking_read_only_connector.dart';

// =========================================================
// AI AGENT - CALL HOTEL READ-ONLY BRIDGE
// =========================================================
//
// Phase 32 Step 6.
//
// Converts already-sanitized Hotel booking data into a
// customer-friendly Call Agent status draft.
//
// PRIVACY:
// Internal/private identity fields are rejected.
//
// NO booking write.
// NO cancellation.
// NO check-in/out.
// NO payment/refund.
// NO no-show mutation.

class AgentCallHotelReadOnlyBridge {
  final AgentHotelBookingReadOnlyConnector hotelConnector;

  AgentCallHotelReadOnlyBridge({
    AgentHotelBookingReadOnlyConnector? hotelConnector,
  }) : hotelConnector =
            hotelConnector ??
            AgentHotelBookingReadOnlyConnector();

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
      throw const AgentCallHotelReadOnlyBridgeException(
        'bookingId cannot be empty.',
      );
    }

    verifySanitizedPayload(
      sanitizedBookingData,
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

    final String checkIn =
        _text(
          sanitizedBookingData,
          'checkInDate',
          fallback: 'not available',
        );

    final String checkOut =
        _text(
          sanitizedBookingData,
          'checkOutDate',
          fallback: 'not available',
        );

    final AgentCallServiceRequestDraft result =
        AgentCallServiceRequestDraft(
      serviceType:
          AgentCallServiceType.hotel,
      requestType:
          AgentCallServiceRequestType.status,
      customerName:
          customerName.trim(),
      contactPhoneMasked:
          contactPhoneMasked.trim(),
      referenceId:
          cleanBookingId,
      requestSummary:
          'Hotel booking $cleanBookingId, '
          'status: $status, '
          'payment: $payment, '
          'check-in: $checkIn, '
          'check-out: $checkOut',
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
      'guestPhone',
      'guestEmail',
      'guestCnic',
      'cnic',
      'phone',
      'email',
      'cardNumber',
      'cvv',
      'otp',
      'paymentToken',
      'homeAddress',
    };

    for (final String key in forbiddenKeys) {
      if (data.containsKey(key)) {
        throw AgentCallHotelReadOnlyBridgeException(
          'Sensitive Hotel field is not allowed in Call bridge: $key',
        );
      }
    }
  }

  String _text(
    Map<String, dynamic> data,
    String key, {
    String fallback = '',
  }) {
    final dynamic value = data[key];

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

class AgentCallHotelReadOnlyBridgeException
    implements Exception {
  final String message;

  const AgentCallHotelReadOnlyBridgeException(
    this.message,
  );

  @override
  String toString() =>
      'AgentCallHotelReadOnlyBridgeException: $message';
}