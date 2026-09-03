import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/constants/agent_security_incident_persistence_design_constants.dart';
import 'package:swat_ride/ai_agent/services/agent_security_incident_persistence_design_policy.dart';

void main() {
  const policy = AgentSecurityIncidentPersistenceDesignPolicy();

  test('design is explicitly not implemented or production active', () {
    final design = policy.evaluate();

    expect(
      design.status,
      AgentSecurityIncidentPersistenceDesignConstants.designStatus,
    );
    expect(design.liveRepositoryImplemented, isFalse);
    expect(design.firestoreRulesImplemented, isFalse);
    expect(design.productionPersistenceActive, isFalse);
  });

  test('proposed collection identifier is design metadata only', () {
    final design = policy.evaluate();

    expect(design.proposedCollectionId, 'agent_security_incidents');
    expect(design.createsFirestoreCollection, isFalse);
    expect(policy.createsFirestoreCollection, isFalse);
  });

  test('existing Phase 54 incident fields are preserved in design', () {
    final design = policy.evaluate();

    expect(
      design.immutableCreateFields,
      containsAll(<String>[
        'incidentId',
        'source',
        'sourceReferenceId',
        'pseudonymousSubjectRef',
        'createdAt',
      ]),
    );

    expect(
      design.lifecycleFields,
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

  test('security incident records are protected evidence', () {
    final design = policy.evaluate();

    expect(design.protectedEvidence, isTrue);
    expect(design.phase63RetentionAuthoritative, isTrue);
    expect(design.genericAutoDeleteAllowed, isFalse);
  });

  test('raw private and secret payload persistence is forbidden', () {
    final design = policy.evaluate();

    expect(design.rawPayloadPersistenceAllowed, isFalse);
    expect(
      design.forbiddenRawPayloadKinds,
      containsAll(<String>[
        'rawConversation',
        'rawCallTranscript',
        'rawStackTrace',
        'authToken',
        'sessionToken',
        'paymentCardNumber',
        'cvv',
        'childDirectIdentifier',
      ]),
    );
  });

  test('direct client and direct agent writes are forbidden', () {
    final design = policy.evaluate();

    expect(design.directClientWriteAllowed, isFalse);
    expect(design.directAgentWriteAllowed, isFalse);
  });

  test('cross-subject reads are forbidden', () {
    final design = policy.evaluate();

    expect(design.crossSubjectReadAllowed, isFalse);
    expect(design.requiredAuthorityControls, contains('crossSubjectIsolation'));
  });

  test('future implementation requires full authority chain', () {
    final design = policy.evaluate();

    expect(design.phase66ImplementationAuthorityRequired, isTrue);
    expect(
      design.requiredAuthorityControls,
      containsAll(<String>[
        'trustedOwnerOrSuperAdminBoundary',
        'permissionEngine',
        'approvalEngineForSensitiveMutation',
        'runtimeGate',
        'immutableAudit',
        'phase63ProtectedRetention',
        'idempotentMutation',
      ]),
    );
  });

  test('Phase 54 and Phase 65 safety boundaries remain authoritative', () {
    final design = policy.evaluate();

    expect(design.phase54FoundationPreserved, isTrue);
    expect(design.phase65SafetyAuthoritative, isTrue);
  });

  test('design step has zero live persistence or rule authority', () {
    final design = policy.evaluate();

    expect(design.writesFirestore, isFalse);
    expect(design.readsLiveFirestore, isFalse);
    expect(design.changesFirestoreRules, isFalse);

    expect(policy.designOnly, isTrue);
    expect(policy.writesFirestore, isFalse);
    expect(policy.readsLiveFirestore, isFalse);
    expect(policy.changesFirestoreRules, isFalse);
    expect(policy.deploysFirestoreRules, isFalse);
    expect(policy.createsRepository, isFalse);
    expect(policy.enablesRuntimePersistence, isFalse);
  });

  test('design step cannot mutate rollout or Emergency Stop', () {
    final design = policy.evaluate();

    expect(design.changesRolloutStage, isFalse);
    expect(design.changesAgentMode, isFalse);
    expect(design.changesEmergencyStop, isFalse);

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

    expect(design.suggestOnlyAuthorized, isFalse);
    expect(design.autoAuthorized, isFalse);
    expect(policy.authorizesSuggestOnly, isFalse);
    expect(policy.authorizesAuto, isFalse);
  });
}
