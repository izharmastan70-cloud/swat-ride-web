import '../constants/agent_version_full_rollout_constants.dart';
import '../models/agent_version_known_good_rollback_readiness.dart';
import '../models/agent_version_record.dart';

class AgentVersionKnownGoodRollbackReadinessPolicy {
  const AgentVersionKnownGoodRollbackReadinessPolicy();

  AgentVersionKnownGoodRollbackReadinessDecision evaluate({
    required AgentVersionRecord currentVersion,
    required AgentVersionKnownGoodRollbackReadiness readiness,
    required DateTime evaluatedAtUtc,
  }) {
    try {
      currentVersion.validate();
      readiness.validate();

      if (!evaluatedAtUtc.isUtc) {
        throw const FormatException('Evaluation time must be UTC.');
      }
    } catch (_) {
      return const AgentVersionKnownGoodRollbackReadinessDecision(
        status:
            AgentVersionKnownGoodRollbackReadinessStatus.blockedInvalidInput,
        reasonCode: 'invalid_known_good_readiness',
      );
    }

    final String? previous = currentVersion.previousVersionId;

    if (previous == null || previous.trim().isEmpty) {
      return const AgentVersionKnownGoodRollbackReadinessDecision(
        status: AgentVersionKnownGoodRollbackReadinessStatus
            .blockedNoPreviousVersion,
        reasonCode: 'previous_known_good_version_missing',
      );
    }

    if (readiness.currentVersionId != currentVersion.versionId ||
        readiness.rollbackTargetVersionId != previous) {
      return const AgentVersionKnownGoodRollbackReadinessDecision(
        status:
            AgentVersionKnownGoodRollbackReadinessStatus.blockedTargetMismatch,
        reasonCode: 'rollback_target_identity_mismatch',
      );
    }

    if (readiness.verifiedAtUtc.isAfter(
      evaluatedAtUtc.add(AgentVersionFullRolloutPolicy.maximumFutureClockSkew),
    )) {
      return const AgentVersionKnownGoodRollbackReadinessDecision(
        status: AgentVersionKnownGoodRollbackReadinessStatus.blockedClockSkew,
        reasonCode: 'rollback_readiness_clock_skew',
      );
    }

    if (evaluatedAtUtc.difference(readiness.verifiedAtUtc) >
        AgentVersionFullRolloutPolicy.maximumRollbackReadinessAge) {
      return const AgentVersionKnownGoodRollbackReadinessDecision(
        status: AgentVersionKnownGoodRollbackReadinessStatus.blockedStale,
        reasonCode: 'rollback_readiness_stale',
      );
    }

    if (!readiness.backupVerified) {
      return const AgentVersionKnownGoodRollbackReadinessDecision(
        status: AgentVersionKnownGoodRollbackReadinessStatus
            .blockedBackupUnverified,
        reasonCode: 'rollback_backup_not_verified',
      );
    }

    if (!readiness.restoreValidationPassed ||
        !readiness.securityBoundaryVerified) {
      return const AgentVersionKnownGoodRollbackReadinessDecision(
        status: AgentVersionKnownGoodRollbackReadinessStatus
            .blockedRestoreValidation,
        reasonCode: 'rollback_restore_validation_failed',
      );
    }

    if (!readiness.exactScopeMatched) {
      return const AgentVersionKnownGoodRollbackReadinessDecision(
        status:
            AgentVersionKnownGoodRollbackReadinessStatus.blockedScopeMismatch,
        reasonCode: 'rollback_backup_scope_mismatch',
      );
    }

    if (!readiness.coreAppIsolationVerified) {
      return const AgentVersionKnownGoodRollbackReadinessDecision(
        status:
            AgentVersionKnownGoodRollbackReadinessStatus.blockedCoreIsolation,
        reasonCode: 'rollback_core_app_isolation_failed',
      );
    }

    return const AgentVersionKnownGoodRollbackReadinessDecision(
      status: AgentVersionKnownGoodRollbackReadinessStatus.ready,
      reasonCode: 'known_good_rollback_ready_not_executed',
    );
  }

  bool get executesRestore => false;
  bool get executesRollback => false;
  bool get persistsReadiness => false;
  bool get deploysVersion => false;
  bool get activatesProduction => false;
  bool get routesTraffic => false;
  bool get consumesApproval => false;
  bool get grantsPermission => false;
  bool get writesBusinessData => false;
}
