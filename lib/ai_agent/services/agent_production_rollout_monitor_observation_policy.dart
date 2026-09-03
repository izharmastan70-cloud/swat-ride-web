class AgentProductionRolloutMonitorObservationDecision {
  const AgentProductionRolloutMonitorObservationDecision({
    required this.failureCodes,
  });

  final List<String> failureCodes;

  bool get stable => failureCodes.isEmpty;

  String get status =>
      stable ? 'MONITOR_ONLY_CORE_STABLE' : 'MONITOR_ONLY_CORE_UNSTABLE';
}

class AgentProductionRolloutMonitorObservationPolicy {
  const AgentProductionRolloutMonitorObservationPolicy();

  AgentProductionRolloutMonitorObservationDecision evaluate({
    required bool masterExists,
    required Map<String, dynamic> master,
    required bool rolloutExists,
    required Map<String, dynamic> rollout,
    required bool guardExists,
    required Map<String, dynamic> guard,
    required bool activationExists,
    required Map<String, dynamic> activation,
    required bool tokenExists,
    required Map<String, dynamic> token,
    required int liveRoleCount,
    required int enabledAutoRoleCount,
  }) {
    final List<String> failures = <String>[];

    final bool masterClean =
        masterExists &&
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

    if (!masterClean) {
      failures.add('MASTER_MONITOR_ONLY_TARGET_MISMATCH');
    }

    final int guardRevision = _intValue(guard['revision']);
    final int rolloutGuardRevision = _intValue(rollout['guardRevision']);
    final int activationGuardRevision = _intValue(activation['guardRevision']);
    final int tokenGuardRevision = _intValue(token['guardRevision']);

    final String activationId = _text(rollout['activationId']);

    final bool rolloutClean =
        rolloutExists &&
        rollout['stage'] == 'MONITOR_ONLY' &&
        _intValue(rollout['autoTrafficPercent']) == 0 &&
        _intValue(rollout['businessWriteTrafficPercent']) == 0 &&
        rollout['appChatOnly'] == true &&
        rollout['externalChannelsEnabled'] == false &&
        rollout['providerClass'] == 'FREE_AI_ONLY' &&
        activationId.isNotEmpty &&
        rolloutGuardRevision >= 1;

    if (!rolloutClean) {
      failures.add('ROLLOUT_MONITOR_ONLY_RECORD_MISMATCH');
    }

    final bool guardClean =
        guardExists &&
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

    if (!guardClean) {
      failures.add('RUNTIME_GUARD_MISMATCH');
    }

    final String tokenSha = _normalized(activation['armingTokenIdSha256']);

    final bool activationClean =
        activationExists &&
        activation['status'] == 'APPLIED' &&
        activation['targetStage'] == 'MONITOR_ONLY' &&
        activation['armingTokenConsumed'] == true &&
        _isSha256(tokenSha) &&
        _intValue(activation['autoTrafficPercent']) == 0 &&
        _intValue(activation['businessWriteTrafficPercent']) == 0 &&
        activation['externalChannelsEnabled'] == false;

    if (!activationClean) {
      failures.add('ACTIVATION_RECEIPT_MISMATCH');
    }

    final bool tokenClean =
        tokenExists &&
        token['status'] == 'CONSUMED' &&
        token['consumedAt'] != null &&
        _normalized(token['tokenIdSha256']) == tokenSha &&
        token['targetStage'] == 'MONITOR_ONLY' &&
        token['guardVersion'] == 'MONITOR_ONLY_GUARD_V1';

    if (!tokenClean) {
      failures.add('ARMING_TOKEN_MISMATCH');
    }

    final bool revisionClean =
        guardRevision >= 1 &&
        guardRevision == rolloutGuardRevision &&
        guardRevision == activationGuardRevision &&
        guardRevision == tokenGuardRevision;

    if (!revisionClean) {
      failures.add('GUARD_REVISION_BINDING_MISMATCH');
    }

    final int guardRoleCount = _intValue(guard['roleCount']);
    final int tokenRoleCount = _intValue(token['roleCount']);

    final bool roleCountClean =
        liveRoleCount > 0 &&
        liveRoleCount == guardRoleCount &&
        liveRoleCount == tokenRoleCount;

    if (!roleCountClean) {
      failures.add('ROLE_COUNT_BINDING_MISMATCH');
    }

    if (enabledAutoRoleCount != 0) {
      failures.add('ENABLED_AUTO_ROLE_DETECTED');
    }

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
      token['controlStateFingerprintSha256'],
    );

    final bool controlClean =
        _isSha256(rolloutControlSha) &&
        rolloutControlSha == guardControlSha &&
        rolloutControlSha == activationControlSha &&
        rolloutControlSha == tokenControlSha;

    if (!controlClean) {
      failures.add('CONTROL_STATE_BINDING_MISMATCH');
    }

    final String guardPlanSha = _normalized(guard['planFingerprintSha256']);
    final String activationPlanSha = _normalized(
      activation['planFingerprintSha256'],
    );
    final String tokenPlanSha = _normalized(token['planFingerprintSha256']);

    final bool planClean =
        _isSha256(guardPlanSha) &&
        guardPlanSha == activationPlanSha &&
        guardPlanSha == tokenPlanSha;

    if (!planClean) {
      failures.add('PLAN_BINDING_MISMATCH');
    }

    final String guardActorSha = _normalized(guard['actorReferenceSha256']);
    final String activationActorSha = _normalized(
      activation['actorReferenceSha256'],
    );
    final String tokenActorSha = _normalized(token['actorReferenceSha256']);

    final bool actorClean =
        _isSha256(guardActorSha) &&
        guardActorSha == activationActorSha &&
        guardActorSha == tokenActorSha;

    if (!actorClean) {
      failures.add('OWNER_ACTOR_BINDING_MISMATCH');
    }

    final String guardApprovalId = _text(guard['ownerApprovalId']);
    final String rolloutApprovalId = _text(rollout['ownerApprovalId']);
    final String activationApprovalId = _text(activation['ownerApprovalId']);
    final String tokenApprovalId = _text(token['ownerApprovalId']);

    final bool approvalClean =
        guardApprovalId.isNotEmpty &&
        guardApprovalId == rolloutApprovalId &&
        guardApprovalId == activationApprovalId &&
        guardApprovalId == tokenApprovalId;

    if (!approvalClean) {
      failures.add('OWNER_APPROVAL_BINDING_MISMATCH');
    }

    return AgentProductionRolloutMonitorObservationDecision(
      failureCodes: List<String>.unmodifiable(failures),
    );
  }

  int _intValue(dynamic value) => value is num
      ? value.toInt()
      : int.tryParse(value?.toString() ?? '') ?? -1;

  String _text(dynamic value) => (value ?? '').toString().trim();

  String _normalized(dynamic value) => _text(value).toLowerCase();

  bool _isSha256(String value) =>
      RegExp(r'^[a-f0-9]{64}$').hasMatch(value.toLowerCase());
}
