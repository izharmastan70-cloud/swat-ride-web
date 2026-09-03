import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cargo_driver_application_model.dart';
import 'cargo_operational_settings_service.dart';

class CargoDriverApplicationService {
  CargoDriverApplicationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String collectionName = 'cargo_driver_applications';

  CollectionReference<Map<String, dynamic>> get _applications =>
      _firestore.collection(collectionName);

  Future<String> submitApplication({
    required String userId,
    required String fullName,
    required String phone,
    required String cnicNumber,
    required String vehicleType,
    required String vehicleNumber,
    required String address,
    String? cnicFrontUrl,
    String? cnicBackUrl,
    String? licenseFrontUrl,
    String? licenseBackUrl,
    String? vehicleRegistrationUrl,
    String? vehiclePhotoUrl,
    String? driverPhotoUrl,
  }) async {
    final settings = await CargoOperationalSettingsService().getSettings();

    if (!settings.cargoEnabled) {
      throw StateError('Cargo service is currently disabled by Admin.');
    }

    if (!settings.driverApplicationsEnabled) {
      throw StateError(
        'Cargo Driver applications are currently disabled by Admin.',
      );
    }

    final String cleanUserId = userId.trim();
    final String cleanVehicleType = vehicleType.trim();

    if (cleanUserId.isEmpty) {
      throw ArgumentError('userId cannot be empty.');
    }

    if (fullName.trim().isEmpty) {
      throw ArgumentError('fullName cannot be empty.');
    }

    if (phone.trim().isEmpty) {
      throw ArgumentError('phone cannot be empty.');
    }

    if (cnicNumber.trim().isEmpty) {
      throw ArgumentError('cnicNumber cannot be empty.');
    }

    if (!CargoDriverApplicationModel.supportedVehicleTypes.contains(
      cleanVehicleType,
    )) {
      throw ArgumentError('Unsupported Cargo vehicle type: $cleanVehicleType');
    }

    if (vehicleNumber.trim().isEmpty) {
      throw ArgumentError('vehicleNumber cannot be empty.');
    }

    final QuerySnapshot<Map<String, dynamic>> existing = await _applications
        .where('userId', isEqualTo: cleanUserId)
        .get();

    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in existing.docs) {
      final CargoDriverApplicationModel application =
          CargoDriverApplicationModel.fromMap(<String, dynamic>{
            ...doc.data(),
            'applicationId': doc.id,
          });

      if (application.status == CargoDriverApplicationModel.pending ||
          application.status == CargoDriverApplicationModel.approved) {
        throw StateError('An active Cargo Driver application already exists.');
      }
    }

    final DocumentReference<Map<String, dynamic>> reference = _applications
        .doc();

    final CargoDriverApplicationModel application = CargoDriverApplicationModel(
      applicationId: reference.id,
      userId: cleanUserId,
      fullName: fullName.trim(),
      phone: phone.trim(),
      cnicNumber: cnicNumber.trim(),
      vehicleType: cleanVehicleType,
      vehicleNumber: vehicleNumber.trim(),
      address: address.trim(),
      status: CargoDriverApplicationModel.pending,
      cnicFrontUrl: _nullableText(cnicFrontUrl),
      cnicBackUrl: _nullableText(cnicBackUrl),
      licenseFrontUrl: _nullableText(licenseFrontUrl),
      licenseBackUrl: _nullableText(licenseBackUrl),
      vehicleRegistrationUrl: _nullableText(vehicleRegistrationUrl),
      vehiclePhotoUrl: _nullableText(vehiclePhotoUrl),
      driverPhotoUrl: _nullableText(driverPhotoUrl),
      createdAt: DateTime.now(),
    );

    await reference.set(application.toMap());

