import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_role_inventory_migration_approval_handoff.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_role_inventory_migration_owner_approval.dart';
import 'package:swat_ride/ai_agent/services/agent_security_incident_role_inventory_migration_approval_handoff_coordinator.dart';
import 'package:swat_ride/ai_agent/services/agent_security_incident_role_inventory_migration_central_approval_request_policy.dart';

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

  AgentSecurityIncidentRoleInventoryMigrationApprovalHandoff handoff() {
    const coordinator =
        AgentSecurityIncidentRoleInventoryMigrationApprovalHandoffCoordinator();

    return coordinator.prepare(
      approval: approval(),
      nowUtc: DateTime.utc(2026, 8, 28, 17, 5),
    );
  }

  test('request principal is system coordinator, not Owner pseudonym', () {
    const policy =
        AgentSecurityIncidentRoleInventoryMigrationCentralApprovalRequestPolicy();

    final request = policy.prepare(
      approval: approval(),
      handoff: handoff(),
      nowUtc: DateTime.utc(2026, 8, 28, 17, 5),
    );

    expect(
      request.requestedBy,
      startsWith('phase66_migration_coordinator_sha256:'),
    );

    expect(request.requestedBy, isNot('phase66_owner_sha256:$ownerSha'));

    expect(request.requesterIsSystemMigrationCoordinator, isTrue);
  });

  test('fresh Owner is separately bound as required approver SHA', () {
    const policy =
        AgentSecurityIncidentRoleInventoryMigrationCentralApprovalRequestPolicy();

    final request = policy.prepare(
      approval: approval(),
      handoff: handoff(),
      nowUtc: DateTime.utc(2026, 8, 28, 17, 5),
    );

    expect(request.ownerApproverReferenceSha256, ownerSha);
    expect(request.actionScope['ownerApproverReferenceSha256'], ownerSha);
    expect(request.approverMustBeFreshOwner, isTrue);
  });

  test('self approval is explicitly forbidden', () {
    const policy =
        AgentSecurityIncidentRoleInventoryMigrationCentralApprovalRequestPolicy();

    final request = policy.prepare(
      approval: approval(),
      handoff: handoff(),
      nowUtc: DateTime.utc(2026, 8, 28, 17, 5),
    );

    expect(request.selfApprovalAllowed, isFalse);
    expect(request.requesterAndApproverMustDiffer, isTrue);
    expect(request.actionScope['selfApprovalAllowed'], isFalse);
  });

  test('role action module remain exact', () {
    const policy =
        AgentSecurityIncidentRoleInventoryMigrationCentralApprovalRequestPolicy();

    final request = policy.prepare(
      approval: approval(),
      handoff: handoff(),
      nowUtc: DateTime.utc(2026, 8, 28, 17, 5),
    );

    expect(request.roleId, 'security_incident_agent');
    expect(request.actionId, 'security_incident.attach_runtime');
    expect(request.module, 'security_incident');
    expect(request.risk, 'CRITICAL');
  });

  test('migration fingerprints remain exact-bound', () {
    const policy =
        AgentSecurityIncidentRoleInventoryMigrationCentralApprovalRequestPolicy();

    final request = policy.prepare(
      approval: approval(),
      handoff: handoff(),
      nowUtc: DateTime.utc(2026, 8, 28, 17, 5),
    );

    expect(
      request.actionScope['currentInventoryFingerprintSha256'],
      clean(currentInventorySha),
    );
    expect(
      request.actionScope['proposedInventoryFingerprintSha256'],
      proposedInventorySha,
    );
    expect(request.actionScope['currentControlFingerprintSha256'], controlSha);
    expect(
      request.actionScope['preconditionEvidenceFingerprintSha256'],
      preconditionSha,
    );
  });

  test('guard revision stays 2 to 3 and proposed role disabled', () {
    const policy =
        AgentSecurityIncidentRoleInventoryMigrationCentralApprovalRequestPolicy();

    final request = policy.prepare(
      approval: approval(),
      handoff: handoff(),
      nowUtc: DateTime.utc(2026, 8, 28, 17, 5),
    );

    expect(request.actionScope['currentGuardRevision'], 2);
    expect(request.actionScope['proposedGuardRevision'], 3);
    expect(request.actionScope['proposedRoleEnabled'], isFalse);
  });

  test('old evidence immutable and token reuse forbidden', () {
    const policy =
        AgentSecurityIncidentRoleInventoryMigrationCentralApprovalRequestPolicy();

    final request = policy.prepare(
      approval: approval(),
      handoff: handoff(),
      nowUtc: DateTime.utc(2026, 8, 28, 17, 5),
    );

    expect(request.actionScope['oldGuardImmutable'], isTrue);
    expect(request.actionScope['oldArmingTokenImmutable'], isTrue);
    expect(request.actionScope['oldActivationReceiptImmutable'], isTrue);
    expect(request.actionScope['existingActivationTokenReuseAllowed'], isFalse);
  });

  test('request grants no live or runtime authority', () {
    const policy =
        AgentSecurityIncidentRoleInventoryMigrationCentralApprovalRequestPolicy();

    final request = policy.prepare(
      approval: approval(),
      handoff: handoff(),
      nowUtc: DateTime.utc(2026, 8, 28, 17, 5),
    );

    expect(request.createsCentralApproval, isFalse);
    expect(request.approvesCentralApproval, isFalse);
    expect(request.consumesCentralApproval, isFalse);
    expect(request.writesFirestore, isFalse);
    expect(request.executesMigration, isFalse);
    expect(request.createsRole, isFalse);
    expect(request.mutatesGuard, isFalse);
    expect(request.createsArmingToken, isFalse);
    expect(request.attachesRuntime, isFalse);
    expect(request.armsRepository, isFalse);
    expect(request.writesIncident, isFalse);
    expect(request.authorizesSuggestOnly, isFalse);
    expect(request.authorizesAuto, isFalse);
  });

  test('request contains no raw Owner identity/token/claims', () {
    const policy =
        AgentSecurityIncidentRoleInventoryMigrationCentralApprovalRequestPolicy();

    final request = policy.prepare(
      approval: approval(),
      handoff: handoff(),
      nowUtc: DateTime.utc(2026, 8, 28, 17, 5),
    );

    expect(request.containsRawOwnerIdentity, isFalse);
    expect(request.containsRawAuthToken, isFalse);
    expect(request.containsRawClaims, isFalse);
  });

  test('T-AC owner requester pseudonym is not forwarded to live request', () {
    const policy =
        AgentSecurityIncidentRoleInventoryMigrationCentralApprovalRequestPolicy();

    final oldHandoff = handoff();

    expect(oldHandoff.requestedBy, 'phase66_owner_sha256:$ownerSha');

    final request = policy.prepare(
      approval: approval(),
      handoff: oldHandoff,
      nowUtc: DateTime.utc(2026, 8, 28, 17, 5),
    );

    expect(request.requestedBy, isNot(oldHandoff.requestedBy));
  });
}
