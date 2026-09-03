import 'agent_core_read_only_connector.dart';
import 'agent_read_only_connector.dart';

// =========================================================
// AI AGENT — READ-ONLY CONNECTOR REGISTRY
// =========================================================
//
// Phase 7 attaches only the AI Core connector.
// Business-module connectors are intentionally absent.

class AgentReadOnlyConnectorRegistry {
  final List<AgentReadOnlyConnector> _connectors;

  AgentReadOnlyConnectorRegistry({
    List<AgentReadOnlyConnector>? connectors,
  }) : _connectors = List<AgentReadOnlyConnector>.unmodifiable(
          connectors ??
              <AgentReadOnlyConnector>[
                AgentCoreReadOnlyConnector(),
              ],
        );

  AgentReadOnlyConnector? connectorFor({
    required String module,
    required String actionId,
  }) {
    for (final AgentReadOnlyConnector connector in _connectors) {
      if (connector.module == module &&
          connector.supports(actionId)) {
        return connector;
      }
    }
    return null;
  }

  List<AgentReadOnlyConnector> get all =>
      List<AgentReadOnlyConnector>.unmodifiable(_connectors);
}
