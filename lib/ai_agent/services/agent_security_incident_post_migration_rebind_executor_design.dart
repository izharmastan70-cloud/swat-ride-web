import '../models/agent_security_incident_post_migration_rebind_execution_contract.dart';

/// Phase 66 Step1I-T-AM-T.
///
/// Offline-only design for the dedicated post-migration 23-role rebind
/// executor. This class intentionally does not import Firebase/Firestore,
/// does not issue a token, and does not mutate the live guard.
///
/// A later trusted backend implementation may be created only after this
/// fail-closed contract is verified.
class AgentSecurityIncidentPostMigrationRebindExecutorDesign {
  const AgentSecurityIncidentPostMigrationRebindExecutorDesign();

  static const String lockedPostMigrationSnapshotSha256 =
      '01ac8f1fc48b9d95a3ca1179ab550fe7c7a630b9605ff937b2feedd10a6c1888';

  static const String lockedRoleInventoryFingerprintSha256 =
      'd16c6ff23b0d56a9e3b76146eefe22832d86196dee48bb05d6bc0129f48e2f2a';

  static const int requiredRoleCount = 23;
  static const int requiredAuthorityManifestRevision = 2;
  static const int requiredCurrentGuardRevision = 2;
  static const int requiredCurrentGuardRoleCount = 22;
  static const int requiredNextGuardRevision = 3;

  static const String requiredTargetRoleMode = 'ASK_FIRST';
  static const String requiredMigrationHoldStatus = 'ROLE_DELTA_COMMITTED';
  static const String requiredRolloutStage = 'MONITOR_ONLY';

  AgentSecurityIncidentPostMigrationRebindDecision evaluate(
    AgentSecurityIncidentPostMigrationRebindEvidence evidence,
  ) {
    if (!_isSha256(evidence.postMigrationSnapshotSha256) ||
        !_isSha256(evidence.roleInventoryFingerprintSha256) ||
        !_isSha256(evidence.authorityManifestFingerprintSha256)) {
      return _blocked(
        AgentSecurityIncidentPostMigrationRebindStatus.blockedInvalid,
        'post_migration_rebind_hash_input_invalid',
      );
    }

    if (evidence.postMigrationSnapshotSha256.toLowerCase() !=
            lockedPostMigrationSnapshotSha256 ||
        evidence.roleInventoryFingerprintSha256.toLowerCase() !=
            lockedRoleInventoryFingerprintSha256 ||
        evidence.roleCount != requiredRoleCount) {
      return _blocked(
        AgentSecurityIncidentPostMigrationRebindStatus.blockedSnapshot,
        'exact_verified_23_role_post_migration_snapshot_required',
      );
    }

    if (!evidence.targetRoleExists ||
        evidence.targetRoleEnabled ||
        evidence.targetRoleMode != requiredTargetRoleMode) {
      return _blocked(
        AgentSecurityIncidentPostMigrationRebindStatus.blockedRoleAuthority,
        'security_incident_role_must_exist_disabled_in_ask_first',
      );
    }

    if (evidence.authorityManifestRevision !=
            requiredAuthorityManifestRevision ||
        evidence.authorityManifestRoleCount != requiredRoleCount ||
        evidence.authorityManifestFingerprintSha256.toLowerCase() !=
            lockedRoleInventoryFingerprintSha256 ||
        !evidence.postMigrationRebindRequired) {
      return _blocked(
        AgentSecurityIncidentPostMigrationRebindStatus.blockedManifest,
        'authority_manifest_revision2_23_role_rebind_required_state_missing',
      );
    }

    if (evidence.migrationHoldStatus != requiredMigrationHoldStatus ||
        !evidence.migrationHoldActive) {
      return _blocked(
        AgentSecurityIncidentPostMigrationRebindStatus.blockedMigrationHold,
        'role_delta_committed_active_migration_hold_required',
      );
    }

    if (!evidence.oldArmingTokenConsumed ||
        !evidence.oldActivationReceiptApplied ||
        evidence.oldArmingTokenReuseRequested) {
      return _blocked(
        AgentSecurityIncidentPostMigrationRebindStatus
            .blockedHistoricalEvidence,
        'old_token_receipt_must_remain_consumed_applied_and_not_reused',
      );
    }

    if (evidence.currentGuardRevision != requiredCurrentGuardRevision ||
        evidence.currentGuardRoleCount != requiredCurrentGuardRoleCount ||
        evidence.currentRolloutStage != requiredRolloutStage ||
        evidence.currentAutoTrafficPercent != 0 ||
        evidence.currentBusinessWriteTrafficPercent != 0 ||
        evidence.externalChannelsEnabled) {
      return _blocked(
        AgentSecurityIncidentPostMigrationRebindStatus.blockedCurrentGuard,
        'historical_monitor_only_guard_revision2_rolecount22_required_before_rebind',
      );
    }

    if (!evidence.freshOwnerIdentityVerified ||
        !evidence.freshRebindOwnerApprovalPresent ||
        !evidence.rebindApprovalSeparateFromMigrationApproval ||
        !evidence.rebindApprovalExactSnapshotBindingVerified) {
      return _blocked(
        AgentSecurityIncidentPostMigrationRebindStatus.blockedOwner,
        'fresh_separate_owner_bound_rebind_approval_required',
      );
    }

    if (evidence.securityBypassDetected ||
        evidence.duplicateAlternateAuthorityDetected ||
        evidence.repositoryRuntimeAttached ||
        evidence.repositoryExecutionArmed ||
        evidence.incidentWritePerformed) {
      return _blocked(
        AgentSecurityIncidentPostMigrationRebindStatus.blockedSafety,
        'fail_closed_runtime_security_boundary_changed_before_rebind',
      );
    }

    return const AgentSecurityIncidentPostMigrationRebindDecision(
      status: AgentSecurityIncidentPostMigrationRebindStatus.eligible,
      reasonCode:
          'dedicated_trusted_post_migration_rebind_implementation_contract_ready',
      eligibleForDedicatedTrustedImplementation: true,
      plan: AgentSecurityIncidentPostMigrationRebindPlan(
        targetGuardRevision: requiredNextGuardRevision,
        targetRoleCount: requiredRoleCount,
        targetRolloutStage: requiredRolloutStage,
        updateAuthorityManifest: true,
        persistFreshGuard: true,
        issueFreshOneTimeArmingToken: true,
        createFreshRebindReceipt: true,
        appendAuditInSameTrustedBoundary: true,
        keepMigrationHoldActive: true,
        enableSecurityIncidentRole: false,
        releaseMigrationHold: false,
        reuseOldArmingToken: false,
        persistRawArmingToken: false,
        attachRepositoryRuntime: false,
        armRepositoryExecution: false,
        writeIncident: false,
        authorizeSuggestOnly: false,
        authorizeAuto: false,
      ),
    );
  }

