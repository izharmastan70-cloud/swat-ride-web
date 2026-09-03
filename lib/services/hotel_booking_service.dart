import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/hotel_booking.dart';
import 'hotel_service_control_service.dart';
import 'hotel_booking_inventory_lock_service.dart';

class HotelBookingService {
  HotelBookingService({
    FirebaseFirestore? firestore,
  }) : _firestore =
            firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // =========================================================
  // FIRESTORE COLLECTION
  // =========================================================

  CollectionReference<Map<String, dynamic>>
      get _bookingsCollection =>
          _firestore.collection('hotel_bookings');

  // =========================================================
  // CREATE HOTEL BOOKING
  // =========================================================

  Future<void> _requireHotelActiveForBooking(
    String hotelId,
  ) async {
    final String normalizedHotelId = hotelId.trim();

    if (normalizedHotelId.isEmpty) {
      throw StateError(
        'Hotel ID is missing. Booking cannot continue.',
      );
    }

    DocumentSnapshot<Map<String, dynamic>> hotelDocument =
        await _firestore
            .collection('hotels')
            .doc(normalizedHotelId)
            .get();

    if (!hotelDocument.exists) {
      final QuerySnapshot<Map<String, dynamic>> hotelQuery =
          await _firestore
              .collection('hotels')
              .where(
                'hotelId',
                isEqualTo: normalizedHotelId,
              )
              .limit(1)
              .get();

      if (hotelQuery.docs.isNotEmpty) {
        hotelDocument = hotelQuery.docs.first;
      }
    }

    if (!hotelDocument.exists ||
        hotelDocument.data() == null) {
      throw StateError(
        'Selected hotel is no longer available.',
      );
    }

    final Map<String, dynamic> hotelData =
        hotelDocument.data()!;

    if (hotelData['isActive'] == false ||
        hotelData['isDeleted'] == true) {
      throw StateError(
        'This hotel is currently unavailable for new bookings.',
      );
    }
  }
  DateTime? _readBookingSafetyDate(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }

