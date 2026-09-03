import '../constants/agent_production_rollout_runtime_guard_constants.dart';

class AgentProductionRolloutArmingReadinessDecision {
  const AgentProductionRolloutArmingReadinessDecision({
    required this.status,
    required this.reasonCode,
    required this.safeArmingReady,
  });

  final String status;
  final String reasonCode;
  final bool safeArmingReady;

  bool get activatesProduction => false;
  bool get armsRepository => false;
}

class AgentProductionRolloutArmingReadinessPolicy {
  const AgentProductionRolloutArmingReadinessPolicy();

  AgentProductionRolloutArmingReadinessDecision evaluate({
    required bool runtimeOverlayVerified,
    required bool guardPersistenceContractVerified,
    required bool firestoreRulesHardened,
    required bool firestoreRulesDeployed,
    required bool step1DRepositoryDefaultsNotArmed,
    required bool liveGuardPersisted,
  }) {
    if (!runtimeOverlayVerified) {
      return const AgentProductionRolloutArmingReadinessDecision(
        status: AgentProductionRolloutArmingReadinessStatus.blockedOverlay,
        reasonCode: 'runtime_monitor_only_overlay_verification_required',
        safeArmingReady: false,
      );
    }

    if (!guardPersistenceContractVerified) {
      return const AgentProductionRolloutArmingReadinessDecision(
        status:
            AgentProductionRolloutArmingReadinessStatus.blockedGuardPersistence,
        reasonCode: 'atomic_production_guard_persistence_contract_required',
        safeArmingReady: false,
      );
    }

    if (!firestoreRulesHardened || !firestoreRulesDeployed) {
      return const AgentProductionRolloutArmingReadinessDecision(
        status: AgentProductionRolloutArmingReadinessStatus.blockedRules,
        reasonCode:
            'phase66_critical_firestore_rules_must_be_hardened_and_deployed',
        safeArmingReady: false,
      );
    }

    if (!step1DRepositoryDefaultsNotArmed) {
      return const AgentProductionRolloutArmingReadinessDecision(
        status:
            AgentProductionRolloutArmingReadinessStatus.blockedRepositorySafety,
        reasonCode: 'activation_repository_must_remain_default_not_armed',
        safeArmingReady: false,
      );
    }

    if (!liveGuardPersisted) {
      return const AgentProductionRolloutArmingReadinessDecision(
        status: AgentProductionRolloutArmingReadinessStatus
            .readyForTrustedGuardPersistenceNotArmed,
        reasonCode:
            'overlay_and_rules_ready_but_exact_live_owner_bound_guard_not_yet_persisted',
        safeArmingReady: false,
      );
    }

    return const AgentProductionRolloutArmingReadinessDecision(
      status: AgentProductionRolloutArmingReadinessStatus
          .readyToArmMonitorRepository,
      reasonCode:
          'exact_live_guard_persisted_and_all_monitor_only_safety_controls_ready',
      safeArmingReady: true,
    );
  }

  bool get policyOnly => true;
  bool get writesFirestore => false;
  bool get activatesProduction => false;
  bool get armsRepository => false;
}
