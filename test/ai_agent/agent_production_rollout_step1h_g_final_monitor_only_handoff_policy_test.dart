import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/models/agent_production_rollout_monitor_only_final_handoff.dart';
import 'package:swat_ride/ai_agent/services/agent_production_rollout_monitor_only_final_handoff_policy.dart';

void main() {
  const policy = AgentProductionRolloutMonitorOnlyFinalHandoffPolicy();

  AgentProductionRolloutMonitorOnlyFinalHandoff clean() {
    return policy.evaluate(
      monitorOnlyObservationChainComplete: true,
      coreStabilityClean: true,
      persistedOperationalSignalsClean: true,
      knownRecoveryControlHistoryClassified: true,
      unclassifiedCriticalSignalsClear: true,
      incidentPersistenceAuthorityGapExplicit: true,
      separateImplementationAuthorityRequired: true,
      ownerReviewReady: true,
    );
  }

  test('clean A-to-F chain becomes final handoff ready', () {
    final result = clean();

    expect(
      result.status,
      AgentProductionRolloutMonitorOnlyFinalHandoffPolicy
          .readyAwaitingOwnerDecision,
    );
    expect(result.monitorOnlyObservationChainComplete, isTrue);
  });

  test('fresh Owner decision remains required and absent', () {
    final result = clean();

    expect(result.freshOwnerDecisionRequired, isTrue);
    expect(result.ownerDecisionPresent, isFalse);
  });

  test('current production stage stays MONITOR_ONLY', () {
    final result = clean();

    expect(result.keepMonitorOnly, isTrue);
    expect(result.changesRolloutStage, isFalse);
    expect(result.changesAgentMode, isFalse);
  });

  test('SUGGEST_ONLY stays blocked', () {
    final result = clean();

    expect(result.suggestOnlyBlocked, isTrue);
    expect(result.mayAdvanceToSuggestOnly, isFalse);
    expect(result.authorizesSuggestOnly, isFalse);
    expect(policy.authorizesSuggestOnly, isFalse);
  });

  test('AUTO stays blocked', () {
    final result = clean();

    expect(result.autoBlocked, isTrue);
    expect(result.mayAdvanceToAuto, isFalse);
    expect(result.authorizesAuto, isFalse);
    expect(policy.authorizesAuto, isFalse);
  });

  test('incident persistence authority gap remains explicit', () {
    final result = clean();

    expect(result.incidentPersistenceAuthorityGapExplicit, isTrue);
    expect(result.separateImplementationAuthorityRequired, isTrue);
  });

  test('unclean critical signals block final handoff readiness', () {
    final result = policy.evaluate(
      monitorOnlyObservationChainComplete: true,
      coreStabilityClean: true,
      persistedOperationalSignalsClean: true,
      knownRecoveryControlHistoryClassified: true,
      unclassifiedCriticalSignalsClear: false,
      incidentPersistenceAuthorityGapExplicit: true,
      separateImplementationAuthorityRequired: true,
      ownerReviewReady: true,
    );

    expect(
      result.status,
      AgentProductionRolloutMonitorOnlyFinalHandoffPolicy.notReady,
    );
  });

  test('policy cannot create or consume Owner approval', () {
    final result = clean();

    expect(result.createsApproval, isFalse);
    expect(result.consumesApproval, isFalse);
    expect(policy.createsApproval, isFalse);
    expect(policy.invokesApprovalEngine, isFalse);
    expect(policy.consumesApproval, isFalse);
  });

  test('policy has zero persistence or production mutation authority', () {
    final result = clean();

    expect(result.writesFirestore, isFalse);
    expect(result.changesFirestoreRules, isFalse);
    expect(result.changesEmergencyStop, isFalse);
    expect(result.grantsPermission, isFalse);

    expect(policy.writesFirestore, isFalse);
    expect(policy.changesFirestoreRules, isFalse);
    expect(policy.changesEmergencyStop, isFalse);
    expect(policy.invokesPermissionEngine, isFalse);
    expect(policy.grantsPermission, isFalse);
  });
}
