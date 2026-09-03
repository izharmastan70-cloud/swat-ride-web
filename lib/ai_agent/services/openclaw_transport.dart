import '../models/agent_orchestrator_request.dart';
import '../models/agent_orchestrator_response.dart';

// =========================================================
// OPENCLAW — TRANSPORT CONTRACT
// =========================================================
//
// Phase 10 intentionally has no HTTP/WebSocket implementation and no
// credentials. A later approved adapter can implement this interface.

abstract class OpenClawTransport {
  String get transportId;

  Future<bool> ping();

  Future<AgentOrchestratorResponse> send(
    AgentOrchestratorRequest request,
  );
}
