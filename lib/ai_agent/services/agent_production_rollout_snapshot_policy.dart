import '../constants/agent_production_rollout_snapshot_constants.dart';
import '../models/agent_production_rollout_owner_approval.dart';
import '../models/agent_production_rollout_snapshot.dart';

class AgentProductionRolloutSnapshotDecision {
  const AgentProductionRolloutSnapshotDecision({
    required this.status,
    required this.reasonCode,
    required this.monitorOnlyHandoffEligible,
  });

  final String status;
  final String reasonCode;
  final bool monitorOnlyHandoffEligible;

  bool get activatesRollout => false;
  bool get changesAgentMode => false;
  bool get changesMasterSettings => false;
  bool get consumesApproval => false;
  bool get grantsPermission => false;
  bool get overridesRuntimeGate => false;
  bool get changesEmergencyStop => false;
  bool get callsProvider => false;
  bool get writesFirestore => false;
  bool get executesBusinessAction => false;
}

class AgentProductionRolloutSnapshotPolicy {
  const AgentProductionRolloutSnapshotPolicy();

  AgentProductionRolloutSnapshotDecision evaluate({
    required AgentProductionRolloutSnapshot snapshot,
    required AgentProductionRolloutOwnerApproval ownerApproval,
    required DateTime evaluatedAtUtc,
    required bool phase65SafetyReady,
    required bool phase62VersionSafetyReady,
  }) {
    snapshot.validate();
    ownerApproval.validate();

    if (snapshot.source != AgentProductionRolloutSnapshotSource.liveFirestore) {
      return _blocked(
        AgentProductionRolloutSnapshotPolicyStatus.blockedSource,
        'live_firestore_snapshot_required',
      );
    }

    final DateTime now = evaluatedAtUtc.toUtc();
    final Duration age = now.difference(snapshot.capturedAtUtc);

    if (age < -AgentProductionRolloutSnapshotLimits.snapshotMaxFutureSkew) {
      return _blocked(
        AgentProductionRolloutSnapshotPolicyStatus.blockedFutureSnapshot,
        'snapshot_future_clock_skew_exceeded',
      );
    }

    if (age > AgentProductionRolloutSnapshotLimits.snapshotMaxAge) {
      return _blocked(
        AgentProductionRolloutSnapshotPolicyStatus.blockedStaleSnapshot,
        'live_snapshot_is_stale',
      );
    }

    if (!phase65SafetyReady) {
      return _blocked(
        AgentProductionRolloutSnapshotPolicyStatus.blockedPhase65Evidence,
        'phase65_final_safety_readiness_required',
      );
    }

    if (!phase62VersionSafetyReady) {
      return _blocked(
        AgentProductionRolloutSnapshotPolicyStatus.blockedPhase62Evidence,
        'phase62_version_rollback_readiness_required',
      );
    }

    if (snapshot.masterEnabled ||
        !snapshot.emergencyReadOnly ||
        !snapshot.approvalEngineEnabled ||
        !snapshot.auditLoggingEnabled) {
      return _blocked(
        AgentProductionRolloutSnapshotPolicyStatus.blockedUnsafeBaseline,
        'initial_phase66_snapshot_must_be_fail_closed_before_monitor_only_handoff',
      );
    }

    if (snapshot.anyEnabledAutoRole) {
      return _blocked(
        AgentProductionRolloutSnapshotPolicyStatus.blockedLiveAutoDetected,
        'live_enabled_auto_role_detected_before_controlled_rollout',
      );
    }

    if (!ownerApproval.explicitOwnerApproval) {
      return _blocked(
        AgentProductionRolloutSnapshotPolicyStatus.blockedOwnerApproval,
        'explicit_owner_approval_required',
      );
    }

    if (now.isBefore(ownerApproval.approvedAtUtc) ||
        !now.isBefore(ownerApproval.expiresAtUtc)) {
      return _blocked(
        AgentProductionRolloutSnapshotPolicyStatus.blockedApprovalExpired,
        'owner_approval_not_current',
      );
    }

    if (!ownerApproval.bindsSnapshot(snapshot.snapshotFingerprintSha256)) {
      return _blocked(
        AgentProductionRolloutSnapshotPolicyStatus.blockedApprovalBinding,
        'owner_approval_snapshot_fingerprint_mismatch',
      );
    }

    if (ownerApproval.requestedStage !=
        AgentProductionRolloutStage.monitorOnly) {
      return _blocked(
        AgentProductionRolloutSnapshotPolicyStatus.blockedStageSkip,
        'phase66_initial_rollout_cannot_skip_monitor_only',
      );
    }

    return const AgentProductionRolloutSnapshotDecision(
      status:
          AgentProductionRolloutSnapshotPolicyStatus.eligibleMonitorOnlyHandoff,
      reasonCode:
          'exact_live_state_and_owner_approval_bound_monitor_only_handoff_eligible_not_activated',
      monitorOnlyHandoffEligible: true,
    );
  }

  AgentProductionRolloutSnapshotDecision _blocked(
    String status,
    String reasonCode,
  ) {
    return AgentProductionRolloutSnapshotDecision(
      status: status,
      reasonCode: reasonCode,
      monitorOnlyHandoffEligible: false,
    );
  }

  bool get policyOnly => true;
  bool get activatesRollout => false;
  bool get changesAgentMode => false;
  bool get changesMasterSettings => false;
  bool get consumesApproval => false;
  bool get grantsPermission => false;
  bool get overridesRuntimeGate => false;
  bool get changesEmergencyStop => false;
  bool get callsProvider => false;
  bool get readsFirestore => false;
  bool get writesFirestore => false;
  bool get writesBusinessData => false;
}
