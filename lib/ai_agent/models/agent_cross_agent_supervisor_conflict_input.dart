import '../constants/agent_cross_agent_supervisor_conflict_constants.dart';
import 'agent_cross_agent_supervisor_work_claim.dart';

class AgentCrossAgentSupervisorConflictInput {
  AgentCrossAgentSupervisorConflictInput({
    required List<AgentCrossAgentSupervisorWorkClaim> claims,
  }) : claims = List<AgentCrossAgentSupervisorWorkClaim>.unmodifiable(claims);

  final List<AgentCrossAgentSupervisorWorkClaim> claims;

  bool get hasDuplicateClaimId {
    final Set<String> seen = <String>{};

    for (final AgentCrossAgentSupervisorWorkClaim claim in claims) {
      if (!seen.add(claim.claimId)) {
        return true;
      }
    }

    return false;
  }

  void validateStructure() {
    if (claims.isEmpty ||
        claims.length > AgentCrossAgentSupervisorConflictLimits.maxClaims ||
        hasDuplicateClaimId) {
      throw const FormatException(
        'Invalid Cross-Agent Supervisor conflict input.',
      );
    }

    for (final AgentCrossAgentSupervisorWorkClaim claim in claims) {
      claim.validateStructure();
    }
  }
}
