import '../constants/agent_cross_agent_supervisor_resilience_constants.dart';
import '../models/agent_cross_agent_supervisor_handoff_hop.dart';
import '../models/agent_cross_agent_supervisor_resilience_input.dart';

class AgentCrossAgentSupervisorLoopDeadlockDetectionPolicy {
  const AgentCrossAgentSupervisorLoopDeadlockDetectionPolicy();

  bool hasAgentLoop(AgentCrossAgentSupervisorResilienceInput input) {
    if (input.handoffs.isEmpty) {
      return false;
    }

    final Set<String> visitedAgents = <String>{};
    final AgentCrossAgentSupervisorHandoffHop first = input.handoffs.first;

    visitedAgents.add(first.fromAgentId);

    for (final AgentCrossAgentSupervisorHandoffHop hop in input.handoffs) {
      if (!visitedAgents.add(hop.toAgentId)) {
        return true;
      }
    }

    return false;
  }

  bool hasDeadlock(AgentCrossAgentSupervisorResilienceInput input) {
    return input.noProgressCycles >=
            AgentCrossAgentSupervisorResilienceLimits
                .deadlockNoProgressCycles ||
        input.handoffs.length >=
            AgentCrossAgentSupervisorResilienceLimits.excessiveHandoffThreshold;
  }

  bool hasRetryStorm(AgentCrossAgentSupervisorResilienceInput input) {
    return input.retryCount >=
            AgentCrossAgentSupervisorResilienceLimits.retryStormThreshold ||
        input.repeatedFailureFingerprintCount >=
            AgentCrossAgentSupervisorResilienceLimits
                .repeatedFailureFingerprintThreshold;
  }

  bool hasAgentFighting(AgentCrossAgentSupervisorResilienceInput input) {
    return input.ownershipFlipCount >=
            AgentCrossAgentSupervisorResilienceLimits.ownershipFlipThreshold ||
        input.undoAttemptCount >=
            AgentCrossAgentSupervisorResilienceLimits.undoAttemptThreshold;
  }

  bool get detectsAtoBtoALoop => true;
  bool get detectsLongerAgentRevisitLoop => true;
  bool get detectsNoProgressDeadlock => true;
  bool get detectsExcessiveHandoffDeadlock => true;
  bool get detectsRetryStorm => true;
  bool get detectsRepeatedFailureStorm => true;
  bool get detectsOwnershipFlipFighting => true;
  bool get detectsUndoAttemptFighting => true;

  bool get executesRollbackHere => false;
  bool get mutatesTaskHere => false;
  bool get mutatesOwnerHere => false;
  bool get persistenceImplementedHere => false;
}
