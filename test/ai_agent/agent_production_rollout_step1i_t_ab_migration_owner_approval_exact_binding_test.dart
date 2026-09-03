import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_role_inventory_migration_owner_approval.dart';
import 'package:swat_ride/ai_agent/services/agent_security_incident_role_inventory_migration_owner_approval_policy.dart';

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

  AgentSecurityIncidentRoleInventoryMigrationOwnerApproval validApproval({
    bool freshOwnerVerified = true,
    bool explicitOwnerApproval = true,
    int currentGuardRevision = 2,
    int proposedGuardRevision = 3,
    DateTime? approvedAt,
    DateTime? expiresAt,
  }) {
    final DateTime approved = approvedAt ?? DateTime.utc(2026, 8, 28, 17, 0);

    return AgentSecurityIncidentRoleInventoryMigrationOwnerApproval(
      approvalId: 'phase66-migration-owner-approval-001',
      ownerReferenceSha256: ownerSha,
      currentInventoryFingerprintSha256: clean(currentInventorySha),
      proposedInventoryFingerprintSha256: proposedInventorySha,
      currentControlFingerprintSha256: controlSha,
      preconditionEvidenceFingerprintSha256: preconditionSha,
      currentGuardRevision: currentGuardRevision,
      proposedGuardRevision: proposedGuardRevision,
      approvedAtUtc: approved,
      expiresAtUtc: expiresAt ?? approved.add(const Duration(minutes: 10)),
      freshOwnerVerifiedAtApproval: freshOwnerVerified,
      explicitOwnerApproval: explicitOwnerApproval,
    );
  }

  test('exact 22 to 23 migration approval binding is valid offline', () {
    const policy =
        AgentSecurityIncidentRoleInventoryMigrationOwnerApprovalPolicy();

    final approval = validApproval();

    final decision = policy.evaluate(
      approval: approval,
      nowUtc: DateTime.utc(2026, 8, 28, 17, 5),
    );

    expect(decision.valid, isTrue);
    expect(
      decision.reasonCode,
      'exact_fresh_owner_migration_approval_binding_valid',
    );
    expect(decision.bindingFingerprintSha256, hasLength(64));
  });

  test('approval operation is migration-specific, not runtime execution', () {
    final approval = validApproval();

    expect(
      approval.operation,
      'MIGRATE_SECURITY_INCIDENT_ROLE_INVENTORY_22_TO_23',
    );
    expect(approval.targetActionId, 'security_incident.attach_runtime');
    expect(approval.executesMigration, isFalse);
    expect(approval.attachesRuntime, isFalse);
    expect(approval.armsRepository, isFalse);
  });

  test('proposed role remains disabled at 22 to 23 commit', () {
    final approval = validApproval();

    expect(approval.proposedRoleEnabled, isFalse);
  });

  test('approval binds exact live T-Y inventory fingerprints', () {
    final approval = validApproval();

    expect(
      approval.currentInventoryFingerprintSha256,
      clean(currentInventorySha),
    );
    expect(approval.proposedInventoryFingerprintSha256, proposedInventorySha);
  });

  test('approval binds T-Z control and precondition evidence hashes', () {
    final approval = validApproval();

    expect(approval.currentControlFingerprintSha256, controlSha);
    expect(approval.preconditionEvidenceFingerprintSha256, preconditionSha);
    expect(approval.currentGuardRevision, 2);
    expect(approval.proposedGuardRevision, 3);
  });

  test('fresh Owner verification is mandatory', () {
    expect(
      () => validApproval(freshOwnerVerified: false),
      throwsFormatException,
    );
  });

  test('explicit Owner approval is mandatory', () {
    expect(
      () => validApproval(explicitOwnerApproval: false),
      throwsFormatException,
    );
  });

  test('approval validity cannot exceed 15 minutes', () {
    final DateTime approved = DateTime.utc(2026, 8, 28, 17);

    expect(
      () => validApproval(
        approvedAt: approved,
        expiresAt: approved.add(const Duration(minutes: 16)),
      ),
      throwsFormatException,
    );
  });

  test('guard revision must advance exactly one revision', () {
    expect(
      () => validApproval(currentGuardRevision: 2, proposedGuardRevision: 4),
      throwsFormatException,
    );
  });

  test('expired approval fails closed', () {
    const policy =
        AgentSecurityIncidentRoleInventoryMigrationOwnerApprovalPolicy();

    final approval = validApproval();

    final decision = policy.evaluate(
      approval: approval,
      nowUtc: DateTime.utc(2026, 8, 28, 17, 11),
    );

    expect(decision.valid, isFalse);
    expect(decision.reasonCode, 'migration_owner_approval_expired');
  });

  test('binding fingerprint changes when approval id changes', () {
    const policy =
        AgentSecurityIncidentRoleInventoryMigrationOwnerApprovalPolicy();

    final first = validApproval();

    final second = AgentSecurityIncidentRoleInventoryMigrationOwnerApproval(
      approvalId: 'phase66-migration-owner-approval-002',
      ownerReferenceSha256: ownerSha,
      currentInventoryFingerprintSha256: clean(currentInventorySha),
      proposedInventoryFingerprintSha256: proposedInventorySha,
      currentControlFingerprintSha256: controlSha,
      preconditionEvidenceFingerprintSha256: preconditionSha,
      currentGuardRevision: 2,
      proposedGuardRevision: 3,
      approvedAtUtc: DateTime.utc(2026, 8, 28, 17),
      expiresAtUtc: DateTime.utc(2026, 8, 28, 17, 10),
      freshOwnerVerifiedAtApproval: true,
      explicitOwnerApproval: true,
    );

    expect(
      policy.bindingFingerprintSha256(first),
      isNot(policy.bindingFingerprintSha256(second)),
    );
  });

  test(
    'approval grants no runtime, Firestore, SUGGEST_ONLY or AUTO authority',
    () {
      final approval = validApproval();

      expect(approval.writesFirestore, isFalse);
      expect(approval.createsCentralApproval, isFalse);
      expect(approval.consumesCentralApproval, isFalse);
      expect(approval.executesMigration, isFalse);
      expect(approval.createsRole, isFalse);
      expect(approval.attachesRuntime, isFalse);
      expect(approval.armsRepository, isFalse);
      expect(approval.writesIncident, isFalse);
      expect(approval.authorizesSuggestOnly, isFalse);
      expect(approval.authorizesAuto, isFalse);
    },
  );
}
