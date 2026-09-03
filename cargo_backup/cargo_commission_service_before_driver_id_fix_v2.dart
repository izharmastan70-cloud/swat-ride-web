import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cargo_booking_model.dart';
import '../models/cargo_driver_application_model.dart';

class CargoCommissionService {
  CargoCommissionService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _bookings =>
      _firestore.collection('cargo_bookings');

  CollectionReference<Map<String, dynamic>> get _driverApplications =>
      _firestore.collection('cargo_driver_applications');

  /// Records Cargo commission after a booking is delivered.
  ///
  /// Cash:
  /// Admin commission becomes outstanding against the driver.
  ///
  /// Non-cash:
  /// No fake settlement is made here. Gateway/platform
  /// collection will be recorded only when real payment is
  /// actually verified.
  ///
  /// Idempotent:
  /// A booking can only be processed once.
  Future<void> processDeliveredBooking(String bookingId) async {
    final String id = bookingId.trim();

    if (id.isEmpty) {
      throw ArgumentError('bookingId cannot be empty.');
    }

    final DocumentReference<Map<String, dynamic>> bookingReference = _bookings
        .doc(id);

    final DocumentSnapshot<Map<String, dynamic>> bookingSnapshot =
        await bookingReference.get();

    final Map<String, dynamic>? bookingData = bookingSnapshot.data();

    if (!bookingSnapshot.exists || bookingData == null) {
      throw StateError('Cargo booking not found.');
    }

    final CargoBookingModel booking = CargoBookingModel.fromMap(
      <String, dynamic>{...bookingData, 'bookingId': bookingSnapshot.id},
    );

    if (booking.status != CargoBookingModel.delivered) {
      return;
    }

    if (bookingData['commissionProcessed'] == true) {
      return;
    }

    final String driverId = booking.driverId?.trim() ?? '';

    if (driverId.isEmpty) {
      throw StateError('Delivered Cargo booking has no driver.');
    }

    final double commissionAmount = booking.commissionAmount;

    if (!commissionAmount.isFinite || commissionAmount < 0) {
      throw StateError('Cargo booking has invalid commission amount.');
    }

    final String paymentMethod =
        booking.paymentMethod?.trim().toLowerCase() ?? '';

    final QuerySnapshot<Map<String, dynamic>> driverQuery =
        await _driverApplications.where('userId', isEqualTo: driverId).get();

    QueryDocumentSnapshot<Map<String, dynamic>>? driverDocument;

    for (final doc in driverQuery.docs) {
      final CargoDriverApplicationModel application =
          CargoDriverApplicationModel.fromMap(<String, dynamic>{
            ...doc.data(),
            'applicationId': doc.id,
          });

      if (application.status == CargoDriverApplicationModel.approved) {
        driverDocument = doc;
        break;
      }
    }

    // Backward-safe fallback:
    // if driverId was ever stored as applicationId.
    if (driverDocument == null) {
      final DocumentSnapshot<Map<String, dynamic>> directDriver =
          await _driverApplications.doc(driverId).get();

      if (directDriver.exists && directDriver.data() != null) {
        driverDocument = _DriverDocumentAdapter(directDriver);
      }
    }

    if (driverDocument == null) {
      throw StateError('Approved Cargo Driver application not found.');
    }

    final DocumentReference<Map<String, dynamic>> driverReference =
        _driverApplications.doc(driverDocument.id);

    await _firestore.runTransaction((transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> freshBooking =
          await transaction.get(bookingReference);

      final Map<String, dynamic>? freshData = freshBooking.data();

      if (!freshBooking.exists || freshData == null) {
        throw StateError(
          'Cargo booking not found during commission processing.',
        );
      }

      if (freshData['commissionProcessed'] == true) {
        return;
      }

      final DocumentSnapshot<Map<String, dynamic>> freshDriver =
          await transaction.get(driverReference);

      final Map<String, dynamic>? driverData = freshDriver.data();

      if (!freshDriver.exists || driverData == null) {
        throw StateError('Cargo Driver application not found.');
      }

      if (paymentMethod == 'cash') {
        final double currentOutstanding = _safeNumber(
          driverData['outstandingCommission'],
        );

        transaction.update(driverReference, <String, dynamic>{
          'outstandingCommission': currentOutstanding + commissionAmount,
          'commissionUpdatedAt': Timestamp.now(),
        });

        transaction.update(bookingReference, <String, dynamic>{
          'commissionProcessed': true,
          'commissionAccountingStatus': 'driver_outstanding',
          'commissionProcessedAt': Timestamp.now(),
        });

        return;
      }

      // Online/wallet/card commission must NOT be
      // marked collected until real payment is verified.
      transaction.update(bookingReference, <String, dynamic>{
        'commissionProcessed': true,
        'commissionAccountingStatus': 'awaiting_verified_payment',
        'commissionProcessedAt': Timestamp.now(),
      });
    });
  }

  static double _safeNumber(dynamic value) {
    if (value is num) {
      final double number = value.toDouble();

      if (number.isFinite && number >= 0) {
        return number;
      }
    }

    if (value is String) {
      final double? number = double.tryParse(value);

      if (number != null && number.isFinite && number >= 0) {
        return number;
      }
    }

    return 0;
  }
}
