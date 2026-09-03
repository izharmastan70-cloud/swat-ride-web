import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/agent_audit_constants.dart';
import '../constants/agent_future_proposal_constants.dart';
import '../models/agent_approval_request.dart';
import '../models/agent_future_code_handoff.dart';
import '../models/agent_future_proposal.dart';
import 'agent_audit_service.dart';
import 'agent_future_proposal_review_service.dart';

class AgentFutureCodeHandoffRecord {
  const AgentFutureCodeHandoffRecord({
    required this.handoffId,
    required this.proposalId,
    required this.proposalApprovalId,
    required this.scopeFingerprint,
    required this.status,
  });

  final String handoffId;
  final String proposalId;
  final String proposalApprovalId;
  final String scopeFingerprint;
  final String status;

  void validate() {
    if (handoffId.trim().isEmpty ||
        proposalId.trim().isEmpty ||
        proposalApprovalId.trim().isEmpty ||
        scopeFingerprint.trim().isEmpty) {
      throw const AgentFutureCodeHandoffRepositoryException(
        'Persisted handoff identity/fingerprint cannot be empty.',
      );
    }

    if (!AgentFutureCodeHandoffStatus.isValid(status)) {
      throw AgentFutureCodeHandoffRepositoryException(
        'Persisted handoff has unsupported status: $status',
      );
    }
  }
}

/// Persistence-only repository for the Future -> Code Agent handoff.
///
/// The handoff ID is deterministic per proposal, so repeated finalize calls
/// cannot create multiple logical handoffs.
///
/// Final completion is one Firestore transaction:
/// - verify consumed central approval;
/// - verify persisted handoff fingerprint;
/// - verify exact proposal approval scope;
/// - move proposal to HANDED_TO_CODE_AGENT;
/// - move handoff to HANDED_TO_CODE_AGENT;
/// - append audit in the SAME transaction.
///
/// This repository has no task enqueue, source write, provider, or deploy API.
class AgentFutureCodeHandoffRepository {
  AgentFutureCodeHandoffRepository({FirebaseFirestore? firestore})
    : firestore = firestore ?? FirebaseFirestore.instance {
    auditService = AgentAuditService(firestore: this.firestore);
  }

  static const String collectionPath = 'agent_future_code_handoffs';
  static const String proposalCollectionPath = 'agent_future_proposals';
  static const String approvalCollectionPath = 'agent_approvals';

  final FirebaseFirestore firestore;
  late final AgentAuditService auditService;

  CollectionReference<Map<String, dynamic>> get _handoffs =>
      firestore.collection(collectionPath);

  CollectionReference<Map<String, dynamic>> get _proposals =>
      firestore.collection(proposalCollectionPath);

  CollectionReference<Map<String, dynamic>> get _approvals =>
      firestore.collection(approvalCollectionPath);

  String scopeFingerprintForProposal(AgentFutureProposal proposal) {
    proposal.validate();

    return _fingerprint(<String, dynamic>{
      'proposalId': proposal.proposalId,
      'proposalApprovalId': proposal.superAdminApprovalId,
      'proposalApprovedBy': proposal.approvedBy,
      'problem': proposal.problem,
      'affectedModule': proposal.affectedModule,
      'proposedSolution': proposal.proposedSolution,
      'expectedBenefit': proposal.expectedBenefit,
      'evidenceRefs': _normalized(proposal.evidenceRefs),
      'affectedUserCount': proposal.affectedUserCount,
      'affectedEventCount': proposal.affectedEventCount,
      'risk': proposal.risk,
      'developmentComplexity': proposal.developmentComplexity,
      'candidateFiles': _normalized(proposal.affectedFiles),
      'affectedModules': _normalized(proposal.affectedModules),
      'aiConfidence': proposal.aiConfidence,
      'targetAgentRoleId': 'code_agent',
      'codeWriteAuthorized': false,
      'paidProviderAuthorized': false,
      'deploymentAuthorized': false,
      'requiresSeparateCodeChangeApproval': true,
    });
  }

