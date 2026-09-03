import '../constants/agent_production_rollout_runtime_guard_constants.dart';
import '../models/agent_production_rollout_activation_models.dart';
import '../models/agent_production_rollout_arming_token_models.dart';
import '../models/agent_production_rollout_runtime_guard.dart';
import 'agent_production_rollout_guard_repository.dart';

class AgentProductionRolloutOwnerBoundGuardCoordinator {
  const AgentProductionRolloutOwnerBoundGuardCoordinator({
    required this.guardRepository,
  });

  final AgentProductionRolloutGuardRepository guardRepository;

  AgentProductionRolloutOwnerBoundGuardRequest build({
    required AgentProductionRolloutTrustedLivePreflight preflight,
    required AgentProductionRolloutMonitorActivationPlan plan,
    required int expectedPreviousRevision,
  }) {
    preflight.validate();
    plan.validate();

    final AgentProductionRolloutRuntimeGuard guard =
        AgentProductionRolloutRuntimeGuard(
          enabled: true,
          guardVersion: AgentProductionRolloutRuntimeGuardVersion.monitorOnlyV1,
          revision: expectedPreviousRevision + 1,
          targetStage: AgentProductionRolloutRuntimeGuardStatus.monitorOnly,
          runtimeMonitorOnlyOverlayEnforced: true,
          noAutoBusinessWriteBoundaryEnforced: true,
          appChatOnly: true,
          autoTrafficPercent: 0,
          businessWriteTrafficPercent: 0,
          externalChannelsEnabled: false,
          controlStateFingerprintSha256:
              preflight.controlStateFingerprintSha256,
          planFingerprintSha256: preflight.planFingerprintSha256,
          roleCount: preflight.roleCount,
          ownerApprovalId: preflight.ownerApprovalId,
          actorReferenceSha256: preflight.actorReferenceSha256,
        );

    return AgentProductionRolloutOwnerBoundGuardRequest(
      preflight: preflight,
      plan: plan,
      guard: guard,
      expectedPreviousRevision: expectedPreviousRevision,
    );
  }

  Future<AgentProductionRolloutGuardPersistenceResult> persistExactGuard({
    required AgentProductionRolloutOwnerBoundGuardRequest request,
    required DateTime requestedAtUtc,
  }) {
    request.validate();

    return guardRepository.persist(
      request: AgentProductionRolloutGuardPersistenceRequest(
        guard: request.guard,
        expectedPreviousRevision: request.expectedPreviousRevision,
        requestedAtUtc: requestedAtUtc.toUtc(),
      ),
    );
  }

  bool get exactBindingRequired => true;
  bool get grantsPermission => false;
  bool get activatesProduction => false;
  bool get armsActivationRepository => false;
}
