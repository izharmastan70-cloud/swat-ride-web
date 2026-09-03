import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/models/agent_approval_request.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_fresh_owner_claim_verification_result.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_post_rebind_enable_approval_decision_authorization.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_post_rebind_enable_execution_contract.dart';
import 'package:swat_ride/ai_agent/services/agent_security_incident_post_migration_rebind_approval_decision_policy.dart';
import 'package:swat_ride/ai_agent/services/agent_security_incident_post_rebind_enable_approval_decision_coordinator.dart';
import 'package:swat_ride/ai_agent/services/agent_security_incident_post_rebind_enable_approval_decision_policy.dart';
import 'package:swat_ride/ai_agent/services/agent_security_incident_post_rebind_enable_central_approval_gateway.dart';

void main() {
  const String currentAdminId = 'owner-firebase-uid-001';

  String sha(String value) => sha256.convert(utf8.encode(value)).toString();

  final String ownerSha = sha(currentAdminId);

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

  AgentApprovalRequest historicalMigration() {
    final DateTime created = DateTime.now().subtract(
      const Duration(minutes: 30),
    );

    return AgentApprovalRequest(
      approvalId: AgentSecurityIncidentPostMigrationRebindApprovalDecisionPolicy
          .historicalMigrationApprovalId,
      roleId: 'security_incident_agent',
      actionId: 'security_incident.attach_runtime',
      module: 'security_incident',
      reason: 'historical migration evidence',
      risk: 'CRITICAL',
      requestedBy:
          'phase66_migration_coordinator_sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
      actionScope: <String, dynamic>{
        'operation':
            AgentSecurityIncidentPostMigrationRebindApprovalDecisionPolicy
                .historicalMigrationOperation,
        'ownerApproverReferenceSha256': ownerSha,
      },
      status: AgentApprovalStatus.consumed,
      createdAt: created,
      expiresAt: created.add(const Duration(minutes: 15)),
      decidedAt: created.add(const Duration(minutes: 1)),
      consumedAt: created.add(const Duration(minutes: 2)),
      decidedBy: 'phase66_owner_sha256:$ownerSha',
      decisionNote: 'approved and consumed historically',
    );
  }

  AgentApprovalRequest pendingEnable({
    Map<String, dynamic>? scopeOverride,
    String? requestedBy,
  }) {
    final DateTime created = DateTime.now();

    final Map<String, dynamic> scope = <String, dynamic>{
      'operation': AgentSecurityIncidentPostRebindEnableExecutionContract
          .enableOperation,
      'roleId': AgentSecurityIncidentPostRebindEnableExecutionContract.roleId,
      'module': AgentSecurityIncidentPostRebindEnableExecutionContract.module,
      'actionId':
          AgentSecurityIncidentPostRebindEnableExecutionContract.targetActionId,
      'rolloutStage':
          AgentSecurityIncidentPostRebindEnableExecutionContract.rolloutStage,
      'roleCount':
          AgentSecurityIncidentPostRebindEnableExecutionContract.roleCount,
      'authorityManifestRevision':
          AgentSecurityIncidentPostRebindEnableExecutionContract
              .authorityManifestRevision,
      'guardRevision':
          AgentSecurityIncidentPostRebindEnableExecutionContract.guardRevision,
      'rebindReceiptIdSha256':
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      'replacementTokenIdSha256':
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'freshOwnerVerifiedAtApproval': true,
      'explicitOwnerApproval': true,
      'selfApprovalAllowed': false,
      'migrationApprovalReuseAllowed': false,
      'rebindApprovalReuseAllowed': false,
      'oldArmingTokenReuseAllowed': false,
      'replacementTokenConsumeAuthorized': true,
      'roleEnableAuthorized': true,
      'migrationHoldReleaseAuthorized': true,
      'repositoryAttachAuthorized': false,
      'repositoryArmAuthorized': false,
      'firstIncidentWriteAuthorized': false,
      'authorizesSuggestOnly': false,
      'authorizesAuto': false,
    };

    if (scopeOverride != null) {
      scope.addAll(scopeOverride);
    }

    return AgentApprovalRequest(
      approvalId: 'phase66-enable-test-001',
      roleId: AgentSecurityIncidentPostRebindEnableExecutionContract.roleId,
      actionId:
          AgentSecurityIncidentPostRebindEnableExecutionContract.targetActionId,
      module: AgentSecurityIncidentPostRebindEnableExecutionContract.module,
      reason: AgentSecurityIncidentPostRebindEnableApprovalDecisionPolicy
          .exactReason,
      risk: 'HIGH',
      requestedBy:
          requestedBy ??
          'phase66_enable_coordinator_sha256:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd',
      actionScope: scope,
      status: AgentApprovalStatus.pending,
      createdAt: created,
      expiresAt: created.add(
        AgentSecurityIncidentPostRebindEnableApprovalDecisionPolicy
            .maxApprovalValidity,
      ),
    );
  }

  test('exact fresh Owner authorizes central APPROVE only', () {
    const policy =
        AgentSecurityIncidentPostRebindEnableApprovalDecisionPolicy();

    final result = policy.evaluate(
      request: pendingEnable(),
      historicalMigrationApproval: historicalMigration(),
      freshOwnerVerification: fresh(),
      currentAdminId: currentAdminId,
      decisionAction:
          AgentSecurityIncidentPostRebindEnableApprovalDecisionAction.approve,
    );

    expect(result.allowed, isTrue);
    expect(result.mayCallCentralApprove, isTrue);
    expect(result.mayCallCentralReject, isFalse);
    expect(result.ownerApproverReferenceSha256, ownerSha);
  });

  test('wrong authenticated Owner UID fails closed', () {
    const policy =
        AgentSecurityIncidentPostRebindEnableApprovalDecisionPolicy();

    final result = policy.evaluate(
      request: pendingEnable(),
      historicalMigrationApproval: historicalMigration(),
      freshOwnerVerification: fresh(),
      currentAdminId: 'different-owner-uid',
      decisionAction:
          AgentSecurityIncidentPostRebindEnableApprovalDecisionAction.approve,
    );

    expect(result.allowed, isFalse);
    expect(result.reasonCode, 'fresh_owner_reference_mismatch');
  });

  test('stale Owner verification fails closed', () {
    const policy =
        AgentSecurityIncidentPostRebindEnableApprovalDecisionPolicy();

    final result = policy.evaluate(
      request: pendingEnable(),
      historicalMigrationApproval: historicalMigration(),
      freshOwnerVerification: fresh(verified: false),
      currentAdminId: currentAdminId,
      decisionAction:
          AgentSecurityIncidentPostRebindEnableApprovalDecisionAction.approve,
    );

    expect(result.allowed, isFalse);
    expect(result.reasonCode, 'fresh_owner_verification_required');
  });

  test(
    'scope without replacement token consume authorization fails closed',
    () {
      const policy =
          AgentSecurityIncidentPostRebindEnableApprovalDecisionPolicy();

      expect(
        policy.matchesExactPendingRequest(
          pendingEnable(
            scopeOverride: <String, dynamic>{
              'replacementTokenConsumeAuthorized': false,
            },
          ),
        ),
        isFalse,
      );
    },
  );

  test('scope that authorizes repository attach fails closed', () {
    const policy =
        AgentSecurityIncidentPostRebindEnableApprovalDecisionPolicy();

    expect(
      policy.matchesExactPendingRequest(
        pendingEnable(
          scopeOverride: <String, dynamic>{'repositoryAttachAuthorized': true},
        ),
      ),
      isFalse,
    );
  });

  test('requester cannot equal Owner SHA', () {
    const policy =
        AgentSecurityIncidentPostRebindEnableApprovalDecisionPolicy();

    final result = policy.evaluate(
      request: pendingEnable(
        requestedBy: 'phase66_enable_coordinator_sha256:$ownerSha',
      ),
      historicalMigrationApproval: historicalMigration(),
      freshOwnerVerification: fresh(),
      currentAdminId: currentAdminId,
      decisionAction:
          AgentSecurityIncidentPostRebindEnableApprovalDecisionAction.approve,
    );

    expect(result.allowed, isFalse);
    expect(result.reasonCode, 'enable_requester_owner_separation_violation');
  });

  test('default-disarmed coordinator cannot approve', () async {
    final fake = _FakeGateway(
      pending: <AgentApprovalRequest>[pendingEnable()],
      historical: historicalMigration(),
    );

    final coordinator =
        AgentSecurityIncidentPostRebindEnableApprovalDecisionCoordinator(
          gateway: fake,
          freshOwnerVerifier: (String _) async => fresh(),
        );

    expect(coordinator.defaultFailClosed, isTrue);

    await expectLater(
      coordinator.approveObserved(
        observed: pendingEnable(),
        currentAdminId: currentAdminId,
      ),
      throwsStateError,
    );

    expect(fake.approveCalls, 0);
    expect(fake.rejectCalls, 0);
  });

  test('armed fresh Owner APPROVE calls only central approve', () async {
    final observed = pendingEnable();

    final fake = _FakeGateway(
      pending: <AgentApprovalRequest>[observed],
      historical: historicalMigration(),
    );

    final coordinator =
        AgentSecurityIncidentPostRebindEnableApprovalDecisionCoordinator(
          gateway: fake,
          freshOwnerVerifier: (String _) async => fresh(),
          executionArmed: true,
        );

    final result = await coordinator.approveObserved(
      observed: observed,
      currentAdminId: currentAdminId,
    );

    expect(result.allowed, isTrue);
    expect(fake.approveCalls, 1);
    expect(fake.rejectCalls, 0);
    expect(fake.lastDecidedBy, 'phase66_owner_sha256:$ownerSha');
  });

  test('armed fresh Owner REJECT calls only central reject', () async {
    final observed = pendingEnable();

    final fake = _FakeGateway(
      pending: <AgentApprovalRequest>[observed],
      historical: historicalMigration(),
    );

    final coordinator =
        AgentSecurityIncidentPostRebindEnableApprovalDecisionCoordinator(
          gateway: fake,
          freshOwnerVerifier: (String _) async => fresh(),
          executionArmed: true,
        );

    final result = await coordinator.rejectObserved(
      observed: observed,
      currentAdminId: currentAdminId,
    );

    expect(result.allowed, isTrue);
    expect(fake.approveCalls, 0);
    expect(fake.rejectCalls, 1);
  });

  test('watchExactPending filters unrelated approvals', () async {
    final exact = pendingEnable();

    final unrelated = AgentApprovalRequest(
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
    );

    final fake = _FakeGateway(
      pending: <AgentApprovalRequest>[unrelated, exact],
      historical: historicalMigration(),
    );

    final coordinator =
        AgentSecurityIncidentPostRebindEnableApprovalDecisionCoordinator(
          gateway: fake,
          freshOwnerVerifier: (String _) async => fresh(),
        );

    final items = await coordinator.watchExactPending().first;

    expect(items, hasLength(1));
    expect(items.single.approvalId, exact.approvalId);
  });

  test('authorization model exposes decision only and no live authority', () {
    final model =
        AgentSecurityIncidentPostRebindEnableApprovalDecisionAuthorization(
          allowed: true,
          reasonCode: 'test',
          decisionAction:
              AgentSecurityIncidentPostRebindEnableApprovalDecisionAction
                  .approve,
          ownerApproverReferenceSha256: ownerSha,
          ownerAuthAgeSeconds: 60,
        );

    expect(model.approvalDecisionOnly, isTrue);
    expect(model.consumesCentralApproval, isFalse);
    expect(model.issuesReplacementToken, isFalse);
    expect(model.consumesReplacementToken, isFalse);
    expect(model.enablesRole, isFalse);
    expect(model.releasesMigrationHold, isFalse);
    expect(model.attachesRuntime, isFalse);
    expect(model.armsRepository, isFalse);
    expect(model.writesIncident, isFalse);
    expect(model.authorizesSuggestOnly, isFalse);
    expect(model.authorizesAuto, isFalse);
  });
}

class _FakeGateway
    implements AgentSecurityIncidentPostRebindEnableCentralApprovalGateway {
  _FakeGateway({required this.pending, required this.historical});

  final List<AgentApprovalRequest> pending;
  final AgentApprovalRequest historical;

  int approveCalls = 0;
  int rejectCalls = 0;
  String? lastDecidedBy;

  @override
  Stream<List<AgentApprovalRequest>> watchPendingRequests() {
    return Stream<List<AgentApprovalRequest>>.value(pending);
  }

  @override
  Future<AgentApprovalRequest?> getRequest(String approvalId) async {
    if (approvalId == historical.approvalId) {
      return historical;
    }

    return null;
  }

  @override
  Future<void> approve({
    required String approvalId,
    required String decidedBy,
  }) async {
    approveCalls++;
    lastDecidedBy = decidedBy;
  }

  @override
  Future<void> reject({
    required String approvalId,
    required String decidedBy,
  }) async {
    rejectCalls++;
    lastDecidedBy = decidedBy;
  }
}
