import '../models/agent_orchestrator_request.dart';
import '../models/agent_orchestrator_response.dart';
import 'openclaw_transport.dart';

// =========================================================
// OPENCLAW — PLACEHOLDER TRANSPORT
// =========================================================
//
// Safe Phase 10 default: always unavailable.
// This prevents accidental network calls before owner-approved setup.

class OpenClawPlaceholderTransport
    implements OpenClawTransport {
  const OpenClawPlaceholderTransport();

  @override
  String get transportId => 'openclaw_placeholder';

  @override
  Future<bool> ping() async => false;

  @override
  Future<AgentOrchestratorResponse> send(
    AgentOrchestratorRequest request,
  ) async {
    return AgentOrchestratorResponse(
      requestId: request.requestId,
      status: 'UNAVAILABLE',
      text: '',
      requestedToolIds: const <String>[],
      message:
          'OpenClaw transport is not connected in Phase 10.',
    );
  }
}
