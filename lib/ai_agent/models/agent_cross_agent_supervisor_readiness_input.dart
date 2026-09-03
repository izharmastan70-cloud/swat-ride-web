import '../constants/agent_cross_agent_supervisor_closeout_constants.dart';
import 'agent_cross_agent_supervisor_adversarial_scenario.dart';

class AgentCrossAgentSupervisorReadinessInput {
  AgentCrossAgentSupervisorReadinessInput({
    required this.readinessId,
    required this.securityContractReady,
    required this.conflictDetectionReady,
    required this.safeCoordinationReady,
    required this.ownerAdminAttentionReady,
    required this.resilienceReady,
    required this.securityAuthorityAlwaysAboveSupervisor,
    required this.supervisorNeverSuperAdmin,
    required this.noPermissionOrApprovalAuthority,
    required this.noBusinessExecutionAuthority,
    required this.noSecurityMutationAuthority,
    required this.coreFailureIsolationReady,
    required List<AgentCrossAgentSupervisorAdversarialScenario>
    adversarialScenarios,
  }) : adversarialScenarios =
           List<AgentCrossAgentSupervisorAdversarialScenario>.unmodifiable(
             adversarialScenarios,
           );

  final String readinessId;

  final bool securityContractReady;
  final bool conflictDetectionReady;
  final bool safeCoordinationReady;
  final bool ownerAdminAttentionReady;
  final bool resilienceReady;

  final bool securityAuthorityAlwaysAboveSupervisor;
  final bool supervisorNeverSuperAdmin;
  final bool noPermissionOrApprovalAuthority;
  final bool noBusinessExecutionAuthority;
  final bool noSecurityMutationAuthority;
  final bool coreFailureIsolationReady;

  final List<AgentCrossAgentSupervisorAdversarialScenario> adversarialScenarios;

  bool get allFoundationLocksReady =>
      securityContractReady &&
      conflictDetectionReady &&
      safeCoordinationReady &&
      ownerAdminAttentionReady &&
      resilienceReady &&
      securityAuthorityAlwaysAboveSupervisor &&
      supervisorNeverSuperAdmin &&
      noPermissionOrApprovalAuthority &&
      noBusinessExecutionAuthority &&
      noSecurityMutationAuthority &&
      coreFailureIsolationReady;

  bool get containsRawUserMessage => false;
  bool get containsRawConversation => false;
  bool get containsPrivatePayload => false;
  bool get containsSecret => false;
  bool get containsRawApprovalToken => false;
  bool get containsRawPermissionToken => false;

  void validateStructure() {
    final String trimmed = readinessId.trim();

    if (trimmed.isEmpty ||
        trimmed.length >
            AgentCrossAgentSupervisorCloseoutLimits.opaqueIdMaxLength ||
        !RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(trimmed) ||
        adversarialScenarios.isEmpty ||
        adversarialScenarios.length >
            AgentCrossAgentSupervisorCloseoutLimits.maxScenarios) {
      throw const FormatException(
        'Invalid Cross-Agent Supervisor readiness input.',
      );
    }

    final Set<String> ids = <String>{};

    for (final AgentCrossAgentSupervisorAdversarialScenario scenario
        in adversarialScenarios) {
      scenario.validateStructure();

      if (!ids.add(scenario.scenarioId)) {
        throw const FormatException(
          'Duplicate Cross-Agent Supervisor adversarial scenario.',
        );
      }
    }
  }
}
