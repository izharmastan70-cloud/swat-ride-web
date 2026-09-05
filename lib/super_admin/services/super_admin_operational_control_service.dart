import 'package:cloud_firestore/cloud_firestore.dart';

class SuperAdminOperationalControls {
  const SuperAdminOperationalControls({
    required this.phoneCallBookingEnabled,
    required this.localMessagingRelayEnabled,
    required this.billingAutoDiscoveryEnabled,
    required this.billingWhatsAppAlertsEnabled,
  });

  final bool phoneCallBookingEnabled;
  final bool localMessagingRelayEnabled;
  final bool billingAutoDiscoveryEnabled;
  final bool billingWhatsAppAlertsEnabled;

  factory SuperAdminOperationalControls.fromMap(Map<String, dynamic>? data) {
    return SuperAdminOperationalControls(
      phoneCallBookingEnabled: data?['phoneCallBookingEnabled'] != false,
      localMessagingRelayEnabled: data?['localMessagingRelayEnabled'] != false,
        billingAutoDiscoveryEnabled: data?['billingAutoDiscoveryEnabled'] != false,
        billingWhatsAppAlertsEnabled:
          data?['billingWhatsAppAlertsEnabled'] != false,
    );
  }
}

class SuperAdminOperationalControlService {
  SuperAdminOperationalControlService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String documentId = 'super_admin_operational_controls';

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get _document =>
      _firestore.collection('app_config').doc(documentId);

  Stream<SuperAdminOperationalControls> watch() => _document.snapshots().map(
        (DocumentSnapshot<Map<String, dynamic>> snapshot) =>
            SuperAdminOperationalControls.fromMap(snapshot.data()),
      );

  Future<SuperAdminOperationalControls> get() async =>
      SuperAdminOperationalControls.fromMap((await _document.get()).data());

  Future<void> setPhoneCallBookingEnabled(bool enabled) => _document.set(
        <String, dynamic>{
          'phoneCallBookingEnabled': enabled,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

  Future<void> setLocalMessagingRelayEnabled(bool enabled) => _document.set(
        <String, dynamic>{
          'localMessagingRelayEnabled': enabled,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

  Future<void> setBillingAutoDiscoveryEnabled(bool enabled) => _document.set(
        <String, dynamic>{
          'billingAutoDiscoveryEnabled': enabled,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

  Future<void> setBillingWhatsAppAlertsEnabled(bool enabled) => _document.set(
        <String, dynamic>{
          'billingWhatsAppAlertsEnabled': enabled,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
}