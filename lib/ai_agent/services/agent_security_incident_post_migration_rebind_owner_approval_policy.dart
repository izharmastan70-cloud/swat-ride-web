import '../models/agent_security_incident_post_migration_rebind_owner_approval.dart';

abstract final class AgentSecurityIncidentPostMigrationRebindApprovalStatus {
  static const String blockedInvalid = 'BLOCKED_INVALID';
  static const String blockedExpired = 'BLOCKED_EXPIRED';
  static const String blockedBinding = 'BLOCKED_BINDING';
  static const String blockedSeparation = 'BLOCKED_APPROVAL_SEPARATION';
  static const String blockedSafety = 'BLOCKED_SAFETY';
  static const String valid = 'VALID_EXACT_FRESH_OWNER_REBIND_APPROVAL';
}

class AgentSecurityIncidentPostMigrationRebindApprovalDecision {
  const AgentSecurityIncidentPostMigrationRebindApprovalDecision({
    required this.status,
    required this.reasonCode,
    required this.valid,
  });

  final String status;
  final String reasonCode;
  final bool valid;

  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get writesFirestore => false;
  bool get executesRebind => false;
  bool get enablesRole => false;
  bool get releasesMigrationHold => false;
  bool get attachesRuntime => false;
  bool get armsRepository => false;
  bool get writesIncident => false;
  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;
}

class AgentSecurityIncidentPostMigrationRebindOwnerApprovalPolicy {
  const AgentSecurityIncidentPostMigrationRebindOwnerApprovalPolicy();

  AgentSecurityIncidentPostMigrationRebindApprovalDecision evaluate({
    required AgentSecurityIncidentPostMigrationRebindOwnerApproval approval,
    required DateTime nowUtc,
  }) {
    if (!_validStructure(approval, nowUtc)) {
      return _blocked(
        AgentSecurityIncidentPostMigrationRebindApprovalStatus.blockedInvalid,
        'invalid_post_migration_rebind_owner_approval_contract',
      );
    }

    final DateTime now = nowUtc.toUtc();

    if (!now.isBefore(approval.expiresAtUtc)) {
      return _blocked(
        AgentSecurityIncidentPostMigrationRebindApprovalStatus.blockedExpired,
        'post_migration_rebind_owner_approval_expired',
      );
    }

    if (approval.postMigrationSnapshotSha256.toLowerCase() !=
            AgentSecurityIncidentPostMigrationRebindApprovalContract
                .lockedPostMigrationSnapshotSha256 ||
        approval.roleInventoryFingerprintSha256.toLowerCase() !=
            AgentSecurityIncidentPostMigrationRebindApprovalContract
                .lockedRoleInventoryFingerprintSha256 ||
        approval.roleCount !=
            AgentSecurityIncidentPostMigrationRebindApprovalContract
                .roleCount ||
        approval.currentAuthorityManifestRevision !=
            AgentSecurityIncidentPostMigrationRebindApprovalContract
                .currentAuthorityManifestRevision ||
        approval.targetAuthorityManifestRevision !=
            AgentSecurityIncidentPostMigrationRebindApprovalContract
                .targetAuthorityManifestRevision ||
        approval.currentGuardRevision !=
            AgentSecurityIncidentPostMigrationRebindApprovalContract
                .currentGuardRevision ||
        approval.targetGuardRevision !=
            AgentSecurityIncidentPostMigrationRebindApprovalContract
                .targetGuardRevision ||
        approval.targetRoleId !=
            AgentSecurityIncidentPostMigrationRebindApprovalContract
                .targetRoleId ||
        approval.targetModule !=
            AgentSecurityIncidentPostMigrationRebindApprovalContract
                .targetModule ||
        approval.targetActionId !=
            AgentSecurityIncidentPostMigrationRebindApprovalContract
                .targetActionId ||
        approval.requestedRolloutStage !=
            AgentSecurityIncidentPostMigrationRebindApprovalContract
                .targetRolloutStage) {
      return _blocked(
        AgentSecurityIncidentPostMigrationRebindApprovalStatus.blockedBinding,
        'rebind_approval_does_not_exactly_bind_verified_23_role_checkpoint',
      );
    }

    if (approval.approvalId == approval.migrationApprovalId ||
        approval.requesterReferenceSha256.toLowerCase() ==
            approval.ownerApproverReferenceSha256.toLowerCase() ||
        approval.selfApprovalAllowed ||
        approval.migrationApprovalReuseAllowed) {
      return _blocked(
        AgentSecurityIncidentPostMigrationRebindApprovalStatus
            .blockedSeparation,
        'fresh_rebind_approval_must_be_separate_from_migration_and_requester',
      );
    }

    if (!approval.freshOwnerVerifiedAtApproval ||
        !approval.explicitOwnerApproval ||
        approval.oldArmingTokenReuseAllowed ||
        approval.roleEnableAuthorized ||
        approval.migrationHoldReleaseAuthorized ||
        approval.repositoryAttachAuthorized ||
        approval.repositoryArmAuthorized ||
        approval.firstIncidentWriteAuthorized ||
        approval.authorizesSuggestOnly ||
        approval.authorizesAuto) {
      return _blocked(
        AgentSecurityIncidentPostMigrationRebindApprovalStatus.blockedSafety,
        'rebind_approval_scope_exceeds_fail_closed_rebind_boundary',
      );
    }

    return const AgentSecurityIncidentPostMigrationRebindApprovalDecision(
      status: AgentSecurityIncidentPostMigrationRebindApprovalStatus.valid,
      reasonCode:
          'exact_fresh_separate_owner_post_migration_rebind_approval_valid',
      valid: true,
    );
  }

  bool _validStructure(
    AgentSecurityIncidentPostMigrationRebindOwnerApproval approval,
    DateTime nowUtc,
  ) {
    final RegExp sha = RegExp(r'^[a-fA-F0-9]{64}$');

    if (approval.approvalId.trim().isEmpty ||
        approval.migrationApprovalId.trim().isEmpty ||
        !sha.hasMatch(approval.requesterReferenceSha256) ||
        !sha.hasMatch(approval.ownerApproverReferenceSha256) ||
        !sha.hasMatch(approval.postMigrationSnapshotSha256) ||
        !sha.hasMatch(approval.roleInventoryFingerprintSha256) ||
        !sha.hasMatch(approval.postMigrationControlStateFingerprintSha256) ||
        !sha.hasMatch(approval.rebindPlanFingerprintSha256) ||
        !approval.approvedAtUtc.isUtc ||
        !approval.expiresAtUtc.isUtc ||
        nowUtc != nowUtc.toUtc() ||
        approval.approvedAtUtc.isAfter(nowUtc.toUtc()) ||
        !approval.expiresAtUtc.isAfter(approval.approvedAtUtc) ||
        approval.expiresAtUtc.difference(approval.approvedAtUtc) >
            AgentSecurityIncidentPostMigrationRebindApprovalContract
                .maxApprovalValidity) {
      return false;
    }

    return true;
  }

  AgentSecurityIncidentPostMigrationRebindApprovalDecision _blocked(
    String status,
    String reasonCode,
  ) {
    return AgentSecurityIncidentPostMigrationRebindApprovalDecision(
      status: status,
      reasonCode: reasonCode,
      valid: false,
    );
  }

  bool get purePolicyOnly => true;
  bool get createsApproval => false;
  bool get consumesApproval => false;
  bool get writesFirestore => false;
  bool get executesRebind => false;
}
