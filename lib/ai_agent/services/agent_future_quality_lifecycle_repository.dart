import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/agent_audit_constants.dart';
import '../constants/agent_future_proposal_constants.dart';
import '../models/agent_code_test_result.dart';
import '../models/agent_future_proposal.dart';
import '../models/agent_future_quality_lifecycle.dart';
import '../models/agent_security_finding.dart';
import 'agent_audit_service.dart';

/// Firestore persistence boundary for Phase 41 quality lifecycle.
///
/// Every lifecycle transition atomically:
/// - verifies optimistic-lock updatedAt;
/// - validates legal status progression;
/// - writes the lifecycle record;
/// - mirrors the status to agent_future_proposals;
/// - appends an audit event in the SAME Firestore transaction.
///
/// This repository does not execute QA, Security scans, rollback, Code Agent,
/// provider calls, or deployment.
class AgentFutureQualityLifecycleRepository {
  AgentFutureQualityLifecycleRepository({FirebaseFirestore? firestore})
    : firestore = firestore ?? FirebaseFirestore.instance {
    auditService = AgentAuditService(firestore: this.firestore);
  }

  static const String collectionPath = 'agent_future_quality_lifecycles';
  static const String proposalCollectionPath = 'agent_future_proposals';

  final FirebaseFirestore firestore;
  late final AgentAuditService auditService;

  CollectionReference<Map<String, dynamic>> get _lifecycles =>
      firestore.collection(collectionPath);

  CollectionReference<Map<String, dynamic>> get _proposals =>
      firestore.collection(proposalCollectionPath);

  Future<AgentFutureQualityLifecycle?> getLifecycle(String proposalId) async {
    final String normalized = proposalId.trim();

    if (normalized.isEmpty) {
      throw const AgentFutureQualityLifecycleRepositoryException(
        'proposalId cannot be empty.',
      );
    }

    final DocumentSnapshot<Map<String, dynamic>> snapshot = await _lifecycles
        .doc(normalized)
        .get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    return _fromMap(snapshot.data()!);
  }

