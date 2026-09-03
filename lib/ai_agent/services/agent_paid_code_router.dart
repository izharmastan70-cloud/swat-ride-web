import '../constants/agent_enums.dart';
import '../constants/agent_paid_code_constants.dart';
import '../models/agent_master_settings.dart';
import '../models/agent_paid_code_request.dart';
import '../models/agent_paid_code_response.dart';
import '../models/agent_role.dart';
import 'agent_paid_code_provider.dart';
import 'agent_placeholder_paid_code_provider.dart';

// =========================================================
// AI AGENT — PAID CODE ROUTER
// =========================================================
//
// Dedicated technical route only.
// This router is deliberately separate from AgentFreeAiRouter.

class AgentPaidCodeRouter {
  final AgentPaidCodeProvider provider;

  AgentPaidCodeRouter({
    AgentPaidCodeProvider? provider,
  }) : provider =
            provider ?? const AgentPlaceholderPaidCodeProvider();

  Future<AgentPaidCodeResponse> route({
    required AgentMasterSettings settings,
    required AgentRole codeRole,
    required AgentPaidCodeRequest request,
  }) async {
    try {
      request.validate();
    } catch (error) {
      return _deny(
        request,
        'Invalid Paid Code AI request: $error',
      );
    }

    if (codeRole.roleId != AgentRole.codeAgentRoleId ||
        codeRole.aiClass != AiClass.paidCodeAi) {
      return _deny(
        request,
        'Only code_agent with PAID_CODE_AI may use this router.',
      );
    }

    if (request.roleId != codeRole.roleId) {
      return _deny(
        request,
        'Request role does not match code_agent.',
      );
    }

    if (!codeRole.isOperational ||
        codeRole.isFailClosed ||
        !codeRole.isValid) {
      return _deny(
        request,
        'Code Agent is not operational/valid.',
      );
    }

    if (!settings.masterEnabled) {
      return _deny(
        request,
        'AI Master Control is OFF.',
      );
    }

    if (settings.emergencyReadOnly) {
      return _deny(
        request,
        'Emergency Read-Only mode blocks Paid Code AI.',
      );
    }

    if (!settings.paidCodeAiOperational) {
      return _deny(
        request,
        'Paid Code AI is OFF or budget is unavailable/exhausted.',
      );
    }

    final bool available = await provider.isAvailable();

    if (!available) {
      return AgentPaidCodeResponse(
        requestId: request.requestId,
        providerId: provider.providerId,
        status: AgentPaidCodeResultStatus.unavailable,
        diagnosis: '',
        proposedFixSummary: '',
        proposedFilePatches: const <String, String>{},
        additionalFilesRequested: const <String>[],
        message: 'Paid Code AI provider is unavailable.',
      );
    }

    try {
      return await provider.analyze(request);
    } catch (error) {
      return AgentPaidCodeResponse(
        requestId: request.requestId,
        providerId: provider.providerId,
        status: AgentPaidCodeResultStatus.failed,
        diagnosis: '',
        proposedFixSummary: '',
        proposedFilePatches: const <String, String>{},
        additionalFilesRequested: const <String>[],
        message: 'Paid Code AI provider failed safely: $error',
      );
    }
  }

  AgentPaidCodeResponse _deny(
    AgentPaidCodeRequest request,
    String message,
  ) {
    return AgentPaidCodeResponse(
      requestId: request.requestId,
      providerId: '',
      status: AgentPaidCodeResultStatus.denied,
      diagnosis: '',
      proposedFixSummary: '',
      proposedFilePatches: const <String, String>{},
      additionalFilesRequested: const <String>[],
      message: message,
    );
  }
}
