import '../models/agent_task.dart';

// =========================================================
// AI AGENT — TASK QUEUE CONTRACT
// =========================================================
//
// Implementations must provide:
// - idempotent enqueue
// - atomic worker lease
// - lease-token validation
// - controlled retry
// - terminal task protection

abstract class AgentTaskQueue {
  String get queueId;

  Future<AgentTask> enqueue(AgentTask task);

  Future<AgentTask?> getTask(String taskId);

  Stream<AgentTask?> watchTask(String taskId);

  Stream<List<AgentTask>> watchQueuedTasks({
    int limit = 50,
  });

  Future<AgentTask?> acquireLease({
    required String taskId,
    required String workerId,
    required String leaseToken,
    Duration leaseDuration = const Duration(minutes: 2),
  });

  Future<AgentTask> markProcessing({
    required String taskId,
    required String workerId,
    required String leaseToken,
  });

  Future<AgentTask> complete({
    required String taskId,
    required String workerId,
    required String leaseToken,
    required String resultSummary,
  });

  Future<AgentTask> fail({
    required String taskId,
    required String workerId,
    required String leaseToken,
    required String errorCode,
    required String errorMessage,
    Duration retryDelay = const Duration(seconds: 30),
  });

  Future<AgentTask> cancel({
    required String taskId,
    required String cancelledBy,
    required String reason,
  });

  Future<int> recoverExpiredLeases({
    int limit = 50,
  });
}

class AgentTaskQueueException implements Exception {
  final String code;
  final String message;

  const AgentTaskQueueException({
    required this.code,
    required this.message,
  });

  @override
  String toString() =>
      'AgentTaskQueueException($code): $message';
}