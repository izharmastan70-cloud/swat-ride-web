import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/constants/agent_security_incident_persistence_schema_design_constants.dart';
import 'package:swat_ride/ai_agent/services/agent_security_incident_persistence_schema_design_policy.dart';

void main() {
  const policy = AgentSecurityIncidentPersistenceSchemaDesignPolicy();

  test('schema design remains non-production design only', () {
    final design = policy.evaluate();

    expect(
      design.status,
      AgentSecurityIncidentPersistenceSchemaDesignConstants.designStatus,
    );
    expect(design.repositoryImplemented, isFalse);
    expect(design.rulesImplemented, isFalse);
    expect(design.productionActive, isFalse);
  });

  test('required create fields preserve Phase54 incident identity', () {
    final design = policy.evaluate();

    expect(
      design.requiredCreateFields,
      containsAll(<String>[
        'incidentId',
        'source',
        'sourceReferenceId',
        'pseudonymousSubjectRef',
        'status',
        'severity',
        'evidenceConfidence',
        'createdAt',
        'updatedAt',
        'evidenceReferenceCodes',
      ]),
    );
  });

  test('identity and origin fields are immutable after create', () {
    final design = policy.evaluate();

    expect(design.immutableAfterCreateFields, <String>{
      'incidentId',
      'source',
      'sourceReferenceId',
      'pseudonymousSubjectRef',
      'createdAt',
    });
  });

  test('lifecycle updates are explicitly controlled', () {
    final design = policy.evaluate();

    expect(
      design.controlledLifecycleFields,
      containsAll(<String>[
        'status',
        'severity',
        'evidenceConfidence',
        'updatedAt',
        'assignedResponderRef',
        'acknowledgedAt',
        'triagedAt',
        'resolvedAt',
        'closedAt',
        'evidenceReferenceCodes',
      ]),
    );
  });

  test('raw secrets and direct child identifiers are forbidden', () {
    final design = policy.evaluate();

    expect(design.rawPayloadPersistenceAllowed, isFalse);
    expect(
      design.forbiddenPersistedFields,
      containsAll(<String>[
        'rawConversation',
        'rawCallTranscript',
        'rawStackTrace',
        'authToken',
        'sessionToken',
        'apiKey',
        'paymentCardNumber',
        'cvv',
        'childName',
        'childPhone',
        'childExactAddress',
      ]),
    );
  });

  test('trusted mutation actor design is Owner or Super Admin only', () {
    final design = policy.evaluate();

    expect(design.allowedTrustedMutationActorRoles, <String>{
      'OWNER',
      'SUPER_ADMIN',
    });
    expect(design.createRequiresTrustedAuthority, isTrue);
    expect(design.updateRequiresTrustedAuthority, isTrue);
  });

  test('sensitive mutation checks require full authority chain', () {
    final design = policy.evaluate();

    expect(
      design.requiredSensitiveMutationChecks,
      containsAll(<String>[
        'freshTrustedIdentity',
        'permissionEngine',
        'approvalEngineWhenSensitive',
        'runtimeGate',
        'idempotencyKey',
        'exactIncidentBinding',
        'immutableAudit',
        'phase63ProtectedRetention',
      ]),
    );
  });

  test('protected evidence has no generic deletion path', () {
    final design = policy.evaluate();

    expect(design.deleteAllowed, isFalse);
    expect(design.genericAutoDeleteAllowed, isFalse);
    expect(design.collectionPurgeAllowed, isFalse);
    expect(design.batchDeleteAllowed, isFalse);

    expect(
      design.protectedEvidenceRetentionRules,
      containsAll(<String>[
        'noGenericAutoDelete',
        'noCollectionPurge',
        'noBatchDelete',
        'retentionReviewSignalOnly',
        'explicitProtectedEvidenceAuthorityRequired',
      ]),
    );
  });

  test('cross-subject reads remain forbidden', () {
    final design = policy.evaluate();

    expect(design.crossSubjectReadAllowed, isFalse);
  });

  test('design step creates no live collection or repository', () {
    final design = policy.evaluate();

    expect(design.createsCollection, isFalse);
    expect(design.writesFirestore, isFalse);
    expect(design.readsLiveFirestore, isFalse);
    expect(policy.createsCollection, isFalse);
    expect(policy.createsRepository, isFalse);
    expect(policy.writesFirestore, isFalse);
    expect(policy.readsLiveFirestore, isFalse);
  });

  test('design step cannot change rules or rollout', () {
    final design = policy.evaluate();

    expect(design.changesFirestoreRules, isFalse);
    expect(design.deploysFirestoreRules, isFalse);
    expect(design.changesRolloutStage, isFalse);
    expect(design.changesAgentMode, isFalse);
    expect(design.changesEmergencyStop, isFalse);

    expect(policy.changesFirestoreRules, isFalse);
    expect(policy.deploysFirestoreRules, isFalse);
    expect(policy.changesRolloutStage, isFalse);
    expect(policy.changesAgentMode, isFalse);
    expect(policy.changesEmergencyStop, isFalse);
  });

  test(
    'design step cannot create or consume Permission/Approval authority',
    () {
      final design = policy.evaluate();

      expect(design.createsApproval, isFalse);
      expect(design.consumesApproval, isFalse);
      expect(design.grantsPermission, isFalse);

      expect(policy.invokesPermissionEngine, isFalse);
      expect(policy.invokesApprovalEngine, isFalse);
      expect(policy.createsApproval, isFalse);
      expect(policy.consumesApproval, isFalse);
      expect(policy.grantsPermission, isFalse);
    },
  );

  test('SUGGEST_ONLY and AUTO remain unauthorized', () {
    final design = policy.evaluate();

    expect(design.authorizesSuggestOnly, isFalse);
    expect(design.authorizesAuto, isFalse);
    expect(policy.authorizesSuggestOnly, isFalse);
    expect(policy.authorizesAuto, isFalse);
  });
}
