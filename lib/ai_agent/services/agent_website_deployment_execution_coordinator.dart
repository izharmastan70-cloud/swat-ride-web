import '../models/agent_code_backup_manifest.dart';
import '../models/agent_website_deployment_history.dart';
import '../models/agent_website_deployment_plan.dart';
import 'agent_website_deployment_adapter.dart';
import 'agent_website_deployment_lifecycle_service.dart';

/// Phase 34 Step 3D-E2.
///
/// Controlled website deployment execution boundary.
///
/// Required chain:
///
/// approved production plan
///   -> exact complete backup
///   -> controlled deployment adapter
///   -> persistent deployment history
///   -> append-only deployment audit
///
/// Default adapter is fail-closed and performs no real deployment.
///
/// This coordinator itself contains no:
/// - Vercel/GitHub credential handling;
/// - shell/process execution;
/// - DNS/domain mutation;
/// - unrestricted filesystem access.
class AgentWebsiteDeploymentExecutionCoordinator {
  final AgentWebsiteDeploymentAdapter adapter;
  final AgentWebsiteDeploymentLifecycleService lifecycleService;

  const AgentWebsiteDeploymentExecutionCoordinator({
    this.adapter = const AgentDisabledWebsiteDeploymentAdapter(),
    required this.lifecycleService,
  });

  Future<AgentWebsiteControlledDeploymentResult> executeProduction({
    required AgentWebsiteDeploymentPlan plan,
    required AgentCodeBackupManifest backup,
    required String actorId,
  }) async {
    plan.validate();

    final String safeActorId = actorId.trim();

    if (safeActorId.isEmpty) {
      throw const AgentWebsiteDeploymentExecutionException(
        'Deployment execution requires actorId.',
      );
    }

    if (plan.target != AgentWebsiteDeploymentTarget.production) {
      throw const AgentWebsiteDeploymentExecutionException(
        'Controlled production execution requires PRODUCTION target.',
      );
    }

    if (!plan.canDeployToProduction) {
      throw const AgentWebsiteDeploymentExecutionException(
        'Production deployment plan is not authorized. '
        'Separate production approval must be consumed and preview must remain valid.',
      );
    }

    _validateBackup(plan: plan, backup: backup);

    final AgentWebsiteDeploymentExecutionResult execution = await adapter
        .deploy(plan);

    if (execution.deploymentId != plan.deploymentId) {
      throw const AgentWebsiteDeploymentExecutionException(
        'Deployment adapter returned a mismatched deploymentId.',
      );
    }

    final DateTime now = DateTime.now();

    final AgentWebsiteDeploymentHistory history = AgentWebsiteDeploymentHistory(
      deploymentId: plan.deploymentId,
      changeId: plan.changeId,
      approvalId: plan.approvalId,
      target: plan.target,

      // This records execution state only.
      // KEEP and ROLLBACK remain later explicit Owner decisions.
      decision: AgentWebsiteDeploymentDecision.approved,

      approvedFilePaths: List<String>.unmodifiable(plan.approvedFilePaths),

      backupId: backup.backupId,

      deploymentAttempted: execution.attempted,

      deploymentSucceeded: execution.succeeded,

      ownerKeepConfirmed: false,

      rollbackRequested: false,

      rollbackCompleted: false,

      createdAt: now,

      deployedAt: execution.succeeded ? execution.createdAt : null,

      decidedAt: null,
    );

    history.validate();

    final AgentWebsiteDeploymentHistory savedHistory = await lifecycleService
        .recordDeploymentState(
          history: history,
          actorId: safeActorId,
          reason: execution.reason,
        );

    return AgentWebsiteControlledDeploymentResult(
      execution: execution,
      history: savedHistory,
      backup: backup,
    );
  }

  void _validateBackup({
    required AgentWebsiteDeploymentPlan plan,
    required AgentCodeBackupManifest backup,
  }) {
    if (!backup.isComplete) {
      throw const AgentWebsiteDeploymentExecutionException(
        'Production deployment blocked because backup is incomplete.',
      );
    }

    if (backup.changeId != plan.changeId) {
      throw const AgentWebsiteDeploymentExecutionException(
        'Backup changeId does not match deployment plan changeId.',
      );
    }

    final Set<String> deploymentScope = plan.approvedFilePaths
        .map((String path) => _normalizePath(path))
        .toSet();

    final Set<String> backupScope = backup.entries
        .map((entry) => _normalizePath(entry.filePath))
        .toSet();

    if (deploymentScope.length != plan.approvedFilePaths.length ||
        backupScope.length != backup.entries.length) {
      throw const AgentWebsiteDeploymentExecutionException(
        'Duplicate paths detected in deployment or backup scope.',
      );
    }

    if (deploymentScope.length != backupScope.length ||
        !deploymentScope.containsAll(backupScope) ||
        !backupScope.containsAll(deploymentScope)) {
      throw const AgentWebsiteDeploymentExecutionException(
        'Backup scope must exactly match production-approved website file scope.',
      );
    }
  }

  static String _normalizePath(String path) {
    return path.trim().replaceAll(r'\', '/');
  }
}

class AgentWebsiteControlledDeploymentResult {
  final AgentWebsiteDeploymentExecutionResult execution;
  final AgentWebsiteDeploymentHistory history;
  final AgentCodeBackupManifest backup;

  const AgentWebsiteControlledDeploymentResult({
    required this.execution,
    required this.history,
    required this.backup,
  });

  bool get deploymentAttempted => execution.attempted;

  bool get deploymentSucceeded => execution.succeeded;

  bool get blocked => !execution.attempted && !execution.succeeded;
}

class AgentWebsiteDeploymentExecutionException implements Exception {
  final String message;

  const AgentWebsiteDeploymentExecutionException(this.message);

  @override
  String toString() => 'AgentWebsiteDeploymentExecutionException: $message';
}
