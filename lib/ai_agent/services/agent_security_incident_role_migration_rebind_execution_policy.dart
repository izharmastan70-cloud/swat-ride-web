import '../models/agent_security_incident_role_migration_rebind_execution_boundary.dart';

/// Phase 66 Step1I-T-U.
///
/// Offline-only ordering and execution-readiness policy for the future 22 -> 23
/// security-incident role migration.
///
/// It deliberately stops before live migration. The role must be created
/// disabled, the migration hold must remain, and all post-migration
/// snapshot/manifest/guard/token/receipt rebinding remains mandatory before a
/// separate Owner-bound enable transaction may ever be considered.
class AgentSecurityIncidentRoleMigrationRebindExecutionPolicy {
  const AgentSecurityIncidentRoleMigrationRebindExecutionPolicy();

  static const int requiredCurrentRoleCount = 22;
  static const int requiredTargetRoleCount = 23;
  static const String requiredRoleId = 'security_incident_agent';
  static const String requiredModule = 'security_incident';

  AgentSecurityIncidentRoleMigrationRebindDecision evaluate(
    AgentSecurityIncidentRoleMigrationRebindEvidence evidence,
  ) {
    try {
      evidence.validate();
    } catch (_) {
      return const AgentSecurityIncidentRoleMigrationRebindDecision(
        status: AgentSecurityIncidentRoleMigrationRebindStatus.blockedInvalid,
        reasonCode: 'invalid_role_migration_rebind_evidence',
        eligibleForSeparateMigrationExecutionImplementation: false,
      );
    }

    if (evidence.currentRoleCount != requiredCurrentRoleCount ||
        evidence.targetRoleCount != requiredTargetRoleCount) {
      return const AgentSecurityIncidentRoleMigrationRebindDecision(
        status: AgentSecurityIncidentRoleMigrationRebindStatus
            .blockedCurrentInventory,
        reasonCode: 'role_inventory_must_be_exact_22_to_23',
        eligibleForSeparateMigrationExecutionImplementation: false,
      );
    }

    if (evidence.roleId != requiredRoleId ||
        evidence.module != requiredModule ||
        evidence.roleEnabledAtMigrationCommit ||
        !evidence.exactTSPayloadVerified) {
      return const AgentSecurityIncidentRoleMigrationRebindDecision(
        status:
            AgentSecurityIncidentRoleMigrationRebindStatus.blockedRolePayload,
        reasonCode:
            'security_incident_role_must_use_exact_t_s_payload_and_commit_disabled',
        eligibleForSeparateMigrationExecutionImplementation: false,
      );
    }

    if (!evidence.dedicatedMigrationRepositoryReady ||
        !evidence.migrationRulesManifestCouplingVerified ||
        !evidence.trustedBackendExecutionEnvironmentReady) {
      return const AgentSecurityIncidentRoleMigrationRebindDecision(
        status: AgentSecurityIncidentRoleMigrationRebindStatus
            .blockedMigrationAuthority,
        reasonCode: 'trusted_migration_execution_authority_not_complete',
        eligibleForSeparateMigrationExecutionImplementation: false,
      );
    }

    if (!evidence.freshOwnerIdentityVerified ||
        !evidence.freshOwnerMigrationApprovalPresent ||
        !evidence.ownerMigrationApprovalExactBindingVerified) {
      return const AgentSecurityIncidentRoleMigrationRebindDecision(
        status: AgentSecurityIncidentRoleMigrationRebindStatus
            .blockedOwnerMigrationApproval,
        reasonCode: 'fresh_owner_migration_approval_not_exact',
        eligibleForSeparateMigrationExecutionImplementation: false,
      );
    }

    if (!evidence.roleCreateSameTransactionRequired ||
        !evidence.authorityManifestUpdateSameTransactionRequired ||
        !evidence.migrationHoldSameTransactionRequired ||
        !evidence.migrationAuditSameTransactionRequired) {
      return const AgentSecurityIncidentRoleMigrationRebindDecision(
        status: AgentSecurityIncidentRoleMigrationRebindStatus
            .blockedAtomicMigration,
        reasonCode: 'migration_atomicity_contract_incomplete',
        eligibleForSeparateMigrationExecutionImplementation: false,
      );
    }

    if (!evidence.postMigrationSnapshotRequired ||
        !evidence.postMigrationAuthorityManifestRebindRequired ||
        !evidence.postMigrationGuardRebindRequired ||
        !evidence.postMigrationFreshArmingTokenRequired ||
        !evidence.postMigrationMigrationReceiptRequired) {
      return const AgentSecurityIncidentRoleMigrationRebindDecision(
        status: AgentSecurityIncidentRoleMigrationRebindStatus
            .blockedPostMigrationPlan,
        reasonCode: 'post_migration_rebind_chain_not_fully_required',
        eligibleForSeparateMigrationExecutionImplementation: false,
      );
    }

    if (!evidence.separatePostRebindEnableApprovalRequired ||
        evidence.roleEnableIncludedInMigrationTransaction ||
        evidence.oldArmingTokenReuseAllowed) {
      return const AgentSecurityIncidentRoleMigrationRebindDecision(
        status: AgentSecurityIncidentRoleMigrationRebindStatus
            .blockedEnableSeparation,
        reasonCode:
            'migration_and_enable_must_remain_separate_and_old_token_reuse_forbidden',
        eligibleForSeparateMigrationExecutionImplementation: false,
      );
    }

    if (evidence.repositoryRuntimeAttached ||
        evidence.repositoryExecutionArmed ||
        evidence.incidentWritePerformed) {
      return const AgentSecurityIncidentRoleMigrationRebindDecision(
        status: AgentSecurityIncidentRoleMigrationRebindStatus
            .blockedEnableSeparation,
        reasonCode:
            'incident_runtime_must_remain_inactive_during_role_migration',
        eligibleForSeparateMigrationExecutionImplementation: false,
      );
    }

    return const AgentSecurityIncidentRoleMigrationRebindDecision(
      status: AgentSecurityIncidentRoleMigrationRebindStatus.eligible,
      reasonCode:
          'migration_execution_prerequisites_ready_for_separate_controlled_implementation',
      eligibleForSeparateMigrationExecutionImplementation: true,
    );
  }

  bool get migrationMustCommitRoleDisabled => true;
  bool get migrationHoldMustRemainAfterCommit => true;
  bool get requiresPostMigrationSnapshot => true;
  bool get requiresPostMigrationManifestRebind => true;
  bool get requiresPostMigrationGuardRebind => true;
  bool get requiresFreshPostMigrationArmingToken => true;
  bool get requiresPostMigrationMigrationReceipt => true;
  bool get requiresSeparatePostRebindOwnerEnableApproval => true;
  bool get permitsOldArmingTokenReuse => false;
  bool get permitsRoleEnableInsideMigrationTransaction => false;

  bool get performsLiveMigration => false;
  bool get writesFirestore => false;
  bool get readsLiveFirestore => false;
  bool get invokesApprovalEngine => false;
  bool get consumesApproval => false;
  bool get invokesPermissionEngine => false;
  bool get invokesRuntimeGate => false;
  bool get changesFirestoreRules => false;
  bool get deploysFirestoreRules => false;
  bool get changesRolloutStage => false;
  bool get changesAgentMode => false;
  bool get changesEmergencyStop => false;
  bool get repositoryAttached => false;
  bool get repositoryArmed => false;
  bool get incidentWritten => false;
  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;
}
