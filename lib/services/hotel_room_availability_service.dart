import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/hotel_room_availability.dart';

class HotelRoomAvailabilityService {
  HotelRoomAvailabilityService({
    FirebaseFirestore? firestore,
  }) : _firestore =
            firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String collectionName =
      'hotel_room_availability';

  Stream<List<HotelRoomAvailability>>
      hotelAvailabilityStream(
    String hotelId,
  ) {
    return _firestore
        .collection(collectionName)
        .where(
          'hotelId',
          isEqualTo: hotelId,
        )
        .orderBy(
          'startDate',
          descending: false,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    HotelRoomAvailability.fromMap(
                  doc.data(),
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  Stream<List<HotelRoomAvailability>>
      roomAvailabilityStream(
    String roomId,
  ) {
    return _firestore
        .collection(collectionName)
        .where(
          'roomId',
          isEqualTo: roomId,
        )
        .orderBy(
          'startDate',
          descending: false,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    HotelRoomAvailability.fromMap(
                  doc.data(),
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  Future<String> createAvailability(
    HotelRoomAvailability availability,
  ) async {
    _validate(availability);

    final DocumentReference<Map<String, dynamic>>
        document = await _firestore
            .collection(collectionName)
            .add({
      ...availability.toMap(),
      'createdAt':
          FieldValue.serverTimestamp(),
      'updatedAt':
          FieldValue.serverTimestamp(),
    });

    return document.id;
  }

  Future<void> updateAvailability({
    required String availabilityId,
    required HotelRoomAvailability availability,
  }) async {
    _validate(availability);

    await _firestore
        .collection(collectionName)
        .doc(availabilityId)
        .update({
      ...availability.toMap(),
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteAvailability(
    String availabilityId,
  ) async {
    await _firestore
        .collection(collectionName)
        .doc(availabilityId)
        .delete();
  }

  Future<bool> isRoomAvailableForDates({
    required String roomId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    if (!checkOut.isAfter(checkIn)) {
      throw ArgumentError(
        'Check-out must be after check-in.',
      );
    }

    final QuerySnapshot<Map<String, dynamic>>
        snapshot = await _firestore
            .collection(collectionName)
            .where(
              'roomId',
              isEqualTo: roomId,
            )
            .where(
              'isBlocked',
              isEqualTo: true,
            )
            .get();

    for (final QueryDocumentSnapshot<
            Map<String, dynamic>>
        document in snapshot.docs) {
      final HotelRoomAvailability availability =
          HotelRoomAvailability.fromMap(
        document.data(),
        document.id,
      );

      if (availability.overlaps(
        checkIn: checkIn,
        checkOut: checkOut,
      )) {
        return false;
      }
    }

    return true;
  }

  Future<double?> getPriceOverrideForDate({
    required String roomId,
    required DateTime date,
  }) async {
    final QuerySnapshot<Map<String, dynamic>>
        snapshot = await _firestore
            .collection(collectionName)
            .where(
              'roomId',
              isEqualTo: roomId,
            )
            .get();

    for (final QueryDocumentSnapshot<
            Map<String, dynamic>>
        document in snapshot.docs) {
      final HotelRoomAvailability availability =
          HotelRoomAvailability.fromMap(
        document.data(),
        document.id,
      );

      final bool insideRange =
          !date.isBefore(availability.startDate) &&
              date.isBefore(availability.endDate);

      if (insideRange &&
          availability.priceOverride != null) {
        return availability.priceOverride;
      }
    }

    return null;
  }

  void _validate(
    HotelRoomAvailability availability,
  ) {
    if (availability.hotelId.trim().isEmpty) {
      throw ArgumentError(
        'Hotel ID is required.',
      );
    }

    if (availability.roomId.trim().isEmpty) {
      throw ArgumentError(
        'Room ID is required.',
      );
    }

    if (!availability.endDate
        .isAfter(availability.startDate)) {
      throw ArgumentError(
        'End date must be after start date.',
      );
    }

    if (availability.priceOverride != null &&
        availability.priceOverride! < 0) {
      throw ArgumentError(
        'Price override cannot be negative.',
      );
    }
  }
}
