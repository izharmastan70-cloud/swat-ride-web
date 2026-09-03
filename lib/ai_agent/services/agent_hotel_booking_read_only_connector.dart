import '../../models/hotel_booking.dart';
import '../../services/hotel_booking_service.dart';

// =========================================================
// AI AGENT - HOTEL BOOKING READ-ONLY CONNECTOR
// =========================================================
//
// Phase 32 Step 4.
//
// Uses the EXISTING HotelBookingService.getBooking() read
// path.
//
// READ ONLY.
//
// It can:
// - load one exact booking by bookingId
// - return sanitized booking/status information
//
// It CANNOT:
// - accept/reject booking
// - cancel booking
// - check-in/check-out
// - mark no-show
// - refund/charge
// - expose guest CNIC/phone/email
// - change price/status/payment
//
// Future AgentReadOnlyConnectorRegistry registration will be
// done only after its framework request/payload contract is
// verified.

class AgentHotelBookingReadOnlyConnector {
  final HotelBookingService bookingService;

  AgentHotelBookingReadOnlyConnector({
    HotelBookingService? bookingService,
  }) : bookingService =
            bookingService ??
            HotelBookingService();

  String get connectorId =>
      'connector.hotel.booking.read_only';

  String get module => 'hotel';

  String get actionId =>
      'hotel.read_booking';

  Future<Map<String, dynamic>> readBooking({
    required String bookingId,
  }) async {
    final String cleanBookingId =
        bookingId.trim();

    if (cleanBookingId.isEmpty) {
      throw const AgentHotelBookingReadOnlyConnectorException(
        'bookingId cannot be empty.',
      );
    }

    final HotelBooking? booking =
        await bookingService.getBooking(
      cleanBookingId,
    );

    if (booking == null) {
      throw const AgentHotelBookingReadOnlyConnectorException(
        'Hotel booking was not found.',
      );
    }

    return <String, dynamic>{
      'bookingId': booking.id,
      'hotelId': booking.hotelId,
      'roomId': booking.roomId,
      'userId': booking.userId,
      'bookingStatus': booking.bookingStatus,
      'paymentStatus': booking.paymentStatus,
      'checkInDate':
          booking.checkIn.toIso8601String(),
      'checkOutDate':
          booking.checkOut.toIso8601String(),
      'readOnly': true,
    };
  }
}

class AgentHotelBookingReadOnlyConnectorException
    implements Exception {
  final String message;

  const AgentHotelBookingReadOnlyConnectorException(
    this.message,
  );

  @override
  String toString() =>
      'AgentHotelBookingReadOnlyConnectorException: $message';
}