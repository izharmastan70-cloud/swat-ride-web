import 'package:cloud_firestore/cloud_firestore.dart';

class SuperAdminVideoTrainingAccessService {
  SuperAdminVideoTrainingAccessService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String collectionName = 'help_video_training_entitlements';

  static const Set<String> allowedAudiences = <String>{
    'driver',
    'food_rider',
    'restaurant_partner',
    'hotel_partner',
    'tourism_driver',
    'tour_guide',
    'admin',
    'super_admin',
  };

  final FirebaseFirestore _firestore;

  Future<Map<String, dynamic>?> getAccess(String userId) async {
    final uid = _requiredUserId(userId);

    final snapshot = await _firestore.collection(collectionName).doc(uid).get();

    return snapshot.data();
  }

  Future<void> saveAccess({
    required String userId,
    required Set<String> audiences,
    required bool isActive,
    required String adminId,
  }) async {
    final uid = _requiredUserId(userId);

    final reviewer = adminId.trim();

    if (reviewer.isEmpty) {
      throw ArgumentError('Super Admin ID is required.');
    }

    final normalized =
        audiences
            .map((value) => value.trim().toLowerCase())
            .where(allowedAudiences.contains)
            .toSet()
            .toList(growable: false)
          ..sort();

    if (normalized.isEmpty && isActive) {
      throw ArgumentError(
        'At least one private training audience is required.',
      );
    }

    final reference = _firestore.collection(collectionName).doc(uid);

    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(reference);

      if (!existing.exists) {
        transaction.set(reference, <String, dynamic>{
          'userId': uid,
          'allowedAudiences': normalized,
          'isActive': isActive,
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': reviewer,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': reviewer,
        });

        return;
      }

      transaction.update(reference, <String, dynamic>{
        'allowedAudiences': normalized,
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': reviewer,
      });
    });
  }

  String _requiredUserId(String value) {
    final uid = value.trim();

    if (uid.isEmpty) {
      throw ArgumentError('Firebase user UID is required.');
    }

    return uid;
  }
}
