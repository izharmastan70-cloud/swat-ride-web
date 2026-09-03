import '../models/agent_website_deployment_history.dart';
import 'agent_audit_recorder.dart';
import 'agent_website_deployment_history_repository.dart';

/// Phase 34 Step 3D-D2C.
///
/// Couples website deployment-history persistence with the existing
/// append-only AgentAuditService through AgentAuditRecorder.
///
/// Ordering is deliberate:
/// 1. validate history;
/// 2. persist history;
/// 3. append audit event.
///
/// This service does NOT:
/// - deploy website code;
/// - execute shell/Git/Vercel commands;
/// - access deployment secrets;
/// - mutate DNS/domain configuration.
class AgentWebsiteDeploymentLifecycleService {
  final AgentWebsiteDeploymentHistoryRepository repository;
  final AgentAuditRecorder auditRecorder;

  const AgentWebsiteDeploymentLifecycleService({
    required this.repository,
    required this.auditRecorder,
  });

  Future<AgentWebsiteDeploymentHistory> recordDeploymentState({
    required AgentWebsiteDeploymentHistory history,
    required String actorId,
    required String reason,
  }) async {
    history.validate();

    final saved = await repository.save(history);

    await auditRecorder.websiteDeploymentLifecycle(
      history: saved,
      actorId: actorId,
      actionId: AgentWebsiteDeploymentAuditAction.stateSaved,
      result: saved.decision,
      reason: reason,
    );

    return saved;
  }

  Future<AgentWebsiteDeploymentHistory> recordKeep({
    required AgentWebsiteDeploymentHistory history,
    required String actorId,
  }) async {
    history.validate();

    if (!history.isKept) {
      throw const AgentWebsiteDeploymentLifecycleException(
        'KEEP audit requires a valid KEPT deployment history state.',
      );
    }

    final saved = await repository.save(history);

    await auditRecorder.websiteDeploymentLifecycle(
      history: saved,
      actorId: actorId,
      actionId: AgentWebsiteDeploymentAuditAction.keepConfirmed,
      result: 'KEPT',
      reason: 'Owner confirmed KEEP for website deployment.',
    );

    return saved;
  }

  Future<AgentWebsiteDeploymentHistory> recordRollbackRequested({
    required AgentWebsiteDeploymentHistory history,
    required String actorId,
  }) async {
    history.validate();

    if (!history.needsRollback) {
      throw const AgentWebsiteDeploymentLifecycleException(
        'Rollback-request audit requires ROLLBACK_REQUESTED state.',
      );
    }

    final saved = await repository.save(history);

    await auditRecorder.websiteDeploymentLifecycle(
      history: saved,
      actorId: actorId,
      actionId: AgentWebsiteDeploymentAuditAction.rollbackRequested,
      result: 'ROLLBACK_REQUESTED',
      reason: 'Owner requested website deployment rollback.',
    );

    return saved;
  }

  Future<AgentWebsiteDeploymentHistory> recordRollbackCompleted({
    required AgentWebsiteDeploymentHistory history,
    required String actorId,
  }) async {
    history.validate();

    if (!history.isRolledBack) {
      throw const AgentWebsiteDeploymentLifecycleException(
        'Rollback-complete audit requires ROLLED_BACK state.',
      );
    }

    final saved = await repository.save(history);

    await auditRecorder.websiteDeploymentLifecycle(
      history: saved,
      actorId: actorId,
      actionId: AgentWebsiteDeploymentAuditAction.rollbackCompleted,
      result: 'ROLLED_BACK',
      reason: 'Website deployment rollback completed.',
    );

    return saved;
  }
}

class AgentWebsiteDeploymentAuditAction {
  AgentWebsiteDeploymentAuditAction._();

  static const String stateSaved = 'website.deployment.history_saved';

  static const String keepConfirmed = 'website.deployment.keep_confirmed';

  static const String rollbackRequested =
      'website.deployment.rollback_requested';

  static const String rollbackCompleted =
      'website.deployment.rollback_completed';
}

class AgentWebsiteDeploymentLifecycleException implements Exception {
  final String message;

  const AgentWebsiteDeploymentLifecycleException(this.message);

  @override
  String toString() => 'AgentWebsiteDeploymentLifecycleException: $message';
}
