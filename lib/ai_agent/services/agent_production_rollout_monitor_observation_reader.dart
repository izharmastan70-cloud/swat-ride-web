import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../super_admin/services/super_admin_access_service.dart';
import '../models/agent_production_rollout_monitor_observation_models.dart';
import 'agent_production_rollout_monitor_observation_policy.dart';

class AgentProductionRolloutMonitorObservationReader {
  factory AgentProductionRolloutMonitorObservationReader({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    SuperAdminAccessService? accessService,
  }) {
    final FirebaseAuth resolvedAuth = auth ?? FirebaseAuth.instance;
    final FirebaseFirestore resolvedFirestore =
        firestore ?? FirebaseFirestore.instance;

    return AgentProductionRolloutMonitorObservationReader._(
      resolvedAuth,
      resolvedFirestore,
      accessService ??
          SuperAdminAccessService(
            auth: resolvedAuth,
            firestore: resolvedFirestore,
          ),
    );
  }

  AgentProductionRolloutMonitorObservationReader._(
    this._auth,
    this._firestore,
    this._accessService,
  );

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final SuperAdminAccessService _accessService;

  static const AgentProductionRolloutMonitorObservationPolicy _policy =
      AgentProductionRolloutMonitorObservationPolicy();

  Future<AgentProductionRolloutMonitorObservation> read({
    required String currentAdminId,
  }) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw StateError('Firebase Super Admin sign-in required.');
    }

    final access = await _accessService.checkCurrentAccess(
      forceRefreshToken: true,
    );

    final IdTokenResult tokenResult = await user.getIdTokenResult(true);
    final Map<String, dynamic> claims =
        tokenResult.claims ?? <String, dynamic>{};

    final String role = claims['role']?.toString().trim().toLowerCase() ?? '';

    if (user.uid != currentAdminId.trim() ||
        !access.isAllowed ||
        !access.isSuperAdmin ||
        access.isTestingBypass ||
        role != 'super_admin') {
      throw StateError(
        'MONITOR_ONLY observation requires verified Firebase super_admin.',
      );
    }

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

    final String armingTokenSha = (activation['armingTokenIdSha256'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    DocumentSnapshot<Map<String, dynamic>>? tokenSnapshot;

    if (RegExp(r'^[a-f0-9]{64}$').hasMatch(armingTokenSha)) {
      tokenSnapshot = await _firestore
          .collection('agent_production_rollout_arming_tokens')
          .doc(armingTokenSha)
          .get();
    }

    final Map<String, dynamic> token =
        tokenSnapshot?.data() ?? <String, dynamic>{};

    final QuerySnapshot<Map<String, dynamic>> rolesSnapshot = await _firestore
        .collection('agent_roles')
        .get();

    final List<QueryDocumentSnapshot<Map<String, dynamic>>> roleDocs =
        rolesSnapshot.docs;

    final int enabledAutoRoleCount = roleDocs.where((
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
    ) {
      final Map<String, dynamic> data = doc.data();

      return data['enabled'] == true &&
          data['mode']?.toString().trim() == 'AUTO';
    }).length;

    final AgentProductionRolloutMonitorObservationDecision decision = _policy
        .evaluate(
          masterExists: masterSnapshot.exists,
          master: master,
          rolloutExists: rolloutSnapshot.exists,
          rollout: rollout,
          guardExists: guardSnapshot.exists,
          guard: guard,
          activationExists: activationSnapshot?.exists == true,
          activation: activation,
          tokenExists: tokenSnapshot?.exists == true,
          token: token,
          liveRoleCount: roleDocs.length,
          enabledAutoRoleCount: enabledAutoRoleCount,
        );

    return AgentProductionRolloutMonitorObservation(
      observedAtUtc: DateTime.now().toUtc(),
      rolloutActivatedAtUtc: _timestampUtc(rollout['activatedAt']),
      activationId: activationId,
      guardRevision: _intValue(guard['revision']),
      roleCount: roleDocs.length,
      enabledAutoRoleCount: enabledAutoRoleCount,
      stage: (rollout['stage'] ?? '').toString().trim(),
      autoTrafficPercent: _intValue(rollout['autoTrafficPercent']),
      businessWriteTrafficPercent: _intValue(
        rollout['businessWriteTrafficPercent'],
      ),
      externalChannelsEnabled: rollout['externalChannelsEnabled'] == true,
      masterEnabled: master['masterEnabled'] == true,
      emergencyReadOnly: master['emergencyReadOnly'] == true,
      freeAiEnabled: master['freeAiEnabled'] == true,
      localAiEnabled: master['localAiEnabled'] == true,
      paidCodeAiEnabled: master['paidCodeAiEnabled'] == true,
      paidReasoningEnabled: master['paidReasoningEnabled'] == true,
      callAgentEnabled: master['callAgentEnabled'] == true,
      emailAgentEnabled: master['emailAgentEnabled'] == true,
      customerWhatsAppAgentEnabled:
          master['customerWhatsAppAgentEnabled'] == true,
      ownerWhatsAppAgentEnabled: master['ownerWhatsAppAgentEnabled'] == true,
      emergencyWhatsAppAgentEnabled:
          master['emergencyWhatsAppAgentEnabled'] == true,
      approvalEngineEnabled: master['approvalEngineEnabled'] == true,
      auditLoggingEnabled: master['auditLoggingEnabled'] == true,
      askBeforePaid: master['askBeforePaid'] == true,
      runtimeGuardClean: !decision.failureCodes.contains(
        'RUNTIME_GUARD_MISMATCH',
      ),
      activationReceiptClean: !decision.failureCodes.contains(
        'ACTIVATION_RECEIPT_MISMATCH',
      ),
      armingTokenClean: !decision.failureCodes.contains(
        'ARMING_TOKEN_MISMATCH',
      ),
      revisionBindingClean: !decision.failureCodes.contains(
        'GUARD_REVISION_BINDING_MISMATCH',
      ),
      roleCountBindingClean: !decision.failureCodes.contains(
        'ROLE_COUNT_BINDING_MISMATCH',
      ),
      controlBindingClean: !decision.failureCodes.contains(
        'CONTROL_STATE_BINDING_MISMATCH',
      ),
      planBindingClean: !decision.failureCodes.contains(
        'PLAN_BINDING_MISMATCH',
      ),
      actorBindingClean: !decision.failureCodes.contains(
        'OWNER_ACTOR_BINDING_MISMATCH',
      ),
      approvalBindingClean: !decision.failureCodes.contains(
        'OWNER_APPROVAL_BINDING_MISMATCH',
      ),
      failureCodes: decision.failureCodes,
    );
  }

  int _intValue(dynamic value) => value is num
      ? value.toInt()
      : int.tryParse(value?.toString() ?? '') ?? -1;

  DateTime? _timestampUtc(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toUtc();
    }

    return null;
  }

  bool get writesFirestore => false;
  bool get changesRolloutStage => false;
  bool get changesAgentMode => false;
  bool get enablesProviders => false;
  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;
}
