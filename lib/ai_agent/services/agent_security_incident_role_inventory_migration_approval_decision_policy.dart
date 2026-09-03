import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/agent_security_incident_fresh_owner_claim_verification_result.dart';
import '../models/agent_security_incident_role_inventory_migration_approval_decision_authorization.dart';
import '../models/agent_security_incident_role_inventory_migration_central_approval_request.dart';

class AgentSecurityIncidentRoleInventoryMigrationApprovalDecisionPolicy {
  const AgentSecurityIncidentRoleInventoryMigrationApprovalDecisionPolicy();

  AgentSecurityIncidentRoleInventoryMigrationApprovalDecisionAuthorization
  evaluate({
    required AgentSecurityIncidentRoleInventoryMigrationCentralApprovalRequest
    request,
    required AgentSecurityIncidentFreshOwnerClaimVerificationResult
    freshOwnerVerification,
    required String currentAdminId,
    required String decisionAction,
  }) {
    try {
      request.validate();
    } on FormatException {
      return _blocked(
        request: request,
        decisionAction: decisionAction,
        reasonCode: 'invalid_migration_central_approval_request',
      );
    }

    if (!AgentSecurityIncidentRoleInventoryMigrationApprovalDecisionAction
        .values
        .contains(decisionAction)) {
      return _blocked(
        request: request,
        decisionAction: decisionAction,
        reasonCode: 'invalid_migration_approval_decision_action',
      );
    }

    final String adminId = currentAdminId.trim();

    if (adminId.isEmpty) {
      return _blocked(
        request: request,
        decisionAction: decisionAction,
        reasonCode: 'current_admin_id_required',
      );
    }

    final String currentOwnerSha = sha256
        .convert(utf8.encode(adminId))
        .toString();

    if (currentOwnerSha != request.ownerApproverReferenceSha256.toLowerCase()) {
      return _blocked(
        request: request,
        decisionAction: decisionAction,
        reasonCode: 'fresh_owner_reference_mismatch',
      );
    }

    final int? authAge = freshOwnerVerification.boundedAuthAgeSeconds;

    final bool exactFreshOwner =
        freshOwnerVerification.verified &&
        freshOwnerVerification.superAdminAccessVerified &&
        freshOwnerVerification.roleClaimVerified &&
        freshOwnerVerification.uidBindingVerified &&
        freshOwnerVerification.customClaimSourceVerified &&
        freshOwnerVerification.freshLoginVerified &&
        freshOwnerVerification.authAgeBucket ==
            AgentSecurityIncidentFreshOwnerAuthAgeBucket.fresh &&
        authAge != null &&
        authAge >= 0 &&
        authAge <= 300;

    if (!exactFreshOwner) {
      return _blocked(
        request: request,
        decisionAction: decisionAction,
        reasonCode: 'fresh_owner_verification_required',
      );
    }

    if (!request.requesterIsSystemMigrationCoordinator ||
        !request.approverMustBeFreshOwner ||
        !request.requesterAndApproverMustDiffer ||
        request.selfApprovalAllowed) {
      return _blocked(
        request: request,
        decisionAction: decisionAction,
        reasonCode: 'requester_approver_separation_failed',
      );
    }

    if (request.actionScope['operation'] !=
            'MIGRATE_SECURITY_INCIDENT_ROLE_INVENTORY_22_TO_23' ||
        request.actionScope['requestPrincipal'] !=
            'PHASE66_MIGRATION_COORDINATOR' ||
        request.actionScope['selfApprovalAllowed'] != false ||
        request.actionScope['requestedRolloutStage'] != 'MONITOR_ONLY' ||
        request.actionScope['proposedRoleEnabled'] != false ||
        request.actionScope['existingActivationTokenReuseAllowed'] != false ||
        request.actionScope['repositoryAttachAuthorized'] != false ||
        request.actionScope['repositoryArmAuthorized'] != false ||
        request.actionScope['firstIncidentWriteAuthorized'] != false ||
        request.actionScope['authorizesSuggestOnly'] != false ||
        request.actionScope['authorizesAuto'] != false) {
      return _blocked(
        request: request,
        decisionAction: decisionAction,
        reasonCode: 'migration_scope_not_fail_closed',
      );
    }

    final authorization =
        AgentSecurityIncidentRoleInventoryMigrationApprovalDecisionAuthorization(
          allowed: true,
          reasonCode:
              decisionAction ==
                  AgentSecurityIncidentRoleInventoryMigrationApprovalDecisionAction
                      .approve
              ? 'fresh_owner_exact_migration_approval_decision_authorized'
              : 'fresh_owner_exact_migration_rejection_decision_authorized',
          decisionAction: decisionAction,
          roleId: request.roleId,
          actionId: request.actionId,
          module: request.module,
          bindingFingerprintSha256: request.bindingFingerprintSha256
              .toLowerCase(),
          ownerApproverReferenceSha256: request.ownerApproverReferenceSha256
              .toLowerCase(),
          ownerAuthAgeSeconds: authAge,
        );

    authorization.validate();
    return authorization;
  }

  AgentSecurityIncidentRoleInventoryMigrationApprovalDecisionAuthorization
  _blocked({
    required AgentSecurityIncidentRoleInventoryMigrationCentralApprovalRequest
    request,
    required String decisionAction,
    required String reasonCode,
  }) {
    final String safeDecision =
        AgentSecurityIncidentRoleInventoryMigrationApprovalDecisionAction.values
            .contains(decisionAction)
        ? decisionAction
        : AgentSecurityIncidentRoleInventoryMigrationApprovalDecisionAction
              .reject;

    final authorization =
        AgentSecurityIncidentRoleInventoryMigrationApprovalDecisionAuthorization(
          allowed: false,
          reasonCode: reasonCode,
          decisionAction: safeDecision,
          roleId: request.roleId,
          actionId: request.actionId,
          module: request.module,
          bindingFingerprintSha256: request.bindingFingerprintSha256
              .toLowerCase(),
          ownerApproverReferenceSha256: request.ownerApproverReferenceSha256
              .toLowerCase(),
          ownerAuthAgeSeconds: null,
        );

    authorization.validate();
    return authorization;
  }

  bool get deterministicOnly => true;

  bool get callsFreshOwnerService => false;
  bool get callsCentralApprovalService => false;

  bool get createsCentralApproval => false;
  bool get approvesCentralApproval => false;
  bool get rejectsCentralApproval => false;
  bool get consumesCentralApproval => false;

  bool get writesFirestore => false;
  bool get executesMigration => false;
  bool get createsRole => false;
  bool get enablesRole => false;
  bool get mutatesGuard => false;
  bool get createsArmingToken => false;
  bool get attachesRuntime => false;
  bool get armsRepository => false;
  bool get writesIncident => false;

  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;
}
