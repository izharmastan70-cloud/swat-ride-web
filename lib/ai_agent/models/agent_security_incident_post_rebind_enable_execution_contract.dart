abstract final class AgentSecurityIncidentPostRebindEnableExecutionContract {
  static const String replacementTokenOperation =
      'ISSUE_FRESH_SECURITY_INCIDENT_POST_REBIND_ENABLE_TOKEN';

  static const String enableOperation =
      'ENABLE_SECURITY_INCIDENT_ROLE_AND_RELEASE_MIGRATION_HOLD_23_ROLE';

  static const String roleId = 'security_incident_agent';
  static const String module = 'security_incident';
  static const String targetActionId = 'security_incident.attach_runtime';
  static const String rolloutStage = 'MONITOR_ONLY';
  static const String requiredHoldStatus = 'ROLE_DELTA_COMMITTED';

  static const int authorityManifestRevision = 3;
  static const int guardRevision = 3;
  static const int roleCount = 23;

  static const List<String> replacementTokenWriteOrder = <String>[
    'FRESH_REPLACEMENT_TOKEN_CREATE',
    'REPLACEMENT_TOKEN_AUDIT_CREATE',
  ];

  static const List<String> atomicEnableWriteOrder = <String>[
    'OWNER_ENABLE_APPROVAL_CONSUME',
    'REPLACEMENT_TOKEN_CONSUME',
    'SECURITY_INCIDENT_ROLE_ENABLE',
    'MIGRATION_HOLD_RELEASE',
    'ENABLE_AUDIT_CREATE',
  ];

  static const bool oldTokenReuseAllowed = false;
  static const bool replacementTokenMutatesHistoricalToken = false;
  static const bool replacementTokenMustBeConsumedAtomically = true;
  static const bool enableAndHoldReleaseMustBeAtomic = true;
  static const bool repositoryAttachIncluded = false;
  static const bool repositoryArmIncluded = false;
  static const bool incidentWriteIncluded = false;
  static const bool suggestOnlyAuthorized = false;
  static const bool autoAuthorized = false;
}

abstract final class AgentSecurityIncidentPostRebindTokenRecoveryStatus {
  static const String blockedInvalid = 'BLOCKED_INVALID';
  static const String blockedCheckpoint = 'BLOCKED_CHECKPOINT';
  static const String blockedHistoricalToken = 'BLOCKED_HISTORICAL_TOKEN';
  static const String blockedOwnerIdentity = 'BLOCKED_OWNER_IDENTITY';
  static const String blockedRuntimeState = 'BLOCKED_RUNTIME_STATE';

  static const String eligible =
      'ELIGIBLE_FOR_FRESH_REPLACEMENT_TOKEN_ISSUANCE_NOT_EXECUTED';
}

class AgentSecurityIncidentPostRebindTokenRecoveryEvidence {
  const AgentSecurityIncidentPostRebindTokenRecoveryEvidence({
    required this.authorityManifestRevision,
    required this.guardRevision,
    required this.roleCount,
    required this.roleEnabled,
    required this.roleMode,
    required this.migrationHoldActive,
    required this.migrationHoldStatus,
    required this.rolloutStage,
    required this.rebindReceiptVerified,
    required this.historicalTokenExists,
    required this.historicalTokenReady,
    required this.historicalTokenExpired,
    required this.historicalTokenConsumed,
    required this.rawHistoricalTokenReuseAttempted,
    required this.freshOwnerIdentityVerified,
    required this.repositoryRuntimeAttached,
    required this.repositoryExecutionArmed,
    required this.incidentWritePerformed,
  });

  final int authorityManifestRevision;
  final int guardRevision;
  final int roleCount;
  final bool roleEnabled;
  final String roleMode;
  final bool migrationHoldActive;
  final String migrationHoldStatus;
  final String rolloutStage;
  final bool rebindReceiptVerified;

  final bool historicalTokenExists;
  final bool historicalTokenReady;
  final bool historicalTokenExpired;
  final bool historicalTokenConsumed;
  final bool rawHistoricalTokenReuseAttempted;

  final bool freshOwnerIdentityVerified;

  final bool repositoryRuntimeAttached;
  final bool repositoryExecutionArmed;
  final bool incidentWritePerformed;

  void validate() {
    if (authorityManifestRevision < 0 ||
        guardRevision < 0 ||
        roleCount < 0 ||
        roleMode.trim().isEmpty ||
        migrationHoldStatus.trim().isEmpty ||
        rolloutStage.trim().isEmpty) {
      throw const FormatException(
        'Invalid post-rebind token recovery evidence.',
      );
    }
  }
}

class AgentSecurityIncidentPostRebindTokenRecoveryDecision {
  const AgentSecurityIncidentPostRebindTokenRecoveryDecision({
    required this.status,
    required this.reasonCode,
    required this.eligibleForReplacementTokenIssuance,
  });

