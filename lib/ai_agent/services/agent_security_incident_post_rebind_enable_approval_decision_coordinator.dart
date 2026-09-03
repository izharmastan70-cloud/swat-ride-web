import '../models/agent_approval_request.dart';
import '../models/agent_security_incident_fresh_owner_claim_verification_result.dart';
import '../models/agent_security_incident_post_rebind_enable_approval_decision_authorization.dart';
import 'agent_approval_service.dart';
import 'agent_security_incident_fresh_owner_claim_verification_service.dart';
import 'agent_security_incident_post_migration_rebind_approval_decision_policy.dart';
import 'agent_security_incident_post_rebind_enable_approval_decision_policy.dart';
import 'agent_security_incident_post_rebind_enable_central_approval_gateway.dart';

typedef AgentSecurityIncidentPostRebindEnableFreshOwnerVerifier =
    Future<AgentSecurityIncidentFreshOwnerClaimVerificationResult> Function(
      String currentAdminId,
    );

class AgentSecurityIncidentPostRebindEnableApprovalDecisionCoordinator {
  AgentSecurityIncidentPostRebindEnableApprovalDecisionCoordinator({
    required this.gateway,
    required this.freshOwnerVerifier,
    this.decisionPolicy =
        const AgentSecurityIncidentPostRebindEnableApprovalDecisionPolicy(),
    this.executionArmed = false,
  });

  factory AgentSecurityIncidentPostRebindEnableApprovalDecisionCoordinator.live({
    bool executionArmed = false,
  }) {
    final AgentApprovalService approvalService = AgentApprovalService();
    final AgentSecurityIncidentFreshOwnerClaimVerificationService
    freshOwnerService =
        AgentSecurityIncidentFreshOwnerClaimVerificationService();

    return AgentSecurityIncidentPostRebindEnableApprovalDecisionCoordinator(
      gateway:
          AgentSecurityIncidentPostRebindEnableCentralApprovalGatewayAdapter(
            approvalService: approvalService,
          ),
      freshOwnerVerifier: (String currentAdminId) {
        return freshOwnerService.verify(currentAdminId: currentAdminId);
      },
      executionArmed: executionArmed,
    );
  }

  final AgentSecurityIncidentPostRebindEnableCentralApprovalGateway gateway;
  final AgentSecurityIncidentPostRebindEnableFreshOwnerVerifier
  freshOwnerVerifier;
  final AgentSecurityIncidentPostRebindEnableApprovalDecisionPolicy
  decisionPolicy;
  final bool executionArmed;

  Stream<List<AgentApprovalRequest>> watchExactPending() {
    return gateway.watchPendingRequests().map(
      (List<AgentApprovalRequest> items) => items
          .where(decisionPolicy.matchesExactPendingRequest)
          .toList(growable: false),
    );
  }

  Future<AgentSecurityIncidentPostRebindEnableApprovalDecisionAuthorization>
  approveObserved({
    required AgentApprovalRequest observed,
    required String currentAdminId,
  }) {
    return _decideObserved(
      observed: observed,
      currentAdminId: currentAdminId,
      decisionAction:
          AgentSecurityIncidentPostRebindEnableApprovalDecisionAction.approve,
    );
  }

  Future<AgentSecurityIncidentPostRebindEnableApprovalDecisionAuthorization>
  rejectObserved({
    required AgentApprovalRequest observed,
    required String currentAdminId,
  }) {
    return _decideObserved(
      observed: observed,
      currentAdminId: currentAdminId,
      decisionAction:
          AgentSecurityIncidentPostRebindEnableApprovalDecisionAction.reject,
    );
  }

  Future<AgentSecurityIncidentPostRebindEnableApprovalDecisionAuthorization>
  _decideObserved({
    required AgentApprovalRequest observed,
    required String currentAdminId,
    required String decisionAction,
  }) async {
    if (!executionArmed) {
      throw StateError(
        'Post-rebind enable approval decision coordinator is not execution-armed.',
      );
    }

    observed.validate();

    if (!decisionPolicy.matchesExactPendingRequest(observed)) {
      throw const FormatException(
        'Observed approval is not the exact fresh PENDING post-rebind enable request.',
      );
    }

    final AgentApprovalRequest? historicalMigrationApproval = await gateway
        .getRequest(
          AgentSecurityIncidentPostMigrationRebindApprovalDecisionPolicy
              .historicalMigrationApprovalId,
        );

    if (historicalMigrationApproval == null) {
      throw StateError(
        'Historical consumed migration approval evidence is unavailable.',
      );
    }

    historicalMigrationApproval.validate();

    final AgentSecurityIncidentFreshOwnerClaimVerificationResult
    freshOwnerVerification = await freshOwnerVerifier(currentAdminId);

    final AgentSecurityIncidentPostRebindEnableApprovalDecisionAuthorization
    authorization = decisionPolicy.evaluate(
      request: observed,
      historicalMigrationApproval: historicalMigrationApproval,
      freshOwnerVerification: freshOwnerVerification,
      currentAdminId: currentAdminId,
      decisionAction: decisionAction,
    );

    if (!authorization.allowed) {
      throw StateError(
        'Fresh Owner post-rebind enable approval decision blocked: '
        '${authorization.reasonCode}',
      );
    }

    final String decidedBy =
        'phase66_owner_sha256:${authorization.ownerApproverReferenceSha256}';

    if (authorization.mayCallCentralApprove) {
      await gateway.approve(
        approvalId: observed.approvalId,
        decidedBy: decidedBy,
      );
    } else if (authorization.mayCallCentralReject) {
      await gateway.reject(
        approvalId: observed.approvalId,
        decidedBy: decidedBy,
      );
    } else {
      throw StateError(
        'Authorized enable decision exposes no APPROVE/REJECT call.',
      );
    }

    return authorization;
  }

  bool get defaultFailClosed => !executionArmed;
  bool get createsCentralApproval => false;
  bool get consumesCentralApproval => false;
  bool get issuesReplacementToken => false;
  bool get consumesReplacementToken => false;
  bool get enablesRole => false;
  bool get releasesMigrationHold => false;
  bool get attachesRuntime => false;
  bool get armsRepository => false;
  bool get writesIncident => false;
  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;
}
