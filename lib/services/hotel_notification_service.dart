import 'package:cloud_firestore/cloud_firestore.dart';

class HotelNotificationService {
  HotelNotificationService({
    FirebaseFirestore? firestore,
  }) : _firestore =
            firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String hotelCollection =
      'hotel_notifications';
  static const String customerCollection =
      'notifications';

  Future<String> createHotelNotification({
    required String hotelId,
    required String title,
    required String message,
    required String type,
    String bookingId = '',
    String userId = '',
    Map<String, dynamic> extraData =
        const <String, dynamic>{},
  }) async {
    if (hotelId.trim().isEmpty) {
      throw Exception('Hotel ID is required.');
    }

    final reference = _firestore
        .collection(hotelCollection)
        .doc();

    await reference.set(<String, dynamic>{
      'notificationId': reference.id,
      'hotelId': hotelId,
      'bookingId': bookingId,
      'userId': userId,
      'title': title.trim(),
      'message': message.trim(),
      'type': type.trim(),
      'isRead': false,
      'isDeleted': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      ...extraData,
    });

    return reference.id;
  }

  Future<String> createCustomerNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String hotelId = '',
    String bookingId = '',
    Map<String, dynamic> extraData =
        const <String, dynamic>{},
  }) async {
    if (userId.trim().isEmpty) {
      throw Exception(
        'Customer user ID is required.',
      );
    }

    final reference = _firestore
        .collection(customerCollection)
        .doc();

    await reference.set(<String, dynamic>{
      'notificationId': reference.id,
      'userId': userId,
      'hotelId': hotelId,
      'bookingId': bookingId,
      'title': title.trim(),
      'message': message.trim(),
      'type': type.trim(),
      'isRead': false,
      'isDeleted': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      ...extraData,
    });

    return reference.id;
  }

  Future<void> notifyNewBooking({
    required String hotelId,
    required String bookingId,
    required String userId,
    required String guestName,
    required String roomName,
  }) {
    return createHotelNotification(
      hotelId: hotelId,
      bookingId: bookingId,
      userId: userId,
      title: 'New Hotel Booking',
      message:
          '$guestName booked $roomName. Please review the booking.',
      type: 'new_booking',
    );
  }

  Future<void> notifyBookingApproved({
    required String userId,
    required String hotelId,
    required String bookingId,
    required String hotelName,
    String roomNumber = '',
  }) {
    final roomText = roomNumber.trim().isEmpty
        ? ''
        : ' Room $roomNumber has been assigned.';

    return createCustomerNotification(
      userId: userId,
      hotelId: hotelId,
      bookingId: bookingId,
      title: 'Hotel Booking Confirmed',
      message:
          'Your booking at $hotelName has been confirmed.$roomText',
      type: 'booking_confirmed',
    );
  }

  Future<void> notifyBookingRejected({
    required String userId,
    required String hotelId,
    required String bookingId,
    required String hotelName,
    required String reason,
  }) {
    return createCustomerNotification(
      userId: userId,
      hotelId: hotelId,
      bookingId: bookingId,
      title: 'Hotel Booking Rejected',
      message: reason.trim().isEmpty
          ? 'Your booking at $hotelName was rejected.'
          : 'Your booking at $hotelName was rejected. Reason: $reason',
      type: 'booking_rejected',
    );
  }

  Future<void> notifyBookingCancelled({
    required String hotelId,
    required String bookingId,
    required String userId,
    required String guestName,
    required String reason,
  }) {
    return createHotelNotification(
      hotelId: hotelId,
      bookingId: bookingId,
      userId: userId,
      title: 'Booking Cancelled',
      message: reason.trim().isEmpty
          ? '$guestName cancelled the booking.'
          : '$guestName cancelled the booking. Reason: $reason',
      type: 'booking_cancelled',
    );
  }

  Future<void> notifyQrReady({
    required String userId,
    required String hotelId,
    required String bookingId,
  }) {
    return createCustomerNotification(
      userId: userId,
      hotelId: hotelId,
      bookingId: bookingId,
      title: 'Check-in QR Ready',
      message:
          'Your secure QR and verification PIN are ready.',
      type: 'qr_ready',
    );
  }

  Future<void> notifyCheckedIn({
    required String userId,
    required String hotelId,
    required String bookingId,
    required String hotelName,
  }) {
    return createCustomerNotification(
      userId: userId,
      hotelId: hotelId,
      bookingId: bookingId,
      title: 'Hotel Check-in Complete',
      message:
          'You have successfully checked in at $hotelName.',
      type: 'checked_in',
    );
  }

  Future<void> notifyCheckedOut({
    required String userId,
    required String hotelId,
    required String bookingId,
    required String hotelName,
  }) {
    return createCustomerNotification(
      userId: userId,
      hotelId: hotelId,
      bookingId: bookingId,
      title: 'Hotel Check-out Complete',
      message:
          'Thank you for staying at $hotelName. You can now leave a review.',
      type: 'checked_out',
    );
  }

  Future<void> notifyRoomAssigned({
    required String userId,
    required String hotelId,
    required String bookingId,
    required String roomNumber,
  }) {
    return createCustomerNotification(
      userId: userId,
      hotelId: hotelId,
      bookingId: bookingId,
      title: 'Room Assigned',
      message:
          'Room $roomNumber has been assigned to your booking.',
      type: 'room_assigned',
    );
  }

  Future<void> notifyRoomChanged({
    required String userId,
    required String hotelId,
    required String bookingId,
    required String roomNumber,
  }) {
    return createCustomerNotification(
      userId: userId,
      hotelId: hotelId,
      bookingId: bookingId,
      title: 'Room Changed',
      message:
          'Your room has been changed to Room $roomNumber.',
      type: 'room_changed',
    );
  }

  Future<void> notifyStayExtended({
    required String userId,
    required String hotelId,
    required String bookingId,
    required int extraNights,
    required double addedAmount,
  }) {
    return createCustomerNotification(
      userId: userId,
      hotelId: hotelId,
      bookingId: bookingId,
      title: 'Hotel Stay Extended',
      message:
          'Your stay was extended by $extraNights night(s). Added amount: PKR ${_money(addedAmount)}.',
      type: 'stay_extended',
    );
  }

  Future<void> notifyPaymentUpdated({
    required String userId,
    required String hotelId,
    required String bookingId,
    required String paymentStatus,
    required double paidAmount,
    required double remainingAmount,
  }) {
    return createCustomerNotification(
      userId: userId,
      hotelId: hotelId,
      bookingId: bookingId,
      title: 'Hotel Payment Updated',
      message:
          'Status: $paymentStatus. Paid: PKR ${_money(paidAmount)}. Remaining: PKR ${_money(remainingAmount)}.',
      type: 'payment_updated',
      extraData: <String, dynamic>{
        'paymentStatus': paymentStatus,
        'paidAmount': paidAmount,
        'remainingAmount': remainingAmount,
        'realPaymentProcessed': false,
      },
    );
  }

  Future<void> notifyCheckInReminder({
    required String userId,
    required String hotelId,
    required String bookingId,
    required String hotelName,
    required DateTime checkInDate,
  }) {
    return createCustomerNotification(
      userId: userId,
      hotelId: hotelId,
      bookingId: bookingId,
      title: 'Hotel Check-in Reminder',
      message:
          'Your stay at $hotelName starts on ${_date(checkInDate)}.',
      type: 'check_in_reminder',
    );
  }

  Future<void> notifyCheckOutReminder({
    required String userId,
    required String hotelId,
    required String bookingId,
    required String hotelName,
    required DateTime checkOutDate,
  }) {
    return createCustomerNotification(
      userId: userId,
      hotelId: hotelId,
      bookingId: bookingId,
      title: 'Hotel Check-out Reminder',
      message:
          'Your check-out from $hotelName is on ${_date(checkOutDate)}.',
      type: 'check_out_reminder',
    );
  }

  Future<void> markRead({
    required String collection,
    required String notificationId,
  }) async {
    await _firestore
        .collection(collection)
        .doc(notificationId)
        .set(
      <String, dynamic>{
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> deleteNotification({
    required String collection,
    required String notificationId,
  }) async {
    await _firestore
        .collection(collection)
        .doc(notificationId)
        .set(
      <String, dynamic>{
        'isDeleted': true,
        'deletedAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  String _date(DateTime value) {
    final day =
        value.day.toString().padLeft(2, '0');
    final month =
        value.month.toString().padLeft(2, '0');

    return '$day/$month/${value.year}';
  }

  String _money(num amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
        );
  }
}
