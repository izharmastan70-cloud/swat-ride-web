class AgentProductionRolloutArmingTokenStatus {
  AgentProductionRolloutArmingTokenStatus._();

  static const String ready = 'READY';
  static const String consumed = 'CONSUMED';
}

class AgentProductionRolloutArmingTokenLimits {
  AgentProductionRolloutArmingTokenLimits._();

  static const Duration maxValidity = Duration(seconds: 90);
  static const int secureRandomBytes = 32;
  static const int sha256HexLength = 64;
}

class AgentProductionRolloutArmingTokenCollection {
  AgentProductionRolloutArmingTokenCollection._();

  static const String path = 'agent_production_rollout_arming_tokens';
}

class AgentProductionRolloutTrustedPreflightStatus {
  AgentProductionRolloutTrustedPreflightStatus._();

  static const String blockedUntrustedActor = 'BLOCKED_UNTRUSTED_ACTOR';
  static const String blockedReauthentication = 'BLOCKED_REAUTHENTICATION';
  static const String blockedStaleContext = 'BLOCKED_STALE_CONTEXT';
  static const String blockedApproval = 'BLOCKED_APPROVAL';
  static const String blockedExpiredPlan = 'BLOCKED_EXPIRED_PLAN';
  static const String blockedLiveRead = 'BLOCKED_LIVE_READ';
  static const String blockedControlStateChanged =
      'BLOCKED_CONTROL_STATE_CHANGED';
  static const String blockedRoleCountChanged = 'BLOCKED_ROLE_COUNT_CHANGED';
  static const String blockedUnsafeMasterBaseline =
      'BLOCKED_UNSAFE_MASTER_BASELINE';
  static const String ready = 'TRUSTED_LIVE_PREFLIGHT_READY';
}

class AgentProductionRolloutArmingAuthorizationStatus {
  AgentProductionRolloutArmingAuthorizationStatus._();

  static const String blockedMissing = 'BLOCKED_ARMING_TOKEN_MISSING';
  static const String blockedInvalid = 'BLOCKED_ARMING_TOKEN_INVALID';
  static const String blockedExpired = 'BLOCKED_ARMING_TOKEN_EXPIRED';
  static const String blockedBinding = 'BLOCKED_ARMING_TOKEN_BINDING';
  static const String authorized = 'ARMING_TOKEN_AUTHORIZED';
}

class AgentProductionRolloutArmingTokenRepositoryStatus {
  AgentProductionRolloutArmingTokenRepositoryStatus._();

  static const String blockedNotArmed = 'BLOCKED_TOKEN_ISSUANCE_NOT_ARMED';
  static const String blockedInvalid = 'BLOCKED_TOKEN_ISSUANCE_INVALID';
  static const String blockedGuard = 'BLOCKED_TOKEN_GUARD_MISMATCH';
  static const String blockedMaster = 'BLOCKED_TOKEN_MASTER_BASELINE';
  static const String blockedRollout = 'BLOCKED_TOKEN_ROLLOUT_STATE';
  static const String blockedCollision = 'BLOCKED_TOKEN_ID_COLLISION';
  static const String issued = 'ARMING_TOKEN_ISSUED';
}