  Future<void> _requireRoomAvailableForBooking(
    HotelBooking booking,
  ) async {
    final String hotelId =
        booking.hotelId.trim();

    final String roomId =
        booking.roomId.trim();

    if (hotelId.isEmpty) {
      throw StateError(
        'Hotel ID is missing. Booking cannot continue.',
      );
    }

    if (roomId.isEmpty) {
      throw StateError(
        'Room ID is missing. Booking cannot continue.',
      );
    }

    if (!booking.checkOut.isAfter(
      booking.checkIn,
    )) {
      throw StateError(
        'Check-out must be after check-in.',
      );
    }

    if (booking.rooms <= 0) {
      throw StateError(
        'At least one room must be selected.',
      );
    }

    // =====================================================
    // RESOLVE ROOM
    // =====================================================

    DocumentSnapshot<Map<String, dynamic>>
        roomDocument = await _firestore
            .collection('hotel_rooms')
            .doc(roomId)
            .get();

    if (!roomDocument.exists) {
      final QuerySnapshot<Map<String, dynamic>>
          roomQuery = await _firestore
              .collection('hotel_rooms')
              .where(
                'roomId',
                isEqualTo: roomId,
              )
              .limit(1)
              .get();

      if (roomQuery.docs.isNotEmpty) {
        roomDocument =
            roomQuery.docs.first;
      }
    }

    if (!roomDocument.exists ||
        roomDocument.data() == null) {
      throw StateError(
        'Selected room is no longer available.',
      );
    }

    final Map<String, dynamic> roomData =
        roomDocument.data()!;

    final String roomHotelId =
        roomData['hotelId']
                ?.toString()
                .trim() ??
            '';

    if (roomHotelId.isNotEmpty &&
        roomHotelId != hotelId) {
      throw StateError(
        'Selected room does not belong to this hotel.',
      );
    }

    if (roomData['isDeleted'] == true ||
        roomData['isActive'] == false) {
      throw StateError(
        'Selected room is currently inactive.',
      );
    }

    final String manualStatus =
        (roomData['manualStatus'] ??
                roomData['status'] ??
                'available')
            .toString()
            .trim()
            .toLowerCase();

    if (manualStatus == 'maintenance' ||
        manualStatus == 'housekeeping' ||
        manualStatus == 'blocked') {
      throw StateError(
        'Selected room is currently unavailable.',
      );
    }

    final dynamic quantityValue =
        roomData['availableQuantity'] ??
            roomData['quantity'];

    int inventory = 1;

    if (quantityValue is num) {
      inventory =
          quantityValue.toInt();
    } else if (quantityValue != null) {
      inventory =
          int.tryParse(
            quantityValue.toString(),
          ) ??
          1;
    }

    if (inventory <= 0) {
      throw StateError(
        'No room inventory is currently available.',
      );
    }

    if (booking.rooms > inventory) {
      throw StateError(
        'Requested room quantity exceeds available inventory.',
      );
    }

    // =====================================================
    // BLOCKED DATE RULES
    // =====================================================

    final QuerySnapshot<Map<String, dynamic>>
        availabilitySnapshot =
        await _firestore
            .collection('hotel_room_availability')
            .where(
              'roomId',
              isEqualTo: roomId,
            )
            .get();

    for (final QueryDocumentSnapshot<
            Map<String, dynamic>>
        availability
        in availabilitySnapshot.docs) {
      final Map<String, dynamic> data =
          availability.data();

      if (data['isBlocked'] != true) {
        continue;
      }

      final DateTime? start =
          _readBookingSafetyDate(
        data['startDate'],
      );

      final DateTime? end =
          _readBookingSafetyDate(
        data['endDate'],
      );

      if (start == null || end == null) {
        continue;
      }

      final bool overlaps =
          booking.checkIn.isBefore(end) &&
              booking.checkOut.isAfter(start);

      if (overlaps) {
        throw StateError(
          'Selected room is blocked for the requested dates.',
        );
      }
    }

    // =====================================================
    // EXISTING BOOKING OVERLAP / INVENTORY
    // =====================================================

    final QuerySnapshot<Map<String, dynamic>>
        bookingSnapshot =
        await _bookingsCollection
            .where(
              'roomId',
              isEqualTo: roomId,
            )
            .get();

    int overlappingReservedRooms = 0;

    const Set<String> terminalStatuses =
        <String>{
      'cancelled',
      'rejected',
      'completed',
      'checked_out',
    };

    for (final QueryDocumentSnapshot<
            Map<String, dynamic>>
        document
        in bookingSnapshot.docs) {
      final Map<String, dynamic> data =
          document.data();

      final String existingHotelId =
          data['hotelId']
                  ?.toString()
                  .trim() ??
              '';

      if (existingHotelId.isNotEmpty &&
          existingHotelId != hotelId) {
        continue;
      }

      final String status =
          (data['bookingStatus'] ?? '')
              .toString()
              .trim()
              .toLowerCase();

      if (terminalStatuses.contains(
        status,
      )) {
        continue;
      }

      final DateTime? existingCheckIn =
          _readBookingSafetyDate(
        data['checkIn'],
      );

      final DateTime? existingCheckOut =
          _readBookingSafetyDate(
        data['checkOut'],
      );

      if (existingCheckIn == null ||
          existingCheckOut == null) {
        continue;
      }

      final bool overlaps =
          booking.checkIn.isBefore(
            existingCheckOut,
          ) &&
          booking.checkOut.isAfter(
            existingCheckIn,
          );

      if (!overlaps) {
        continue;
      }

      final dynamic existingRoomsValue =
          data['rooms'];

      int reservedRooms = 1;

      if (existingRoomsValue is num) {
        reservedRooms =
            existingRoomsValue.toInt();
      } else if (existingRoomsValue !=
          null) {
        reservedRooms =
            int.tryParse(
              existingRoomsValue
                  .toString(),
            ) ??
            1;
      }

      if (reservedRooms <= 0) {
        reservedRooms = 1;
      }

      overlappingReservedRooms +=
          reservedRooms;
    }

    if (overlappingReservedRooms +
            booking.rooms >
        inventory) {
      throw StateError(
        'Requested room is already booked for the selected dates.',
      );
    }
  }
  Future<String> createBooking(
    HotelBooking booking,
  ) async {
    final HotelServiceDecision decision =
        await HotelServiceControlService(
      firestore: _firestore,
    ).canCreateBooking();

    if (!decision.isAllowed) {
      throw StateError(decision.message);
    }

    await _requireHotelActiveForBooking(
      booking.hotelId,
    );

    await _requireRoomAvailableForBooking(
      booking,
    );

    try {
      return await HotelBookingInventoryLockService(
        firestore: _firestore,
      ).createBookingAtomically(
        booking,
      );
    } catch (e) {
      throw Exception(
        'Unable to create hotel booking: $e',
      );
    }
  }

  // =========================================================
  // GET SINGLE HOTEL BOOKING
  // =========================================================

