import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/agent_task.dart';
import 'agent_task_execution_service.dart';
import 'agent_task_lease_service.dart';
import 'agent_task_queue.dart';
import 'agent_task_recovery_service.dart';
import 'agent_task_repository.dart';

// =========================================================
// AI AGENT — FIRESTORE TASK QUEUE
// =========================================================
//
// Single public Phase 21 implementation combining:
// - idempotent storage
// - atomic leases
// - execution lifecycle
// - controlled retry
// - cancellation
// - expired lease recovery

class AgentFirestoreTaskQueue implements AgentTaskQueue {
  final AgentTaskRepository _repository;
  final AgentTaskLeaseService _leaseService;
  final AgentTaskExecutionService _executionService;
  final AgentTaskRecoveryService _recoveryService;

  AgentFirestoreTaskQueue({
    FirebaseFirestore? firestore,
  })  : _repository = AgentTaskRepository(
          firestore: firestore,
        ),
        _leaseService = AgentTaskLeaseService(
          firestore: firestore,
        ),
        _executionService = AgentTaskExecutionService(
          firestore: firestore,
        ),
        _recoveryService = AgentTaskRecoveryService(
          firestore: firestore,
        );

  @override
  String get queueId => 'firestore_agent_task_queue';

  @override
  Future<AgentTask> enqueue(AgentTask task) {
    return _repository.enqueue(task);
  }

  @override
  Future<AgentTask?> getTask(String taskId) {
    return _repository.getTask(taskId);
  }

  @override
  Stream<AgentTask?> watchTask(String taskId) {
    return _repository.watchTask(taskId);
  }

  @override
  Stream<List<AgentTask>> watchQueuedTasks({
    int limit = 50,
  }) {
    return _repository.watchQueuedTasks(limit: limit);
  }

  @override
  Future<AgentTask?> acquireLease({
    required String taskId,
    required String workerId,
    required String leaseToken,
    Duration leaseDuration = const Duration(minutes: 2),
  }) {
    return _leaseService.acquireLease(
      taskId: taskId,
      workerId: workerId,
      leaseToken: leaseToken,
      leaseDuration: leaseDuration,
    );
  }

  @override
  Future<AgentTask> markProcessing({
    required String taskId,
    required String workerId,
    required String leaseToken,
  }) {
    return _executionService.markProcessing(
      taskId: taskId,
      workerId: workerId,
      leaseToken: leaseToken,
    );
  }

  @override
  Future<AgentTask> complete({
    required String taskId,
    required String workerId,
    required String leaseToken,
    required String resultSummary,
  }) {
    return _executionService.complete(
      taskId: taskId,
      workerId: workerId,
      leaseToken: leaseToken,
      resultSummary: resultSummary,
    );
  }

  @override
  Future<AgentTask> fail({
    required String taskId,
    required String workerId,
    required String leaseToken,
    required String errorCode,
    required String errorMessage,
    Duration retryDelay = const Duration(seconds: 30),
  }) {
    return _executionService.fail(
      taskId: taskId,
      workerId: workerId,
      leaseToken: leaseToken,
      errorCode: errorCode,
      errorMessage: errorMessage,
      retryDelay: retryDelay,
    );
  }

  @override
  Future<AgentTask> cancel({
    required String taskId,
    required String cancelledBy,
    required String reason,
  }) {
    return _executionService.cancel(
      taskId: taskId,
      cancelledBy: cancelledBy,
      reason: reason,
    );
  }

  @override
  Future<int> recoverExpiredLeases({
    int limit = 50,
  }) {
    return _recoveryService.recoverExpiredLeases(
      limit: limit,
    );
  }
}