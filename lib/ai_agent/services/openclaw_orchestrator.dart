import '../models/agent_orchestrator_request.dart';
import '../models/agent_orchestrator_response.dart';
import 'agent_orchestrator.dart';
import 'openclaw_placeholder_transport.dart';
import 'openclaw_transport.dart';

// =========================================================
// OPENCLAW — ORCHESTRATOR ADAPTER
// =========================================================
//
// Read-only foundation.
// OpenClaw can request ONLY the read-only tool IDs supplied in the request.
// Any unknown/wider tool request is stripped and treated as invalid later
// by the Controlled Tool layer.

class OpenClawOrchestrator implements AgentOrchestrator {
  final OpenClawTransport transport;

  OpenClawOrchestrator({
    OpenClawTransport? transport,
  }) : transport =
            transport ?? const OpenClawPlaceholderTransport();

  @override
  String get orchestratorId => 'openclaw';

  @override
  Future<bool> isAvailable() => transport.ping();

  @override
  Future<AgentOrchestratorResponse> process(
    AgentOrchestratorRequest request,
  ) async {
    request.validate();

    final bool available = await isAvailable();

    if (!available) {
      return AgentOrchestratorResponse(
        requestId: request.requestId,
        status: 'UNAVAILABLE',
        text: '',
        requestedToolIds: const <String>[],
        message: 'OpenClaw is not currently connected.',
      );
    }

    final AgentOrchestratorResponse raw =
        await transport.send(request);

    final Set<String> allowed =
        request.allowedReadOnlyToolIds.toSet();

    final List<String> filteredToolIds =
        raw.requestedToolIds
            .where(allowed.contains)
            .toList(growable: false);

    final bool attemptedUnauthorizedTool =
        filteredToolIds.length != raw.requestedToolIds.length;

    if (attemptedUnauthorizedTool) {
      return AgentOrchestratorResponse(
        requestId: raw.requestId,
        status: 'DENIED',
        text: '',
        requestedToolIds: filteredToolIds,
        message:
            'OpenClaw requested one or more tools outside the supplied read-only allowlist.',
      );
    }

    return AgentOrchestratorResponse(
      requestId: raw.requestId,
      status: raw.status,
      text: raw.text,
      requestedToolIds: filteredToolIds,
      message: raw.message,
    );
  }
}
