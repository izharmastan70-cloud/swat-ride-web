import '../constants/agent_paid_code_constants.dart';
import '../models/agent_paid_code_request.dart';
import '../models/agent_paid_code_response.dart';
import 'agent_paid_code_provider.dart';

// =========================================================
// AI AGENT — PLACEHOLDER PAID CODE PROVIDER
// =========================================================
//
// Phase 15 contains no real paid API key/network call.
// Safe default: unavailable.

class AgentPlaceholderPaidCodeProvider
    implements AgentPaidCodeProvider {
  const AgentPlaceholderPaidCodeProvider();

  @override
  String get providerId => 'paid_code_provider_slot';

  @override
  bool get enabled => true;

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<AgentPaidCodeResponse> analyze(
    AgentPaidCodeRequest request,
  ) async {
    return AgentPaidCodeResponse(
      requestId: request.requestId,
      providerId: providerId,
      status: AgentPaidCodeResultStatus.unavailable,
      diagnosis: '',
      proposedFixSummary: '',
      proposedFilePatches: const <String, String>{},
      additionalFilesRequested: const <String>[],
      message:
          'Paid Code AI provider slot exists, but no real provider/API is connected yet.',
    );
  }
}
