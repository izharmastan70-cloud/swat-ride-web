import 'package:cloud_firestore/cloud_firestore.dart';

class SuperAdminHotelOperationalService {
  SuperAdminHotelOperationalService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<DocumentReference<Map<String, dynamic>>> _resolveHotelReference(
    String hotelId,
  ) async {
    final String normalizedHotelId = hotelId.trim();

    if (normalizedHotelId.isEmpty) {
      throw StateError('Hotel ID is required.');
    }

    final DocumentReference<Map<String, dynamic>> directReference =
        _firestore.collection('hotels').doc(normalizedHotelId);

    final DocumentSnapshot<Map<String, dynamic>> directSnapshot =
        await directReference.get();

    if (directSnapshot.exists) {
      return directReference;
    }

    final QuerySnapshot<Map<String, dynamic>> querySnapshot =
        await _firestore
            .collection('hotels')
            .where(
              'hotelId',
              isEqualTo: normalizedHotelId,
            )
            .limit(1)
            .get();

    if (querySnapshot.docs.isEmpty) {
      throw StateError('Hotel record was not found.');
    }

    return querySnapshot.docs.first.reference;
  }

  Future<void> setHotelActive({
    required String hotelId,
    required bool isActive,
    required String adminId,
    required String reason,
  }) async {
    final String normalizedAdminId = adminId.trim();
    final String normalizedReason = reason.trim();

    if (normalizedAdminId.isEmpty) {
      throw StateError('Verified Super Admin ID is required.');
    }

    if (!isActive && normalizedReason.isEmpty) {
      throw StateError(
        'A reason is required before disabling a hotel.',
      );
    }

    final DocumentReference<Map<String, dynamic>> hotelReference =
        await _resolveHotelReference(hotelId);

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await hotelReference.get();

    if (!snapshot.exists || snapshot.data() == null) {
      throw StateError('Hotel record was not found.');
    }

    final Map<String, dynamic> currentData = snapshot.data()!;

    if (currentData['isDeleted'] == true) {
      throw StateError(
        'Deleted hotels cannot be enabled or disabled from operational control.',
      );
    }

    await hotelReference.update(
      <String, dynamic>{
        'isActive': isActive,
        'operationalStatus': isActive ? 'active' : 'disabled',
        'operationalReason': normalizedReason,
        'operationalUpdatedBy': normalizedAdminId,
        'operationalUpdatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> disableHotel({
    required String hotelId,
    required String adminId,
    required String reason,
  }) {
    return setHotelActive(
      hotelId: hotelId,
      isActive: false,
      adminId: adminId,
      reason: reason,
    );
  }

  Future<void> enableHotel({
    required String hotelId,
    required String adminId,
    String reason = '',
  }) {
    return setHotelActive(
      hotelId: hotelId,
      isActive: true,
      adminId: adminId,
      reason: reason,
    );
  }
}