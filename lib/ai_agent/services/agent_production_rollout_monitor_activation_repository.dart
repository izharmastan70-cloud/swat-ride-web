import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/agent_audit_constants.dart';
import '../constants/agent_production_rollout_repository_constants.dart';
import '../constants/agent_production_rollout_snapshot_constants.dart';
import '../models/agent_master_settings.dart';
import '../constants/agent_production_rollout_arming_token_constants.dart';
import '../models/agent_production_rollout_arming_token_models.dart';
import '../models/agent_production_rollout_repository_models.dart';
import 'agent_audit_service.dart';
import 'agent_production_rollout_activation_authorization_policy.dart';
import 'agent_production_rollout_monitor_repository_policy.dart';

class AgentProductionRolloutMonitorActivationRepository {
  factory AgentProductionRolloutMonitorActivationRepository({
    FirebaseFirestore? firestore,
    AgentAuditService? auditService,
    bool executionArmed = false,
  }) {
    return AgentProductionRolloutMonitorActivationRepository._(
      firestore,
      auditService,
      executionArmed,
    );
  }

  AgentProductionRolloutMonitorActivationRepository._(
    this._firestore,
    this._auditService,
    this._executionArmed,
  );

  final FirebaseFirestore? _firestore;
  final AgentAuditService? _auditService;
  final bool _executionArmed;

