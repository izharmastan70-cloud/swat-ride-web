import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/services/agent_production_rollout_monitor_only_owner_review_policy.dart';

void main() {
  const policy = AgentProductionRolloutMonitorOnlyOwnerReviewPolicy();

  test('clean MONITOR_ONLY closeout becomes owner-review ready only', () {
    final result = policy.evaluate(
      monitorOnlyObservationComplete: true,
      coreStabilityVerified: true,
      persistedOperationalSignalsClear: true,
      incidentPersistenceAuthorityGapPresent: true,
      separateExplicitImplementationAuthorityRequired: true,
    );

    expect(result.readyForOwnerReview, isTrue);
    expect(
      result.status,
      AgentProductionRolloutMonitorOnlyOwnerReviewPolicy.readyHoldStatus,
    );
  });

  test('owner review is mandatory before any future advancement', () {
    final result = policy.evaluate(
      monitorOnlyObservationComplete: true,
      coreStabilityVerified: true,
      persistedOperationalSignalsClear: true,
      incidentPersistenceAuthorityGapPresent: true,
      separateExplicitImplementationAuthorityRequired: true,
    );

    expect(result.ownerReviewRequired, isTrue);
    expect(result.freshOwnerDecisionRequiredBeforeAnyAdvance, isTrue);
  });

  test('current rollout must remain MONITOR_ONLY', () {
    final result = policy.evaluate(
      monitorOnlyObservationComplete: true,
      coreStabilityVerified: true,
      persistedOperationalSignalsClear: true,
      incidentPersistenceAuthorityGapPresent: true,
      separateExplicitImplementationAuthorityRequired: true,
    );

    expect(result.keepMonitorOnly, isTrue);
    expect(result.changesRolloutStage, isFalse);
    expect(result.changesAgentMode, isFalse);
  });

  test('SUGGEST_ONLY remains blocked', () {
    final result = policy.evaluate(
      monitorOnlyObservationComplete: true,
      coreStabilityVerified: true,
      persistedOperationalSignalsClear: true,
      incidentPersistenceAuthorityGapPresent: true,
      separateExplicitImplementationAuthorityRequired: true,
    );

    expect(result.suggestOnlyAdvancementBlocked, isTrue);
    expect(result.mayAdvanceToSuggestOnly, isFalse);
    expect(result.authorizesSuggestOnly, isFalse);
    expect(policy.authorizesSuggestOnly, isFalse);
  });

  test('AUTO remains blocked', () {
    final result = policy.evaluate(
      monitorOnlyObservationComplete: true,
      coreStabilityVerified: true,
      persistedOperationalSignalsClear: true,
      incidentPersistenceAuthorityGapPresent: true,
      separateExplicitImplementationAuthorityRequired: true,
    );

    expect(result.autoAdvancementBlocked, isTrue);
    expect(result.mayAdvanceToAuto, isFalse);
    expect(result.authorizesAuto, isFalse);
    expect(policy.authorizesAuto, isFalse);
  });

  test('incident persistence gap stays visible at owner review', () {
    final result = policy.evaluate(
      monitorOnlyObservationComplete: true,
      coreStabilityVerified: true,
      persistedOperationalSignalsClear: true,
      incidentPersistenceAuthorityGapPresent: true,
      separateExplicitImplementationAuthorityRequired: true,
    );

    expect(result.incidentPersistenceAuthorityGapPresent, isTrue);
    expect(result.separateExplicitImplementationAuthorityRequired, isTrue);
  });

  test('unclean observation is not owner-review ready', () {
    final result = policy.evaluate(
      monitorOnlyObservationComplete: false,
      coreStabilityVerified: true,
      persistedOperationalSignalsClear: true,
      incidentPersistenceAuthorityGapPresent: true,
      separateExplicitImplementationAuthorityRequired: true,
    );

    expect(result.readyForOwnerReview, isFalse);
    expect(
      result.status,
      AgentProductionRolloutMonitorOnlyOwnerReviewPolicy.notReadyStatus,
    );
  });

  test('unclear persisted signals are not owner-review ready', () {
    final result = policy.evaluate(
      monitorOnlyObservationComplete: true,
      coreStabilityVerified: true,
      persistedOperationalSignalsClear: false,
      incidentPersistenceAuthorityGapPresent: true,
      separateExplicitImplementationAuthorityRequired: true,
    );

    expect(result.readyForOwnerReview, isFalse);
  });

  test('policy cannot create persistence or mutate production', () {
    final result = policy.evaluate(
      monitorOnlyObservationComplete: true,
      coreStabilityVerified: true,
      persistedOperationalSignalsClear: true,
      incidentPersistenceAuthorityGapPresent: true,
      separateExplicitImplementationAuthorityRequired: true,
    );

    expect(result.writesFirestore, isFalse);
    expect(result.changesFirestoreRules, isFalse);
    expect(result.changesRolloutStage, isFalse);
    expect(result.changesAgentMode, isFalse);
    expect(result.changesEmergencyStop, isFalse);

    expect(policy.createsIncidentCollection, isFalse);
    expect(policy.writesFirestore, isFalse);
    expect(policy.changesFirestoreRules, isFalse);
    expect(policy.changesRolloutStage, isFalse);
    expect(policy.changesAgentMode, isFalse);
    expect(policy.changesEmergencyStop, isFalse);
  });

  test('policy cannot consume Permission or Approval authority', () {
    expect(policy.invokesPermissionEngine, isFalse);
    expect(policy.invokesApprovalEngine, isFalse);
    expect(policy.consumesApproval, isFalse);
    expect(policy.grantsPermission, isFalse);
  });
}
