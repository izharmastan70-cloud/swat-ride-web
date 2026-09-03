import 'agent_action_definition.dart';

// =========================================================
// AI AGENT — CONTROLLED TOOL DEFINITION
// =========================================================
//
// A tool is NOT permission by itself.
// It only describes a future controlled function that may implement
// one registered AgentActionId.
//
// No direct Firebase/payment/file-system authority is stored here.

class AgentToolDefinition {
  final String toolId;
  final String actionId;
  final String module;
  final String description;
  final String risk;
  final bool readOnly;
  final bool enabled;
  final bool connectorReady;

  const AgentToolDefinition({
    required this.toolId,
    required this.actionId,
    required this.module,
    required this.description,
    required this.risk,
    required this.readOnly,
    required this.enabled,
    required this.connectorReady,
  });

  bool get executable => enabled && connectorReady;

  void validateAgainstAction(AgentActionDefinition action) {
    if (actionId != action.actionId) {
      throw const AgentToolValidationException(
        'Tool actionId does not match Action Registry definition.',
      );
    }
    if (module != action.module) {
      throw const AgentToolValidationException(
        'Tool module does not match Action Registry definition.',
      );
    }
    if (risk != action.risk) {
      throw const AgentToolValidationException(
        'Tool risk does not match Action Registry definition.',
      );
    }
    if (readOnly != action.readOnly) {
      throw const AgentToolValidationException(
        'Tool readOnly flag does not match Action Registry definition.',
      );
    }
  }
}

class AgentToolValidationException implements Exception {
  final String message;
  const AgentToolValidationException(this.message);

  @override
  String toString() => 'AgentToolValidationException: $message';
}
