import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/hotel.dart';
import '../models/hotel_room.dart';
import '../models/tour_destination.dart';
import '../models/tour_package.dart';
import '../models/tour_vehicle.dart';

class TourismService {
  TourismService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // =========================================================
  // FIRESTORE COLLECTION NAMES
  // =========================================================

  static const String destinationsCollection =
      'tour_destinations';

  static const String packagesCollection =
      'tour_packages';

  static const String vehiclesCollection =
      'tour_vehicles';

  static const String hotelsCollection =
      'hotels';

  static const String roomsCollection =
      'hotel_rooms';

  // =========================================================
  // TOUR DESTINATIONS - READ
  // =========================================================

  Future<List<TourDestination>>
      getTourDestinations() async {
    final QuerySnapshot<Map<String, dynamic>>
        snapshot = await _firestore
            .collection(destinationsCollection)
            .where(
              'isActive',
              isEqualTo: true,
            )
            .get();

    return snapshot.docs
        .map(
          (doc) => TourDestination.fromMap(
            doc.data(),
            doc.id,
          ),
        )
        .toList();
  }

  Future<List<TourDestination>>
      getFeaturedDestinations() async {
    final QuerySnapshot<Map<String, dynamic>>
        snapshot = await _firestore
            .collection(destinationsCollection)
            .where(
              'isActive',
              isEqualTo: true,
            )
            .where(
              'isFeatured',
              isEqualTo: true,
            )
            .get();

    return snapshot.docs
        .map(
          (doc) => TourDestination.fromMap(
            doc.data(),
            doc.id,
          ),
        )
        .toList();
  }

  Future<TourDestination?>
      getTourDestinationById(
    String destinationId,
  ) async {
    final DocumentSnapshot<Map<String, dynamic>>
        doc = await _firestore
            .collection(destinationsCollection)
            .doc(destinationId)
            .get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return TourDestination.fromMap(
      doc.data()!,
      doc.id,
    );
  }

  // =========================================================
  // TOUR PACKAGES - READ
  // =========================================================

  Future<List<TourPackage>>
      getTourPackages() async {
    final QuerySnapshot<Map<String, dynamic>>
        snapshot = await _firestore
            .collection(packagesCollection)
            .where(
              'isActive',
              isEqualTo: true,
            )
            .get();

    return snapshot.docs
        .map(
          (doc) => TourPackage.fromMap(
            doc.data(),
            doc.id,
          ),
        )
        .toList();
  }

  Future<List<TourPackage>>
      getFeaturedTourPackages() async {
    final QuerySnapshot<Map<String, dynamic>>
        snapshot = await _firestore
            .collection(packagesCollection)
            .where(
              'isActive',
              isEqualTo: true,
            )
            .where(
              'isFeatured',
              isEqualTo: true,
            )
            .get();

    return snapshot.docs
        .map(
          (doc) => TourPackage.fromMap(
            doc.data(),
            doc.id,
          ),
        )
        .toList();
  }

  Future<TourPackage?>
      getTourPackageById(
    String packageId,
  ) async {
    final DocumentSnapshot<Map<String, dynamic>>
        doc = await _firestore
            .collection(packagesCollection)
            .doc(packageId)
            .get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return TourPackage.fromMap(
      doc.data()!,
      doc.id,
    );
  }

  // =========================================================
  // TOUR VEHICLES - READ
  // =========================================================

  Future<List<TourVehicle>>
      getTourVehicles() async {
    final QuerySnapshot<Map<String, dynamic>>
        snapshot = await _firestore
            .collection(vehiclesCollection)
            .where(
              'isAvailable',
              isEqualTo: true,
            )
            .get();

    return snapshot.docs
        .map(
          (doc) => TourVehicle.fromMap(
            doc.data(),
            doc.id,
          ),
        )
        .toList();
  }

