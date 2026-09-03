import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/agent_audit_constants.dart';
import '../constants/agent_production_rollout_repository_constants.dart';
import '../constants/agent_production_rollout_runtime_guard_constants.dart';
import '../models/agent_production_rollout_runtime_guard.dart';
import 'agent_audit_service.dart';

class AgentProductionRolloutGuardRepository {
  factory AgentProductionRolloutGuardRepository({
    FirebaseFirestore? firestore,
    AgentAuditService? auditService,
    bool persistenceArmed = false,
  }) {
    return AgentProductionRolloutGuardRepository._(
      firestore,
      auditService,
      persistenceArmed,
    );
  }

  AgentProductionRolloutGuardRepository._(
    this._firestore,
    this._auditService,
    this._persistenceArmed,
  );

  final FirebaseFirestore? _firestore;
  final AgentAuditService? _auditService;
  final bool _persistenceArmed;

  Future<AgentProductionRolloutGuardPersistenceResult> persist({
    required AgentProductionRolloutGuardPersistenceRequest request,
  }) async {
    try {
      request.validate();
    } on FormatException {
      return const AgentProductionRolloutGuardPersistenceResult(
        status:
            AgentProductionRolloutGuardPersistenceStatus.blockedInvalidGuard,
        reasonCode: 'guard_persistence_request_validation_failed',
        revision: 0,
        persisted: false,
        idempotentReplay: false,
      );
    }

    if (!_persistenceArmed) {
      return AgentProductionRolloutGuardPersistenceResult(
        status: AgentProductionRolloutGuardPersistenceStatus.blockedNotArmed,
        reasonCode: 'production_guard_persistence_repository_is_not_armed',
        revision: request.guard.revision,
        persisted: false,
        idempotentReplay: false,
      );
    }

    final FirebaseFirestore firestore =
        _firestore ?? FirebaseFirestore.instance;

    final AgentAuditService auditService =
        _auditService ?? AgentAuditService(firestore: firestore);

    final DocumentReference<Map<String, dynamic>> guardRef = firestore
        .collection(AgentProductionRolloutRepositoryPath.settingsCollection)
        .doc(AgentProductionRolloutRepositoryPath.rolloutGuardDocument);

    return firestore.runTransaction<
      AgentProductionRolloutGuardPersistenceResult
    >((Transaction transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> existingSnapshot =
          await transaction.get(guardRef);

      if (existingSnapshot.exists) {
        final Map<String, dynamic> existing =
            existingSnapshot.data() ?? <String, dynamic>{};

        final int existingRevision =
            (existing['revision'] as num?)?.toInt() ?? 0;

        final String existingPlanSha = (existing['planFingerprintSha256'] ?? '')
            .toString()
            .trim()
            .toLowerCase();

        final String existingControlSha =
            (existing['controlStateFingerprintSha256'] ?? '')
                .toString()
                .trim()
                .toLowerCase();

        if (existingRevision == request.guard.revision &&
            existingPlanSha ==
                request.guard.planFingerprintSha256.toLowerCase() &&
            existingControlSha ==
                request.guard.controlStateFingerprintSha256.toLowerCase()) {
          return AgentProductionRolloutGuardPersistenceResult(
            status:
                AgentProductionRolloutGuardPersistenceStatus.alreadyPersisted,
            reasonCode: 'same_exact_guard_revision_already_persisted',
            revision: existingRevision,
            persisted: true,
            idempotentReplay: true,
          );
        }

        if (existingRevision != request.expectedPreviousRevision) {
          return AgentProductionRolloutGuardPersistenceResult(
            status: AgentProductionRolloutGuardPersistenceStatus
                .blockedRevisionConflict,
            reasonCode: 'guard_revision_changed_before_transaction_commit',
            revision: existingRevision,
            persisted: false,
            idempotentReplay: false,
          );
        }
      } else if (request.expectedPreviousRevision != 0) {
        return const AgentProductionRolloutGuardPersistenceResult(
          status: AgentProductionRolloutGuardPersistenceStatus
              .blockedRevisionConflict,
          reasonCode: 'expected_existing_guard_revision_but_guard_is_missing',
          revision: 0,
          persisted: false,
          idempotentReplay: false,
        );
      }

      final Map<String, dynamic> payload = request.guard.toMap();

      payload['updatedAt'] = FieldValue.serverTimestamp();

      if (!existingSnapshot.exists) {
        payload['createdAt'] = FieldValue.serverTimestamp();
      }

      transaction.set(guardRef, payload, SetOptions(merge: true));

      auditService.appendInTransaction(
        transaction: transaction,
        eventType: AgentAuditEventType.systemEvent,
        severity: AgentAuditSeverity.warning,
        actorType: AgentAuditActorType.admin,
        actorId: request.guard.actorReferenceSha256,
        module: 'ai_core',
        actionId: 'ai.production_rollout.guard.persist',
        result: 'PERSISTED',
        reason:
            'Phase 66 MONITOR_ONLY production runtime guard persisted atomically.',
        relatedApprovalId: request.guard.ownerApprovalId,
        scope: <String, dynamic>{
          'targetStage': AgentProductionRolloutRuntimeGuardStatus.monitorOnly,
          'revision': request.guard.revision,
          'autoTrafficPercent': 0,
          'businessWriteTrafficPercent': 0,
          'externalChannelsEnabled': false,
        },
        metadata: <String, dynamic>{
          'controlStateFingerprintSha256': request
              .guard
              .controlStateFingerprintSha256
              .toLowerCase(),
          'planFingerprintSha256': request.guard.planFingerprintSha256
              .toLowerCase(),
          'roleCount': request.guard.roleCount,
        },
      );

      return AgentProductionRolloutGuardPersistenceResult(
        status: AgentProductionRolloutGuardPersistenceStatus.persisted,
        reasonCode: 'runtime_guard_and_audit_committed_atomically',
        revision: request.guard.revision,
        persisted: true,
        idempotentReplay: false,
      );
    });
  }

  bool get persistenceArmed => _persistenceArmed;
  bool get defaultsNotArmed => true;
  bool get usesFirestoreTransaction => true;
  bool get usesSameTransactionAudit => true;
  bool get activatesProduction => false;
  bool get armsActivationRepository => false;
  bool get scriptInvokesGuardPersistence => false;
}