  String scopeFingerprintForHandoff(AgentFutureCodeHandoff handoff) {
    handoff.validate();

    return _fingerprint(<String, dynamic>{
      'proposalId': handoff.proposalId,
      'proposalApprovalId': handoff.proposalApprovalId,
      'proposalApprovedBy': handoff.proposalApprovedBy,
      'problem': handoff.problem,
      'affectedModule': handoff.affectedModule,
      'proposedSolution': handoff.proposedSolution,
      'expectedBenefit': handoff.expectedBenefit,
      'evidenceRefs': _normalized(handoff.evidenceRefs),
      'affectedUserCount': handoff.affectedUserCount,
      'affectedEventCount': handoff.affectedEventCount,
      'risk': handoff.risk,
      'developmentComplexity': handoff.developmentComplexity,
      'candidateFiles': _normalized(handoff.candidateFiles),
      'affectedModules': _normalized(handoff.affectedModules),
      'aiConfidence': handoff.aiConfidence,
      'targetAgentRoleId': handoff.targetAgentRoleId,
      'codeWriteAuthorized': handoff.codeWriteAuthorized,
      'paidProviderAuthorized': handoff.paidProviderAuthorized,
      'deploymentAuthorized': handoff.deploymentAuthorized,
      'requiresSeparateCodeChangeApproval':
          handoff.requiresSeparateCodeChangeApproval,
    });
  }

  Future<AgentFutureCodeHandoffRecord?> getState(String handoffId) async {
    final String normalized = handoffId.trim();

    if (normalized.isEmpty) {
      throw const AgentFutureCodeHandoffRepositoryException(
        'handoffId cannot be empty.',
      );
    }

    final DocumentSnapshot<Map<String, dynamic>> snapshot = await _handoffs
        .doc(normalized)
        .get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    return _recordFromSnapshot(snapshot);
  }

  Future<AgentFutureCodeHandoffRecord> ensurePrepared(
    AgentFutureCodeHandoff handoff,
  ) async {
    handoff.validate();

    if (handoff.status !=
        AgentFutureCodeHandoffStatus.readyForApprovalConsumption) {
      throw const AgentFutureCodeHandoffRepositoryException(
        'New handoff must start READY_FOR_APPROVAL_CONSUMPTION.',
      );
    }

    final String fingerprint = scopeFingerprintForHandoff(handoff);

    final DocumentReference<Map<String, dynamic>> ref = _handoffs.doc(
      handoff.handoffId,
    );

    return firestore.runTransaction<AgentFutureCodeHandoffRecord>((
      Transaction transaction,
    ) async {
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await transaction
          .get(ref);

      if (snapshot.exists && snapshot.data() != null) {
        final AgentFutureCodeHandoffRecord existing = _recordFromSnapshot(
          snapshot,
        );

        _assertSameLogicalHandoff(
          existing: existing,
          handoff: handoff,
          expectedFingerprint: fingerprint,
        );

        return existing;
      }

      final DateTime now = DateTime.now().toUtc();

      transaction.set(ref, <String, dynamic>{
        ...handoff.toMap(),
        'scopeFingerprint': fingerprint,
        'updatedAt': Timestamp.fromDate(now),
      });

      return AgentFutureCodeHandoffRecord(
        handoffId: handoff.handoffId,
        proposalId: handoff.proposalId,
        proposalApprovalId: handoff.proposalApprovalId,
        scopeFingerprint: fingerprint,
        status: handoff.status,
      );
    });
  }

