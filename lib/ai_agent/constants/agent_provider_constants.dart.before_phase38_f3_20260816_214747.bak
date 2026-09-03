// =========================================================
// AI AGENT — PROVIDER CONSTANTS
// =========================================================

class AgentProviderType {
  AgentProviderType._();

  static const String freeCloud = 'FREE_CLOUD';
  static const String local = 'LOCAL';

  static const Set<String> values = <String>{
    freeCloud,
    local,
  };

  static bool isValid(String value) => values.contains(value);
}

class AgentProviderStatus {
  AgentProviderStatus._();

  static const String unknown = 'UNKNOWN';
  static const String healthy = 'HEALTHY';
  static const String degraded = 'DEGRADED';
  static const String unavailable = 'UNAVAILABLE';
  static const String disabled = 'DISABLED';

  static const Set<String> values = <String>{
    unknown,
    healthy,
    degraded,
    unavailable,
    disabled,
  };

  static bool isValid(String value) => values.contains(value);
}

class AgentProviderResultStatus {
  AgentProviderResultStatus._();

  static const String success = 'SUCCESS';
  static const String unavailable = 'UNAVAILABLE';
  static const String failed = 'FAILED';
  static const String denied = 'DENIED';
}
