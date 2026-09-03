import '../constants/agent_future_proposal_constants.dart';
import '../models/agent_approval_request.dart';
import '../models/agent_future_code_handoff.dart';
import '../models/agent_future_proposal.dart';
import 'agent_approval_service.dart';
import 'agent_future_code_handoff_preflight_service.dart';
import 'agent_future_code_handoff_repository.dart';
import 'agent_future_proposal_review_service.dart';

class AgentFutureCodeHandoffFinalizeResult {
  const AgentFutureCodeHandoffFinalizeResult({
    required this.handoffId,
    required this.proposalId,
    required this.status,
  });

  final String handoffId;
  final String proposalId;
  final String status;

  bool get taskQueued => false;
  bool get codeAgentExecutionStarted => false;
  bool get codeWriteAuthorized => false;
  bool get paidProviderAuthorized => false;
  bool get deploymentAuthorized => false;
}

/// Phase 41-F2 controlled Future -> Code Agent handoff coordinator.
///
/// Flow:
/// 1. Persist deterministic READY handoff before consuming approval.
/// 2. Consume exact central approval once.
/// 3. If another caller already consumed it, recover from CONSUMED state.
/// 4. Atomically finalize handoff + proposal status + audit.
/// 5. Do NOT enqueue Code Agent task or invoke any provider.
///
/// The result means "Code Agent handoff package is approved and recorded".
/// It does NOT mean Code Agent may write code.
class AgentFutureCodeHandoffService {
  AgentFutureCodeHandoffService({
    AgentApprovalService? approvalService,
    AgentFutureCodeHandoffPreflightService? preflightService,
    AgentFutureCodeHandoffRepository? handoffRepository,
    AgentFutureProposalReviewService? reviewService,
  }) : approvalService = approvalService ?? AgentApprovalService(),
       preflightService =
           preflightService ?? AgentFutureCodeHandoffPreflightService(),
       handoffRepository =
           handoffRepository ?? AgentFutureCodeHandoffRepository(),
       reviewService = reviewService ?? AgentFutureProposalReviewService();

  final AgentApprovalService approvalService;
  final AgentFutureCodeHandoffPreflightService preflightService;
  final AgentFutureCodeHandoffRepository handoffRepository;
  final AgentFutureProposalReviewService reviewService;

  Future<AgentFutureCodeHandoffFinalizeResult> finalize({
    required AgentFutureProposal proposal,
    required String actorId,
  }) async {
    proposal.validate();

    final String normalizedActorId = actorId.trim();

    if (normalizedActorId.isEmpty) {
      throw const AgentFutureCodeHandoffServiceException(
        'actorId cannot be empty.',
      );
    }

    if (proposal.status != AgentFutureProposalStatus.approved &&
        proposal.status != AgentFutureProposalStatus.handedToCodeAgent) {
      throw AgentFutureCodeHandoffServiceException(
        'Future proposal cannot enter/recover Code Agent handoff from '
        '${proposal.status}.',
      );
    }

    final String handoffId = 'future_code_handoff_${proposal.proposalId}';

    final String expectedFingerprint = handoffRepository
        .scopeFingerprintForProposal(proposal);

    AgentFutureCodeHandoffRecord? state = await handoffRepository.getState(
      handoffId,
    );

    if (state == null) {
      if (proposal.status != AgentFutureProposalStatus.approved) {
        throw const AgentFutureCodeHandoffServiceException(
          'HANDED_TO_CODE_AGENT proposal is missing its persisted handoff.',
        );
      }

      final AgentFutureCodeHandoff prepared = await preflightService.prepare(
        proposal: proposal,
      );

      state = await handoffRepository.ensurePrepared(prepared);
    }

    _verifyExistingState(
      state: state,
      proposal: proposal,
      expectedFingerprint: expectedFingerprint,
    );

    if (state.status == AgentFutureCodeHandoffStatus.handedToCodeAgent &&
        proposal.status == AgentFutureProposalStatus.handedToCodeAgent) {
      return AgentFutureCodeHandoffFinalizeResult(
        handoffId: state.handoffId,
        proposalId: state.proposalId,
        status: state.status,
      );
    }

    AgentApprovalRequest? approval = await approvalService.getRequest(
      proposal.superAdminApprovalId,
    );

    if (approval == null) {
      throw const AgentFutureCodeHandoffServiceException(
        'Bound central Future proposal approval was not found.',
      );
    }

    approval.validate();

    if (approval.status == AgentApprovalStatus.approved) {
      final Map<String, dynamic> exactScope = reviewService.buildApprovalScope(
        proposal,
      );

      try {
        approval = await approvalService.consumeApprovedRequest(
          approvalId: proposal.superAdminApprovalId,
          expectedRoleId: AgentFutureProposalApprovalContract.roleId,
          expectedActionId: AgentFutureProposalApprovalContract.actionId,
          expectedModule: AgentFutureProposalApprovalContract.module,
          expectedActionScope: exactScope,
        );
      } catch (_) {
        // Concurrency/recovery: another valid caller may have consumed the
        // exact same approval after our read. Re-read and continue only if
        // the authoritative status is now CONSUMED.
        final AgentApprovalRequest? recovered = await approvalService
            .getRequest(proposal.superAdminApprovalId);

        if (recovered == null ||
            recovered.status != AgentApprovalStatus.consumed) {
          rethrow;
        }

        approval = recovered;
      }
    }

    if (approval.status != AgentApprovalStatus.consumed) {
      throw AgentFutureCodeHandoffServiceException(
        'Future proposal approval must be APPROVED/CONSUMED for handoff. '
        'Current status: ${approval.status}.',
      );
    }

    final AgentFutureCodeHandoffRecord completed = await handoffRepository
        .completeAfterConsumedApproval(
          handoffId: handoffId,
          expectedScopeFingerprint: expectedFingerprint,
          actorId: normalizedActorId,
        );

    return AgentFutureCodeHandoffFinalizeResult(
      handoffId: completed.handoffId,
      proposalId: completed.proposalId,
      status: completed.status,
    );
  }

  void _verifyExistingState({
    required AgentFutureCodeHandoffRecord state,
    required AgentFutureProposal proposal,
    required String expectedFingerprint,
  }) {
    state.validate();

    if (state.handoffId != 'future_code_handoff_${proposal.proposalId}' ||
        state.proposalId != proposal.proposalId ||
        state.proposalApprovalId != proposal.superAdminApprovalId ||
        state.scopeFingerprint != expectedFingerprint) {
      throw const AgentFutureCodeHandoffServiceException(
        'Persisted handoff does not match current approved proposal scope.',
      );
    }
  }
}

class AgentFutureCodeHandoffServiceException implements Exception {
  const AgentFutureCodeHandoffServiceException(this.message);

  final String message;

  @override
  String toString() => 'AgentFutureCodeHandoffServiceException: $message';
}
