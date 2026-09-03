import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cargo_booking_model.dart';

class CargoBookingService {
  CargoBookingService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String collectionName = 'cargo_bookings';

  CollectionReference<Map<String, dynamic>> get _bookings =>
      _firestore.collection(collectionName);

  Future<String> createBooking(CargoBookingModel booking) async {
    final DocumentReference<Map<String, dynamic>> reference =
        booking.bookingId.trim().isEmpty
        ? _bookings.doc()
        : _bookings.doc(booking.bookingId.trim());

    final Map<String, dynamic> data = booking.toMap();

    data['bookingId'] = reference.id;

    await reference.set(data);

    return reference.id;
  }

  Future<CargoBookingModel?> getBooking(String bookingId) async {
    final String id = bookingId.trim();

    if (id.isEmpty) {
      return null;
    }

    final DocumentSnapshot<Map<String, dynamic>> snapshot = await _bookings
        .doc(id)
        .get();

    final Map<String, dynamic>? data = snapshot.data();

    if (!snapshot.exists || data == null) {
      return null;
    }

    data['bookingId'] ??= snapshot.id;

    return CargoBookingModel.fromMap(data);
  }

  Stream<CargoBookingModel?> watchBooking(String bookingId) {
    final String id = bookingId.trim();

    if (id.isEmpty) {
      return Stream<CargoBookingModel?>.value(null);
    }

    return _bookings.doc(id).snapshots().map((snapshot) {
      final Map<String, dynamic>? data = snapshot.data();

      if (!snapshot.exists || data == null) {
        return null;
      }

      data['bookingId'] ??= snapshot.id;

      return CargoBookingModel.fromMap(data);
    });
  }

  Stream<List<CargoBookingModel>> watchCustomerBookings(String customerId) {
    final String id = customerId.trim();

    if (id.isEmpty) {
      return Stream<List<CargoBookingModel>>.value(<CargoBookingModel>[]);
    }

    return _bookings.where('customerId', isEqualTo: id).snapshots().map((
      snapshot,
    ) {
      final List<CargoBookingModel> bookings = snapshot.docs.map((doc) {
        final Map<String, dynamic> data = doc.data();

        data['bookingId'] ??= doc.id;

        return CargoBookingModel.fromMap(data);
      }).toList();

      bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return bookings;
    });
  }

  Stream<List<CargoBookingModel>> watchDriverBookings(String driverId) {
    final String id = driverId.trim();

    if (id.isEmpty) {
      return Stream<List<CargoBookingModel>>.value(<CargoBookingModel>[]);
    }

    return _bookings.where('driverId', isEqualTo: id).snapshots().map((
      snapshot,
    ) {
      final List<CargoBookingModel> bookings = snapshot.docs.map((doc) {
        final Map<String, dynamic> data = doc.data();

        data['bookingId'] ??= doc.id;

        return CargoBookingModel.fromMap(data);
      }).toList();

      bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return bookings;
    });
  }

  Future<void> updateStatus({
    required String bookingId,
    required String status,
  }) async {
    final String id = bookingId.trim();

    if (id.isEmpty) {
      throw ArgumentError('bookingId cannot be empty.');
    }

    final Map<String, dynamic> update = <String, dynamic>{'status': status};

    if (status == CargoBookingModel.cancelled) {
      update['cancelledAt'] = Timestamp.now();
    }

    if (status == CargoBookingModel.delivered) {
      update['completedAt'] = Timestamp.now();
    }

    await _bookings.doc(id).update(update);
  }

  Future<void> assignDriver({
    required String bookingId,
    required String driverId,
  }) async {
    final String id = bookingId.trim();
    final String cargoDriverId = driverId.trim();

    if (id.isEmpty) {
      throw ArgumentError('bookingId cannot be empty.');
    }

    if (cargoDriverId.isEmpty) {
      throw ArgumentError('driverId cannot be empty.');
    }

    await _bookings.doc(id).update({
      'driverId': cargoDriverId,
      'status': CargoBookingModel.driverAssigned,
    });
  }

  Future<void> cancelBooking({
    required String bookingId,
    String? reason,
    double cancellationFee = 0,
    bool cancellationFeeWaived = false,
  }) async {
    final String id = bookingId.trim();

    if (id.isEmpty) {
      throw ArgumentError('bookingId cannot be empty.');
    }

    await _bookings.doc(id).update({
      'status': CargoBookingModel.cancelled,
      'cancellationReason': _nullableText(reason),
      'cancellationFee': cancellationFee < 0 ? 0 : cancellationFee,
      'cancellationFeeWaived': cancellationFeeWaived,
      'cancelledAt': Timestamp.now(),
    });
  }

  Future<void> updateFareSnapshot({
    required String bookingId,
    required double distanceKm,
    required double estimatedMinutes,
    required double totalFare,
    required double adminCommissionPercentage,
    required double commissionAmount,
    required double driverNetEarning,
    double baseFare = 0,
    double distanceFare = 0,
    double timeFare = 0,
    double weightCharge = 0,
    double loadingCharge = 0,
    double unloadingCharge = 0,
    double surgeAmount = 0,
  }) async {
    final String id = bookingId.trim();

    if (id.isEmpty) {
      throw ArgumentError('bookingId cannot be empty.');
    }

    await _bookings.doc(id).update({
      'distanceKm': _nonNegative(distanceKm),
      'estimatedMinutes': _nonNegative(estimatedMinutes),
      'baseFare': _nonNegative(baseFare),
      'distanceFare': _nonNegative(distanceFare),
      'timeFare': _nonNegative(timeFare),
      'weightCharge': _nonNegative(weightCharge),
      'loadingCharge': _nonNegative(loadingCharge),
      'unloadingCharge': _nonNegative(unloadingCharge),
      'surgeAmount': _nonNegative(surgeAmount),
      'totalFare': _nonNegative(totalFare),
      'adminCommissionPercentage': _percentage(adminCommissionPercentage),
      'commissionAmount': _nonNegative(commissionAmount),
      'driverNetEarning': _nonNegative(driverNetEarning),
      'fareCalculatedAt': Timestamp.now(),
    });
  }

  Future<void> markOffPlatformReported({
    required String bookingId,
    required String reportId,
  }) async {
    final String id = bookingId.trim();
    final String cargoReportId = reportId.trim();

    if (id.isEmpty || cargoReportId.isEmpty) {
      return;
    }

    await _bookings.doc(id).update({
      'offPlatformReported': true,
      'offPlatformReportId': cargoReportId,
    });
  }

  static double _nonNegative(double value) {
    if (!value.isFinite || value < 0) {
      return 0;
    }

    return value;
  }

  static double _percentage(double value) {
    if (!value.isFinite) {
      return 0;
    }

    return value.clamp(0, 100).toDouble();
  }

  static String? _nullableText(String? value) {
    final String result = value?.trim() ?? '';

    return result.isEmpty ? null : result;
  }
}
