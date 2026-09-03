import '../constants/agent_future_proposal_constants.dart';
import '../models/agent_code_backup_manifest.dart';
import '../models/agent_code_test_result.dart';
import '../models/agent_future_proposal.dart';
import '../models/agent_future_quality_lifecycle.dart';
import '../models/agent_security_finding.dart';
import 'agent_code_change_coordinator.dart';
import 'agent_future_quality_lifecycle_repository.dart';
import 'agent_future_quality_lifecycle_service.dart';

/// Phase 41 quality + explicit Owner decision coordinator.
///
/// Safety:
/// - KEEP requires the G1/G2A strict QA + Security lifecycle.
/// - ROLLBACK first persists ROLLBACK_REQUESTED.
/// - Raw source backup content is not persisted in Firestore here.
/// - The existing Code Agent apply result retains the exact in-memory backup.
/// - ROLLED_BACK is persisted only after exact backup restoration succeeds.
/// - No provider, Paid AI, deployment or unrestricted shell API exists here.
class AgentFutureQualityWorkflowCoordinator {
  AgentFutureQualityWorkflowCoordinator({
    AgentFutureQualityLifecycleRepository? repository,
    AgentFutureQualityLifecycleService? lifecycleService,
    AgentCodeChangeCoordinator? codeChangeCoordinator,
  }) : repository = repository ?? AgentFutureQualityLifecycleRepository(),
       lifecycleService =
           lifecycleService ?? const AgentFutureQualityLifecycleService(),
       codeChangeCoordinator =
           codeChangeCoordinator ?? AgentCodeChangeCoordinator();

  final AgentFutureQualityLifecycleRepository repository;
  final AgentFutureQualityLifecycleService lifecycleService;
  final AgentCodeChangeCoordinator codeChangeCoordinator;

  Future<AgentFutureQualityLifecycle> beginQa({
    required AgentFutureProposal proposal,
    required String actorId,
  }) async {
    final AgentFutureQualityLifecycle next = lifecycleService.beginQa(
      proposal: proposal,
    );

    await repository.saveTransition(
      lifecycle: next,
      expectedPreviousUpdatedAt: null,
      actorId: _identity(actorId, 'actorId'),
    );

    return next;
  }

  Future<AgentFutureQualityLifecycle> recordQa({
    required String proposalId,
    required String codeChangeId,
    required String backupId,
    required String reviewerId,
    required AgentCodeTestResult testResult,
  }) async {
    final AgentFutureQualityLifecycle current = await _requiredLifecycle(
      proposalId,
    );

    final AgentFutureQualityLifecycle next = lifecycleService.recordQa(
      lifecycle: current,
      codeChangeId: codeChangeId,
      backupId: backupId,
      reviewerId: reviewerId,
      testResult: testResult,
    );

    await repository.saveTransition(
      lifecycle: next,
      expectedPreviousUpdatedAt: current.updatedAt,
      actorId: _identity(reviewerId, 'reviewerId'),
    );

    return next;
  }

  Future<AgentFutureQualityLifecycle> beginSecurity({
    required String proposalId,
    required String actorId,
  }) async {
    final AgentFutureQualityLifecycle current = await _requiredLifecycle(
      proposalId,
    );

    final AgentFutureQualityLifecycle next = lifecycleService.beginSecurity(
      lifecycle: current,
    );

    await repository.saveTransition(
      lifecycle: next,
      expectedPreviousUpdatedAt: current.updatedAt,
      actorId: _identity(actorId, 'actorId'),
    );

    return next;
  }

  Future<AgentFutureQualityLifecycle> recordSecurity({
    required String proposalId,
    required String reviewerId,
    required bool reviewCompleted,
    required List<AgentSecurityFinding> findings,
  }) async {
    final AgentFutureQualityLifecycle current = await _requiredLifecycle(
      proposalId,
    );

    final AgentFutureQualityLifecycle next = lifecycleService.recordSecurity(
      lifecycle: current,
      reviewerId: reviewerId,
      reviewCompleted: reviewCompleted,
      findings: findings,
    );

    await repository.saveTransition(
      lifecycle: next,
      expectedPreviousUpdatedAt: current.updatedAt,
      actorId: _identity(reviewerId, 'reviewerId'),
    );

    return next;
  }

  Future<AgentFutureQualityLifecycle> requestOwnerDecision({
    required String proposalId,
    required String actorId,
  }) async {
    final AgentFutureQualityLifecycle current = await _requiredLifecycle(
      proposalId,
    );

    final AgentFutureQualityLifecycle next = lifecycleService
        .requestOwnerDecision(lifecycle: current);

    await repository.saveTransition(
      lifecycle: next,
      expectedPreviousUpdatedAt: current.updatedAt,
      actorId: _identity(actorId, 'actorId'),
    );

    return next;
  }

