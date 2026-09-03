import '../constants/agent_action_ids.dart';
import '../models/agent_action_definition.dart';
import '../models/agent_tool_definition.dart';
import 'agent_action_registry.dart';

// =========================================================
// AI AGENT — CONTROLLED TOOL REGISTRY
// =========================================================
//
// Phase 6 FOUNDATION ONLY.
//
// All tools are connectorReady = false on purpose.
// This means the AI can discover what controlled functions exist,
// but cannot execute Ride/Driver/Food/Hotel/Tour/Finance/etc. yet.
//
// Later connector phases may replace individual definitions with
// connectorReady=true only after the real module adapter is built,
// reviewed, permission-gated and tested.

class AgentControlledToolRegistry {
  AgentControlledToolRegistry._();

  static final Map<String, AgentToolDefinition> _tools =
      _buildDefinitions();

  static Map<String, AgentToolDefinition> _buildDefinitions() {
    final Map<String, AgentToolDefinition> result =
        <String, AgentToolDefinition>{};

    for (final String actionId in AgentActionId.values) {
      final AgentActionDefinition? action =
          AgentActionRegistry.get(actionId);

      if (action == null) {
        continue;
      }

      final AgentToolDefinition tool = AgentToolDefinition(
        toolId: 'tool.$actionId',
        actionId: action.actionId,
        module: action.module,
        description: action.description,
        risk: action.risk,
        readOnly: action.readOnly,
        enabled: true,
        connectorReady: false,
      );

      tool.validateAgainstAction(action);
      result[tool.toolId] = tool;
    }

    return Map<String, AgentToolDefinition>.unmodifiable(result);
  }

  static AgentToolDefinition? get(String toolId) => _tools[toolId];

  static AgentToolDefinition? getByActionId(String actionId) {
    return _tools['tool.$actionId'];
  }

  static List<AgentToolDefinition> get all =>
      _tools.values.toList(growable: false);

  static List<AgentToolDefinition> forModule(String module) {
    return _tools.values
        .where((AgentToolDefinition tool) => tool.module == module)
        .toList(growable: false);
  }

  static bool isKnownTool(String toolId) => _tools.containsKey(toolId);
}
