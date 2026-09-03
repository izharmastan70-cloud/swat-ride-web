import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/services/agent_production_rollout_monitor_observation_policy.dart';

void main() {
  const AgentProductionRolloutMonitorObservationPolicy policy =
      AgentProductionRolloutMonitorObservationPolicy();

  const String sha =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

  Map<String, dynamic> master() => <String, dynamic>{
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
    'sourceControlStateFingerprintSha256': sha,
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
    'controlStateFingerprintSha256': sha,
    'planFingerprintSha256': sha,
    'actorReferenceSha256': sha,
    'ownerApprovalId': 'approval-1',
  };

  Map<String, dynamic> activation() => <String, dynamic>{
    'status': 'APPLIED',
    'targetStage': 'MONITOR_ONLY',
    'armingTokenConsumed': true,
    'armingTokenIdSha256': sha,
    'autoTrafficPercent': 0,
    'businessWriteTrafficPercent': 0,
    'externalChannelsEnabled': false,
    'guardRevision': 2,
    'sourceControlStateFingerprintSha256': sha,
    'planFingerprintSha256': sha,
    'actorReferenceSha256': sha,
    'ownerApprovalId': 'approval-1',
  };

  Map<String, dynamic> token() => <String, dynamic>{
    'status': 'CONSUMED',
    'consumedAt': 'server-time',
    'tokenIdSha256': sha,
    'targetStage': 'MONITOR_ONLY',
    'guardVersion': 'MONITOR_ONLY_GUARD_V1',
    'guardRevision': 2,
    'roleCount': 22,
    'controlStateFingerprintSha256': sha,
    'planFingerprintSha256': sha,
    'actorReferenceSha256': sha,
    'ownerApprovalId': 'approval-1',
  };

  AgentProductionRolloutMonitorObservationDecision evaluate({
    Map<String, dynamic>? masterOverride,
    Map<String, dynamic>? rolloutOverride,
    Map<String, dynamic>? guardOverride,
    Map<String, dynamic>? activationOverride,
    Map<String, dynamic>? tokenOverride,
    int liveRoleCount = 22,
    int enabledAutoRoleCount = 0,
  }) {
    return policy.evaluate(
      masterExists: true,
      master: masterOverride ?? master(),
      rolloutExists: true,
      rollout: rolloutOverride ?? rollout(),
      guardExists: true,
      guard: guardOverride ?? guard(),
      activationExists: true,
      activation: activationOverride ?? activation(),
      tokenExists: true,
      token: tokenOverride ?? token(),
      liveRoleCount: liveRoleCount,
      enabledAutoRoleCount: enabledAutoRoleCount,
    );
  }

  test('clean recovered MONITOR_ONLY state is stable', () {
    final decision = evaluate();

    expect(decision.stable, true);
    expect(decision.failureCodes, isEmpty);
    expect(decision.status, 'MONITOR_ONLY_CORE_STABLE');
  });

  test('Emergency Stop active is not normal stable state', () {
    final changed = master();
    changed['emergencyReadOnly'] = true;

    final decision = evaluate(masterOverride: changed);

    expect(decision.stable, false);
    expect(
      decision.failureCodes,
      contains('MASTER_MONITOR_ONLY_TARGET_MISMATCH'),
    );
  });

  test('AUTO role blocks stability', () {
    final decision = evaluate(enabledAutoRoleCount: 1);

    expect(decision.stable, false);
    expect(decision.failureCodes, contains('ENABLED_AUTO_ROLE_DETECTED'));
  });

  test('AUTO traffic above zero blocks stability', () {
    final changed = rollout();
    changed['autoTrafficPercent'] = 1;

    final decision = evaluate(rolloutOverride: changed);

    expect(decision.stable, false);
    expect(
      decision.failureCodes,
      contains('ROLLOUT_MONITOR_ONLY_RECORD_MISMATCH'),
    );
  });

  test('business-write traffic above zero blocks stability', () {
    final changed = rollout();
    changed['businessWriteTrafficPercent'] = 1;

    final decision = evaluate(rolloutOverride: changed);

    expect(decision.stable, false);
  });

  test('external channel enable blocks stability', () {
    final changed = rollout();
    changed['externalChannelsEnabled'] = true;

    final decision = evaluate(rolloutOverride: changed);

    expect(decision.stable, false);
  });

  test('paid provider enable blocks stability', () {
    final changed = master();
    changed['paidCodeAiEnabled'] = true;

    final decision = evaluate(masterOverride: changed);

    expect(decision.stable, false);
  });

  test('local provider enable blocks stability', () {
    final changed = master();
    changed['localAiEnabled'] = true;

    final decision = evaluate(masterOverride: changed);

    expect(decision.stable, false);
  });

  test('role count mismatch blocks stability', () {
    final decision = evaluate(liveRoleCount: 21);

    expect(decision.stable, false);
    expect(decision.failureCodes, contains('ROLE_COUNT_BINDING_MISMATCH'));
  });

  test('guard revision drift blocks stability', () {
    final changed = guard();
    changed['revision'] = 3;

    final decision = evaluate(guardOverride: changed);

    expect(decision.stable, false);
    expect(decision.failureCodes, contains('GUARD_REVISION_BINDING_MISMATCH'));
  });

  test('token must remain consumed', () {
    final changed = token();
    changed['status'] = 'READY';

    final decision = evaluate(tokenOverride: changed);

    expect(decision.stable, false);
    expect(decision.failureCodes, contains('ARMING_TOKEN_MISMATCH'));
  });

  test('approval binding drift blocks stability', () {
    final changed = token();
    changed['ownerApprovalId'] = 'different';

    final decision = evaluate(tokenOverride: changed);

    expect(decision.stable, false);
    expect(decision.failureCodes, contains('OWNER_APPROVAL_BINDING_MISMATCH'));
  });
}
