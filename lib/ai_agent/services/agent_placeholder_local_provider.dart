import '../constants/agent_provider_constants.dart';
import '../models/agent_ai_request.dart';
import '../models/agent_ai_response.dart';
import 'agent_ai_provider.dart';

// =========================================================
// AI AGENT — PLACEHOLDER LOCAL PROVIDER
// =========================================================
//
// Future slot for Ollama/local server or another private runtime.
// No local model process is started in Phase 9.

class AgentPlaceholderLocalProvider implements AgentAiProvider {
  const AgentPlaceholderLocalProvider();

  @override
  String get providerId => 'local_ai_slot';

  @override
  String get providerType => AgentProviderType.local;

  @override
  int get priority => 100;

  @override
  bool get enabled => true;

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<AgentAiResponse> complete(
    AgentAiRequest request,
  ) async {
    return AgentAiResponse(
      requestId: request.requestId,
      providerId: providerId,
      providerType: providerType,
      status: AgentProviderResultStatus.unavailable,
      text: '',
      message:
          'Local AI slot exists, but no local model/server is attached yet.',
    );
  }
}