  Future<AgentFutureQualityLifecycle> ownerKeep({
    required String proposalId,
    required String ownerId,
    required String note,
  }) async {
    final AgentFutureQualityLifecycle current = await _requiredLifecycle(
      proposalId,
    );

    final AgentFutureQualityLifecycle next = lifecycleService.ownerKeep(
      lifecycle: current,
      ownerId: _identity(ownerId, 'ownerId'),
      note: _note(note),
    );

    await repository.saveTransition(
      lifecycle: next,
      expectedPreviousUpdatedAt: current.updatedAt,
      actorId: ownerId.trim(),
    );

    return next;
  }

  /// Persists explicit Owner rollback intent only.
  /// It never marks ROLLED_BACK and never restores code by itself.
  Future<AgentFutureQualityLifecycle> ownerRollbackRequest({
    required String proposalId,
    required String ownerId,
    required String note,
  }) async {
    final AgentFutureQualityLifecycle current = await _requiredLifecycle(
      proposalId,
    );

    final AgentFutureQualityLifecycle next = lifecycleService
        .ownerRollbackDecision(
          lifecycle: current,
          ownerId: _identity(ownerId, 'ownerId'),
          note: _note(note),
        );

    if (next.status != AgentFutureProposalStatus.rollbackRequested) {
      throw const AgentFutureQualityWorkflowException(
        'ROLLBACK must enter ROLLBACK_REQUESTED before restoration.',
      );
    }

    await repository.saveTransition(
      lifecycle: next,
      expectedPreviousUpdatedAt: current.updatedAt,
      actorId: ownerId.trim(),
    );

    return next;
  }

  /// Preferred runtime completion path: use the exact backup retained by the
  /// Code Agent apply result from the same code-change session.
  Future<AgentFutureQualityLifecycle> executeRequestedRollbackFromApplyResult({
    required String proposalId,
    required AgentCodeApplyResult applyResult,
    required String actorId,
  }) async {
    final AgentCodeBackupManifest? backup = applyResult.backup;

    if (backup == null) {
      throw const AgentFutureQualityWorkflowException(
        'Rollback blocked because the Code Agent apply result has no backup.',
      );
    }

    return executeRequestedRollback(
      proposalId: proposalId,
      backup: backup,
      actorId: actorId,
    );
  }

  /// Controlled restoration path.
  ///
  /// If restore fails/throws, execution stops before completeRollback() and
  /// ROLLED_BACK is never persisted.
  Future<AgentFutureQualityLifecycle> executeRequestedRollback({
    required String proposalId,
    required AgentCodeBackupManifest backup,
    required String actorId,
  }) async {
    final AgentFutureQualityLifecycle current = await _requiredLifecycle(
      proposalId,
    );

    if (current.status != AgentFutureProposalStatus.rollbackRequested ||
        current.ownerDecision != AgentFutureOwnerDecision.rollback) {
      throw const AgentFutureQualityWorkflowException(
        'Rollback execution requires ROLLBACK_REQUESTED Owner state.',
      );
    }

    final AgentFutureQaEvidence? qa = current.qaEvidence;

    if (qa == null) {
      throw const AgentFutureQualityWorkflowException(
        'Rollback blocked because QA/code-change backup evidence is missing.',
      );
    }

    if (!backup.isComplete) {
      throw const AgentFutureQualityWorkflowException(
        'Rollback blocked because backup is incomplete.',
      );
    }

    if (backup.backupId.trim() != qa.backupId.trim() ||
        backup.changeId.trim() != qa.codeChangeId.trim()) {
      throw const AgentFutureQualityWorkflowException(
        'Rollback backup does not match QA/code-change evidence.',
      );
    }

    final String normalizedActor = _identity(actorId, 'actorId');

    await codeChangeCoordinator.rollback(backup);

    final AgentFutureQualityLifecycle completed = lifecycleService
        .completeRollback(lifecycle: current, rollbackPerformed: true);

    await repository.saveTransition(
      lifecycle: completed,
      expectedPreviousUpdatedAt: current.updatedAt,
      actorId: normalizedActor,
    );

    return completed;
  }

  Future<AgentFutureQualityLifecycle> _requiredLifecycle(
    String proposalId,
  ) async {
    final String normalized = proposalId.trim();

    if (normalized.isEmpty) {
      throw const AgentFutureQualityWorkflowException(
        'proposalId cannot be empty.',
      );
    }

    final AgentFutureQualityLifecycle? lifecycle = await repository
        .getLifecycle(normalized);

    if (lifecycle == null) {
      throw const AgentFutureQualityWorkflowException(
        'Future quality lifecycle was not found.',
      );
    }

    lifecycle.validate();
    return lifecycle;
  }

  String _identity(String value, String fieldName) {
    final String normalized = value.trim();

    if (normalized.isEmpty) {
      throw AgentFutureQualityWorkflowException('$fieldName cannot be empty.');
    }

    return normalized;
  }

  String _note(String value) {
    final String normalized = value.trim();

    if (normalized.isEmpty) {
      throw const AgentFutureQualityWorkflowException(
        'Owner decision note cannot be empty.',
      );
    }

    return normalized;
  }
}

class AgentFutureQualityWorkflowException implements Exception {
  const AgentFutureQualityWorkflowException(this.message);

  final String message;

  @override
  String toString() => 'AgentFutureQualityWorkflowException: $message';
}
