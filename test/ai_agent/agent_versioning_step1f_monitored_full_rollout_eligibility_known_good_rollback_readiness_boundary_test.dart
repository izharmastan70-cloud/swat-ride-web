import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_version_full_rollout_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_versioning_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_version_full_rollout_owner_approval.dart';
import 'package:swat_ride/ai_agent/models/agent_version_known_good_rollback_readiness.dart';
import 'package:swat_ride/ai_agent/models/agent_version_monitored_evidence_summary.dart';
import 'package:swat_ride/ai_agent/models/agent_version_record.dart';
import 'package:swat_ride/ai_agent/services/agent_version_full_rollout_eligibility_policy.dart';
import 'package:swat_ride/ai_agent/services/agent_version_known_good_rollback_readiness_policy.dart';

void main() {
  const AgentVersionKnownGoodRollbackReadinessPolicy rollbackPolicy =
      AgentVersionKnownGoodRollbackReadinessPolicy();

  const AgentVersionFullRolloutEligibilityPolicy fullPolicy =
      AgentVersionFullRolloutEligibilityPolicy();

  const String artifactSha =
      '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

  const String previousArtifactSha =
      '1111111111111111111111111111111111111111111111111111111111111111';

  const String rolloutScopeSha =
      'abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789';

  const String monitoringSummarySha =
      '2222222222222222222222222222222222222222222222222222222222222222';

  const String rollbackReadinessSha =
      '3333333333333333333333333333333333333333333333333333333333333333';

  final DateTime evaluatedAtUtc = DateTime.utc(2026, 8, 24, 2, 0);

  AgentVersionRecord monitoredVersion({
    String status = AgentVersionLifecycleStatus.monitored,
    String? previousVersionId = 'ride_agent:v1.0.0',
  }) {
    return AgentVersionRecord(
      contractVersion: AgentVersionContract.contractVersion,
      versionId: 'ride_agent:v1.1.0',
      agentId: 'ride_agent',
      semanticVersion: '1.1.0',
      previousVersionId: previousVersionId,
      changeType: AgentVersionChangeType.behaviorPrompt,
      changeRisk: AgentVersionChangeRisk.high,
      changeCode: 'improve_booking_clarification',
      artifactFingerprintSha256: artifactSha,
      status: status,
      proposedAtUtc: DateTime.utc(2026, 8, 24, 0, 0),
      evaluationRunId: 'phase62:eval:ride_agent:v1.1.0',
    );
  }

  AgentVersionMonitoredEvidenceSummary monitoring({
    int healthyWindows = 3,
    int completedObservations = 100,
    int rollbackRequests = 0,
    int holdWindows = 0,
    int outstandingAlerts = 0,
    bool monitoringHealthy = true,
    bool coreIsolation = true,
    DateTime? completedAtUtc,
  }) {
    return AgentVersionMonitoredEvidenceSummary(
      summaryId: 'phase62:monitoring:ride_agent:v1.1.0',
      summaryFingerprintSha256: monitoringSummarySha,
      versionId: 'ride_agent:v1.1.0',
      agentId: 'ride_agent',
      artifactFingerprintSha256: artifactSha,
      rolloutId: 'phase62:rollout:ride_agent:v1.1.0',
      rolloutScopeSha256: rolloutScopeSha,
      limitedRolloutPercent: 5,
      healthyWindowCount: healthyWindows,
      totalCompletedObservationCount: completedObservations,
      rollbackRequestCount: rollbackRequests,
      holdWindowCount: holdWindows,
      outstandingOwnerAlertCount: outstandingAlerts,
      monitoringPipelineHealthy: monitoringHealthy,
      coreAppIsolationVerified: coreIsolation,
      completedAtUtc: completedAtUtc ?? DateTime.utc(2026, 8, 24, 1, 50),
    );
  }

  AgentVersionKnownGoodRollbackReadiness rollbackReadiness({
    String rollbackTargetVersionId = 'ride_agent:v1.0.0',
    bool backupVerified = true,
    bool restoreValidationPassed = true,
    bool securityBoundaryVerified = true,
    bool coreIsolation = true,
    String backupScopeSha256 = rolloutScopeSha,
    String expectedScopeSha256 = rolloutScopeSha,
    DateTime? verifiedAtUtc,
  }) {
    return AgentVersionKnownGoodRollbackReadiness(
      readinessId: 'phase62:rollbackready:ride_agent:v1.1.0',
      readinessFingerprintSha256: rollbackReadinessSha,
      currentVersionId: 'ride_agent:v1.1.0',
      rollbackTargetVersionId: rollbackTargetVersionId,
      rollbackTargetArtifactFingerprintSha256: previousArtifactSha,
      backupManifestId: 'backup:ride_agent:v1.0.0',
      backupScopeSha256: backupScopeSha256,
      expectedRollbackScopeSha256: expectedScopeSha256,
      backupVerified: backupVerified,
      restoreValidationPassed: restoreValidationPassed,
      securityBoundaryVerified: securityBoundaryVerified,
      coreAppIsolationVerified: coreIsolation,
      verifiedAtUtc: verifiedAtUtc ?? DateTime.utc(2026, 8, 24, 1, 30),
    );
  }

  AgentVersionFullRolloutOwnerApproval fullApproval({
    String approvalId = 'owner:full:ride_agent:v1.1.0',
    String limitedApprovalId = 'owner:limited:ride_agent:v1.1.0',
    String monitoringSha = monitoringSummarySha,
    String rollbackSha = rollbackReadinessSha,
    DateTime? approvedAtUtc,
    DateTime? expiresAtUtc,
  }) {
    final DateTime approved = approvedAtUtc ?? DateTime.utc(2026, 8, 24, 1, 55);

    return AgentVersionFullRolloutOwnerApproval(
      approvalId: approvalId,
      limitedRolloutApprovalId: limitedApprovalId,
      versionId: 'ride_agent:v1.1.0',
      agentId: 'ride_agent',
      artifactFingerprintSha256: artifactSha,
      monitoringSummaryFingerprintSha256: monitoringSha,
      rollbackReadinessFingerprintSha256: rollbackSha,
      approvedByRole: 'OWNER',
      approvedAtUtc: approved,
      expiresAtUtc: expiresAtUtc ?? approved.add(const Duration(minutes: 20)),
    );
  }

  group('Phase 62 Step 1F monitored evidence', () {
    test('clean multi-window monitoring is sufficient', () {
      final value = monitoring();

      expect(value.sufficientEvidence, true);
      expect(value.cleanForFullRolloutEligibility, true);
      expect(value.healthyWindowCount, 3);
      expect(value.totalCompletedObservationCount, 100);
    });

    test('fewer than 3 healthy windows is insufficient', () {
      expect(
        monitoring(healthyWindows: 2).cleanForFullRolloutEligibility,
        false,
      );
    });

    test('fewer than 100 observations is insufficient', () {
      expect(
        monitoring(completedObservations: 99).cleanForFullRolloutEligibility,
        false,
      );
    });

    test('rollback request or hold prevents clean monitoring', () {
      expect(
        monitoring(rollbackRequests: 1).cleanForFullRolloutEligibility,
        false,
      );
      expect(monitoring(holdWindows: 1).cleanForFullRolloutEligibility, false);
    });

    test('outstanding Owner alert prevents clean monitoring', () {
      expect(
        monitoring(outstandingAlerts: 1).cleanForFullRolloutEligibility,
        false,
      );
    });

    test('monitoring summary stores no raw/private authority payload', () {
      final value = monitoring();

      expect(value.metadataOnly, true);
      expect(value.rawPromptStored, false);
      expect(value.rawConversationStored, false);
      expect(value.privatePayloadStored, false);
      expect(value.secretsStored, false);
      expect(value.tokensStored, false);
      expect(value.productionActivationPerformed, false);
      expect(value.autoModeAuthorized, false);
    });
  });

  group('Phase 62 Step 1F known-good rollback readiness', () {
    test('exact previous version + verified backup metadata is ready', () {
      final decision = rollbackPolicy.evaluate(
        currentVersion: monitoredVersion(),
        readiness: rollbackReadiness(),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(decision.ready, true);
      expect(
        decision.status,
        AgentVersionKnownGoodRollbackReadinessStatus.ready,
      );
    });

    test('missing previous version fails closed', () {
      final decision = rollbackPolicy.evaluate(
        currentVersion: monitoredVersion(previousVersionId: null),
        readiness: rollbackReadiness(),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(decision.ready, false);
      expect(
        decision.status,
        AgentVersionKnownGoodRollbackReadinessStatus.blockedNoPreviousVersion,
      );
    });

    test('wrong rollback target is blocked', () {
      final decision = rollbackPolicy.evaluate(
        currentVersion: monitoredVersion(),
        readiness: rollbackReadiness(
          rollbackTargetVersionId: 'ride_agent:v0.9.0',
        ),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(
        decision.status,
        AgentVersionKnownGoodRollbackReadinessStatus.blockedTargetMismatch,
      );
    });

    test('unverified backup or failed restore validation is blocked', () {
      final unverified = rollbackPolicy.evaluate(
        currentVersion: monitoredVersion(),
        readiness: rollbackReadiness(backupVerified: false),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(
        unverified.status,
        AgentVersionKnownGoodRollbackReadinessStatus.blockedBackupUnverified,
      );

      final restoreFailed = rollbackPolicy.evaluate(
        currentVersion: monitoredVersion(),
        readiness: rollbackReadiness(restoreValidationPassed: false),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(
        restoreFailed.status,
        AgentVersionKnownGoodRollbackReadinessStatus.blockedRestoreValidation,
      );
    });

    test('backup scope mismatch is blocked', () {
      const String wrongScope =
          'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff';

      final decision = rollbackPolicy.evaluate(
        currentVersion: monitoredVersion(),
        readiness: rollbackReadiness(backupScopeSha256: wrongScope),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(
        decision.status,
        AgentVersionKnownGoodRollbackReadinessStatus.blockedScopeMismatch,
      );
    });

    test('readiness metadata never executes restore', () {
      final value = rollbackReadiness();

      expect(value.metadataOnly, true);
      expect(value.rawBackupContentsStored, false);
      expect(value.exactBackupRestorePerformed, false);
      expect(value.rollbackExecutionPerformed, false);
      expect(value.automaticRollbackPerformed, false);
      expect(value.productionActivationPerformed, false);
    });
  });

  group('Phase 62 Step 1F separate Owner full-rollout approval', () {
    test('full approval is separate from limited approval', () {
      final approval = fullApproval();

      expect(approval.explicitOwnerApproval, true);
      expect(approval.separateFromLimitedRolloutApproval, true);
      expect(approval.approvalEngineConsumptionPerformed, false);
      expect(approval.phase66ProductionActivationAuthorized, false);
      expect(approval.autoModeAuthorized, false);
    });

    test('limited approval ID cannot be reused as full approval ID', () {
      expect(
        () => fullApproval(
          approvalId: 'owner:same:ride_agent:v1.1.0',
          limitedApprovalId: 'owner:same:ride_agent:v1.1.0',
        ),
        throwsFormatException,
      );
    });

    test('full approval validity cannot exceed 30 minutes', () {
      final DateTime approved = DateTime.utc(2026, 8, 24, 1, 0);

      expect(
        () => fullApproval(
          approvedAtUtc: approved,
          expiresAtUtc: approved.add(const Duration(minutes: 31)),
        ),
        throwsFormatException,
      );
    });
  });

  group('Phase 62 Step 1F full-rollout eligibility', () {
    test('clean monitored version becomes eligible, not active', () {
      final result = fullPolicy.evaluate(
        version: monitoredVersion(),
        monitoring: monitoring(),
        rollbackReadiness: rollbackReadiness(),
        ownerApproval: fullApproval(),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(result.eligible, true);
      expect(result.eligibleForLifecycleFullRolloutEligible, true);
      expect(result.foundationReadyNotProductionActive, true);
      expect(result.phase66Required, true);
      expect(result.productionActivationPerformed, false);
      expect(result.autoModeAuthorized, false);
      expect(result.fullSafeAutoAuthorized, false);
    });

    test('version must already be MONITORED', () {
      final result = fullPolicy.evaluate(
        version: monitoredVersion(
          status: AgentVersionLifecycleStatus.testReady,
        ),
        monitoring: monitoring(),
        rollbackReadiness: rollbackReadiness(),
        ownerApproval: fullApproval(),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(
        result.status,
        AgentVersionFullRolloutEligibilityStatus.blockedVersionStatus,
      );
    });

    test('unclean monitoring blocks full rollout eligibility', () {
      final result = fullPolicy.evaluate(
        version: monitoredVersion(),
        monitoring: monitoring(rollbackRequests: 1),
        rollbackReadiness: rollbackReadiness(),
        ownerApproval: fullApproval(),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(
        result.status,
        AgentVersionFullRolloutEligibilityStatus.blockedMonitoring,
      );
    });

    test('stale monitoring summary blocks eligibility', () {
      final result = fullPolicy.evaluate(
        version: monitoredVersion(),
        monitoring: monitoring(
          completedAtUtc: evaluatedAtUtc.subtract(const Duration(minutes: 31)),
        ),
        rollbackReadiness: rollbackReadiness(),
        ownerApproval: fullApproval(),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(
        result.status,
        AgentVersionFullRolloutEligibilityStatus.blockedMonitoring,
      );
    });

    test('bad rollback readiness blocks eligibility', () {
      final result = fullPolicy.evaluate(
        version: monitoredVersion(),
        monitoring: monitoring(),
        rollbackReadiness: rollbackReadiness(backupVerified: false),
        ownerApproval: fullApproval(),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(
        result.status,
        AgentVersionFullRolloutEligibilityStatus.blockedRollbackReadiness,
      );
    });

    test('approval must bind exact monitoring and rollback fingerprints', () {
      const String wrongSha =
          'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff';

      final result = fullPolicy.evaluate(
        version: monitoredVersion(),
        monitoring: monitoring(),
        rollbackReadiness: rollbackReadiness(),
        ownerApproval: fullApproval(monitoringSha: wrongSha),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(
        result.status,
        AgentVersionFullRolloutEligibilityStatus.blockedOwnerApproval,
      );
    });

    test('expired full Owner approval blocks eligibility', () {
      final DateTime approved = DateTime.utc(2026, 8, 24, 1, 0);

      final result = fullPolicy.evaluate(
        version: monitoredVersion(),
        monitoring: monitoring(),
        rollbackReadiness: rollbackReadiness(),
        ownerApproval: fullApproval(
          approvedAtUtc: approved,
          expiresAtUtc: approved.add(const Duration(minutes: 20)),
        ),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(
        result.status,
        AgentVersionFullRolloutEligibilityStatus.blockedApprovalExpired,
      );
    });
  });

  group('Phase 62 Step 1F no production/runtime authority', () {
    test('rollback readiness policy executes nothing', () {
      expect(rollbackPolicy.executesRestore, false);
      expect(rollbackPolicy.executesRollback, false);
      expect(rollbackPolicy.persistsReadiness, false);
      expect(rollbackPolicy.deploysVersion, false);
      expect(rollbackPolicy.activatesProduction, false);
      expect(rollbackPolicy.routesTraffic, false);
      expect(rollbackPolicy.consumesApproval, false);
      expect(rollbackPolicy.grantsPermission, false);
      expect(rollbackPolicy.writesBusinessData, false);
    });

    test('full rollout policy cannot bypass Phase 66 or runtime gates', () {
      expect(fullPolicy.phase66Required, true);
      expect(fullPolicy.persistsEligibility, false);
      expect(fullPolicy.transitionsLifecycle, false);
      expect(fullPolicy.routesTraffic, false);
      expect(fullPolicy.deploysVersion, false);
      expect(fullPolicy.activatesProduction, false);
      expect(fullPolicy.authorizesAutoMode, false);
      expect(fullPolicy.authorizesFullSafeAuto, false);
      expect(fullPolicy.consumesApprovalEngineApproval, false);
      expect(fullPolicy.grantsPermission, false);
      expect(fullPolicy.overridesRuntimeGate, false);
      expect(fullPolicy.overridesSecurity, false);
      expect(fullPolicy.automaticKeepAllowed, false);
      expect(fullPolicy.automaticRollbackAllowed, false);
      expect(fullPolicy.writesBusinessData, false);
    });
  });
}