    return reference.id;
  }

  Future<CargoDriverApplicationModel?> getApplication(
    String applicationId,
  ) async {
    final String id = applicationId.trim();

    if (id.isEmpty) {
      return null;
    }

    final DocumentSnapshot<Map<String, dynamic>> snapshot = await _applications
        .doc(id)
        .get();

    final Map<String, dynamic>? data = snapshot.data();

    if (!snapshot.exists || data == null) {
      return null;
    }

    return CargoDriverApplicationModel.fromMap(<String, dynamic>{
      ...data,
      'applicationId': snapshot.id,
    });
  }

  Stream<CargoDriverApplicationModel?> watchApplication(String applicationId) {
    final String id = applicationId.trim();

    if (id.isEmpty) {
      return Stream<CargoDriverApplicationModel?>.value(null);
    }

    return _applications.doc(id).snapshots().map((snapshot) {
      final Map<String, dynamic>? data = snapshot.data();

      if (!snapshot.exists || data == null) {
        return null;
      }

      return CargoDriverApplicationModel.fromMap(<String, dynamic>{
        ...data,
        'applicationId': snapshot.id,
      });
    });
  }

  Stream<List<CargoDriverApplicationModel>> watchUserApplications(
    String userId,
  ) {
    final String id = userId.trim();

    if (id.isEmpty) {
      return Stream<List<CargoDriverApplicationModel>>.value(
        <CargoDriverApplicationModel>[],
      );
    }

    return _applications.where('userId', isEqualTo: id).snapshots().map((
      snapshot,
    ) {
      final List<CargoDriverApplicationModel> applications = snapshot.docs.map((
        doc,
      ) {
        return CargoDriverApplicationModel.fromMap(<String, dynamic>{
          ...doc.data(),
          'applicationId': doc.id,
        });
      }).toList();

      applications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return applications;
    });
  }

  Stream<List<CargoDriverApplicationModel>> watchPendingApplications() {
    return _applications
        .where('status', isEqualTo: CargoDriverApplicationModel.pending)
        .snapshots()
        .map((snapshot) {
          final List<CargoDriverApplicationModel> applications = snapshot.docs
              .map((doc) {
                return CargoDriverApplicationModel.fromMap(<String, dynamic>{
                  ...doc.data(),
                  'applicationId': doc.id,
                });
              })
              .toList();

          applications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return applications;
        });
  }

  Future<void> approveApplication({
    required String applicationId,
    String? reviewedBy,
    String? adminNote,
  }) async {
    final String id = applicationId.trim();

    if (id.isEmpty) {
      throw ArgumentError('applicationId cannot be empty.');
    }

    await _applications.doc(id).update({
      'status': CargoDriverApplicationModel.approved,
      'reviewedBy': _nullableText(reviewedBy),
      'reviewedAt': Timestamp.now(),
      'adminNote': _nullableText(adminNote),
    });
  }

  Future<void> rejectApplication({
    required String applicationId,
    String? reviewedBy,
    String? adminNote,
  }) async {
    final String id = applicationId.trim();

    if (id.isEmpty) {
      throw ArgumentError('applicationId cannot be empty.');
    }

    await _applications.doc(id).update({
      'status': CargoDriverApplicationModel.rejected,
      'reviewedBy': _nullableText(reviewedBy),
      'reviewedAt': Timestamp.now(),
      'adminNote': _nullableText(adminNote),
    });
  }

  Future<void> suspendApplication({
    required String applicationId,
    String? reviewedBy,
    String? adminNote,
  }) async {
    final String id = applicationId.trim();

    if (id.isEmpty) {
      throw ArgumentError('applicationId cannot be empty.');
    }

    await _applications.doc(id).update({
      'status': CargoDriverApplicationModel.suspended,
      'reviewedBy': _nullableText(reviewedBy),
      'reviewedAt': Timestamp.now(),
      'adminNote': _nullableText(adminNote),
    });
  }

  Future<void> restoreApplication({
    required String applicationId,
    String? reviewedBy,
    String? adminNote,
  }) async {
    final String id = applicationId.trim();

    if (id.isEmpty) {
      throw ArgumentError('applicationId cannot be empty.');
    }

    await _applications.doc(id).update({
      'status': CargoDriverApplicationModel.approved,
      'reviewedBy': _nullableText(reviewedBy),
      'reviewedAt': Timestamp.now(),
      'adminNote': _nullableText(adminNote),
    });
  }

  Stream<List<CargoDriverApplicationModel>> watchAllApplications() {
    return _applications.snapshots().map((snapshot) {
      final List<CargoDriverApplicationModel> applications = snapshot.docs.map((
        doc,
      ) {
        return CargoDriverApplicationModel.fromMap(<String, dynamic>{
          ...doc.data(),
          'applicationId': doc.id,
        });
      }).toList();

      applications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return applications;
    });
  }

  Future<void> suspendDriverByUserId({
    required String userId,
    String? reviewedBy,
    String? adminNote,
  }) async {
    final String id = userId.trim();

    if (id.isEmpty) {
      throw ArgumentError('userId cannot be empty.');
    }

    final QuerySnapshot<Map<String, dynamic>> snapshot = await _applications
        .where('userId', isEqualTo: id)
        .get();

    DocumentReference<Map<String, dynamic>>? applicationReference;

    for (final doc in snapshot.docs) {
      final CargoDriverApplicationModel application =
          CargoDriverApplicationModel.fromMap(<String, dynamic>{
            ...doc.data(),
            'applicationId': doc.id,
          });

      if (application.status == CargoDriverApplicationModel.approved ||
          application.status == CargoDriverApplicationModel.pending) {
        applicationReference = doc.reference;
        break;
      }
    }

    // Backward compatibility:
    // older records may contain applicationId as driverId.
    if (applicationReference == null) {
      final DocumentReference<Map<String, dynamic>> directReference =
          _applications.doc(id);

      final DocumentSnapshot<Map<String, dynamic>> directSnapshot =
          await directReference.get();

      if (directSnapshot.exists && directSnapshot.data() != null) {
        applicationReference = directReference;
      }
    }

    if (applicationReference == null) {
      throw StateError('Cargo Driver application not found for this user.');
    }

    await applicationReference.update({
      'status': CargoDriverApplicationModel.suspended,
      'reviewedBy': _nullableText(reviewedBy),
      'reviewedAt': Timestamp.now(),
      'adminNote': _nullableText(adminNote),
      'suspendedAt': Timestamp.now(),
      'suspensionSource': 'off_platform_report',
    });
  }

  Future<void> updateCommissionPercentage({
    required String applicationId,
    required double commissionPercentage,
  }) async {
    final String id = applicationId.trim();

    if (id.isEmpty) {
      throw ArgumentError('applicationId cannot be empty.');
    }

    final double safePercentage = commissionPercentage.clamp(0, 100).toDouble();

    await _applications.doc(id).update({
      'commissionPercentage': safePercentage,
      'commissionUpdatedAt': Timestamp.now(),
    });
  }

  Future<void> addOutstandingCommission({
    required String applicationId,
    required double commissionAmount,
  }) async {
    final String id = applicationId.trim();

    if (id.isEmpty) {
      throw ArgumentError('applicationId cannot be empty.');
    }

    if (!commissionAmount.isFinite || commissionAmount <= 0) {
      return;
    }

    await _firestore.runTransaction((transaction) async {
      final DocumentReference<Map<String, dynamic>> reference = _applications
          .doc(id);

      final DocumentSnapshot<Map<String, dynamic>> snapshot = await transaction
          .get(reference);

      if (!snapshot.exists) {
        throw StateError('Cargo Driver application not found.');
      }

      final Map<String, dynamic> data = snapshot.data() ?? <String, dynamic>{};

      final double currentOutstanding = _safeNumber(
        data['outstandingCommission'],
      );

      transaction.update(reference, {
        'outstandingCommission': currentOutstanding + commissionAmount,
        'commissionUpdatedAt': Timestamp.now(),
      });
    });
  }

  Future<void> settleOutstandingCommission({
    required String applicationId,
    required double amount,
  }) async {
    final String id = applicationId.trim();

    if (id.isEmpty) {
      throw ArgumentError('applicationId cannot be empty.');
    }

    if (!amount.isFinite || amount <= 0) {
      throw ArgumentError('Settlement amount must be greater than zero.');
    }

    await _firestore.runTransaction((transaction) async {
      final DocumentReference<Map<String, dynamic>> reference = _applications
          .doc(id);

      final DocumentSnapshot<Map<String, dynamic>> snapshot = await transaction
          .get(reference);

      if (!snapshot.exists) {
        throw StateError('Cargo Driver application not found.');
      }

      final Map<String, dynamic> data = snapshot.data() ?? <String, dynamic>{};

      final double currentOutstanding = _safeNumber(
        data['outstandingCommission'],
      );

      final double currentPaid = _safeNumber(data['totalCommissionPaid']);

      final double settlementAmount = amount > currentOutstanding
          ? currentOutstanding
          : amount;

      if (settlementAmount <= 0) {
        throw StateError('This Cargo Driver has no outstanding commission.');
      }

      transaction.update(reference, {
        'outstandingCommission': currentOutstanding - settlementAmount,
        'totalCommissionPaid': currentPaid + settlementAmount,
        'lastCommissionSettlement': settlementAmount,
        'lastCommissionSettlementAt': Timestamp.now(),
      });
    });
  }

  static double _safeNumber(dynamic value) {
    if (value is num) {
      final double result = value.toDouble();

      if (result.isFinite && result >= 0) {
        return result;
      }
    }

    if (value is String) {
      final double? result = double.tryParse(value);

      if (result != null && result.isFinite && result >= 0) {
        return result;
      }
    }

    return 0;
  }

  static String? _nullableText(String? value) {
    final String result = value?.trim() ?? '';
    return result.isEmpty ? null : result;
  }
}
