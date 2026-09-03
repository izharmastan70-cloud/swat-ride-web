import '../models/agent_security_incident_post_rebind_enable_boundary.dart';

/// Phase 66 Step1I-T-T.
///
/// Offline-only prerequisite policy for the later, separately authorized
/// post-rebind enable boundary.
///
/// This policy does not enable a role, release the migration hold, consume an
/// Owner approval, attach/arm the incident repository, or write Firestore.
class AgentSecurityIncidentPostRebindEnablePolicy {
  const AgentSecurityIncidentPostRebindEnablePolicy();

  static const String requiredRoleId = 'security_incident_agent';
  static const String requiredModule = 'security_incident';
  static const int requiredPostMigrationRoleCount = 23;

  AgentSecurityIncidentPostRebindEnableDecision evaluate(
    AgentSecurityIncidentPostRebindEnableEvidence evidence,
  ) {
    try {
      evidence.validate();
    } catch (_) {
      return const AgentSecurityIncidentPostRebindEnableDecision(
        status:
            AgentSecurityIncidentPostRebindEnableBoundaryStatus.blockedInvalid,
        reasonCode: 'invalid_post_rebind_enable_evidence',
        eligibleForSeparateEnableImplementation: false,
      );
    }

    if (evidence.postMigrationRoleCount != requiredPostMigrationRoleCount) {
      return const AgentSecurityIncidentPostRebindEnableDecision(
        status: AgentSecurityIncidentPostRebindEnableBoundaryStatus
            .blockedRoleInventory,
        reasonCode: 'post_migration_role_inventory_not_exact_23',
        eligibleForSeparateEnableImplementation: false,
      );
    }

    if (evidence.roleId != requiredRoleId ||
        evidence.module != requiredModule ||
        evidence.roleEnabled ||
        !evidence.exactDisabledRolePayloadVerified) {
      return const AgentSecurityIncidentPostRebindEnableDecision(
        status: AgentSecurityIncidentPostRebindEnableBoundaryStatus
            .blockedRoleAuthority,
        reasonCode: 'disabled_security_incident_role_authority_not_exact',
        eligibleForSeparateEnableImplementation: false,
      );
    }

    if (!evidence.postMigrationSnapshotVerified ||
        !evidence.authorityManifestRebound ||
        !evidence.migrationReceiptVerified) {
      return const AgentSecurityIncidentPostRebindEnableDecision(
        status: AgentSecurityIncidentPostRebindEnableBoundaryStatus
            .blockedRebindEvidence,
        reasonCode: 'post_migration_rebind_evidence_incomplete',
        eligibleForSeparateEnableImplementation: false,
      );
    }

    if (!evidence.migrationHoldPresent) {
      return const AgentSecurityIncidentPostRebindEnableDecision(
        status: AgentSecurityIncidentPostRebindEnableBoundaryStatus
            .blockedMigrationHold,
        reasonCode: 'migration_hold_must_remain_until_future_atomic_enable',
        eligibleForSeparateEnableImplementation: false,
      );
    }

    if (!evidence.productionGuardReboundToPostMigrationInventory ||
        !evidence.freshArmingTokenIssuedAfterRebind ||
        evidence.oldArmingTokenReused) {
      return const AgentSecurityIncidentPostRebindEnableDecision(
        status: AgentSecurityIncidentPostRebindEnableBoundaryStatus
            .blockedSecurityRebind,
        reasonCode: 'fresh_post_rebind_guard_token_boundary_not_proven',
        eligibleForSeparateEnableImplementation: false,
      );
    }

    if (!evidence.freshOwnerIdentityVerified) {
      return const AgentSecurityIncidentPostRebindEnableDecision(
        status: AgentSecurityIncidentPostRebindEnableBoundaryStatus
            .blockedOwnerIdentity,
        reasonCode: 'fresh_owner_identity_required',
        eligibleForSeparateEnableImplementation: false,
      );
    }

    if (!evidence.freshOwnerApprovalPresent ||
        !evidence.ownerApprovalSeparateFromMigrationApproval ||
        !evidence.ownerApprovalExactBindingVerified) {
      return const AgentSecurityIncidentPostRebindEnableDecision(
        status: AgentSecurityIncidentPostRebindEnableBoundaryStatus
            .blockedOwnerApproval,
        reasonCode: 'fresh_separate_exact_owner_enable_approval_required',
        eligibleForSeparateEnableImplementation: false,
      );
    }

    if (evidence.repositoryRuntimeAttached ||
        evidence.repositoryExecutionArmed ||
        evidence.incidentWritePerformed) {
      return const AgentSecurityIncidentPostRebindEnableDecision(
        status: AgentSecurityIncidentPostRebindEnableBoundaryStatus
            .blockedRuntimeState,
        reasonCode: 'runtime_changed_before_separate_enable_boundary',
        eligibleForSeparateEnableImplementation: false,
      );
    }

    return const AgentSecurityIncidentPostRebindEnableDecision(
      status: AgentSecurityIncidentPostRebindEnableBoundaryStatus.eligible,
      reasonCode:
          'post_rebind_enable_prerequisites_ready_separate_execution_required',
      eligibleForSeparateEnableImplementation: true,
    );
  }

  bool get offlineDesignOnly => true;
  bool get requiresFreshOwnerDecisionAtExecution => true;
  bool get requiresSeparateOwnerApproval => true;
  bool get requiresAtomicRoleEnableAndHoldReleaseAtExecution => true;
  bool get requiresPostMigrationSnapshot => true;
  bool get requiresPostMigrationGuardRebind => true;
  bool get requiresFreshPostRebindArmingToken => true;
  bool get permitsOldArmingTokenReuse => false;

  bool get roleEnablePerformed => false;
  bool get migrationHoldReleased => false;
  bool get writesFirestore => false;
  bool get readsLiveFirestore => false;
  bool get consumesApproval => false;
  bool get createsApproval => false;
  bool get invokesPermissionEngine => false;
  bool get invokesRuntimeGate => false;
  bool get grantsPermission => false;
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
