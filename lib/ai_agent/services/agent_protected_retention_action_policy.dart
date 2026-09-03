import '../models/agent_protected_retention_action_request.dart';

class AgentProtectedRetentionActionDecision {
  final bool allowedToRequestApproval;
  final bool approvalRequired;
  final bool auditRequired;
  final bool executionAuthorized;
  final String decisionCode;
  final String reason;

  const AgentProtectedRetentionActionDecision({
    required this.allowedToRequestApproval,
    required this.approvalRequired,
    required this.auditRequired,
    required this.executionAuthorized,
    required this.decisionCode,
    required this.reason,
  });
}

/// High-risk policy for protected retention operations.
///
/// IMPORTANT:
/// - This service only evaluates whether a request may proceed
///   to approval.
/// - It does NOT delete anything.
/// - It does NOT write to Firestore.
/// - Approval + audit are mandatory.
/// - Execution remains separately blocked in this phase.
abstract final class AgentProtectedRetentionActionPolicy {
  static AgentProtectedRetentionActionDecision evaluate(
    AgentProtectedRetentionActionRequest request,
  ) {
    if (!request.isSuperAdminRequest) {
      return const AgentProtectedRetentionActionDecision(
        allowedToRequestApproval: false,
        approvalRequired: true,
        auditRequired: true,
        executionAuthorized: false,
        decisionCode: 'SUPER_ADMIN_REQUIRED',
        reason: 'Protected retention actions require Super Admin authority.',
      );
    }

    if (request.requestedBy.trim().isEmpty) {
      return const AgentProtectedRetentionActionDecision(
        allowedToRequestApproval: false,
        approvalRequired: true,
        auditRequired: true,
        executionAuthorized: false,
        decisionCode: 'ACTOR_REQUIRED',
        reason: 'Actor identity is required for protected retention actions.',
      );
    }

    if (!request.hasExplicitReason) {
      return const AgentProtectedRetentionActionDecision(
        allowedToRequestApproval: false,
        approvalRequired: true,
        auditRequired: true,
        executionAuthorized: false,
        decisionCode: 'REASON_REQUIRED',
        reason:
            'A meaningful reason is required before protected-data action approval.',
      );
    }

    if (!request.hasExplicitConfirmation) {
      return const AgentProtectedRetentionActionDecision(
        allowedToRequestApproval: false,
        approvalRequired: true,
        auditRequired: true,
        executionAuthorized: false,
        decisionCode: 'EXPLICIT_CONFIRMATION_REQUIRED',
        reason: 'Exact protected-data confirmation phrase is required.',
      );
    }

    if (request.collectionPath.trim().isEmpty || request.recordIds.isEmpty) {
      return const AgentProtectedRetentionActionDecision(
        allowedToRequestApproval: false,
        approvalRequired: true,
        auditRequired: true,
        executionAuthorized: false,
        decisionCode: 'TARGET_REQUIRED',
        reason: 'Protected-data target collection and record IDs are required.',
      );
    }

    if (!request.hasApproval) {
      return const AgentProtectedRetentionActionDecision(
        allowedToRequestApproval: true,
        approvalRequired: true,
        auditRequired: true,
        executionAuthorized: false,
        decisionCode: 'APPROVAL_REQUIRED',
        reason:
            'Request is valid but requires an explicit approval before execution.',
      );
    }

    return const AgentProtectedRetentionActionDecision(
      allowedToRequestApproval: true,
      approvalRequired: true,
      auditRequired: true,
      executionAuthorized: false,
      decisionCode: 'APPROVED_REQUEST_AWAITING_EXECUTION_LAYER',
      reason:
          'Approval reference is present, but deletion execution is intentionally not enabled in this phase.',
    );
  }
}
