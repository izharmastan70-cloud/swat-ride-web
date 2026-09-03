import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/super_admin_access_result.dart';

// =========================================================
// SWAT RIDE — SUPER ADMIN ACCESS SERVICE
// =========================================================
//
// Separate from Ride Admin access.
//
// Production access:
// 1. Firebase custom claim: role == super_admin
// OR
// 2. Firestore admins/{uid}: isActive == true && role == super_admin
//
// Normal admin is NOT enough.
//
// IMPORTANT:
// Testing bypass is development-only and must be disabled before release.

class SuperAdminAccessService {
  SuperAdminAccessService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // =========================================================
  // DEVELOPMENT TESTING BYPASS
  // =========================================================

  static const bool testingSuperAdminBypassEnabled = false;

  static const Set<String> testingSuperAdminPhones = <String>{
    // Example:
    // '+923001234567',
  };

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  // =========================================================
  // CHECK ACCESS
  // =========================================================

  Future<SuperAdminAccessResult> checkCurrentAccess({
    bool forceRefreshToken = false,
  }) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return const SuperAdminAccessResult.denied(
        reason:
            'Please sign in before opening the SWAT RIDE Super Admin dashboard.',
      );
    }

    // =========================================================
    // DEV BYPASS
    // =========================================================

    final String normalizedPhone = _normalizePhone(user.phoneNumber);

    if (testingSuperAdminBypassEnabled &&
        testingSuperAdminPhones.contains(normalizedPhone)) {
      return SuperAdminAccessResult.allowed(
        adminId: user.uid,
        adminName: user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : 'Testing Super Admin',
        source: SuperAdminAccessSource.testingBypass,
        isTestingBypass: true,
      );
    }

    // =========================================================
    // FIREBASE CUSTOM CLAIM
    // =========================================================

    try {
      final IdTokenResult token =
          await user.getIdTokenResult(forceRefreshToken);

      final Map<String, dynamic> claims =
          token.claims ?? <String, dynamic>{};

      final String claimRole =
          claims['role']?.toString().trim().toLowerCase() ?? '';

      final bool isSuperAdminClaim =
          claimRole == 'super_admin';

      if (isSuperAdminClaim) {
        return SuperAdminAccessResult.allowed(
          adminId: user.uid,
          adminName: user.displayName?.trim().isNotEmpty == true
              ? user.displayName!.trim()
              : 'SWAT RIDE Super Admin',
          source: SuperAdminAccessSource.customClaim,
        );
      }
    } on FirebaseAuthException catch (error) {
      return SuperAdminAccessResult.error(
        reason:
            error.message ??
            'Unable to verify the Super Admin login token.',
      );
    }

    // =========================================================
    // FIRESTORE ADMINS/{UID}
    // =========================================================

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _firestore
              .collection('admins')
              .doc(user.uid)
              .get();

      final Map<String, dynamic>? data = snapshot.data();

      if (!snapshot.exists || data == null) {
        return const SuperAdminAccessResult.denied(
          reason:
              'This account does not have SWAT RIDE Super Admin access.',
        );
      }

      final bool isActive =
          data['isActive'] is bool
              ? data['isActive'] as bool
              : data['active'] is bool
              ? data['active'] as bool
              : false;

      final String role =
          data['role']?.toString().trim().toLowerCase() ?? '';

      if (!isActive) {
        return const SuperAdminAccessResult.denied(
          reason: 'This Super Admin account is inactive.',
        );
      }

      if (role != 'super_admin') {
        return const SuperAdminAccessResult.denied(
          reason:
              'This account is not authorized as SWAT RIDE Super Admin.',
        );
      }

      final String storedName =
          <dynamic>[
            data['displayName'],
            data['name'],
            user.displayName,
          ]
              .map(
                (dynamic value) =>
                    value?.toString().trim() ?? '',
              )
              .firstWhere(
                (String value) => value.isNotEmpty,
                orElse: () => 'SWAT RIDE Super Admin',
              );

      return SuperAdminAccessResult.allowed(
        adminId: user.uid,
        adminName: storedName,
        source:
            SuperAdminAccessSource.firestoreAdminRecord,
      );
    } on FirebaseException catch (error) {
      return SuperAdminAccessResult.error(
        reason:
            error.message ??
            'Unable to verify the Super Admin account.',
      );
    } catch (error) {
      return SuperAdminAccessResult.error(
        reason: 'Super Admin verification failed: $error',
      );
    }
  }

  // =========================================================
  // TOKEN REFRESH
  // =========================================================

  Future<void> refreshUserToken() async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    await user.getIdToken(true);
  }

  // =========================================================
  // SIGN OUT
  // =========================================================

  Future<void> signOut() => _auth.signOut();

  // =========================================================
  // PHONE NORMALIZATION
  // =========================================================

  static String _normalizePhone(String? value) {
    final String phone = value?.trim() ?? '';

    if (phone.isEmpty) {
      return '';
    }

    return phone.replaceAll(
      RegExp(r'[\s\-()]'),
      '',
    );
  }
}
