import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriverLoginResult {
  const DriverLoginResult({
    required this.driverId,
    required this.driverName,
    required this.phoneNumber,
    required this.vehicleType,
    required this.vehicleNumber,
  });

  final String driverId;
  final String driverName;
  final String phoneNumber;
  final String vehicleType;
  final String vehicleNumber;
}

class DriverAuthService {
  DriverAuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // DEVELOPMENT ONLY. Set false before production release.
  // When false, an authenticated Firebase Phone OTP session is required.
  static const bool testingOtpBypassEnabled = false;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;
  String? get currentDriverId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _drivers =>
      _firestore.collection('drivers');

  Future<DocumentSnapshot<Map<String, dynamic>>?> getCurrentDriverData({
    String? driverId,
  }) async {
    final String id = (driverId ?? currentDriverId ?? '').trim();
    if (id.isEmpty) return null;
    return _drivers.doc(id).get();
  }

  Future<bool> isDriverApproved({String? driverId}) async {
    final DocumentSnapshot<Map<String, dynamic>>? document =
        await getCurrentDriverData(driverId: driverId);
    return document?.exists == true &&
        document?.data()?['status']?.toString().toLowerCase() == 'approved';
  }

  // =========================================================
  // UNIFIED DRIVER LOGIN
  // =========================================================

  Future<DriverLoginResult> loginDriver({
    required String phoneNumber,
  }) async {
    final String phone = phoneNumber.trim();
    if (phone.length < 7) throw Exception('Enter a valid phone number.');

    if (testingOtpBypassEnabled) {
      return _findApprovedDriverByPhone(phone);
    }

    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('Verify your phone OTP before driver login.');
    }

    final DocumentSnapshot<Map<String, dynamic>> document =
        await _drivers.doc(user.uid).get();
    return _resultFromDocument(document, expectedPhone: phone);
  }

  Future<DriverLoginResult> _findApprovedDriverByPhone(String phone) async {
    QuerySnapshot<Map<String, dynamic>> snapshot = await _drivers
        .where('phoneNumber', isEqualTo: phone)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      snapshot =
          await _drivers.where('phone', isEqualTo: phone).limit(1).get();
    }

    if (snapshot.docs.isEmpty) {
      throw Exception(
        'Approved driver account not found for this phone number.',
      );
    }

    return _resultFromDocument(snapshot.docs.first, expectedPhone: phone);
  }

  DriverLoginResult _resultFromDocument(
    DocumentSnapshot<Map<String, dynamic>> document, {
    required String expectedPhone,
  }) {
    if (!document.exists || document.data() == null) {
      throw Exception('Driver account not found.');
    }

    final Map<String, dynamic> data = document.data()!;
    final String status =
        (data['status'] ?? 'pending').toString().trim().toLowerCase();

    if (status != 'approved') {
      throw Exception('Driver account is $status and cannot go online.');
    }
    final Map<dynamic, dynamic> vehicleApproval =
        data['vehicleApproval'] as Map<dynamic, dynamic>? ?? const {};
    final Map<dynamic, dynamic> documentApproval =
        data['documentApproval'] as Map<dynamic, dynamic>? ?? const {};
    final Map<dynamic, dynamic> photoApproval =
        data['primaryImageApproval'] as Map<dynamic, dynamic>? ?? const {};
    if (vehicleApproval['status'] != 'approved' ||
        documentApproval['status'] != 'approved' ||
        photoApproval['status'] != 'approved' ||
        (photoApproval['approvedUrl']?.toString().trim().isEmpty ?? true)) {
      throw Exception(
        'Your vehicle, documents and primary photo are awaiting Admin approval.',
      );
    }

    final String storedPhone =
        (data['phoneNumber'] ?? data['phone'] ?? expectedPhone)
            .toString()
            .trim();

    return DriverLoginResult(
      driverId: document.id,
      driverName: (data['fullName'] ?? data['name'] ?? 'SWAT RIDE Driver')
          .toString()
          .trim(),
      phoneNumber: storedPhone,
      vehicleType: (data['vehicleType'] ?? 'Vehicle').toString().trim(),
      vehicleNumber: (data['vehicleNumber'] ?? 'Not Added').toString().trim(),
    );
  }

  // =========================================================
  // REAL FIREBASE PHONE OTP (PRODUCTION)
  // =========================================================

  Future<void> sendPhoneOtp({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(UserCredential credential) onAutoVerified,
    required void Function(String message) onError,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber.trim(),
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          final UserCredential result =
              await _auth.signInWithCredential(credential);
          onAutoVerified(result);
        } on FirebaseAuthException catch (error) {
          onError(error.message ?? error.code);
        }
      },
      verificationFailed: (FirebaseAuthException error) {
        onError(error.message ?? error.code);
      },
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<UserCredential> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId.trim(),
      smsCode: smsCode.trim(),
    );
    return _auth.signInWithCredential(credential);
  }

  Future<void> logoutDriver() => _auth.signOut();
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
