import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_persistence_implementation_state.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_persistence_write_authorization.dart';
import 'package:swat_ride/ai_agent/services/agent_security_incident_persistence_write_gate.dart';
import 'package:swat_ride/ai_agent/services/agent_security_incident_repository.dart';

void main() {
  const gate = AgentSecurityIncidentPersistenceWriteGate();

  AgentSecurityIncidentPersistenceWriteAuthorization validAuthorization({
    String operation = AgentSecurityIncidentPersistenceOperation.create,
    String incidentId = 'incident-001',
    String actorRole = AgentSecurityIncidentPersistenceActorRole.owner,
    bool freshIdentity = true,
    bool permissionGranted = true,
    bool approvalVerified = true,
    bool runtimeGateAllowed = true,
    bool immutableAuditReady = true,
  }) {
    final DateTime now = DateTime.utc(2026, 8, 26, 16);

    return AgentSecurityIncidentPersistenceWriteAuthorization(
      operation: operation,
      incidentId: incidentId,
      actorRole: actorRole,
      actorRef: 'owner-ref-001',
      idempotencyKey: 'incident-write-001',
      issuedAtUtc: now.subtract(const Duration(seconds: 30)),
      expiresAtUtc: now.add(const Duration(minutes: 2)),
      freshTrustedIdentityVerified: freshIdentity,
      permissionGranted: permissionGranted,
      sensitiveApprovalVerified: approvalVerified,
      runtimeGateAllowed: runtimeGateAllowed,
      immutableAuditReady: immutableAuditReady,
    );
  }

  test('trusted Owner authorization passes exact create binding', () {
    final authorization = validAuthorization();

    expect(
      () => gate.requireAuthorized(
        authorization: authorization,
        expectedOperation: AgentSecurityIncidentPersistenceOperation.create,
        expectedIncidentId: 'incident-001',
        nowUtc: DateTime.utc(2026, 8, 26, 16),
      ),
      returnsNormally,
    );
  });

  test('Super Admin is also an allowed trusted actor role', () {
    final authorization = validAuthorization(
      actorRole: AgentSecurityIncidentPersistenceActorRole.superAdmin,
    );

    expect(
      () => gate.requireAuthorized(
        authorization: authorization,
        expectedOperation: AgentSecurityIncidentPersistenceOperation.create,
        expectedIncidentId: 'incident-001',
        nowUtc: DateTime.utc(2026, 8, 26, 16),
      ),
      returnsNormally,
    );
  });

  test('untrusted actor role is blocked', () {
    final authorization = validAuthorization(actorRole: 'ADMIN');

    expect(
      () => gate.requireAuthorized(
        authorization: authorization,
        expectedOperation: AgentSecurityIncidentPersistenceOperation.create,
        expectedIncidentId: 'incident-001',
        nowUtc: DateTime.utc(2026, 8, 26, 16),
      ),
      throwsA(isA<AgentSecurityIncidentPersistenceAuthorizationException>()),
    );
  });

  test('incident binding mismatch is blocked', () {
    final authorization = validAuthorization();

    expect(
      () => gate.requireAuthorized(
        authorization: authorization,
        expectedOperation: AgentSecurityIncidentPersistenceOperation.create,
        expectedIncidentId: 'incident-002',
        nowUtc: DateTime.utc(2026, 8, 26, 16),
      ),
      throwsA(isA<AgentSecurityIncidentPersistenceAuthorizationException>()),
    );
  });

  test('missing Permission authority is blocked', () {
    final authorization = validAuthorization(permissionGranted: false);

    expect(
      () => gate.requireAuthorized(
        authorization: authorization,
        expectedOperation: AgentSecurityIncidentPersistenceOperation.create,
        expectedIncidentId: 'incident-001',
        nowUtc: DateTime.utc(2026, 8, 26, 16),
      ),
      throwsA(isA<AgentSecurityIncidentPersistenceAuthorizationException>()),
    );
  });

  test('missing sensitive Approval verification is blocked', () {
    final authorization = validAuthorization(approvalVerified: false);

    expect(
      () => gate.requireAuthorized(
        authorization: authorization,
        expectedOperation: AgentSecurityIncidentPersistenceOperation.create,
        expectedIncidentId: 'incident-001',
        nowUtc: DateTime.utc(2026, 8, 26, 16),
      ),
      throwsA(isA<AgentSecurityIncidentPersistenceAuthorizationException>()),
    );
  });

  test('runtime gate or immutable audit readiness failure blocks', () {
    final noRuntime = validAuthorization(runtimeGateAllowed: false);

    final noAudit = validAuthorization(immutableAuditReady: false);

    for (final authorization
        in <AgentSecurityIncidentPersistenceWriteAuthorization>[
          noRuntime,
          noAudit,
        ]) {
      expect(
        () => gate.requireAuthorized(
          authorization: authorization,
          expectedOperation: AgentSecurityIncidentPersistenceOperation.create,
          expectedIncidentId: 'incident-001',
          nowUtc: DateTime.utc(2026, 8, 26, 16),
        ),
        throwsA(isA<AgentSecurityIncidentPersistenceAuthorizationException>()),
      );
    }
  });

  test('stale authorization is blocked', () {
    final DateTime now = DateTime.utc(2026, 8, 26, 16);

    final authorization = AgentSecurityIncidentPersistenceWriteAuthorization(
      operation: AgentSecurityIncidentPersistenceOperation.create,
      incidentId: 'incident-001',
      actorRole: AgentSecurityIncidentPersistenceActorRole.owner,
      actorRef: 'owner-ref-001',
      idempotencyKey: 'incident-write-001',
      issuedAtUtc: now.subtract(const Duration(minutes: 10)),
      expiresAtUtc: now.subtract(const Duration(minutes: 5)),
      freshTrustedIdentityVerified: true,
      permissionGranted: true,
      sensitiveApprovalVerified: true,
      runtimeGateAllowed: true,
      immutableAuditReady: true,
    );

    expect(
      () => gate.requireAuthorized(
        authorization: authorization,
        expectedOperation: AgentSecurityIncidentPersistenceOperation.create,
        expectedIncidentId: 'incident-001',
        nowUtc: now,
      ),
      throwsA(isA<AgentSecurityIncidentPersistenceAuthorizationException>()),
    );
  });

  test('repository defaults fail closed and exposes no delete authority', () {
    expect(AgentSecurityIncidentRepository.defaultExecutionArmed, isFalse);
    expect(
      AgentSecurityIncidentRepository.collectionName,
      'agent_security_incidents',
    );
    expect(
      AgentSecurityIncidentRepository.persistedFields,
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
        'assignedResponderRef',
        'acknowledgedAt',
        'triagedAt',
        'resolvedAt',
        'closedAt',
      ]),
    );
  });

  test('implementation state is code-ready but not live', () {
    expect(
      AgentSecurityIncidentPersistenceImplementationState
          .repositoryCodeImplemented,
      isTrue,
    );
    expect(
      AgentSecurityIncidentPersistenceImplementationState
          .firestoreRulesSourceImplemented,
      isTrue,
    );
    expect(
      AgentSecurityIncidentPersistenceImplementationState
          .phase63RetentionMappingImplemented,
      isTrue,
    );

    expect(
      AgentSecurityIncidentPersistenceImplementationState
          .repositoryRuntimeAttached,
      isFalse,
    );
    // Phase66 Step1I-H V2 subsequently deployed the exact audited rules source.
    expect(
      AgentSecurityIncidentPersistenceImplementationState
          .firestoreRulesDeployed,
      isTrue,
    );
    expect(
      AgentSecurityIncidentPersistenceImplementationState
          .liveCollectionActivated,
      isFalse,
    );
    expect(
      AgentSecurityIncidentPersistenceImplementationState
          .productionPersistenceActive,
      isFalse,
    );
    // Phase66 Step1I-F-B supersedes the earlier offline Step1I-E state:
    // atomic incident + immutable audit transaction code is now implemented,
    // while runtime attachment / deployment / production activation remain false.
    expect(
      AgentSecurityIncidentPersistenceImplementationState
          .atomicImmutableAuditPersistenceImplemented,
      isTrue,
    );
  });

  test('Firestore rules source contains protected incident boundary', () {
    final String rules = File('firestore.rules').readAsStringSync();

    expect(
      rules.contains('match /agent_security_incidents/{incidentId}'),
      isTrue,
    );
    expect(
      rules.contains('request.resource.data.incidentId == incidentId'),
      isTrue,
    );
    expect(
      rules.contains(
        'request.resource.data.sourceReferenceId == resource.data.sourceReferenceId',
      ),
      isTrue,
    );
    expect(rules.contains('allow delete: if false;'), isTrue);
  });

  test('Phase63 retention map classifies incidents as security evidence', () {
    final String retention = File(
      'lib/ai_agent/constants/agent_retention_record_map.dart',
    ).readAsStringSync();

    expect(
      retention.contains(
        "'agent_security_incidents': AgentRetentionCategory.securityEvidence",
      ),
      isTrue,
    );
  });

  test('offline implementation does not authorize rollout advancement', () {
    expect(
      AgentSecurityIncidentPersistenceImplementationState.changesRolloutStage,
      isFalse,
    );
    expect(
      AgentSecurityIncidentPersistenceImplementationState.changesAgentMode,
      isFalse,
    );
    expect(
      AgentSecurityIncidentPersistenceImplementationState.changesEmergencyStop,
      isFalse,
    );
    expect(
      AgentSecurityIncidentPersistenceImplementationState.authorizesSuggestOnly,
      isFalse,
    );
    expect(
      AgentSecurityIncidentPersistenceImplementationState.authorizesAuto,
      isFalse,
    );

    expect(gate.grantsPermission, isFalse);
    expect(gate.consumesApproval, isFalse);
    expect(gate.createsApproval, isFalse);
    expect(gate.overridesRuntimeGate, isFalse);
  });
}
