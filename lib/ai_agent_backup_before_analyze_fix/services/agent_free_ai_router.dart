import '../constants/agent_enums.dart';
import '../constants/agent_provider_constants.dart';
import '../models/agent_ai_request.dart';
import '../models/agent_ai_response.dart';
import '../models/agent_master_settings.dart';
import '../models/agent_role.dart';
import 'agent_ai_provider.dart';
import 'agent_placeholder_free_provider.dart';
import 'agent_placeholder_local_provider.dart';
import 'agent_provider_health_service.dart';

// =========================================================
// AI AGENT — FREE/LOCAL ROUTER
// =========================================================
//
// Phase 9 routing policy:
// 1) Primary FREE provider
// 2) Backup FREE provider
// 3) LOCAL slot if enabled
// 4) Safe unavailable result
//
// PAID_CODE_AI is intentionally NOT part of this router.
// Business/routine AI can never silently fall through to paid code AI.

class AgentFreeAiRouter {
  final List<AgentAiProvider> providers;
  final AgentProviderHealthService healthService;

  AgentFreeAiRouter({
    List<AgentAiProvider>? providers,
    AgentProviderHealthService? healthService,
  })  : providers = List<AgentAiProvider>.unmodifiable(
          providers ??
              const <AgentAiProvider>[
                AgentPlaceholderFreeProvider(
                  id: 'free_primary_slot',
                  providerPriority: 10,
                ),
                AgentPlaceholderFreeProvider(
                  id: 'free_backup_slot',
                  providerPriority: 20,
                ),
                AgentPlaceholderLocalProvider(),
              ],
        ),
        healthService =
            healthService ?? AgentProviderHealthService();

  Future<AgentAiResponse> route({
    required AgentMasterSettings settings,
    required AgentRole role,
    required AgentAiRequest request,
  }) async {
    try {
      request.validate();
    } catch (error) {
      return _denied(
        request,
        message: 'Invalid AI request: $error',
      );
    }

    if (!settings.masterEnabled) {
      return _denied(
        request,
        message: 'AI Master Control is OFF.',
      );
    }

    if (settings.emergencyReadOnly &&
        role.mode != AgentMode.monitorOnly &&
        role.mode != AgentMode.suggestOnly) {
      return _denied(
        request,
        message:
            'Emergency Read-Only mode allows only monitor/suggest AI work.',
      );
    }

    if (!role.isOperational || role.isFailClosed || !role.isValid) {
      return _denied(
        request,
        message: 'Agent role is not operational/valid.',
      );
    }

    if (role.aiClass == AiClass.paidCodeAi) {
      return _denied(
        request,
        message:
            'PAID_CODE_AI is isolated from the Free/Local business router.',
      );
    }

    if (role.aiClass != AiClass.freeAi &&
        role.aiClass != AiClass.localAi) {
      return _denied(
        request,
        message: 'Unsupported AI class for this router.',
      );
    }

    final List<AgentAiProvider> ordered = providers
        .where((AgentAiProvider provider) => provider.enabled)
        .where(
          (AgentAiProvider provider) {
            if (provider.providerType == AgentProviderType.freeCloud) {
              return settings.freeAiEnabled;
            }

            if (provider.providerType == AgentProviderType.local) {
              return settings.localAiEnabled;
            }

            return false;
          },
        )
        .toList(growable: false)
      ..sort(
        (AgentAiProvider a, AgentAiProvider b) =>
            a.priority.compareTo(b.priority),
      );

    for (final AgentAiProvider provider in ordered) {
      try {
        final bool available = await provider.isAvailable();

        if (!available) {
          await healthService.markUnavailable(
            providerId: provider.providerId,
            providerType: provider.providerType,
            reason: 'Provider availability check returned false.',
          );
          continue;
        }

        final AgentAiResponse response =
            await provider.complete(request);

        if (response.isSuccess) {
          await healthService.recordSuccess(
            providerId: provider.providerId,
            providerType: provider.providerType,
          );
          return response;
        }

        await healthService.recordFailure(
          providerId: provider.providerId,
          providerType: provider.providerType,
          error: response.message,
        );
      } catch (error) {
        await healthService.recordFailure(
          providerId: provider.providerId,
          providerType: provider.providerType,
          error: error.toString(),
        );
      }
    }

    return AgentAiResponse(
      requestId: request.requestId,
      providerId: '',
      providerType: '',
      status: AgentProviderResultStatus.unavailable,
      text: '',
      message:
          'No free/local AI provider is currently available. Core SWAT RIDE must continue without AI.',
    );
  }

  AgentAiResponse _denied(
    AgentAiRequest request, {
    required String message,
  }) {
    return AgentAiResponse(
      requestId: request.requestId,
      providerId: '',
      providerType: '',
      status: AgentProviderResultStatus.denied,
      text: '',
      message: message,
    );
  }
}
