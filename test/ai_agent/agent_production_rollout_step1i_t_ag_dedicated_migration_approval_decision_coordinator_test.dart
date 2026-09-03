import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/models/agent_approval_request.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_fresh_owner_claim_verification_result.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_role_inventory_migration_central_approval_request.dart';
import 'package:swat_ride/ai_agent/services/agent_security_incident_role_inventory_migration_approval_decision_coordinator.dart';
import 'package:swat_ride/ai_agent/services/agent_security_incident_role_inventory_migration_central_approval_gateway.dart';

void main() {
  const String currentAdminId = 'owner-firebase-uid-001';

  String sha(String value) => sha256.convert(utf8.encode(value)).toString();

  AgentSecurityIncidentRoleInventoryMigrationCentralApprovalRequest expected() {
    const String bindingSha =
        'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

    final String ownerSha = sha(currentAdminId);

    return AgentSecurityIncidentRoleInventoryMigrationCentralApprovalRequest(
      roleId: 'security_incident_agent',
      actionId: 'security_incident.attach_runtime',
      module: 'security_incident',
      reason:
          'Owner approval required for exact 22-to-23 Security Incident role-inventory migration only.',
      risk: 'CRITICAL',
      requestedBy:
          'phase66_migration_coordinator_sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
      ownerApproverReferenceSha256: ownerSha,
      actionScope: <String, dynamic>{
        'operation': 'MIGRATE_SECURITY_INCIDENT_ROLE_INVENTORY_22_TO_23',
        'bindingFingerprintSha256': bindingSha,
        'requestPrincipal': 'PHASE66_MIGRATION_COORDINATOR',
        'ownerApproverReferenceSha256': ownerSha,
        'currentInventoryVersion': 'phase66_roles_v1_22',
        'proposedInventoryVersion': 'phase66_roles_v2_23_security_incident',
        'currentRoleCount': 22,
        'proposedRoleCount': 23,
        'currentInventoryFingerprintSha256':
            '3ba eafc2e8ce82d138f884f6f3990c4ff644d981be864a35182c5475997b1f1d'
                .replaceAll(' ', ''),
        'proposedInventoryFingerprintSha256':
            'd16c6ff23b0d56a9e3b76146eefe22832d86196dee48bb05d6bc0129f48e2f2a',
        'currentControlFingerprintSha256':
            'db72e5c0888ea558c07ef002d059c3d92f909fb77f223725a029f35fa6ee9b5e',
        'preconditionEvidenceFingerprintSha256':
            '6cb1df3565e6a9130cadb54d888e6cfe89d7ed393dda369a54ad32d40d937240',
        'currentGuardRevision': 2,
        'proposedGuardRevision': 3,
        'targetRoleId': 'security_incident_agent',
        'targetModule': 'security_incident',
        'targetActionId': 'security_incident.attach_runtime',
        'requestedRolloutStage': 'MONITOR_ONLY',
        'proposedRoleEnabled': false,
        'oldGuardImmutable': true,
        'oldArmingTokenImmutable': true,
        'oldActivationReceiptImmutable': true,
        'existingActivationTokenReuseAllowed': false,
        'repositoryAttachAuthorized': false,
        'repositoryArmAuthorized': false,
        'firstIncidentWriteAuthorized': false,
        'authorizesSuggestOnly': false,
        'authorizesAuto': false,
        'selfApprovalAllowed': false,
      },
      validity: const Duration(minutes: 15),
      bindingFingerprintSha256: bindingSha,
    );
  }

  AgentApprovalRequest observed({
    Map<String, dynamic>? actionScope,
    String status = AgentApprovalStatus.pending,
    String? decidedBy,
  }) {
    final AgentSecurityIncidentRoleInventoryMigrationCentralApprovalRequest
    request = expected();

    final DateTime createdAt = DateTime.now().subtract(
      const Duration(minutes: 1),
    );

    return AgentApprovalRequest(
      approvalId: 'pending-migration-approval-001',
      roleId: request.roleId,
      actionId: request.actionId,
      module: request.module,
      reason: request.reason,
      risk: request.risk,
      requestedBy: request.requestedBy,
      actionScope:
          actionScope ?? Map<String, dynamic>.from(request.actionScope),
      status: status,
      createdAt: createdAt,
      expiresAt: createdAt.add(const Duration(minutes: 15)),
      decidedAt: decidedBy == null ? null : DateTime.now(),
      consumedAt: null,
      decidedBy: decidedBy,
      decisionNote: null,
    );
  }

  AgentSecurityIncidentFreshOwnerClaimVerificationResult fresh({
    bool verified = true,
  }) {
    return AgentSecurityIncidentFreshOwnerClaimVerificationResult(
      status: verified
          ? AgentSecurityIncidentFreshOwnerClaimVerificationStatus.verified
          : AgentSecurityIncidentFreshOwnerClaimVerificationStatus.blocked,
      reasonCode: verified
          ? 'fresh_authenticated_super_admin_custom_claim_verified'
          : 'fresh_login_required',
      superAdminAccessVerified: verified,
      roleClaimVerified: verified,
      uidBindingVerified: verified,
      customClaimSourceVerified: verified,
      freshLoginVerified: verified,
      authAgeBucket: verified
          ? AgentSecurityIncidentFreshOwnerAuthAgeBucket.fresh
          : AgentSecurityIncidentFreshOwnerAuthAgeBucket.stale,
      boundedAuthAgeSeconds: verified ? 60 : 301,
    );
  }

  test('watchExactPending filters unrelated approval', () async {
    final fake = _FakeGateway(
      pending: <AgentApprovalRequest>[
        observed(),
        AgentApprovalRequest(
          approvalId: 'other',
          roleId: 'support_agent',
          actionId: 'support.read',
          module: 'support',
          reason: 'other',
          risk: 'LOW',
          requestedBy: 'other',
          actionScope: const <String, dynamic>{'x': 1},
          status: AgentApprovalStatus.pending,
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(minutes: 10)),
        ),
      ],
    );

    final coordinator =
        AgentSecurityIncidentRoleInventoryMigrationApprovalDecisionCoordinator(
          gateway: fake,
          freshOwnerVerifier: (String _) async => fresh(),
        );

    final items = await coordinator
        .watchExactPending(expected: expected())
        .first;

    expect(items, hasLength(1));
    expect(items.single.approvalId, 'pending-migration-approval-001');
  });

  test('default disarmed coordinator cannot approve', () async {
    final fake = _FakeGateway(pending: <AgentApprovalRequest>[observed()]);

    final coordinator =
        AgentSecurityIncidentRoleInventoryMigrationApprovalDecisionCoordinator(
          gateway: fake,
          freshOwnerVerifier: (String _) async => fresh(),
        );

    expect(coordinator.defaultFailClosed, isTrue);

    await expectLater(
      coordinator.approveObserved(
        observed: observed(),
        expected: expected(),
        currentAdminId: currentAdminId,
      ),
      throwsStateError,
    );

    expect(fake.approveCalls, 0);
    expect(fake.rejectCalls, 0);
  });

  test('armed fresh Owner APPROVE calls only central approve', () async {
    final fake = _FakeGateway(pending: <AgentApprovalRequest>[observed()]);

    final coordinator =
        AgentSecurityIncidentRoleInventoryMigrationApprovalDecisionCoordinator(
          gateway: fake,
          freshOwnerVerifier: (String _) async => fresh(),
          executionArmed: true,
        );

    final result = await coordinator.approveObserved(
      observed: observed(),
      expected: expected(),
      currentAdminId: currentAdminId,
    );

    expect(result.allowed, isTrue);
    expect(fake.approveCalls, 1);
    expect(fake.rejectCalls, 0);
    expect(fake.lastDecidedBy, 'phase66_owner_sha256:${sha(currentAdminId)}');
  });

  test('armed fresh Owner REJECT calls only central reject', () async {
    final fake = _FakeGateway(pending: <AgentApprovalRequest>[observed()]);

    final coordinator =
        AgentSecurityIncidentRoleInventoryMigrationApprovalDecisionCoordinator(
          gateway: fake,
          freshOwnerVerifier: (String _) async => fresh(),
          executionArmed: true,
        );

    final result = await coordinator.rejectObserved(
      observed: observed(),
      expected: expected(),
      currentAdminId: currentAdminId,
    );

    expect(result.allowed, isTrue);
    expect(fake.approveCalls, 0);
    expect(fake.rejectCalls, 1);
  });

  test('stale Owner verification blocks central mutation', () async {
    final fake = _FakeGateway(pending: <AgentApprovalRequest>[observed()]);

    final coordinator =
        AgentSecurityIncidentRoleInventoryMigrationApprovalDecisionCoordinator(
          gateway: fake,
          freshOwnerVerifier: (String _) async => fresh(verified: false),
          executionArmed: true,
        );

    await expectLater(
      coordinator.approveObserved(
        observed: observed(),
        expected: expected(),
        currentAdminId: currentAdminId,
      ),
      throwsStateError,
    );

    expect(fake.approveCalls, 0);
    expect(fake.rejectCalls, 0);
  });

  test('scope mismatch blocks central mutation', () async {
    final fake = _FakeGateway();

    final coordinator =
        AgentSecurityIncidentRoleInventoryMigrationApprovalDecisionCoordinator(
          gateway: fake,
          freshOwnerVerifier: (String _) async => fresh(),
          executionArmed: true,
        );

    final Map<String, dynamic> wrongScope = Map<String, dynamic>.from(
      expected().actionScope,
    )..['proposedRoleEnabled'] = true;

    await expectLater(
      coordinator.approveObserved(
        observed: observed(actionScope: wrongScope),
        expected: expected(),
        currentAdminId: currentAdminId,
      ),
      throwsFormatException,
    );

    expect(fake.approveCalls, 0);
  });

  test('already decided approval blocks mutation', () async {
    final fake = _FakeGateway();

    final coordinator =
        AgentSecurityIncidentRoleInventoryMigrationApprovalDecisionCoordinator(
          gateway: fake,
          freshOwnerVerifier: (String _) async => fresh(),
          executionArmed: true,
        );

    await expectLater(
      coordinator.approveObserved(
        observed: observed(
          status: AgentApprovalStatus.approved,
          decidedBy: 'phase66_owner_sha256:${sha(currentAdminId)}',
        ),
        expected: expected(),
        currentAdminId: currentAdminId,
      ),
      throwsFormatException,
    );

    expect(fake.approveCalls, 0);
  });

  test('coordinator exposes no create/consume/migration authority', () {
    final fake = _FakeGateway();

    final coordinator =
        AgentSecurityIncidentRoleInventoryMigrationApprovalDecisionCoordinator(
          gateway: fake,
          freshOwnerVerifier: (String _) async => fresh(),
        );

    expect(coordinator.createsCentralApproval, isFalse);
    expect(coordinator.consumesCentralApproval, isFalse);
    expect(coordinator.executesMigration, isFalse);
    expect(coordinator.createsRole, isFalse);
    expect(coordinator.enablesRole, isFalse);
    expect(coordinator.mutatesGuard, isFalse);
    expect(coordinator.createsArmingToken, isFalse);
    expect(coordinator.reusesExistingActivationToken, isFalse);
    expect(coordinator.attachesRuntime, isFalse);
    expect(coordinator.armsRepository, isFalse);
    expect(coordinator.writesIncident, isFalse);
    expect(coordinator.authorizesSuggestOnly, isFalse);
    expect(coordinator.authorizesAuto, isFalse);
  });
}

class _FakeGateway
    implements
        AgentSecurityIncidentRoleInventoryMigrationCentralApprovalGateway {
  _FakeGateway({this._pending = const <AgentApprovalRequest>[]});

  final List<AgentApprovalRequest> _pending;

  int approveCalls = 0;
  int rejectCalls = 0;
  String lastApprovalId = '';
  String lastDecidedBy = '';

  @override
  Stream<List<AgentApprovalRequest>> watchPendingRequests() {
    return Stream<List<AgentApprovalRequest>>.value(
      List<AgentApprovalRequest>.from(_pending),
    );
  }

  @override
  Future<void> approve({
    required String approvalId,
    required String decidedBy,
  }) async {
    approveCalls += 1;
    lastApprovalId = approvalId;
    lastDecidedBy = decidedBy;
  }

  @override
  Future<void> reject({
    required String approvalId,
    required String decidedBy,
  }) async {
    rejectCalls += 1;
    lastApprovalId = approvalId;
    lastDecidedBy = decidedBy;
  }
}
