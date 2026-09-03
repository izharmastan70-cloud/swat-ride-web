import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/agent_dispatcher_constants.dart';
import '../constants/agent_task_constants.dart';
import '../models/agent_task.dart';
import '../models/agent_task_assignment.dart';
import '../models/agent_worker.dart';
import 'agent_task_assignment_service.dart';
import 'agent_worker_selection_service.dart';

// =========================================================
// AI AGENT — MASTER DISPATCHER COORDINATOR
// =========================================================
//
// Flow:
// eligible queued/failed task
//   -> best worker selection
//   -> secure lease token
//   -> atomic Task + Worker assignment
//
// Assignment service performs the final transaction-level
// validation, so stale selection results cannot overwrite
// newer task or worker state.

class AgentMasterDispatcher {
  final FirebaseFirestore _firestore;
  final AgentWorkerSelectionService _selectionService;
  final AgentTaskAssignmentService _assignmentService;
  final Random _secureRandom;

  AgentMasterDispatcher({
    FirebaseFirestore? firestore,
    AgentWorkerSelectionService? selectionService,
    AgentTaskAssignmentService? assignmentService,
    Random? secureRandom,
  })  : _firestore =
            firestore ?? FirebaseFirestore.instance,
        _selectionService = selectionService ??
            AgentWorkerSelectionService(
              firestore: firestore,
            ),
        _assignmentService = assignmentService ??
            AgentTaskAssignmentService(
              firestore: firestore,
            ),
        _secureRandom = secureRandom ?? Random.secure();

  CollectionReference<Map<String, dynamic>> get _tasks =>
      _firestore.collection(AgentTaskCollection.tasks);

  Future<AgentTaskAssignment?> dispatchTask({
    required String taskId,
    Duration leaseDuration = const Duration(minutes: 2),
  }) async {
    final String normalizedTaskId = taskId.trim();

    if (normalizedTaskId.isEmpty) {
      throw const AgentMasterDispatcherException(
        code: 'invalid_task_id',
        message: 'taskId is required.',
      );
    }

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _tasks.doc(normalizedTaskId).get();

    if (!snapshot.exists) {
      throw const AgentMasterDispatcherException(
        code: 'task_not_found',
        message: 'Task does not exist.',
      );
    }

    final AgentTask task = AgentTask.fromMap(
      snapshot.data()!,
      documentId: snapshot.id,
    );

    if (task.status != AgentTaskStatus.queued &&
        task.status != AgentTaskStatus.failed) {
      throw AgentMasterDispatcherException(
        code: 'task_not_dispatchable',
        message:
            'Task status ${task.status} is not dispatchable.',
      );
    }

    final DateTime now = DateTime.now().toUtc();

    if (task.availableAt.toUtc().isAfter(now)) {
      return null;
    }

    final AgentWorker? worker =
        await _selectionService.selectBestWorker(
      task: task,
    );

    if (worker == null) return null;

    return _assignmentService.assign(
      taskId: task.taskId,
      workerId: worker.workerId,
      leaseToken: _createLeaseToken(),
      leaseDuration: leaseDuration,
    );
  }

  Future<AgentDispatchBatchResult> dispatchBatch({
    int limit = AgentDispatcherDefaults.dispatchBatchLimit,
    Duration leaseDuration = const Duration(minutes: 2),
  }) async {
    if (limit < 1 ||
        limit > AgentDispatcherDefaults.dispatchBatchLimit) {
      throw AgentMasterDispatcherException(
        code: 'invalid_batch_limit',
        message:
            'Batch limit must be between 1 and '
            '${AgentDispatcherDefaults.dispatchBatchLimit}.',
      );
    }

    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _tasks
            .where(
              'status',
              whereIn: const <String>[
                AgentTaskStatus.queued,
                AgentTaskStatus.failed,
              ],
            )
            .orderBy('priorityRank', descending: true)
            .orderBy('availableAt')
            .limit(limit)
            .get();

    final DateTime now = DateTime.now().toUtc();
    int assignedCount = 0;
    int unavailableCount = 0;
    int conflictCount = 0;

    final List<String> assignedTaskIds = <String>[];

    for (final QueryDocumentSnapshot<Map<String, dynamic>>
        document in snapshot.docs) {
      final AgentTask task = AgentTask.fromMap(
        document.data(),
        documentId: document.id,
      );

      if (task.availableAt.toUtc().isAfter(now)) {
        unavailableCount++;
        continue;
      }

      try {
        final AgentTaskAssignment? assignment =
            await dispatchTask(
          taskId: task.taskId,
          leaseDuration: leaseDuration,
        );

        if (assignment == null) {
          unavailableCount++;
          continue;
        }

        assignedCount++;
        assignedTaskIds.add(task.taskId);
      } on AgentTaskAssignmentServiceException {
        conflictCount++;
      }
    }

    return AgentDispatchBatchResult(
      scannedCount: snapshot.docs.length,
      assignedCount: assignedCount,
      unavailableCount: unavailableCount,
      conflictCount: conflictCount,
      assignedTaskIds:
          List<String>.unmodifiable(assignedTaskIds),
      completedAt: DateTime.now().toUtc(),
    );
  }

  String _createLeaseToken() {
    final List<int> bytes = List<int>.generate(
      32,
      (_) => _secureRandom.nextInt(256),
      growable: false,
    );

    return base64Url.encode(bytes).replaceAll('=', '');
  }
}

class AgentDispatchBatchResult {
  final int scannedCount;
  final int assignedCount;
  final int unavailableCount;
  final int conflictCount;
  final List<String> assignedTaskIds;
  final DateTime completedAt;

  const AgentDispatchBatchResult({
    required this.scannedCount,
    required this.assignedCount,
    required this.unavailableCount,
    required this.conflictCount,
    required this.assignedTaskIds,
    required this.completedAt,
  });
}

class AgentMasterDispatcherException implements Exception {
  final String code;
  final String message;

  const AgentMasterDispatcherException({
    required this.code,
    required this.message,
  });

  @override
  String toString() =>
      'AgentMasterDispatcherException($code): $message';
}