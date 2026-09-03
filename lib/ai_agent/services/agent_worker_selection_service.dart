import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/agent_dispatcher_constants.dart';
import '../models/agent_task.dart';
import '../models/agent_worker.dart';

// =========================================================
// AI AGENT — WORKER SELECTION ENGINE
// =========================================================
//
// Selection rules:
// 1. Worker must be enabled.
// 2. Worker status must accept tasks.
// 3. Heartbeat must be fresh.
// 4. Worker must support the task role and module.
// 5. Worker must have remaining capacity.
// 6. Least-loaded eligible worker wins.
// 7. Tie: most recent heartbeat, then stable worker ID.

class AgentWorkerSelectionService {
  final FirebaseFirestore _firestore;

  AgentWorkerSelectionService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _workers =>
      _firestore.collection(AgentWorkerCollection.workers);

  Future<AgentWorker?> selectBestWorker({
    required AgentTask task,
    int candidateLimit = 100,
  }) async {
    task.validate();

    if (task.isTerminal) {
      throw const AgentWorkerSelectionException(
        code: 'terminal_task',
        message:
            'A terminal task cannot be assigned to a worker.',
      );
    }

    if (candidateLimit < 1 || candidateLimit > 200) {
      throw const AgentWorkerSelectionException(
        code: 'invalid_candidate_limit',
        message:
            'candidateLimit must be between 1 and 200.',
      );
    }

    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _workers
            .where('enabled', isEqualTo: true)
            .orderBy('name')
            .limit(candidateLimit)
            .get();

    final DateTime now = DateTime.now().toUtc();

    final List<AgentWorker> eligibleWorkers =
        <AgentWorker>[];

    for (final QueryDocumentSnapshot<Map<String, dynamic>>
        document in snapshot.docs) {
      final AgentWorker worker = AgentWorker.fromMap(
        document.data(),
        documentId: document.id,
      );

      if (worker.canAcceptTask(
        roleId: task.targetAgentRoleId,
        module: task.module,
        now: now,
      )) {
        eligibleWorkers.add(worker);
      }
    }

    if (eligibleWorkers.isEmpty) return null;

    eligibleWorkers.sort(_compareWorkers);

    return eligibleWorkers.first;
  }

  Future<List<AgentWorker>> findEligibleWorkers({
    required AgentTask task,
    int limit = 100,
  }) async {
    task.validate();

    if (limit < 1 || limit > 200) {
      throw const AgentWorkerSelectionException(
        code: 'invalid_limit',
        message: 'Worker limit must be between 1 and 200.',
      );
    }

    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _workers
            .where('enabled', isEqualTo: true)
            .orderBy('name')
            .limit(limit)
            .get();

    final DateTime now = DateTime.now().toUtc();

    final List<AgentWorker> workers = snapshot.docs
        .map(
          (QueryDocumentSnapshot<Map<String, dynamic>>
              document) =>
              AgentWorker.fromMap(
            document.data(),
            documentId: document.id,
          ),
        )
        .where(
          (AgentWorker worker) => worker.canAcceptTask(
            roleId: task.targetAgentRoleId,
            module: task.module,
            now: now,
          ),
        )
        .toList();

    workers.sort(_compareWorkers);
    return List<AgentWorker>.unmodifiable(workers);
  }

  static int _compareWorkers(
    AgentWorker first,
    AgentWorker second,
  ) {
    final int loadComparison = first.currentTaskIds.length
        .compareTo(second.currentTaskIds.length);

    if (loadComparison != 0) return loadComparison;

    final int heartbeatComparison = second.lastHeartbeatAt
        .compareTo(first.lastHeartbeatAt);

    if (heartbeatComparison != 0) {
      return heartbeatComparison;
    }

    return first.workerId.compareTo(second.workerId);
  }
}

class AgentWorkerSelectionException implements Exception {
  final String code;
  final String message;

  const AgentWorkerSelectionException({
    required this.code,
    required this.message,
  });

  @override
  String toString() =>
      'AgentWorkerSelectionException($code): $message';
}