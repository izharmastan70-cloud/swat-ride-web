import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/agent_audit_constants.dart';
import '../models/agent_evaluation_run.dart';
import 'agent_audit_service.dart';

/// Create-only persistence for Phase 42 evaluation evidence.
///
/// Evaluation runs are immutable evidence. This repository cannot update or
/// delete runs, cannot train a model, cannot mutate prompts, cannot grant
/// permissions, cannot consume approvals, cannot call providers, and cannot
/// deploy anything.
class AgentEvaluationRunRepository {
  AgentEvaluationRunRepository({
    FirebaseFirestore? firestore,
    AgentAuditService? auditService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auditService =
           auditService ??
           AgentAuditService(
             firestore: firestore ?? FirebaseFirestore.instance,
           );

  static const String collectionName = 'agent_evaluation_runs';

  final FirebaseFirestore _firestore;
  final AgentAuditService _auditService;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  bool get createOnly => true;
  bool get updateAllowed => false;
  bool get deleteAllowed => false;
  bool get autonomousTrainingAllowed => false;
  bool get promptMutationAllowed => false;
  bool get providerExecutionAllowed => false;
  bool get approvalConsumptionAllowed => false;
  bool get runtimeBusinessWriteAllowed => false;
  bool get deploymentAllowed => false;

  Future<AgentEvaluationRun?> getById(String runId) async {
    final String normalizedRunId = runId.trim();

    if (normalizedRunId.isEmpty) {
      throw const AgentEvaluationRunRepositoryException(
        'runId cannot be empty.',
      );
    }

    final DocumentSnapshot<Map<String, dynamic>> snapshot = await _collection
        .doc(normalizedRunId)
        .get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    return AgentEvaluationRun.fromMap(snapshot.data()!);
  }

  Stream<List<AgentEvaluationRun>> watchRecent({int limit = 50}) {
    final int safeLimit = limit.clamp(1, 200).toInt();

    return _collection
        .orderBy('completedAt', descending: true)
        .limit(safeLimit)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
              .map(
                (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                    AgentEvaluationRun.fromMap(doc.data()),
              )
              .toList(growable: false),
        );
  }

  /// Persists exactly one immutable evaluation run and its audit log in the
  /// same Firestore transaction.
  ///
  /// Existing runId => fail closed. No overwrite/update path exists.
  Future<AgentEvaluationRun> createImmutableRun({
    required AgentEvaluationRun run,
    required String actorId,
  }) async {
    run.validate();

    final String normalizedRunId = run.runId.trim();
    final String normalizedActorId = actorId.trim();

    if (normalizedRunId.isEmpty) {
      throw const AgentEvaluationRunRepositoryException(
        'runId cannot be empty.',
      );
    }

    if (normalizedActorId.isEmpty) {
      throw const AgentEvaluationRunRepositoryException(
        'actorId cannot be empty.',
      );
    }

    if (!run.isReadOnlyEvidence ||
        run.mayTrainModel ||
        run.mayChangePrompt ||
        run.mayGrantPermission ||
        run.mayConsumeApproval ||
        run.mayWriteBusinessData ||
        run.mayCallProvider ||
        run.mayDeploy) {
      throw const AgentEvaluationRunRepositoryException(
        'Evaluation run contains forbidden runtime/training authority.',
      );
    }

    final DocumentReference<Map<String, dynamic>> runRef = _collection.doc(
      normalizedRunId,
    );

    return _firestore.runTransaction<AgentEvaluationRun>((
      Transaction transaction,
    ) async {
      final DocumentSnapshot<Map<String, dynamic>> existing = await transaction
          .get(runRef);

      if (existing.exists) {
        throw AgentEvaluationRunRepositoryException(
          'Evaluation run "$normalizedRunId" already exists and is immutable.',
        );
      }

      transaction.set(runRef, run.toMap());

      _auditService.appendInTransaction(
        transaction: transaction,
        eventType: AgentAuditEventType.systemEvent,
        severity: run.failClosed
            ? AgentAuditSeverity.warning
            : AgentAuditSeverity.info,
        actorType: AgentAuditActorType.system,
        actorId: normalizedActorId,
        roleId: 'evaluation_agent',
        module: 'agent_training_evaluation',
        actionId: 'evaluation.run.persist',
        result: run.failClosed
            ? 'FAIL_CLOSED'
            : run.eligibleForHumanReview
            ? 'HUMAN_REVIEW_ELIGIBLE'
            : 'NOT_ELIGIBLE',
        reason:
            'Immutable Phase 42 evaluation evidence persisted with '
            'atomic audit. No autonomous training or runtime mutation.',
        scope: <String, dynamic>{
          'runId': normalizedRunId,
          'catalogVersion': run.catalogVersion,
          'evaluatorVersion': run.evaluatorVersion,
          'policyVersion': run.policyVersion,
        },
        metadata: <String, dynamic>{
          'totalCount': run.totalCount,
          'passedCount': run.passedCount,
          'failedCount': run.failedCount,
          'blockedCount': run.blockedCount,
          'passPercent': run.passPercent,
          'weightedScorePercent': run.weightedScorePercent,
          'criticalFailureCount': run.criticalFailureCount,
          'highFailureCount': run.highFailureCount,
          'safetyViolationCount': run.safetyViolationCount,
          'thresholdPassed': run.thresholdPassed,
          'failClosed': run.failClosed,
          'eligibleForHumanReview': run.eligibleForHumanReview,
          'isReadOnlyEvidence': true,
          'autonomousTrainingAllowed': false,
          'promptMutationAllowed': false,
          'providerExecutionAllowed': false,
          'deploymentAllowed': false,
        },
      );

      return run;
    });
  }
}

class AgentEvaluationRunRepositoryException implements Exception {
  const AgentEvaluationRunRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'AgentEvaluationRunRepositoryException: $message';
}
