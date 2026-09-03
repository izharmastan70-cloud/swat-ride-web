import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_ecosystem_final_safety_readiness_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_ecosystem_final_safety_readiness_request.dart';
import 'package:swat_ride/ai_agent/services/agent_ecosystem_final_safety_readiness_policy.dart';

void main() {
  const policy = AgentEcosystemFinalSafetyReadinessPolicy();

  AgentEcosystemFinalSafetyReadinessRequest readyRequest({
    bool step1BVerified = true,
    bool step1CVerified = true,
    bool step1DVerified = true,
    bool step1EVerified = true,
    bool step1FVerified = true,
    int channelCoverageCount = 5,
    int agentSafetyCoverageCount = 10,
    int attackCoverageCount = 9,
    bool permanentRulesVerified = true,
    bool coreSwatRideFailureIsolationVerified = true,
    bool callAgentExactFourVerified = true,
    bool productionRuntimeActivated = false,
    bool anyAgentAutoEnabledByPhase65 = false,
    bool providerExecutionActivatedByPhase65 = false,
    bool businessExecutionActivatedByPhase65 = false,
    bool phase66ControlledRolloutRequired = true,
  }) {
    return AgentEcosystemFinalSafetyReadinessRequest(
      step1BVerified: step1BVerified,
      step1CVerified: step1CVerified,
      step1DVerified: step1DVerified,
      step1EVerified: step1EVerified,
      step1FVerified: step1FVerified,
      channelCoverageCount: channelCoverageCount,
      agentSafetyCoverageCount: agentSafetyCoverageCount,
      attackCoverageCount: attackCoverageCount,
      permanentRulesVerified: permanentRulesVerified,
      coreSwatRideFailureIsolationVerified:
          coreSwatRideFailureIsolationVerified,
      callAgentExactFourVerified: callAgentExactFourVerified,
      productionRuntimeActivated: productionRuntimeActivated,
      anyAgentAutoEnabledByPhase65: anyAgentAutoEnabledByPhase65,
      providerExecutionActivatedByPhase65: providerExecutionActivatedByPhase65,
      businessExecutionActivatedByPhase65: businessExecutionActivatedByPhase65,
      phase66ControlledRolloutRequired: phase66ControlledRolloutRequired,
    );
  }

  test(
    'locked roadmap counts are exactly 5 channels, 10 controls, 9 attacks',
    () {
      expect(AgentEcosystemFinalSafetyReadinessCounts.requiredChannels, 5);
      expect(
        AgentEcosystemFinalSafetyReadinessCounts.requiredAgentSafetyAreas,
        10,
      );
      expect(AgentEcosystemFinalSafetyReadinessCounts.requiredAttackCases, 9);
    },
  );

  test('Phase 66 controlled rollout order remains locked', () {
    expect(AgentEcosystemPhase66RolloutStage.controlledOrder, <String>[
      AgentEcosystemPhase66RolloutStage.off,
      AgentEcosystemPhase66RolloutStage.monitorOnly,
      AgentEcosystemPhase66RolloutStage.suggestOnly,
      AgentEcosystemPhase66RolloutStage.askFirst,
      AgentEcosystemPhase66RolloutStage.limitedAuto,
      AgentEcosystemPhase66RolloutStage.fullSafeAuto,
    ]);
  });

  test('complete Phase 65 evidence is ready for Phase 66 only', () {
    final result = policy.assess(readyRequest());

    expect(
      result.status,
      AgentEcosystemFinalSafetyReadinessStatus.readyForPhase66ControlledRollout,
    );
    expect(result.phase65Complete, true);
    expect(result.phase66HandoffEligible, true);
    expect(result.productionRuntimeActivated, false);
    expect(result.anyAgentAutoEnabled, false);
  });

  test('missing Step 1F evidence fails closed', () {
    final result = policy.assess(readyRequest(step1FVerified: false));

    expect(
      result.status,
      AgentEcosystemFinalSafetyReadinessStatus.blockedStepEvidence,
    );
    expect(result.phase66HandoffEligible, false);
  });

  test('missing one of five channels fails closed', () {
    final result = policy.assess(readyRequest(channelCoverageCount: 4));

    expect(
      result.status,
      AgentEcosystemFinalSafetyReadinessStatus.blockedChannelCoverage,
    );
  });

  test('missing one Agent safety area fails closed', () {
    final result = policy.assess(readyRequest(agentSafetyCoverageCount: 9));

    expect(
      result.status,
      AgentEcosystemFinalSafetyReadinessStatus.blockedAgentControlCoverage,
    );
  });

  test('missing one attack case fails closed', () {
    final result = policy.assess(readyRequest(attackCoverageCount: 8));

    expect(
      result.status,
      AgentEcosystemFinalSafetyReadinessStatus.blockedAttackCoverage,
    );
  });

  test('permanent safety rules must remain verified', () {
    final result = policy.assess(readyRequest(permanentRulesVerified: false));

    expect(
      result.status,
      AgentEcosystemFinalSafetyReadinessStatus.blockedPermanentRules,
    );
  });

  test('call_agent exact four is part of permanent closeout', () {
    final result = policy.assess(
      readyRequest(callAgentExactFourVerified: false),
    );

    expect(
      result.status,
      AgentEcosystemFinalSafetyReadinessStatus.blockedPermanentRules,
    );
  });

  test('core SWAT RIDE failure isolation is mandatory', () {
    final result = policy.assess(
      readyRequest(coreSwatRideFailureIsolationVerified: false),
    );

    expect(
      result.status,
      AgentEcosystemFinalSafetyReadinessStatus.blockedCoreFailureIsolation,
    );
  });

  test('Phase 65 cannot activate production runtime', () {
    final result = policy.assess(
      readyRequest(productionRuntimeActivated: true),
    );

    expect(
      result.status,
      AgentEcosystemFinalSafetyReadinessStatus
          .blockedUnexpectedProductionActivation,
    );
  });

  test('Phase 65 cannot switch any Agent to AUTO', () {
    final result = policy.assess(
      readyRequest(anyAgentAutoEnabledByPhase65: true),
    );

    expect(
      result.status,
      AgentEcosystemFinalSafetyReadinessStatus
          .blockedUnexpectedProductionActivation,
    );
  });

  test('Phase 65 cannot activate provider execution', () {
    final result = policy.assess(
      readyRequest(providerExecutionActivatedByPhase65: true),
    );

    expect(
      result.status,
      AgentEcosystemFinalSafetyReadinessStatus
          .blockedUnexpectedProductionActivation,
    );
  });

  test('Phase 65 cannot activate business execution', () {
    final result = policy.assess(
      readyRequest(businessExecutionActivatedByPhase65: true),
    );

    expect(
      result.status,
      AgentEcosystemFinalSafetyReadinessStatus
          .blockedUnexpectedProductionActivation,
    );
  });

  test('Phase 66 controlled rollout requirement cannot be bypassed', () {
    final result = policy.assess(
      readyRequest(phase66ControlledRolloutRequired: false),
    );

    expect(
      result.status,
      AgentEcosystemFinalSafetyReadinessStatus
          .blockedUnexpectedProductionActivation,
    );
  });

  test('final readiness result grants no execution authority', () {
    final result = policy.assess(readyRequest());

    expect(result.mayGrantPermission, false);
    expect(result.mayConsumeApproval, false);
    expect(result.mayOverrideRuntimeGate, false);
    expect(result.mayDisableEmergencyStop, false);
    expect(result.mayChangeKillSwitch, false);
    expect(result.mayDeployPromptOrModel, false);
    expect(result.mayExecuteRollback, false);
    expect(result.mayCallProvider, false);
    expect(result.maySendMessage, false);
    expect(result.mayMoveMoney, false);
    expect(result.mayReadPrivateData, false);
    expect(result.mayWriteBusinessData, false);
    expect(result.mayChangeRolloutStage, false);
  });

  test('final readiness policy is audit-only and mutation-free', () {
    expect(policy.auditOnly, true);
    expect(policy.activatesProductionRuntime, false);
    expect(policy.changesAgentMode, false);
    expect(policy.enablesAuto, false);
    expect(policy.callsProvider, false);
    expect(policy.sendsMessage, false);
    expect(policy.movesMoney, false);
    expect(policy.readsFirestore, false);
    expect(policy.writesFirestore, false);
    expect(policy.grantsPermission, false);
    expect(policy.consumesApproval, false);
    expect(policy.overridesRuntimeGate, false);
    expect(policy.changesEmergencyStop, false);
    expect(policy.changesKillSwitch, false);
    expect(policy.deploysPromptOrModel, false);
    expect(policy.executesRollback, false);
    expect(policy.writesBusinessData, false);
  });
}
