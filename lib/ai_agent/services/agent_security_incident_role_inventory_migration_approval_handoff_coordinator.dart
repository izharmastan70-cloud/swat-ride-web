import '../models/agent_security_incident_role_inventory_migration_approval_handoff.dart';
import '../models/agent_security_incident_role_inventory_migration_owner_approval.dart';
import 'agent_security_incident_role_inventory_migration_owner_approval_policy.dart';

class AgentSecurityIncidentRoleInventoryMigrationApprovalHandoffCoordinator {
  const AgentSecurityIncidentRoleInventoryMigrationApprovalHandoffCoordinator({
    this.policy =
        const AgentSecurityIncidentRoleInventoryMigrationOwnerApprovalPolicy(),
  });

  final AgentSecurityIncidentRoleInventoryMigrationOwnerApprovalPolicy policy;

  AgentSecurityIncidentRoleInventoryMigrationApprovalHandoff prepare({
    required AgentSecurityIncidentRoleInventoryMigrationOwnerApproval approval,
    required DateTime nowUtc,
  }) {
    final decision = policy.evaluate(approval: approval, nowUtc: nowUtc);

    if (!decision.valid) {
      throw FormatException(
        'Migration Owner approval is not handoff-ready: ${decision.reasonCode}',
      );
    }

    final String requesterReference =
        'phase66_owner_sha256:${approval.ownerReferenceSha256.toLowerCase()}';

    final Map<String, dynamic> exactScope = <String, dynamic>{
      'operation': approval.operation,
      'bindingFingerprintSha256': decision.bindingFingerprintSha256
          .toLowerCase(),
      'currentInventoryVersion': approval.currentInventoryVersion,
      'proposedInventoryVersion': approval.proposedInventoryVersion,
      'currentRoleCount': approval.currentRoleCount,
      'proposedRoleCount': approval.proposedRoleCount,
      'currentInventoryFingerprintSha256': approval
          .currentInventoryFingerprintSha256
          .toLowerCase(),
      'proposedInventoryFingerprintSha256': approval
          .proposedInventoryFingerprintSha256
          .toLowerCase(),
      'currentControlFingerprintSha256': approval
          .currentControlFingerprintSha256
          .toLowerCase(),
      'preconditionEvidenceFingerprintSha256': approval
          .preconditionEvidenceFingerprintSha256
          .toLowerCase(),
      'currentGuardRevision': approval.currentGuardRevision,
      'proposedGuardRevision': approval.proposedGuardRevision,
      'targetRoleId': approval.targetRoleId,
      'targetModule': approval.targetModule,
      'targetActionId': approval.targetActionId,
      'requestedRolloutStage': approval.requestedRolloutStage,
      'proposedRoleEnabled': approval.proposedRoleEnabled,
      'freshOwnerVerifiedAtApproval': approval.freshOwnerVerifiedAtApproval,
      'explicitOwnerApproval': approval.explicitOwnerApproval,
      'oldGuardImmutable': approval.oldGuardImmutable,
      'oldArmingTokenImmutable': approval.oldArmingTokenImmutable,
      'oldActivationReceiptImmutable': approval.oldActivationReceiptImmutable,
      'existingActivationTokenReuseAllowed':
          approval.existingActivationTokenReuseAllowed,
      'repositoryAttachAuthorized': approval.repositoryAttachAuthorized,
      'repositoryArmAuthorized': approval.repositoryArmAuthorized,
      'firstIncidentWriteAuthorized': approval.firstIncidentWriteAuthorized,
      'authorizesSuggestOnly': approval.authorizesSuggestOnly,
      'authorizesAuto': approval.authorizesAuto,
    };

    final handoff = AgentSecurityIncidentRoleInventoryMigrationApprovalHandoff(
      roleId: approval.targetRoleId,
      actionId: approval.targetActionId,
      module: approval.targetModule,
      reason:
          'Owner approval required for exact 22-to-23 Security Incident role-inventory migration only.',
      risk: 'CRITICAL',
      requestedBy: requesterReference,
      actionScope: exactScope,
      validity: AgentSecurityIncidentRoleInventoryMigrationOwnerApprovalContract
          .maxApprovalValidity,
      bindingFingerprintSha256: decision.bindingFingerprintSha256.toLowerCase(),
    );

    handoff.validate();
    return handoff;
  }

  bool get callsCentralApprovalService => false;
  bool get writesFirestore => false;
  bool get createsCentralApproval => false;
  bool get consumesCentralApproval => false;
  bool get executesMigration => false;
  bool get createsRole => false;
  bool get mutatesGuard => false;
  bool get createsArmingToken => false;
  bool get attachesRuntime => false;
  bool get armsRepository => false;
  bool get writesIncident => false;
  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;
}
