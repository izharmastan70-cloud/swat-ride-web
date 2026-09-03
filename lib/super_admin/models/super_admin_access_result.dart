// =========================================================
// SWAT RIDE — SUPER ADMIN ACCESS RESULT
// =========================================================
//
// Ye model sirf Super Admin access verification ka result hold karega.
//
// IMPORTANT:
// - Normal `admin` ko Super Admin access nahi milega.
// - Sirf `super_admin` role allowed hoga.
// - Testing bypass ko production se pehle disable karna hoga.
// - Firebase verification actual service file mein hogi.

class SuperAdminAccessSource {
  SuperAdminAccessSource._();

  static const String customClaim = 'CUSTOM_CLAIM';
  static const String firestoreAdminRecord = 'FIRESTORE_ADMIN_RECORD';
  static const String testingBypass = 'TESTING_BYPASS';
  static const String none = 'NONE';
}

class SuperAdminAccessStatus {
  SuperAdminAccessStatus._();

  static const String allowed = 'ALLOWED';
  static const String denied = 'DENIED';
  static const String error = 'ERROR';
}

class SuperAdminAccessResult {
  final String status;
  final String adminId;
  final String adminName;
  final String role;
  final String reason;
  final String source;
  final bool isTestingBypass;

  const SuperAdminAccessResult._({
    required this.status,
    required this.adminId,
    required this.adminName,
    required this.role,
    required this.reason,
    required this.source,
    required this.isTestingBypass,
  });

  const SuperAdminAccessResult.allowed({
    required String adminId,
    required String adminName,
    required String source,
    bool isTestingBypass = false,
  }) : this._(
          status: SuperAdminAccessStatus.allowed,
          adminId: adminId,
          adminName: adminName,
          role: 'super_admin',
          reason: '',
          source: source,
          isTestingBypass: isTestingBypass,
        );

  const SuperAdminAccessResult.denied({
    required String reason,
  }) : this._(
          status: SuperAdminAccessStatus.denied,
          adminId: '',
          adminName: '',
          role: '',
          reason: reason,
          source: SuperAdminAccessSource.none,
          isTestingBypass: false,
        );

  const SuperAdminAccessResult.error({
    required String reason,
  }) : this._(
          status: SuperAdminAccessStatus.error,
          adminId: '',
          adminName: '',
          role: '',
          reason: reason,
          source: SuperAdminAccessSource.none,
          isTestingBypass: false,
        );

  bool get isAllowed =>
      status == SuperAdminAccessStatus.allowed;

  bool get isDenied =>
      status == SuperAdminAccessStatus.denied;

  bool get hasError =>
      status == SuperAdminAccessStatus.error;

  bool get isSuperAdmin =>
      isAllowed && role == 'super_admin';

  String get sourceLabel {
    switch (source) {
      case SuperAdminAccessSource.customClaim:
        return 'Firebase Super Admin claim';

      case SuperAdminAccessSource.firestoreAdminRecord:
        return 'Firestore Super Admin record';

      case SuperAdminAccessSource.testingBypass:
        return 'Testing Super Admin bypass';

      default:
        return 'No Super Admin access';
    }
  }
}