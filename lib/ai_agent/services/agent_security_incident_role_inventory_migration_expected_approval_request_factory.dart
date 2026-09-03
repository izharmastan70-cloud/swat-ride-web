import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/agent_security_incident_role_inventory_migration_central_approval_request.dart';

class AgentSecurityIncidentRoleInventoryMigrationExpectedApprovalRequestFactory {
  const AgentSecurityIncidentRoleInventoryMigrationExpectedApprovalRequestFactory();

  static const String currentInventorySha256 =
      '3ba eafc2e8ce82d138f884f6f3990c4ff644d981be864a35182c5475997b1f1d';

  static const String proposedInventorySha256 =
      'd16c6ff23b0d56a9e3b76146eefe22832d86196dee48bb05d6bc0129f48e2f2a';

  static const String currentControlSha256 =
      'db72e5c0888ea558c07ef002d059c3d92f909fb77f223725a029f35fa6ee9b5e';

  static const String preconditionEvidenceSha256 =
      '6cb1df3565e6a9130cadb54d888e6cfe89d7ed393dda369a54ad32d40d937240';

  static const String requestBindingSha256 =
      '1b2041d892cdafaaa312d04b8794ee2fa2953800038886fd5305ef8875c7a757';

  static const String migrationOperation =
      'MIGRATE_SECURITY_INCIDENT_ROLE_INVENTORY_22_TO_23';

  static const String targetRoleId = 'security_incident_agent';
  static const String targetModule = 'security_incident';
  static const String targetActionId = 'security_incident.attach_runtime';

  static const String reason =
      'Owner approval required for exact 22-to-23 Security Incident role-inventory migration only.';

  static const String risk = 'CRITICAL';

  AgentSecurityIncidentRoleInventoryMigrationCentralApprovalRequest build({
    required String currentAdminId,
  }) {
    final String cleanAdminId = currentAdminId.trim();

    if (cleanAdminId.isEmpty) {
      throw const FormatException(
        'currentAdminId is required for exact migration approval review.',
      );
    }

    final String ownerSha = sha256
        .convert(utf8.encode(cleanAdminId))
        .toString();

    final String coordinatorSha = sha256
        .convert(
          utf8.encode('PHASE66_MIGRATION_COORDINATOR|$requestBindingSha256'),
        )
        .toString();

    final Map<String, dynamic> actionScope = <String, dynamic>{
      'operation': migrationOperation,
      'bindingFingerprintSha256': requestBindingSha256,
      'requestPrincipal': 'PHASE66_MIGRATION_COORDINATOR',
      'ownerApproverReferenceSha256': ownerSha,
      'currentInventoryVersion': 'phase66_roles_v1_22',
      'proposedInventoryVersion': 'phase66_roles_v2_23_security_incident',
      'currentRoleCount': 22,
      'proposedRoleCount': 23,
      'currentInventoryFingerprintSha256': currentInventorySha256.replaceAll(
        ' ',
        '',
      ),
      'proposedInventoryFingerprintSha256': proposedInventorySha256,
      'currentControlFingerprintSha256': currentControlSha256,
      'preconditionEvidenceFingerprintSha256': preconditionEvidenceSha256,
      'currentGuardRevision': 2,
      'proposedGuardRevision': 3,
      'targetRoleId': targetRoleId,
      'targetModule': targetModule,
      'targetActionId': targetActionId,
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
    };

    final request =
        AgentSecurityIncidentRoleInventoryMigrationCentralApprovalRequest(
          roleId: targetRoleId,
          actionId: targetActionId,
          module: targetModule,
          reason: reason,
          risk: risk,
          requestedBy: 'phase66_migration_coordinator_sha256:$coordinatorSha',
          ownerApproverReferenceSha256: ownerSha,
          actionScope: actionScope,
          validity: const Duration(minutes: 15),
          bindingFingerprintSha256: requestBindingSha256,
        );

    request.validate();
    return request;
  }

  bool get readsFirestore => false;
  bool get writesFirestore => false;
  bool get createsApproval => false;
  bool get decidesApproval => false;
  bool get consumesApproval => false;
  bool get executesMigration => false;
  bool get createsRole => false;
  bool get enablesRole => false;
  bool get attachesRuntime => false;
  bool get armsRepository => false;
  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;
}
