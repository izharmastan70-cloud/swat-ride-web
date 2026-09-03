import '../models/agent_ai_request.dart';
import '../models/agent_ai_response.dart';

// =========================================================
// AI AGENT — PROVIDER CONTRACT
// =========================================================
//
// Provider adapters must never receive unrestricted SWAT RIDE backend access.
// They only receive already-prepared/redacted request data.

abstract class AgentAiProvider {
  String get providerId;
  String get providerType;
  int get priority;
  bool get enabled;

  Future<bool> isAvailable();

  Future<AgentAiResponse> complete(
    AgentAiRequest request,
  );
}
