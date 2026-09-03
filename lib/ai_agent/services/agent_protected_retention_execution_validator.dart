import '../models/agent_approval_request.dart';
import '../models/agent_protected_retention_action_request.dart';
import '../models/agent_protected_retention_execution_plan.dart';

class AgentProtectedRetentionExecutionValidation {
  final bool prerequisitesSatisfied;
  final bool deletionAuthorized;
  final String decisionCode;
  final String reason;

  const AgentProtectedRetentionExecutionValidation({
    required this.prerequisitesSatisfied,
    required this.deletionAuthorized,
    required this.decisionCode,
    required this.reason,
  });
}

/// Final pre-execution design validator.
///
/// This validator remains deliberately fail-closed.
///
/// Even when every prerequisite passes:
/// deletionAuthorized remains FALSE until a later, separately
/// audited execution adapter is explicitly implemented.
abstract final class AgentProtectedRetentionExecutionValidator {
  static AgentProtectedRetentionExecutionValidation validate({
    required AgentProtectedRetentionExecutionPlan plan,
    required AgentProtectedRetentionActionRequest request,
    required AgentApprovalRequest consumedApproval,
  }) {
    if (!consumedApproval.isConsumed) {
      return const AgentProtectedRetentionExecutionValidation(
        prerequisitesSatisfied: false,
        deletionAuthorized: false,
        decisionCode: 'CONSUMED_APPROVAL_REQUIRED',
        reason:
            'Protected-data execution requires an already-consumed approval.',
      );
    }

    if (plan.approvalId.trim() != consumedApproval.approvalId.trim()) {
      return const AgentProtectedRetentionExecutionValidation(
        prerequisitesSatisfied: false,
        deletionAuthorized: false,
        decisionCode: 'APPROVAL_ID_MISMATCH',
        reason: 'Execution plan approval does not match the consumed approval.',
      );
    }

    if (plan.requestId.trim() != request.requestId.trim()) {
      return const AgentProtectedRetentionExecutionValidation(
        prerequisitesSatisfied: false,
        deletionAuthorized: false,
        decisionCode: 'REQUEST_ID_MISMATCH',
        reason:
            'Execution plan request does not match the protected action request.',
      );
    }

    if (plan.actorId.trim() != request.requestedBy.trim() ||
        plan.actorRole.trim() != request.requestedByRole.trim()) {
      return const AgentProtectedRetentionExecutionValidation(
        prerequisitesSatisfied: false,
        deletionAuthorized: false,
        decisionCode: 'ACTOR_MISMATCH',
        reason:
            'Execution actor must exactly match the approved protected request.',
      );
    }

    if (plan.actionType != request.actionType ||
        plan.dataClass != request.dataClass) {
      return const AgentProtectedRetentionExecutionValidation(
        prerequisitesSatisfied: false,
        deletionAuthorized: false,
        decisionCode: 'PROTECTED_CLASS_MISMATCH',
        reason:
            'Protected action type/data class no longer matches the approved request.',
      );
    }

    if (plan.collectionPath.trim() != request.collectionPath.trim()) {
      return const AgentProtectedRetentionExecutionValidation(
        prerequisitesSatisfied: false,
        deletionAuthorized: false,
        decisionCode: 'COLLECTION_SCOPE_MISMATCH',
        reason: 'Execution collection no longer matches the approved request.',
      );
    }

    final List<String> plannedIds = plan.recordIds
        .map((String value) => value.trim())
        .toList(growable: false);

    final List<String> requestedIds = request.recordIds
        .map((String value) => value.trim())
        .toList(growable: false);

    if (!_sameOrderedValues(plannedIds, requestedIds)) {
      return const AgentProtectedRetentionExecutionValidation(
        prerequisitesSatisfied: false,
        deletionAuthorized: false,
        decisionCode: 'RECORD_SCOPE_MISMATCH',
        reason:
            'Execution record IDs do not exactly match the approved protected request.',
      );
    }

    if (!plan.approvalConsumed) {
      return const AgentProtectedRetentionExecutionValidation(
        prerequisitesSatisfied: false,
        deletionAuthorized: false,
        decisionCode: 'PLAN_APPROVAL_NOT_CONSUMED',
        reason:
            'Execution plan must explicitly record consumed approval state.',
      );
    }

    if (!plan.exactScopeVerified) {
      return const AgentProtectedRetentionExecutionValidation(
        prerequisitesSatisfied: false,
        deletionAuthorized: false,
        decisionCode: 'EXACT_SCOPE_NOT_VERIFIED',
        reason: 'Exact protected-data scope verification is required.',
      );
    }

    if (!plan.finalConfirmationVerified) {
      return const AgentProtectedRetentionExecutionValidation(
        prerequisitesSatisfied: false,
        deletionAuthorized: false,
        decisionCode: 'FINAL_CONFIRMATION_REQUIRED',
        reason: 'A separate final confirmation is required before execution.',
      );
    }

    if (!plan.hasExplicitTargets) {
      return const AgentProtectedRetentionExecutionValidation(
        prerequisitesSatisfied: false,
        deletionAuthorized: false,
        decisionCode: 'EXPLICIT_TARGETS_REQUIRED',
        reason:
            'Protected execution requires explicit collection and record IDs.',
      );
    }

    if (!plan.isSuperAdminPlan) {
      return const AgentProtectedRetentionExecutionValidation(
        prerequisitesSatisfied: false,
        deletionAuthorized: false,
        decisionCode: 'SUPER_ADMIN_REQUIRED',
        reason: 'Protected-data execution plan requires Super Admin authority.',
      );
    }

    if (plan.actorId.trim().isEmpty || plan.reason.trim().length < 10) {
      return const AgentProtectedRetentionExecutionValidation(
        prerequisitesSatisfied: false,
        deletionAuthorized: false,
        decisionCode: 'ACTOR_REASON_REQUIRED',
        reason:
            'Protected execution requires actor identity and a meaningful reason.',
      );
    }

    // Phase 37 Step 10:
    // Every design prerequisite passed, but real deletion
    // capability is still intentionally not authorized.
    return const AgentProtectedRetentionExecutionValidation(
      prerequisitesSatisfied: true,
      deletionAuthorized: false,
      decisionCode: 'READY_FOR_SEPARATE_EXECUTION_ADAPTER',
      reason:
          'Protected execution prerequisites passed. Actual deletion remains disabled until a separate audited execution adapter exists.',
    );
  }

  static bool _sameOrderedValues(List<String> left, List<String> right) {
    if (left.length != right.length) {
      return false;
    }

    for (int index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }

    return true;
  }
}
