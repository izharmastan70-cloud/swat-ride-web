import '../constants/agent_cross_agent_supervisor_conflict_constants.dart';

class AgentCrossAgentSupervisorConflictFinding {
  const AgentCrossAgentSupervisorConflictFinding({
    required this.type,
    required this.primaryClaimId,
    required this.relatedClaimId,
    required this.reasonCode,
  });

  final String type;
  final String primaryClaimId;
  final String? relatedClaimId;
  final String reasonCode;

  bool get metadataOnly => true;
  bool get grantsPermission => false;
  bool get createsApproval => false;
  bool get authorizesExecution => false;
  bool get executesBusinessAction => false;
  bool get mutatesRouting => false;
  bool get mutatesTaskOwnership => false;
  bool get persistsFinding => false;

  void validateStructure() {
    if (!AgentCrossAgentConflictType.values.contains(type) ||
        type == AgentCrossAgentConflictType.none ||
        primaryClaimId.trim().isEmpty ||
        reasonCode.trim().isEmpty) {
      throw const FormatException(
        'Invalid Cross-Agent Supervisor conflict finding.',
      );
    }
  }
}
