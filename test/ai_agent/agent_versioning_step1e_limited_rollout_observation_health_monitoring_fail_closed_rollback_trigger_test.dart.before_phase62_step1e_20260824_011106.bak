import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_version_monitoring_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_version_rollout_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_versioning_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_version_limited_rollout_eligibility.dart';
import 'package:swat_ride/ai_agent/models/agent_version_limited_rollout_observation.dart';
import 'package:swat_ride/ai_agent/models/agent_version_limited_rollout_plan.dart';
import 'package:swat_ride/ai_agent/models/agent_version_record.dart';
import 'package:swat_ride/ai_agent/services/agent_version_rollback_trigger_policy.dart';
import 'package:swat_ride/ai_agent/services/agent_version_rollout_health_monitoring_policy.dart';

void main() {
  const AgentVersionRolloutHealthMonitoringPolicy healthPolicy =
      AgentVersionRolloutHealthMonitoringPolicy();

  const AgentVersionRollbackTriggerPolicy rollbackPolicy =
      AgentVersionRollbackTriggerPolicy();

  const String artifactSha =
      '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

  const String scopeSha =
      'abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789';

  final DateTime evaluatedAtUtc = DateTime.utc(2026, 8, 24, 1, 30);

  AgentVersionRecord version({
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
      status: AgentVersionLifecycleStatus.testReady,
      proposedAtUtc: DateTime.utc(2026, 8, 24, 0, 0),
      evaluationRunId: 'phase62:eval:ride_agent:v1.1.0',
    );
  }

  AgentVersionLimitedRolloutPlan plan({double requestedPercent = 5}) {
    return AgentVersionLimitedRolloutPlan(
      rolloutId: 'phase62:rollout:ride_agent:v1.1.0',
      versionId: 'ride_agent:v1.1.0',
      agentId: 'ride_agent',
      artifactFingerprintSha256: artifactSha,
      rolloutScopeSha256: scopeSha,
      cohortId: 'limited_cohort_v1',
      requestedPercent: requestedPercent,
    );
  }

  AgentVersionLimitedRolloutEligibility eligibility({
    String status = AgentVersionLimitedRolloutEligibilityStatus.eligible,
  }) {
    return AgentVersionLimitedRolloutEligibility(
      status: status,
      versionId: 'ride_agent:v1.1.0',
      rolloutId: 'phase62:rollout:ride_agent:v1.1.0',
      requestedPercent: 5,
      reasonCode: status == AgentVersionLimitedRolloutEligibilityStatus.eligible
          ? 'limited_rollout_eligible_not_executed'
          : 'blocked',
    );
  }

  AgentVersionLimitedRolloutObservation observation({
    int completed = 20,
    int successful = 20,
    int failed = 0,
    int criticalCrashes = 0,
    bool regressionDetected = false,
    int safety = 0,
    int privacy = 0,
    int security = 0,
    int permission = 0,
    int approvalBypass = 0,
    int businessWrite = 0,
    bool coreIsolation = true,
    bool monitoringHealthy = true,
    DateTime? completedAtUtc,
    String rolloutScopeSha256 = scopeSha,
    double rolloutPercent = 5,
  }) {
    final DateTime completedAt =
        completedAtUtc ?? DateTime.utc(2026, 8, 24, 1, 25);

    return AgentVersionLimitedRolloutObservation(
      observationId: 'phase62:obs:ride_agent:v1.1.0:001',
      rolloutId: 'phase62:rollout:ride_agent:v1.1.0',
      versionId: 'ride_agent:v1.1.0',
      agentId: 'ride_agent',
      artifactFingerprintSha256: artifactSha,
      rolloutScopeSha256: rolloutScopeSha256,
      rolloutPercent: rolloutPercent,
      completedObservationCount: completed,
      successfulObservationCount: successful,
      failedObservationCount: failed,
      criticalCrashCount: criticalCrashes,
      regressionDetected: regressionDetected,
      safetyViolationCount: safety,
      privacyViolationCount: privacy,
      securityViolationCount: security,
      permissionViolationCount: permission,
      approvalBypassCount: approvalBypass,
      businessWriteViolationCount: businessWrite,
      coreAppIsolationVerified: coreIsolation,
      monitoringPipelineHealthy: monitoringHealthy,
      windowStartedAtUtc: completedAt.subtract(const Duration(minutes: 10)),
      windowCompletedAtUtc: completedAt,
    );
  }

  group('Phase 62 Step 1E monitoring evidence', () {
    test('clean 20-sample observation is healthy', () {
      final result = healthPolicy.evaluate(
        version: version(),
        eligibility: eligibility(),
        plan: plan(),
        observation: observation(),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(result.healthy, true);
      expect(result.eligibleForMonitoredLifecycle, true);
      expect(result.ownerAlertRequired, false);
      expect(result.lifecycleTransitionPerformed, false);
    });

    test('insufficient sample holds instead of inventing health', () {
      final result = healthPolicy.evaluate(
        version: version(),
        eligibility: eligibility(),
        plan: plan(),
        observation: observation(completed: 19, successful: 19),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(result.healthy, false);
      expect(
        result.status,
        AgentVersionRolloutHealthStatus.holdInsufficientEvidence,
      );
    });

    test('stale monitoring evidence is held', () {
      final result = healthPolicy.evaluate(
        version: version(),
        eligibility: eligibility(),
        plan: plan(),
        observation: observation(
          completedAtUtc: evaluatedAtUtc.subtract(const Duration(minutes: 16)),
        ),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(result.status, AgentVersionRolloutHealthStatus.holdStaleEvidence);
    });

    test('future clock skew beyond 5 minutes is held', () {
      final result = healthPolicy.evaluate(
        version: version(),
        eligibility: eligibility(),
        plan: plan(),
        observation: observation(
          completedAtUtc: evaluatedAtUtc.add(const Duration(minutes: 6)),
        ),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(result.status, AgentVersionRolloutHealthStatus.holdClockSkew);
    });

    test('rollout scope mismatch is held', () {
      const String wrongScope =
          'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff';

      final result = healthPolicy.evaluate(
        version: version(),
        eligibility: eligibility(),
        plan: plan(),
        observation: observation(rolloutScopeSha256: wrongScope),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(
        result.status,
        AgentVersionRolloutHealthStatus.holdIdentityMismatch,
      );
    });

    test(
      'unhealthy monitoring pipeline holds and requires Owner attention',
      () {
        final result = healthPolicy.evaluate(
          version: version(),
          eligibility: eligibility(),
          plan: plan(),
          observation: observation(monitoringHealthy: false),
          evaluatedAtUtc: evaluatedAtUtc,
        );

        expect(
          result.status,
          AgentVersionRolloutHealthStatus.holdInsufficientEvidence,
        );
        expect(result.ownerAlertRequired, true);
      },
    );
  });

  group('Phase 62 Step 1E rollback trigger signals', () {
    test('critical crash requires rollback request', () {
      final health = healthPolicy.evaluate(
        version: version(),
        eligibility: eligibility(),
        plan: plan(),
        observation: observation(criticalCrashes: 1),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(health.rollbackRequestRequired, true);
      expect(health.ownerAlertRequired, true);
      expect(health.reasonCode, 'critical_crash_detected');

      final trigger = rollbackPolicy.evaluate(
        version: version(),
        health: health,
      );

      expect(trigger.required, true);
      expect(trigger.rollbackTargetVersionId, 'ride_agent:v1.0.0');
      expect(trigger.triggerOnly, true);
      expect(trigger.rollbackExecutionPerformed, false);
    });

    test('behavior regression requires rollback request', () {
      final health = healthPolicy.evaluate(
        version: version(),
        eligibility: eligibility(),
        plan: plan(),
        observation: observation(regressionDetected: true),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(health.rollbackRequestRequired, true);
      expect(health.reasonCode, 'behavior_regression_detected');
    });

    test('privacy violation requires rollback request', () {
      final health = healthPolicy.evaluate(
        version: version(),
        eligibility: eligibility(),
        plan: plan(),
        observation: observation(privacy: 1),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(health.rollbackRequestRequired, true);
      expect(health.reasonCode, 'privacy_violation_detected');
    });

    test('Permission violation requires rollback request', () {
      final health = healthPolicy.evaluate(
        version: version(),
        eligibility: eligibility(),
        plan: plan(),
        observation: observation(permission: 1),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(health.rollbackRequestRequired, true);
      expect(health.reasonCode, 'permission_violation_detected');
    });

    test('Approval bypass requires rollback request', () {
      final health = healthPolicy.evaluate(
        version: version(),
        eligibility: eligibility(),
        plan: plan(),
        observation: observation(approvalBypass: 1),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(health.rollbackRequestRequired, true);
      expect(health.reasonCode, 'approval_bypass_detected');
    });

    test('business-write violation requires rollback request', () {
      final health = healthPolicy.evaluate(
        version: version(),
        eligibility: eligibility(),
        plan: plan(),
        observation: observation(businessWrite: 1),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(health.rollbackRequestRequired, true);
      expect(health.reasonCode, 'business_write_violation_detected');
    });

    test('core app isolation failure requires rollback request', () {
      final health = healthPolicy.evaluate(
        version: version(),
        eligibility: eligibility(),
        plan: plan(),
        observation: observation(coreIsolation: false),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(health.rollbackRequestRequired, true);
      expect(health.reasonCode, 'core_app_failure_isolation_broken');
    });

    test(
      'any failed limited-rollout observation requires rollback request',
      () {
        final health = healthPolicy.evaluate(
          version: version(),
          eligibility: eligibility(),
          plan: plan(),
          observation: observation(completed: 20, successful: 19, failed: 1),
          evaluatedAtUtc: evaluatedAtUtc,
        );

        expect(health.rollbackRequestRequired, true);
        expect(health.reasonCode, 'limited_rollout_failure_detected');
      },
    );
  });

  group('Phase 62 Step 1E known-good rollback target', () {
    test('healthy observation produces no rollback trigger', () {
      final health = healthPolicy.evaluate(
        version: version(),
        eligibility: eligibility(),
        plan: plan(),
        observation: observation(),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      final trigger = rollbackPolicy.evaluate(
        version: version(),
        health: health,
      );

      expect(trigger.required, false);
      expect(trigger.status, AgentVersionRollbackTriggerStatus.notRequired);
      expect(trigger.rollbackTargetVersionId, isNull);
    });

    test('rollback target comes only from previousVersionId', () {
      final health = healthPolicy.evaluate(
        version: version(),
        eligibility: eligibility(),
        plan: plan(),
        observation: observation(criticalCrashes: 1),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      final trigger = rollbackPolicy.evaluate(
        version: version(previousVersionId: 'ride_agent:v0.9.0'),
        health: health,
      );

      expect(trigger.required, true);
      expect(trigger.rollbackTargetVersionId, 'ride_agent:v0.9.0');
    });

    test(
      'missing previous version blocks trigger target instead of guessing',
      () {
        final current = version(previousVersionId: null);

        final health = healthPolicy.evaluate(
          version: current,
          eligibility: eligibility(),
          plan: plan(),
          observation: observation(criticalCrashes: 1),
          evaluatedAtUtc: evaluatedAtUtc,
        );

        final trigger = rollbackPolicy.evaluate(
          version: current,
          health: health,
        );

        expect(trigger.required, false);
        expect(
          trigger.status,
          AgentVersionRollbackTriggerStatus.blockedNoKnownGoodVersion,
        );
        expect(trigger.rollbackTargetVersionId, isNull);
        expect(trigger.ownerAlertRequired, true);
      },
    );
  });

  group('Phase 62 Step 1E no execution authority', () {
    test('observation stores no raw/private/secret/token payload', () {
      final value = observation();

      expect(value.metadataOnly, true);
      expect(value.rawPromptStored, false);
      expect(value.rawConversationStored, false);
      expect(value.privatePayloadStored, false);
      expect(value.secretsStored, false);
      expect(value.authTokenStored, false);
      expect(value.approvalTokenStored, false);
      expect(value.permissionTokenStored, false);
    });

    test('health policy has zero protected execution authority', () {
      expect(healthPolicy.persistsObservation, false);
      expect(healthPolicy.routesTraffic, false);
      expect(healthPolicy.deploysVersion, false);
      expect(healthPolicy.activatesProduction, false);
      expect(healthPolicy.transitionsLifecycle, false);
      expect(healthPolicy.executesRollback, false);
      expect(healthPolicy.sendsOwnerAlert, false);
      expect(healthPolicy.consumesApproval, false);
      expect(healthPolicy.grantsPermission, false);
      expect(healthPolicy.mutatesSecurity, false);
      expect(healthPolicy.writesBusinessData, false);
    });

    test('rollback policy is trigger-only and never executes restore', () {
      expect(rollbackPolicy.triggerOnly, true);
      expect(rollbackPolicy.exactBackupRestorePerformed, false);
      expect(rollbackPolicy.rollbackExecutionPerformed, false);
      expect(rollbackPolicy.automaticRollbackPerformed, false);
      expect(rollbackPolicy.persistsTrigger, false);
      expect(rollbackPolicy.mutatesLifecycle, false);
      expect(rollbackPolicy.routesTraffic, false);
      expect(rollbackPolicy.deploysVersion, false);
      expect(rollbackPolicy.activatesProduction, false);
      expect(rollbackPolicy.consumesApproval, false);
      expect(rollbackPolicy.grantsPermission, false);
      expect(rollbackPolicy.sendsOwnerAlert, false);
      expect(rollbackPolicy.writesBusinessData, false);
    });
  });
}
