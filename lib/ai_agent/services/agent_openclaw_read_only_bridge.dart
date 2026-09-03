import '../models/agent_ai_request.dart';
import '../models/agent_master_settings.dart';
import '../models/agent_orchestrator_config.dart';
import '../models/agent_orchestrator_request.dart';
import '../models/agent_orchestrator_response.dart';
import '../models/agent_role.dart';
import '../services/agent_read_only_sanitizer.dart';
import 'agent_orchestrator.dart';
import 'agent_orchestrator_config_service.dart';
import 'openclaw_orchestrator.dart';

// =========================================================
// AI AGENT — OPENCLAW READ-ONLY BRIDGE
// =========================================================
//
// Phase 10 bridge does NOT execute tools.
// It only sends sanitized context + an explicit read-only tool allowlist
// to OpenClaw and returns its proposed response/tool requests.
//
// Actual tool execution must still go back through:
// Permission Engine -> Runtime Gate -> Controlled Read-Only Executor.

class AgentOpenClawReadOnlyBridge {
  final AgentOrchestrator orchestrator;
  final AgentOrchestratorConfigService configService;
  final AgentReadOnlySanitizer sanitizer;

  AgentOpenClawReadOnlyBridge({
    AgentOrchestrator? orchestrator,
    AgentOrchestratorConfigService? configService,
    AgentReadOnlySanitizer? sanitizer,
  })  : orchestrator = orchestrator ?? OpenClawOrchestrator(),
        configService =
            configService ?? AgentOrchestratorConfigService(),
        sanitizer = sanitizer ?? const AgentReadOnlySanitizer();

  Future<AgentOrchestratorResponse> process({
    required AgentMasterSettings settings,
    required AgentRole role,
    required AgentAiRequest aiRequest,
    required List<String> allowedReadOnlyToolIds,
  }) async {
    if (!settings.masterEnabled) {
      return _deny(
        aiRequest.requestId,
        'AI Master Control is OFF.',
      );
    }

    if (!role.isOperational ||
        role.isFailClosed ||
        !role.isValid) {
      return _deny(
        aiRequest.requestId,
        'Agent role is not operational/valid.',
      );
    }

    final AgentOrchestratorConfig config =
        await configService.getConfig();

    if (!config.enabled || !config.readOnlyOnly) {
      return _deny(
        aiRequest.requestId,
        'OpenClaw orchestrator is disabled or not in read-only mode.',
      );
    }

    final AgentOrchestratorRequest request =
        AgentOrchestratorRequest(
      requestId: aiRequest.requestId,
      roleId: role.roleId,
      purpose: aiRequest.purpose,
      prompt: aiRequest.prompt,
      sanitizedContext:
          sanitizer.sanitizeMap(aiRequest.context),
      allowedReadOnlyToolIds:
          List<String>.unmodifiable(
        allowedReadOnlyToolIds,
      ),
      createdAt: DateTime.now(),
    );

    return orchestrator.process(request);
  }

  AgentOrchestratorResponse _deny(
    String requestId,
    String message,
  ) {
    return AgentOrchestratorResponse(
      requestId: requestId,
      status: 'DENIED',
      text: '',
      requestedToolIds: const <String>[],
      message: message,
    );
  }
}
