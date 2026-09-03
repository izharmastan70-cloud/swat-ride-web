import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/services/agent_production_rollout_monitor_only_closeout_policy.dart';

void main() {
  const policy = AgentProductionRolloutMonitorOnlyCloseoutPolicy();

  test('clean MONITOR_ONLY observation closes observation only', () {
    final result = policy.evaluate(
      coreObservationStable: true,
      persistedOperationalSignalsClear: true,
      unclassifiedCriticalAuditCount: 0,
      openCriticalCrashCount: 0,
      emergencyOwnerAttentionCount: 0,
      incidentPersistenceAuthorityGapPresent: true,
      separateExplicitImplementationAuthorityRequired: true,
    );

    expect(result.monitorOnlyObservationComplete, isTrue);
    expect(
      result.status,
      AgentProductionRolloutMonitorOnlyCloseoutPolicy.cleanBlockedStatus,
    );
  });

  test('clean observation does not authorize SUGGEST_ONLY advancement', () {
    final result = policy.evaluate(
      coreObservationStable: true,
      persistedOperationalSignalsClear: true,
      unclassifiedCriticalAuditCount: 0,
      openCriticalCrashCount: 0,
      emergencyOwnerAttentionCount: 0,
      incidentPersistenceAuthorityGapPresent: true,
      separateExplicitImplementationAuthorityRequired: true,
    );

    expect(result.suggestOnlyAdvancementBlocked, isTrue);
    expect(result.canAdvanceToSuggestOnly, isFalse);
    expect(result.authorizesSuggestOnly, isFalse);
    expect(policy.authorizesSuggestOnly, isFalse);
  });

  test('AUTO remains blocked', () {
    final result = policy.evaluate(
      coreObservationStable: true,
      persistedOperationalSignalsClear: true,
      unclassifiedCriticalAuditCount: 0,
      openCriticalCrashCount: 0,
      emergencyOwnerAttentionCount: 0,
      incidentPersistenceAuthorityGapPresent: true,
      separateExplicitImplementationAuthorityRequired: true,
    );

    expect(result.autoAdvancementBlocked, isTrue);
    expect(result.canAdvanceToAuto, isFalse);
    expect(result.authorizesAuto, isFalse);
    expect(policy.authorizesAuto, isFalse);
  });

  test('unclassified CRITICAL audit prevents clean closeout', () {
    final result = policy.evaluate(
      coreObservationStable: true,
      persistedOperationalSignalsClear: true,
      unclassifiedCriticalAuditCount: 1,
      openCriticalCrashCount: 0,
      emergencyOwnerAttentionCount: 0,
      incidentPersistenceAuthorityGapPresent: true,
      separateExplicitImplementationAuthorityRequired: true,
    );

    expect(result.monitorOnlyObservationComplete, isFalse);
    expect(
      result.status,
      AgentProductionRolloutMonitorOnlyCloseoutPolicy.unsafeStatus,
    );
  });

  test('open critical crash prevents clean closeout', () {
    final result = policy.evaluate(
      coreObservationStable: true,
      persistedOperationalSignalsClear: true,
      unclassifiedCriticalAuditCount: 0,
      openCriticalCrashCount: 1,
      emergencyOwnerAttentionCount: 0,
      incidentPersistenceAuthorityGapPresent: true,
      separateExplicitImplementationAuthorityRequired: true,
    );

    expect(result.monitorOnlyObservationComplete, isFalse);
  });

  test('emergency Owner Attention prevents clean closeout', () {
    final result = policy.evaluate(
      coreObservationStable: true,
      persistedOperationalSignalsClear: true,
      unclassifiedCriticalAuditCount: 0,
      openCriticalCrashCount: 0,
      emergencyOwnerAttentionCount: 1,
      incidentPersistenceAuthorityGapPresent: true,
      separateExplicitImplementationAuthorityRequired: true,
    );

    expect(result.monitorOnlyObservationComplete, isFalse);
  });

  test('persistence authority gap remains explicit', () {
    final result = policy.evaluate(
      coreObservationStable: true,
      persistedOperationalSignalsClear: true,
      unclassifiedCriticalAuditCount: 0,
      openCriticalCrashCount: 0,
      emergencyOwnerAttentionCount: 0,
      incidentPersistenceAuthorityGapPresent: true,
      separateExplicitImplementationAuthorityRequired: true,
    );

    expect(result.incidentPersistenceAuthorityGapPresent, isTrue);
    expect(result.separateExplicitImplementationAuthorityRequired, isTrue);
  });

  test('policy has zero production mutation authority', () {
    final result = policy.evaluate(
      coreObservationStable: true,
      persistedOperationalSignalsClear: true,
      unclassifiedCriticalAuditCount: 0,
      openCriticalCrashCount: 0,
      emergencyOwnerAttentionCount: 0,
      incidentPersistenceAuthorityGapPresent: true,
      separateExplicitImplementationAuthorityRequired: true,
    );

    expect(result.writesFirestore, isFalse);
    expect(result.changesRolloutStage, isFalse);
    expect(result.changesAgentMode, isFalse);
    expect(result.changesEmergencyStop, isFalse);

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
