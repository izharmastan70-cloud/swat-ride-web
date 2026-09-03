// =========================================================
// AI AGENT — ORCHESTRATOR CONSTANTS
// =========================================================

class AgentOrchestratorType {
  AgentOrchestratorType._();

  static const String openClaw = 'OPENCLAW';
  static const String future = 'FUTURE';

  static const Set<String> values = <String>{
    openClaw,
    future,
  };

  static bool isValid(String value) => values.contains(value);
}

class AgentOrchestratorStatus {
  AgentOrchestratorStatus._();

  static const String disconnected = 'DISCONNECTED';
  static const String configured = 'CONFIGURED';
  static const String healthy = 'HEALTHY';
  static const String unavailable = 'UNAVAILABLE';
  static const String error = 'ERROR';

  static const Set<String> values = <String>{
    disconnected,
    configured,
    healthy,
    unavailable,
    error,
  };

  static bool isValid(String value) => values.contains(value);
}
