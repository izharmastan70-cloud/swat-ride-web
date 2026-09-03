import '../constants/agent_action_ids.dart';
import '../models/agent_read_only_payload.dart';
import '../models/agent_tool_request.dart';
import 'agent_read_only_connector.dart';

// =========================================================
// AI AGENT — CARGO READ-ONLY CONNECTOR STUB
// =========================================================
//
// IMPORTANT:
// This connector is intentionally NOT registered in
// AgentReadOnlyConnectorRegistry.
//
// It exists only to define the future Cargo read-only contract shape.
// Calling it directly still returns a safe unavailable error.

class AgentCargoConnectorStub implements AgentReadOnlyConnector {
  @override
  String get connectorId => 'connector.cargo.stub';

  @override
  String get module => 'cargo';

  @override
  Set<String> get supportedActionIds => const <String>{
        AgentActionId.readCargoBooking,
        AgentActionId.readCargoStatus,
      };

  @override
  bool supports(String actionId) =>
      supportedActionIds.contains(actionId);

  @override
  Future<AgentReadOnlyPayload> executeReadOnly(
    AgentToolRequest request,
  ) {
    throw StateError(
      'Cargo connector is not connected. Build/audit the real Cargo module first.',
    );
  }
}