  /// Finalizes only AFTER the central approval is already CONSUMED.
  ///
  /// This method is intentionally idempotent. If proposal + handoff are
  /// already HANDED_TO_CODE_AGENT with the same fingerprint, it returns
  /// without writing a duplicate audit event.
  Future<AgentFutureCodeHandoffRecord> completeAfterConsumedApproval({
    required String handoffId,
    required String expectedScopeFingerprint,
    required String actorId,
  }) async {
    final String normalizedHandoffId = handoffId.trim();
    final String normalizedFingerprint = expectedScopeFingerprint.trim();
    final String normalizedActorId = actorId.trim();

    if (normalizedHandoffId.isEmpty ||
        normalizedFingerprint.isEmpty ||
        normalizedActorId.isEmpty) {
      throw const AgentFutureCodeHandoffRepositoryException(
        'handoffId, scope fingerprint and actorId are required.',
      );
    }

    final DocumentReference<Map<String, dynamic>> handoffRef = _handoffs.doc(
      normalizedHandoffId,
    );

    return firestore.runTransaction<AgentFutureCodeHandoffRecord>((
      Transaction transaction,
    ) async {
      final DocumentSnapshot<Map<String, dynamic>> handoffSnapshot =
          await transaction.get(handoffRef);

      if (!handoffSnapshot.exists || handoffSnapshot.data() == null) {
        throw const AgentFutureCodeHandoffRepositoryException(
          'Prepared Future Code handoff does not exist.',
        );
      }

      final AgentFutureCodeHandoffRecord handoff = _recordFromSnapshot(
        handoffSnapshot,
      );

      if (handoff.scopeFingerprint != normalizedFingerprint) {
        throw const AgentFutureCodeHandoffRepositoryException(
          'Persisted Future Code handoff fingerprint mismatch.',
        );
      }

      final DocumentReference<Map<String, dynamic>> approvalRef = _approvals
          .doc(handoff.proposalApprovalId);

      final DocumentReference<Map<String, dynamic>> proposalRef = _proposals
          .doc(handoff.proposalId);

      final DocumentSnapshot<Map<String, dynamic>> approvalSnapshot =
          await transaction.get(approvalRef);

      final DocumentSnapshot<Map<String, dynamic>> proposalSnapshot =
          await transaction.get(proposalRef);

      if (!approvalSnapshot.exists || approvalSnapshot.data() == null) {
        throw const AgentFutureCodeHandoffRepositoryException(
          'Consumed central approval record is missing.',
        );
      }

      if (!proposalSnapshot.exists || proposalSnapshot.data() == null) {
        throw const AgentFutureCodeHandoffRepositoryException(
          'Future proposal record is missing.',
        );
      }

      final AgentApprovalRequest approval = AgentApprovalRequest.fromSnapshot(
        approvalSnapshot,
      );

      approval.validate();

      if (approval.status != AgentApprovalStatus.consumed) {
        throw AgentFutureCodeHandoffRepositoryException(
          'Central approval must be CONSUMED before final handoff. '
          'Current status: ${approval.status}.',
        );
      }

      if (approval.roleId != AgentFutureProposalApprovalContract.roleId ||
          approval.actionId != AgentFutureProposalApprovalContract.actionId ||
          approval.module != AgentFutureProposalApprovalContract.module ||
          approval.approvalId != handoff.proposalApprovalId) {
        throw const AgentFutureCodeHandoffRepositoryException(
          'Consumed approval identity does not match Future proposal contract.',
        );
      }

      final AgentFutureProposal proposal = AgentFutureProposal.fromMap(
        proposalSnapshot.data()!,
      );

      proposal.validate();

      if (proposal.proposalId != handoff.proposalId ||
          proposal.superAdminApprovalId != handoff.proposalApprovalId) {
        throw const AgentFutureCodeHandoffRepositoryException(
          'Persisted proposal identity does not match handoff.',
        );
      }

      final String proposalFingerprint = scopeFingerprintForProposal(proposal);

      if (proposalFingerprint != normalizedFingerprint) {
        throw const AgentFutureCodeHandoffRepositoryException(
          'Future proposal changed after approval/handoff preparation.',
        );
      }

      final Map<String, dynamic> expectedApprovalScope = _buildApprovalScope(
        proposal,
      );

      if (!_mapsEquivalent(approval.actionScope, expectedApprovalScope)) {
        throw const AgentFutureCodeHandoffRepositoryException(
          'Consumed central approval scope no longer matches proposal.',
        );
      }

      final bool handoffAlreadyComplete =
          handoff.status == AgentFutureCodeHandoffStatus.handedToCodeAgent;

      final bool proposalAlreadyComplete =
          proposal.status == AgentFutureProposalStatus.handedToCodeAgent;

      if (handoffAlreadyComplete && proposalAlreadyComplete) {
        return handoff;
      }

      if (handoff.status !=
              AgentFutureCodeHandoffStatus.readyForApprovalConsumption &&
          handoff.status != AgentFutureCodeHandoffStatus.approvalConsumed &&
          !handoffAlreadyComplete) {
        throw AgentFutureCodeHandoffRepositoryException(
          'Handoff status cannot be finalized: ${handoff.status}.',
        );
      }

      if (proposal.status != AgentFutureProposalStatus.approved &&
          !proposalAlreadyComplete) {
        throw AgentFutureCodeHandoffRepositoryException(
          'Proposal status cannot be handed to Code Agent: '
          '${proposal.status}.',
        );
      }

      final DateTime now = DateTime.now().toUtc();

      if (!handoffAlreadyComplete) {
        transaction.update(handoffRef, <String, dynamic>{
          'status': AgentFutureCodeHandoffStatus.handedToCodeAgent,
          'updatedAt': Timestamp.fromDate(now),
        });
      }

      if (!proposalAlreadyComplete) {
        final AgentFutureProposal handedProposal = proposal.copyWith(
          status: AgentFutureProposalStatus.handedToCodeAgent,
          updatedAt: now,
        );

        handedProposal.validate();
        transaction.set(proposalRef, handedProposal.toMap());
      }

      auditService.appendInTransaction(
        transaction: transaction,
        eventType: AgentAuditEventType.systemEvent,
        severity: AgentAuditSeverity.info,
        actorType: AgentAuditActorType.system,
        actorId: 'system',
        roleId: 'future_agent',
        module: 'app_future',
        actionId: 'future.code_handoff',
        result: AgentFutureProposalStatus.handedToCodeAgent,
        reason:
            'Consumed exact Future proposal approval finalized a '
            'non-executing Code Agent handoff package.',
        relatedApprovalId: handoff.proposalApprovalId,
        scope: <String, dynamic>{
          'proposalId': handoff.proposalId,
          'handoffId': handoff.handoffId,
          'scopeFingerprint': handoff.scopeFingerprint,
          'actorId': normalizedActorId,
        },
        metadata: const <String, dynamic>{
          'codeWriteAuthorized': false,
          'paidProviderAuthorized': false,
          'deploymentAuthorized': false,
          'taskQueued': false,
        },
      );

      return AgentFutureCodeHandoffRecord(
        handoffId: handoff.handoffId,
        proposalId: handoff.proposalId,
        proposalApprovalId: handoff.proposalApprovalId,
        scopeFingerprint: handoff.scopeFingerprint,
        status: AgentFutureCodeHandoffStatus.handedToCodeAgent,
      );
    });
  }

