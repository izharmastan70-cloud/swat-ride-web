import '../models/agent_read_only_payload.dart';
import '../models/agent_tool_request.dart';

// =========================================================
// AI AGENT — READ-ONLY CONNECTOR CONTRACT
// =========================================================
//
// Future SWAT RIDE module connectors must implement this contract for
// read-only access first.
//
// A connector:
// - declares exactly which actionIds it supports
// - receives exact actionScope
// - returns structured data only
// - exposes no arbitrary Firestore/database query primitive
// - performs no writes

abstract class AgentReadOnlyConnector {
  String get connectorId;
  String get module;
  Set<String> get supportedActionIds;

  bool supports(String actionId) =>
      supportedActionIds.contains(actionId);

  Future<AgentReadOnlyPayload> executeReadOnly(
    AgentToolRequest request,
  );
}