  Stream<AgentFutureQualityLifecycle?> watchLifecycle(String proposalId) {
    final String normalized = proposalId.trim();

    if (normalized.isEmpty) {
      throw const AgentFutureQualityLifecycleRepositoryException(
        'proposalId cannot be empty.',
      );
    }

    return _lifecycles.doc(normalized).snapshots().map((
      DocumentSnapshot<Map<String, dynamic>> snapshot,
    ) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return _fromMap(snapshot.data()!);
    });
  }

  Future<void> saveTransition({
    required AgentFutureQualityLifecycle lifecycle,
    required DateTime? expectedPreviousUpdatedAt,
    required String actorId,
  }) async {
    lifecycle.validate();

    final String normalizedActorId = actorId.trim();

    if (normalizedActorId.isEmpty) {
      throw const AgentFutureQualityLifecycleRepositoryException(
        'actorId cannot be empty.',
      );
    }

    final DocumentReference<Map<String, dynamic>> lifecycleRef = _lifecycles
        .doc(lifecycle.proposalId);

    final DocumentReference<Map<String, dynamic>> proposalRef = _proposals.doc(
      lifecycle.proposalId,
    );

    await firestore.runTransaction<void>((Transaction transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> lifecycleSnapshot =
          await transaction.get(lifecycleRef);

      final DocumentSnapshot<Map<String, dynamic>> proposalSnapshot =
          await transaction.get(proposalRef);

      if (!proposalSnapshot.exists || proposalSnapshot.data() == null) {
        throw const AgentFutureQualityLifecycleRepositoryException(
          'Future proposal does not exist.',
        );
      }

      final AgentFutureProposal proposal = AgentFutureProposal.fromMap(
        proposalSnapshot.data()!,
      );

      proposal.validate();

      AgentFutureQualityLifecycle? previous;

      if (lifecycleSnapshot.exists && lifecycleSnapshot.data() != null) {
        previous = _fromMap(lifecycleSnapshot.data()!);

        if (expectedPreviousUpdatedAt == null ||
            !previous.updatedAt.toUtc().isAtSameMomentAs(
              expectedPreviousUpdatedAt.toUtc(),
            )) {
          throw const AgentFutureQualityLifecycleRepositoryException(
            'Future quality lifecycle changed since it was opened. Reload before retry.',
          );
        }
      } else if (expectedPreviousUpdatedAt != null) {
        throw const AgentFutureQualityLifecycleRepositoryException(
          'Expected previous lifecycle does not exist.',
        );
      }

      _validateTransition(
        previous: previous,
        next: lifecycle,
        currentProposalStatus: proposal.status,
      );

      final DateTime now = DateTime.now().toUtc();

      if (lifecycle.updatedAt.toUtc().isAfter(
        now.add(const Duration(minutes: 5)),
      )) {
        throw const AgentFutureQualityLifecycleRepositoryException(
          'Lifecycle updatedAt is unreasonably in the future.',
        );
      }

      transaction.set(lifecycleRef, lifecycle.toMap());

      final AgentFutureProposal updatedProposal = proposal.copyWith(
        status: lifecycle.status,
        updatedAt: lifecycle.updatedAt,
      );

      updatedProposal.validate();

      transaction.set(proposalRef, updatedProposal.toMap());

      auditService.appendInTransaction(
        transaction: transaction,
        eventType: AgentAuditEventType.systemEvent,
        severity: _auditSeverity(lifecycle.status),
        actorType: AgentAuditActorType.system,
        actorId: 'system',
        roleId: 'future_agent',
        module: 'app_future',
        actionId: _auditAction(lifecycle.status),
        result: lifecycle.status,
        reason: _auditReason(lifecycle.status),
        scope: <String, dynamic>{
          'proposalId': lifecycle.proposalId,
          'actorId': normalizedActorId,
          'previousStatus': previous?.status ?? proposal.status,
          'nextStatus': lifecycle.status,
        },
        metadata: <String, dynamic>{
          'qaPassed': lifecycle.qaPassed,
          'securityPassed': lifecycle.securityPassed,
          'rollbackAvailable': lifecycle.rollbackAvailable,
          'ownerDecision': lifecycle.ownerDecision,
          'deploymentAuthorized': false,
          'automaticKeepAuthorized': false,
          'automaticRollbackAuthorized': false,
        },
      );
    });
  }

  void _validateTransition({
    required AgentFutureQualityLifecycle? previous,
    required AgentFutureQualityLifecycle next,
    required String currentProposalStatus,
  }) {
    if (previous == null) {
      if (next.status != AgentFutureProposalStatus.qaPending) {
        throw const AgentFutureQualityLifecycleRepositoryException(
          'First persisted quality state must be QA_PENDING.',
        );
      }

      if (currentProposalStatus !=
              AgentFutureProposalStatus.handedToCodeAgent &&
          currentProposalStatus !=
              AgentFutureProposalStatus.codeChangePrepared) {
        throw AgentFutureQualityLifecycleRepositoryException(
          'QA lifecycle cannot start from proposal status '
          '$currentProposalStatus.',
        );
      }

      return;
    }

    if (previous.proposalId != next.proposalId) {
      throw const AgentFutureQualityLifecycleRepositoryException(
        'Lifecycle proposal identity cannot change.',
      );
    }

    final Set<String> allowedNext = _allowedNextStatuses(previous.status);

    if (!allowedNext.contains(next.status)) {
      throw AgentFutureQualityLifecycleRepositoryException(
        'Illegal Future quality transition: '
        '${previous.status} -> ${next.status}.',
      );
    }

    if (currentProposalStatus != previous.status) {
      throw AgentFutureQualityLifecycleRepositoryException(
        'Proposal/lifecycle status drift detected. '
        'Proposal: $currentProposalStatus, lifecycle: '
        '${previous.status}.',
      );
    }

    if (next.updatedAt.toUtc().isBefore(previous.updatedAt.toUtc())) {
      throw const AgentFutureQualityLifecycleRepositoryException(
        'Lifecycle updatedAt cannot move backwards.',
      );
    }
  }

  Set<String> _allowedNextStatuses(String status) {
    switch (status) {
      case AgentFutureProposalStatus.qaPending:
        return const <String>{
          AgentFutureProposalStatus.qaPassed,
          AgentFutureProposalStatus.qaFailed,
        };

      case AgentFutureProposalStatus.qaPassed:
        return const <String>{AgentFutureProposalStatus.securityPending};

      case AgentFutureProposalStatus.securityPending:
        return const <String>{
          AgentFutureProposalStatus.securityPassed,
          AgentFutureProposalStatus.securityRejected,
        };

      case AgentFutureProposalStatus.securityPassed:
        return const <String>{AgentFutureProposalStatus.ownerDecisionPending};

      case AgentFutureProposalStatus.qaFailed:
      case AgentFutureProposalStatus.securityRejected:
        return const <String>{AgentFutureProposalStatus.rollbackRequested};

      case AgentFutureProposalStatus.ownerDecisionPending:
        return const <String>{
          AgentFutureProposalStatus.kept,
          AgentFutureProposalStatus.rollbackRequested,
        };

      case AgentFutureProposalStatus.rollbackRequested:
        return const <String>{AgentFutureProposalStatus.rolledBack};

      default:
        return const <String>{};
    }
  }

  String _auditAction(String status) {
    switch (status) {
      case AgentFutureProposalStatus.qaPending:
        return 'future.quality.qa_started';
      case AgentFutureProposalStatus.qaPassed:
        return 'future.quality.qa_passed';
      case AgentFutureProposalStatus.qaFailed:
        return 'future.quality.qa_failed';
      case AgentFutureProposalStatus.securityPending:
        return 'future.quality.security_started';
      case AgentFutureProposalStatus.securityPassed:
        return 'future.quality.security_passed';
      case AgentFutureProposalStatus.securityRejected:
        return 'future.quality.security_rejected';
      case AgentFutureProposalStatus.ownerDecisionPending:
        return 'future.quality.owner_decision_pending';
      case AgentFutureProposalStatus.kept:
        return 'future.quality.owner_keep';
      case AgentFutureProposalStatus.rollbackRequested:
        return 'future.quality.rollback_requested';
      case AgentFutureProposalStatus.rolledBack:
        return 'future.quality.rollback_completed';
      default:
        return 'future.quality.state_changed';
    }
  }

  String _auditReason(String status) {
    switch (status) {
      case AgentFutureProposalStatus.qaPending:
        return 'Future proposal implementation entered QA review.';
      case AgentFutureProposalStatus.qaPassed:
        return 'Strict QA evidence passed analyze, unit tests and build.';
      case AgentFutureProposalStatus.qaFailed:
        return 'Strict QA evidence did not fully pass.';
      case AgentFutureProposalStatus.securityPending:
        return 'QA-passed implementation entered Security review.';
      case AgentFutureProposalStatus.securityPassed:
        return 'Security review completed without HIGH/CRITICAL findings.';
      case AgentFutureProposalStatus.securityRejected:
        return 'Security review found HIGH/CRITICAL risk.';
      case AgentFutureProposalStatus.ownerDecisionPending:
        return 'QA and Security passed; explicit Owner KEEP/ROLLBACK decision required.';
      case AgentFutureProposalStatus.kept:
        return 'Owner explicitly confirmed KEEP.';
      case AgentFutureProposalStatus.rollbackRequested:
        return 'Owner explicitly requested ROLLBACK; restore has not yet been marked complete.';
      case AgentFutureProposalStatus.rolledBack:
        return 'Requested rollback was confirmed complete after backup restoration.';
      default:
        return 'Future quality lifecycle changed.';
    }
  }

  String _auditSeverity(String status) {
    if (status == AgentFutureProposalStatus.qaFailed ||
        status == AgentFutureProposalStatus.securityRejected) {
      return AgentAuditSeverity.warning;
    }

    return AgentAuditSeverity.info;
  }

  AgentFutureQualityLifecycle _fromMap(Map<String, dynamic> data) {
    final dynamic qaRaw = data['qaEvidence'];
    final dynamic securityRaw = data['securityEvidence'];

    AgentFutureQaEvidence? qaEvidence;

    if (qaRaw is Map) {
      final Map<String, dynamic> qa = qaRaw.map(
        (dynamic key, dynamic value) =>
            MapEntry<String, dynamic>(key.toString(), value),
      );

      qaEvidence = AgentFutureQaEvidence(
        codeChangeId: (qa['codeChangeId'] ?? '').toString(),
        backupId: (qa['backupId'] ?? '').toString(),
        reviewerId: (qa['reviewerId'] ?? '').toString(),
        testResult: AgentCodeTestResult(
          analyzeStatus: (qa['analyzeStatus'] ?? '').toString(),
          unitTestStatus: (qa['unitTestStatus'] ?? '').toString(),
          buildStatus: (qa['buildStatus'] ?? '').toString(),
          outputSummary: (qa['outputSummary'] ?? '').toString(),
          completedAt: _dateTimeValue(qa['testCompletedAt']),
        ),
        recordedAt: _dateTimeValue(qa['recordedAt']),
      );
    }

    AgentFutureSecurityEvidence? securityEvidence;

    if (securityRaw is Map) {
      final Map<String, dynamic> security = securityRaw.map(
        (dynamic key, dynamic value) =>
            MapEntry<String, dynamic>(key.toString(), value),
      );

      final List<AgentSecurityFinding> findings = <AgentSecurityFinding>[];

      final dynamic rawFindings = security['findings'];

      if (rawFindings is Iterable) {
        for (final dynamic rawFinding in rawFindings) {
          if (rawFinding is! Map) {
            continue;
          }

          final Map<String, dynamic> finding = rawFinding.map(
            (dynamic key, dynamic value) =>
                MapEntry<String, dynamic>(key.toString(), value),
          );

          findings.add(
            AgentSecurityFinding(
              findingType: (finding['findingType'] ?? '').toString(),
              severity: (finding['severity'] ?? '').toString(),
              roleId: (finding['roleId'] ?? '').toString(),
              module: (finding['module'] ?? '').toString(),
              actionId: (finding['actionId'] ?? '').toString(),
              reason: (finding['reason'] ?? '').toString(),
              metadata: _stringDynamicMap(finding['metadata']),
            ),
          );
        }
      }

      securityEvidence = AgentFutureSecurityEvidence(
        reviewerId: (security['reviewerId'] ?? '').toString(),
        reviewCompleted: security['reviewCompleted'] == true,
        findings: List<AgentSecurityFinding>.unmodifiable(findings),
        recordedAt: _dateTimeValue(security['recordedAt']),
      );
    }

    final AgentFutureQualityLifecycle lifecycle = AgentFutureQualityLifecycle(
      proposalId: (data['proposalId'] ?? '').toString(),
      status: (data['status'] ?? '').toString(),
      qaEvidence: qaEvidence,
      securityEvidence: securityEvidence,
      ownerDecision: (data['ownerDecision'] ?? '').toString(),
      ownerId: (data['ownerId'] ?? '').toString(),
      ownerDecisionNote: (data['ownerDecisionNote'] ?? '').toString(),
      updatedAt: _dateTimeValue(data['updatedAt']),
    );

    lifecycle.validate();
    return lifecycle;
  }

  Map<String, dynamic> _stringDynamicMap(dynamic raw) {
    if (raw is! Map) {
      return const <String, dynamic>{};
    }

    return raw.map(
      (dynamic key, dynamic value) =>
          MapEntry<String, dynamic>(key.toString(), value),
    );
  }

  DateTime _dateTimeValue(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toUtc();
    }

    if (value is DateTime) {
      return value.toUtc();
    }

    return DateTime.tryParse(value?.toString() ?? '')?.toUtc() ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
}

class AgentFutureQualityLifecycleRepositoryException implements Exception {
  const AgentFutureQualityLifecycleRepositoryException(this.message);

  final String message;

  @override
  String toString() =>
      'AgentFutureQualityLifecycleRepositoryException: $message';
}
