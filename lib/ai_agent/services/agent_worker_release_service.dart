import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/agent_dispatcher_constants.dart';
import '../constants/agent_task_constants.dart';
import '../models/agent_task.dart';
import '../models/agent_worker.dart';

// =========================================================
// AI AGENT — WORKER TASK RELEASE SERVICE
// =========================================================
//
// Removes a finished/non-running task from worker workload.
//
// Release is allowed for:
// - completed
// - failed/retry waiting
// - cancelled
// - dead-letter
// - awaiting approval/review
//
// Leased or processing tasks cannot be released through this
// service because their worker still owns active execution.

class AgentWorkerReleaseService {
  final FirebaseFirestore _firestore;

  AgentWorkerReleaseService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _tasks =>
      _firestore.collection(AgentTaskCollection.tasks);

  CollectionReference<Map<String, dynamic>> get _workers =>
      _firestore.collection(AgentWorkerCollection.workers);

  Future<AgentWorker> releaseTask({
    required String taskId,
    required String workerId,
  }) async {
    final String normalizedTaskId = taskId.trim();
    final String normalizedWorkerId = workerId.trim();

    if (normalizedTaskId.isEmpty) {
      throw const AgentWorkerReleaseException(
        code: 'invalid_task_id',
        message: 'taskId is required.',
      );
    }

    if (normalizedWorkerId.isEmpty) {
      throw const AgentWorkerReleaseException(
        code: 'invalid_worker_id',
        message: 'workerId is required.',
      );
    }

    final DocumentReference<Map<String, dynamic>> taskDocument =
        _tasks.doc(normalizedTaskId);

    final DocumentReference<Map<String, dynamic>>
        workerDocument =
        _workers.doc(normalizedWorkerId);

    return _firestore.runTransaction<AgentWorker>(
      (Transaction transaction) async {
        final DocumentSnapshot<Map<String, dynamic>>
            taskSnapshot =
            await transaction.get(taskDocument);

        final DocumentSnapshot<Map<String, dynamic>>
            workerSnapshot =
            await transaction.get(workerDocument);

        if (!taskSnapshot.exists) {
          throw const AgentWorkerReleaseException(
            code: 'task_not_found',
            message: 'Task does not exist.',
          );
        }

        if (!workerSnapshot.exists) {
          throw const AgentWorkerReleaseException(
            code: 'worker_not_found',
            message: 'Worker does not exist.',
          );
        }

        final AgentTask task = AgentTask.fromMap(
          taskSnapshot.data()!,
          documentId: taskSnapshot.id,
        );

        final AgentWorker worker = AgentWorker.fromMap(
          workerSnapshot.data()!,
          documentId: workerSnapshot.id,
        );

        final bool releasableStatus =
            task.status == AgentTaskStatus.completed ||
            task.status == AgentTaskStatus.failed ||
            task.status == AgentTaskStatus.cancelled ||
            task.status == AgentTaskStatus.deadLetter ||
            task.status == AgentTaskStatus.awaitingApproval ||
            task.status == AgentTaskStatus.awaitingReview;

        if (!releasableStatus) {
          throw AgentWorkerReleaseException(
            code: 'task_still_active',
            message:
                'Task status ${task.status} cannot release worker capacity.',
          );
        }

        if (!worker.currentTaskIds.contains(task.taskId)) {
          return worker;
        }

        final List<String> updatedTaskIds =
            worker.currentTaskIds
                .where(
                  (String currentTaskId) =>
                      currentTaskId != task.taskId,
                )
                .toList(growable: false);

        final DateTime now = DateTime.now().toUtc();

        final String updatedStatus = !worker.enabled
            ? AgentWorkerStatus.offline
            : AgentWorkerStatus.available;

        final AgentWorker updatedWorker = worker.copyWith(
          currentTaskIds:
              List<String>.unmodifiable(updatedTaskIds),
          status: updatedStatus,
          updatedAt: now,
        );

        updatedWorker.validate();

        transaction.update(
          workerDocument,
          <String, dynamic>{
            'currentTaskIds': updatedTaskIds,
            'activeTaskCount': updatedTaskIds.length,
            'status': updatedStatus,
            'updatedAt': Timestamp.fromDate(now),
          },
        );

        transaction.update(
          taskDocument,
          <String, dynamic>{
            'workerReleasedAt': Timestamp.fromDate(now),
            'updatedAt': Timestamp.fromDate(now),
          },
        );

        return updatedWorker;
      },
    );
  }
}

class AgentWorkerReleaseException implements Exception {
  final String code;
  final String message;

  const AgentWorkerReleaseException({
    required this.code,
    required this.message,
  });

  @override
  String toString() =>
      'AgentWorkerReleaseException($code): $message';
}