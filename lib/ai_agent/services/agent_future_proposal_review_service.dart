import '../constants/agent_future_proposal_constants.dart';
import '../models/agent_approval_request.dart';
import '../models/agent_future_proposal.dart';
import 'agent_approval_service.dart';

class AgentFutureProposalApprovalContract {
  AgentFutureProposalApprovalContract._();

  static const String roleId = 'future_agent';
  static const String actionId = 'future.approve_proposal';
  static const String module = 'app_future';
}

/// Phase 41 Reviewer + Super Admin approval bridge.
///
/// Reuses the existing central AgentApprovalService. This service does not
/// create a second approval store and never executes Code Agent.
///
/// EDIT behavior:
/// - any still-pending central approval is cancelled first;
/// - the proposal becomes NEEDS_EDIT;
/// - after edit it returns to AWAITING_REVIEW;
/// - a new exact-scope approval request is required.
///
/// APPROVE behavior:
/// - central Approval Inbox/Super Admin approves the AgentApprovalRequest;
/// - this bridge verifies exact proposal scope before marking proposal APPROVED.
///
/// REJECT behavior:
/// - central rejection maps the proposal to REJECTED.
///
/// Approval is intentionally NOT consumed here. Phase 41-F will consume the
/// exact approval only when creating the controlled Code Agent handoff.
class AgentFutureProposalReviewService {
  AgentFutureProposalReviewService({AgentApprovalService? approvalService})
    : approvalService = approvalService ?? AgentApprovalService();

  final AgentApprovalService approvalService;

  Future<AgentFutureProposal> submitForSuperAdminApproval({
    required AgentFutureProposal proposal,
    required String reviewerId,
    required String reviewNote,
    Duration validity = const Duration(minutes: 30),
  }) async {
    proposal.validate();

    if (proposal.status != AgentFutureProposalStatus.awaitingReview) {
      throw AgentFutureProposalReviewException(
        'Only AWAITING_REVIEW proposals may enter Super Admin approval. '
        'Current status: ${proposal.status}.',
      );
    }

    if (reviewerId.trim().isEmpty) {
      throw const AgentFutureProposalReviewException(
        'reviewerId cannot be empty.',
      );
    }

    if (proposal.superAdminApprovalId.trim().isNotEmpty) {
      final AgentApprovalRequest? existing = await approvalService.getRequest(
        proposal.superAdminApprovalId,
      );

      if (existing != null && existing.isPending && !existing.isExpiredNow) {
        throw const AgentFutureProposalReviewException(
          'Proposal already has a pending Super Admin approval request.',
        );
      }
    }

    final AgentApprovalRequest approval = await approvalService.createRequest(
      roleId: AgentFutureProposalApprovalContract.roleId,
      actionId: AgentFutureProposalApprovalContract.actionId,
      module: AgentFutureProposalApprovalContract.module,
      reason:
          'Super Admin review required for Future proposal '
          '${proposal.proposalId}: ${proposal.problem}',
      risk: proposal.risk,
      requestedBy: reviewerId.trim(),
      actionScope: buildApprovalScope(proposal),
      validity: validity,
    );

    approval.validate();

    return proposal.copyWith(
      reviewerId: reviewerId.trim(),
      reviewNote: reviewNote.trim(),
      superAdminApprovalId: approval.approvalId,
      approvedBy: '',
      updatedAt: DateTime.now().toUtc(),
    );
  }

  Future<AgentFutureProposal> requestEdit({
    required AgentFutureProposal proposal,
    required String reviewerId,
    required String reviewNote,
  }) async {
    proposal.validate();

    if (reviewerId.trim().isEmpty || reviewNote.trim().isEmpty) {
      throw const AgentFutureProposalReviewException(
        'Reviewer identity and edit reason are required.',
      );
    }

    if (proposal.status == AgentFutureProposalStatus.approved ||
        proposal.status == AgentFutureProposalStatus.rejected ||
        proposal.isTerminal) {
      throw AgentFutureProposalReviewException(
        'Proposal in status ${proposal.status} cannot enter edit flow.',
      );
    }

    if (proposal.superAdminApprovalId.trim().isNotEmpty) {
      final AgentApprovalRequest? approval = await approvalService.getRequest(
        proposal.superAdminApprovalId,
      );

      if (approval != null && approval.isPending && !approval.isExpiredNow) {
        await approvalService.cancelRequest(
          approvalId: approval.approvalId,
          cancelledBy: reviewerId.trim(),
          note:
              'Future proposal moved to EDIT. Old approval scope invalidated.',
        );
      }
    }

    final AgentFutureProposal editedState = proposal.copyWith(
      status: AgentFutureProposalStatus.needsEdit,
      reviewerId: reviewerId.trim(),
      reviewNote: reviewNote.trim(),
      superAdminApprovalId: '',
      approvedBy: '',
      updatedAt: DateTime.now().toUtc(),
    );

    editedState.validate();
    return editedState;
  }

