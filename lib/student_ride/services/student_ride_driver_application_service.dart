import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/student_ride_driver_application_model.dart';

class StudentRideDriverApplicationService {
  StudentRideDriverApplicationService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _applications =>
      _firestore.collection('student_ride_driver_applications');

  CollectionReference<Map<String, dynamic>> get _drivers =>
      _firestore.collection('drivers');

  String get _requiredUserId {
    final String? userId = _auth.currentUser?.uid;

    if (userId == null || userId.trim().isEmpty) {
      throw Exception('User is not logged in.');
    }

    return userId.trim();
  }

  Future<String> submitApplication(
    StudentRideDriverApplicationModel application,
  ) async {
    final String userId = _requiredUserId;

    _validateApplication(application);

    final DocumentReference<Map<String, dynamic>> reference =
        _applications.doc(userId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      final Map<String, dynamic>? oldData = snapshot.data();

      if (snapshot.exists && oldData != null) {
        final String oldStatus =
            oldData['status']?.toString() ?? '';

        if (oldStatus ==
                StudentRideDriverApplicationStatus.submitted.name ||
            oldStatus ==
                StudentRideDriverApplicationStatus.underReview.name ||
            oldStatus ==
                StudentRideDriverApplicationStatus.approved.name) {
          throw Exception(
            'A Student Ride Driver application already exists.',
          );
        }
      }

      final Map<String, dynamic> data = application.toMap()
        ..['id'] = userId
        ..['userId'] = userId
        ..['status'] =
            StudentRideDriverApplicationStatus.submitted.name
        ..['rejectionReason'] = ''
        ..['adminNotes'] = ''
        ..['reviewedBy'] = ''
        ..['submittedAt'] = FieldValue.serverTimestamp()
        ..['reviewedAt'] = null
        ..['updatedAt'] = FieldValue.serverTimestamp();

      if (!snapshot.exists) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }

      transaction.set(
        reference,
        data,
        SetOptions(merge: true),
      );
    });

    return userId;
  }

  Future<StudentRideDriverApplicationModel?> getMyApplication() async {
    final String userId = _requiredUserId;
    final snapshot = await _applications.doc(userId).get();
    final data = snapshot.data();

    if (!snapshot.exists || data == null) return null;

    return StudentRideDriverApplicationModel.fromMap(
      data,
      documentId: snapshot.id,
    );
  }

  Stream<StudentRideDriverApplicationModel?>
      watchMyApplication() {
    final String userId = _requiredUserId;

    return _applications.doc(userId).snapshots().map((snapshot) {
      final data = snapshot.data();

      if (!snapshot.exists || data == null) return null;

      return StudentRideDriverApplicationModel.fromMap(
        data,
        documentId: snapshot.id,
      );
    });
  }

  Stream<List<StudentRideDriverApplicationModel>>
      watchAllApplications({
    StudentRideDriverApplicationStatus? status,
  }) {
    Query<Map<String, dynamic>> query = _applications;

    if (status != null) {
      query = query.where(
        'status',
        isEqualTo: status.name,
      );
    }

    return query.snapshots().map((snapshot) {
      final List<StudentRideDriverApplicationModel> items =
          snapshot.docs
              .map(
                (document) =>
                    StudentRideDriverApplicationModel.fromMap(
                  document.data(),
                  documentId: document.id,
                ),
              )
              .toList();

      items.sort((first, second) {
        final DateTime firstDate =
            first.submittedAt ?? DateTime(2000);
        final DateTime secondDate =
            second.submittedAt ?? DateTime(2000);
        return secondDate.compareTo(firstDate);
      });

      return items;
    });
  }

  Future<void> markUnderReview({
    required String applicationId,
    required String adminId,
  }) {
    return _updateApplicationStatus(
      applicationId: applicationId,
      status: StudentRideDriverApplicationStatus.underReview,
      adminId: adminId,
    );
  }

  Future<void> approveApplication({
    required String applicationId,
    required String adminId,
    String adminNotes = '',
  }) async {
    final String normalizedApplicationId =
        applicationId.trim();
    final String normalizedAdminId = adminId.trim();

    if (normalizedApplicationId.isEmpty) {
      throw Exception('Application ID is required.');
    }

    if (normalizedAdminId.isEmpty) {
      throw Exception('Admin ID is required.');
    }

    final applicationReference =
        _applications.doc(normalizedApplicationId);

    await _firestore.runTransaction((transaction) async {
      final applicationSnapshot =
          await transaction.get(applicationReference);

      if (!applicationSnapshot.exists) {
        throw Exception(
          'Student Ride Driver application was not found.',
        );
      }

      final Map<String, dynamic> data =
          applicationSnapshot.data()!;

      final String currentStatus =
          data['status']?.toString() ?? '';

      if (currentStatus ==
          StudentRideDriverApplicationStatus.approved.name) {
        return;
      }

      if (currentStatus ==
          StudentRideDriverApplicationStatus.suspended.name) {
        throw Exception(
          'Suspended application cannot be approved directly.',
        );
      }

      final String userId =
          data['userId']?.toString().trim() ?? '';

      final String existingNormalDriverId =
          data['existingNormalDriverId']?.toString().trim() ?? '';

      final String driverId = existingNormalDriverId.isNotEmpty
          ? existingNormalDriverId
          : userId;

      if (driverId.isEmpty) {
        throw Exception('Driver account ID is missing.');
      }

      final driverReference = _drivers.doc(driverId);

      transaction.set(
        applicationReference,
        <String, dynamic>{
          'status':
              StudentRideDriverApplicationStatus.approved.name,
          'approvedDriverId': driverId,
          'rejectionReason': '',
          'adminNotes': adminNotes.trim(),
          'reviewedBy': normalizedAdminId,
          'reviewedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      transaction.set(
        driverReference,
        <String, dynamic>{
          'driverId': driverId,
          'userId': userId,
          'name': data['fullName'],
          'phoneNumber': data['phoneNumber'],
          'vehicleType': data['vehicleType'],
          'vehicleMake': data['vehicleMake'],
          'vehicleModel': data['vehicleModel'],
          'vehicleColor': data['vehicleColor'],
          'vehicleRegistrationNumber':
              data['vehicleRegistrationNumber'],
          'studentRideApproved': true,
          'studentRideApplicationId':
              normalizedApplicationId,
          'studentRideStatus': 'approved',
          'studentRideMorningAvailable':
              data['morningAvailable'] == true,
          'studentRideAfternoonAvailable':
              data['afternoonAvailable'] == true,
          'studentRideVehicleCapacity':
              data['seatingCapacity'] ?? 1,
          'studentRideAssignedSchoolIds':
              data['preferredSchoolIds'] ?? <String>[],
          'studentRideAssignedRouteIds':
              data['preferredRouteIds'] ?? <String>[],
          'studentRideApprovedBy': normalizedAdminId,
          'studentRideApprovedAt':
              FieldValue.serverTimestamp(),
          'walletBalance':
              FieldValue.increment(0),
          'outstandingCommission':
              FieldValue.increment(0),
          'totalCommissionPaid':
              FieldValue.increment(0),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  Future<void> rejectApplication({
    required String applicationId,
    required String adminId,
    required String reason,
    String adminNotes = '',
  }) async {
    final String normalizedReason = reason.trim();

    if (normalizedReason.length < 3) {
      throw Exception('Enter a valid rejection reason.');
    }

    await _updateApplicationStatus(
      applicationId: applicationId,
      status: StudentRideDriverApplicationStatus.rejected,
      adminId: adminId,
      rejectionReason: normalizedReason,
      adminNotes: adminNotes,
    );
  }

  Future<void> suspendStudentRideDriver({
    required String applicationId,
    required String adminId,
    required String reason,
  }) async {
    final String normalizedApplicationId =
        applicationId.trim();
    final String normalizedAdminId = adminId.trim();
    final String normalizedReason = reason.trim();

    if (normalizedApplicationId.isEmpty ||
        normalizedAdminId.isEmpty ||
        normalizedReason.length < 3) {
      throw Exception(
        'Application, Admin and suspension reason are required.',
      );
    }

    final applicationReference =
        _applications.doc(normalizedApplicationId);

    await _firestore.runTransaction((transaction) async {
      final snapshot =
          await transaction.get(applicationReference);

      if (!snapshot.exists) {
        throw Exception('Application was not found.');
      }

      final data = snapshot.data()!;
      final String approvedDriverId =
          data['approvedDriverId']?.toString().trim() ?? '';

      transaction.set(
        applicationReference,
        <String, dynamic>{
          'status':
              StudentRideDriverApplicationStatus.suspended.name,
          'adminNotes': normalizedReason,
          'reviewedBy': normalizedAdminId,
          'reviewedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (approvedDriverId.isNotEmpty) {
        transaction.set(
          _drivers.doc(approvedDriverId),
          <String, dynamic>{
            'studentRideApproved': false,
            'studentRideStatus': 'suspended',
            'studentRideSuspensionReason': normalizedReason,
            'studentRideSuspendedBy': normalizedAdminId,
            'studentRideSuspendedAt':
                FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    });
  }

  Future<void> _updateApplicationStatus({
    required String applicationId,
    required StudentRideDriverApplicationStatus status,
    required String adminId,
    String rejectionReason = '',
    String adminNotes = '',
  }) async {
    final String normalizedApplicationId =
        applicationId.trim();
    final String normalizedAdminId = adminId.trim();

    if (normalizedApplicationId.isEmpty) {
      throw Exception('Application ID is required.');
    }

    if (normalizedAdminId.isEmpty) {
      throw Exception('Admin ID is required.');
    }

    await _applications.doc(normalizedApplicationId).set(
      <String, dynamic>{
        'status': status.name,
        'rejectionReason': rejectionReason.trim(),
        'adminNotes': adminNotes.trim(),
        'reviewedBy': normalizedAdminId,
        'reviewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  void _validateApplication(
    StudentRideDriverApplicationModel application,
  ) {
    if (application.fullName.trim().length < 3) {
      throw Exception('Enter Driver full name.');
    }

    if (application.phoneNumber.trim().length < 10) {
      throw Exception('Enter a valid phone number.');
    }

    if (application.cnicNumber.trim().length < 13) {
      throw Exception('Enter a valid CNIC number.');
    }

    if (application.drivingLicenseNumber.trim().isEmpty) {
      throw Exception('Driving licence is required.');
    }

    if (application.vehicleRegistrationNumber.trim().isEmpty) {
      throw Exception('Vehicle registration is required.');
    }

    if (application.seatingCapacity < 1) {
      throw Exception('Vehicle seating capacity is invalid.');
    }

    if (!application.hasRequiredConsent) {
      throw Exception(
        'Child safety declaration and background consent are required.',
      );
    }

    if (!application.hasValidAvailability) {
      throw Exception(
        'Select morning or afternoon availability.',
      );
    }
  }
}
