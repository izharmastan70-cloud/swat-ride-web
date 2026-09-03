import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/services/agent_security_incident_persistence_implementation_readiness_policy.dart';

void main() {
  const policy =
      AgentSecurityIncidentPersistenceImplementationReadinessPolicy();

  test(
    'complete design becomes ready for Owner implementation decision only',
    () {
      final result = policy.evaluate(
        designFoundationComplete: true,
        schemaDesignComplete: true,
        privacyRetentionDesignComplete: true,
        mutationAuthorityDesignComplete: true,
      );

      expect(
        result.status,
        AgentSecurityIncidentPersistenceImplementationReadinessPolicy
            .readyAwaitingAuthorization,
      );
      expect(result.readyForOwnerImplementationDecision, isTrue);
    },
  );

  test('fresh Owner implementation authorization is required and absent', () {
    final result = policy.evaluate(
      designFoundationComplete: true,
      schemaDesignComplete: true,
      privacyRetentionDesignComplete: true,
      mutationAuthorityDesignComplete: true,
    );

    expect(result.freshOwnerImplementationAuthorizationRequired, isTrue);
    expect(result.freshOwnerImplementationAuthorizationPresent, isFalse);
  });

  test('repository implementation is not authorized', () {
    final result = policy.evaluate(
      designFoundationComplete: true,
      schemaDesignComplete: true,
      privacyRetentionDesignComplete: true,
      mutationAuthorityDesignComplete: true,
    );

    expect(result.repositoryImplementationAuthorized, isFalse);
    expect(result.createsRepository, isFalse);
    expect(policy.createsRepository, isFalse);
  });

  test('Firestore rules implementation is not authorized', () {
    final result = policy.evaluate(
      designFoundationComplete: true,
      schemaDesignComplete: true,
      privacyRetentionDesignComplete: true,
      mutationAuthorityDesignComplete: true,
    );

    expect(result.firestoreRulesImplementationAuthorized, isFalse);
    expect(result.changesFirestoreRules, isFalse);
    expect(result.deploysFirestoreRules, isFalse);
    expect(policy.changesFirestoreRules, isFalse);
    expect(policy.deploysFirestoreRules, isFalse);
  });

  test(
    'collection activation and production persistence are not authorized',
    () {
      final result = policy.evaluate(
        designFoundationComplete: true,
        schemaDesignComplete: true,
        privacyRetentionDesignComplete: true,
        mutationAuthorityDesignComplete: true,
      );

      expect(result.collectionActivationAuthorized, isFalse);
      expect(result.productionPersistenceAuthorized, isFalse);
      expect(result.createsCollection, isFalse);
      expect(policy.createsCollection, isFalse);
    },
  );

  test('MONITOR_ONLY remains locked', () {
    final result = policy.evaluate(
      designFoundationComplete: true,
      schemaDesignComplete: true,
      privacyRetentionDesignComplete: true,
      mutationAuthorityDesignComplete: true,
    );

    expect(result.keepMonitorOnly, isTrue);
    expect(result.changesRolloutStage, isFalse);
    expect(result.changesAgentMode, isFalse);
  });

  test('SUGGEST_ONLY and AUTO remain blocked', () {
    final result = policy.evaluate(
      designFoundationComplete: true,
      schemaDesignComplete: true,
      privacyRetentionDesignComplete: true,
      mutationAuthorityDesignComplete: true,
    );

    expect(result.suggestOnlyBlocked, isTrue);
    expect(result.autoBlocked, isTrue);
    expect(result.authorizesSuggestOnly, isFalse);
    expect(result.authorizesAuto, isFalse);
    expect(policy.authorizesSuggestOnly, isFalse);
    expect(policy.authorizesAuto, isFalse);
  });

  test('incomplete design cannot be implementation-decision ready', () {
    final result = policy.evaluate(
      designFoundationComplete: true,
      schemaDesignComplete: false,
      privacyRetentionDesignComplete: true,
      mutationAuthorityDesignComplete: true,
    );

    expect(
      result.status,
      AgentSecurityIncidentPersistenceImplementationReadinessPolicy
          .designIncomplete,
    );
    expect(result.readyForOwnerImplementationDecision, isFalse);
  });

  test('gate has zero Firebase or Emergency Stop mutation authority', () {
    final result = policy.evaluate(
      designFoundationComplete: true,
      schemaDesignComplete: true,
      privacyRetentionDesignComplete: true,
      mutationAuthorityDesignComplete: true,
    );

    expect(result.writesFirestore, isFalse);
    expect(result.readsLiveFirestore, isFalse);
    expect(result.changesEmergencyStop, isFalse);

    expect(policy.writesFirestore, isFalse);
    expect(policy.readsLiveFirestore, isFalse);
    expect(policy.changesEmergencyStop, isFalse);
  });

  test('gate cannot create or consume Permission/Approval authority', () {
    final result = policy.evaluate(
      designFoundationComplete: true,
      schemaDesignComplete: true,
      privacyRetentionDesignComplete: true,
      mutationAuthorityDesignComplete: true,
    );

    expect(result.createsApproval, isFalse);
    expect(result.consumesApproval, isFalse);
    expect(result.grantsPermission, isFalse);

    expect(policy.invokesPermissionEngine, isFalse);
    expect(policy.invokesApprovalEngine, isFalse);
    expect(policy.createsApproval, isFalse);
    expect(policy.consumesApproval, isFalse);
    expect(policy.grantsPermission, isFalse);
  });
}