  AgentFutureCodeHandoffRecord _recordFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final Map<String, dynamic> data =
        snapshot.data() ?? const <String, dynamic>{};

    final AgentFutureCodeHandoffRecord record = AgentFutureCodeHandoffRecord(
      handoffId: (data['handoffId'] ?? snapshot.id).toString().trim(),
      proposalId: (data['proposalId'] ?? '').toString().trim(),
      proposalApprovalId: (data['proposalApprovalId'] ?? '').toString().trim(),
      scopeFingerprint: (data['scopeFingerprint'] ?? '').toString().trim(),
      status: (data['status'] ?? '').toString().trim(),
    );

    record.validate();

    if (record.handoffId != snapshot.id) {
      throw const AgentFutureCodeHandoffRepositoryException(
        'Stored handoffId does not match document ID.',
      );
    }

    return record;
  }

  void _assertSameLogicalHandoff({
    required AgentFutureCodeHandoffRecord existing,
    required AgentFutureCodeHandoff handoff,
    required String expectedFingerprint,
  }) {
    if (existing.handoffId != handoff.handoffId ||
        existing.proposalId != handoff.proposalId ||
        existing.proposalApprovalId != handoff.proposalApprovalId ||
        existing.scopeFingerprint != expectedFingerprint) {
      throw const AgentFutureCodeHandoffRepositoryException(
        'Existing handoff conflicts with this Future proposal scope.',
      );
    }
  }

  Map<String, dynamic> _buildApprovalScope(AgentFutureProposal proposal) {
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

  String _fingerprint(Map<String, dynamic> value) {
    final String canonical = jsonEncode(value);

    int hash = 2166136261;

    for (final int codeUnit in canonical.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 16777619) & 0x7fffffff;
    }

    return 'future_scope_$hash';
  }
}

class AgentFutureCodeHandoffRepositoryException implements Exception {
  const AgentFutureCodeHandoffRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'AgentFutureCodeHandoffRepositoryException: $message';
}
