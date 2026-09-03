// SWAT RIDE - Rewards production safety gate.
//
// Customer-facing Rewards and all reward-value mutations remain
// disabled until trusted backend execution and secure Firestore
// authorization are ready.

class RewardProductionGate {
  RewardProductionGate._();

  static const bool trustedBackendReady = false;

  static const bool customerRewardsAccessEnabled = false;

  static const bool financialMutationsEnabled = false;
}