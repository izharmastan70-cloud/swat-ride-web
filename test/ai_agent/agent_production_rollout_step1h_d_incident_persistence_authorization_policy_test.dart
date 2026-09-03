import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/services/agent_production_rollout_incident_persistence_authorization_policy.dart';

void main() {
  const policy = AgentProductionRolloutIncidentPersistenceAuthorizationPolicy();

  test(
    'Phase 54 production incident persistence remains intentionally absent',
    () {
      final decision = policy.evaluate();

      expect(decision.phase54FoundationOnly, isTrue);
      expect(decision.phase54ProductionPersistenceIntentionallyAbsent, isTrue);
      expect(decision.dedicatedIncidentCollectionExists, isFalse);
    },
  );

  test('Phase 65 remains handoff-only for production activation', () {
    final decision = policy.evaluate();

    expect(decision.phase65ProductionActivationAuthorityAbsent, isTrue);
    expect(decision.phase66OwnsControlledRollout, isTrue);
  });

  test('Phase 63 privacy and retention remain authoritative', () {
    final decision = policy.evaluate();

    expect(decision.phase63PrivacyRetentionRemainsAuthoritative, isTrue);
  });

  test('Phase 66 cannot invent dedicated incident persistence', () {
    final decision = policy.evaluate();

    expect(decision.phase66MayInventIncidentPersistence, isFalse);
    expect(decision.requiresSeparateExplicitImplementationAuthority, isTrue);
    expect(
      decision.disposition,
      AgentProductionRolloutIncidentPersistenceAuthorizationPolicy.disposition,
    );
  });

  test('existing persisted operational observation may continue', () {
    final decision = policy.evaluate();

    expect(decision.existingPersistedObservationMayContinue, isTrue);
    expect(decision.persistedObservationSources, <String>{
      'agent_audit_logs',
      'agent_crash_events',
      'agent_owner_attention_inbox',
    });
  });

  test('SUGGEST_ONLY remains blocked', () {
    final decision = policy.evaluate();

    expect(decision.blocksSuggestOnly, isTrue);
    expect(decision.authorizesSuggestOnly, isFalse);
    expect(policy.authorizesSuggestOnly, isFalse);
  });

  test('AUTO remains blocked', () {
    final decision = policy.evaluate();

    expect(decision.blocksAuto, isTrue);
    expect(decision.authorizesAuto, isFalse);
    expect(policy.authorizesAuto, isFalse);
  });

  test('decision cannot mutate production or persistence', () {
    final decision = policy.evaluate();

    expect(decision.createsIncidentCollection, isFalse);
    expect(decision.writesFirestore, isFalse);
    expect(decision.changesFirestoreRules, isFalse);
    expect(decision.changesRolloutStage, isFalse);
    expect(decision.changesAgentMode, isFalse);
    expect(decision.changesEmergencyStop, isFalse);

    expect(policy.createsIncidentCollection, isFalse);
    expect(policy.writesFirestore, isFalse);
    expect(policy.changesFirestoreRules, isFalse);
    expect(policy.changesRolloutStage, isFalse);
    expect(policy.changesAgentMode, isFalse);
    expect(policy.changesEmergencyStop, isFalse);
  });

  test('decision cannot consume Permission or Approval authority', () {
    expect(policy.invokesPermissionEngine, isFalse);
    expect(policy.invokesApprovalEngine, isFalse);
    expect(policy.consumesApproval, isFalse);
    expect(policy.grantsPermission, isFalse);
  });
}
