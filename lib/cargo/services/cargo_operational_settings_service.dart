import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cargo_operational_settings_model.dart';

class CargoOperationalSettingsService {
  CargoOperationalSettingsService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String collectionName = 'cargo_settings';

  static const String documentId = 'operational';

  DocumentReference<Map<String, dynamic>> get _settings =>
      _firestore.collection(collectionName).doc(documentId);

  Future<CargoOperationalSettingsModel> getSettings() async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot = await _settings
        .get();

    final Map<String, dynamic>? data = snapshot.data();

    if (!snapshot.exists || data == null) {
      final CargoOperationalSettingsModel defaults =
          CargoOperationalSettingsModel.defaults();

      await _settings.set(defaults.toMap());

      return defaults;
    }

    return CargoOperationalSettingsModel.fromMap(data);
  }

  Stream<CargoOperationalSettingsModel> watchSettings() {
    return _settings.snapshots().map((snapshot) {
      final Map<String, dynamic>? data = snapshot.data();

      if (!snapshot.exists || data == null) {
        return CargoOperationalSettingsModel.defaults();
      }

      return CargoOperationalSettingsModel.fromMap(data);
    });
  }

  Future<void> saveSettings(CargoOperationalSettingsModel settings) async {
    await _settings.set(settings.toMap(), SetOptions(merge: true));
  }

  Future<void> updateCargoEnabled(bool enabled, {String? updatedBy}) {
    return _updateField('cargoEnabled', enabled, updatedBy: updatedBy);
  }

  Future<void> updateAcceptingNewBookings(bool enabled, {String? updatedBy}) {
    return _updateField('acceptingNewBookings', enabled, updatedBy: updatedBy);
  }

  Future<void> updateDriverApplicationsEnabled(
    bool enabled, {
    String? updatedBy,
  }) {
    return _updateField(
      'driverApplicationsEnabled',
      enabled,
      updatedBy: updatedBy,
    );
  }

  Future<void> updateOffPlatformReportingEnabled(
    bool enabled, {
    String? updatedBy,
  }) {
    return _updateField(
      'offPlatformReportingEnabled',
      enabled,
      updatedBy: updatedBy,
    );
  }

  Future<void> _updateField(
    String field,
    bool value, {
    String? updatedBy,
  }) async {
    await _settings.set(<String, dynamic>{
      field: value,
      'updatedAt': Timestamp.now(),
      'updatedBy': _nullableText(updatedBy),
    }, SetOptions(merge: true));
  }

  static String? _nullableText(String? value) {
    final String result = value?.trim() ?? '';

    return result.isEmpty ? null : result;
  }
}