  AgentFutureProposal applyEdit({
    required AgentFutureProposal proposal,
    required String editorId,
    String? problem,
    String? affectedModule,
    String? proposedSolution,
    String? expectedBenefit,
    String? risk,
    String? developmentComplexity,
    List<String>? affectedFiles,
    List<String>? affectedModules,
    double? aiConfidence,
    String reviewNote = '',
  }) {
    proposal.validate();

    if (proposal.status != AgentFutureProposalStatus.needsEdit) {
      throw AgentFutureProposalReviewException(
        'Only NEEDS_EDIT proposals may be edited. '
        'Current status: ${proposal.status}.',
      );
    }

    if (editorId.trim().isEmpty) {
      throw const AgentFutureProposalReviewException(
        'editorId cannot be empty.',
      );
    }

    final AgentFutureProposal revised = proposal.copyWith(
      problem: problem?.trim(),
      affectedModule: affectedModule?.trim(),
      proposedSolution: proposedSolution?.trim(),
      expectedBenefit: expectedBenefit?.trim(),
      risk: risk,
      developmentComplexity: developmentComplexity,
      affectedFiles: affectedFiles == null ? null : _normalized(affectedFiles),
      affectedModules: affectedModules == null
          ? null
          : _normalized(affectedModules),
      aiConfidence: aiConfidence,
      status: AgentFutureProposalStatus.awaitingReview,
      reviewerId: editorId.trim(),
      reviewNote: reviewNote.trim(),
      superAdminApprovalId: '',
      approvedBy: '',
      updatedAt: DateTime.now().toUtc(),
    );

    revised.validate();
    return revised;
  }

  Future<AgentFutureProposal> syncSuperAdminDecision({
    required AgentFutureProposal proposal,
  }) async {
    proposal.validate();

    final String approvalId = proposal.superAdminApprovalId.trim();

    if (approvalId.isEmpty) {
      throw const AgentFutureProposalReviewException(
        'Proposal has no bound Super Admin approval request.',
      );
    }

    final AgentApprovalRequest? approval = await approvalService.getRequest(
      approvalId,
    );

    if (approval == null) {
      throw const AgentFutureProposalReviewException(
        'Bound Super Admin approval request was not found.',
      );
    }

    approval.validate();

    if (!_approvalMatchesProposal(approval: approval, proposal: proposal)) {
      throw const AgentFutureProposalReviewException(
        'Central approval scope no longer matches the Future proposal.',
      );
    }

    if (approval.status == AgentApprovalStatus.pending) {
      return proposal;
    }

    if (approval.status == AgentApprovalStatus.approved) {
      final AgentFutureProposal approved = proposal.copyWith(
        status: AgentFutureProposalStatus.approved,
        approvedBy: (approval.decidedBy ?? '').trim(),
        reviewNote: (approval.decisionNote ?? proposal.reviewNote).trim(),
        updatedAt: DateTime.now().toUtc(),
      );

      approved.validate();
      return approved;
    }

    if (approval.status == AgentApprovalStatus.rejected) {
      final AgentFutureProposal rejected = proposal.copyWith(
        status: AgentFutureProposalStatus.rejected,
        approvedBy: '',
        reviewNote: (approval.decisionNote ?? proposal.reviewNote).trim(),
        updatedAt: DateTime.now().toUtc(),
      );

      rejected.validate();
      return rejected;
    }

    if (approval.status == AgentApprovalStatus.expired ||
        approval.status == AgentApprovalStatus.cancelled) {
      final AgentFutureProposal retryable = proposal.copyWith(
        status: AgentFutureProposalStatus.awaitingReview,
        superAdminApprovalId: '',
        approvedBy: '',
        reviewNote:
            'Previous Super Admin approval ${approval.status.toLowerCase()}. '
            'A new exact-scope approval is required.',
        updatedAt: DateTime.now().toUtc(),
      );

      retryable.validate();
      return retryable;
    }

    throw AgentFutureProposalReviewException(
      'Unsupported approval state for review sync: ${approval.status}.',
    );
  }

  Map<String, dynamic> buildApprovalScope(AgentFutureProposal proposal) {
    proposal.validate();

    return <String, dynamic>{
      'proposalId': proposal.proposalId,
      'problem': proposal.problem,
      'affectedModule': proposal.affectedModule,
      'evidenceRefs': _normalized(proposal.evidenceRefs),
      'affectedUserCount': proposal.affectedUserCount,
      'affectedEventCount': proposal.affectedEventCount,
      'proposedSolution': proposal.proposedSolution,
      'expectedBenefit': proposal.expectedBenefit,
      'risk': proposal.risk,
      'developmentComplexity': proposal.developmentComplexity,
      'affectedFiles': _normalized(proposal.affectedFiles),
      'affectedModules': _normalized(proposal.affectedModules),
      'aiConfidence': proposal.aiConfidence,
      'recommendationOnly': true,
      'directCodeExecutionAllowed': false,
    };
  }

  bool _approvalMatchesProposal({
    required AgentApprovalRequest approval,
    required AgentFutureProposal proposal,
  }) {
    if (approval.roleId != AgentFutureProposalApprovalContract.roleId ||
        approval.actionId != AgentFutureProposalApprovalContract.actionId ||
        approval.module != AgentFutureProposalApprovalContract.module ||
        approval.approvalId != proposal.superAdminApprovalId) {
      return false;
    }

    final Map<String, dynamic> expected = buildApprovalScope(proposal);

    return _mapsEquivalent(approval.actionScope, expected);
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
    final List<String> normalized = values
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);

    normalized.sort();
    return normalized;
  }
}

class AgentFutureProposalReviewException implements Exception {
  const AgentFutureProposalReviewException(this.message);

  final String message;

  @override
  String toString() => 'AgentFutureProposalReviewException: $message';
}
