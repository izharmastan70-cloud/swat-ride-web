import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DriverRegistrationService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseStorage _storage =
      FirebaseStorage.instance;

    static const String _applicationsCollection = 'driver_applications';

    Future<void> ensureVehicleIdentityAvailable({
        required String vehicleOwnerId,
        required String vehicleNumber,
        required String chassisNumber,
        required String cnicNumber,
    }) async {
        final String ownerId = vehicleOwnerId.trim();
        final String normalizedVehicleNumber = normalizeVehicleIdentity(vehicleNumber);
        final String normalizedChassisNumber = normalizeVehicleIdentity(chassisNumber);
        final String normalizedCnicNumber = normalizeVehicleIdentity(cnicNumber);

        if (ownerId.isEmpty || normalizedVehicleNumber.isEmpty ||
                normalizedChassisNumber.isEmpty || normalizedCnicNumber.isEmpty) {
            throw ArgumentError('Owner, registration, chassis and CNIC are required.');
        }

        await _ensureNoActiveApplication(
            field: 'vehicleNumberNormalized',
            value: normalizedVehicleNumber,
            message: 'This vehicle registration number already has an active application.',
        );
        await _ensureNoActiveApplication(
            field: 'chassisNumberNormalized',
            value: normalizedChassisNumber,
            message: 'This chassis number already has an active application.',
        );

        final QuerySnapshot<Map<String, dynamic>> ownerApplications = await _firestore
                .collection(_applicationsCollection)
                .where('cnicNumberNormalized', isEqualTo: normalizedCnicNumber)
                .get();
        for (final QueryDocumentSnapshot<Map<String, dynamic>> document
                in ownerApplications.docs) {
            final Map<String, dynamic> data = document.data();
            final String status = data['status']?.toString().toLowerCase() ?? '';
            final String existingOwner = data['vehicleOwnerId']?.toString().trim() ??
                    data['userId']?.toString().trim() ?? '';
            if ((status == 'pending' || status == 'approved') && existingOwner != ownerId) {
                throw StateError('This CNIC already belongs to another active owner application.');
            }
        }
    }

    static String normalizeVehicleIdentity(String value) =>
            value.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

    Future<void> _ensureNoActiveApplication({
        required String field,
        required String value,
        required String message,
    }) async {
        final QuerySnapshot<Map<String, dynamic>> existing = await _firestore
                .collection(_applicationsCollection)
                .where(field, isEqualTo: value)
                .get();
        if (existing.docs.any((document) {
            final String status = document.data()['status']?.toString().toLowerCase() ?? '';
            return status == 'pending' || status == 'approved';
        })) {
            throw StateError(message);
        }
    }

  // =========================================================
  // SUBMIT DRIVER APPLICATION
  // =========================================================

  Future<String> submitDriverApplication({
    required String fullName,
    required String phoneNumber,
    required String cnicNumber,
    required String vehicleType,
    required String vehicleNumber,
    required String chassisNumber,
    required String vehicleOwnerId,
    required String authorizedDriverId,
    required String address,

    // DRIVER DOCUMENTS
    required File cnicFrontImage,
    required File cnicBackImage,
    required File drivingLicenseFrontImage,
    required File drivingLicenseBackImage,
    required File vehicleRegistrationImage,
    required File vehiclePhotoImage,
    required File driverPhotoImage,
  }) async {
        await ensureVehicleIdentityAvailable(
            vehicleOwnerId: vehicleOwnerId,
            vehicleNumber: vehicleNumber,
            chassisNumber: chassisNumber,
            cnicNumber: cnicNumber,
        );

    // =======================================================
    // CREATE UNIQUE APPLICATION ID
    // =======================================================

    final DocumentReference applicationReference =
        _firestore.collection('driver_applications').doc();

    final String applicationId =
        applicationReference.id;

    // =======================================================
    // FIREBASE STORAGE ROOT
    // =======================================================

    final String storageRoot =
        'driver_applications/$applicationId';

    try {
      // =====================================================
      // UPLOAD CNIC FRONT
      // =====================================================

      final String cnicFrontUrl =
          await _uploadImage(
        file: cnicFrontImage,
        path: '$storageRoot/cnic_front.jpg',
      );

      // =====================================================
      // UPLOAD CNIC BACK
      // =====================================================

      final String cnicBackUrl =
          await _uploadImage(
        file: cnicBackImage,
        path: '$storageRoot/cnic_back.jpg',
      );

      // =====================================================
      // UPLOAD DRIVING LICENSE FRONT
      // =====================================================

      final String drivingLicenseFrontUrl =
          await _uploadImage(
        file: drivingLicenseFrontImage,
        path:
            '$storageRoot/driving_license_front.jpg',
      );

      // =====================================================
      // UPLOAD DRIVING LICENSE BACK
      // =====================================================

      final String drivingLicenseBackUrl =
          await _uploadImage(
        file: drivingLicenseBackImage,
        path:
            '$storageRoot/driving_license_back.jpg',
      );

      // =====================================================
      // UPLOAD VEHICLE REGISTRATION
      // =====================================================

      final String vehicleRegistrationUrl =
          await _uploadImage(
        file: vehicleRegistrationImage,
        path:
            '$storageRoot/vehicle_registration.jpg',
      );

      // =====================================================
      // UPLOAD VEHICLE PHOTO
      // =====================================================

      final String vehiclePhotoUrl =
          await _uploadImage(
        file: vehiclePhotoImage,
        path:
            '$storageRoot/vehicle_photo.jpg',
      );

      // =====================================================
      // UPLOAD DRIVER PHOTO
      // =====================================================

      final String driverPhotoUrl =
          await _uploadImage(
        file: driverPhotoImage,
        path:
            '$storageRoot/driver_photo.jpg',
      );

      // =====================================================
      // SAVE APPLICATION TO FIRESTORE
      // =====================================================

      await applicationReference.set({
        // ===================================================
        // BASIC APPLICATION INFORMATION
        // ===================================================

        'applicationId':
            applicationId,

        'applicationType':
            'driver_registration',

        'status':
            'pending',

        // ===================================================
        // DRIVER INFORMATION
        // ===================================================

        'fullName':
            fullName.trim(),

        'phoneNumber':
            phoneNumber.trim(),

        'cnicNumber':
            cnicNumber.trim(),

        'cnicNumberNormalized':
            normalizeVehicleIdentity(cnicNumber),

        'address':
            address.trim(),

        // ===================================================
        // VEHICLE INFORMATION
        // ===================================================

        'vehicleType':
            vehicleType,

        'vehicleNumber':
            vehicleNumber.trim(),

        'vehicleNumberNormalized':
            normalizeVehicleIdentity(vehicleNumber),

        'chassisNumber':
            chassisNumber.trim(),

        'chassisNumberNormalized':
            normalizeVehicleIdentity(chassisNumber),

        'vehicleOwnerId':
            vehicleOwnerId.trim(),

        'authorizedDriverId':
            authorizedDriverId.trim(),

        // ===================================================
        // DOCUMENTS
        // ===================================================

        'documents': {
          'cnicFront':
              cnicFrontUrl,

          'cnicBack':
              cnicBackUrl,

          'drivingLicenseFront':
              drivingLicenseFrontUrl,

          'drivingLicenseBack':
              drivingLicenseBackUrl,

          'vehicleRegistration':
              vehicleRegistrationUrl,

          'vehiclePhoto':
              vehiclePhotoUrl,

          'driverPhoto':
              driverPhotoUrl,
        },

        // ===================================================
        // ADMIN REVIEW
        // ===================================================

        'adminReview': {
          'reviewed':
              false,

          'reviewedBy':
              null,

          'reviewedAt':
              null,

          'rejectionReason':
              null,
        },

                'reviewTimeline': {
                    'vehicleStatus': 'pending',
                    'documentsStatus': 'pending',
                    'primaryImageStatus': 'pending',
                    'submittedAt': FieldValue.serverTimestamp(),
                    'estimatedReviewWindowHours': 48,
                },

                'photoReview': {
                    'primaryImageKey': 'driverPhoto',
                    'primaryImageStatus': 'pending',
                    'reviewedBy': null,
                    'reviewedAt': null,
                },

        // ===================================================
        // FUTURE DRIVER ACCOUNT
        // ===================================================

        'driverAccount': {
          'created':
              false,

          'driverId':
              null,

          'approvedAt':
              null,
        },

        // ===================================================
        // TIMESTAMPS
        // ===================================================

        'createdAt':
            FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      // =====================================================
      // RETURN APPLICATION ID
      // =====================================================

      return applicationId;
    } catch (e) {
      throw Exception(
        'Failed to submit driver application: $e',
      );
    }
  }

  // =========================================================
  // UPLOAD IMAGE TO FIREBASE STORAGE
  // =========================================================

  Future<String> _uploadImage({
    required File file,
    required String path,
  }) async {
    final Reference storageReference =
        _storage.ref().child(path);

    final UploadTask uploadTask =
        storageReference.putFile(file);

    final TaskSnapshot snapshot =
        await uploadTask;

    final String downloadUrl =
        await snapshot.ref.getDownloadURL();

    return downloadUrl;
  }
}