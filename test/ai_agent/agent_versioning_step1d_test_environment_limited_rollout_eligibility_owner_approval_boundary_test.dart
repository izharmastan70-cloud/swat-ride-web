import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_version_rollout_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_versioning_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_version_limited_rollout_plan.dart';
import 'package:swat_ride/ai_agent/models/agent_version_owner_rollout_approval.dart';
import 'package:swat_ride/ai_agent/models/agent_version_record.dart';
import 'package:swat_ride/ai_agent/models/agent_version_test_environment_evidence.dart';
import 'package:swat_ride/ai_agent/services/agent_version_limited_rollout_eligibility_policy.dart';
import 'package:swat_ride/ai_agent/services/agent_version_test_environment_readiness_policy.dart';

void main() {
  const AgentVersionTestEnvironmentReadinessPolicy testPolicy =
      AgentVersionTestEnvironmentReadinessPolicy();

  const AgentVersionLimitedRolloutEligibilityPolicy rolloutPolicy =
      AgentVersionLimitedRolloutEligibilityPolicy();

  const String artifactSha =
      '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

  const String scopeSha =
      'abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789';

  final DateTime evaluatedAtUtc = DateTime.utc(2026, 8, 24, 1, 0);

  AgentVersionRecord testReadyVersion({
    String status = AgentVersionLifecycleStatus.testReady,
  }) {
    return AgentVersionRecord(
      contractVersion: AgentVersionContract.contractVersion,
      versionId: 'ride_agent:v1.1.0',
      agentId: 'ride_agent',
      semanticVersion: '1.1.0',
      previousVersionId: 'ride_agent:v1.0.0',
      changeType: AgentVersionChangeType.behaviorPrompt,
      changeRisk: AgentVersionChangeRisk.high,
      changeCode: 'improve_booking_clarification',
      artifactFingerprintSha256: artifactSha,
      status: status,
      proposedAtUtc: DateTime.utc(2026, 8, 24, 0, 0),
      evaluationRunId: 'phase62:eval:ride_agent:v1.1.0',
    );
  }

  AgentVersionTestEnvironmentEvidence testEvidence({
    String versionId = 'ride_agent:v1.1.0',
    String agentId = 'ride_agent',
    String fingerprint = artifactSha,
    bool buildPassed = true,
    bool analyzePassed = true,
    bool targetedTestsPassed = true,
    bool fullRegressionPassed = true,
    bool securityBoundaryPassed = true,
    bool failureIsolationPassed = true,
    bool safeDataOnly = true,
    bool productionTrafficUsed = false,
    bool providerExecutionUsed = false,
    bool coreAppIsolationVerified = true,
    DateTime? completedAtUtc,
  }) {
    final DateTime completed =
        completedAtUtc ?? DateTime.utc(2026, 8, 24, 0, 40);

    return AgentVersionTestEnvironmentEvidence(
      evidenceId: 'phase62:testenv:ride_agent:v1.1.0',
      versionId: versionId,
      agentId: agentId,
      artifactFingerprintSha256: fingerprint,
      evaluationRunId: 'phase62:eval:ride_agent:v1.1.0',
      environmentId: 'phase62_test_env',
      buildPassed: buildPassed,
      analyzePassed: analyzePassed,
      targetedTestsPassed: targetedTestsPassed,
      fullRegressionPassed: fullRegressionPassed,
      securityBoundaryPassed: securityBoundaryPassed,
      failureIsolationPassed: failureIsolationPassed,
      syntheticOrApprovedNonPrivateDataOnly: safeDataOnly,
      productionTrafficUsed: productionTrafficUsed,
      providerExecutionUsed: providerExecutionUsed,
      coreAppIsolationVerified: coreAppIsolationVerified,
      startedAtUtc: completed.subtract(const Duration(minutes: 20)),
      completedAtUtc: completed,
    );
  }

  AgentVersionOwnerRolloutApproval ownerApproval({
    String versionId = 'ride_agent:v1.1.0',
    String agentId = 'ride_agent',
    String fingerprint = artifactSha,
    String rolloutScopeSha256 = scopeSha,
    double maximumRolloutPercent = 5,
    DateTime? approvedAtUtc,
    DateTime? expiresAtUtc,
  }) {
    final DateTime approved = approvedAtUtc ?? DateTime.utc(2026, 8, 24, 0, 50);

    return AgentVersionOwnerRolloutApproval(
      approvalId: 'owner:approval:ride_agent:v1.1.0',
      versionId: versionId,
      agentId: agentId,
      artifactFingerprintSha256: fingerprint,
      rolloutScopeSha256: rolloutScopeSha256,
      approvedByRole: 'OWNER',
      maximumRolloutPercent: maximumRolloutPercent,
      approvedAtUtc: approved,
      expiresAtUtc: expiresAtUtc ?? approved.add(const Duration(minutes: 20)),
    );
  }

  AgentVersionLimitedRolloutPlan plan({
    String versionId = 'ride_agent:v1.1.0',
    String agentId = 'ride_agent',
    String fingerprint = artifactSha,
    String rolloutScopeSha256 = scopeSha,
    double requestedPercent = 5,
  }) {
    return AgentVersionLimitedRolloutPlan(
      rolloutId: 'phase62:rollout:ride_agent:v1.1.0',
      versionId: versionId,
      agentId: agentId,
      artifactFingerprintSha256: fingerprint,
      rolloutScopeSha256: rolloutScopeSha256,
      cohortId: 'synthetic_limited_cohort',
      requestedPercent: requestedPercent,
    );
  }

  group('Phase 62 Step 1D test-environment readiness', () {
    test('clean test environment is ready', () {
      final decision = testPolicy.evaluate(
        version: testReadyVersion(),
        evidence: testEvidence(),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(decision.ready, true);
      expect(decision.status, AgentVersionTestReadinessStatus.ready);
    });

    test('exact version identity mismatch fails closed', () {
      final decision = testPolicy.evaluate(
        version: testReadyVersion(),
        evidence: testEvidence(versionId: 'ride_agent:v9.9.9'),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(decision.ready, false);
      expect(
        decision.status,
        AgentVersionTestReadinessStatus.blockedIdentityMismatch,
      );
    });

    test('production traffic in test environment is blocked', () {
      final decision = testPolicy.evaluate(
        version: testReadyVersion(),
        evidence: testEvidence(productionTrafficUsed: true),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(decision.ready, false);
      expect(
        decision.status,
        AgentVersionTestReadinessStatus.blockedProductionTraffic,
      );
    });

    test('private or unapproved test data is blocked', () {
      final decision = testPolicy.evaluate(
        version: testReadyVersion(),
        evidence: testEvidence(safeDataOnly: false),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(decision.ready, false);
      expect(
        decision.status,
        AgentVersionTestReadinessStatus.blockedPrivateData,
      );
    });

    test('failed full regression blocks readiness', () {
      final decision = testPolicy.evaluate(
        version: testReadyVersion(),
        evidence: testEvidence(fullRegressionPassed: false),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(decision.ready, false);
      expect(
        decision.status,
        AgentVersionTestReadinessStatus.blockedFailedChecks,
      );
    });

    test('provider execution inside Step 1D test evidence is blocked', () {
      final decision = testPolicy.evaluate(
        version: testReadyVersion(),
        evidence: testEvidence(providerExecutionUsed: true),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(decision.ready, false);
      expect(
        decision.status,
        AgentVersionTestReadinessStatus.blockedFailedChecks,
      );
    });

    test('stale test evidence beyond 24 hours is blocked', () {
      final decision = testPolicy.evaluate(
        version: testReadyVersion(),
        evidence: testEvidence(
          completedAtUtc: evaluatedAtUtc.subtract(const Duration(hours: 25)),
        ),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(decision.ready, false);
      expect(
        decision.status,
        AgentVersionTestReadinessStatus.blockedStaleEvidence,
      );
    });

    test('future test clock skew beyond 5 minutes is blocked', () {
      final decision = testPolicy.evaluate(
        version: testReadyVersion(),
        evidence: testEvidence(
          completedAtUtc: evaluatedAtUtc.add(const Duration(minutes: 6)),
        ),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(decision.ready, false);
      expect(decision.status, AgentVersionTestReadinessStatus.blockedClockSkew);
    });
  });

  group('Phase 62 Step 1D Owner approval boundary', () {
    test('Owner approval is explicit metadata only', () {
      final approval = ownerApproval();

      expect(approval.explicitOwnerApproval, true);
      expect(approval.metadataOnly, true);
      expect(approval.approvalEngineConsumptionPerformed, false);
      expect(approval.productionActivationAuthorized, false);
      expect(approval.productionTrafficRoutingAuthorized, false);
      expect(approval.deploymentAuthorized, false);
      expect(approval.automaticKeepAuthorized, false);
      expect(approval.automaticRollbackAuthorized, false);
      expect(approval.permissionGrantAuthorized, false);
      expect(approval.securityOverrideAuthorized, false);
    });

    test('approval cannot exceed 5 percent foundation cap', () {
      expect(
        () => ownerApproval(maximumRolloutPercent: 6),
        throwsFormatException,
      );
    });

    test('approval validity cannot exceed 30 minutes', () {
      final DateTime approved = DateTime.utc(2026, 8, 24, 0, 0);

      expect(
        () => ownerApproval(
          approvedAtUtc: approved,
          expiresAtUtc: approved.add(const Duration(minutes: 31)),
        ),
        throwsFormatException,
      );
    });
  });

  group('Phase 62 Step 1D limited-rollout eligibility', () {
    test('clean exact Owner-approved plan becomes eligible only', () {
      final result = rolloutPolicy.evaluate(
        version: testReadyVersion(),
        testEvidence: testEvidence(),
        ownerApproval: ownerApproval(),
        plan: plan(),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(result.eligible, true);
      expect(result.eligibleForLifecycleLimitedRolloutReady, true);
      expect(result.transitionPerformed, false);
      expect(result.rolloutExecutionPerformed, false);
      expect(result.productionTrafficRouted, false);
      expect(result.deploymentPerformed, false);
      expect(result.productionActivationPerformed, false);
    });

    test('version not TEST_READY is blocked', () {
      final result = rolloutPolicy.evaluate(
        version: testReadyVersion(
          status: AgentVersionLifecycleStatus.offlineEvaluated,
        ),
        testEvidence: testEvidence(),
        ownerApproval: ownerApproval(),
        plan: plan(),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(result.eligible, false);
      expect(
        result.status,
        AgentVersionLimitedRolloutEligibilityStatus.blockedVersionStatus,
      );
    });

    test('expired Owner approval is blocked', () {
      final DateTime approved = DateTime.utc(2026, 8, 24, 0, 0);

      final result = rolloutPolicy.evaluate(
        version: testReadyVersion(),
        testEvidence: testEvidence(),
        ownerApproval: ownerApproval(
          approvedAtUtc: approved,
          expiresAtUtc: approved.add(const Duration(minutes: 20)),
        ),
        plan: plan(),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(result.eligible, false);
      expect(
        result.status,
        AgentVersionLimitedRolloutEligibilityStatus.blockedApprovalExpired,
      );
    });

    test('Owner approval scope mismatch is blocked', () {
      const String otherScope =
          'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff';

      final result = rolloutPolicy.evaluate(
        version: testReadyVersion(),
        testEvidence: testEvidence(),
        ownerApproval: ownerApproval(rolloutScopeSha256: otherScope),
        plan: plan(),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(result.eligible, false);
      expect(
        result.status,
        AgentVersionLimitedRolloutEligibilityStatus.blockedScopeMismatch,
      );
    });

    test('requested percent above Owner-approved percent is blocked', () {
      final result = rolloutPolicy.evaluate(
        version: testReadyVersion(),
        testEvidence: testEvidence(),
        ownerApproval: ownerApproval(maximumRolloutPercent: 3),
        plan: plan(requestedPercent: 5),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(result.eligible, false);
      expect(
        result.status,
        AgentVersionLimitedRolloutEligibilityStatus.blockedPercent,
      );
    });

    test('wrong approval version identity is blocked', () {
      final result = rolloutPolicy.evaluate(
        version: testReadyVersion(),
        testEvidence: testEvidence(),
        ownerApproval: ownerApproval(versionId: 'ride_agent:v1.0.0'),
        plan: plan(),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(result.eligible, false);
      expect(
        result.status,
        AgentVersionLimitedRolloutEligibilityStatus.blockedOwnerApproval,
      );
    });
  });

  group('Phase 62 Step 1D no authority / no execution', () {
    test('test policy has zero protected authority', () {
      expect(testPolicy.persistsEvidence, false);
      expect(testPolicy.deploysVersion, false);
      expect(testPolicy.activatesProduction, false);
      expect(testPolicy.routesProductionTraffic, false);
      expect(testPolicy.callsProvider, false);
      expect(testPolicy.trainsModel, false);
      expect(testPolicy.mutatesPrompt, false);
      expect(testPolicy.grantsPermission, false);
      expect(testPolicy.consumesApproval, false);
      expect(testPolicy.writesBusinessData, false);
    });

    test('rollout policy has zero rollout/deployment authority', () {
      expect(rolloutPolicy.persistsEligibility, false);
      expect(rolloutPolicy.consumesApprovalEngineApproval, false);
      expect(rolloutPolicy.routesProductionTraffic, false);
      expect(rolloutPolicy.executesRollout, false);
      expect(rolloutPolicy.deploysVersion, false);
      expect(rolloutPolicy.activatesProduction, false);
      expect(rolloutPolicy.automaticKeepAllowed, false);
      expect(rolloutPolicy.automaticRollbackAllowed, false);
      expect(rolloutPolicy.trainsModel, false);
      expect(rolloutPolicy.mutatesPrompt, false);
      expect(rolloutPolicy.grantsPermission, false);
      expect(rolloutPolicy.mutatesSecurity, false);
      expect(rolloutPolicy.writesBusinessData, false);
    });
  });
}
