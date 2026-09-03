import 'agent_retention_policy.dart';

enum AgentRetentionCategory {
  transientCallSession,
  supportContext,
  crashDiagnostic,
  approvalWorkflow,
  completedTask,
  taskIdempotency,
  providerHealth,
  auditEvidence,
  securityEvidence,
  financeEvidence,
  configuration,
  unknown,
}

/// Maps persistent SWAT RIDE AI record types to retention classifications.
///
/// IMPORTANT:
/// - This is classification only.
/// - It performs ZERO Firestore reads/writes/deletes.
/// - It does NOT enable cleanup.
/// - Finance/security/audit records remain protected from generic auto-delete.
abstract final class AgentRetentionRecordMap {
  static const Map<String, AgentRetentionCategory> collectionCategories =
      <String, AgentRetentionCategory>{
        'agent_call_sessions': AgentRetentionCategory.transientCallSession,

        'agent_feedback': AgentRetentionCategory.supportContext,

        'agent_crash_events': AgentRetentionCategory.crashDiagnostic,

        'agent_approvals': AgentRetentionCategory.approvalWorkflow,

        'agent_tasks': AgentRetentionCategory.completedTask,

        'agent_task_idempotency': AgentRetentionCategory.taskIdempotency,

        'ai_provider_status': AgentRetentionCategory.providerHealth,

        'agent_audit_logs': AgentRetentionCategory.auditEvidence,

        'agent_security_incidents': AgentRetentionCategory.securityEvidence,
        'agent_security_incident_idempotency':
            AgentRetentionCategory.securityEvidence,

        'agent_finance_records': AgentRetentionCategory.financeEvidence,

        'agent_settings': AgentRetentionCategory.configuration,

        'agent_roles': AgentRetentionCategory.configuration,

        'agent_workers': AgentRetentionCategory.configuration,
      };

  static AgentRetentionCategory categoryForCollection(String collectionPath) {
    return collectionCategories[collectionPath.trim()] ??
        AgentRetentionCategory.unknown;
  }

  static Duration? retentionForCategory(AgentRetentionCategory category) {
    switch (category) {
      case AgentRetentionCategory.transientCallSession:
        return AgentRetentionPolicy.callSessionRetention;

      case AgentRetentionCategory.supportContext:
        return AgentRetentionPolicy.supportContextRetention;

      case AgentRetentionCategory.crashDiagnostic:
        return AgentRetentionPolicy.crashEventRetention;

      case AgentRetentionCategory.approvalWorkflow:
        return AgentRetentionPolicy.approvalRetention;

      case AgentRetentionCategory.completedTask:
        return AgentRetentionPolicy.completedTaskRetention;

      case AgentRetentionCategory.taskIdempotency:
        return AgentRetentionPolicy.taskIdempotencyRetention;

      case AgentRetentionCategory.providerHealth:
        return AgentRetentionPolicy.providerHealthRetention;

      case AgentRetentionCategory.auditEvidence:
        return AgentRetentionPolicy.auditLogMinimumRetention;

      case AgentRetentionCategory.securityEvidence:
        return AgentRetentionPolicy.securityEvidenceMinimumRetention;

      case AgentRetentionCategory.financeEvidence:
        return AgentRetentionPolicy.financeRecordMinimumRetention;

      case AgentRetentionCategory.configuration:
      case AgentRetentionCategory.unknown:
        return null;
    }
  }

  static bool isGenericAutomaticCleanupEligible(
    AgentRetentionCategory category,
  ) {
    if (!AgentRetentionPolicy.automaticCleanupEnabled) {
      return false;
    }

    switch (category) {
      case AgentRetentionCategory.transientCallSession:
      case AgentRetentionCategory.supportContext:
      case AgentRetentionCategory.crashDiagnostic:
      case AgentRetentionCategory.approvalWorkflow:
      case AgentRetentionCategory.completedTask:
      case AgentRetentionCategory.taskIdempotency:
      case AgentRetentionCategory.providerHealth:
        return AgentRetentionPolicy.transientDataMayBeEligibleForCleanup;

      case AgentRetentionCategory.auditEvidence:
      case AgentRetentionCategory.securityEvidence:
      case AgentRetentionCategory.financeEvidence:
      case AgentRetentionCategory.configuration:
      case AgentRetentionCategory.unknown:
        return false;
    }
  }

  static bool requiresProtectedEvidenceHandling(
    AgentRetentionCategory category,
  ) {
    switch (category) {
      case AgentRetentionCategory.auditEvidence:
      case AgentRetentionCategory.securityEvidence:
      case AgentRetentionCategory.financeEvidence:
        return true;

      case AgentRetentionCategory.transientCallSession:
      case AgentRetentionCategory.supportContext:
      case AgentRetentionCategory.crashDiagnostic:
      case AgentRetentionCategory.approvalWorkflow:
      case AgentRetentionCategory.completedTask:
      case AgentRetentionCategory.taskIdempotency:
      case AgentRetentionCategory.providerHealth:
      case AgentRetentionCategory.configuration:
      case AgentRetentionCategory.unknown:
        return false;
    }
  }
}
