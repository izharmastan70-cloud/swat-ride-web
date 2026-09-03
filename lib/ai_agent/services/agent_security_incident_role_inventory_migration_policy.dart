import '../models/agent_security_incident_role_inventory_migration_decision.dart';
import '../models/agent_security_incident_role_inventory_migration_plan.dart';
import '../models/agent_security_incident_role_inventory_revision_design.dart';

class AgentSecurityIncidentRoleInventoryMigrationPolicy {
  const AgentSecurityIncidentRoleInventoryMigrationPolicy();

  AgentSecurityIncidentRoleInventoryMigrationDecision evaluate(
    AgentSecurityIncidentRoleInventoryMigrationPlan plan,
  ) {
    AgentSecurityIncidentRoleInventoryMigrationDecision blocked(String reason) {
      return AgentSecurityIncidentRoleInventoryMigrationDecision(
        status: AgentSecurityIncidentRoleInventoryMigrationStatus.blocked,
        reasonCode: reason,
      );
    }

    if (plan.currentInventoryVersion !=
            AgentSecurityIncidentRoleInventoryRevisionDesign
                .currentInventoryVersion ||
        plan.proposedInventoryVersion !=
            AgentSecurityIncidentRoleInventoryRevisionDesign
                .proposedInventoryVersion) {
      return blocked('inventory_version_binding_mismatch');
    }

    if (plan.currentRoleCount !=
            AgentSecurityIncidentRoleInventoryRevisionDesign.currentRoleCount ||
        plan.proposedRoleCount !=
            AgentSecurityIncidentRoleInventoryRevisionDesign
                .proposedRoleCount ||
        plan.proposedRoleCount != plan.currentRoleCount + 1) {
      return blocked('role_count_delta_mismatch');
    }

    if (!_looksLikeSha256(plan.currentInventoryFingerprintSha256) ||
        !_looksLikeSha256(plan.proposedInventoryFingerprintSha256) ||
        !_looksLikeSha256(plan.currentControlFingerprintSha256) ||
        !_looksLikeSha256(plan.ownerApprovalBindingSha256)) {
      return blocked('required_sha256_binding_missing_or_invalid');
    }

    if (plan.currentInventoryFingerprintSha256 ==
        plan.proposedInventoryFingerprintSha256) {
      return blocked('old_and_proposed_inventory_fingerprints_must_differ');
    }

    if (!plan.freshOwnerVerified) {
      return blocked('fresh_owner_verification_required');
    }

    if (plan.currentRolloutStage != 'MONITOR_ONLY') {
      return blocked('migration_requires_monitor_only_stage');
    }

    if (plan.dedicatedRoleId !=
            AgentSecurityIncidentRoleInventoryRevisionDesign.dedicatedRoleId ||
        plan.dedicatedModule !=
            AgentSecurityIncidentRoleInventoryRevisionDesign.dedicatedModule ||
        plan.dedicatedActionId !=
            AgentSecurityIncidentRoleInventoryRevisionDesign
                .attachRuntimeActionId) {
      return blocked('dedicated_role_action_binding_mismatch');
    }

    if (!plan.oldGuardImmutable ||
        !plan.oldArmingTokenImmutable ||
        !plan.oldActivationReceiptImmutable ||
        plan.existingArmingTokenReuseAllowed) {
      return blocked('old_activation_evidence_must_remain_immutable');
    }

    if (plan.currentGuardRevision < 1 ||
        plan.proposedGuardRevision != plan.currentGuardRevision + 1) {
      return blocked('new_guard_revision_must_increment_exactly_once');
    }

    if (!plan.migrationHoldRequired || !plan.migrationHoldActive) {
      return blocked('fail_closed_migration_hold_required');
    }

    if (!plan.newLiveSnapshotRequired ||
        !plan.newGuardRequired ||
        !plan.newOneTimeTokenRequired ||
        !plan.newMigrationReceiptRequired) {
      return blocked('fresh_rebinding_evidence_required');
    }

    if (plan.firstIncidentWriteAuthorized ||
        plan.repositoryAttachAuthorized ||
        plan.repositoryArmAuthorized ||
        plan.authorizesSuggestOnly ||
        plan.authorizesAuto) {
      return blocked('migration_must_not_grant_runtime_or_rollout_authority');
    }

    return const AgentSecurityIncidentRoleInventoryMigrationDecision(
      status: AgentSecurityIncidentRoleInventoryMigrationStatus
          .readyForSeparateAtomicExecutorDesign,
      reasonCode:
          '22_to_23_migration_architecture_preconditions_satisfied_offline_only',
    );
  }

  bool _looksLikeSha256(String value) {
    final String normalized = value.trim().toLowerCase();

    if (normalized.length != 64) {
      return false;
    }

    return RegExp(r'^[0-9a-f]{64}$').hasMatch(normalized);
  }

  bool get ordinaryRoleServiceCreateIsMigrationAuthority => false;

  bool get exactOldInventoryPreconditionRequired => true;
  bool get exactProposedInventoryBindingRequired => true;
  bool get freshOwnerRequired => true;
  bool get exactOwnerApprovalBindingRequired => true;
  bool get migrationHoldRequired => true;

  bool get roleDeltaTransactionRequired => true;
  bool get partialRoleWriteAllowed => false;

  bool get oldEvidenceMutationAllowed => false;
  bool get oldArmingTokenReuseAllowed => false;

  bool get postMigrationSnapshotRequired => true;
  bool get newGuardRevisionRequired => true;
  bool get newOneTimeTokenRequired => true;
  bool get newMigrationReceiptRequired => true;
  bool get postMigrationMonitorVerificationRequired => true;

  bool get repositoryAttachAuthorized => false;
  bool get repositoryArmAuthorized => false;
  bool get firstIncidentWriteAuthorized => false;
  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;
}
