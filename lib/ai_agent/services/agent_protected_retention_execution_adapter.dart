import '../models/agent_protected_retention_execution_plan.dart';

/// Result returned by the protected-retention execution adapter.
///
/// IMPORTANT:
/// This result describes whether an adapter actually executed
/// an operation. It does not itself grant execution authority.
class AgentProtectedRetentionExecutionResult {
  final bool executed;
  final String decisionCode;
  final String reason;
  final String executionPlanId;
  final List<String> affectedRecordIds;

  const AgentProtectedRetentionExecutionResult({
    required this.executed,
    required this.decisionCode,
    required this.reason,
    required this.executionPlanId,
    required this.affectedRecordIds,
  });

  factory AgentProtectedRetentionExecutionResult.disabled({
    required AgentProtectedRetentionExecutionPlan plan,
  }) {
    return AgentProtectedRetentionExecutionResult(
      executed: false,
      decisionCode: 'PROTECTED_EXECUTION_ADAPTER_DISABLED',
      reason:
          'Protected-data execution adapter is disabled. No records were deleted or modified.',
      executionPlanId: plan.executionPlanId.trim(),
      affectedRecordIds: const <String>[],
    );
  }
}

/// Controlled boundary for any future protected-data execution.
///
/// Implementations MUST NOT broaden the approved collection,
/// record IDs, action type, or data class.
///
/// A real implementation may only be connected in a later phase
/// after its persistence rules, runtime gate, audit ordering,
/// emergency-stop behavior, and rollback/recovery strategy have
/// been separately reviewed.
abstract interface class AgentProtectedRetentionExecutionAdapter {
  bool get isConnected;

  bool get destructiveExecutionEnabled;

  Future<AgentProtectedRetentionExecutionResult> execute(
    AgentProtectedRetentionExecutionPlan plan,
  );
}

/// Default fail-closed implementation.
///
/// This adapter intentionally performs NO Firestore operation,
/// NO deletion, NO update, and NO external side effect.
///
/// Merely constructing or calling this adapter cannot authorize
/// protected-data deletion.
class AgentDisabledProtectedRetentionExecutionAdapter
    implements AgentProtectedRetentionExecutionAdapter {
  const AgentDisabledProtectedRetentionExecutionAdapter();

  @override
  bool get isConnected => false;

  @override
  bool get destructiveExecutionEnabled => false;

  @override
  Future<AgentProtectedRetentionExecutionResult> execute(
    AgentProtectedRetentionExecutionPlan plan,
  ) async {
    return AgentProtectedRetentionExecutionResult.disabled(plan: plan);
  }
}
