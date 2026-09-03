import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/services/agent_production_rollout_incident_observability_authority_policy.dart';

void main() {
  const AgentProductionRolloutIncidentObservabilityAuthorityPolicy policy =
      AgentProductionRolloutIncidentObservabilityAuthorityPolicy();

  test('Phase 54 incident response remains foundation-only', () {
    final report = policy.evaluate();

    expect(report.phase54FoundationOnly, isTrue);
    expect(
      report.disposition,
      AgentProductionRolloutIncidentObservabilityAuthorityPolicy.disposition,
    );
  });

  test('dedicated incident persistence authority is absent', () {
    final report = policy.evaluate();

    expect(report.dedicatedIncidentPersistenceAuthorityPresent, isFalse);
    expect(report.newIncidentCollectionCreationAuthorized, isFalse);
    expect(policy.inventsIncidentCollection, isFalse);
  });

  test('existing persisted operational safety sources are explicit', () {
    final report = policy.evaluate();

    expect(report.persistedOperationalSignalSources, <String>{
      'agent_audit_logs',
      'agent_crash_events',
      'agent_owner_attention_inbox',
    });
  });

  test('absence of dedicated store never means zero incidents', () {
    final report = policy.evaluate();

    expect(report.claimsDedicatedIncidentCountZero, isFalse);
  });

  test(
    'MONITOR_ONLY observation may continue without inventing persistence',
    () {
      final report = policy.evaluate();

      expect(report.monitorOnlyObservationCanContinue, isTrue);
      expect(report.changesProductionState, isFalse);
    },
  );

  test(
    'SUGGEST_ONLY remains blocked by unresolved persistence authority gap',
    () {
      final report = policy.evaluate();

      expect(report.blocksSuggestOnly, isTrue);
      expect(report.authorizesSuggestOnly, isFalse);
      expect(policy.authorizesSuggestOnly, isFalse);
    },
  );

  test('AUTO remains blocked', () {
    final report = policy.evaluate();

    expect(report.blocksAuto, isTrue);
    expect(report.authorizesAuto, isFalse);
    expect(policy.authorizesAuto, isFalse);
  });

  test('authority policy cannot write, change rules, mode or rollout', () {
    final report = policy.evaluate();

    expect(report.writesFirestore, isFalse);
    expect(report.changesFirestoreRules, isFalse);
    expect(report.changesRolloutStage, isFalse);
    expect(report.changesAgentMode, isFalse);
    expect(policy.writesFirestore, isFalse);
    expect(policy.changesFirestoreRules, isFalse);
    expect(policy.changesRolloutStage, isFalse);
    expect(policy.changesAgentMode, isFalse);
  });

  test('authority policy cannot consume Permission or Approval authority', () {
    expect(policy.invokesPermissionEngine, isFalse);
    expect(policy.invokesApprovalEngine, isFalse);
    expect(policy.consumesApproval, isFalse);
    expect(policy.grantsPermission, isFalse);
  });
}
