import '../constants/agent_provider_constants.dart';
import '../models/agent_ai_request.dart';
import '../models/agent_ai_response.dart';
import 'agent_ai_provider.dart';

// =========================================================
// AI AGENT — PLACEHOLDER FREE PROVIDER
// =========================================================
//
// Phase 9 deliberately does NOT include real API keys or HTTP calls.
// Replace this adapter later with an approved free provider implementation.

class AgentPlaceholderFreeProvider implements AgentAiProvider {
  final String id;
  final int providerPriority;
  final bool providerEnabled;

  const AgentPlaceholderFreeProvider({
    required this.id,
    required this.providerPriority,
    this.providerEnabled = true,
  });

  @override
  String get providerId => id;

  @override
  String get providerType => AgentProviderType.freeCloud;

  @override
  int get priority => providerPriority;

  @override
  bool get enabled => providerEnabled;

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
          'Placeholder free provider has no real network/API implementation yet.',
    );
  }
}
