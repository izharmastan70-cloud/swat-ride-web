// =========================================================
// AI AGENT — CORE ENUM CONSTANTS
// =========================================================
//
// SWAT RIDE keeps enum-like values as String constants so they
// serialize directly to/from Firestore and stay consistent with
// the existing project style.

class AgentMode {
  AgentMode._();

  static const String off = 'OFF';
  static const String monitorOnly = 'MONITOR_ONLY';
  static const String suggestOnly = 'SUGGEST_ONLY';
  static const String askFirst = 'ASK_FIRST';
  static const String auto = 'AUTO';

  static const Set<String> values = <String>{
    off,
    monitorOnly,
    suggestOnly,
    askFirst,
    auto,
  };

  static bool isValid(String value) => values.contains(value);
}

class AiClass {
  AiClass._();

  static const String freeAi = 'FREE_AI';
  static const String paidCodeAi = 'PAID_CODE_AI';
  static const String localAi = 'LOCAL_AI';

  static const Set<String> values = <String>{
    freeAi,
    paidCodeAi,
    localAi,
  };

  static bool isValid(String value) => values.contains(value);
}

class PrivacyLevel {
  PrivacyLevel._();

  static const String public = 'PUBLIC';
  static const String internal = 'INTERNAL';
  static const String private = 'PRIVATE';
  static const String highlySensitive = 'HIGHLY_SENSITIVE';
  static const String secret = 'SECRET';

  static const Set<String> values = <String>{
    public,
    internal,
    private,
    highlySensitive,
    secret,
  };

  static bool isValid(String value) => values.contains(value);
}
