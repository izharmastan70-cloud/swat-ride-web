import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/hotel_service_control_model.dart';

class HotelServiceControlService {
  HotelServiceControlService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String collectionName = 'hotel_service_control';
  static const String globalDocumentId = 'global';

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get _controlDocument {
    return _firestore
        .collection(collectionName)
        .doc(globalDocumentId);
  }

  Stream<HotelServiceControlModel> watchControl() {
    return _controlDocument.snapshots().map(
      (DocumentSnapshot<Map<String, dynamic>> snapshot) {
        final Map<String, dynamic>? data = snapshot.data();

        if (!snapshot.exists || data == null) {
          return HotelServiceControlModel.defaults();
        }

        return HotelServiceControlModel.fromMap(data);
      },
    );
  }

  Future<HotelServiceControlModel> getControl() async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _controlDocument.get();

    final Map<String, dynamic>? data = snapshot.data();

    if (!snapshot.exists || data == null) {
      return HotelServiceControlModel.defaults();
    }

    return HotelServiceControlModel.fromMap(data);
  }

  Future<void> ensureDefaults({
    required String updatedBy,
  }) async {
    final String normalizedAdminId = updatedBy.trim();

    if (normalizedAdminId.isEmpty) {
      throw ArgumentError('updatedBy is required.');
    }

    await _firestore.runTransaction(
      (Transaction transaction) async {
        final DocumentSnapshot<Map<String, dynamic>> snapshot =
            await transaction.get(_controlDocument);

        if (snapshot.exists) {
          return;
        }

        transaction.set(
          _controlDocument,
          <String, dynamic>{
            'serviceEnabled': true,
            'acceptNewBookings': true,
            'acceptPartnerApplications': true,
            'maintenanceMode': false,
            'maintenanceMessage': '',
            'superAdminOverride':
                HotelServiceOverride.none.name,
            'updatedBy': normalizedAdminId,
            'updatedAt': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          },
        );
      },
    );
  }

  Future<void> updateOperationalControl({
    required bool serviceEnabled,
    required bool acceptNewBookings,
    required bool acceptPartnerApplications,
    required bool maintenanceMode,
    required String maintenanceMessage,
    required String updatedBy,
  }) async {
    final String normalizedAdminId = updatedBy.trim();
    final String normalizedMessage = maintenanceMessage.trim();

    if (normalizedAdminId.isEmpty) {
      throw ArgumentError('updatedBy is required.');
    }

    if ((!serviceEnabled || maintenanceMode) &&
        normalizedMessage.isEmpty) {
      throw ArgumentError(
        'Maintenance/unavailable message is required.',
      );
    }

    await _controlDocument.set(
      <String, dynamic>{
        'serviceEnabled': serviceEnabled,
        'acceptNewBookings': acceptNewBookings,
        'acceptPartnerApplications':
            acceptPartnerApplications,
        'maintenanceMode': maintenanceMode,
        'maintenanceMessage': normalizedMessage,
        'updatedBy': normalizedAdminId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> updateSuperAdminOverride({
    required HotelServiceOverride override,
    required String superAdminId,
    required String reason,
  }) async {
    final String normalizedAdminId = superAdminId.trim();
    final String normalizedReason = reason.trim();

    if (normalizedAdminId.isEmpty) {
      throw ArgumentError('superAdminId is required.');
    }

    if (override != HotelServiceOverride.none &&
        normalizedReason.isEmpty) {
      throw ArgumentError(
        'Super Admin override reason is required.',
      );
    }

    await _controlDocument.set(
      <String, dynamic>{
        'superAdminOverride': override.name,
        'superAdminOverrideReason': normalizedReason,
        'superAdminOverrideBy': normalizedAdminId,
        'superAdminOverrideAt':
            FieldValue.serverTimestamp(),
        'updatedBy': normalizedAdminId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<HotelServiceDecision> canCreateBooking() async {
    final HotelServiceControlModel control =
        await getControl();

    if (control.canAcceptNewBookings) {
      return const HotelServiceDecision.allowed();
    }

    return HotelServiceDecision.blocked(
      message: control.customerUnavailableMessage,
    );
  }

  Future<HotelServiceDecision>
      canSubmitPartnerApplication() async {
    final HotelServiceControlModel control =
        await getControl();

    if (control.canAcceptPartnerApplications) {
      return const HotelServiceDecision.allowed();
    }

    return HotelServiceDecision.blocked(
      message: control.customerUnavailableMessage,
    );
  }
}

class HotelServiceDecision {
  const HotelServiceDecision._({
    required this.isAllowed,
    required this.message,
  });

  const HotelServiceDecision.allowed()
      : this._(
          isAllowed: true,
          message: '',
        );

  const HotelServiceDecision.blocked({
    required String message,
  }) : this._(
          isAllowed: false,
          message: message,
        );

  final bool isAllowed;
  final String message;
}
