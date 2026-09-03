import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/models/agent_approval_request.dart';
import 'package:swat_ride/ai_agent/services/agent_security_incident_role_inventory_migration_exact_pending_approval_reader.dart';
import 'package:swat_ride/ai_agent/services/agent_security_incident_role_inventory_migration_expected_approval_request_factory.dart';

void main() {
  const factory =
      AgentSecurityIncidentRoleInventoryMigrationExpectedApprovalRequestFactory();

  const String currentAdminId = 'owner-firebase-uid-001';

  test('deterministic exact approval id matches T-AI write id', () {
    expect(
      AgentSecurityIncidentRoleInventoryMigrationExactPendingApprovalReader.deterministicApprovalIdForBinding(
        AgentSecurityIncidentRoleInventoryMigrationExpectedApprovalRequestFactory
            .requestBindingSha256,
      ),
      'phase66-migration-1b2041d892cdafaaa312d04b8794ee2f',
    );
  });

  test('exact synthetic pending approval matches expected request', () {
    final expected = factory.build(currentAdminId: currentAdminId);

    final DateTime now = DateTime.utc(2026, 8, 28, 18);

    final observed = AgentApprovalRequest(
      approvalId: 'phase66-migration-1b2041d892cdafaaa312d04b8794ee2f',
      roleId: expected.roleId,
      actionId: expected.actionId,
      module: expected.module,
      reason: expected.reason,
      risk: expected.risk,
      requestedBy: expected.requestedBy,
      actionScope: Map<String, dynamic>.from(expected.actionScope),
      status: AgentApprovalStatus.pending,
      createdAt: now,
      expiresAt: now.add(const Duration(minutes: 15)),
    );

    expect(
      AgentSecurityIncidentRoleInventoryMigrationExactPendingApprovalReader.matchesExpected(
        observed: observed,
        expected: expected,
      ),
      isTrue,
    );
  });

  test('scope mismatch fails exact matching', () {
    final expected = factory.build(currentAdminId: currentAdminId);

    final Map<String, dynamic> wrongScope = Map<String, dynamic>.from(
      expected.actionScope,
    )..['proposedRoleEnabled'] = true;

    final DateTime now = DateTime.utc(2026, 8, 28, 18);

    final observed = AgentApprovalRequest(
      approvalId: 'phase66-migration-1b2041d892cdafaaa312d04b8794ee2f',
      roleId: expected.roleId,
      actionId: expected.actionId,
      module: expected.module,
      reason: expected.reason,
      risk: expected.risk,
      requestedBy: expected.requestedBy,
      actionScope: wrongScope,
      status: AgentApprovalStatus.pending,
      createdAt: now,
      expiresAt: now.add(const Duration(minutes: 15)),
    );

    expect(
      AgentSecurityIncidentRoleInventoryMigrationExactPendingApprovalReader.matchesExpected(
        observed: observed,
        expected: expected,
      ),
      isFalse,
    );
  });

  test('fresh PENDING unconsumed approval is usable', () {
    final expected = factory.build(currentAdminId: currentAdminId);

    final DateTime now = DateTime.utc(2026, 8, 28, 18);

    final observed = AgentApprovalRequest(
      approvalId: 'phase66-migration-1b2041d892cdafaaa312d04b8794ee2f',
      roleId: expected.roleId,
      actionId: expected.actionId,
      module: expected.module,
      reason: expected.reason,
      risk: expected.risk,
      requestedBy: expected.requestedBy,
      actionScope: Map<String, dynamic>.from(expected.actionScope),
      status: AgentApprovalStatus.pending,
      createdAt: now,
      expiresAt: now.add(const Duration(minutes: 15)),
    );

    expect(
      AgentSecurityIncidentRoleInventoryMigrationExactPendingApprovalReader.isUsableFreshPending(
        observed: observed,
        nowUtc: now.add(const Duration(minutes: 5)),
      ),
      isTrue,
    );
  });

  test('expired PENDING approval is not usable', () {
    final expected = factory.build(currentAdminId: currentAdminId);

    final DateTime now = DateTime.utc(2026, 8, 28, 18);

    final observed = AgentApprovalRequest(
      approvalId: 'phase66-migration-1b2041d892cdafaaa312d04b8794ee2f',
      roleId: expected.roleId,
      actionId: expected.actionId,
      module: expected.module,
      reason: expected.reason,
      risk: expected.risk,
      requestedBy: expected.requestedBy,
      actionScope: Map<String, dynamic>.from(expected.actionScope),
      status: AgentApprovalStatus.pending,
      createdAt: now,
      expiresAt: now.add(const Duration(minutes: 15)),
    );

    expect(
      AgentSecurityIncidentRoleInventoryMigrationExactPendingApprovalReader.isUsableFreshPending(
        observed: observed,
        nowUtc: now.add(const Duration(minutes: 16)),
      ),
      isFalse,
    );
  });

  test('approved approval is not usable as pending', () {
    final expected = factory.build(currentAdminId: currentAdminId);

    final DateTime now = DateTime.utc(2026, 8, 28, 18);

    final observed = AgentApprovalRequest(
      approvalId: 'phase66-migration-1b2041d892cdafaaa312d04b8794ee2f',
      roleId: expected.roleId,
      actionId: expected.actionId,
      module: expected.module,
      reason: expected.reason,
      risk: expected.risk,
      requestedBy: expected.requestedBy,
      actionScope: Map<String, dynamic>.from(expected.actionScope),
      status: AgentApprovalStatus.approved,
      createdAt: now,
      expiresAt: now.add(const Duration(minutes: 15)),
      decidedAt: now.add(const Duration(minutes: 1)),
      decidedBy: 'phase66_owner_sha256:test',
    );

    expect(
      AgentSecurityIncidentRoleInventoryMigrationExactPendingApprovalReader.isUsableFreshPending(
        observed: observed,
        nowUtc: now.add(const Duration(minutes: 2)),
      ),
      isFalse,
    );
  });
}
