import '../constants/agent_owner_attention_constants.dart';

class AgentOwnerAttentionPriorityPolicy {
  const AgentOwnerAttentionPriorityPolicy();

  String minimumPriorityFor(String category) {
    switch (category) {
      case AgentOwnerAttentionCategory.seriousComplaint:
      case AgentOwnerAttentionCategory.highValuePaymentDispute:
      case AgentOwnerAttentionCategory.unresolvedCall:
      case AgentOwnerAttentionCategory.agentConflict:
      case AgentOwnerAttentionCategory.pendingSensitiveApproval:
        return AgentOwnerAttentionPriority.high;

      case AgentOwnerAttentionCategory.securityAlert:
      case AgentOwnerAttentionCategory.criticalCrash:
      case AgentOwnerAttentionCategory.fraudFinding:
        return AgentOwnerAttentionPriority.critical;

      case AgentOwnerAttentionCategory.emergencyCase:
        return AgentOwnerAttentionPriority.emergency;

      default:
        throw const FormatException('Unknown Owner Attention category.');
    }
  }

  bool isPriorityAllowed({required String category, required String priority}) {
    if (!AgentOwnerAttentionPriority.values.contains(priority)) {
      return false;
    }

    try {
      return AgentOwnerAttentionPriority.rank(priority) >=
          AgentOwnerAttentionPriority.rank(minimumPriorityFor(category));
    } catch (_) {
      return false;
    }
  }

  bool get priorityGrantsAuthority => false;
}
