// =========================================================
// AI AGENT — ACTION DEFINITION
// =========================================================

class AgentActionRisk {
  AgentActionRisk._();

  static const String low = 'LOW';
  static const String medium = 'MEDIUM';
  static const String high = 'HIGH';
  static const String critical = 'CRITICAL';

  static const Set<String> values = <String>{
    low,
    medium,
    high,
    critical,
  };

  static bool isValid(String value) => values.contains(value);
}

class AgentActionDefinition {
  final String actionId;
  final String module;
  final String description;
  final String risk;
  final bool readOnly;
  final bool alwaysRequiresApproval;
  final bool permanentlyForbiddenForAi;

  const AgentActionDefinition({
    required this.actionId,
    required this.module,
    required this.description,
    required this.risk,
    required this.readOnly,
    this.alwaysRequiresApproval = false,
    this.permanentlyForbiddenForAi = false,
  });
}
