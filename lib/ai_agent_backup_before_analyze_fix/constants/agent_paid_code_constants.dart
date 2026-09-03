// =========================================================
// AI AGENT — PAID CODE AI CONSTANTS
// =========================================================

class AgentPaidCodeRequestType {
  AgentPaidCodeRequestType._();

  static const String analyzeError = 'ANALYZE_ERROR';
  static const String prepareFix = 'PREPARE_FIX';

  static const Set<String> values = <String>{
    analyzeError,
    prepareFix,
  };

  static bool isValid(String value) => values.contains(value);
}

class AgentPaidCodeResultStatus {
  AgentPaidCodeResultStatus._();

  static const String success = 'SUCCESS';
  static const String denied = 'DENIED';
  static const String unavailable = 'UNAVAILABLE';
  static const String failed = 'FAILED';
}

class AgentPaidCodeProviderStatus {
  AgentPaidCodeProviderStatus._();

  static const String configured = 'CONFIGURED';
  static const String unavailable = 'UNAVAILABLE';
  static const String disabled = 'DISABLED';
  static const String error = 'ERROR';
}