  final String status;
  final String reasonCode;
  final bool eligibleForReplacementTokenIssuance;

  bool get replacementTokenIssued => false;
  bool get historicalTokenMutated => false;
  bool get rawHistoricalTokenReused => false;
  bool get roleEnablePerformed => false;
  bool get migrationHoldReleased => false;
  bool get repositoryAttached => false;
  bool get repositoryArmed => false;
  bool get incidentWritten => false;
  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;
  bool get writesFirestore => false;
}

abstract final class AgentSecurityIncidentPostRebindEnableExecutionStatus {
  static const String blockedInvalid = 'BLOCKED_INVALID';
  static const String blockedCheckpoint = 'BLOCKED_CHECKPOINT';
  static const String blockedReplacementToken = 'BLOCKED_REPLACEMENT_TOKEN';
  static const String blockedOwnerIdentity = 'BLOCKED_OWNER_IDENTITY';
  static const String blockedOwnerApproval = 'BLOCKED_OWNER_APPROVAL';
  static const String blockedRuntimeState = 'BLOCKED_RUNTIME_STATE';

  static const String eligible =
      'ELIGIBLE_FOR_ATOMIC_ROLE_ENABLE_HOLD_RELEASE_NOT_EXECUTED';
}

class AgentSecurityIncidentPostRebindEnableExecutionEvidence {
  const AgentSecurityIncidentPostRebindEnableExecutionEvidence({
    required this.authorityManifestRevision,
    required this.guardRevision,
    required this.roleCount,
    required this.roleId,
    required this.module,
    required this.roleEnabled,
    required this.roleMode,
    required this.migrationHoldActive,
    required this.migrationHoldStatus,
    required this.rolloutStage,
    required this.rebindReceiptVerified,
    required this.freshReplacementTokenPresent,
    required this.freshReplacementTokenReady,
    required this.freshReplacementTokenUnexpired,
    required this.freshReplacementTokenExactBindingVerified,
    required this.oldTokenReuseAttempted,
    required this.freshOwnerIdentityVerified,
    required this.separateOwnerEnableApprovalPresent,
    required this.ownerEnableApprovalApproved,
    required this.ownerEnableApprovalUnconsumed,
    required this.ownerEnableApprovalExactBindingVerified,
    required this.migrationOrRebindApprovalReuseAttempted,
    required this.repositoryRuntimeAttached,
    required this.repositoryExecutionArmed,
    required this.incidentWritePerformed,
  });

  final int authorityManifestRevision;
  final int guardRevision;
  final int roleCount;

  final String roleId;
  final String module;
  final bool roleEnabled;
  final String roleMode;

  final bool migrationHoldActive;
  final String migrationHoldStatus;
  final String rolloutStage;

  final bool rebindReceiptVerified;

  final bool freshReplacementTokenPresent;
  final bool freshReplacementTokenReady;
  final bool freshReplacementTokenUnexpired;
  final bool freshReplacementTokenExactBindingVerified;
  final bool oldTokenReuseAttempted;

  final bool freshOwnerIdentityVerified;

  final bool separateOwnerEnableApprovalPresent;
  final bool ownerEnableApprovalApproved;
  final bool ownerEnableApprovalUnconsumed;
  final bool ownerEnableApprovalExactBindingVerified;
  final bool migrationOrRebindApprovalReuseAttempted;

  final bool repositoryRuntimeAttached;
  final bool repositoryExecutionArmed;
  final bool incidentWritePerformed;

  void validate() {
    if (authorityManifestRevision < 0 ||
        guardRevision < 0 ||
        roleCount < 0 ||
        roleId.trim().isEmpty ||
        module.trim().isEmpty ||
        roleMode.trim().isEmpty ||
        migrationHoldStatus.trim().isEmpty ||
        rolloutStage.trim().isEmpty) {
      throw const FormatException(
        'Invalid post-rebind enable execution evidence.',
      );
    }
  }
}

class AgentSecurityIncidentPostRebindEnableExecutionDecision {
  const AgentSecurityIncidentPostRebindEnableExecutionDecision({
    required this.status,
    required this.reasonCode,
    required this.eligibleForAtomicEnableAndHoldRelease,
  });

  final String status;
  final String reasonCode;
  final bool eligibleForAtomicEnableAndHoldRelease;

  List<String> get plannedAtomicWriteOrder =>
      AgentSecurityIncidentPostRebindEnableExecutionContract
          .atomicEnableWriteOrder;

  bool get executionPerformed => false;
  bool get approvalConsumed => false;
  bool get replacementTokenConsumed => false;
  bool get roleEnablePerformed => false;
  bool get migrationHoldReleased => false;
  bool get repositoryAttached => false;
  bool get repositoryArmed => false;
  bool get incidentWritten => false;
  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;
  bool get writesFirestore => false;
}
