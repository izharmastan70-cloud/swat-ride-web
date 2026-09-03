import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/hotel_booking.dart';
import 'hotel_booking_inventory_lock_service.dart';

class HotelBookingOperationsService {
  HotelBookingOperationsService({
    FirebaseFirestore? firestore,
  }) : _firestore =
            firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String bookingsCollection =
      'hotel_bookings';

  static const String notificationsCollection =
      'notifications';

  static const String chatsCollection =
      'hotel_chats';

  Stream<List<HotelBooking>> hotelBookingsStream(
    String hotelId,
  ) {
    return _firestore
        .collection(bookingsCollection)
        .where(
          'hotelId',
          isEqualTo: hotelId,
        )
        .snapshots()
        .map(
          (snapshot) {
            final List<HotelBooking> bookings =
                snapshot.docs
                    .map(
                      (doc) =>
                          HotelBooking.fromMap(
                        doc.data(),
                        doc.id,
                      ),
                    )
                    .toList();

            bookings.sort(
              (a, b) =>
                  b.createdAt.compareTo(
                a.createdAt,
              ),
            );

            return bookings;
          },
        );
  }

  Future<void> acceptBooking({
    required HotelBooking booking,
    required String agentUserId,
  }) async {
    await _ensureNoDateConflict(
      booking: booking,
    );

    final WriteBatch batch =
        _firestore.batch();

    final DocumentReference<Map<String, dynamic>>
        bookingRef = _firestore
            .collection(bookingsCollection)
            .doc(booking.id);

    batch.update(
      bookingRef,
      {
        'bookingStatus': 'confirmed',
        'confirmedByUserId': agentUserId,
        'confirmedAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
    );

    final DocumentReference<Map<String, dynamic>>
        notificationRef = _firestore
            .collection(notificationsCollection)
            .doc();

    batch.set(
      notificationRef,
      {
        'userId': booking.userId,
        'title': 'Hotel booking confirmed',
        'message':
            'Your hotel booking has been confirmed.',
        'type': 'hotel_booking_confirmed',
        'referenceId': booking.id,
        'isRead': false,
        'createdAt':
            FieldValue.serverTimestamp(),
      },
    );

    final DocumentReference<Map<String, dynamic>>
        chatRef = _firestore
            .collection(chatsCollection)
            .doc(booking.id);

    batch.set(
      chatRef,
      {
        'bookingId': booking.id,
        'hotelId': booking.hotelId,
        'userId': booking.userId,
        'lastMessage':
            'Your hotel booking has been confirmed.',
        'lastMessageType':
            'booking_confirmed',
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.set(
      chatRef.collection('messages').doc(),
      {
        'senderType': 'system',
        'senderId': 'auto_agent',
        'messageType':
            'booking_confirmed',
        'text':
            'Your hotel booking has been confirmed.',
        'isRead': false,
        'createdAt':
            FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
  }

  Future<void> rejectBooking({
    required HotelBooking booking,
    required String agentUserId,
    required String reason,
  }) async {
    final String cleanReason =
        reason.trim();

    if (cleanReason.isEmpty) {
      throw ArgumentError(
        'Rejection reason is required.',
      );
    }

    // Rejection is a terminal booking state.
    // The inventory service owns the atomic status change
    // and releases any managed room inventory locks.
    await HotelBookingInventoryLockService(
      firestore: _firestore,
    ).setTerminalStatusAndReleaseLocks(
      bookingId: booking.id,
      status: 'rejected',
    );

    final WriteBatch batch =
        _firestore.batch();

    final DocumentReference<Map<String, dynamic>>
        bookingRef = _firestore
            .collection(bookingsCollection)
            .doc(booking.id);

    // Preserve rejection/admin metadata without rewriting
    // the terminal status owned by the inventory service.
    batch.set(
      bookingRef,
      <String, dynamic>{
        'rejectedByUserId': agentUserId,
        'lastUpdatedBy': agentUserId,
        'rejectionReason': cleanReason,
        'rejectedAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    // Single canonical rejection notification.
    batch.set(
      _firestore
          .collection(notificationsCollection)
          .doc(),
      <String, dynamic>{
        'userId': booking.userId,
        'title':
            'Hotel booking not confirmed',
        'message': cleanReason,
        'type': 'hotel_booking_rejected',
        'referenceId': booking.id,
        'isRead': false,
        'createdAt':
            FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
  }
  Future<void> cancelBooking({
    required HotelBooking booking,
    required String agentUserId,
  }) async {
    // Cancellation is terminal. Inventory service owns
    // the atomic cancelled status + inventory release.
    await HotelBookingInventoryLockService(
      firestore: _firestore,
    ).setTerminalStatusAndReleaseLocks(
      bookingId: booking.id,
      status: 'cancelled',
    );

    await _firestore
        .collection(bookingsCollection)
        .doc(booking.id)
        .set(
      <String, dynamic>{
        'cancelledByUserId': agentUserId,
        'lastUpdatedBy': agentUserId,
        'cancellationRequestStatus': 'approved',
        'cancellationApprovedAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
  Future<void> markCheckedIn({
    required HotelBooking booking,
    required String agentUserId,
  }) async {
    if (booking.bookingStatus !=
        'confirmed') {
      throw StateError(
        'Only confirmed bookings can be checked in.',
      );
    }

    await _firestore
        .collection(bookingsCollection)
        .doc(booking.id)
        .update({
      'bookingStatus': 'checked_in',
      'checkedInByUserId': agentUserId,
      'checkedInAt':
          FieldValue.serverTimestamp(),
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  Future<void> markCheckedOut({
    required HotelBooking booking,
    required String agentUserId,
  }) async {
    if (booking.bookingStatus !=
        'checked_in') {
      throw StateError(
        'Guest must be checked in first.',
      );
    }

    final WriteBatch batch =
        _firestore.batch();

    batch.update(
      _firestore
          .collection(bookingsCollection)
          .doc(booking.id),
      {
        'bookingStatus': 'completed',
        'checkedOutByUserId':
            agentUserId,
        'checkedOutAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
    );

    batch.set(
      _firestore
          .collection(notificationsCollection)
          .doc(),
      {
        'userId': booking.userId,
        'title': 'Hotel stay completed',
        'message':
            'Your hotel stay has been marked completed. You can now rate your stay.',
        'type': 'hotel_booking_completed',
        'referenceId': booking.id,
        'isRead': false,
        'createdAt':
            FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
  }

  Future<void> markNoShow({
    required HotelBooking booking,
    required String agentUserId,
    required String note,
  }) async {
    await _firestore
        .collection(bookingsCollection)
        .doc(booking.id)
        .update({
      'bookingStatus': 'no_show',
      'noShowByUserId': agentUserId,
      'noShowNote': note.trim(),
      'noShowAt':
          FieldValue.serverTimestamp(),
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  Future<void> _ensureNoDateConflict({
    required HotelBooking booking,
  }) async {
    final QuerySnapshot<Map<String, dynamic>>
        snapshot = await _firestore
            .collection(bookingsCollection)
            .where(
              'roomId',
              isEqualTo: booking.roomId,
            )
            .get();

    for (final QueryDocumentSnapshot<
            Map<String, dynamic>>
        document in snapshot.docs) {
      if (document.id == booking.id) {
        continue;
      }

      final HotelBooking existing =
          HotelBooking.fromMap(
        document.data(),
        document.id,
      );

      final bool reservesRoom =
          existing.bookingStatus ==
                  'confirmed' ||
              existing.bookingStatus ==
                  'checked_in';

      if (!reservesRoom) {
        continue;
      }

      final bool overlaps =
          booking.checkIn.isBefore(
                existing.checkOut,
              ) &&
              booking.checkOut.isAfter(
                existing.checkIn,
              );

      if (overlaps) {
        throw StateError(
          'This room is already booked for the selected dates.',
        );
      }
    }
  }
}
