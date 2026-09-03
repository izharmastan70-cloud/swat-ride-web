import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/agent_audit_constants.dart';
import '../constants/agent_owner_attention_constants.dart';
import '../constants/agent_owner_attention_review_constants.dart';
import '../models/agent_owner_attention_event.dart';
import '../models/agent_owner_attention_inbox_record.dart';
import '../models/agent_owner_attention_status_transition.dart';
import 'agent_audit_service.dart';
import 'agent_owner_attention_contract_service.dart';
import 'agent_owner_attention_status_transition_policy.dart';

class AgentOwnerAttentionRepository {
  AgentOwnerAttentionRepository({
    FirebaseFirestore? firestore,
    AgentAuditService? auditService,
    AgentOwnerAttentionContractService? contractService,
    AgentOwnerAttentionStatusTransitionPolicy? transitionPolicy,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auditService =
           auditService ??
           AgentAuditService(
             firestore: firestore ?? FirebaseFirestore.instance,
           ),
       _contractService =
           contractService ?? const AgentOwnerAttentionContractService(),
       _transitionPolicy =
           transitionPolicy ??
           const AgentOwnerAttentionStatusTransitionPolicy();

  static const String collectionName = 'agent_owner_attention_inbox';

  static const String dedupeCollectionName = 'agent_owner_attention_dedupe';

  final FirebaseFirestore _firestore;
  final AgentAuditService _auditService;
  final AgentOwnerAttentionContractService _contractService;
  final AgentOwnerAttentionStatusTransitionPolicy _transitionPolicy;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  CollectionReference<Map<String, dynamic>> get _dedupeCollection =>
      _firestore.collection(dedupeCollectionName);

  bool get immutableIngestion => true;
  bool get duplicateSourceOverwriteAllowed => false;
  bool get sourcePayloadUpdateAllowed => false;
  bool get deleteAllowed => false;
  bool get sourceRecordMutationAllowed => false;
  bool get approvalConsumptionAllowed => false;
  bool get permissionGrantAllowed => false;
  bool get runtimeGateOverrideAllowed => false;
  bool get providerExecutionAllowed => false;
  bool get businessExecutionAllowed => false;

  Future<AgentOwnerAttentionInboxRecord?> getById(String attentionId) async {
    final id = attentionId.trim();

    if (id.isEmpty) {
      throw const AgentOwnerAttentionRepositoryException(
        'attentionId cannot be empty.',
      );
    }

    final snapshot = await _collection.doc(id).get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    return AgentOwnerAttentionInboxRecord.fromMap(snapshot.data()!);
  }

  Stream<List<AgentOwnerAttentionInboxRecord>> watchRecent({int limit = 50}) {
    final safeLimit = limit
        .clamp(1, AgentOwnerAttentionRepositoryLimits.recentLimitMax)
        .toInt();

    return _collection
        .orderBy('createdAtUtc', descending: true)
        .limit(safeLimit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AgentOwnerAttentionInboxRecord.fromMap(doc.data()))
              .toList(growable: false),
        );
  }

  Future<AgentOwnerAttentionInboxRecord> createImmutableIngestion({
    required AgentOwnerAttentionEvent event,
    required String actorRef,
    required DateTime evaluatedAtUtc,
  }) async {
    event.validate();

    final actor = actorRef.trim();

    if (actor.isEmpty ||
        !_contractService.validateForCentralInbox(
          event,
          evaluatedAtUtc: evaluatedAtUtc,
        )) {
      throw const AgentOwnerAttentionRepositoryException(
        'Owner Attention event/actor is not valid for ingestion.',
      );
    }

    final record = AgentOwnerAttentionInboxRecord.initial(event);

    final inboxRef = _collection.doc(event.attentionId);
    final dedupeId = '${event.source.sourceType}_${event.source.sourceEventId}';
    final dedupeRef = _dedupeCollection.doc(dedupeId);

    return _firestore.runTransaction<AgentOwnerAttentionInboxRecord>((
      transaction,
    ) async {
      final existingInbox = await transaction.get(inboxRef);
      final existingDedupe = await transaction.get(dedupeRef);

      if (existingInbox.exists) {
        throw AgentOwnerAttentionRepositoryException(
          'Attention "${event.attentionId}" already exists.',
        );
      }

      if (existingDedupe.exists) {
        throw const AgentOwnerAttentionRepositoryException(
          'Duplicate Owner Attention source identity.',
        );
      }

      transaction.set(inboxRef, record.toMap());

      transaction.set(dedupeRef, <String, dynamic>{
        'dedupeId': dedupeId,
        'attentionId': event.attentionId,
        'sourceType': event.source.sourceType,
        'sourceEventId': event.source.sourceEventId,
        'sourceReferenceSha256': event.source.sourceReferenceSha256,
        'sourceDedupeKey': event.source.dedupeKey,
        'createdAtUtc': event.createdAtUtc.toIso8601String(),
        'immutable': true,
      });

      _auditService.appendInTransaction(
        transaction: transaction,
        eventType: AgentAuditEventType.systemEvent,
        severity:
            event.priority == AgentOwnerAttentionPriority.emergency ||
                event.priority == AgentOwnerAttentionPriority.critical
            ? AgentAuditSeverity.warning
            : AgentAuditSeverity.info,
        actorType: AgentAuditActorType.system,
        actorId: actor,
        roleId: 'owner_attention_inbox',
        module: 'owner_attention_inbox',
        actionId: 'owner_attention.ingest',
        result: 'PENDING_REVIEW',
        reason:
            'Safe unified Owner Attention event persisted with atomic dedupe and audit.',
        scope: <String, dynamic>{
          'attentionId': event.attentionId,
          'category': event.category,
          'priority': event.priority,
          'sourceType': event.source.sourceType,
          'sourceReferenceSha256': event.source.sourceReferenceSha256,
        },
      );

      return record;
    });
  }

  Future<AgentOwnerAttentionInboxRecord> transitionStatus({
    required AgentOwnerAttentionStatusTransition transition,
  }) async {
    transition.validate();

    if (!_transitionPolicy.isAllowed(transition)) {
      throw const AgentOwnerAttentionRepositoryException(
        'Owner Attention status transition is not allowed.',
      );
    }

    final inboxRef = _collection.doc(transition.attentionId);

    return _firestore.runTransaction<AgentOwnerAttentionInboxRecord>((
      transaction,
    ) async {
      final snapshot = await transaction.get(inboxRef);

      if (!snapshot.exists || snapshot.data() == null) {
        throw const AgentOwnerAttentionRepositoryException(
          'Owner Attention item was not found.',
        );
      }

      final current = AgentOwnerAttentionInboxRecord.fromMap(snapshot.data()!);

      if (current.event.status != transition.expectedStatus ||
          current.reviewVersion != transition.expectedReviewVersion) {
        throw const AgentOwnerAttentionRepositoryException(
          'Owner Attention item changed since it was opened. Reload before retry.',
        );
      }

      final nextEvent = AgentOwnerAttentionEvent(
        attentionId: current.event.attentionId,
        category: current.event.category,
        priority: current.event.priority,
        status: transition.nextStatus,
        source: current.event.source,
        payload: current.event.payload,
        createdAtUtc: current.event.createdAtUtc,
      );

      final next = AgentOwnerAttentionInboxRecord(
        event: nextEvent,
        reviewVersion: current.reviewVersion + 1,
        reviewedByRole: transition.reviewerRole,
        reviewerRef: transition.reviewerRef.trim(),
        reviewUpdatedAtUtc: transition.reviewedAtUtc,
      );

      transaction.update(inboxRef, <String, dynamic>{
        'status': transition.nextStatus,
        'reviewVersion': next.reviewVersion,
        'reviewedByRole': transition.reviewerRole,
        'reviewerRef': transition.reviewerRef.trim(),
        'reviewUpdatedAtUtc': transition.reviewedAtUtc.toIso8601String(),
      });

      _auditService.appendInTransaction(
        transaction: transaction,
        eventType: AgentAuditEventType.systemEvent,
        severity: AgentAuditSeverity.info,
        actorType: AgentAuditActorType.admin,
        actorId: transition.reviewerRef.trim(),
        roleId: 'owner_attention_inbox',
        module: 'owner_attention_inbox',
        actionId: 'owner_attention.status_transition',
        result: transition.nextStatus,
        reason:
            'Owner Attention review workflow status changed. Source record was not mutated.',
        scope: <String, dynamic>{
          'attentionId': current.event.attentionId,
          'fromStatus': current.event.status,
          'toStatus': transition.nextStatus,
          'reviewVersion': next.reviewVersion,
          'reviewerRole': transition.reviewerRole,
        },
      );

      return next;
    });
  }
}

class AgentOwnerAttentionRepositoryException implements Exception {
  const AgentOwnerAttentionRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'AgentOwnerAttentionRepositoryException: $message';
}
