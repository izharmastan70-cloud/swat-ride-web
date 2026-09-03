import '../models/agent_paid_code_request.dart';
import '../models/agent_paid_code_response.dart';

// =========================================================
// AI AGENT — PAID CODE SCOPE GUARD
// =========================================================
//
// Enforces "one approval = one technical scope".
// A provider may suggest that additional files are needed, but those files
// must NOT be treated as approved automatically.

class AgentPaidCodeScopeGuard {
  const AgentPaidCodeScopeGuard();

  AgentPaidCodeScopeCheck checkResponse({
    required AgentPaidCodeRequest request,
    required AgentPaidCodeResponse response,
  }) {
    final Set<String> approved =
        request.approvedFilePaths.map((String e) => e.trim()).toSet();

    final Set<String> patched =
        response.proposedFilePatches.keys.map((String e) => e.trim()).toSet();

    final Set<String> requestedMore = response.additionalFilesRequested
        .map((String e) => e.trim())
        .where((String e) => e.isNotEmpty)
        .toSet();

    final Set<String> unauthorizedPatched =
        patched.difference(approved);

    if (unauthorizedPatched.isNotEmpty) {
      return AgentPaidCodeScopeCheck(
        allowed: false,
        requiresNewApproval: true,
        reason:
            'Provider proposed patches outside approved file scope: '
            '${unauthorizedPatched.join(', ')}',
      );
    }

    if (requestedMore.isNotEmpty) {
      return AgentPaidCodeScopeCheck(
        allowed: true,
        requiresNewApproval: true,
        reason:
            'Additional files were requested and require a new owner approval: '
            '${requestedMore.join(', ')}',
      );
    }

    return const AgentPaidCodeScopeCheck(
      allowed: true,
      requiresNewApproval: false,
      reason: 'Paid Code AI response stayed inside approved scope.',
    );
  }
}

class AgentPaidCodeScopeCheck {
  final bool allowed;
  final bool requiresNewApproval;
  final String reason;

  const AgentPaidCodeScopeCheck({
    required this.allowed,
    required this.requiresNewApproval,
    required this.reason,
  });
}
