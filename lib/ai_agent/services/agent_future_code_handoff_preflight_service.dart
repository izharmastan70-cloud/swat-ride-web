import '../constants/agent_future_proposal_constants.dart';
import '../models/agent_approval_request.dart';
import '../models/agent_future_code_handoff.dart';
import '../models/agent_future_proposal.dart';
import 'agent_approval_service.dart';
import 'agent_future_proposal_review_service.dart';

/// Read-only preflight for Phase 41-F.
///
/// This service verifies that:
/// - the Future proposal is APPROVED;
/// - a central approval is bound;
/// - the approval is APPROVED and still consumable;
/// - role/action/module and exact proposal scope still match;
/// - the produced Code Agent package grants NO write/provider/deploy authority.
///
/// It intentionally does NOT consume the approval in F1.
/// It intentionally does NOT enqueue a Code Agent task.
class AgentFutureCodeHandoffPreflightService {
  AgentFutureCodeHandoffPreflightService({
    AgentApprovalService? approvalService,
    AgentFutureProposalReviewService? reviewService,
  }) : approvalService = approvalService ?? AgentApprovalService(),
       reviewService = reviewService ?? AgentFutureProposalReviewService();

  final AgentApprovalService approvalService;
  final AgentFutureProposalReviewService reviewService;

  Future<AgentFutureCodeHandoff> prepare({
    required AgentFutureProposal proposal,
  }) async {
    proposal.validate();

    if (proposal.status != AgentFutureProposalStatus.approved) {
      throw AgentFutureCodeHandoffPreflightException(
        'Only APPROVED Future proposals may enter Code Agent handoff. '
        'Current status: ${proposal.status}.',
      );
    }

    final String approvalId = proposal.superAdminApprovalId.trim();

    if (approvalId.isEmpty) {
      throw const AgentFutureCodeHandoffPreflightException(
        'Approved proposal has no central Super Admin approval ID.',
      );
    }

    if (proposal.approvedBy.trim().isEmpty) {
      throw const AgentFutureCodeHandoffPreflightException(
        'Approved proposal has no Super Admin approver identity.',
      );
    }

    final AgentApprovalRequest? approval = await approvalService.getRequest(
      approvalId,
    );

    if (approval == null) {
      throw const AgentFutureCodeHandoffPreflightException(
        'Bound central approval request was not found.',
      );
    }

    approval.validate();

    if (approval.status != AgentApprovalStatus.approved) {
      throw AgentFutureCodeHandoffPreflightException(
        'Central proposal approval must be APPROVED before handoff. '
        'Current approval status: ${approval.status}.',
      );
    }

    if (!approval.canBeConsumed) {
      throw const AgentFutureCodeHandoffPreflightException(
        'Central proposal approval is not safely consumable.',
      );
    }

    if (approval.roleId != AgentFutureProposalApprovalContract.roleId ||
        approval.actionId != AgentFutureProposalApprovalContract.actionId ||
        approval.module != AgentFutureProposalApprovalContract.module ||
        approval.approvalId != proposal.superAdminApprovalId) {
      throw const AgentFutureCodeHandoffPreflightException(
        'Central approval identity does not match the Future proposal contract.',
      );
    }

    final Map<String, dynamic> expectedScope = reviewService.buildApprovalScope(
      proposal,
    );

    if (!_mapsEquivalent(approval.actionScope, expectedScope)) {
      throw const AgentFutureCodeHandoffPreflightException(
        'Central approval scope no longer matches the approved Future proposal.',
      );
    }

    final AgentFutureCodeHandoff handoff = AgentFutureCodeHandoff(
      handoffId: 'future_code_handoff_${proposal.proposalId}',
      proposalId: proposal.proposalId,
      proposalApprovalId: approval.approvalId,
      proposalApprovedBy: proposal.approvedBy,
      problem: proposal.problem,
      affectedModule: proposal.affectedModule,
      proposedSolution: proposal.proposedSolution,
      expectedBenefit: proposal.expectedBenefit,
      evidenceRefs: _normalized(proposal.evidenceRefs),
      affectedUserCount: proposal.affectedUserCount,
      affectedEventCount: proposal.affectedEventCount,
      risk: proposal.risk,
      developmentComplexity: proposal.developmentComplexity,
      candidateFiles: _normalized(proposal.affectedFiles),
      affectedModules: _normalized(proposal.affectedModules),
      aiConfidence: proposal.aiConfidence,
      targetAgentRoleId: 'code_agent',
      status: AgentFutureCodeHandoffStatus.readyForApprovalConsumption,
      createdAt: DateTime.now().toUtc(),
    );

    handoff.validate();
    return handoff;
  }

  bool _mapsEquivalent(
    Map<String, dynamic> first,
    Map<String, dynamic> second,
  ) {
    if (first.length != second.length) {
      return false;
    }

    for (final String key in second.keys) {
      if (!first.containsKey(key)) {
        return false;
      }

      final dynamic a = first[key];
      final dynamic b = second[key];

      if (a is Iterable && b is Iterable) {
        if (!_stringSetsEqual(a, b)) {
          return false;
        }
        continue;
      }

      if (a is num && b is num) {
        if (a.toDouble() != b.toDouble()) {
          return false;
        }
        continue;
      }

      if (a != b) {
        return false;
      }
    }

    return true;
  }

  bool _stringSetsEqual(Iterable<dynamic> first, Iterable<dynamic> second) {
    final Set<String> a = first
        .map((dynamic item) => item.toString().trim())
        .where((String item) => item.isNotEmpty)
        .toSet();

    final Set<String> b = second
        .map((dynamic item) => item.toString().trim())
        .where((String item) => item.isNotEmpty)
        .toSet();

    return a.length == b.length && a.containsAll(b);
  }

  List<String> _normalized(Iterable<String> values) {
    final List<String> result = values
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);

    result.sort();
    return result;
  }
}

class AgentFutureCodeHandoffPreflightException implements Exception {
  const AgentFutureCodeHandoffPreflightException(this.message);

  final String message;

  @override
  String toString() => 'AgentFutureCodeHandoffPreflightException: $message';
}
