import 'package:cloud_firestore/cloud_firestore.dart';

class DriverApplicationService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;


  // =========================================================
  // GET DRIVER APPLICATION
  // =========================================================

  Future<DocumentSnapshot<Map<String, dynamic>>>
      getDriverApplication(
    String applicationId,
  ) async {
    return await _firestore
        .collection('driver_applications')
        .doc(applicationId)
        .get();
  }

  // =========================================================
  // LISTEN TO DRIVER APPLICATION STATUS
  // =========================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      watchDriverApplication(
    String applicationId,
  ) {
    return _firestore
        .collection('driver_applications')
        .doc(applicationId)
        .snapshots();
  }

  // =========================================================
  // UPDATE APPLICATION STATUS
  // =========================================================

  Future<void> updateApplicationStatus({
    required String applicationId,
    required String status,
    String? rejectionReason,
    String? reviewedBy,
  }) async {
    await _firestore
        .collection('driver_applications')
        .doc(applicationId)
        .update({
      'status': status,
      'adminReview': {
        'reviewed': true,
        'reviewedBy': reviewedBy,
        'reviewedAt':
            FieldValue.serverTimestamp(),
        'rejectionReason':
            rejectionReason,
      },
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  // =========================================================
  // APPROVE DRIVER APPLICATION
  // =========================================================

  Future<void> approveApplication({
    required String applicationId,
    required String reviewedBy,
    String? driverId,
  }) async {
    final String id = applicationId.trim();
    if (id.isEmpty) {
      throw Exception('Application ID is required.');
    }

    final DocumentReference<Map<String, dynamic>> applicationReference =
        _firestore.collection('driver_applications').doc(id);

    await _firestore.runTransaction((Transaction transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await transaction.get(applicationReference);

      if (!snapshot.exists) {
        throw Exception('Driver application not found.');
      }

      final Map<String, dynamic> data = snapshot.data()!;
      final String resolvedDriverId = (driverId ??
              data['authorizedDriverId']?.toString() ??
              data['userId']?.toString() ??
              data['driverId']?.toString() ??
              '')
          .trim();

      if (resolvedDriverId.isEmpty) {
        throw Exception(
          'Applicant Firebase user ID is missing. Ask the applicant to submit again.',
        );
      }

      final String driverName =
          (data['fullName'] ?? data['name'] ?? 'SWAT RIDE Driver')
              .toString()
              .trim();
      final String phoneNumber =
          (data['phoneNumber'] ?? data['phone'] ?? '').toString().trim();
      final String cnicNumber =
          (data['cnicNumber'] ?? data['cnic'] ?? '').toString().trim();
      final String vehicleType =
          (data['vehicleType'] ?? 'Vehicle').toString().trim();
      final String vehicleNumber =
          (data['vehicleNumber'] ?? '').toString().trim();
      final String address = (data['address'] ?? '').toString().trim();

      final DocumentReference<Map<String, dynamic>> driverReference =
          _firestore.collection('drivers').doc(resolvedDriverId);

      transaction.set(
        driverReference,
        <String, dynamic>{
          'driverId': resolvedDriverId,
          'applicationId': id,
          'fullName': driverName,
          'name': driverName,
          'phoneNumber': phoneNumber,
          'phone': phoneNumber,
          'cnicNumber': cnicNumber,
          'cnic': cnicNumber,
          'address': address,
          'vehicleType': vehicleType,
          'vehicleNumber': vehicleNumber,
          'documents': data['documents'] ?? <String, dynamic>{},
          'vehicleApproval': <String, dynamic>{
            'status': 'approved',
            'reviewedBy': reviewedBy.trim(),
            'reviewedAt': FieldValue.serverTimestamp(),
          },
          'documentApproval': <String, dynamic>{
            'status': 'approved',
            'reviewedBy': reviewedBy.trim(),
            'reviewedAt': FieldValue.serverTimestamp(),
          },
          'primaryImageApproval': <String, dynamic>{
            'key': 'driverPhoto',
            'status': 'approved',
            'approvedUrl': (data['documents'] as Map?)?['driverPhoto'],
            'reviewedBy': reviewedBy.trim(),
            'reviewedAt': FieldValue.serverTimestamp(),
          },
          'status': 'approved',
          'isOnline': false,
          'isAvailable': false,
          'activeRideId': null,
          'rating': 0.0,
          'totalRatings': 0,
          'totalRides': 0,
          'approvedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      transaction.update(applicationReference, <String, dynamic>{
        'userId': resolvedDriverId,
        'driverId': resolvedDriverId,
        'status': 'approved',
        'adminReviewed': true,
        'adminReview': <String, dynamic>{
          'reviewed': true,
          'reviewedBy': reviewedBy.trim(),
          'reviewedAt': FieldValue.serverTimestamp(),
          'rejectionReason': null,
        },
        'reviewTimeline': <String, dynamic>{
          'vehicleStatus': 'approved',
          'documentsStatus': 'approved',
          'primaryImageStatus': 'approved',
          'reviewedBy': reviewedBy.trim(),
          'reviewedAt': FieldValue.serverTimestamp(),
        },
        'photoReview': <String, dynamic>{
          'primaryImageKey': 'driverPhoto',
          'primaryImageStatus': 'approved',
          'reviewedBy': reviewedBy.trim(),
          'reviewedAt': FieldValue.serverTimestamp(),
        },
        'driverAccount': <String, dynamic>{
          'created': true,
          'driverId': resolvedDriverId,
          'approvedAt': FieldValue.serverTimestamp(),
        },
        'approvedAt': FieldValue.serverTimestamp(),
        'rejectionReason': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // =========================================================
  // REJECT DRIVER APPLICATION
  // =========================================================

  Future<void> rejectApplication({
    required String applicationId,
    required String reviewedBy,
    required String rejectionReason,
  }) async {
    await updateApplicationStatus(
      applicationId: applicationId,
      status: 'rejected',
      reviewedBy: reviewedBy,
      rejectionReason: rejectionReason,
    );
  }

  // =========================================================
  // RESET APPLICATION TO PENDING
  // =========================================================

  Future<void> resetApplicationToPending({
    required String applicationId,
  }) async {
    await _firestore
        .collection('driver_applications')
        .doc(applicationId)
        .update({
      'status': 'pending',
      'adminReview': {
        'reviewed': false,
        'reviewedBy': null,
        'reviewedAt': null,
        'rejectionReason': null,
      },
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }
}
