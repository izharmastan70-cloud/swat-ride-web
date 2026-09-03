import '../constants/agent_owner_attention_constants.dart';
import '../models/agent_owner_attention_status_transition.dart';

class AgentOwnerAttentionStatusTransitionPolicy {
  const AgentOwnerAttentionStatusTransitionPolicy();

  bool isAllowed(AgentOwnerAttentionStatusTransition transition) {
    try {
      transition.validate();
    } catch (_) {
      return false;
    }

    switch (transition.expectedStatus) {
      case AgentOwnerAttentionStatus.pendingReview:
        return transition.nextStatus == AgentOwnerAttentionStatus.acknowledged;

      case AgentOwnerAttentionStatus.acknowledged:
        return transition.nextStatus == AgentOwnerAttentionStatus.inReview ||
            transition.nextStatus == AgentOwnerAttentionStatus.dismissed;

      case AgentOwnerAttentionStatus.inReview:
        return transition.nextStatus == AgentOwnerAttentionStatus.resolved ||
            transition.nextStatus == AgentOwnerAttentionStatus.dismissed;

      case AgentOwnerAttentionStatus.resolved:
      case AgentOwnerAttentionStatus.dismissed:
        return false;

      default:
        return false;
    }
  }

  bool get workflowOnly => true;
  bool get directSourceResolutionAllowed => false;
  bool get approvalConsumptionAllowed => false;
  bool get permissionGrantAllowed => false;
  bool get businessExecutionAllowed => false;
}
