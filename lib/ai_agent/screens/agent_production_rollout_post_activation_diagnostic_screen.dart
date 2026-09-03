import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AgentProductionRolloutPostActivationDiagnosticScreen
    extends StatefulWidget {
  const AgentProductionRolloutPostActivationDiagnosticScreen({
    super.key,
    required this.currentAdminId,
  });

  final String currentAdminId;

  @override
  State<AgentProductionRolloutPostActivationDiagnosticScreen> createState() =>
      _AgentProductionRolloutPostActivationDiagnosticScreenState();
}

class _AgentProductionRolloutPostActivationDiagnosticScreenState
    extends State<AgentProductionRolloutPostActivationDiagnosticScreen> {
  bool _working = false;
  String _summary =
      'Emergency Stop must remain active. Run this read-only diagnostic once.';
  List<_DiagnosticCheck> _checks = const <_DiagnosticCheck>[];

  Future<void> _runReadOnlyDiagnostic() async {
    if (_working) return;

    setState(() {
      _working = true;
      _summary = 'Reading current Phase 66 production records...';
      _checks = const <_DiagnosticCheck>[];
    });

    try {
      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw StateError('Firebase Super Admin sign-in required.');
      }

      final IdTokenResult tokenResult = await user.getIdTokenResult(true);

      final Map<String, dynamic> claims =
          tokenResult.claims ?? <String, dynamic>{};

      final String role = claims['role']?.toString().trim().toLowerCase() ?? '';

      if (user.uid != widget.currentAdminId.trim() || role != 'super_admin') {
        throw StateError(
          'Read-only diagnostic requires the verified Firebase '
          'super_admin account.',
        );
      }

      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      final DocumentSnapshot<Map<String, dynamic>> masterSnapshot =
          await firestore.collection('agent_settings').doc('master').get();

      final DocumentSnapshot<Map<String, dynamic>> rolloutSnapshot =
          await firestore
              .collection('agent_settings')
              .doc('production_rollout')
              .get();

      final DocumentSnapshot<Map<String, dynamic>> guardSnapshot =
          await firestore
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
        activationSnapshot = await firestore
            .collection('agent_production_rollout_activations')
            .doc(activationId)
            .get();
      }

      final Map<String, dynamic> activation =
          activationSnapshot?.data() ?? <String, dynamic>{};

      final String tokenSha = (activation['armingTokenIdSha256'] ?? '')
          .toString()
          .trim()
          .toLowerCase();

      DocumentSnapshot<Map<String, dynamic>>? armingTokenSnapshot;

      if (_isSha256(tokenSha)) {
        armingTokenSnapshot = await firestore
            .collection('agent_production_rollout_arming_tokens')
            .doc(tokenSha)
            .get();
      }

      final Map<String, dynamic> armingToken =
          armingTokenSnapshot?.data() ?? <String, dynamic>{};

      final QuerySnapshot<Map<String, dynamic>> rolesSnapshot = await firestore
          .collection('agent_roles')
          .get();

      final List<QueryDocumentSnapshot<Map<String, dynamic>>> roleDocs =
          rolesSnapshot.docs;

      final int roleCount = roleDocs.length;

      final bool enabledAutoRole = roleDocs.any((
        QueryDocumentSnapshot<Map<String, dynamic>> doc,
      ) {
        final Map<String, dynamic> data = doc.data();
        return data['enabled'] == true &&
            data['mode']?.toString().trim() == 'AUTO';
      });

      final int guardRevision = (guard['revision'] as num?)?.toInt() ?? 0;

      final int rolloutGuardRevision =
          (rollout['guardRevision'] as num?)?.toInt() ?? 0;

      final int activationGuardRevision =
          (activation['guardRevision'] as num?)?.toInt() ?? 0;

      final int tokenGuardRevision =
          (armingToken['guardRevision'] as num?)?.toInt() ?? 0;

      final int guardRoleCount = (guard['roleCount'] as num?)?.toInt() ?? 0;

      final int tokenRoleCount =
          (armingToken['roleCount'] as num?)?.toInt() ?? 0;

      final String rolloutControlSha = _normalized(
        rollout['sourceControlStateFingerprintSha256'],
      );

      final String guardControlSha = _normalized(
        guard['controlStateFingerprintSha256'],
      );

      final String activationControlSha = _normalized(
        activation['sourceControlStateFingerprintSha256'],
      );

      final String tokenControlSha = _normalized(
        armingToken['controlStateFingerprintSha256'],
      );

      final String guardPlanSha = _normalized(guard['planFingerprintSha256']);

      final String activationPlanSha = _normalized(
        activation['planFingerprintSha256'],
      );

      final String tokenPlanSha = _normalized(
        armingToken['planFingerprintSha256'],
      );

      final String guardActorSha = _normalized(guard['actorReferenceSha256']);

      final String activationActorSha = _normalized(
        activation['actorReferenceSha256'],
      );

      final String tokenActorSha = _normalized(
        armingToken['actorReferenceSha256'],
      );

      final String guardApprovalId = (guard['ownerApprovalId'] ?? '')
          .toString()
          .trim();

      final String rolloutApprovalId = (rollout['ownerApprovalId'] ?? '')
          .toString()
          .trim();

      final String activationApprovalId = (activation['ownerApprovalId'] ?? '')
          .toString()
          .trim();

      final String tokenApprovalId = (armingToken['ownerApprovalId'] ?? '')
          .toString()
          .trim();

      final bool emergencyReadOnlyActive = master['emergencyReadOnly'] == true;

      final bool currentMasterMatchesMonitorTarget =
          master['masterEnabled'] == true &&
          master['emergencyReadOnly'] == false &&
          master['freeAiEnabled'] == true &&
          master['localAiEnabled'] == false &&
          master['paidCodeAiEnabled'] == false &&
          master['paidReasoningEnabled'] == false &&
          master['callAgentEnabled'] == false &&
          master['emailAgentEnabled'] == false &&
          master['customerWhatsAppAgentEnabled'] == false &&
          master['ownerWhatsAppAgentEnabled'] == false &&
          master['emergencyWhatsAppAgentEnabled'] == false &&
          master['approvalEngineEnabled'] == true &&
          master['auditLoggingEnabled'] == true &&
          master['askBeforePaid'] == true;

      final bool rolloutClean =
          rolloutSnapshot.exists &&
          rollout['stage'] == 'MONITOR_ONLY' &&
          _intValue(rollout['autoTrafficPercent']) == 0 &&
          _intValue(rollout['businessWriteTrafficPercent']) == 0 &&
          rollout['appChatOnly'] == true &&
          rollout['externalChannelsEnabled'] == false &&
          rollout['providerClass'] == 'FREE_AI_ONLY' &&
          activationId.isNotEmpty &&
          rolloutGuardRevision >= 1;

      final bool guardClean =
          guardSnapshot.exists &&
          guard['enabled'] == true &&
          guard['guardVersion'] == 'MONITOR_ONLY_GUARD_V1' &&
          guardRevision >= 1 &&
          guard['targetStage'] == 'MONITOR_ONLY' &&
          guard['runtimeMonitorOnlyOverlayEnforced'] == true &&
          guard['noAutoBusinessWriteBoundaryEnforced'] == true &&
          guard['appChatOnly'] == true &&
          _intValue(guard['autoTrafficPercent']) == 0 &&
          _intValue(guard['businessWriteTrafficPercent']) == 0 &&
          guard['externalChannelsEnabled'] == false;

      final bool activationClean =
          activationSnapshot?.exists == true &&
          activation['status'] == 'APPLIED' &&
          activation['targetStage'] == 'MONITOR_ONLY' &&
          activation['armingTokenConsumed'] == true &&
          _isSha256(tokenSha) &&
          _intValue(activation['autoTrafficPercent']) == 0 &&
          _intValue(activation['businessWriteTrafficPercent']) == 0 &&
          activation['externalChannelsEnabled'] == false;

      final bool tokenClean =
          armingTokenSnapshot?.exists == true &&
          armingToken['status'] == 'CONSUMED' &&
          armingToken['consumedAt'] != null &&
          _normalized(armingToken['tokenIdSha256']) == tokenSha &&
          armingToken['targetStage'] == 'MONITOR_ONLY' &&
          armingToken['guardVersion'] == 'MONITOR_ONLY_GUARD_V1';

      final bool revisionBindingClean =
          guardRevision >= 1 &&
          guardRevision == rolloutGuardRevision &&
          guardRevision == activationGuardRevision &&
          guardRevision == tokenGuardRevision;

      final bool roleCountBindingClean =
          roleCount > 0 &&
          roleCount == guardRoleCount &&
          roleCount == tokenRoleCount;

      final bool controlBindingClean =
          _isSha256(rolloutControlSha) &&
          rolloutControlSha == guardControlSha &&
          rolloutControlSha == activationControlSha &&
          rolloutControlSha == tokenControlSha;

      final bool planBindingClean =
          _isSha256(guardPlanSha) &&
          guardPlanSha == activationPlanSha &&
          guardPlanSha == tokenPlanSha;

      final bool actorBindingClean =
          _isSha256(guardActorSha) &&
          guardActorSha == activationActorSha &&
          guardActorSha == tokenActorSha;

      final bool approvalBindingClean =
          guardApprovalId.isNotEmpty &&
          guardApprovalId == rolloutApprovalId &&
          guardApprovalId == activationApprovalId &&
          guardApprovalId == tokenApprovalId;

      final bool rolesSafe = roleCount > 0 && !enabledAutoRole;

      final bool immutableActivationArtifactsClean =
          rolloutClean &&
          guardClean &&
          activationClean &&
          tokenClean &&
          revisionBindingClean &&
          roleCountBindingClean &&
          controlBindingClean &&
          planBindingClean &&
          actorBindingClean &&
          approvalBindingClean &&
          rolesSafe;

      final Timestamp? masterUpdatedAt = master['updatedAt'] is Timestamp
          ? master['updatedAt'] as Timestamp
          : null;

      final Timestamp? rolloutActivatedAt = rollout['activatedAt'] is Timestamp
          ? rollout['activatedAt'] as Timestamp
          : null;

      final bool masterChangedAfterActivation =
          masterUpdatedAt != null &&
          rolloutActivatedAt != null &&
          masterUpdatedAt.toDate().isAfter(rolloutActivatedAt.toDate());

      final List<_DiagnosticCheck> checks = <_DiagnosticCheck>[
        _DiagnosticCheck(
          label: 'Verified Firebase Super Admin',
          passed: true,
          detail: 'Custom claim role=super_admin; UID matches this screen.',
        ),
        _DiagnosticCheck(
          label: 'Master document exists',
          passed: masterSnapshot.exists,
          detail: masterSnapshot.exists
              ? 'agent_settings/master present.'
              : 'Missing master document.',
        ),
        _DiagnosticCheck(
          label: 'Emergency Stop / read-only is active',
          passed: emergencyReadOnlyActive,
          detail: emergencyReadOnlyActive
              ? 'Fail-closed emergency freeze is active. Keep it active.'
              : 'Emergency read-only is NOT active.',
        ),
        _DiagnosticCheck(
          label: 'Current master equals active MONITOR_ONLY target',
          passed: currentMasterMatchesMonitorTarget,
          informational: true,
          detail: emergencyReadOnlyActive
              ? 'Expected to be false after Emergency Stop changed the master.'
              : 'This is the old immediate post-activation master check.',
        ),
        _DiagnosticCheck(
          label: 'Master changed after rollout activation',
          passed: masterChangedAfterActivation,
          informational: true,
          detail: masterChangedAfterActivation
              ? 'Master updatedAt is later than rollout activatedAt; this is '
                    'consistent with the later Emergency Stop.'
              : 'Timestamp evidence did not prove a later master change.',
        ),
        _DiagnosticCheck(
          label: 'Rollout MONITOR_ONLY record',
          passed: rolloutClean,
          detail:
              'stage=${rollout['stage'] ?? '(missing)'}, '
              'AUTO=${rollout['autoTrafficPercent'] ?? '(missing)'}, '
              'business=${rollout['businessWriteTrafficPercent'] ?? '(missing)'}, '
              'external=${rollout['externalChannelsEnabled'] ?? '(missing)'}.',
        ),
        _DiagnosticCheck(
          label: 'Runtime guard',
          passed: guardClean,
          detail:
              'revision=$guardRevision, '
              'version=${guard['guardVersion'] ?? '(missing)'}.',
        ),
        _DiagnosticCheck(
          label: 'Activation receipt',
          passed: activationClean,
          detail:
              'id=${_short(activationId)}, '
              'status=${activation['status'] ?? '(missing)'}.',
        ),
        _DiagnosticCheck(
          label: 'One-time arming token consumed',
          passed: tokenClean,
          detail:
              'token=${_short(tokenSha)}, '
              'status=${armingToken['status'] ?? '(missing)'}.',
        ),
        _DiagnosticCheck(
          label: 'Guard revision exact binding',
          passed: revisionBindingClean,
          detail:
              'guard=$guardRevision rollout=$rolloutGuardRevision '
              'activation=$activationGuardRevision token=$tokenGuardRevision.',
        ),
        _DiagnosticCheck(
          label: 'Role count exact binding',
          passed: roleCountBindingClean,
          detail:
              'live=$roleCount guard=$guardRoleCount token=$tokenRoleCount.',
        ),
        _DiagnosticCheck(
          label: 'No enabled AUTO role',
          passed: !enabledAutoRole,
          detail: enabledAutoRole
              ? 'At least one enabled AUTO role exists.'
              : 'Enabled AUTO roles: 0.',
        ),
        _DiagnosticCheck(
          label: 'Control-state SHA binding',
          passed: controlBindingClean,
          detail:
              'rollout=${_short(rolloutControlSha)} '
              'guard=${_short(guardControlSha)} '
              'activation=${_short(activationControlSha)} '
              'token=${_short(tokenControlSha)}.',
        ),
        _DiagnosticCheck(
          label: 'Plan SHA binding',
          passed: planBindingClean,
          detail:
              'guard=${_short(guardPlanSha)} '
              'activation=${_short(activationPlanSha)} '
              'token=${_short(tokenPlanSha)}.',
        ),
        _DiagnosticCheck(
          label: 'Owner actor SHA binding',
          passed: actorBindingClean,
          detail:
              'guard=${_short(guardActorSha)} '
              'activation=${_short(activationActorSha)} '
              'token=${_short(tokenActorSha)}.',
        ),
        _DiagnosticCheck(
          label: 'Owner approval binding',
          passed: approvalBindingClean,
          detail: approvalBindingClean
              ? 'Guard, rollout, activation and token approval IDs match.'
              : 'Approval binding mismatch detected.',
        ),
      ];

      final String summary;

      if (!emergencyReadOnlyActive) {
        summary =
            'CRITICAL: Emergency Stop is not active. Do not continue rollout.';
      } else if (!immutableActivationArtifactsClean) {
        summary =
            'READ-ONLY DIAGNOSTIC FOUND A PERSISTED MISMATCH. '
            'Keep Emergency Stop active and send this screen to ChatGPT.';
      } else {
        summary =
            'Immutable MONITOR_ONLY activation artifacts are clean and '
            'AUTO/business writes remain 0%. Emergency Stop changed the '
            'master afterward, so the original immediate verifier failure '
            'cannot be reconstructed from the current master alone. '
            'Keep Emergency Stop active until the verifier is repaired.';
      }

      if (!mounted) return;

      setState(() {
        _checks = List<_DiagnosticCheck>.unmodifiable(checks);
        _summary = summary;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _checks = const <_DiagnosticCheck>[];
        _summary = 'Diagnostic blocked safely: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _working = false;
        });
      }
    }
  }

  int _intValue(dynamic value) {
    return value is num
        ? value.toInt()
        : int.tryParse(value?.toString() ?? '') ?? -999999;
  }

  String _normalized(dynamic value) {
    return (value ?? '').toString().trim().toLowerCase();
  }

  bool _isSha256(String value) {
    return RegExp(r'^[a-f0-9]{64}$').hasMatch(value.trim().toLowerCase());
  }

  String _short(String value) {
    final String clean = value.trim();
    if (clean.isEmpty) return '(missing)';
    if (clean.length <= 16) return clean;
    return '${clean.substring(0, 8)}...${clean.substring(clean.length - 8)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(title: const Text('Rollout Read-Only Diagnostic')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF4A1010),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'EMERGENCY STOP MUST REMAIN ACTIVE',
                  style: TextStyle(
                    color: Color(0xFFFF6B6B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'This screen is diagnostic only. It does not release '
                  'Emergency Stop, activate rollout, change Agent Modes, '
                  'write Firestore, consume approvals or call AI providers.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _working ? null : _runReadOnlyDiagnostic,
            icon: const Icon(Icons.fact_check_outlined),
            label: Text(
              _working
                  ? 'READING...'
                  : 'RUN READ-ONLY POST-ACTIVATION DIAGNOSTIC',
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _summary,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          ..._checks.map(
            (_DiagnosticCheck check) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: check.informational
                      ? const Color(0xFFE4C75A)
                      : check.passed
                      ? const Color(0xFF55D69E)
                      : const Color(0xFFFF6B6B),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    check.informational
                        ? Icons.info_outline
                        : check.passed
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          check.label,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(check.detail),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagnosticCheck {
  const _DiagnosticCheck({
    required this.label,
    required this.passed,
    required this.detail,
    this.informational = false,
  });

  final String label;
  final bool passed;
  final String detail;
  final bool informational;
}
