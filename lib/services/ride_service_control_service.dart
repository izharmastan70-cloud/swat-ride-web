import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ride_service_control_model.dart';

class RideServiceControlService {
  RideServiceControlService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String collectionName = 'app_config';
  static const String documentId = 'normal_ride_service';

  DocumentReference<Map<String, dynamic>> get _settingsReference =>
      _firestore.collection(collectionName).doc(documentId);

  Stream<RideServiceControlModel> watchSettings() {
    return _settingsReference.snapshots().map((
      DocumentSnapshot<Map<String, dynamic>> snapshot,
    ) {
      return RideServiceControlModel.fromMap(snapshot.data());
    });
  }

  Future<RideServiceControlModel> getSettings() async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _settingsReference.get();

    return RideServiceControlModel.fromMap(snapshot.data());
  }

  Future<bool> canCreateNewRide() async {
    final RideServiceControlModel settings = await getSettings();

    return settings.effectiveServiceEnabled;
  }

  Future<void> ensureNewRideAvailable() async {
    final RideServiceControlModel settings = await getSettings();

    if (!settings.effectiveServiceEnabled) {
      throw RideServiceUnavailableException(
        settings.effectiveReason,
        maintenanceMode: settings.isMaintenanceActive,
      );
    }
  }

  Future<void> updateByRideAdmin({
    required bool serviceEnabled,
    required bool maintenanceMode,
    required String reason,
    required String updatedBy,
  }) async {
    final String adminId = updatedBy.trim();

    if (adminId.isEmpty) {
      throw ArgumentError('Admin ID is required.');
    }

    final String normalizedReason = reason.trim();

    if ((!serviceEnabled || maintenanceMode) && normalizedReason.isEmpty) {
      throw ArgumentError(
        'Please enter a reason before disabling Normal Ride or enabling maintenance mode.',
      );
    }

    await _settingsReference.set(<String, dynamic>{
      'serviceEnabled': serviceEnabled,
      'maintenanceMode': maintenanceMode,
      'reason': normalizedReason,
      'updatedBy': adminId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Super Admin-only architecture hook.
  ///
  /// UI/authorization for this method should live behind
  /// Super Admin access controls. Ride Admin must not call it.
  Future<void> setSuperAdminOverride({
    required bool? enabled,
    required String reason,
    required String updatedBy,
  }) async {
    final String adminId = updatedBy.trim();

    if (adminId.isEmpty) {
      throw ArgumentError('Super Admin ID is required.');
    }

    final String normalizedReason = reason.trim();

    if (enabled != null && normalizedReason.isEmpty) {
      throw ArgumentError('A reason is required for a Super Admin override.');
    }

    await _settingsReference.set(<String, dynamic>{
      'superAdminOverride': enabled,
      'superAdminOverrideReason': enabled == null ? '' : normalizedReason,
      'superAdminOverrideBy': enabled == null ? '' : adminId,
      'superAdminOverrideAt': enabled == null
          ? null
          : FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

class RideServiceUnavailableException implements Exception {
  const RideServiceUnavailableException(
    this.message, {
    this.maintenanceMode = false,
  });

  final String message;
  final bool maintenanceMode;

  @override
  String toString() => message;
}