  Future<AgentProductionRolloutActivationRepositoryResult> activate({
    required AgentProductionRolloutMonitorExecutionRequest request,
    required DateTime nowUtc,
    AgentProductionRolloutArmingCredential? armingCredential,
  }) async {
    const AgentProductionRolloutMonitorRepositoryPolicy policy =
        AgentProductionRolloutMonitorRepositoryPolicy();

    final precheck = policy.evaluate(
      request: request,
      nowUtc: nowUtc,
      executionArmed: _executionArmed,
    );

    if (!precheck.allowed) {
      return AgentProductionRolloutActivationRepositoryResult(
        status: precheck.status,
        reasonCode: precheck.reasonCode,
        activationId: request.idempotencyKeySha256,
        applied: false,
        idempotentReplay: false,
      );
    }
    const AgentProductionRolloutActivationAuthorizationPolicy
    authorizationPolicy = AgentProductionRolloutActivationAuthorizationPolicy();

    final authorization = authorizationPolicy.evaluate(
      request: request,
      credential: armingCredential,
      nowUtc: nowUtc,
    );

    if (!authorization.authorized) {
      return AgentProductionRolloutActivationRepositoryResult(
        status: authorization.status,
        reasonCode: authorization.reasonCode,
        activationId: request.idempotencyKeySha256,
        applied: false,
        idempotentReplay: false,
      );
    }

    final FirebaseFirestore firestore =
        _firestore ?? FirebaseFirestore.instance;

    final AgentAuditService auditService =
        _auditService ?? AgentAuditService(firestore: firestore);

    final DocumentReference<Map<String, dynamic>> masterRef = firestore
        .collection(AgentProductionRolloutRepositoryPath.settingsCollection)
        .doc(AgentProductionRolloutRepositoryPath.masterDocument);

    final DocumentReference<Map<String, dynamic>> rolloutRef = firestore
        .collection(AgentProductionRolloutRepositoryPath.settingsCollection)
        .doc(AgentProductionRolloutRepositoryPath.rolloutStateDocument);

    final DocumentReference<Map<String, dynamic>> guardRef = firestore
        .collection(AgentProductionRolloutRepositoryPath.settingsCollection)
        .doc(AgentProductionRolloutRepositoryPath.rolloutGuardDocument);

    final DocumentReference<Map<String, dynamic>> activationRef = firestore
        .collection(AgentProductionRolloutRepositoryPath.activationsCollection)
        .doc(request.idempotencyKeySha256);
    final DocumentReference<Map<String, dynamic>> armingTokenRef = firestore
        .collection(AgentProductionRolloutArmingTokenCollection.path)
        .doc(authorization.tokenIdSha256);

    return firestore.runTransaction<
      AgentProductionRolloutActivationRepositoryResult
    >((Transaction transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> existingActivation =
          await transaction.get(activationRef);

      if (existingActivation.exists) {
        final Map<String, dynamic> data =
            existingActivation.data() ?? <String, dynamic>{};

        final String storedFingerprint = (data['planFingerprintSha256'] ?? '')
            .toString()
            .trim()
            .toLowerCase();

        final String storedStatus = (data['status'] ?? '').toString().trim();

        if (storedFingerprint == request.planFingerprintSha256.toLowerCase() &&
            storedStatus ==
                AgentProductionRolloutRepositoryRecordStatus.applied) {
          return AgentProductionRolloutActivationRepositoryResult(
            status: AgentProductionRolloutRepositoryStatus.alreadyApplied,
            reasonCode: 'same_exact_monitor_only_activation_already_applied',
            activationId: activationRef.id,
            applied: true,
            idempotentReplay: true,
          );
        }

        return AgentProductionRolloutActivationRepositoryResult(
          status: AgentProductionRolloutRepositoryStatus
              .blockedIdempotencyCollision,
          reasonCode: 'idempotency_key_exists_with_different_binding_or_status',
          activationId: activationRef.id,
          applied: false,
          idempotentReplay: false,
        );
      }

      final DocumentSnapshot<Map<String, dynamic>> armingTokenSnapshot =
          await transaction.get(armingTokenRef);

      if (!armingTokenSnapshot.exists) {
        return AgentProductionRolloutActivationRepositoryResult(
          status:
              AgentProductionRolloutArmingAuthorizationStatus.blockedMissing,
          reasonCode: 'persisted_one_time_arming_token_is_missing',
          activationId: activationRef.id,
          applied: false,
          idempotentReplay: false,
        );
      }

      final Map<String, dynamic> armingToken =
          armingTokenSnapshot.data() ?? <String, dynamic>{};

      final String tokenStatus = (armingToken['status'] ?? '')
          .toString()
          .trim();

      if (tokenStatus != AgentProductionRolloutArmingTokenStatus.ready) {
        return AgentProductionRolloutActivationRepositoryResult(
          status:
              AgentProductionRolloutArmingAuthorizationStatus.blockedInvalid,
          reasonCode: 'one_time_arming_token_is_not_ready',
          activationId: activationRef.id,
          applied: false,
          idempotentReplay: false,
        );
      }

      final dynamic rawExpiresAt = armingToken['expiresAt'];
      final DateTime? tokenExpiresAt = rawExpiresAt is Timestamp
          ? rawExpiresAt.toDate().toUtc()
          : rawExpiresAt is DateTime
          ? rawExpiresAt.toUtc()
          : null;

      final DateTime transactionalNow = nowUtc.toUtc();

      if (tokenExpiresAt == null ||
          !transactionalNow.isBefore(tokenExpiresAt)) {
        return AgentProductionRolloutActivationRepositoryResult(
          status:
              AgentProductionRolloutArmingAuthorizationStatus.blockedExpired,
          reasonCode: 'persisted_one_time_arming_token_is_expired',
          activationId: activationRef.id,
          applied: false,
          idempotentReplay: false,
        );
      }

      final bool exactArmingBinding =
          (armingToken['tokenIdSha256'] ?? '')
                  .toString()
                  .trim()
                  .toLowerCase() ==
              authorization.tokenIdSha256 &&
          (armingToken['targetStage'] ?? '').toString().trim() ==
              AgentProductionRolloutStage.monitorOnly &&
          (armingToken['actorReferenceSha256'] ?? '')
                  .toString()
                  .trim()
                  .toLowerCase() ==
              request.plan.actorReferenceSha256.toLowerCase() &&
          (armingToken['ownerApprovalId'] ?? '').toString().trim() ==
              request.plan.ownerApprovalId &&
          (armingToken['planFingerprintSha256'] ?? '')
                  .toString()
                  .trim()
                  .toLowerCase() ==
              request.planFingerprintSha256.toLowerCase() &&
          (armingToken['controlStateFingerprintSha256'] ?? '')
                  .toString()
                  .trim()
                  .toLowerCase() ==
              request.plan.sourceControlStateFingerprintSha256.toLowerCase() &&
          (armingToken['guardRevision'] as num?)?.toInt() ==
              request.expectedGuardRevision &&
          (armingToken['guardVersion'] ?? '').toString().trim() ==
              request.expectedGuardVersion &&
          (armingToken['roleCount'] as num?)?.toInt() ==
              request.plan.precondition.expectedRoleCount;

      if (!exactArmingBinding) {
        return AgentProductionRolloutActivationRepositoryResult(
          status:
              AgentProductionRolloutArmingAuthorizationStatus.blockedBinding,
          reasonCode:
              'persisted_arming_token_binding_changed_before_activation',
          activationId: activationRef.id,
          applied: false,
          idempotentReplay: false,
        );
      }
      final DocumentSnapshot<Map<String, dynamic>> guardSnapshot =
          await transaction.get(guardRef);

      if (!guardSnapshot.exists) {
        return AgentProductionRolloutActivationRepositoryResult(
          status: AgentProductionRolloutRepositoryStatus.blockedGuardMissing,
          reasonCode: 'production_rollout_guard_must_exist_before_activation',
          activationId: activationRef.id,
          applied: false,
          idempotentReplay: false,
        );
      }

      final Map<String, dynamic> guard =
          guardSnapshot.data() ?? <String, dynamic>{};

      if (guard['enabled'] != true) {
        return AgentProductionRolloutActivationRepositoryResult(
          status: AgentProductionRolloutRepositoryStatus.blockedGuardDisabled,
          reasonCode: 'production_rollout_guard_is_disabled',
          activationId: activationRef.id,
          applied: false,
          idempotentReplay: false,
        );
      }

      if (guard['runtimeMonitorOnlyOverlayEnforced'] != true) {
        return AgentProductionRolloutActivationRepositoryResult(
          status: AgentProductionRolloutRepositoryStatus.blockedRuntimeOverlay,
          reasonCode: 'runtime_monitor_only_overlay_must_be_enforced_first',
          activationId: activationRef.id,
          applied: false,
          idempotentReplay: false,
        );
      }

      if (guard['noAutoBusinessWriteBoundaryEnforced'] != true) {
        return AgentProductionRolloutActivationRepositoryResult(
          status: AgentProductionRolloutRepositoryStatus.blockedNoAutoBoundary,
          reasonCode: 'no_auto_and_no_business_write_runtime_boundary_required',
          activationId: activationRef.id,
          applied: false,
          idempotentReplay: false,
        );
      }

      final int guardRevision = (guard['revision'] as num?)?.toInt() ?? -1;

      final String guardVersion = (guard['guardVersion'] ?? '')
          .toString()
          .trim();

      if (guardRevision != request.expectedGuardRevision ||
          guardVersion != request.expectedGuardVersion) {
        return AgentProductionRolloutActivationRepositoryResult(
          status: AgentProductionRolloutRepositoryStatus.blockedGuardRevision,
          reasonCode: 'production_rollout_guard_revision_or_version_changed',
          activationId: activationRef.id,
          applied: false,
          idempotentReplay: false,
        );
      }

      final String guardedControlSha =
          (guard['controlStateFingerprintSha256'] ?? '')
              .toString()
              .trim()
              .toLowerCase();

      if (guardedControlSha !=
          request.plan.sourceControlStateFingerprintSha256.toLowerCase()) {
        return AgentProductionRolloutActivationRepositoryResult(
          status: AgentProductionRolloutRepositoryStatus
              .blockedControlStateMismatch,
          reasonCode: 'guarded_control_state_changed_after_owner_plan',
          activationId: activationRef.id,
          applied: false,
          idempotentReplay: false,
        );
      }

      final int guardedRoleCount = (guard['roleCount'] as num?)?.toInt() ?? -1;

      if (guardedRoleCount != request.plan.precondition.expectedRoleCount) {
        return AgentProductionRolloutActivationRepositoryResult(
          status:
              AgentProductionRolloutRepositoryStatus.blockedRoleCountMismatch,
          reasonCode: 'guarded_role_count_changed_after_owner_plan',
          activationId: activationRef.id,
          applied: false,
          idempotentReplay: false,
        );
      }

      final DocumentSnapshot<Map<String, dynamic>> masterSnapshot =
          await transaction.get(masterRef);

      if (!masterSnapshot.exists) {
        return AgentProductionRolloutActivationRepositoryResult(
          status: AgentProductionRolloutRepositoryStatus.blockedMasterMissing,
          reasonCode: 'agent_settings_master_must_exist_before_activation',
          activationId: activationRef.id,
          applied: false,
          idempotentReplay: false,
        );
      }

      final AgentMasterSettings master = AgentMasterSettings.fromMap(
        masterSnapshot.data() ?? <String, dynamic>{},
      );

      final bool safeInitialBaseline =
          !master.masterEnabled &&
          master.emergencyReadOnly &&
          !master.freeAiEnabled &&
          !master.localAiEnabled &&
          !master.paidCodeAiEnabled &&
          !master.paidReasoningEnabled &&
          !master.callAgentEnabled &&
          !master.emailAgentEnabled &&
          !master.customerWhatsAppAgentEnabled &&
          !master.ownerWhatsAppAgentEnabled &&
          !master.emergencyWhatsAppAgentEnabled &&
          master.approvalEngineEnabled &&
          master.auditLoggingEnabled &&
          master.askBeforePaid;

      if (!safeInitialBaseline) {
        return AgentProductionRolloutActivationRepositoryResult(
          status: AgentProductionRolloutRepositoryStatus
              .blockedUnsafeMasterBaseline,
          reasonCode:
              'live_master_state_no_longer_matches_initial_fail_closed_baseline',
          activationId: activationRef.id,
          applied: false,
          idempotentReplay: false,
        );
      }

      final DocumentSnapshot<Map<String, dynamic>> rolloutSnapshot =
          await transaction.get(rolloutRef);

      if (rolloutSnapshot.exists) {
        final String currentStage =
            ((rolloutSnapshot.data() ?? <String, dynamic>{})['stage'] ??
                    AgentProductionRolloutStage.off)
                .toString()
                .trim();

        if (currentStage != AgentProductionRolloutStage.off) {
          return AgentProductionRolloutActivationRepositoryResult(
            status: AgentProductionRolloutRepositoryStatus
                .blockedExistingRolloutState,
            reasonCode:
                'initial_monitor_only_activation_requires_rollout_stage_off',
            activationId: activationRef.id,
            applied: false,
            idempotentReplay: false,
          );
        }
      }

      final DateTime now = nowUtc.toUtc();

      if (now.isBefore(request.plan.precondition.createdAtUtc) ||
          !now.isBefore(request.plan.precondition.expiresAtUtc)) {
        return AgentProductionRolloutActivationRepositoryResult(
          status:
              AgentProductionRolloutRepositoryStatus.blockedExpiredPrecondition,
          reasonCode: 'atomic_precondition_expired_during_transaction',
          activationId: activationRef.id,
          applied: false,
          idempotentReplay: false,
        );
      }

      transaction.update(armingTokenRef, <String, dynamic>{
        'status': AgentProductionRolloutArmingTokenStatus.consumed,
        'consumedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(masterRef, <String, dynamic>{
        'masterEnabled': true,
        'emergencyReadOnly': false,
        'freeAiEnabled': true,
        'localAiEnabled': false,
        'paidCodeAiEnabled': false,
        'paidReasoningEnabled': false,
        'callAgentEnabled': false,
        'emailAgentEnabled': false,
        'customerWhatsAppAgentEnabled': false,
        'ownerWhatsAppAgentEnabled': false,
        'emergencyWhatsAppAgentEnabled': false,
        'approvalEngineEnabled': true,
        'auditLoggingEnabled': true,
        'askBeforePaid': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.set(rolloutRef, <String, dynamic>{
        'stage': AgentProductionRolloutStage.monitorOnly,
        'autoTrafficPercent': 0,
        'businessWriteTrafficPercent': 0,
        'appChatOnly': true,
        'externalChannelsEnabled': false,
        'providerClass': 'FREE_AI_ONLY',
        'sourceSnapshotFingerprintSha256': request
            .plan
            .sourceSnapshotFingerprintSha256
            .toLowerCase(),
        'sourceControlStateFingerprintSha256': request
            .plan
            .sourceControlStateFingerprintSha256
            .toLowerCase(),
        'guardRevision': request.expectedGuardRevision,
        'guardVersion': request.expectedGuardVersion,
        'ownerApprovalId': request.plan.ownerApprovalId,
        'activationId': activationRef.id,
        'activatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.set(activationRef, <String, dynamic>{
        'activationId': activationRef.id,
        'status': AgentProductionRolloutRepositoryRecordStatus.applied,
        'targetStage': AgentProductionRolloutStage.monitorOnly,
        'planId': request.plan.planId,
        'planFingerprintSha256': request.planFingerprintSha256.toLowerCase(),
        'idempotencyKeySha256': request.idempotencyKeySha256.toLowerCase(),
        'armingTokenIdSha256': authorization.tokenIdSha256,
        'armingTokenConsumed': true,
        'sourceSnapshotFingerprintSha256': request
            .plan
            .sourceSnapshotFingerprintSha256
            .toLowerCase(),
        'sourceControlStateFingerprintSha256': request
            .plan
            .sourceControlStateFingerprintSha256
            .toLowerCase(),
        'actorReferenceSha256': request.plan.actorReferenceSha256.toLowerCase(),
        'ownerApprovalId': request.plan.ownerApprovalId,
        'guardRevision': request.expectedGuardRevision,
        'guardVersion': request.expectedGuardVersion,
        'autoTrafficPercent': 0,
        'businessWriteTrafficPercent': 0,
        'externalChannelsEnabled': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      auditService.appendInTransaction(
        transaction: transaction,
        eventType: AgentAuditEventType.systemEvent,
        severity: AgentAuditSeverity.warning,
        actorType: AgentAuditActorType.admin,
        actorId: request.plan.actorReferenceSha256,
        module: 'ai_core',
        actionId: 'ai.production_rollout.monitor_only.activate',
        result: 'APPLIED',
        reason:
            'Owner-bound MONITOR_ONLY production rollout activation applied atomically.',
        relatedApprovalId: request.plan.ownerApprovalId,
        scope: <String, dynamic>{
          'targetStage': AgentProductionRolloutStage.monitorOnly,
          'autoTrafficPercent': 0,
          'businessWriteTrafficPercent': 0,
          'externalChannelsEnabled': false,
        },
        metadata: <String, dynamic>{
          'activationId': activationRef.id,
          'armingTokenIdSha256': authorization.tokenIdSha256,
          'planFingerprintSha256': request.planFingerprintSha256.toLowerCase(),
          'sourceControlStateFingerprintSha256': request
              .plan
              .sourceControlStateFingerprintSha256
              .toLowerCase(),
          'guardRevision': request.expectedGuardRevision,
        },
      );

      return AgentProductionRolloutActivationRepositoryResult(
        status: AgentProductionRolloutRepositoryStatus.appliedMonitorOnly,
        reasonCode: 'monitor_only_state_and_audit_committed_atomically',
        activationId: activationRef.id,
        applied: true,
        idempotentReplay: false,
      );
    });
  }

  bool get executionArmed => _executionArmed;
  bool get defaultsNotArmed => true;

  bool get usesFirestoreTransaction => true;
  bool get usesSameTransactionAudit => true;
  bool get usesIdempotencyReceipt => true;
  bool get usesGuardRevisionConcurrencyCheck => true;
  bool get requiresRuntimeMonitorOnlyOverlay => true;
  bool get requiresNoAutoBusinessWriteBoundary => true;

  bool get writesAgentRoles => false;
  bool get enablesAuto => false;
  bool get routesAutoTraffic => false;
  bool get enablesBusinessWrites => false;
  bool get enablesPaidAi => false;
  bool get enablesLocalAi => false;
  bool get enablesCallAgent => false;
  bool get enablesEmailAgent => false;
  bool get enablesCustomerWhatsApp => false;
  bool get enablesOwnerWhatsApp => false;
  bool get enablesEmergencyWhatsApp => false;
  bool get requiresOneTimeArmingToken => true;
  bool get consumesArmingTokenAtomically => true;
  bool get storesRawArmingToken => false;
  bool get logsRawArmingToken => false;

  bool get scriptInvokesLiveActivation => false;
}
