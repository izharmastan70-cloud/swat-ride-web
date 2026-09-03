import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_ecosystem_resilience_safety_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_ecosystem_resilience_safety_request.dart';
import 'package:swat_ride/ai_agent/services/agent_ecosystem_resilience_safety_policy.dart';

void main() {
  const policy = AgentEcosystemResilienceSafetyPolicy();

  AgentEcosystemResilienceSafetyRequest request({
    bool rawConversationSelfTrainingRequested = false,
    bool directProductionPromptReplacementRequested = false,
    bool evaluationPassed = true,
    bool ownerApprovalVerified = true,
    bool exactVersionIdentityBound = true,
    bool testEnvironmentPassed = true,
    bool monitoringHealthy = true,
    bool rollbackRequested = false,
    bool knownGoodRollbackTargetExact = true,
    bool rollbackReadinessVerified = true,
    bool primaryProviderAvailable = true,
    bool fallbackProviderAvailable = true,
    bool fallbackPolicyAllows = true,
    bool auditReady = true,
    bool coreSwatRideIsolationVerified = true,
  }) {
    return AgentEcosystemResilienceSafetyRequest(
      rawConversationSelfTrainingRequested:
          rawConversationSelfTrainingRequested,
      directProductionPromptReplacementRequested:
          directProductionPromptReplacementRequested,
      evaluationPassed: evaluationPassed,
      ownerApprovalVerified: ownerApprovalVerified,
      exactVersionIdentityBound: exactVersionIdentityBound,
      testEnvironmentPassed: testEnvironmentPassed,
      monitoringHealthy: monitoringHealthy,
      rollbackRequested: rollbackRequested,
      knownGoodRollbackTargetExact: knownGoodRollbackTargetExact,
      rollbackReadinessVerified: rollbackReadinessVerified,
      primaryProviderAvailable: primaryProviderAvailable,
      fallbackProviderAvailable: fallbackProviderAvailable,
      fallbackPolicyAllows: fallbackPolicyAllows,
      auditReady: auditReady,
      coreSwatRideIsolationVerified: coreSwatRideIsolationVerified,
    );
  }

  test('raw conversation self-training is blocked', () {
    final decision = policy.evaluate(
      request(rawConversationSelfTrainingRequested: true),
    );

    expect(
      decision.status,
      AgentEcosystemResilienceDecisionStatus.blockUnrestrictedTraining,
    );
    expect(decision.mayTrainModel, false);
  });

  test('Training Agent cannot directly replace production prompt', () {
    final decision = policy.evaluate(
      request(directProductionPromptReplacementRequested: true),
    );

    expect(
      decision.status,
      AgentEcosystemResilienceDecisionStatus.blockUnrestrictedTraining,
    );
    expect(decision.mayReplaceProductionPrompt, false);
  });

  test('core SWAT RIDE isolation failure blocks before rollout logic', () {
    final decision = policy.evaluate(
      request(coreSwatRideIsolationVerified: false),
    );

    expect(
      decision.status,
      AgentEcosystemResilienceDecisionStatus.blockCoreIsolationFailure,
    );
    expect(decision.mayDisableCoreSwatRide, false);
  });

  test('missing critical audit readiness blocks transition', () {
    final decision = policy.evaluate(request(auditReady: false));

    expect(
      decision.status,
      AgentEcosystemResilienceDecisionStatus.blockAuditUnavailable,
    );
    expect(decision.auditRequired, true);
  });

  test('failed/missing offline evaluation blocks', () {
    final decision = policy.evaluate(request(evaluationPassed: false));

    expect(
      decision.status,
      AgentEcosystemResilienceDecisionStatus.blockEvaluationRequired,
    );
  });

  test('meaningful change without Owner approval blocks', () {
    final decision = policy.evaluate(request(ownerApprovalVerified: false));

    expect(
      decision.status,
      AgentEcosystemResilienceDecisionStatus.blockOwnerApprovalRequired,
    );
  });

  test('missing exact immutable version binding blocks', () {
    final decision = policy.evaluate(request(exactVersionIdentityBound: false));

    expect(
      decision.status,
      AgentEcosystemResilienceDecisionStatus.blockVersionBinding,
    );
  });

  test('test environment failure blocks rollout handoff', () {
    final decision = policy.evaluate(request(testEnvironmentPassed: false));

    expect(
      decision.status,
      AgentEcosystemResilienceDecisionStatus.blockTestEnvironment,
    );
  });

  test('unhealthy monitoring requires rollback path', () {
    final decision = policy.evaluate(request(monitoringHealthy: false));

    expect(
      decision.status,
      AgentEcosystemResilienceDecisionStatus.rollbackRequestEligible,
    );
    expect(decision.mayExecuteRollback, false);
  });

  test('rollback target may never be guessed', () {
    final decision = policy.evaluate(
      request(monitoringHealthy: false, knownGoodRollbackTargetExact: false),
    );

    expect(
      decision.status,
      AgentEcosystemResilienceDecisionStatus.blockRollbackTargetUnknown,
    );
  });

  test('rollback readiness must be verified before request eligibility', () {
    final decision = policy.evaluate(
      request(rollbackRequested: true, rollbackReadinessVerified: false),
    );

    expect(
      decision.status,
      AgentEcosystemResilienceDecisionStatus.blockRollbackNotReady,
    );
  });

  test('rollback request is never automatic rollback execution', () {
    final decision = policy.evaluate(request(rollbackRequested: true));

    expect(
      decision.status,
      AgentEcosystemResilienceDecisionStatus.rollbackRequestEligible,
    );
    expect(decision.mayExecuteRollback, false);
  });

  test('primary provider outage can yield safe fallback eligibility only', () {
    final decision = policy.evaluate(request(primaryProviderAvailable: false));

    expect(
      decision.status,
      AgentEcosystemResilienceDecisionStatus.safeProviderFallbackEligible,
    );
    expect(decision.mayCallFallbackProvider, false);
    expect(decision.mayChangeProviderPolicy, false);
    expect(decision.mayChangeCostLimits, false);
  });

  test('fallback cannot bypass existing provider policy', () {
    final decision = policy.evaluate(
      request(
        primaryProviderAvailable: false,
        fallbackProviderAvailable: true,
        fallbackPolicyAllows: false,
      ),
    );

    expect(
      decision.status,
      AgentEcosystemResilienceDecisionStatus.aiUnavailableCoreContinues,
    );
    expect(decision.mayCallFallbackProvider, false);
  });

  test('all AI providers offline keeps core SWAT RIDE available', () {
    final decision = policy.evaluate(
      request(
        primaryProviderAvailable: false,
        fallbackProviderAvailable: false,
      ),
    );

    expect(
      decision.status,
      AgentEcosystemResilienceDecisionStatus.aiUnavailableCoreContinues,
    );
    expect(decision.reasonCode, contains('core_swat_ride_continues'));
    expect(decision.mayDisableCoreSwatRide, false);
  });

  test('healthy evidence yields monitored handoff, not activation', () {
    final decision = policy.evaluate(request());

    expect(
      decision.status,
      AgentEcosystemResilienceDecisionStatus.monitoredHandoffEligible,
    );
    expect(decision.mayActivateVersion, false);
    expect(decision.mayDeployProduction, false);
  });

  test('resilience policy has zero mutation/execution authority', () {
    expect(policy.coordinationOnly, true);
    expect(policy.trainsModel, false);
    expect(policy.replacesProductionPrompt, false);
    expect(policy.activatesVersion, false);
    expect(policy.deploysProduction, false);
    expect(policy.executesRollback, false);
    expect(policy.callsProvider, false);
    expect(policy.changesProviderPolicy, false);
    expect(policy.changesCostLimits, false);
    expect(policy.consumesApproval, false);
    expect(policy.grantsPermission, false);
    expect(policy.readsFirestore, false);
    expect(policy.writesFirestore, false);
    expect(policy.writesBusinessData, false);
    expect(policy.activatesProduction, false);
  });
}
