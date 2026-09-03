import '../../models/tour_booking.dart';
import '../../services/tour_booking_service.dart';

// =========================================================
// AI AGENT - TOUR BOOKING READ-ONLY CONNECTOR
// =========================================================
//
// Phase 32 Step 5B.
//
// Uses the EXISTING TourBookingService.getBooking().
//
// MINIMUM-DATA READ ONLY.
//
// Exposes only support/status-safe fields.
//
// DOES NOT expose:
// - userId
// - pickup coordinates
// - specialRequest
// - financial amounts
// - private assignment identities
//
// NO create/cancel/update.
// NO payment.
// NO assignment mutation.
// NO customer/driver punishment.

class AgentTourBookingReadOnlyConnector {
  final TourBookingService bookingService;

  AgentTourBookingReadOnlyConnector({
    TourBookingService? bookingService,
  }) : bookingService =
            bookingService ??
            TourBookingService();

  String get connectorId =>
      'connector.tour.booking.read_only';

  String get module => 'tour';

  String get actionId =>
      'tour.read_booking';

  Future<Map<String, dynamic>> readBooking({
    required String bookingId,
  }) async {
    final String cleanBookingId =
        bookingId.trim();

    if (cleanBookingId.isEmpty) {
      throw const AgentTourBookingReadOnlyConnectorException(
        'bookingId cannot be empty.',
      );
    }

    final TourBooking? booking =
        await bookingService.getBooking(
      cleanBookingId,
    );

    if (booking == null) {
      throw const AgentTourBookingReadOnlyConnectorException(
        'Tour booking was not found.',
      );
    }

    return <String, dynamic>{
      'bookingId': booking.id,
      'tourType': booking.tourType,
      'bookingStatus': booking.bookingStatus,
      'paymentStatus': booking.paymentStatus,
      'assignmentStatus':
          booking.assignmentStatus,
      'startDate':
          booking.startDate.toIso8601String(),
      'endDate':
          booking.endDate.toIso8601String(),
      'hasDriver':
          booking.driverId.isNotEmpty,
      'hasGuide':
          booking.guideId.isNotEmpty,
      'hasVehicle':
          booking.vehicleId.isNotEmpty,
      'hasHotel':
          booking.hotelId.isNotEmpty,
      'readOnly': true,
    };
  }
}

class AgentTourBookingReadOnlyConnectorException
    implements Exception {
  final String message;

  const AgentTourBookingReadOnlyConnectorException(
    this.message,
  );

  @override
  String toString() =>
      'AgentTourBookingReadOnlyConnectorException: $message';
}