import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_fresh_owner_claim_verification_result.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_role_inventory_migration_approval_decision_authorization.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_role_inventory_migration_central_approval_request.dart';
import 'package:swat_ride/ai_agent/services/agent_security_incident_role_inventory_migration_approval_decision_policy.dart';

void main() {
  const String currentAdminId = 'owner-firebase-uid-001';

  String sha(String value) => sha256.convert(utf8.encode(value)).toString();

  AgentSecurityIncidentRoleInventoryMigrationCentralApprovalRequest request({
    String? ownerSha,
  }) {
    const String bindingSha =
        'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

    final String expectedOwnerSha = ownerSha ?? sha(currentAdminId);

    return AgentSecurityIncidentRoleInventoryMigrationCentralApprovalRequest(
      roleId: 'security_incident_agent',
      actionId: 'security_incident.attach_runtime',
      module: 'security_incident',
      reason:
          'Owner approval required for exact 22-to-23 Security Incident role-inventory migration only.',
      risk: 'CRITICAL',
      requestedBy:
          'phase66_migration_coordinator_sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
      ownerApproverReferenceSha256: expectedOwnerSha,
      actionScope: <String, dynamic>{
        'operation': 'MIGRATE_SECURITY_INCIDENT_ROLE_INVENTORY_22_TO_23',
        'bindingFingerprintSha256': bindingSha,
        'requestPrincipal': 'PHASE66_MIGRATION_COORDINATOR',
        'ownerApproverReferenceSha256': expectedOwnerSha,
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

  AgentSecurityIncidentFreshOwnerClaimVerificationResult verified({
    int authAgeSeconds = 90,
    bool freshLoginVerified = true,
  }) {
    return AgentSecurityIncidentFreshOwnerClaimVerificationResult(
      status: freshLoginVerified
          ? AgentSecurityIncidentFreshOwnerClaimVerificationStatus.verified
          : AgentSecurityIncidentFreshOwnerClaimVerificationStatus.blocked,
      reasonCode: freshLoginVerified
          ? 'fresh_authenticated_super_admin_custom_claim_verified'
          : 'fresh_login_required',
      superAdminAccessVerified: true,
      roleClaimVerified: true,
      uidBindingVerified: true,
      customClaimSourceVerified: true,
      freshLoginVerified: freshLoginVerified,
      authAgeBucket: freshLoginVerified
          ? AgentSecurityIncidentFreshOwnerAuthAgeBucket.fresh
          : AgentSecurityIncidentFreshOwnerAuthAgeBucket.stale,
      boundedAuthAgeSeconds: freshLoginVerified ? authAgeSeconds : 301,
    );
  }

  const policy =
      AgentSecurityIncidentRoleInventoryMigrationApprovalDecisionPolicy();

  test('fresh exact Owner can authorize central APPROVE call only', () {
    final result = policy.evaluate(
      request: request(),
      freshOwnerVerification: verified(),
      currentAdminId: currentAdminId,
      decisionAction:
          AgentSecurityIncidentRoleInventoryMigrationApprovalDecisionAction
              .approve,
    );

    expect(result.allowed, isTrue);
    expect(result.mayCallCentralApprove, isTrue);
    expect(result.mayCallCentralReject, isFalse);
    expect(result.ownerAuthAgeSeconds, 90);
  });

  test('fresh exact Owner can authorize central REJECT call only', () {
    final result = policy.evaluate(
      request: request(),
      freshOwnerVerification: verified(),
      currentAdminId: currentAdminId,
      decisionAction:
          AgentSecurityIncidentRoleInventoryMigrationApprovalDecisionAction
              .reject,
    );

    expect(result.allowed, isTrue);
    expect(result.mayCallCentralApprove, isFalse);
    expect(result.mayCallCentralReject, isTrue);
  });

  test('Owner SHA mismatch fails closed', () {
    final result = policy.evaluate(
      request: request(
        ownerSha:
            'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd',
      ),
      freshOwnerVerification: verified(),
      currentAdminId: currentAdminId,
      decisionAction:
          AgentSecurityIncidentRoleInventoryMigrationApprovalDecisionAction
              .approve,
    );

    expect(result.allowed, isFalse);
    expect(result.reasonCode, 'fresh_owner_reference_mismatch');
    expect(result.mayCallCentralApprove, isFalse);
  });

  test('stale Owner verification fails closed', () {
    final result = policy.evaluate(
      request: request(),
      freshOwnerVerification: verified(freshLoginVerified: false),
      currentAdminId: currentAdminId,
      decisionAction:
          AgentSecurityIncidentRoleInventoryMigrationApprovalDecisionAction
              .approve,
    );

    expect(result.allowed, isFalse);
    expect(result.reasonCode, 'fresh_owner_verification_required');
    expect(result.mayCallCentralApprove, isFalse);
  });

  test('empty currentAdminId fails closed', () {
    final result = policy.evaluate(
      request: request(),
      freshOwnerVerification: verified(),
      currentAdminId: '',
      decisionAction:
          AgentSecurityIncidentRoleInventoryMigrationApprovalDecisionAction
              .approve,
    );

    expect(result.allowed, isFalse);
    expect(result.reasonCode, 'current_admin_id_required');
  });

  test('invalid decision action fails closed', () {
    final result = policy.evaluate(
      request: request(),
      freshOwnerVerification: verified(),
      currentAdminId: currentAdminId,
      decisionAction: 'AUTO_APPROVE',
    );

    expect(result.allowed, isFalse);
    expect(result.reasonCode, 'invalid_migration_approval_decision_action');
    expect(result.mayCallCentralApprove, isFalse);
    expect(result.mayCallCentralReject, isFalse);
  });

  test('exact migration identity and binding are preserved', () {
    final result = policy.evaluate(
      request: request(),
      freshOwnerVerification: verified(authAgeSeconds: 120),
      currentAdminId: currentAdminId,
      decisionAction:
          AgentSecurityIncidentRoleInventoryMigrationApprovalDecisionAction
              .approve,
    );

    expect(result.roleId, 'security_incident_agent');
    expect(result.actionId, 'security_incident.attach_runtime');
    expect(result.module, 'security_incident');
    expect(result.bindingFingerprintSha256, hasLength(64));
    expect(result.ownerApproverReferenceSha256, sha(currentAdminId));
  });

  test('decision authorization grants no migration/runtime authority', () {
    final result = policy.evaluate(
      request: request(),
      freshOwnerVerification: verified(),
      currentAdminId: currentAdminId,
      decisionAction:
          AgentSecurityIncidentRoleInventoryMigrationApprovalDecisionAction
              .approve,
    );

    expect(result.createsCentralApproval, isFalse);
    expect(result.approvesCentralApproval, isFalse);
    expect(result.rejectsCentralApproval, isFalse);
    expect(result.consumesCentralApproval, isFalse);
    expect(result.writesFirestore, isFalse);
    expect(result.executesMigration, isFalse);
    expect(result.createsRole, isFalse);
    expect(result.enablesRole, isFalse);
    expect(result.mutatesGuard, isFalse);
    expect(result.createsArmingToken, isFalse);
    expect(result.reusesExistingActivationToken, isFalse);
    expect(result.attachesRuntime, isFalse);
    expect(result.armsRepository, isFalse);
    expect(result.writesIncident, isFalse);
    expect(result.authorizesSuggestOnly, isFalse);
    expect(result.authorizesAuto, isFalse);
  });

  test('decision authorization contains no raw identity/token/claims', () {
    final result = policy.evaluate(
      request: request(),
      freshOwnerVerification: verified(),
      currentAdminId: currentAdminId,
      decisionAction:
          AgentSecurityIncidentRoleInventoryMigrationApprovalDecisionAction
              .approve,
    );

    expect(result.containsRawOwnerIdentity, isFalse);
    expect(result.containsRawIdToken, isFalse);
    expect(result.containsRawClaims, isFalse);
  });

  test('fresh auth upper bound 300 seconds is accepted', () {
    final result = policy.evaluate(
      request: request(),
      freshOwnerVerification: verified(authAgeSeconds: 300),
      currentAdminId: currentAdminId,
      decisionAction:
          AgentSecurityIncidentRoleInventoryMigrationApprovalDecisionAction
              .approve,
    );

    expect(result.allowed, isTrue);
    expect(result.ownerAuthAgeSeconds, 300);
  });
}
