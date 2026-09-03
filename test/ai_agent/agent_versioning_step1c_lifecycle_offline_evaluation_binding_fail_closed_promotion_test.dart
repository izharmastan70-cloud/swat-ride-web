import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_version_lifecycle_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_versioning_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_evaluation_result.dart';
import 'package:swat_ride/ai_agent/models/agent_evaluation_run.dart';
import 'package:swat_ride/ai_agent/models/agent_version_evaluation_binding.dart';
import 'package:swat_ride/ai_agent/models/agent_version_lifecycle_transition.dart';
import 'package:swat_ride/ai_agent/models/agent_version_record.dart';
import 'package:swat_ride/ai_agent/services/agent_version_evaluation_binding_service.dart';
import 'package:swat_ride/ai_agent/services/agent_version_lifecycle_transition_policy.dart';

void main() {
  const AgentVersionEvaluationBindingService bindingService =
      AgentVersionEvaluationBindingService();

  const AgentVersionLifecycleTransitionPolicy transitionPolicy =
      AgentVersionLifecycleTransitionPolicy();

  const String sha256 =
      '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

  AgentVersionRecord version({
    String status = AgentVersionLifecycleStatus.proposed,
    String changeRisk = AgentVersionChangeRisk.high,
  }) {
    return AgentVersionRecord(
      contractVersion: AgentVersionContract.contractVersion,
      versionId: 'ride_agent:v1.1.0',
      agentId: 'ride_agent',
      semanticVersion: '1.1.0',
      previousVersionId: 'ride_agent:v1.0.0',
      changeType: AgentVersionChangeType.behaviorPrompt,
      changeRisk: changeRisk,
      changeCode: 'improve_booking_clarification',
      artifactFingerprintSha256: sha256,
      status: status,
      proposedAtUtc: DateTime.utc(2026, 8, 24),
      evaluationRunId: null,
    );
  }

  AgentEvaluationResult passedResult() {
    return AgentEvaluationResult(
      caseId: 'phase62_synthetic_case',
      caseVersion: 1,
      status: 'PASSED',
      actualDecision: 'ALLOW',
      actualBehaviorSummary: 'Synthetic offline evaluation passed safely.',
      passedChecks: const <String>['synthetic_pass'],
      failedChecks: const <String>[],
      safetyViolations: const <String>[],
      evaluatorVersion: 'phase42_b2_v1',
      evaluatedAt: DateTime.utc(2026, 8, 24, 0, 10),
    );
  }

  AgentEvaluationRun cleanRun({
    double passPercent = 100,
    double weightedScorePercent = 100,
    int criticalFailureCount = 0,
    int safetyViolationCount = 0,
    int blockedCount = 0,
    bool thresholdPassed = true,
    bool failClosed = false,
    bool eligibleForHumanReview = true,
  }) {
    final AgentEvaluationResult result = passedResult();

    return AgentEvaluationRun(
      runId: 'phase62:eval:ride_agent:v1.1.0',
      catalogVersion: 'phase42_core_v1',
      evaluatorVersion: 'phase42_b2_v1',
      policyVersion: 'phase42_policy_v1',
      totalCount: 1,
      passedCount: blockedCount == 0 ? 1 : 0,
      failedCount: 0,
      blockedCount: blockedCount,
      passPercent: passPercent,
      weightedScorePercent: weightedScorePercent,
      criticalFailureCount: criticalFailureCount,
      highFailureCount: 0,
      safetyViolationCount: safetyViolationCount,
      thresholdPassed: thresholdPassed,
      failClosed: failClosed,
      eligibleForHumanReview: eligibleForHumanReview,
      results: <AgentEvaluationResult>[result],
      startedAt: DateTime.utc(2026, 8, 24, 0, 0),
      completedAt: DateTime.utc(2026, 8, 24, 0, 15),
    );
  }

  AgentVersionEvaluationBinding cleanBinding({
    AgentVersionRecord? sourceVersion,
    AgentEvaluationRun? run,
    String evaluatedVersionId = 'ride_agent:v1.1.0',
    String evaluatedAgentId = 'ride_agent',
    String evaluatedFingerprint = sha256,
  }) {
    return bindingService.bind(
      version: sourceVersion ?? version(),
      evaluationRun: run ?? cleanRun(),
      evaluatedVersionId: evaluatedVersionId,
      evaluatedAgentId: evaluatedAgentId,
      evaluatedArtifactFingerprintSha256: evaluatedFingerprint,
    );
  }

  AgentVersionLifecycleTransitionRequest request({
    required String from,
    required String to,
    bool humanApproval = false,
    bool securityReview = false,
  }) {
    return AgentVersionLifecycleTransitionRequest(
      versionId: 'ride_agent:v1.1.0',
      fromStatus: from,
      toStatus: to,
      humanApprovalGranted: humanApproval,
      securityReviewPassed: securityReview,
    );
  }

  group('Phase 62 Step 1C Phase 42 evidence binding', () {
    test('clean Phase 42 run binds to exact immutable version identity', () {
      final AgentVersionEvaluationBinding binding = cleanBinding();

      expect(binding.versionId, 'ride_agent:v1.1.0');
      expect(binding.agentId, 'ride_agent');
      expect(binding.artifactFingerprintSha256, sha256);
      expect(binding.phase42EvidenceReused, true);
      expect(binding.immutableEvidenceReference, true);
      expect(binding.metadataOnly, true);
      expect(binding.cleanForOfflinePromotion, true);
    });

    test('binding copies no raw evaluation results or private payload', () {
      final AgentVersionEvaluationBinding binding = cleanBinding();

      expect(binding.rawEvaluationResultsCopied, false);
      expect(binding.rawPromptStored, false);
      expect(binding.privateConversationStored, false);
      expect(binding.secretsStored, false);
      expect(binding.authTokenStored, false);
      expect(binding.approvalTokenStored, false);
      expect(binding.permissionTokenStored, false);
    });

    test('wrong artifact fingerprint fails closed', () {
      expect(
        () => cleanBinding(
          evaluatedFingerprint:
              'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff',
        ),
        throwsStateError,
      );
    });

    test('wrong version id fails closed', () {
      expect(
        () => cleanBinding(evaluatedVersionId: 'ride_agent:v9.9.9'),
        throwsStateError,
      );
    });

    test('binding service has no runtime/deployment authority', () {
      expect(bindingService.copiesRawEvaluationResults, false);
      expect(bindingService.persistsBinding, false);
      expect(bindingService.callsProvider, false);
      expect(bindingService.trainsModel, false);
      expect(bindingService.mutatesPrompt, false);
      expect(bindingService.deploysVersion, false);
      expect(bindingService.activatesProduction, false);
      expect(bindingService.grantsPermission, false);
      expect(bindingService.consumesApproval, false);
      expect(bindingService.writesBusinessData, false);
    });
  });

  group('Phase 62 Step 1C PROPOSED to OFFLINE_EVALUATED', () {
    test('clean evidence allows offline-evaluated decision', () {
      final AgentVersionRecord source = version();
      final decision = transitionPolicy.evaluate(
        version: source,
        request: request(
          from: AgentVersionLifecycleStatus.proposed,
          to: AgentVersionLifecycleStatus.offlineEvaluated,
        ),
        evidence: cleanBinding(sourceVersion: source),
      );

      expect(decision.allowed, true);
      expect(
        decision.reasonCode,
        AgentVersionTransitionReason.offlineEvaluationPassed,
      );
      expect(decision.mutatesVersionRecord, false);
    });

    test('missing evidence blocks promotion', () {
      final decision = transitionPolicy.evaluate(
        version: version(),
        request: request(
          from: AgentVersionLifecycleStatus.proposed,
          to: AgentVersionLifecycleStatus.offlineEvaluated,
        ),
      );

      expect(decision.allowed, false);
      expect(
        decision.status,
        AgentVersionTransitionDecisionStatus.blockedEvidenceMissing,
      );
    });

    test('below 95 pass score blocks promotion', () {
      final AgentVersionRecord source = version();
      final binding = cleanBinding(
        sourceVersion: source,
        run: cleanRun(
          passPercent: 94,
          weightedScorePercent: 100,
          thresholdPassed: false,
          eligibleForHumanReview: false,
        ),
      );

      final decision = transitionPolicy.evaluate(
        version: source,
        request: request(
          from: AgentVersionLifecycleStatus.proposed,
          to: AgentVersionLifecycleStatus.offlineEvaluated,
        ),
        evidence: binding,
      );

      expect(decision.allowed, false);
      expect(decision.reasonCode, AgentVersionTransitionReason.thresholdFailed);
    });

    test('below 95 weighted score blocks promotion', () {
      final AgentVersionRecord source = version();
      final binding = cleanBinding(
        sourceVersion: source,
        run: cleanRun(
          passPercent: 100,
          weightedScorePercent: 94,
          thresholdPassed: false,
          eligibleForHumanReview: false,
        ),
      );

      final decision = transitionPolicy.evaluate(
        version: source,
        request: request(
          from: AgentVersionLifecycleStatus.proposed,
          to: AgentVersionLifecycleStatus.offlineEvaluated,
        ),
        evidence: binding,
      );

      expect(decision.allowed, false);
      expect(decision.reasonCode, AgentVersionTransitionReason.thresholdFailed);
    });

    test('critical failure blocks promotion', () {
      final AgentVersionRecord source = version();
      final binding = cleanBinding(
        sourceVersion: source,
        run: cleanRun(
          criticalFailureCount: 1,
          thresholdPassed: false,
          failClosed: true,
          eligibleForHumanReview: false,
        ),
      );

      final decision = transitionPolicy.evaluate(
        version: source,
        request: request(
          from: AgentVersionLifecycleStatus.proposed,
          to: AgentVersionLifecycleStatus.offlineEvaluated,
        ),
        evidence: binding,
      );

      expect(decision.allowed, false);
      expect(decision.reasonCode, AgentVersionTransitionReason.criticalFailure);
    });

    test('safety violation blocks promotion', () {
      final AgentVersionRecord source = version();
      final binding = cleanBinding(
        sourceVersion: source,
        run: cleanRun(
          safetyViolationCount: 1,
          thresholdPassed: false,
          failClosed: true,
          eligibleForHumanReview: false,
        ),
      );

      final decision = transitionPolicy.evaluate(
        version: source,
        request: request(
          from: AgentVersionLifecycleStatus.proposed,
          to: AgentVersionLifecycleStatus.offlineEvaluated,
        ),
        evidence: binding,
      );

      expect(decision.allowed, false);
      expect(decision.reasonCode, AgentVersionTransitionReason.safetyViolation);
    });
  });

  group('Phase 62 Step 1C OFFLINE_EVALUATED to TEST_READY', () {
    test('high-risk version requires human approval and security review', () {
      final AgentVersionRecord source = version(
        status: AgentVersionLifecycleStatus.offlineEvaluated,
      );
      final AgentVersionEvaluationBinding evidence = cleanBinding(
        sourceVersion: source,
      );

      final noHuman = transitionPolicy.evaluate(
        version: source,
        request: request(
          from: AgentVersionLifecycleStatus.offlineEvaluated,
          to: AgentVersionLifecycleStatus.testReady,
          humanApproval: false,
          securityReview: true,
        ),
        evidence: evidence,
      );

      expect(
        noHuman.status,
        AgentVersionTransitionDecisionStatus.blockedHumanApproval,
      );

      final noSecurity = transitionPolicy.evaluate(
        version: source,
        request: request(
          from: AgentVersionLifecycleStatus.offlineEvaluated,
          to: AgentVersionLifecycleStatus.testReady,
          humanApproval: true,
          securityReview: false,
        ),
        evidence: evidence,
      );

      expect(
        noSecurity.status,
        AgentVersionTransitionDecisionStatus.blockedSecurityReview,
      );

      final approved = transitionPolicy.evaluate(
        version: source,
        request: request(
          from: AgentVersionLifecycleStatus.offlineEvaluated,
          to: AgentVersionLifecycleStatus.testReady,
          humanApproval: true,
          securityReview: true,
        ),
        evidence: evidence,
      );

      expect(approved.allowed, true);
      expect(
        approved.reasonCode,
        AgentVersionTransitionReason.testReadinessApproved,
      );
    });

    test('medium-risk still requires human approval', () {
      final AgentVersionRecord source = version(
        status: AgentVersionLifecycleStatus.offlineEvaluated,
        changeRisk: AgentVersionChangeRisk.medium,
      );
      final AgentVersionEvaluationBinding evidence = cleanBinding(
        sourceVersion: source,
      );

      final blocked = transitionPolicy.evaluate(
        version: source,
        request: request(
          from: AgentVersionLifecycleStatus.offlineEvaluated,
          to: AgentVersionLifecycleStatus.testReady,
        ),
        evidence: evidence,
      );

      expect(
        blocked.status,
        AgentVersionTransitionDecisionStatus.blockedHumanApproval,
      );

      final approved = transitionPolicy.evaluate(
        version: source,
        request: request(
          from: AgentVersionLifecycleStatus.offlineEvaluated,
          to: AgentVersionLifecycleStatus.testReady,
          humanApproval: true,
        ),
        evidence: evidence,
      );

      expect(approved.allowed, true);
    });

    test('cannot skip directly from proposed to test ready', () {
      final decision = transitionPolicy.evaluate(
        version: version(),
        request: request(
          from: AgentVersionLifecycleStatus.proposed,
          to: AgentVersionLifecycleStatus.testReady,
          humanApproval: true,
          securityReview: true,
        ),
        evidence: cleanBinding(),
      );

      expect(decision.allowed, false);
      expect(
        decision.status,
        AgentVersionTransitionDecisionStatus.blockedIllegalTransition,
      );
    });

    test('limited rollout remains blocked for later Phase 62 step', () {
      final AgentVersionRecord source = version(
        status: AgentVersionLifecycleStatus.testReady,
      );

      final decision = transitionPolicy.evaluate(
        version: source,
        request: request(
          from: AgentVersionLifecycleStatus.testReady,
          to: AgentVersionLifecycleStatus.limitedRolloutReady,
          humanApproval: true,
          securityReview: true,
        ),
        evidence: cleanBinding(),
      );

      expect(decision.allowed, false);
      expect(
        decision.status,
        AgentVersionTransitionDecisionStatus.blockedLaterPhase,
      );
    });
  });

  group('Phase 62 Step 1C authority and failure isolation', () {
    test('transition policy performs no mutation or deployment', () {
      expect(transitionPolicy.mutatesVersionRecord, false);
      expect(transitionPolicy.persistsTransition, false);
      expect(transitionPolicy.callsProvider, false);
      expect(transitionPolicy.trainsModel, false);
      expect(transitionPolicy.mutatesPrompt, false);
      expect(transitionPolicy.deploysVersion, false);
      expect(transitionPolicy.activatesProduction, false);
      expect(transitionPolicy.performsRollback, false);
      expect(transitionPolicy.grantsPermission, false);
      expect(transitionPolicy.consumesApproval, false);
      expect(transitionPolicy.mutatesSecurity, false);
      expect(transitionPolicy.writesBusinessData, false);
    });

    test('allowed decision still performs zero authority actions', () {
      final AgentVersionRecord source = version();
      final decision = transitionPolicy.evaluate(
        version: source,
        request: request(
          from: AgentVersionLifecycleStatus.proposed,
          to: AgentVersionLifecycleStatus.offlineEvaluated,
        ),
        evidence: cleanBinding(sourceVersion: source),
      );

      expect(decision.allowed, true);
      expect(decision.deploymentPerformed, false);
      expect(decision.productionActivationPerformed, false);
      expect(decision.rollbackPerformed, false);
      expect(decision.modelTrainingPerformed, false);
      expect(decision.promptMutationPerformed, false);
      expect(decision.permissionGranted, false);
      expect(decision.approvalConsumed, false);
      expect(decision.businessWritePerformed, false);
      expect(decision.securityAuthorityPreserved, true);
    });
  });
}