  Future<HotelBooking?> getBooking(
    String bookingId,
  ) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>>
          snapshot =
          await _bookingsCollection
              .doc(bookingId)
              .get();

      if (!snapshot.exists ||
          snapshot.data() == null) {
        return null;
      }

      return HotelBooking.fromMap(
        snapshot.data()!,
        snapshot.id,
      );
    } catch (e) {
      throw Exception(
        'Unable to load hotel booking: $e',
      );
    }
  }

  // =========================================================
  // GET USER HOTEL BOOKINGS
  // =========================================================

  Future<List<HotelBooking>>
      getUserBookings(
    String userId,
  ) async {
    try {
      final QuerySnapshot<Map<String, dynamic>>
          snapshot =
          await _bookingsCollection
              .where(
                'userId',
                isEqualTo: userId,
              )
              .orderBy(
                'createdAt',
                descending: true,
              )
              .get();

      return snapshot.docs
          .map(
            (doc) => HotelBooking.fromMap(
              doc.data(),
              doc.id,
            ),
          )
          .toList();
    } catch (e) {
      throw Exception(
        'Unable to load user hotel bookings: $e',
      );
    }
  }

  // =========================================================
  // USER HOTEL BOOKINGS - REALTIME
  // =========================================================

  Stream<List<HotelBooking>>
      userBookingsStream(
    String userId,
  ) {
    return _bookingsCollection
        .where(
          'userId',
          isEqualTo: userId,
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) =>
                        HotelBooking.fromMap(
                      doc.data(),
                      doc.id,
                    ),
                  )
                  .toList(),
        );
  }

  // =========================================================
  // UPDATE BOOKING STATUS
  // =========================================================

  Future<void> updateBookingStatus({
    required String bookingId,
    required String status,
  }) async {
    try {
      final String normalizedStatus =
          status.trim().toLowerCase();

      if (normalizedStatus == 'cancelled' ||
          normalizedStatus == 'rejected') {
        await HotelBookingInventoryLockService(
          firestore: _firestore,
        ).setTerminalStatusAndReleaseLocks(
          bookingId: bookingId,
          status: normalizedStatus,
        );

        return;
      }

      await _bookingsCollection
          .doc(bookingId)
          .update({
        'bookingStatus': status,
        'updatedAt':
            FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception(
        'Unable to update hotel booking status: $e',
      );
    }
  }

  // =========================================================
  // CONFIRM BOOKING
  // =========================================================

  Future<void> confirmBooking(
    String bookingId,
  ) async {
    await updateBookingStatus(
      bookingId: bookingId,
      status: 'confirmed',
    );
  }

  // =========================================================
  // CANCEL BOOKING
  // =========================================================

  Future<void> cancelBooking(
    String bookingId,
  ) async {
    await updateBookingStatus(
      bookingId: bookingId,
      status: 'cancelled',
    );
  }

  // =========================================================
  // COMPLETE BOOKING
  // =========================================================

  Future<void> completeBooking(
    String bookingId,
  ) async {
    await updateBookingStatus(
      bookingId: bookingId,
      status: 'completed',
    );
  }

  // =========================================================
  // DELETE BOOKING
  // =========================================================

  Future<void> deleteBooking(
    String bookingId,
  ) async {
    try {
      await _bookingsCollection
          .doc(bookingId)
          .delete();
    } catch (e) {
      throw Exception(
        'Unable to delete hotel booking: $e',
      );
    }
  }

  // =========================================================
  // UPDATE PAYMENT STATUS
  // =========================================================

  Future<void> updatePaymentStatus({
    required String bookingId,
    required String paymentStatus,
  }) async {
    try {
      await _bookingsCollection
          .doc(bookingId)
          .update({
        'paymentStatus':
            paymentStatus,
        'updatedAt':
            FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception(
        'Unable to update hotel payment status: $e',
      );
    }
  }

  // =========================================================
  // MARK PAYMENT AS PAID
  // =========================================================

  Future<void> markPaymentPaid(
    String bookingId,
  ) async {
    throw StateError(
      'Real hotel payment cannot be marked paid from the client. '
      'A verified payment provider/backend confirmation is required.',
    );
  }

  // =========================================================
  // MARK PAYMENT AS PENDING
  // =========================================================

  Future<void> markPaymentPending(
    String bookingId,
  ) async {
    await updatePaymentStatus(
      bookingId: bookingId,
      paymentStatus: 'pending',
    );
  }
}
