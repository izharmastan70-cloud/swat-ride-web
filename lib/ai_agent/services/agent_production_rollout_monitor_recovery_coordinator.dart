import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../super_admin/models/super_admin_access_result.dart';
import '../../super_admin/services/super_admin_access_service.dart';
import '../models/agent_production_rollout_monitor_recovery_models.dart';
import 'agent_emergency_stop_service.dart';
import 'agent_production_rollout_monitor_recovery_policy.dart';
import 'agent_production_rollout_step1g_authenticated_owner_policy.dart';

class AgentProductionRolloutMonitorRecoveryCoordinator {
  factory AgentProductionRolloutMonitorRecoveryCoordinator({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    SuperAdminAccessService? accessService,
  }) {
    final FirebaseAuth resolvedAuth = auth ?? FirebaseAuth.instance;
    final FirebaseFirestore resolvedFirestore =
        firestore ?? FirebaseFirestore.instance;

    return AgentProductionRolloutMonitorRecoveryCoordinator._(
      resolvedAuth,
      resolvedFirestore,
      accessService ??
          SuperAdminAccessService(
            auth: resolvedAuth,
            firestore: resolvedFirestore,
          ),
    );
  }

  AgentProductionRolloutMonitorRecoveryCoordinator._(
    this._auth,
    this._firestore,
    this._accessService,
  );

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final SuperAdminAccessService _accessService;

  static const AgentProductionRolloutStep1GAuthenticatedOwnerPolicy
  _authPolicy = AgentProductionRolloutStep1GAuthenticatedOwnerPolicy();

  static const AgentProductionRolloutMonitorRecoveryPolicy _recoveryPolicy =
      AgentProductionRolloutMonitorRecoveryPolicy();

  static const Duration preparedMaxAge = Duration(minutes: 2);

  Future<AgentProductionRolloutMonitorRecoveryPrepared> prepare({
    required String currentAdminId,
  }) async {
    final _RecoveryIdentity identity = await _verifyIdentity(currentAdminId);

    final _RecoveryLiveState state = await _readLiveState(
      currentActorSha256: _sha256(identity.uid),
      expectEmergencyReadOnly: true,
    );

    if (!state.decision.safe) {
      throw StateError(
        'monitor_only_recovery_precheck_blocked_${state.decision.reasonCode}',
      );
    }

    return AgentProductionRolloutMonitorRecoveryPrepared(
      preparedAtUtc: DateTime.now().toUtc(),
      stateFingerprintSha256: state.stateFingerprintSha256,
      activationId: state.activationId,
      armingTokenIdSha256: state.tokenSha256,
      guardRevision: state.guardRevision,
      roleCount: state.roleCount,
      roleProjectionSha256: state.roleProjectionSha256,
      controlStateSha256: state.controlStateSha256,
      planSha256: state.planSha256,
      actorSha256: state.actorSha256,
      ownerApprovalId: state.ownerApprovalId,
    );
  }