  AgentSecurityIncidentPostMigrationRebindDecision _blocked(
    String status,
    String reasonCode,
  ) {
    return AgentSecurityIncidentPostMigrationRebindDecision(
      status: status,
      reasonCode: reasonCode,
      eligibleForDedicatedTrustedImplementation: false,
      plan: null,
    );
  }

  bool _isSha256(String value) {
    final String normalized = value.trim().toLowerCase();

    return RegExp(r'^[a-f0-9]{64}$').hasMatch(normalized);
  }

  bool get offlineDesignOnly => true;
  bool get trustedBackendImplementationStillRequired => true;

  bool get requiresFreshPostMigrationSnapshot => true;
  bool get requiresExact23RoleInventory => true;
  bool get requiresFreshSeparateOwnerRebindApproval => true;
  bool get requiresGuardRevision2To3 => true;
  bool get requiresFreshOneTimeArmingToken => true;
  bool get requiresNewRebindReceipt => true;
  bool get requiresAuthorityManifestRebind => true;
  bool get migrationHoldMustRemainActive => true;

  bool get permitsOldArmingTokenReuse => false;
  bool get permitsRoleEnableInsideRebind => false;
  bool get permitsMigrationHoldReleaseInsideRebind => false;
  bool get persistsRawArmingToken => false;
  bool get securityBypassAllowed => false;
  bool get duplicateAlternateAuthorityAllowed => false;

  bool get performsLiveFirestoreWrite => false;
  bool get invokesPermissionEngine => false;
  bool get invokesRuntimeGate => false;
  bool get attachesRepositoryRuntime => false;
  bool get armsRepositoryExecution => false;
  bool get writesIncident => false;
  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;
}
