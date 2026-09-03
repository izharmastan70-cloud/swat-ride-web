import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/services/agent_security_incident_role_inventory_migration_expected_approval_request_factory.dart';

void main() {
  const factory =
      AgentSecurityIncidentRoleInventoryMigrationExpectedApprovalRequestFactory();

  const String currentAdminId = 'owner-firebase-uid-001';

  String sha(String value) => sha256.convert(utf8.encode(value)).toString();

  test('factory binds exact T-AH migration request fingerprint', () {
    final request = factory.build(currentAdminId: currentAdminId);

    expect(
      request.bindingFingerprintSha256,
      '1b2041d892cdafaaa312d04b8794ee2fa2953800038886fd5305ef8875c7a757',
    );
  });

  test('factory binds current Firebase Admin SHA only', () {
    final request = factory.build(currentAdminId: currentAdminId);

    expect(request.ownerApproverReferenceSha256, sha(currentAdminId));

    expect(
      request.actionScope['ownerApproverReferenceSha256'],
      sha(currentAdminId),
    );
  });

  test('factory keeps exact role action module', () {
    final request = factory.build(currentAdminId: currentAdminId);

    expect(request.roleId, 'security_incident_agent');
    expect(request.actionId, 'security_incident.attach_runtime');
    expect(request.module, 'security_incident');
    expect(request.risk, 'CRITICAL');
  });

  test('factory uses system migration coordinator requester', () {
    final request = factory.build(currentAdminId: currentAdminId);

    expect(
      request.requestedBy,
      startsWith('phase66_migration_coordinator_sha256:'),
    );

    expect(
      request.actionScope['requestPrincipal'],
      'PHASE66_MIGRATION_COORDINATOR',
    );
  });

  test('factory binds exact T-Y inventory hashes', () {
    final request = factory.build(currentAdminId: currentAdminId);

    expect(
      request.actionScope['currentInventoryFingerprintSha256'],
      '3ba eafc2e8ce82d138f884f6f3990c4ff644d981be864a35182c5475997b1f1d'
          .replaceAll(' ', ''),
    );

    expect(
      request.actionScope['proposedInventoryFingerprintSha256'],
      'd16c6ff23b0d56a9e3b76146eefe22832d86196dee48bb05d6bc0129f48e2f2a',
    );
  });

  test('factory binds exact T-Z control and evidence', () {
    final request = factory.build(currentAdminId: currentAdminId);

    expect(
      request.actionScope['currentControlFingerprintSha256'],
      'db72e5c0888ea558c07ef002d059c3d92f909fb77f223725a029f35fa6ee9b5e',
    );

    expect(
      request.actionScope['preconditionEvidenceFingerprintSha256'],
      '6cb1df3565e6a9130cadb54d888e6cfe89d7ed393dda369a54ad32d40d937240',
    );
  });

  test('factory keeps guard 2 to 3 and role disabled', () {
    final request = factory.build(currentAdminId: currentAdminId);

    expect(request.actionScope['currentGuardRevision'], 2);
    expect(request.actionScope['proposedGuardRevision'], 3);
    expect(request.actionScope['proposedRoleEnabled'], isFalse);
  });

  test('factory preserves immutable historical evidence locks', () {
    final request = factory.build(currentAdminId: currentAdminId);

    expect(request.actionScope['oldGuardImmutable'], isTrue);
    expect(request.actionScope['oldArmingTokenImmutable'], isTrue);
    expect(request.actionScope['oldActivationReceiptImmutable'], isTrue);
    expect(request.actionScope['existingActivationTokenReuseAllowed'], isFalse);
  });

  test('factory grants no migration/runtime authority', () {
    expect(factory.readsFirestore, isFalse);
    expect(factory.writesFirestore, isFalse);
    expect(factory.createsApproval, isFalse);
    expect(factory.decidesApproval, isFalse);
    expect(factory.consumesApproval, isFalse);
    expect(factory.executesMigration, isFalse);
    expect(factory.createsRole, isFalse);
    expect(factory.enablesRole, isFalse);
    expect(factory.attachesRuntime, isFalse);
    expect(factory.armsRepository, isFalse);
    expect(factory.authorizesSuggestOnly, isFalse);
    expect(factory.authorizesAuto, isFalse);
  });

  test('empty Admin identity fails closed', () {
    expect(() => factory.build(currentAdminId: '  '), throwsFormatException);
  });
}
