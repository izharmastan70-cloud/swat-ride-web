// =========================================================
// AI AGENT — CRASH CONSTANTS
// =========================================================

class AgentCrashSeverity {
  AgentCrashSeverity._();

  static const String info = 'INFO';
  static const String warning = 'WARNING';
  static const String high = 'HIGH';
  static const String critical = 'CRITICAL';

  static const Set<String> values = <String>{
    info,
    warning,
    high,
    critical,
  };
}

class AgentCrashCategory {
  AgentCrashCategory._();

  static const String flutter = 'FLUTTER';
  static const String dart = 'DART';
  static const String firebase = 'FIREBASE';
  static const String network = 'NETWORK';
  static const String storage = 'STORAGE';
  static const String payment = 'PAYMENT';
  static const String build = 'BUILD';
  static const String unknown = 'UNKNOWN';
}

class AgentCrashStatus {
  AgentCrashStatus._();

  static const String open = 'OPEN';
  static const String classified = 'CLASSIFIED';
  static const String handedToCodeAgent = 'HANDED_TO_CODE_AGENT';
  static const String resolved = 'RESOLVED';
  static const String ignored = 'IGNORED';
}
