import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/agent_audit_constants.dart';
import '../constants/agent_production_rollout_arming_token_constants.dart';
import '../constants/agent_production_rollout_repository_constants.dart';
import '../constants/agent_production_rollout_runtime_guard_constants.dart';
import '../models/agent_master_settings.dart';
import '../models/agent_production_rollout_arming_token_models.dart';
import 'agent_audit_service.dart';

class AgentProductionRolloutArmingTokenRepository {
  factory AgentProductionRolloutArmingTokenRepository({
    FirebaseFirestore? firestore,
    AgentAuditService? auditService,
    bool issuanceArmed = false,
  }) {
    return AgentProductionRolloutArmingTokenRepository._(
      firestore,
      auditService,
      issuanceArmed,
    );
  }

  AgentProductionRolloutArmingTokenRepository._(
    this._firestore,
    this._auditService,
    this._issuanceArmed,
  );

  final FirebaseFirestore? _firestore;
  final AgentAuditService? _auditService;
  final bool _issuanceArmed;

  Future<AgentProductionRolloutArmingTokenIssuanceResult> issue({
    required AgentProductionRolloutArmingTokenIssuanceRequest request,
    required DateTime nowUtc,
  }) async {
    try {
      request.validate();
    } on FormatException {
      return const AgentProductionRolloutArmingTokenIssuanceResult(
        status:
            AgentProductionRolloutArmingTokenRepositoryStatus.blockedInvalid,
        reasonCode: 'arming_token_request_validation_failed',
        tokenIdSha256: '',
        issued: false,
      );
    }

    final DateTime now = nowUtc.toUtc();

    if (now.isBefore(request.credential.issuedAtUtc) ||
        !now.isBefore(request.credential.expiresAtUtc)) {
      return AgentProductionRolloutArmingTokenIssuanceResult(
        status:
            AgentProductionRolloutArmingTokenRepositoryStatus.blockedInvalid,
        reasonCode: 'arming_token_is_not_current',
        tokenIdSha256: request.credential.tokenIdSha256.toLowerCase(),
        issued: false,
      );
    }

    if (!_issuanceArmed) {
      return AgentProductionRolloutArmingTokenIssuanceResult(
        status:
            AgentProductionRolloutArmingTokenRepositoryStatus.blockedNotArmed,
        reasonCode: 'arming_token_issuance_repository_is_not_armed',
        tokenIdSha256: request.credential.tokenIdSha256.toLowerCase(),
        issued: false,
      );
    }

    final FirebaseFirestore firestore =
        _firestore ?? FirebaseFirestore.instance;

    final AgentAuditService auditService =
        _auditService ?? AgentAuditService(firestore: firestore);

    final DocumentReference<Map<String, dynamic>> guardRef = firestore
        .collection(AgentProductionRolloutRepositoryPath.settingsCollection)
        .doc(AgentProductionRolloutRepositoryPath.rolloutGuardDocument);

    final DocumentReference<Map<String, dynamic>> masterRef = firestore
        .collection(AgentProductionRolloutRepositoryPath.settingsCollection)
        .doc(AgentProductionRolloutRepositoryPath.masterDocument);

    final DocumentReference<Map<String, dynamic>> rolloutRef = firestore
        .collection(AgentProductionRolloutRepositoryPath.settingsCollection)
        .doc(AgentProductionRolloutRepositoryPath.rolloutStateDocument);

    final DocumentReference<Map<String, dynamic>> tokenRef = firestore
        .collection(AgentProductionRolloutArmingTokenCollection.path)
        .doc(request.credential.tokenIdSha256.toLowerCase());

    return firestore.runTransaction<
      AgentProductionRolloutArmingTokenIssuanceResult
    >((Transaction transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> tokenSnapshot =
          await transaction.get(tokenRef);

      if (tokenSnapshot.exists) {
        return AgentProductionRolloutArmingTokenIssuanceResult(
          status: AgentProductionRolloutArmingTokenRepositoryStatus
              .blockedCollision,
          reasonCode: 'arming_token_sha256_document_already_exists',
          tokenIdSha256: tokenRef.id,
          issued: false,
        );
      }

      final DocumentSnapshot<Map<String, dynamic>> guardSnapshot =
          await transaction.get(guardRef);

      if (!guardSnapshot.exists) {
        return AgentProductionRolloutArmingTokenIssuanceResult(
          status:
              AgentProductionRolloutArmingTokenRepositoryStatus.blockedGuard,
          reasonCode: 'owner_bound_runtime_guard_is_missing',
          tokenIdSha256: tokenRef.id,
          issued: false,
        );
      }

      final Map<String, dynamic> guard =
          guardSnapshot.data() ?? <String, dynamic>{};

      final bool exactGuard =
          guard['enabled'] == true &&
          guard['guardVersion'] ==
              AgentProductionRolloutRuntimeGuardVersion.monitorOnlyV1 &&
          (guard['revision'] as num?)?.toInt() ==
              request.credential.guardRevision &&
          guard['targetStage'] ==
              AgentProductionRolloutRuntimeGuardStatus.monitorOnly &&
          guard['runtimeMonitorOnlyOverlayEnforced'] == true &&
          guard['noAutoBusinessWriteBoundaryEnforced'] == true &&
          guard['appChatOnly'] == true &&
          (guard['autoTrafficPercent'] as num?)?.toInt() == 0 &&
          (guard['businessWriteTrafficPercent'] as num?)?.toInt() == 0 &&
          guard['externalChannelsEnabled'] == false &&
          (guard['controlStateFingerprintSha256'] ?? '')
                  .toString()
                  .trim()
                  .toLowerCase() ==
              request.credential.controlStateFingerprintSha256.toLowerCase() &&
          (guard['planFingerprintSha256'] ?? '')
                  .toString()
                  .trim()
                  .toLowerCase() ==
              request.credential.planFingerprintSha256.toLowerCase() &&
          (guard['roleCount'] as num?)?.toInt() ==
              request.credential.roleCount &&
          (guard['ownerApprovalId'] ?? '').toString().trim() ==
              request.credential.ownerApprovalId &&
          (guard['actorReferenceSha256'] ?? '')
                  .toString()
                  .trim()
                  .toLowerCase() ==
              request.credential.actorReferenceSha256.toLowerCase();

      if (!exactGuard) {
        return AgentProductionRolloutArmingTokenIssuanceResult(
          status:
              AgentProductionRolloutArmingTokenRepositoryStatus.blockedGuard,
          reasonCode:
              'persisted_guard_does_not_exactly_match_arming_credential',
          tokenIdSha256: tokenRef.id,
          issued: false,
        );
      }

      final DocumentSnapshot<Map<String, dynamic>> masterSnapshot =
          await transaction.get(masterRef);

      if (!masterSnapshot.exists) {
        return AgentProductionRolloutArmingTokenIssuanceResult(
          status:
              AgentProductionRolloutArmingTokenRepositoryStatus.blockedMaster,
          reasonCode: 'master_document_must_exist_before_token_issuance',
          tokenIdSha256: tokenRef.id,
          issued: false,
        );
      }

      final AgentMasterSettings master = AgentMasterSettings.fromMap(
        masterSnapshot.data() ?? <String, dynamic>{},
      );

      final bool safeMaster =
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

      if (!safeMaster) {
        return AgentProductionRolloutArmingTokenIssuanceResult(
          status:
              AgentProductionRolloutArmingTokenRepositoryStatus.blockedMaster,
          reasonCode: 'master_state_changed_before_token_issuance',
          tokenIdSha256: tokenRef.id,
          issued: false,
        );
      }

      final DocumentSnapshot<Map<String, dynamic>> rolloutSnapshot =
          await transaction.get(rolloutRef);

      if (rolloutSnapshot.exists) {
        final String stage =
            ((rolloutSnapshot.data() ?? <String, dynamic>{})['stage'] ?? 'OFF')
                .toString()
                .trim();

        if (stage != 'OFF') {
          return AgentProductionRolloutArmingTokenIssuanceResult(
            status: AgentProductionRolloutArmingTokenRepositoryStatus
                .blockedRollout,
            reasonCode:
                'rollout_must_still_be_off_before_arming_token_issuance',
            tokenIdSha256: tokenRef.id,
            issued: false,
          );
        }
      }

      final Map<String, dynamic> payload = request.credential.toPersistentMap();

      payload['issuedAt'] = Timestamp.fromDate(request.credential.issuedAtUtc);
      payload['expiresAt'] = Timestamp.fromDate(
        request.credential.expiresAtUtc,
      );
      payload.remove('issuedAtUtc');
      payload.remove('expiresAtUtc');
      payload['createdAt'] = FieldValue.serverTimestamp();

      transaction.set(tokenRef, payload);

      auditService.appendInTransaction(
        transaction: transaction,
        eventType: AgentAuditEventType.systemEvent,
        severity: AgentAuditSeverity.warning,
        actorType: AgentAuditActorType.admin,
        actorId: request.credential.actorReferenceSha256,
        module: 'ai_core',
        actionId: 'ai.production_rollout.arming_token.issue',
        result: 'ISSUED',
        reason:
            'One-time MONITOR_ONLY arming token issued after exact live guard verification.',
        relatedApprovalId: request.credential.ownerApprovalId,
        scope: <String, dynamic>{
          'targetStage': 'MONITOR_ONLY',
          'guardRevision': request.credential.guardRevision,
          'autoTrafficPercent': 0,
          'businessWriteTrafficPercent': 0,
          'externalChannelsEnabled': false,
        },
        metadata: <String, dynamic>{
          'tokenIdSha256': tokenRef.id,
          'planFingerprintSha256': request.credential.planFingerprintSha256
              .toLowerCase(),
          'controlStateFingerprintSha256': request
              .credential
              .controlStateFingerprintSha256
              .toLowerCase(),
          'roleCount': request.credential.roleCount,
        },
      );

      return AgentProductionRolloutArmingTokenIssuanceResult(
        status: AgentProductionRolloutArmingTokenRepositoryStatus.issued,
        reasonCode: 'one_time_owner_bound_arming_token_persisted_atomically',
        tokenIdSha256: tokenRef.id,
        issued: true,
      );
    });
  }

  bool get issuanceArmed => _issuanceArmed;
  bool get defaultsNotArmed => true;
  bool get persistsRawToken => false;
  bool get logsRawToken => false;
  bool get usesFirestoreTransaction => true;
  bool get usesSameTransactionAudit => true;
  bool get activatesProduction => false;
  bool get armsActivationRepository => false;
  bool get scriptInvokesTokenIssuance => false;
}
