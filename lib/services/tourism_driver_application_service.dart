import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/tourism_driver_application.dart';

class TourismDriverApplicationService {
  TourismDriverApplicationService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String collectionName =
      'tourism_driver_applications';

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  Future<String> saveDraft(
    TourismDriverApplication application,
  ) async {
    final reference = application.id.trim().isEmpty
        ? _collection.doc()
        : _collection.doc(application.id);

    await reference.set(
      <String, dynamic>{
        ...application.toMap(),
        'applicationStatus': 'draft',
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    return reference.id;
  }

  Future<String> submitApplication(
    TourismDriverApplication application,
  ) async {
    final reference = application.id.trim().isEmpty
        ? _collection.doc()
        : _collection.doc(application.id);

    await reference.set(
      <String, dynamic>{
        ...application.toMap(),
        'applicationStatus': 'submitted',
        'submittedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    return reference.id;
  }

  Future<TourismDriverApplication?> getApplicationById(
    String applicationId,
  ) async {
    final snapshot =
        await _collection.doc(applicationId).get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    return TourismDriverApplication.fromMap(
      snapshot.data()!,
      snapshot.id,
    );
  }

  Future<TourismDriverApplication?> getApplicationByUserId(
    String userId,
  ) async {
    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final document = snapshot.docs.first;

    return TourismDriverApplication.fromMap(
      document.data(),
      document.id,
    );
  }

  Stream<TourismDriverApplication?>
      watchApplicationByUserId(
    String userId,
  ) {
    return _collection
        .where('userId', isEqualTo: userId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return null;
      }

      final document = snapshot.docs.first;

      return TourismDriverApplication.fromMap(
        document.data(),
        document.id,
      );
    });
  }

  Stream<List<TourismDriverApplication>>
      watchApplications({
    String? status,
  }) {
    Query<Map<String, dynamic>> query = _collection;

    if (status != null && status.trim().isNotEmpty) {
      query = query.where(
        'applicationStatus',
        isEqualTo: status,
      );
    }

    return query.snapshots().map((snapshot) {
      final applications = snapshot.docs
          .map(
            (document) =>
                TourismDriverApplication.fromMap(
              document.data(),
              document.id,
            ),
          )
          .toList();

      applications.sort((a, b) {
        final aDate = a.updatedAt ??
            a.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);

        final bDate = b.updatedAt ??
            b.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);

        return bDate.compareTo(aDate);
      });

      return applications;
    });
  }

  Future<void> updateApplicationStatus({
    required String applicationId,
    required String status,
    String adminId = '',
    String adminNote = '',
    String rejectionReason = '',
  }) async {
    await _collection.doc(applicationId).set(
      <String, dynamic>{
        'applicationStatus': status,
        'adminId': adminId,
        'adminNote': adminNote,
        'rejectionReason': rejectionReason,
        'updatedAt': FieldValue.serverTimestamp(),
        if (status == 'approved')
          'approvedAt': FieldValue.serverTimestamp(),
        if (status == 'rejected')
          'rejectedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> approveApplication({
    required String applicationId,
    String adminId = '',
    String adminNote = '',
  }) {
    return updateApplicationStatus(
      applicationId: applicationId,
      status: 'approved',
      adminId: adminId,
      adminNote: adminNote,
    );
  }

  Future<void> rejectApplication({
    required String applicationId,
    required String rejectionReason,
    String adminId = '',
    String adminNote = '',
  }) {
    return updateApplicationStatus(
      applicationId: applicationId,
      status: 'rejected',
      adminId: adminId,
      adminNote: adminNote,
      rejectionReason: rejectionReason,
    );
  }

  Future<void> resetToPending({
    required String applicationId,
  }) {
    return updateApplicationStatus(
      applicationId: applicationId,
      status: 'submitted',
      rejectionReason: '',
    );
  }

  Future<void> setAvailability({
    required String applicationId,
    required bool isAvailable,
  }) async {
    await _collection.doc(applicationId).set(
      <String, dynamic>{
        'isAvailable': isAvailable,
        'availabilityUpdatedAt':
            FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> updateCurrentLocation({
    required String applicationId,
    required double latitude,
    required double longitude,
  }) async {
    await _collection.doc(applicationId).set(
      <String, dynamic>{
        'currentLocation': GeoPoint(
          latitude,
          longitude,
        ),
        'locationUpdatedAt':
            FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