  Future<List<TourVehicle>>
      getVehiclesBySeats(
    int requiredSeats,
  ) async {
    final QuerySnapshot<Map<String, dynamic>>
        snapshot = await _firestore
            .collection(vehiclesCollection)
            .where(
              'isAvailable',
              isEqualTo: true,
            )
            .where(
              'seats',
              isGreaterThanOrEqualTo:
                  requiredSeats,
            )
            .get();

    return snapshot.docs
        .map(
          (doc) => TourVehicle.fromMap(
            doc.data(),
            doc.id,
          ),
        )
        .toList();
  }

  // =========================================================
  // HOTELS - USER READ
  // =========================================================

  Future<List<Hotel>> getHotels() async {
    final QuerySnapshot<Map<String, dynamic>>
        snapshot = await _firestore
            .collection(hotelsCollection)
            .where(
              'isActive',
              isEqualTo: true,
            )
            .get();

    return snapshot.docs
        .map(
          (doc) => Hotel.fromMap(
            doc.data(),
            doc.id,
          ),
        )
        .toList();
  }

  Stream<List<Hotel>> hotelsStream() {
    return _firestore
        .collection(hotelsCollection)
        .where(
          'isActive',
          isEqualTo: true,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => Hotel.fromMap(
                  doc.data(),
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  Future<List<Hotel>>
      getHotelsByLocation(
    String location,
  ) async {
    final QuerySnapshot<Map<String, dynamic>>
        snapshot = await _firestore
            .collection(hotelsCollection)
            .where(
              'location',
              isEqualTo: location,
            )
            .where(
              'isActive',
              isEqualTo: true,
            )
            .get();

    return snapshot.docs
        .map(
          (doc) => Hotel.fromMap(
            doc.data(),
            doc.id,
          ),
        )
        .toList();
  }

  Future<List<Hotel>>
      getHotelsByCategory(
    String category,
  ) async {
    final QuerySnapshot<Map<String, dynamic>>
        snapshot = await _firestore
            .collection(hotelsCollection)
            .where(
              'category',
              isEqualTo: category,
            )
            .where(
              'isActive',
              isEqualTo: true,
            )
            .get();

    return snapshot.docs
        .map(
          (doc) => Hotel.fromMap(
            doc.data(),
            doc.id,
          ),
        )
        .toList();
  }

  Future<List<Hotel>>
      getFeaturedHotels() async {
    final QuerySnapshot<Map<String, dynamic>>
        snapshot = await _firestore
            .collection(hotelsCollection)
            .where(
              'isActive',
              isEqualTo: true,
            )
            .where(
              'isFeatured',
              isEqualTo: true,
            )
            .get();

    return snapshot.docs
        .map(
          (doc) => Hotel.fromMap(
            doc.data(),
            doc.id,
          ),
        )
        .toList();
  }

  Future<Hotel?> getHotelById(
    String hotelId,
  ) async {
    final DocumentSnapshot<Map<String, dynamic>>
        doc = await _firestore
            .collection(hotelsCollection)
            .doc(hotelId)
            .get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return Hotel.fromMap(
      doc.data()!,
      doc.id,
    );
  }

  // =========================================================
  // HOTEL ROOMS - USER READ
  // =========================================================

  Future<List<HotelRoom>> getHotelRooms(
    String hotelId,
  ) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _firestore
            .collection(roomsCollection)
            .where(
              'hotelId',
              isEqualTo: hotelId,
            )
            .get();

    return snapshot.docs
        .map(
          (doc) => HotelRoom.fromMap(
            doc.data(),
            doc.id,
          ),
        )
        .where(
          (room) => room.isAvailable,
        )
        .toList();
  }

  Stream<List<HotelRoom>>
      hotelRoomsStream(
    String hotelId,
  ) {
    return _firestore
        .collection(roomsCollection)
        .where(
          'hotelId',
          isEqualTo: hotelId,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => HotelRoom.fromMap(
                  doc.data(),
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  Future<HotelRoom?> getHotelRoomById(
    String roomId,
  ) async {
    final DocumentSnapshot<Map<String, dynamic>>
        doc = await _firestore
            .collection(roomsCollection)
            .doc(roomId)
            .get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return HotelRoom.fromMap(
      doc.data()!,
      doc.id,
    );
  }

  // =========================================================
  // ADMIN HOTEL MANAGEMENT
  // =========================================================
  //
  // IMPORTANT:
  // Firestore Security Rules must allow these methods only
  // for authenticated admin users with an admin role/claim.
  // Rider/normal users must never receive write permission.
  //
  // Firebase Storage image upload remains deferred because
  // billing is unavailable. imageUrl can still store a safe
  // existing URL or remain empty during testing.
  //
  // =========================================================

  Future<String> adminCreateHotel(
    Hotel hotel,
  ) async {
    final Map<String, dynamic> data = {
      ...hotel.toMap(),
      'createdAt':
          FieldValue.serverTimestamp(),
      'updatedAt':
          FieldValue.serverTimestamp(),
    };

    final DocumentReference<Map<String, dynamic>>
        document = await _firestore
            .collection(hotelsCollection)
            .add(data);

    return document.id;
  }

  Future<void> adminUpdateHotel({
    required String hotelId,
    required Hotel hotel,
  }) async {
    await _firestore
        .collection(hotelsCollection)
        .doc(hotelId)
        .update({
      ...hotel.toMap(),
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  Future<void> adminSetHotelActive({
    required String hotelId,
    required bool isActive,
  }) async {
    await _firestore
        .collection(hotelsCollection)
        .doc(hotelId)
        .update({
      'isActive': isActive,
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  Future<void> adminSetHotelFeatured({
    required String hotelId,
    required bool isFeatured,
  }) async {
    await _firestore
        .collection(hotelsCollection)
        .doc(hotelId)
        .update({
      'isFeatured': isFeatured,
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  Future<void> adminDeleteHotel(
    String hotelId,
  ) async {
    final WriteBatch batch =
        _firestore.batch();

    final QuerySnapshot<Map<String, dynamic>>
        roomSnapshot = await _firestore
            .collection(roomsCollection)
            .where(
              'hotelId',
              isEqualTo: hotelId,
            )
            .get();

    for (final QueryDocumentSnapshot<
            Map<String, dynamic>>
        room in roomSnapshot.docs) {
      batch.delete(room.reference);
    }

    batch.delete(
      _firestore
          .collection(hotelsCollection)
          .doc(hotelId),
    );

    await batch.commit();
  }

  // =========================================================
  // ADMIN ROOM MANAGEMENT
  // =========================================================

  Future<String> adminCreateHotelRoom(
    HotelRoom room,
  ) async {
    final Map<String, dynamic> data = {
      ...room.toMap(),
      'roomName': room.roomType,
      'capacity': room.maxGuests,
      'amenities': room.facilities,
      'isActive': true,
      'manualStatus':
          room.isAvailable ? 'available' : 'blocked',
      'createdAt':
          FieldValue.serverTimestamp(),
      'updatedAt':
          FieldValue.serverTimestamp(),
    };

    final DocumentReference<Map<String, dynamic>>
        document = await _firestore
            .collection(roomsCollection)
            .add(data);

    return document.id;
  }

  Future<void> adminUpdateHotelRoom({
    required String roomId,
    required HotelRoom room,
  }) async {
    await _firestore
        .collection(roomsCollection)
        .doc(roomId)
        .update({
      ...room.toMap(),
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  Future<void> adminSetRoomAvailability({
    required String roomId,
    required bool isAvailable,
  }) async {
    await _firestore
        .collection(roomsCollection)
        .doc(roomId)
        .update({
      'isAvailable': isAvailable,
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  Future<void> adminDeleteHotelRoom(
    String roomId,
  ) async {
    await _firestore
        .collection(roomsCollection)
        .doc(roomId)
        .delete();
  }
}
