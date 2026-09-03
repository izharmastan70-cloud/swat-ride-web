import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_provider_quality_closeout_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_provider_quality_adversarial_scenario.dart';
import 'package:swat_ride/ai_agent/models/agent_provider_quality_readiness_input.dart';
import 'package:swat_ride/ai_agent/services/agent_provider_quality_adversarial_gate.dart';
import 'package:swat_ride/ai_agent/services/agent_provider_quality_final_readiness_service.dart';

void main() {
  const AgentProviderQualityAdversarialGate gate =
      AgentProviderQualityAdversarialGate();

  const AgentProviderQualityFinalReadinessService readiness =
      AgentProviderQualityFinalReadinessService();

  const AgentProviderQualityReadinessInput allReady =
      AgentProviderQualityReadinessInput(
        signalBoundaryReady: true,
        multiSignalAggregationReady: true,
        safetyFirstRecommendationReady: true,
        taskSpecificComparisonReady: true,
        antiFlappingReady: true,
        provenanceReady: true,
        outlierPoisoningResistanceReady: true,
        safeCalibrationReady: true,
        adversarialGateReady: true,
        failureIsolationReady: true,
      );

  AgentProviderQualityAdversarialScenario attack({
    bool forged = false,
    bool duplicate = false,
    bool poisoning = false,
    bool safetySuppression = false,
    bool crossTier = false,
    bool paidBypass = false,
    bool privacyBypass = false,
    bool capabilityBypass = false,
    bool circuitBypass = false,
    bool backendBypass = false,
    bool invoke = false,
    bool routeMutation = false,
    bool providerState = false,
    bool budget = false,
    bool secret = false,
    bool deployment = false,
    bool permission = false,
    bool approval = false,
    bool business = false,
  }) {
    return AgentProviderQualityAdversarialScenario(
      scenarioId: 'quality:adversarial:test',
      forgedProvenance: forged,
      duplicateEvidenceReplay: duplicate,
      poisoningAttempt: poisoning,
      hardSafetySuppressionAttempt: safetySuppression,
      crossTierRankingAttempt: crossTier,
      paidControlBypassAttempt: paidBypass,
      privacyBypassAttempt: privacyBypass,
      capabilityBypassAttempt: capabilityBypass,
      circuitBypassAttempt: circuitBypass,
      backendBoundaryBypassAttempt: backendBypass,
      directProviderInvocationAttempt: invoke,
      automaticRoutingMutationAttempt: routeMutation,
      providerStateMutationAttempt: providerState,
      budgetMutationAttempt: budget,
      secretMutationAttempt: secret,
      modelDeploymentAttempt: deployment,
      permissionAuthorityAttempt: permission,
      approvalAuthorityAttempt: approval,
      businessActionAttempt: business,
    );
  }

  group('Phase 59 Step 1G final closeout', () {
    test('3 readiness states are locked', () {
      expect(AgentProviderQualityReadinessStatus.values.length, 3);
    });

    test('2 adversarial dispositions are locked', () {
      expect(AgentProviderQualityAdversarialDisposition.values.length, 2);
    });

    test('clean scenario passes adversarial gate', () {
      expect(
        gate.evaluate(attack()),
        AgentProviderQualityAdversarialDisposition.pass,
      );
    });

    test('forged provenance fails closed', () {
      expect(
        gate.evaluate(attack(forged: true)),
        AgentProviderQualityAdversarialDisposition.failClosed,
      );
    });

    test('duplicate evidence replay fails closed', () {
      expect(
        gate.evaluate(attack(duplicate: true)),
        AgentProviderQualityAdversarialDisposition.failClosed,
      );
    });

    test('poisoning attempt fails closed', () {
      expect(
        gate.evaluate(attack(poisoning: true)),
        AgentProviderQualityAdversarialDisposition.failClosed,
      );
    });

    test('hard safety suppression fails closed', () {
      expect(
        gate.evaluate(attack(safetySuppression: true)),
        AgentProviderQualityAdversarialDisposition.failClosed,
      );
    });

    test('cross-tier ranking attempt fails closed', () {
      expect(
        gate.evaluate(attack(crossTier: true)),
        AgentProviderQualityAdversarialDisposition.failClosed,
      );
    });

    test('paid control bypass fails closed', () {
      expect(
        gate.evaluate(attack(paidBypass: true)),
        AgentProviderQualityAdversarialDisposition.failClosed,
      );
    });

    test('privacy bypass fails closed', () {
      expect(
        gate.evaluate(attack(privacyBypass: true)),
        AgentProviderQualityAdversarialDisposition.failClosed,
      );
    });

    test('capability bypass fails closed', () {
      expect(
        gate.evaluate(attack(capabilityBypass: true)),
        AgentProviderQualityAdversarialDisposition.failClosed,
      );
    });

    test('circuit bypass fails closed', () {
      expect(
        gate.evaluate(attack(circuitBypass: true)),
        AgentProviderQualityAdversarialDisposition.failClosed,
      );
    });

    test('backend boundary bypass fails closed', () {
      expect(
        gate.evaluate(attack(backendBypass: true)),
        AgentProviderQualityAdversarialDisposition.failClosed,
      );
    });

    test('direct provider invocation attempt fails closed', () {
      expect(
        gate.evaluate(attack(invoke: true)),
        AgentProviderQualityAdversarialDisposition.failClosed,
      );
    });

    test('automatic routing mutation attempt fails closed', () {
      expect(
        gate.evaluate(attack(routeMutation: true)),
        AgentProviderQualityAdversarialDisposition.failClosed,
      );
    });

    test('provider state mutation attempt fails closed', () {
      expect(
        gate.evaluate(attack(providerState: true)),
        AgentProviderQualityAdversarialDisposition.failClosed,
      );
    });

    test('budget mutation attempt fails closed', () {
      expect(
        gate.evaluate(attack(budget: true)),
        AgentProviderQualityAdversarialDisposition.failClosed,
      );
    });

    test('secret mutation attempt fails closed', () {
      expect(
        gate.evaluate(attack(secret: true)),
        AgentProviderQualityAdversarialDisposition.failClosed,
      );
    });

    test('model deployment attempt fails closed', () {
      expect(
        gate.evaluate(attack(deployment: true)),
        AgentProviderQualityAdversarialDisposition.failClosed,
      );
    });

    test('permission authority attempt fails closed', () {
      expect(
        gate.evaluate(attack(permission: true)),
        AgentProviderQualityAdversarialDisposition.failClosed,
      );
    });

    test('approval authority attempt fails closed', () {
      expect(
        gate.evaluate(attack(approval: true)),
        AgentProviderQualityAdversarialDisposition.failClosed,
      );
    });

    test('business action attempt fails closed', () {
      expect(
        gate.evaluate(attack(business: true)),
        AgentProviderQualityAdversarialDisposition.failClosed,
      );
    });

    test('adversarial gate itself has no execution authority', () {
      expect(gate.providerInvocationImplementedHere, false);
      expect(gate.routingMutationImplementedHere, false);
      expect(gate.providerStateMutationImplementedHere, false);
      expect(gate.budgetMutationImplementedHere, false);
      expect(gate.persistenceImplementedHere, false);
      expect(gate.executesBusinessAction, false);
    });

    test('all foundations ready closes as foundation-only', () {
      final report = readiness.evaluate(allReady);

      expect(report.foundationReady, true);
      expect(
        report.status,
        AgentProviderQualityReadinessStatus.foundationReadyNotProductionActive,
      );
      expect(report.productionActive, false);
    });

    test('incomplete foundation fails closed', () {
      final report = readiness.evaluate(
        const AgentProviderQualityReadinessInput(
          signalBoundaryReady: true,
          multiSignalAggregationReady: true,
          safetyFirstRecommendationReady: true,
          taskSpecificComparisonReady: true,
          antiFlappingReady: true,
          provenanceReady: true,
          outlierPoisoningResistanceReady: true,
          safeCalibrationReady: false,
          adversarialGateReady: true,
          failureIsolationReady: true,
        ),
      );

      expect(report.foundationReady, false);
      expect(
        report.status,
        AgentProviderQualityReadinessStatus.blockedFoundationIncomplete,
      );
    });

    test('production implementation remains deferred', () {
      final report = readiness.evaluate(allReady);

      expect(report.realProviderInvocationImplementedHere, false);
      expect(report.providerCredentialsImplementedHere, false);
      expect(report.trustedBackendPersistenceImplementedHere, false);
      expect(report.productionProviderActivationImplementedHere, false);
    });

    test('quality cannot gain Permission Approval Business authority', () {
      final report = readiness.evaluate(allReady);

      expect(report.mayGrantPermission, false);
      expect(report.mayConsumeApproval, false);
      expect(report.mayExpandScope, false);
      expect(report.mayExecuteBusinessAction, false);
    });

    test('quality cannot mutate provider/routing/budget/deployment', () {
      final report = readiness.evaluate(allReady);

      expect(report.mayMutateRouting, false);
      expect(report.mayEnableProvider, false);
      expect(report.mayDisableProvider, false);
      expect(report.mayMutateBudget, false);
      expect(report.mayChangeSecret, false);
      expect(report.mayDeployModel, false);
    });

    test('provider tier and safety gates remain authoritative', () {
      final report = readiness.evaluate(allReady);

      expect(report.freeOnlineFirstPriority, true);
      expect(report.localAiOptionalFuture, true);
      expect(report.paidAiLastEscalation, true);
      expect(report.paidOnOffStillAuthoritative, true);
      expect(report.askBeforePaidStillAuthoritative, true);
      expect(report.budgetStillAuthoritative, true);
      expect(report.privacyStillAuthoritative, true);
      expect(report.capabilityStillAuthoritative, true);
      expect(report.circuitBreakerStillAuthoritative, true);
      expect(report.backendBoundaryStillAuthoritative, true);
    });

    test('quality/provider failures preserve core app continuation', () {
      final report = readiness.evaluate(allReady);

      expect(report.coreAppContinuationPreserved, true);
      expect(report.qualityFailureCannotBreakCoreApp, true);
      expect(readiness.qualityFailureDoesNotBreakCoreApp, true);
      expect(readiness.providerFailureDoesNotBreakCoreApp, true);
      expect(readiness.evidenceFailureDoesNotBreakCoreApp, true);
      expect(readiness.calibrationFailureDoesNotBreakCoreApp, true);
    });

    test('later phase ownership remains separate', () {
      final report = readiness.evaluate(allReady);

      expect(report.phase60CrossAgentSupervisorSeparate, true);
      expect(report.phase61PerformanceDashboardSeparate, true);
      expect(report.phase62VersioningDeploymentSeparate, true);
      expect(report.phase63PrivacyRetentionSeparate, true);
      expect(report.phase65FinalSafetyAuditSeparate, true);
      expect(report.phase66ProductionRolloutSeparate, true);
    });
  });
}
