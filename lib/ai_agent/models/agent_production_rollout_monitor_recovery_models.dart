class AgentProductionRolloutMonitorRecoveryPrepared {
  const AgentProductionRolloutMonitorRecoveryPrepared({
    required this.preparedAtUtc,
    required this.stateFingerprintSha256,
    required this.activationId,
    required this.armingTokenIdSha256,
    required this.guardRevision,
    required this.roleCount,
    required this.roleProjectionSha256,
    required this.controlStateSha256,
    required this.planSha256,
    required this.actorSha256,
    required this.ownerApprovalId,
  });

  final DateTime preparedAtUtc;
  final String stateFingerprintSha256;
  final String activationId;
  final String armingTokenIdSha256;
  final int guardRevision;
  final int roleCount;
  final String roleProjectionSha256;
  final String controlStateSha256;
  final String planSha256;
  final String actorSha256;
  final String ownerApprovalId;

  bool get changesProductionState => false;
  bool get releasesEmergencyStop => false;
  bool get grantsAutoAuthority => false;
  bool get grantsBusinessWriteAuthority => false;
}

class AgentProductionRolloutMonitorRecoveryOutcome {
  const AgentProductionRolloutMonitorRecoveryOutcome({
    required this.released,
    required this.postReleaseVerified,
    required this.status,
    required this.reasonCode,
    required this.activationId,
    required this.guardRevision,
  });

  final bool released;
  final bool postReleaseVerified;
  final String status;
  final String reasonCode;
  final String activationId;
  final int guardRevision;

  bool get safeMonitorOnlyActive => released && postReleaseVerified;
  bool get automaticRollbackPerformed => false;
  bool get autoTrafficEnabled => false;
  bool get businessWriteTrafficEnabled => false;
  bool get externalChannelsEnabled => false;
}
