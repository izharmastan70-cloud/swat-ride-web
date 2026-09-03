import '../constants/agent_cross_agent_supervisor_coordination_constants.dart';

class AgentCrossAgentSupervisorCoordinationDecision {
  AgentCrossAgentSupervisorCoordinationDecision({
    required this.status,
    required this.taskId,
    required this.priorityClass,
    required this.recommendedOwnerAgentId,
    required this.recommendHold,
    required this.escalationRecommended,
    required List<String> reasonCodes,
  }) : reasonCodes = List<String>.unmodifiable(reasonCodes);

  final String status;
  final String taskId;
  final String priorityClass;
  final String? recommendedOwnerAgentId;

  final bool recommendHold;
  final bool escalationRecommended;
  final List<String> reasonCodes;

  bool get ownerRecommendationOnly => true;
  bool get taskOwnerMutatedHere => false;
  bool get queueMutatedHere => false;
  bool get priorityPersistedHere => false;

  bool get securityAuthorityAlwaysAboveSupervisor => true;
  bool get priorityCanBypassSecurity => false;
  bool get priorityCanBypassApproval => false;
  bool get priorityCanBypassEmergencyStop => false;

  bool get grantsPermission => false;
  bool get createsApproval => false;
  bool get consumesApproval => false;
  bool get expandsScope => false;
  bool get assignsPrivilegedRole => false;
  bool get authorizesBusinessExecution => false;
  bool get executesBusinessAction => false;

  bool get modifiesSecurityEngine => false;
  bool get mutatesRouting => false;
  bool get mutatesProviderState => false;
  bool get mutatesBudget => false;
  bool get persistsDecision => false;

  void validateStructure() {
    if (!AgentCrossAgentOwnershipStatus.values.contains(status) ||
        !AgentCrossAgentCoordinationPriority.values.contains(priorityClass) ||
        taskId.trim().isEmpty ||
        reasonCodes.isEmpty ||
        reasonCodes.length >
            AgentCrossAgentSupervisorCoordinationLimits.maxReasonCodes) {
      throw const FormatException(
        'Invalid Cross-Agent Supervisor coordination decision.',
      );
    }

    final bool shouldHaveOwner =
        status == AgentCrossAgentOwnershipStatus.ownerRecommended;

    if (shouldHaveOwner !=
        (recommendedOwnerAgentId != null &&
            recommendedOwnerAgentId!.trim().isNotEmpty)) {
      throw const FormatException(
        'Owner recommendation status/owner mismatch.',
      );
    }

    if (shouldHaveOwner && recommendHold) {
      throw const FormatException(
        'Owner recommendation cannot also recommend HOLD.',
      );
    }
  }
}
