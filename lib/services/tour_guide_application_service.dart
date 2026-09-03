import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/tour_guide_application.dart';

class TourGuideApplicationService {
  TourGuideApplicationService({
    FirebaseFirestore? firestore,
  }) : _firestore =
            firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String collectionName =
      'tour_guide_applications';

  static const String notificationsCollection =
      'notifications';

  Future<String> saveDraft(
    TourGuideApplication application,
  ) async {
    final Map<String, dynamic> data = {
      ...application.toMap(),
      'applicationStatus': 'draft',
      'isCustomerAccessEnabled': true,
      'updatedAt':
          FieldValue.serverTimestamp(),
    };

    if (application.id.isNotEmpty) {
      await _firestore
          .collection(collectionName)
          .doc(application.id)
          .set(
            data,
            SetOptions(merge: true),
          );

      return application.id;
    }

    final DocumentReference<Map<String, dynamic>>
        document = await _firestore
            .collection(collectionName)
            .add({
      ...data,
      'createdAt':
          FieldValue.serverTimestamp(),
    });

    return document.id;
  }

  Future<String> submitApplication(
    TourGuideApplication application,
  ) async {
    _validate(application);

    final Map<String, dynamic> data = {
      ...application.toMap(),
      'applicationStatus': 'submitted',
      'isCustomerAccessEnabled': true,
      'adminId': '',
      'adminNote': '',
      'rejectionReason': '',
      'submittedAt':
          FieldValue.serverTimestamp(),
      'updatedAt':
          FieldValue.serverTimestamp(),
    };

    String applicationId;

    if (application.id.isNotEmpty) {
      applicationId = application.id;

      await _firestore
          .collection(collectionName)
          .doc(applicationId)
          .set(
            data,
            SetOptions(merge: true),
          );
    } else {
      final DocumentReference<Map<String, dynamic>>
          document = await _firestore
              .collection(collectionName)
              .add({
        ...data,
        'createdAt':
            FieldValue.serverTimestamp(),
      });

      applicationId = document.id;
    }

    await _firestore
        .collection(notificationsCollection)
        .add({
      'userId': application.userId,
      'title':
          'Tour guide application submitted',
      'message':
          'Your application is waiting for admin review.',
      'type':
          'tour_guide_application_submitted',
      'referenceId': applicationId,
      'isRead': false,
      'createdAt':
          FieldValue.serverTimestamp(),
    });

    return applicationId;
  }

  Stream<TourGuideApplication?>
      userApplicationStream(
    String userId,
  ) {
    return _firestore
        .collection(collectionName)
        .where(
          'userId',
          isEqualTo: userId,
        )
        .orderBy(
          'updatedAt',
          descending: true,
        )
        .limit(1)
        .snapshots()
        .map(
          (snapshot) {
            if (snapshot.docs.isEmpty) {
              return null;
            }

            final QueryDocumentSnapshot<
                    Map<String, dynamic>>
                document = snapshot.docs.first;

            return TourGuideApplication.fromMap(
              document.data(),
              document.id,
            );
          },
        );
  }

  void _validate(
    TourGuideApplication application,
  ) {
    if (application.userId.trim().isEmpty) {
      throw ArgumentError(
        'User ID is required.',
      );
    }

    if (application.fullName.trim().isEmpty) {
      throw ArgumentError(
        'Guide name is required.',
      );
    }

    if (application.phoneNumber.trim().isEmpty) {
      throw ArgumentError(
        'Phone number is required.',
      );
    }

    if (application.cnic.trim().isEmpty) {
      throw ArgumentError(
        'CNIC is required.',
      );
    }

    if (application.languages.isEmpty) {
      throw ArgumentError(
        'At least one language is required.',
      );
    }

    if (application.destinations.isEmpty) {
      throw ArgumentError(
        'At least one destination is required.',
      );
    }

    if (application.guideTypes.isEmpty) {
      throw ArgumentError(
        'At least one guide type is required.',
      );
    }
  }
}
