import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_role_inventory_migration_owner_approval.dart';
import 'package:swat_ride/ai_agent/services/agent_security_incident_role_inventory_migration_approval_handoff_coordinator.dart';

void main() {
  const String ownerSha =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

  const String currentInventorySha =
      '3ba eafc2e8ce82d138f884f6f3990c4ff644d981be864a35182c5475997b1f1d';

  const String proposedInventorySha =
      'd16c6ff23b0d56a9e3b76146eefe22832d86196dee48bb05d6bc0129f48e2f2a';

  const String controlSha =
      'db72e5c0888ea558c07ef002d059c3d92f909fb77f223725a029f35fa6ee9b5e';

  const String preconditionSha =
      '6cb1df3565e6a9130cadb54d888e6cfe89d7ed393dda369a54ad32d40d937240';

  String clean(String value) => value.replaceAll(' ', '');

  AgentSecurityIncidentRoleInventoryMigrationOwnerApproval approval() {
    final DateTime approvedAt = DateTime.utc(2026, 8, 28, 17);

    return AgentSecurityIncidentRoleInventoryMigrationOwnerApproval(
      approvalId: 'phase66-migration-owner-approval-001',
      ownerReferenceSha256: ownerSha,
      currentInventoryFingerprintSha256: clean(currentInventorySha),
      proposedInventoryFingerprintSha256: proposedInventorySha,
      currentControlFingerprintSha256: controlSha,
      preconditionEvidenceFingerprintSha256: preconditionSha,
      currentGuardRevision: 2,
      proposedGuardRevision: 3,
      approvedAtUtc: approvedAt,
      expiresAtUtc: approvedAt.add(const Duration(minutes: 10)),
      freshOwnerVerifiedAtApproval: true,
      explicitOwnerApproval: true,
    );
  }

  test('exact T-AB approval produces central approval handoff', () {
    const coordinator =
        AgentSecurityIncidentRoleInventoryMigrationApprovalHandoffCoordinator();

    final handoff = coordinator.prepare(
      approval: approval(),
      nowUtc: DateTime.utc(2026, 8, 28, 17, 5),
    );

    expect(handoff.readyForSeparateCentralApprovalCreate, isTrue);
    expect(handoff.roleId, 'security_incident_agent');
    expect(handoff.actionId, 'security_incident.attach_runtime');
    expect(handoff.module, 'security_incident');
    expect(handoff.risk, 'CRITICAL');
    expect(handoff.validity, const Duration(minutes: 15));
  });

  test('scope operation is migration-specific', () {
    const coordinator =
        AgentSecurityIncidentRoleInventoryMigrationApprovalHandoffCoordinator();

    final handoff = coordinator.prepare(
      approval: approval(),
      nowUtc: DateTime.utc(2026, 8, 28, 17, 5),
    );

    expect(
      handoff.actionScope['operation'],
      'MIGRATE_SECURITY_INCIDENT_ROLE_INVENTORY_22_TO_23',
    );

    expect(
      handoff.actionScope['targetActionId'],
      'security_incident.attach_runtime',
    );

    expect(handoff.actionScope['proposedRoleEnabled'], isFalse);
  });

  test('scope binds exact T-Y inventory hashes', () {
    const coordinator =
        AgentSecurityIncidentRoleInventoryMigrationApprovalHandoffCoordinator();

    final handoff = coordinator.prepare(
      approval: approval(),
      nowUtc: DateTime.utc(2026, 8, 28, 17, 5),
    );

    expect(
      handoff.actionScope['currentInventoryFingerprintSha256'],
      clean(currentInventorySha),
    );

    expect(
      handoff.actionScope['proposedInventoryFingerprintSha256'],
      proposedInventorySha,
    );
  });

  test('scope binds exact T-Z control/precondition evidence', () {
    const coordinator =
        AgentSecurityIncidentRoleInventoryMigrationApprovalHandoffCoordinator();

    final handoff = coordinator.prepare(
      approval: approval(),
      nowUtc: DateTime.utc(2026, 8, 28, 17, 5),
    );

    expect(handoff.actionScope['currentControlFingerprintSha256'], controlSha);

    expect(
      handoff.actionScope['preconditionEvidenceFingerprintSha256'],
      preconditionSha,
    );

    expect(handoff.actionScope['currentGuardRevision'], 2);
    expect(handoff.actionScope['proposedGuardRevision'], 3);
  });

  test('requester is pseudonymous owner SHA only', () {
    const coordinator =
        AgentSecurityIncidentRoleInventoryMigrationApprovalHandoffCoordinator();

    final handoff = coordinator.prepare(
      approval: approval(),
      nowUtc: DateTime.utc(2026, 8, 28, 17, 5),
    );

    expect(handoff.requestedBy, 'phase66_owner_sha256:$ownerSha');

    expect(handoff.containsRawOwnerIdentity, isFalse);
    expect(handoff.containsRawAuthToken, isFalse);
    expect(handoff.containsRawClaims, isFalse);
  });

  test('old evidence remains immutable and token reuse stays forbidden', () {
    const coordinator =
        AgentSecurityIncidentRoleInventoryMigrationApprovalHandoffCoordinator();

    final handoff = coordinator.prepare(
      approval: approval(),
      nowUtc: DateTime.utc(2026, 8, 28, 17, 5),
    );

    expect(handoff.actionScope['oldGuardImmutable'], isTrue);
    expect(handoff.actionScope['oldArmingTokenImmutable'], isTrue);
    expect(handoff.actionScope['oldActivationReceiptImmutable'], isTrue);
    expect(handoff.actionScope['existingActivationTokenReuseAllowed'], isFalse);
  });

  test('handoff grants no runtime/migration execution authority', () {
    const coordinator =
        AgentSecurityIncidentRoleInventoryMigrationApprovalHandoffCoordinator();

    final handoff = coordinator.prepare(
      approval: approval(),
      nowUtc: DateTime.utc(2026, 8, 28, 17, 5),
    );

    expect(handoff.createsCentralApproval, isFalse);
    expect(handoff.approvesCentralApproval, isFalse);
    expect(handoff.consumesCentralApproval, isFalse);
    expect(handoff.writesFirestore, isFalse);
    expect(handoff.executesMigration, isFalse);
    expect(handoff.createsRole, isFalse);
    expect(handoff.mutatesGuard, isFalse);
    expect(handoff.createsArmingToken, isFalse);
    expect(handoff.attachesRuntime, isFalse);
    expect(handoff.armsRepository, isFalse);
    expect(handoff.writesIncident, isFalse);
    expect(handoff.authorizesSuggestOnly, isFalse);
    expect(handoff.authorizesAuto, isFalse);
  });

  test('expired T-AB approval cannot produce handoff', () {
    const coordinator =
        AgentSecurityIncidentRoleInventoryMigrationApprovalHandoffCoordinator();

    expect(
      () => coordinator.prepare(
        approval: approval(),
        nowUtc: DateTime.utc(2026, 8, 28, 17, 11),
      ),
      throwsFormatException,
    );
  });

  test('binding fingerprint is copied exactly into action scope', () {
    const coordinator =
        AgentSecurityIncidentRoleInventoryMigrationApprovalHandoffCoordinator();

    final handoff = coordinator.prepare(
      approval: approval(),
      nowUtc: DateTime.utc(2026, 8, 28, 17, 5),
    );

    expect(
      handoff.actionScope['bindingFingerprintSha256'],
      handoff.bindingFingerprintSha256,
    );

    expect(handoff.bindingFingerprintSha256, hasLength(64));
  });
}
