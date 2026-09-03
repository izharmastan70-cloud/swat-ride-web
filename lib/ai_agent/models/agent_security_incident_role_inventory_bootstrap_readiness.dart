class AgentSecurityIncidentRoleInventoryBootstrapReadiness {
  const AgentSecurityIncidentRoleInventoryBootstrapReadiness({
    required this.trustedBackendImplemented,
    required this.backendSingleMutationAuthority,
    required this.clientRoleWritesDenied,
    required this.clientManifestWritesDenied,
    required this.clientMigrationHoldWritesDenied,
    required this.freshTrustedLiveInventoryRead,
    required this.exactCurrentRoleIds,
    required this.currentInventoryFingerprintSha256,
    required this.proposedInventoryFingerprintSha256,
    required this.currentControlFingerprintSha256,
    required this.freshOwnerVerified,
    required this.ownerApprovalBound,
    required this.currentRolloutMonitorOnly,
    required this.dedicatedRoleAbsent,
    required this.oldGuardImmutable,
    required this.oldArmingTokenImmutable,
    required this.oldActivationReceiptImmutable,
    required this.sameTransactionAuditReady,
  });

  final bool trustedBackendImplemented;
  final bool backendSingleMutationAuthority;

  final bool clientRoleWritesDenied;
  final bool clientManifestWritesDenied;
  final bool clientMigrationHoldWritesDenied;

  final bool freshTrustedLiveInventoryRead;
  final List<String> exactCurrentRoleIds;

  final String currentInventoryFingerprintSha256;
  final String proposedInventoryFingerprintSha256;
  final String currentControlFingerprintSha256;

  final bool freshOwnerVerified;
  final bool ownerApprovalBound;

  final bool currentRolloutMonitorOnly;
  final bool dedicatedRoleAbsent;

  final bool oldGuardImmutable;
  final bool oldArmingTokenImmutable;
  final bool oldActivationReceiptImmutable;

  final bool sameTransactionAuditReady;
}

abstract final class AgentSecurityIncidentRoleInventoryBootstrapStatus {
  static const String blockedBackendMissing = 'BLOCKED_BACKEND_MISSING';
  static const String blockedBackendAuthority = 'BLOCKED_BACKEND_AUTHORITY';
  static const String blockedRulesBoundary = 'BLOCKED_RULES_BOUNDARY';
  static const String blockedLiveInventory = 'BLOCKED_LIVE_INVENTORY';
  static const String blockedFingerprint = 'BLOCKED_FINGERPRINT';
  static const String blockedOwner = 'BLOCKED_OWNER';
  static const String blockedRollout = 'BLOCKED_ROLLOUT';
  static const String blockedEvidence = 'BLOCKED_EVIDENCE';
  static const String blockedAudit = 'BLOCKED_AUDIT';

  static const String readyForSeparateTrustedBootstrapExecution =
      'READY_FOR_SEPARATE_TRUSTED_BOOTSTRAP_EXECUTION';
}

class AgentSecurityIncidentRoleInventoryBootstrapDecision {
  const AgentSecurityIncidentRoleInventoryBootstrapDecision({
    required this.status,
    required this.reasonCode,
  });

  final String status;
  final String reasonCode;

  bool get readyForSeparateTrustedBootstrapExecution =>
      status ==
      AgentSecurityIncidentRoleInventoryBootstrapStatus
          .readyForSeparateTrustedBootstrapExecution;

  bool get executesBootstrap => false;
  bool get writesFirestore => false;
  bool get consumesApproval => false;
  bool get createsRole => false;
  bool get changesGuard => false;
  bool get reusesActivationToken => false;
  bool get attachesRepository => false;
  bool get armsRepository => false;
  bool get writesIncident => false;
  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;
}
