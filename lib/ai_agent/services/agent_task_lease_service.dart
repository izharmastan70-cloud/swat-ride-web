import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/agent_audit_constants.dart';
import '../constants/agent_task_constants.dart';
import '../models/agent_task.dart';
import 'agent_audit_service.dart';
import 'agent_task_queue.dart';

// =========================================================
// AI AGENT â€” ATOMIC TASK LEASE SERVICE
// =========================================================
//
// Firestore transaction guarantees that only one worker can
// acquire the same task lease at a time.
//
// This client-side foundation must move behind a trusted
// backend before production worker activation.

class AgentTaskLeaseService {
  final FirebaseFirestore _firestore;
  late final AgentAuditService _auditService;

  AgentTaskLeaseService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance {
    _auditService = AgentAuditService(firestore: _firestore);
  }

  CollectionReference<Map<String, dynamic>> get _tasks =>
      _firestore.collection(AgentTaskCollection.tasks);

  Future<AgentTask?> acquireLease({
    required String taskId,
    required String workerId,
    required String leaseToken,
    Duration leaseDuration = const Duration(minutes: 2),
  }) async {
    final String normalizedTaskId = taskId.trim();
    final String normalizedWorkerId = workerId.trim();
    final String normalizedLeaseToken = leaseToken.trim();

    if (normalizedTaskId.isEmpty) {
      throw const AgentTaskQueueException(
        code: 'invalid_task_id',
        message: 'taskId is required.',
      );
    }

    if (normalizedWorkerId.isEmpty) {
      throw const AgentTaskQueueException(
        code: 'invalid_worker_id',
        message: 'workerId is required.',
      );
    }

    if (normalizedLeaseToken.isEmpty) {
      throw const AgentTaskQueueException(
        code: 'invalid_lease_token',
        message: 'leaseToken is required.',
      );
    }

    if (leaseDuration < const Duration(seconds: 30) ||
        leaseDuration > const Duration(minutes: 10)) {
      throw const AgentTaskQueueException(
        code: 'invalid_lease_duration',
        message: 'Lease duration must be between 30 seconds and 10 minutes.',
      );
    }

    final DocumentReference<Map<String, dynamic>> document = _tasks.doc(
      normalizedTaskId,
    );

    return _firestore.runTransaction<AgentTask?>((
      Transaction transaction,
    ) async {
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await transaction
          .get(document);

      if (!snapshot.exists) return null;

      final AgentTask task = AgentTask.fromMap(
        snapshot.data()!,
        documentId: snapshot.id,
      );

      final DateTime now = DateTime.now().toUtc();

      if (task.isTerminal) return null;

      if (task.availableAt.toUtc().isAfter(now)) {
        return null;
      }

      final DateTime? currentLeaseExpiry = task.leaseExpiresAt?.toUtc();

      final bool leaseIsActive =
          task.leaseOwnerId != null &&
          task.leaseToken != null &&
          currentLeaseExpiry != null &&
          currentLeaseExpiry.isAfter(now);

      if (leaseIsActive) return null;

      final bool statusCanBeLeased =
          task.status == AgentTaskStatus.queued ||
          task.status == AgentTaskStatus.failed ||
          task.status == AgentTaskStatus.leased ||
          task.status == AgentTaskStatus.processing;

      if (!statusCanBeLeased) return null;

      if (task.attemptCount >= task.maxAttempts) {
        transaction.update(document, <String, dynamic>{
          'status': AgentTaskStatus.deadLetter,
          'leaseOwnerId': null,
          'leaseToken': null,
          'leaseExpiresAt': null,
          'completedAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
          'lastErrorCode': AgentTaskFailureCode.retryLimitReached,
          'lastErrorMessage':
              'Task reached its retry limit before lease acquisition.',
        });

        _auditService.appendInTransaction(
          transaction: transaction,
          eventType: AgentAuditEventType.taskDeadLettered,
          severity: AgentAuditSeverity.warning,
          actorType: AgentAuditActorType.agent,
          actorId: normalizedWorkerId,
          module: 'core',
          actionId: 'task.lease.retry_limit',
          result: AgentTaskStatus.deadLetter,
          reason: 'Task reached retry limit before lease acquisition.',
          scope: <String, dynamic>{
            'taskId': normalizedTaskId,
            'workerId': normalizedWorkerId,
          },
          metadata: <String, dynamic>{
            'attemptCount': task.attemptCount,
            'maxAttempts': task.maxAttempts,
          },
        );

        return null;
      }

      final DateTime leaseExpiresAt = now.add(leaseDuration);

      final AgentTask leasedTask = task.copyWith(
        status: AgentTaskStatus.leased,
        attemptCount: task.attemptCount + 1,
        leaseOwnerId: normalizedWorkerId,
        leaseToken: normalizedLeaseToken,
        leaseExpiresAt: leaseExpiresAt,
        startedAt: task.startedAt ?? now,
        updatedAt: now,
        clearError: true,
      );

      leasedTask.validate();

      transaction.update(document, <String, dynamic>{
        'status': leasedTask.status,
        'attemptCount': leasedTask.attemptCount,
        'leaseOwnerId': leasedTask.leaseOwnerId,
        'leaseToken': leasedTask.leaseToken,
        'leaseExpiresAt': Timestamp.fromDate(leaseExpiresAt),
        'startedAt': Timestamp.fromDate(leasedTask.startedAt!),
        'updatedAt': Timestamp.fromDate(now),
        'lastErrorCode': null,
        'lastErrorMessage': null,
      });

      _auditService.appendInTransaction(
        transaction: transaction,
        eventType: AgentAuditEventType.taskLeaseAcquired,
        severity: AgentAuditSeverity.info,
        actorType: AgentAuditActorType.agent,
        actorId: normalizedWorkerId,
        module: 'core',
        actionId: 'task.lease.acquire',
        result: AgentTaskStatus.leased,
        reason: 'Task lease acquired.',
        scope: <String, dynamic>{
          'taskId': normalizedTaskId,
          'workerId': normalizedWorkerId,
        },
        metadata: <String, dynamic>{'attemptCount': leasedTask.attemptCount},
      );

      return leasedTask;
    });
  }
}