  Future<AgentProductionRolloutMonitorRecoveryOutcome> releaseAndReverify({
    required String currentAdminId,
    required String typedConfirmation,
    required AgentProductionRolloutMonitorRecoveryPrepared prepared,
  }) async {
    if (typedConfirmation.trim() != 'RELEASE MONITOR_ONLY') {
      return AgentProductionRolloutMonitorRecoveryOutcome(
        released: false,
        postReleaseVerified: false,
        status: 'BLOCKED_CONFIRMATION',
        reasonCode: 'exact_release_monitor_only_confirmation_required',
        activationId: prepared.activationId,
        guardRevision: prepared.guardRevision,
      );
    }

    final DateTime now = DateTime.now().toUtc();

    if (!prepared.preparedAtUtc.isUtc ||
        now.isBefore(prepared.preparedAtUtc) ||
        now.difference(prepared.preparedAtUtc) > preparedMaxAge) {
      return AgentProductionRolloutMonitorRecoveryOutcome(
        released: false,
        postReleaseVerified: false,
        status: 'BLOCKED_STALE_PRECHECK',
        reasonCode: 'recovery_precheck_expired_prepare_again',
        activationId: prepared.activationId,
        guardRevision: prepared.guardRevision,
      );
    }

    final _RecoveryIdentity identity = await _verifyIdentity(currentAdminId);

    final String currentActorSha = _sha256(identity.uid);

    final _RecoveryLiveState freshPreRelease = await _readLiveState(
      currentActorSha256: currentActorSha,
      expectEmergencyReadOnly: true,
      expectedRoleProjectionSha256: prepared.roleProjectionSha256,
    );

    if (!freshPreRelease.decision.safe) {
      return AgentProductionRolloutMonitorRecoveryOutcome(
        released: false,
        postReleaseVerified: false,
        status: 'BLOCKED_FRESH_PRECHECK',
        reasonCode:
            'fresh_recovery_precheck_blocked_${freshPreRelease.decision.reasonCode}',
        activationId: prepared.activationId,
        guardRevision: prepared.guardRevision,
      );
    }

    if (freshPreRelease.stateFingerprintSha256 !=
            prepared.stateFingerprintSha256 ||
        freshPreRelease.activationId != prepared.activationId ||
        freshPreRelease.tokenSha256 != prepared.armingTokenIdSha256 ||
        freshPreRelease.guardRevision != prepared.guardRevision ||
        freshPreRelease.roleCount != prepared.roleCount ||
        freshPreRelease.controlStateSha256 != prepared.controlStateSha256 ||
        freshPreRelease.planSha256 != prepared.planSha256 ||
        freshPreRelease.actorSha256 != prepared.actorSha256 ||
        freshPreRelease.ownerApprovalId != prepared.ownerApprovalId) {
      return AgentProductionRolloutMonitorRecoveryOutcome(
        released: false,
        postReleaseVerified: false,
        status: 'BLOCKED_STATE_DRIFT',
        reasonCode: 'recovery_state_changed_after_owner_precheck_prepare_again',
        activationId: prepared.activationId,
        guardRevision: prepared.guardRevision,
      );
    }

    await AgentEmergencyStopService().release(
      actorId: identity.uid,
      reason:
          'Phase66 Step1G controlled MONITOR_ONLY recovery after clean immutable activation-artifact precheck.',
    );

    try {
      final _RecoveryLiveState postRelease = await _readLiveState(
        currentActorSha256: currentActorSha,
        expectEmergencyReadOnly: false,
        expectedRoleProjectionSha256: prepared.roleProjectionSha256,
      );

      final List<String> postFailures = List<String>.from(
        postRelease.decision.failureCodes,
      );

      if (postRelease.activationId != prepared.activationId) {
        postFailures.add('ACTIVATION_ID_CHANGED');
      }
      if (postRelease.tokenSha256 != prepared.armingTokenIdSha256) {
        postFailures.add('ARMING_TOKEN_ID_CHANGED');
      }
      if (postRelease.guardRevision != prepared.guardRevision) {
        postFailures.add('GUARD_REVISION_CHANGED');
      }
      if (postRelease.roleCount != prepared.roleCount) {
        postFailures.add('ROLE_COUNT_CHANGED');
      }
      if (postRelease.controlStateSha256 != prepared.controlStateSha256) {
        postFailures.add('CONTROL_STATE_BINDING_CHANGED');
      }
      if (postRelease.planSha256 != prepared.planSha256) {
        postFailures.add('PLAN_BINDING_CHANGED');
      }
      if (postRelease.actorSha256 != prepared.actorSha256) {
        postFailures.add('ACTOR_BINDING_CHANGED');
      }
      if (postRelease.ownerApprovalId != prepared.ownerApprovalId) {
        postFailures.add('OWNER_APPROVAL_BINDING_CHANGED');
      }

      if (postFailures.isNotEmpty) {
        return AgentProductionRolloutMonitorRecoveryOutcome(
          released: true,
          postReleaseVerified: false,
          status: 'CRITICAL_POST_RELEASE_VERIFICATION_FAILED',
          reasonCode:
              '${postFailures.join('+')}_MANUALLY_REACTIVATE_EMERGENCY_STOP',
          activationId: prepared.activationId,
          guardRevision: prepared.guardRevision,
        );
      }

      return AgentProductionRolloutMonitorRecoveryOutcome(
        released: true,
        postReleaseVerified: true,
        status: 'MONITOR_ONLY_RECOVERY_VERIFIED_ACTIVE',
        reasonCode: 'emergency_stop_released_and_monitor_only_reverified_clean',
        activationId: prepared.activationId,
        guardRevision: prepared.guardRevision,
      );
    } on Object catch (error) {
      return AgentProductionRolloutMonitorRecoveryOutcome(
        released: true,
        postReleaseVerified: false,
        status: 'CRITICAL_POST_RELEASE_VERIFICATION_EXCEPTION',
        reasonCode:
            'VERIFIER_EXCEPTION_${error.runtimeType}_MANUALLY_REACTIVATE_EMERGENCY_STOP',
        activationId: prepared.activationId,
        guardRevision: prepared.guardRevision,
      );
    }
  }

