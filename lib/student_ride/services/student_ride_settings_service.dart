import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/student_ride_settings_model.dart';

class StudentRideSettingsService {
  StudentRideSettingsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String collectionName = 'student_ride_config';
  static const String settingsDocumentId = 'global_settings';

  DocumentReference<Map<String, dynamic>> get _settingsReference {
    return _firestore
        .collection(collectionName)
        .doc(settingsDocumentId);
  }

  Future<StudentRideSettingsModel> getSettings() async {
    try {
      final snapshot = await _settingsReference.get();
      final data = snapshot.data();

      if (!snapshot.exists || data == null) {
        return StudentRideSettingsModel.defaults();
      }

      return StudentRideSettingsModel.fromMap(data);
    } catch (_) {
      // Safe fallback keeps Student Ride stable if Firestore is unavailable.
      return StudentRideSettingsModel.defaults();
    }
  }

  Stream<StudentRideSettingsModel> watchSettings() {
    return _settingsReference.snapshots().map((snapshot) {
      final data = snapshot.data();

      if (!snapshot.exists || data == null) {
        return StudentRideSettingsModel.defaults();
      }

      return StudentRideSettingsModel.fromMap(data);
    }).handleError((_) {
      // Stream listeners receive safe defaults instead of an app crash.
    });
  }

  Future<void> saveSettings({
    required StudentRideSettingsModel settings,
    required String adminId,
  }) async {
    final data = settings.toMap();

    data['updatedBy'] = adminId;
    data['updatedAt'] = FieldValue.serverTimestamp();

    await _settingsReference.set(
      data,
      SetOptions(merge: true),
    );
  }

  Future<void> updateFields({
    required Map<String, dynamic> fields,
    required String adminId,
  }) async {
    if (fields.isEmpty) return;

    final safeFields = Map<String, dynamic>.from(fields)
      ..remove('updatedAt')
      ..remove('updatedBy')
      ..['updatedBy'] = adminId
      ..['updatedAt'] = FieldValue.serverTimestamp();

    await _settingsReference.set(
      safeFields,
      SetOptions(merge: true),
    );
  }

  Future<void> setModuleEnabled({
    required bool enabled,
    required String adminId,
  }) {
    return updateFields(
      fields: {'moduleEnabled': enabled},
      adminId: adminId,
    );
  }

  Future<void> updatePaymentMethods({
    required bool cashEnabled,
    required bool walletEnabled,
    required bool easypaisaEnabled,
    required bool jazzCashEnabled,
    required bool cardPaymentEnabled,
    required String adminId,
  }) {
    return updateFields(
      fields: {
        'cashEnabled': cashEnabled,
        'walletEnabled': walletEnabled,
        'easypaisaEnabled': easypaisaEnabled,
        'jazzCashEnabled': jazzCashEnabled,
        'cardPaymentEnabled': cardPaymentEnabled,
      },
      adminId: adminId,
    );
  }

  Future<void> updateCommission({
    required StudentRideCommissionType commissionType,
    required double commissionValue,
    required String adminId,
  }) {
    if (commissionValue < 0) {
      throw ArgumentError.value(
        commissionValue,
        'commissionValue',
        'Commission cannot be negative.',
      );
    }

    if (commissionType == StudentRideCommissionType.percentage &&
        commissionValue > 100) {
      throw ArgumentError.value(
        commissionValue,
        'commissionValue',
        'Percentage commission cannot exceed 100.',
      );
    }

    return updateFields(
      fields: {
        'commissionType': commissionType.name,
        'commissionValue': commissionValue,
      },
      adminId: adminId,
    );
  }

  Future<void> updatePricing({
    required StudentRideBillingMode billingMode,
    required double monthlyBasePrice,
    required double dailyBasePrice,
    required double routeBasePrice,
    required double perKmPrice,
    required double doorToDoorCharge,
    required double registrationFee,
    required double siblingDiscountPercent,
    required String adminId,
  }) {
    final numericValues = <double>[
      monthlyBasePrice,
      dailyBasePrice,
      routeBasePrice,
      perKmPrice,
      doorToDoorCharge,
      registrationFee,
      siblingDiscountPercent,
    ];

    if (numericValues.any((value) => value < 0)) {
      throw ArgumentError(
        'Student Ride prices and discounts cannot be negative.',
      );
    }

    if (siblingDiscountPercent > 100) {
      throw ArgumentError(
        'Sibling discount cannot exceed 100 percent.',
      );
    }

    return updateFields(
      fields: {
        'defaultBillingMode': billingMode.name,
        'monthlyBasePrice': monthlyBasePrice,
        'dailyBasePrice': dailyBasePrice,
        'routeBasePrice': routeBasePrice,
        'perKmPrice': perKmPrice,
        'doorToDoorCharge': doorToDoorCharge,
        'registrationFee': registrationFee,
        'siblingDiscountPercent': siblingDiscountPercent,
      },
      adminId: adminId,
    );
  }

  Future<void> updateOperationalRules({
    required int paymentDueDay,
    required int paymentGraceDays,
    required int renewalReminderDays,
    required int absenceCutoffMinutes,
    required int routeChangeCutoffHours,
    required int maximumStudentsPerVehicle,
    required String adminId,
  }) {
    if (paymentDueDay < 1 || paymentDueDay > 28) {
      throw ArgumentError(
        'Payment due day must be between 1 and 28.',
      );
    }

    if (paymentGraceDays < 0 ||
        renewalReminderDays < 0 ||
        absenceCutoffMinutes < 0 ||
        routeChangeCutoffHours < 0 ||
        maximumStudentsPerVehicle < 1) {
      throw ArgumentError(
        'Student Ride operational values are invalid.',
      );
    }

    return updateFields(
      fields: {
        'paymentDueDay': paymentDueDay,
        'paymentGraceDays': paymentGraceDays,
        'renewalReminderDays': renewalReminderDays,
        'absenceCutoffMinutes': absenceCutoffMinutes,
        'routeChangeCutoffHours': routeChangeCutoffHours,
        'maximumStudentsPerVehicle': maximumStudentsPerVehicle,
      },
      adminId: adminId,
    );
  }

  Future<void> createDefaultsIfMissing({
    required String adminId,
  }) async {
    final snapshot = await _settingsReference.get();

    if (snapshot.exists) return;

    final data = StudentRideSettingsModel.defaults().toMap()
      ..['updatedBy'] = adminId
      ..['updatedAt'] = FieldValue.serverTimestamp();

    await _settingsReference.set(data);
  }
}
