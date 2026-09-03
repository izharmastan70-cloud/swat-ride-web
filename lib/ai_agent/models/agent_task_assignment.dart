import 'agent_task.dart';
import 'agent_worker.dart';

// =========================================================
// AI AGENT — TASK ASSIGNMENT RESULT
// =========================================================
//
// Returned only after the task and worker were atomically
// validated and updated in one transaction.

class AgentTaskAssignment {
  final AgentTask task;
  final AgentWorker worker;
  final String leaseToken;
  final DateTime assignedAt;

  const AgentTaskAssignment({
    required this.task,
    required this.worker,
    required this.leaseToken,
    required this.assignedAt,
  });

  void validate() {
    task.validate();
    worker.validate();

    if (leaseToken.trim().isEmpty) {
      throw const AgentTaskAssignmentException(
        'leaseToken is required.',
      );
    }

    if (task.leaseOwnerId != worker.workerId) {
      throw const AgentTaskAssignmentException(
        'Task lease owner does not match assigned worker.',
      );
    }

    if (task.leaseToken != leaseToken) {
      throw const AgentTaskAssignmentException(
        'Task lease token does not match assignment token.',
      );
    }

    if (!worker.currentTaskIds.contains(task.taskId)) {
      throw const AgentTaskAssignmentException(
        'Worker does not contain the assigned task ID.',
      );
    }
  }
}

class AgentTaskAssignmentException implements Exception {
  final String message;

  const AgentTaskAssignmentException(this.message);

  @override
  String toString() =>
      'AgentTaskAssignmentException: $message';
}