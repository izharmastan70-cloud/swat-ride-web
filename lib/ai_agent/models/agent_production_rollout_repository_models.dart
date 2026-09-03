import '../constants/agent_production_rollout_repository_constants.dart';
import 'agent_production_rollout_activation_models.dart';

class AgentProductionRolloutMonitorExecutionRequest {
  AgentProductionRolloutMonitorExecutionRequest({
    required this.plan,
    required this.planFingerprintSha256,
    required this.idempotencyKeySha256,
    required this.expectedGuardRevision,
    required this.expectedGuardVersion,
    required this.requestedAtUtc,
  }) {
    validate();
  }

  final AgentProductionRolloutMonitorActivationPlan plan;
  final String planFingerprintSha256;
  final String idempotencyKeySha256;
  final int expectedGuardRevision;
  final String expectedGuardVersion;
  final DateTime requestedAtUtc;

  void validate() {
    plan.validate();

    final RegExp sha256 = RegExp(r'^[A-Fa-f0-9]{64}$');

    if (!sha256.hasMatch(planFingerprintSha256) ||
        !sha256.hasMatch(idempotencyKeySha256) ||
        expectedGuardRevision < 1 ||
        expectedGuardVersion !=
            AgentProductionRolloutGuardVersion.monitorOnlyV1 ||
        !requestedAtUtc.isUtc) {
      throw const FormatException(
        'Invalid MONITOR_ONLY activation execution request.',
      );
    }
  }
}

class AgentProductionRolloutActivationRepositoryResult {
  const AgentProductionRolloutActivationRepositoryResult({
    required this.status,
    required this.reasonCode,
    required this.activationId,
    required this.applied,
    required this.idempotentReplay,
  });

  final String status;
  final String reasonCode;
  final String activationId;
  final bool applied;
  final bool idempotentReplay;

  bool get autoEnabled => false;
  bool get businessWriteEnabled => false;
  bool get paidAiEnabled => false;
  bool get externalChannelsEnabled => false;
}