  Future<_RecoveryIdentity> _verifyIdentity(String currentAdminId) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw StateError('Firebase Super Admin sign-in required.');
    }

    final SuperAdminAccessResult access = await _accessService
        .checkCurrentAccess(forceRefreshToken: true);

    final IdTokenResult token = await user.getIdTokenResult(true);
    final Map<String, dynamic> claims = token.claims ?? <String, dynamic>{};

    final String claimRole =
        claims['role']?.toString().trim().toLowerCase() ?? '';

    final dynamic rawAuthTime = claims['auth_time'];

    final int? authSeconds = rawAuthTime is num
        ? rawAuthTime.toInt()
        : int.tryParse(rawAuthTime?.toString() ?? '');

    final DateTime? authTimeUtc = authSeconds == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(authSeconds * 1000, isUtc: true);

    final String idToken = token.token?.trim() ?? '';

    final AgentProductionRolloutStep1GAuthDecision decision = _authPolicy
        .evaluate(
          signedIn: true,
          uidMatchesScreenAdmin: user.uid == currentAdminId.trim(),
          superAdminAccessAllowed: access.isAllowed && access.isSuperAdmin,
          testingBypass: access.isTestingBypass,
          accessCameFromCustomClaim:
              access.source == SuperAdminAccessSource.customClaim,
          claimRole: claimRole,
          idTokenPresent: idToken.isNotEmpty,
          authTimeUtc: authTimeUtc,
          nowUtc: DateTime.now().toUtc(),
        );

    if (!decision.allowed || authTimeUtc == null) {
      throw StateError(decision.reasonCode);
    }

    return _RecoveryIdentity(uid: user.uid, authTimeUtc: authTimeUtc);
  }

  Future<_RecoveryLiveState> _readLiveState({
    required String currentActorSha256,
    required bool expectEmergencyReadOnly,
    String? expectedRoleProjectionSha256,
  }) async {
    final DocumentSnapshot<Map<String, dynamic>> masterSnapshot =
        await _firestore.collection('agent_settings').doc('master').get();

    final DocumentSnapshot<Map<String, dynamic>> rolloutSnapshot =
        await _firestore
            .collection('agent_settings')
            .doc('production_rollout')
            .get();

    final DocumentSnapshot<Map<String, dynamic>> guardSnapshot =
        await _firestore
            .collection('agent_settings')
            .doc('production_rollout_guard')
            .get();

    final Map<String, dynamic> master =
        masterSnapshot.data() ?? <String, dynamic>{};

    final Map<String, dynamic> rollout =
        rolloutSnapshot.data() ?? <String, dynamic>{};

    final Map<String, dynamic> guard =
        guardSnapshot.data() ?? <String, dynamic>{};

    final String activationId = (rollout['activationId'] ?? '')
        .toString()
        .trim();

    DocumentSnapshot<Map<String, dynamic>>? activationSnapshot;

    if (activationId.isNotEmpty) {
      activationSnapshot = await _firestore
          .collection('agent_production_rollout_activations')
          .doc(activationId)
          .get();
    }

    final Map<String, dynamic> activation =
        activationSnapshot?.data() ?? <String, dynamic>{};

    final String tokenSha = _normalized(activation['armingTokenIdSha256']);

    DocumentSnapshot<Map<String, dynamic>>? tokenSnapshot;

    if (_isSha256(tokenSha)) {
      tokenSnapshot = await _firestore
          .collection('agent_production_rollout_arming_tokens')
          .doc(tokenSha)
          .get();
    }

    final Map<String, dynamic> token =
        tokenSnapshot?.data() ?? <String, dynamic>{};

    final QuerySnapshot<Map<String, dynamic>> rolesSnapshot = await _firestore
        .collection('agent_roles')
        .get();

    final List<QueryDocumentSnapshot<Map<String, dynamic>>> roleDocs =
        rolesSnapshot.docs;

    final bool enabledAutoRole = roleDocs.any((
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
    ) {
      final Map<String, dynamic> data = doc.data();

      return data['enabled'] == true &&
          data['mode']?.toString().trim() == 'AUTO';
    });

    final String roleProjectionSha = _roleProjectionSha(roleDocs);

    final AgentProductionRolloutMonitorRecoveryDecision decision =
        _recoveryPolicy.evaluate(
          master: master,
          masterExists: masterSnapshot.exists,
          rollout: rollout,
          rolloutExists: rolloutSnapshot.exists,
          guard: guard,
          guardExists: guardSnapshot.exists,
          activation: activation,
          activationExists: activationSnapshot?.exists == true,
          armingToken: token,
          armingTokenExists: tokenSnapshot?.exists == true,
          liveRoleCount: roleDocs.length,
          enabledAutoRole: enabledAutoRole,
          currentActorSha256: currentActorSha256,
          expectEmergencyReadOnly: expectEmergencyReadOnly,
          expectedRoleProjectionSha256: expectedRoleProjectionSha256,
          liveRoleProjectionSha256: roleProjectionSha,
        );

    final int guardRevision = (guard['revision'] as num?)?.toInt() ?? 0;

    final String controlStateSha = _normalized(
      rollout['sourceControlStateFingerprintSha256'],
    );

    final String planSha = _normalized(guard['planFingerprintSha256']);

    final String actorSha = _normalized(guard['actorReferenceSha256']);

    final String ownerApprovalId = (guard['ownerApprovalId'] ?? '')
        .toString()
        .trim();

    final String stateFingerprintSha = _sha256(
      jsonEncode(<String, dynamic>{
        'master': <String, dynamic>{
          'masterEnabled': master['masterEnabled'],
          'emergencyReadOnly': master['emergencyReadOnly'],
          'freeAiEnabled': master['freeAiEnabled'],
          'localAiEnabled': master['localAiEnabled'],
          'paidCodeAiEnabled': master['paidCodeAiEnabled'],
          'paidReasoningEnabled': master['paidReasoningEnabled'],
          'callAgentEnabled': master['callAgentEnabled'],
          'emailAgentEnabled': master['emailAgentEnabled'],
          'customerWhatsAppAgentEnabled':
              master['customerWhatsAppAgentEnabled'],
          'ownerWhatsAppAgentEnabled': master['ownerWhatsAppAgentEnabled'],
          'emergencyWhatsAppAgentEnabled':
              master['emergencyWhatsAppAgentEnabled'],
          'approvalEngineEnabled': master['approvalEngineEnabled'],
          'auditLoggingEnabled': master['auditLoggingEnabled'],
          'askBeforePaid': master['askBeforePaid'],
        },
        'rollout': <String, dynamic>{
          'stage': rollout['stage'],
          'activationId': activationId,
          'guardRevision': rollout['guardRevision'],
          'autoTrafficPercent': rollout['autoTrafficPercent'],
          'businessWriteTrafficPercent': rollout['businessWriteTrafficPercent'],
          'appChatOnly': rollout['appChatOnly'],
          'externalChannelsEnabled': rollout['externalChannelsEnabled'],
          'providerClass': rollout['providerClass'],
          'sourceControlStateFingerprintSha256': controlStateSha,
        },
        'guard': <String, dynamic>{
          'enabled': guard['enabled'],
          'guardVersion': guard['guardVersion'],
          'revision': guardRevision,
          'targetStage': guard['targetStage'],
          'planFingerprintSha256': planSha,
          'actorReferenceSha256': actorSha,
          'ownerApprovalId': ownerApprovalId,
        },
        'activation': <String, dynamic>{
          'status': activation['status'],
          'targetStage': activation['targetStage'],
          'armingTokenConsumed': activation['armingTokenConsumed'],
          'armingTokenIdSha256': tokenSha,
        },
        'token': <String, dynamic>{
          'status': token['status'],
          'tokenIdSha256': token['tokenIdSha256'],
          'guardRevision': token['guardRevision'],
        },
        'roleCount': roleDocs.length,
        'roleProjectionSha256': roleProjectionSha,
      }),
    );

    return _RecoveryLiveState(
      decision: decision,
      stateFingerprintSha256: stateFingerprintSha,
      activationId: activationId,
      tokenSha256: tokenSha,
      guardRevision: guardRevision,
      roleCount: roleDocs.length,
      roleProjectionSha256: roleProjectionSha,
      controlStateSha256: controlStateSha,
      planSha256: planSha,
      actorSha256: actorSha,
      ownerApprovalId: ownerApprovalId,
    );
  }

  String _roleProjectionSha(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> roleDocs,
  ) {
    final List<Map<String, dynamic>> projections =
        roleDocs
            .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
              final Map<String, dynamic> data = doc.data();

              return <String, dynamic>{
                'roleId': (data['roleId'] ?? doc.id).toString().trim(),
                'module': (data['module'] ?? '').toString().trim(),
                'enabled': data['enabled'] == true,
                'mode': (data['mode'] ?? '').toString().trim(),
                'allowedActions': _sortedStrings(data['allowedActions']),
                'approvalRequiredActions': _sortedStrings(
                  data['approvalRequiredActions'],
                ),
                'forbiddenActions': _sortedStrings(data['forbiddenActions']),
                'aiClass': (data['aiClass'] ?? '').toString().trim(),
                'privacyLevel': (data['privacyLevel'] ?? '').toString().trim(),
                'isFailClosed': data['isFailClosed'] == true,
              };
            })
            .toList(growable: false)
          ..sort(
            (Map<String, dynamic> first, Map<String, dynamic> second) =>
                first['roleId'].toString().compareTo(
                  second['roleId'].toString(),
                ),
          );

    return _sha256(jsonEncode(projections));
  }

  List<String> _sortedStrings(dynamic value) {
    if (value is! List) {
      return const <String>[];
    }

    final List<String> result =
        value
            .map((dynamic item) => item.toString().trim())
            .where((String item) => item.isNotEmpty)
            .toSet()
            .toList(growable: true)
          ..sort();

    return List<String>.unmodifiable(result);
  }

  String _normalized(dynamic value) =>
      (value ?? '').toString().trim().toLowerCase();

  bool _isSha256(String value) =>
      RegExp(r'^[a-f0-9]{64}$').hasMatch(value.toLowerCase());

  String _sha256(String value) => sha256.convert(utf8.encode(value)).toString();

  bool get cliRecoverySupported => false;
  bool get requiresAuthenticatedAppSession => true;
  bool get requiresFreshLogin => true;
  bool get requiresExactTypedConfirmation => true;
  bool get automaticRollbackImplemented => false;
  bool get automaticEmergencyReactivationImplemented => false;
  bool get grantsAutoAuthority => false;
  bool get grantsBusinessWriteAuthority => false;
}

class _RecoveryIdentity {
  const _RecoveryIdentity({required this.uid, required this.authTimeUtc});

  final String uid;
  final DateTime authTimeUtc;
}

class _RecoveryLiveState {
  const _RecoveryLiveState({
    required this.decision,
    required this.stateFingerprintSha256,
    required this.activationId,
    required this.tokenSha256,
    required this.guardRevision,
    required this.roleCount,
    required this.roleProjectionSha256,
    required this.controlStateSha256,
    required this.planSha256,
    required this.actorSha256,
    required this.ownerApprovalId,
  });

  final AgentProductionRolloutMonitorRecoveryDecision decision;
  final String stateFingerprintSha256;
  final String activationId;
  final String tokenSha256;
  final int guardRevision;
  final int roleCount;
  final String roleProjectionSha256;
  final String controlStateSha256;
  final String planSha256;
  final String actorSha256;
  final String ownerApprovalId;
}
