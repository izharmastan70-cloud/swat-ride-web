import '../constants/agent_cross_agent_supervisor_coordination_constants.dart';

class AgentCrossAgentSupervisorOwnerCandidate {
  const AgentCrossAgentSupervisorOwnerCandidate({
    required this.candidateId,
    required this.agentId,
    required this.agentRoleId,
    required this.moduleId,
    required this.actionId,
    required this.enabled,
    required this.healthy,
    required this.authoritativeRoleEligible,
    required this.authoritativeModuleEligible,
    required this.authoritativeScopeEligible,
    required this.authoritativeSecurityEligible,
    required this.primaryForTask,
  });

  final String candidateId;
  final String agentId;
  final String agentRoleId;
  final String moduleId;
  final String actionId;

  final bool enabled;
  final bool healthy;

  /// These are authoritative/prevalidated eligibility outcomes.
  /// Supervisor does not calculate or grant them.
  final bool authoritativeRoleEligible;
  final bool authoritativeModuleEligible;
  final bool authoritativeScopeEligible;
  final bool authoritativeSecurityEligible;

  /// Comes from the existing task/role ownership registry or contract.
  /// Supervisor cannot self-declare a primary owner.
  final bool primaryForTask;

  bool get eligible =>
      enabled &&
      healthy &&
      authoritativeRoleEligible &&
      authoritativeModuleEligible &&
      authoritativeScopeEligible &&
      authoritativeSecurityEligible;

  bool get supervisorGrantedEligibility => false;
  bool get supervisorGrantedPrimaryOwnership => false;

  bool get grantsPermission => false;
  bool get createsApproval => false;
  bool get expandsScope => false;
  bool get assignsRole => false;
  bool get executesBusinessAction => false;
  bool get mutatesTaskOwnership => false;

  void validateStructure() {
    final List<String> values = <String>[
      candidateId,
      agentId,
      agentRoleId,
      moduleId,
      actionId,
    ];

    final bool invalid = values.any((String value) {
      final String trimmed = value.trim();

      return trimmed.isEmpty ||
          trimmed.length >
              AgentCrossAgentSupervisorCoordinationLimits.opaqueIdMaxLength ||
          !RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(trimmed);
    });

    if (invalid) {
      throw const FormatException(
        'Invalid Cross-Agent Supervisor owner candidate.',
      );
    }
  }
}
