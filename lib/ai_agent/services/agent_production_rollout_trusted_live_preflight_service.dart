import '../constants/agent_production_rollout_activation_constants.dart';
import '../constants/agent_production_rollout_arming_token_constants.dart';
import '../models/agent_production_rollout_activation_models.dart';
import '../models/agent_production_rollout_arming_token_models.dart';
import '../models/agent_production_rollout_owner_approval.dart';
import 'agent_production_rollout_control_state_binding_service.dart';
import 'agent_production_rollout_live_snapshot_reader.dart';
import 'agent_production_rollout_monitor_plan_binding_service.dart';

class AgentProductionRolloutTrustedLivePreflightService {
  const AgentProductionRolloutTrustedLivePreflightService({
    required this.reader,
    this.controlStateBindingService =
        const AgentProductionRolloutControlStateBindingService(),
    this.planBindingService =
        const AgentProductionRolloutMonitorPlanBindingService(),
  });

  final AgentProductionRolloutLiveSnapshotReader reader;
  final AgentProductionRolloutControlStateBindingService
  controlStateBindingService;
  final AgentProductionRolloutMonitorPlanBindingService planBindingService;

  Future<AgentProductionRolloutTrustedLivePreflightDecision> evaluate({
    required AgentProductionRolloutTrustedOwnerContext trustedContext,
    required AgentProductionRolloutMonitorActivationPlan plan,
    required AgentProductionRolloutOwnerApproval ownerApproval,
    required DateTime nowUtc,
    required String phase65SafetyEvidenceSha256,
    required String phase62VersionEvidenceSha256,
  }) async {
    trustedContext.validate();
    plan.validate();
    ownerApproval.validate();

    final DateTime now = nowUtc.toUtc();

    if (!trustedContext.authorityVerified ||
        !AgentProductionRolloutTrustedActorRole.allowed.contains(
          trustedContext.actorRole,
        ) ||
        trustedContext.actorReferenceSha256.toLowerCase() !=
            plan.actorReferenceSha256.toLowerCase() ||
        ownerApproval.ownerReferenceSha256.toLowerCase() !=
            plan.actorReferenceSha256.toLowerCase()) {
      return const AgentProductionRolloutTrustedLivePreflightDecision(
        status:
            AgentProductionRolloutTrustedPreflightStatus.blockedUntrustedActor,
        reasonCode: 'trusted_owner_super_admin_exact_actor_binding_required',
        preflight: null,
      );
    }

    if (!trustedContext.freshReauthenticationVerified) {
      return const AgentProductionRolloutTrustedLivePreflightDecision(
        status: AgentProductionRolloutTrustedPreflightStatus
            .blockedReauthentication,
        reasonCode: 'fresh_reauthentication_required',
        preflight: null,
      );
    }

    final Duration contextAge = now.difference(trustedContext.issuedAtUtc);

    if (contextAge <
            -AgentProductionRolloutActivationLimits.trustedContextFutureSkew ||
        contextAge >
            AgentProductionRolloutActivationLimits.trustedContextMaxAge) {
      return const AgentProductionRolloutTrustedLivePreflightDecision(
        status:
            AgentProductionRolloutTrustedPreflightStatus.blockedStaleContext,
        reasonCode: 'trusted_runtime_context_outside_allowed_time_window',
        preflight: null,
      );
    }

    if (!ownerApproval.explicitOwnerApproval ||
        ownerApproval.requestedStage != plan.targetStage ||
        ownerApproval.snapshotFingerprintSha256.toLowerCase() !=
            plan.sourceSnapshotFingerprintSha256.toLowerCase() ||
        ownerApproval.approvalId != plan.ownerApprovalId ||
        now.isBefore(ownerApproval.approvedAtUtc) ||
        !now.isBefore(ownerApproval.expiresAtUtc)) {
      return const AgentProductionRolloutTrustedLivePreflightDecision(
        status: AgentProductionRolloutTrustedPreflightStatus.blockedApproval,
        reasonCode: 'current_exact_owner_approval_binding_required',
        preflight: null,
      );
    }

    if (now.isBefore(plan.precondition.createdAtUtc) ||
        !now.isBefore(plan.precondition.expiresAtUtc)) {
      return const AgentProductionRolloutTrustedLivePreflightDecision(
        status: AgentProductionRolloutTrustedPreflightStatus.blockedExpiredPlan,
        reasonCode: 'atomic_monitor_only_plan_precondition_is_not_current',
        preflight: null,
      );
    }

    try {
      final liveSnapshot = await reader.read(
        capturedAtUtc: now,
        phase65SafetyEvidenceSha256: phase65SafetyEvidenceSha256,
        phase62VersionEvidenceSha256: phase62VersionEvidenceSha256,
      );

      final String liveControlSha = controlStateBindingService.bind(
        liveSnapshot,
      );

      if (liveControlSha.toLowerCase() !=
          plan.sourceControlStateFingerprintSha256.toLowerCase()) {
        return const AgentProductionRolloutTrustedLivePreflightDecision(
          status: AgentProductionRolloutTrustedPreflightStatus
              .blockedControlStateChanged,
          reasonCode:
              'live_master_or_role_control_state_changed_after_owner_plan',
          preflight: null,
        );
      }

      if (liveSnapshot.roleCount != plan.precondition.expectedRoleCount) {
        return const AgentProductionRolloutTrustedLivePreflightDecision(
          status: AgentProductionRolloutTrustedPreflightStatus
              .blockedRoleCountChanged,
          reasonCode: 'live_role_count_changed_after_owner_plan',
          preflight: null,
        );
      }

      final Map<String, dynamic> master = liveSnapshot.masterSettingsProjection;

      final bool safeInitialBaseline =
          master['masterEnabled'] == false &&
          master['emergencyReadOnly'] == true &&
          master['freeAiEnabled'] == false &&
          master['localAiEnabled'] == false &&
          master['paidCodeAiEnabled'] == false &&
          master['paidReasoningEnabled'] == false &&
          master['callAgentEnabled'] == false &&
          master['emailAgentEnabled'] == false &&
          master['customerWhatsAppAgentEnabled'] == false &&
          master['ownerWhatsAppAgentEnabled'] == false &&
          master['emergencyWhatsAppAgentEnabled'] == false &&
          master['approvalEngineEnabled'] == true &&
          master['auditLoggingEnabled'] == true &&
          master['askBeforePaid'] == true;

      if (!safeInitialBaseline) {
        return const AgentProductionRolloutTrustedLivePreflightDecision(
          status: AgentProductionRolloutTrustedPreflightStatus
              .blockedUnsafeMasterBaseline,
          reasonCode: 'live_master_is_not_initial_fail_closed_baseline',
          preflight: null,
        );
      }

      final String planFingerprint = planBindingService.fingerprint(plan);

      final AgentProductionRolloutTrustedLivePreflight preflight =
          AgentProductionRolloutTrustedLivePreflight(
            actorReferenceSha256: plan.actorReferenceSha256.toLowerCase(),
            ownerApprovalId: plan.ownerApprovalId,
            ownerApprovedSnapshotFingerprintSha256: plan
                .sourceSnapshotFingerprintSha256
                .toLowerCase(),
            liveSnapshotFingerprintSha256: liveSnapshot
                .snapshotFingerprintSha256
                .toLowerCase(),
            controlStateFingerprintSha256: liveControlSha.toLowerCase(),
            planFingerprintSha256: planFingerprint.toLowerCase(),
            roleCount: liveSnapshot.roleCount,
            preflightAtUtc: now,
          );

      return AgentProductionRolloutTrustedLivePreflightDecision(
        status: AgentProductionRolloutTrustedPreflightStatus.ready,
        reasonCode:
            'fresh_live_control_state_exactly_matches_owner_approved_monitor_plan',
        preflight: preflight,
      );
    } on Object {
      return const AgentProductionRolloutTrustedLivePreflightDecision(
        status: AgentProductionRolloutTrustedPreflightStatus.blockedLiveRead,
        reasonCode: 'trusted_live_preflight_read_or_binding_failed_closed',
        preflight: null,
      );
    }
  }

  bool get preflightOnly => true;
  bool get writesFirestore => false;
  bool get persistsGuard => false;
  bool get issuesToken => false;
  bool get activatesProduction => false;
}
