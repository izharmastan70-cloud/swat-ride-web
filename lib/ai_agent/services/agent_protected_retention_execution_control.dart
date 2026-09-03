import '../models/agent_protected_retention_execution_settings.dart';

class AgentProtectedRetentionExecutionControlDecision {
  final bool allowedToProceed;
  final bool executionEnabled;
  final bool destructiveExecutionAuthorized;
  final String decisionCode;
  final String reason;

  const AgentProtectedRetentionExecutionControlDecision({
    required this.allowedToProceed,
    required this.executionEnabled,
    required this.destructiveExecutionAuthorized,
    required this.decisionCode,
    required this.reason,
  });
}

/// Owner/Super Admin execution-control boundary.
///
/// IMPORTANT:
/// - This service contains NO Firestore dependency.
/// - It does NOT delete or mutate protected records.
/// - It only evaluates enablement state.
/// - destructiveExecutionAuthorized remains false in Phase 37
///   until a real audited adapter is separately connected.
abstract final class AgentProtectedRetentionExecutionControl {
  static AgentProtectedRetentionExecutionControlDecision evaluate(
    AgentProtectedRetentionExecutionSettings settings,
  ) {
    if (settings.updatedBy.trim().isEmpty) {
      return const AgentProtectedRetentionExecutionControlDecision(
        allowedToProceed: false,
        executionEnabled: false,
        destructiveExecutionAuthorized: false,
        decisionCode: 'OWNER_ID_REQUIRED',
        reason:
            'Owner/Super Admin identity is required for protected execution settings.',
      );
    }

    if (!settings.requireApproval ||
        !settings.requireConsumedApproval ||
        !settings.requireExplicitFinalConfirmation ||
        !settings.requireAuditTrail ||
        !settings.requireSuperAdmin) {
      return const AgentProtectedRetentionExecutionControlDecision(
        allowedToProceed: false,
        executionEnabled: false,
        destructiveExecutionAuthorized: false,
        decisionCode: 'MANDATORY_SAFETY_GUARD_DISABLED',
        reason: 'Protected execution safety guards cannot be disabled.',
      );
    }

    if (settings.emergencyStopActive) {
      return const AgentProtectedRetentionExecutionControlDecision(
        allowedToProceed: false,
        executionEnabled: false,
        destructiveExecutionAuthorized: false,
        decisionCode: 'EMERGENCY_STOP_ACTIVE',
        reason: 'Emergency Stop blocks protected-data execution.',
      );
    }

    if (!settings.masterExecutionEnabled) {
      return const AgentProtectedRetentionExecutionControlDecision(
        allowedToProceed: false,
        executionEnabled: false,
        destructiveExecutionAuthorized: false,
        decisionCode: 'MASTER_EXECUTION_DISABLED',
        reason: 'Protected execution master switch is disabled.',
      );
    }

    if (!settings.protectedDeletionEnabled) {
      return const AgentProtectedRetentionExecutionControlDecision(
        allowedToProceed: false,
        executionEnabled: false,
        destructiveExecutionAuthorized: false,
        decisionCode: 'PROTECTED_DELETION_DISABLED',
        reason: 'Protected deletion enablement is disabled.',
      );
    }

    if (settings.reason.trim().length < 10) {
      return const AgentProtectedRetentionExecutionControlDecision(
        allowedToProceed: false,
        executionEnabled: false,
        destructiveExecutionAuthorized: false,
        decisionCode: 'ENABLEMENT_REASON_REQUIRED',
        reason:
            'A meaningful reason is required before protected execution can be enabled.',
      );
    }

    // Phase 37 safety:
    // Owner controls may indicate operational intent,
    // but real destructive authority remains separately blocked.
    return const AgentProtectedRetentionExecutionControlDecision(
      allowedToProceed: true,
      executionEnabled: true,
      destructiveExecutionAuthorized: false,
      decisionCode: 'ENABLEMENT_CONTROLS_READY',
      reason:
          'Owner enablement controls passed. Real destructive execution remains separately disabled.',
    );
  }
}
