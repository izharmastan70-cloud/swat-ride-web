// =========================================================
// AI AGENT — REPORT CONSTANTS
// =========================================================

class AgentReportType {
  AgentReportType._();

  static const String systemHealth = 'SYSTEM_HEALTH';
  static const String dailyOwnerBrief = 'DAILY_OWNER_BRIEF';

  static const Set<String> values = <String>{
    systemHealth,
    dailyOwnerBrief,
  };

  static bool isValid(String value) => values.contains(value);
}

class AgentReportStatus {
  AgentReportStatus._();

  static const String ready = 'READY';
  static const String partial = 'PARTIAL';
  static const String unavailable = 'UNAVAILABLE';

  static const Set<String> values = <String>{
    ready,
    partial,
    unavailable,
  };

  static bool isValid(String value) => values.contains(value);
}
