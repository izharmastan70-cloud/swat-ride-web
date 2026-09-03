class AgentProductionRolloutSnapshotSource {
  AgentProductionRolloutSnapshotSource._();

  static const String liveFirestore = 'LIVE_FIRESTORE';
}

class AgentProductionRolloutStage {
  AgentProductionRolloutStage._();

  static const String off = 'OFF';
  static const String monitorOnly = 'MONITOR_ONLY';
  static const String suggestOnly = 'SUGGEST_ONLY';
  static const String askFirst = 'ASK_FIRST';
  static const String limitedAuto = 'LIMITED_AUTO';
  static const String fullSafeAuto = 'FULL_SAFE_AUTO';

  static const List<String> controlledOrder = <String>[
    off,
    monitorOnly,
    suggestOnly,
    askFirst,
    limitedAuto,
    fullSafeAuto,
  ];
}

class AgentProductionRolloutSnapshotPolicyStatus {
  AgentProductionRolloutSnapshotPolicyStatus._();

  static const String blockedSource = 'BLOCKED_SOURCE';
  static const String blockedStaleSnapshot = 'BLOCKED_STALE_SNAPSHOT';
  static const String blockedFutureSnapshot = 'BLOCKED_FUTURE_SNAPSHOT';
  static const String blockedPhase65Evidence = 'BLOCKED_PHASE65_EVIDENCE';
  static const String blockedPhase62Evidence = 'BLOCKED_PHASE62_EVIDENCE';
  static const String blockedUnsafeBaseline = 'BLOCKED_UNSAFE_BASELINE';
  static const String blockedLiveAutoDetected = 'BLOCKED_LIVE_AUTO_DETECTED';
  static const String blockedOwnerApproval = 'BLOCKED_OWNER_APPROVAL';
  static const String blockedApprovalExpired = 'BLOCKED_APPROVAL_EXPIRED';
  static const String blockedApprovalBinding = 'BLOCKED_APPROVAL_BINDING';
  static const String blockedStageSkip = 'BLOCKED_STAGE_SKIP';
  static const String eligibleMonitorOnlyHandoff =
      'ELIGIBLE_MONITOR_ONLY_HANDOFF';

  static const Set<String> values = <String>{
    blockedSource,
    blockedStaleSnapshot,
    blockedFutureSnapshot,
    blockedPhase65Evidence,
    blockedPhase62Evidence,
    blockedUnsafeBaseline,
    blockedLiveAutoDetected,
    blockedOwnerApproval,
    blockedApprovalExpired,
    blockedApprovalBinding,
    blockedStageSkip,
    eligibleMonitorOnlyHandoff,
  };
}

class AgentProductionRolloutSnapshotLimits {
  AgentProductionRolloutSnapshotLimits._();

  static const Duration snapshotMaxAge = Duration(minutes: 5);
  static const Duration snapshotMaxFutureSkew = Duration(minutes: 1);
  static const Duration ownerApprovalMaxValidity = Duration(minutes: 15);
  static const int sha256HexLength = 64;
}
