import '../models/agent_orchestrator_request.dart';
import '../models/agent_orchestrator_response.dart';

// =========================================================
// AI AGENT — ORCHESTRATOR CONTRACT
// =========================================================
//
// OpenClaw is one implementation, not the owner of SWAT RIDE security.
// The Permission Engine / Runtime Gate / Controlled Tool layer remain
// outside the orchestrator.

abstract class AgentOrchestrator {
  String get orchestratorId;

  Future<bool> isAvailable();

  Future<AgentOrchestratorResponse> process(
    AgentOrchestratorRequest request,
  );
}
