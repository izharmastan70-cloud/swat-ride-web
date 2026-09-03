import '../models/agent_module_connector_descriptor.dart';

// =========================================================
// AI AGENT — MODULE CONNECTOR CONTRACT
// =========================================================
//
// Future real module connectors implement this interface.
// They do NOT expose raw Firestore/database access.

abstract class AgentModuleConnector {
  AgentModuleConnectorDescriptor get descriptor;

  Future<bool> healthCheck();

  /// Phase 13 does not define write execution.
  /// Real read-only adapters will be added after auditing each actual module.
}
