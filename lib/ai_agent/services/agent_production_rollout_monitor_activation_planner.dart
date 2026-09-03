import '../constants/agent_production_rollout_activation_constants.dart';
import '../constants/agent_production_rollout_snapshot_constants.dart';
import '../models/agent_production_rollout_activation_models.dart';
import '../models/agent_production_rollout_owner_approval.dart';
import 'agent_production_rollout_snapshot_policy.dart';

class AgentProductionRolloutMonitorActivationPlanner {
  const AgentProductionRolloutMonitorActivationPlanner({
    this.snapshotPolicy = const AgentProductionRolloutSnapshotPolicy(),
  });

  final AgentProductionRolloutSnapshotPolicy snapshotPolicy;

  AgentProductionRolloutMonitorPlanDecision plan({
    required AgentProductionRolloutTrustedCapture capture,
    required AgentProductionRolloutOwnerApproval ownerApproval,
    required DateTime evaluatedAtUtc,
    required String planId,
    required bool phase65SafetyReady,
    required bool phase62VersionSafetyReady,
    required bool auditReady,
    required bool coreFailureIsolationReady,
    required bool providerPolicyReady,
    required bool emergencyStopClearanceApproved,
  }) {
    capture.validate();
    ownerApproval.validate();

    final snapshotDecision = snapshotPolicy.evaluate(
      snapshot: capture.snapshot,
      ownerApproval: ownerApproval,
      evaluatedAtUtc: evaluatedAtUtc.toUtc(),
      phase65SafetyReady: phase65SafetyReady,
      phase62VersionSafetyReady: phase62VersionSafetyReady,
    );

    if (!snapshotDecision.monitorOnlyHandoffEligible) {
      return const AgentProductionRolloutMonitorPlanDecision(
        status: AgentProductionRolloutMonitorPlanStatus.blockedSnapshotPolicy,
        reasonCode: 'step1b_snapshot_policy_not_eligible',
        plan: null,
      );
    }

    if (capture.snapshot.roleCount <= 0) {
      return const AgentProductionRolloutMonitorPlanDecision(
        status: AgentProductionRolloutMonitorPlanStatus.blockedEmptyRoleSet,
        reasonCode: 'live_role_set_cannot_be_empty',
        plan: null,
      );
    }

    if (capture.controlStateFingerprintSha256.trim().length != 64) {
      return const AgentProductionRolloutMonitorPlanDecision(
        status:
            AgentProductionRolloutMonitorPlanStatus.blockedControlStateBinding,
        reasonCode: 'exact_control_state_sha256_required',
        plan: null,
      );
    }

    if (!auditReady) {
      return const AgentProductionRolloutMonitorPlanDecision(
        status: AgentProductionRolloutMonitorPlanStatus.blockedAuditReadiness,
        reasonCode: 'atomic_audit_readiness_required',
        plan: null,
      );
    }

    if (!coreFailureIsolationReady) {
      return const AgentProductionRolloutMonitorPlanDecision(
        status:
            AgentProductionRolloutMonitorPlanStatus.blockedCoreFailureIsolation,
        reasonCode: 'core_swat_ride_failure_isolation_required',
        plan: null,
      );
    }

    if (!providerPolicyReady) {
      return const AgentProductionRolloutMonitorPlanDecision(
        status: AgentProductionRolloutMonitorPlanStatus.blockedProviderPolicy,
        reasonCode: 'free_first_provider_policy_readiness_required',
        plan: null,
      );
    }

    if (!emergencyStopClearanceApproved) {
      return const AgentProductionRolloutMonitorPlanDecision(
        status:
            AgentProductionRolloutMonitorPlanStatus.blockedEmergencyClearance,
        reasonCode:
            'explicit_emergency_read_only_clearance_required_for_activation_plan',
        plan: null,
      );
    }

    final DateTime plannedAt = evaluatedAtUtc.toUtc();

    DateTime preconditionExpiry = plannedAt.add(
      AgentProductionRolloutActivationLimits.atomicPreconditionMaxValidity,
    );

    if (ownerApproval.expiresAtUtc.isBefore(preconditionExpiry)) {
      preconditionExpiry = ownerApproval.expiresAtUtc;
    }

    if (!preconditionExpiry.isAfter(plannedAt)) {
      return const AgentProductionRolloutMonitorPlanDecision(
        status: AgentProductionRolloutMonitorPlanStatus.blockedSnapshotPolicy,
        reasonCode: 'owner_approval_expires_before_atomic_precondition',
        plan: null,
      );
    }

    final AgentProductionRolloutAtomicPrecondition precondition =
        AgentProductionRolloutAtomicPrecondition(
          expectedSnapshotFingerprintSha256:
              capture.snapshot.snapshotFingerprintSha256,
          expectedControlStateFingerprintSha256:
              capture.controlStateFingerprintSha256,
          expectedRoleCount: capture.snapshot.roleCount,
          expectedMasterEnabled: false,
          expectedEmergencyReadOnly: true,
          expectedNoEnabledAutoRole: true,
          targetStage: AgentProductionRolloutStage.monitorOnly,
          createdAtUtc: plannedAt,
          expiresAtUtc: preconditionExpiry,
        );

    final AgentProductionRolloutMonitorActivationPlan plan =
        AgentProductionRolloutMonitorActivationPlan(
          planId: planId,
          ownerApprovalId: ownerApproval.approvalId,
          actorReferenceSha256: capture.actorReferenceSha256,
          sourceSnapshotFingerprintSha256:
              capture.snapshot.snapshotFingerprintSha256,
          sourceControlStateFingerprintSha256:
              capture.controlStateFingerprintSha256,
          targetStage: AgentProductionRolloutStage.monitorOnly,
          targetMasterEnabled: true,
          targetEmergencyReadOnly: false,
          targetFreeAiEnabled: true,
          targetLocalAiEnabled: false,
          targetPaidCodeAiEnabled: false,
          targetPaidReasoningEnabled: false,
          targetCallAgentEnabled: false,
          autoTrafficPercent:
              AgentProductionRolloutActivationLimits.autoTrafficPercent,
          businessWriteTrafficPercent: AgentProductionRolloutActivationLimits
              .businessWriteTrafficPercent,
          channelsRemainDisabledExceptAppChat: true,
          precondition: precondition,
          plannedAtUtc: plannedAt,
        );

    return AgentProductionRolloutMonitorPlanDecision(
      status: AgentProductionRolloutMonitorPlanStatus.eligibleMonitorOnlyPlan,
      reasonCode: 'monitor_only_atomic_activation_plan_eligible_not_executed',
      plan: plan,
    );
  }

  bool get plannerOnly => true;
  bool get writesFirestore => false;
  bool get consumesApproval => false;
  bool get grantsPermission => false;
  bool get changesMasterSettings => false;
  bool get changesAgentMode => false;
  bool get activatesRollout => false;
  bool get routesTraffic => false;
  bool get callsProvider => false;
  bool get executesBusinessAction => false;
}
