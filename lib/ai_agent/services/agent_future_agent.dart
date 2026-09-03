import '../models/agent_future_evidence_snapshot.dart';
import '../models/agent_future_proposal.dart';
import 'agent_future_proposal_engine.dart';

/// Phase 41 Product Evolution / Future Agent.
///
/// The agent is intentionally thin. It packages evidence-backed product
/// proposals only and has no direct implementation authority.
class AgentFutureAgent {
  const AgentFutureAgent({this.engine = const AgentFutureProposalEngine()});

  static const String roleId = 'future_agent';

  final AgentFutureProposalEngine engine;

  bool get recommendationOnly => true;
  bool get canImplementFeature => false;
  bool get canInvokeCodeAgentDirectly => false;
  bool get requiresReviewerAndSuperAdmin => true;

  AgentFutureProposal createProposal({
    required AgentFutureEvidenceSnapshot evidence,
    required AgentFutureProposalDraftInput input,
  }) {
    final AgentFutureProposal proposal = engine.buildProposal(
      snapshot: evidence,
      input: input,
    );

    if (!proposal.requiresHumanReview ||
        proposal.mayImplementDirectly ||
        proposal.createdByAgentId.trim().isEmpty) {
      throw const AgentFutureAgentException(
        'Future Agent proposal failed safety boundary verification.',
      );
    }

    return proposal;
  }

  String safeNextStep(AgentFutureProposal proposal) {
    proposal.validate();

    return 'Send proposal to Reviewer/Super Admin for Approve, Reject, or Edit. '
        'Do not hand it directly to Code Agent and do not implement it here.';
  }
}

class AgentFutureAgentException implements Exception {
  const AgentFutureAgentException(this.message);

  final String message;

  @override
  String toString() => 'AgentFutureAgentException: $message';
}
