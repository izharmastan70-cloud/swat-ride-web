import '../models/agent_code_backup_manifest.dart';
import '../models/agent_website_deployment_history.dart';
import '../models/agent_website_deployment_plan.dart';
import 'agent_code_backup_service.dart';

/// Phase 34 Step 3D-C.
///
/// Owner KEEP / ROLLBACK lifecycle coordinator.
///
/// Responsibilities:
/// - KEEP only an actually successful deployment;
/// - validate rollback against exact deployment/change scope;
/// - require a complete matching backup;
/// - restore only approved files from that backup;
/// - return immutable next deployment-history state.
///
/// This coordinator does NOT:
/// - deploy to Vercel;
/// - push Git commits;
/// - access Vercel/GitHub credentials;
/// - mutate DNS/domain configuration;
/// - authorize a rollback by itself.
///
/// Caller must supply explicit Owner decision.
class AgentWebsiteKeepRollbackCoordinator {
  final AgentCodeBackupService backupService;

  const AgentWebsiteKeepRollbackCoordinator({required this.backupService});

  AgentWebsiteDeploymentHistory confirmKeep({
    required AgentWebsiteDeploymentHistory current,
    required bool ownerConfirmedKeep,
    DateTime? decidedAt,
  }) {
    current.validate();

    if (!ownerConfirmedKeep) {
      throw const AgentWebsiteKeepRollbackException(
        'KEEP requires explicit Owner confirmation.',
      );
    }

    if (!current.deploymentAttempted || !current.deploymentSucceeded) {
      throw const AgentWebsiteKeepRollbackException(
        'A failed or unattempted deployment cannot be marked KEEP.',
      );
    }

    if (current.rollbackRequested || current.rollbackCompleted) {
      throw const AgentWebsiteKeepRollbackException(
        'Deployment already entered rollback lifecycle and cannot be marked KEEP.',
      );
    }

    final next = AgentWebsiteDeploymentHistory(
      deploymentId: current.deploymentId,
      changeId: current.changeId,
      approvalId: current.approvalId,
      target: current.target,
      decision: AgentWebsiteDeploymentDecision.kept,
      approvedFilePaths: List<String>.unmodifiable(current.approvedFilePaths),
      backupId: current.backupId,
      deploymentAttempted: current.deploymentAttempted,
      deploymentSucceeded: current.deploymentSucceeded,
      ownerKeepConfirmed: true,
      rollbackRequested: false,
      rollbackCompleted: false,
      createdAt: current.createdAt,
      deployedAt: current.deployedAt,
      decidedAt: decidedAt ?? DateTime.now(),
    );

    next.validate();
    return next;
  }

  AgentWebsiteDeploymentHistory requestRollback({
    required AgentWebsiteDeploymentHistory current,
    required AgentCodeBackupManifest backup,
    required bool ownerRequestedRollback,
    DateTime? decidedAt,
  }) {
    current.validate();

    if (!ownerRequestedRollback) {
      throw const AgentWebsiteKeepRollbackException(
        'ROLLBACK requires explicit Owner request.',
      );
    }

    _validateBackupMatch(current: current, backup: backup);

    if (!current.deploymentAttempted) {
      throw const AgentWebsiteKeepRollbackException(
        'Rollback cannot be requested for a deployment that was never attempted.',
      );
    }

    if (current.rollbackCompleted) {
      throw const AgentWebsiteKeepRollbackException(
        'Deployment is already rolled back.',
      );
    }

    final next = AgentWebsiteDeploymentHistory(
      deploymentId: current.deploymentId,
      changeId: current.changeId,
      approvalId: current.approvalId,
      target: current.target,
      decision: AgentWebsiteDeploymentDecision.rollbackRequested,
      approvedFilePaths: List<String>.unmodifiable(current.approvedFilePaths),
      backupId: backup.backupId,
      deploymentAttempted: current.deploymentAttempted,
      deploymentSucceeded: current.deploymentSucceeded,
      ownerKeepConfirmed: false,
      rollbackRequested: true,
      rollbackCompleted: false,
      createdAt: current.createdAt,
      deployedAt: current.deployedAt,
      decidedAt: decidedAt ?? DateTime.now(),
    );

    next.validate();
    return next;
  }

  Future<AgentWebsiteDeploymentHistory> executeRequestedRollback({
    required AgentWebsiteDeploymentHistory current,
    required AgentCodeBackupManifest backup,
    DateTime? completedAt,
  }) async {
    current.validate();

    if (!current.needsRollback) {
      throw const AgentWebsiteKeepRollbackException(
        'Rollback execution requires an existing ROLLBACK_REQUESTED state.',
      );
    }

    _validateBackupMatch(current: current, backup: backup);

    // Existing AgentCodeBackupService itself also fails closed
    // when the backup is incomplete.
    await backupService.restore(backup);

    final next = AgentWebsiteDeploymentHistory(
      deploymentId: current.deploymentId,
      changeId: current.changeId,
      approvalId: current.approvalId,
      target: current.target,
      decision: AgentWebsiteDeploymentDecision.rolledBack,
      approvedFilePaths: List<String>.unmodifiable(current.approvedFilePaths),
      backupId: backup.backupId,
      deploymentAttempted: current.deploymentAttempted,
      deploymentSucceeded: current.deploymentSucceeded,
      ownerKeepConfirmed: false,
      rollbackRequested: true,
      rollbackCompleted: true,
      createdAt: current.createdAt,
      deployedAt: current.deployedAt,
      decidedAt: completedAt ?? DateTime.now(),
    );

    next.validate();
    return next;
  }

  void _validateBackupMatch({
    required AgentWebsiteDeploymentHistory current,
    required AgentCodeBackupManifest backup,
  }) {
    if (!backup.isComplete) {
      throw const AgentWebsiteKeepRollbackException(
        'Rollback blocked because backup is incomplete.',
      );
    }

    if (backup.changeId != current.changeId) {
      throw const AgentWebsiteKeepRollbackException(
        'Backup changeId does not match deployment changeId.',
      );
    }

    if (current.backupId != null && current.backupId != backup.backupId) {
      throw const AgentWebsiteKeepRollbackException(
        'Backup identity does not match deployment history.',
      );
    }

    final deploymentScope = current.approvedFilePaths
        .map((path) => path.trim().replaceAll(r'\', '/'))
        .toSet();

    final backupScope = backup.entries
        .map((entry) => entry.filePath.trim().replaceAll(r'\', '/'))
        .toSet();

    if (deploymentScope.length != current.approvedFilePaths.length ||
        backupScope.length != backup.entries.length ||
        deploymentScope.length != backupScope.length ||
        !deploymentScope.containsAll(backupScope) ||
        !backupScope.containsAll(deploymentScope)) {
      throw const AgentWebsiteKeepRollbackException(
        'Backup file scope does not exactly match deployed approved scope.',
      );
    }
  }
}

class AgentWebsiteKeepRollbackException implements Exception {
  final String message;

  const AgentWebsiteKeepRollbackException(this.message);

  @override
  String toString() => 'AgentWebsiteKeepRollbackException: $message';
}
