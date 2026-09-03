import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/services/agent_production_rollout_monitor_recovery_policy.dart';

void main() {
  const AgentProductionRolloutMonitorRecoveryPolicy policy =
      AgentProductionRolloutMonitorRecoveryPolicy();

  const String shaA =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

  Map<String, dynamic> master({bool emergency = true}) => <String, dynamic>{
    'masterEnabled': true,
    'emergencyReadOnly': emergency,
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
  };

  Map<String, dynamic> rollout() => <String, dynamic>{
    'stage': 'MONITOR_ONLY',
    'autoTrafficPercent': 0,
    'businessWriteTrafficPercent': 0,
    'appChatOnly': true,
    'externalChannelsEnabled': false,
    'providerClass': 'FREE_AI_ONLY',
    'activationId': 'activation-1',
    'guardRevision': 2,
    'sourceControlStateFingerprintSha256': shaA,
    'ownerApprovalId': 'approval-1',
  };

  Map<String, dynamic> guard() => <String, dynamic>{
    'enabled': true,
    'guardVersion': 'MONITOR_ONLY_GUARD_V1',
    'revision': 2,
    'targetStage': 'MONITOR_ONLY',
    'runtimeMonitorOnlyOverlayEnforced': true,
    'noAutoBusinessWriteBoundaryEnforced': true,
    'appChatOnly': true,
    'autoTrafficPercent': 0,
    'businessWriteTrafficPercent': 0,
    'externalChannelsEnabled': false,
    'roleCount': 22,
    'controlStateFingerprintSha256': shaA,
    'planFingerprintSha256': shaA,
    'actorReferenceSha256': shaA,
    'ownerApprovalId': 'approval-1',
  };

  Map<String, dynamic> activation() => <String, dynamic>{
    'status': 'APPLIED',
    'targetStage': 'MONITOR_ONLY',
    'armingTokenConsumed': true,
    'armingTokenIdSha256': shaA,
    'autoTrafficPercent': 0,
    'businessWriteTrafficPercent': 0,
    'externalChannelsEnabled': false,
    'guardRevision': 2,
    'sourceControlStateFingerprintSha256': shaA,
    'planFingerprintSha256': shaA,
    'actorReferenceSha256': shaA,
    'ownerApprovalId': 'approval-1',
  };

  Map<String, dynamic> token() => <String, dynamic>{
    'status': 'CONSUMED',
    'consumedAt': 'server-timestamp',
    'tokenIdSha256': shaA,
    'targetStage': 'MONITOR_ONLY',
    'guardVersion': 'MONITOR_ONLY_GUARD_V1',
    'guardRevision': 2,
    'roleCount': 22,
    'controlStateFingerprintSha256': shaA,
    'planFingerprintSha256': shaA,
    'actorReferenceSha256': shaA,
    'ownerApprovalId': 'approval-1',
  };

  AgentProductionRolloutMonitorRecoveryDecision evaluate({
    bool emergency = true,
    bool enabledAuto = false,
    int liveRoles = 22,
    String actorSha = shaA,
    String? expectedRoleSha,
    String? liveRoleSha,
    Map<String, dynamic>? masterOverride,
    Map<String, dynamic>? rolloutOverride,
    Map<String, dynamic>? guardOverride,
    Map<String, dynamic>? activationOverride,
    Map<String, dynamic>? tokenOverride,
  }) {
    return policy.evaluate(
      master: masterOverride ?? master(emergency: emergency),
      masterExists: true,
      rollout: rolloutOverride ?? rollout(),
      rolloutExists: true,
      guard: guardOverride ?? guard(),
      guardExists: true,
      activation: activationOverride ?? activation(),
      activationExists: true,
      armingToken: tokenOverride ?? token(),
      armingTokenExists: true,
      liveRoleCount: liveRoles,
      enabledAutoRole: enabledAuto,
      currentActorSha256: actorSha,
      expectEmergencyReadOnly: emergency,
      expectedRoleProjectionSha256: expectedRoleSha,
      liveRoleProjectionSha256: liveRoleSha,
    );
  }

  test('clean emergency-active MONITOR_ONLY recovery precheck passes', () {
    final decision = evaluate();

    expect(decision.safe, true);
    expect(decision.failureCodes, isEmpty);
  });

  test('clean post-release MONITOR_ONLY target passes', () {
    final decision = evaluate(emergency: false);

    expect(decision.safe, true);
  });

  test('master drift fails closed', () {
    final changed = master();
    changed['freeAiEnabled'] = false;

    final decision = evaluate(masterOverride: changed);

    expect(decision.safe, false);
    expect(decision.failureCodes, contains('MASTER_TARGET_MISMATCH'));
  });

  test('enabled AUTO role blocks recovery', () {
    final decision = evaluate(enabledAuto: true);

    expect(decision.safe, false);
    expect(decision.failureCodes, contains('ENABLED_AUTO_ROLE_DETECTED'));
  });

  test('role count mismatch blocks recovery', () {
    final decision = evaluate(liveRoles: 21);

    expect(decision.safe, false);
    expect(decision.failureCodes, contains('ROLE_COUNT_BINDING_MISMATCH'));
  });

  test('current Owner actor must match immutable actor binding', () {
    const String otherSha =
        'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

    final decision = evaluate(actorSha: otherSha);

    expect(decision.safe, false);
    expect(decision.failureCodes, contains('OWNER_ACTOR_BINDING_MISMATCH'));
  });

  test('guard revision mismatch blocks recovery', () {
    final changed = guard();
    changed['revision'] = 3;

    final decision = evaluate(guardOverride: changed);

    expect(decision.safe, false);
    expect(decision.failureCodes, contains('GUARD_REVISION_BINDING_MISMATCH'));
  });

  test('unconsumed token blocks recovery', () {
    final changed = token();
    changed['status'] = 'READY';

    final decision = evaluate(tokenOverride: changed);

    expect(decision.safe, false);
    expect(decision.failureCodes, contains('ARMING_TOKEN_MISMATCH'));
  });

  test('external rollout channel blocks recovery', () {
    final changed = rollout();
    changed['externalChannelsEnabled'] = true;

    final decision = evaluate(rolloutOverride: changed);

    expect(decision.safe, false);
    expect(decision.failureCodes, contains('ROLLOUT_RECORD_MISMATCH'));
  });

  test('role projection drift between prepare and release blocks', () {
    const String expected =
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';

    const String changed =
        'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd';

    final decision = evaluate(expectedRoleSha: expected, liveRoleSha: changed);

    expect(decision.safe, false);
    expect(decision.failureCodes, contains('ROLE_PROJECTION_CHANGED'));
  });

  test('same role projection remains clean', () {
    const String roleSha =
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';

    final decision = evaluate(expectedRoleSha: roleSha, liveRoleSha: roleSha);

    expect(decision.safe, true);
  });
}
