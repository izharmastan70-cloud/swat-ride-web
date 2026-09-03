import '../constants/agent_cross_agent_supervisor_coordination_constants.dart';
import '../models/agent_cross_agent_supervisor_coordination_request.dart';
import '../models/agent_cross_agent_supervisor_owner_candidate.dart';

class AgentCrossAgentSupervisorOwnershipEvaluation {
  const AgentCrossAgentSupervisorOwnershipEvaluation({
    required this.status,
    required this.recommendedOwnerAgentId,
    required this.reasonCode,
  });

  final String status;
  final String? recommendedOwnerAgentId;
  final String reasonCode;
}

class AgentCrossAgentSupervisorSafeOwnershipPolicy {
  const AgentCrossAgentSupervisorSafeOwnershipPolicy();

  AgentCrossAgentSupervisorOwnershipEvaluation evaluate(
    AgentCrossAgentSupervisorCoordinationRequest request,
  ) {
    final List<AgentCrossAgentSupervisorOwnerCandidate> matching = request
        .ownerCandidates
        .where(
          (AgentCrossAgentSupervisorOwnerCandidate candidate) =>
              candidate.moduleId == request.moduleId &&
              candidate.actionId == request.actionId &&
              candidate.eligible,
        )
        .toList(growable: false);

    if (matching.isEmpty) {
      return const AgentCrossAgentSupervisorOwnershipEvaluation(
        status: AgentCrossAgentOwnershipStatus.holdNoEligibleOwner,
        recommendedOwnerAgentId: null,
        reasonCode: 'no_authoritatively_eligible_owner',
      );
    }

    final List<AgentCrossAgentSupervisorOwnerCandidate> primary = matching
        .where(
          (AgentCrossAgentSupervisorOwnerCandidate candidate) =>
              candidate.primaryForTask,
        )
        .toList(growable: false);

    if (primary.length == 1) {
      return AgentCrossAgentSupervisorOwnershipEvaluation(
        status: AgentCrossAgentOwnershipStatus.ownerRecommended,
        recommendedOwnerAgentId: primary.single.agentId,
        reasonCode: 'unique_authoritative_primary_owner',
      );
    }

    if (primary.length > 1) {
      return const AgentCrossAgentSupervisorOwnershipEvaluation(
        status: AgentCrossAgentOwnershipStatus.holdAmbiguousOwner,
        recommendedOwnerAgentId: null,
        reasonCode: 'multiple_authoritative_primary_owners',
      );
    }

    if (matching.length == 1) {
      return AgentCrossAgentSupervisorOwnershipEvaluation(
        status: AgentCrossAgentOwnershipStatus.ownerRecommended,
        recommendedOwnerAgentId: matching.single.agentId,
        reasonCode: 'sole_authoritatively_eligible_owner',
      );
    }

    return const AgentCrossAgentSupervisorOwnershipEvaluation(
      status: AgentCrossAgentOwnershipStatus.holdAmbiguousOwner,
      recommendedOwnerAgentId: null,
      reasonCode: 'multiple_eligible_owners_without_unique_primary',
    );
  }

  bool get authoritativeEligibilityRequired => true;
  bool get exactModuleMatchRequired => true;
  bool get exactActionMatchRequired => true;
  bool get enabledHealthyRequired => true;
  bool get uniquePrimaryPreferred => true;
  bool get ambiguityFailsClosed => true;

  bool get grantsPermission => false;
  bool get createsApproval => false;
  bool get expandsScope => false;
  bool get assignsPrivilegedRole => false;
  bool get mutatesTaskOwner => false;
  bool get mutatesQueue => false;
  bool get executesBusinessAction => false;
  bool get persistenceImplementedHere => false;
}
