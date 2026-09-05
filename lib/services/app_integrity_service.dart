import 'package:firebase_app_check/firebase_app_check.dart';

/// Obtains device-generated Firebase App Check tokens for protected APIs.
class AppIntegrityService {
  AppIntegrityService({FirebaseAppCheck? appCheck})
    : _appCheck = appCheck ?? FirebaseAppCheck.instance;

  final FirebaseAppCheck _appCheck;

  static Future<void> activate() {
    return FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.appAttest,
    );
  }

  Future<String> token() async {
    final String? value = await _appCheck.getToken();
    if (value == null || value.isEmpty) {
      throw StateError('APP_INTEGRITY_TOKEN_UNAVAILABLE');
    }
    return value;
  }
}