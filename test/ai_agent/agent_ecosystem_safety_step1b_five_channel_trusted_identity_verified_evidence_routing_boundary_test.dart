import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_ecosystem_channel_safety_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_ecosystem_channel_safety_request.dart';
import 'package:swat_ride/ai_agent/services/agent_ecosystem_channel_safety_policy.dart';

void main() {
  const policy = AgentEcosystemChannelSafetyPolicy();

  AgentEcosystemChannelSafetyRequest request({
    required String channel,
    String actorClaim = AgentEcosystemActorClaim.customer,
    String requestKind = AgentEcosystemRequestKind.publicInformation,
    bool trustedIdentityVerified = false,
    bool trustedSubjectMatch = false,
    bool verifiedBackendEvidence = false,
    bool permissionVerified = false,
    bool approvalVerified = false,
    bool runtimeGateVerified = false,
    bool emergencyStopActive = false,
    bool moduleEnabled = true,
  }) {
    return AgentEcosystemChannelSafetyRequest(
      channel: channel,
      actorClaim: actorClaim,
      requestKind: requestKind,
      trustedIdentityVerified: trustedIdentityVerified,
      trustedSubjectMatch: trustedSubjectMatch,
      verifiedBackendEvidence: verifiedBackendEvidence,
      permissionVerified: permissionVerified,
      approvalVerified: approvalVerified,
      runtimeGateVerified: runtimeGateVerified,
      emergencyStopActive: emergencyStopActive,
      moduleEnabled: moduleEnabled,
    );
  }

  test('exactly 5 locked ecosystem channels exist', () {
    expect(AgentEcosystemChannel.values, <String>{
      AgentEcosystemChannel.appChat,
      AgentEcosystemChannel.email,
      AgentEcosystemChannel.whatsapp,
      AgentEcosystemChannel.phone,
      AgentEcosystemChannel.voice,
    });
  });

  test('no channel transport grants Owner/Admin authority by itself', () {
    for (final channel in AgentEcosystemChannel.values) {
      expect(policy.channelTransportGrantsAuthority(channel), false);
    }
  });

  test('public App Chat response can remain safe without private identity', () {
    final decision = policy.evaluate(
      request(channel: AgentEcosystemChannel.appChat),
    );

    expect(
      decision.status,
      AgentEcosystemSafetyDecisionStatus.allowSafeResponse,
    );
    expect(decision.mayExecuteBusinessAction, false);
  });

  test('Email Owner claim requires separate trusted identity', () {
    final decision = policy.evaluate(
      request(
        channel: AgentEcosystemChannel.email,
        actorClaim: AgentEcosystemActorClaim.owner,
        requestKind: AgentEcosystemRequestKind.accountPrivateInformation,
      ),
    );

    expect(
      decision.status,
      AgentEcosystemSafetyDecisionStatus.requireTrustedIdentity,
    );
    expect(decision.reasonCode, 'email_identity_not_trusted_by_default');
    expect(decision.grantsOwnerAuthority, false);
  });

  test('WhatsApp Admin claim is not a security bypass', () {
    final decision = policy.evaluate(
      request(
        channel: AgentEcosystemChannel.whatsapp,
        actorClaim: AgentEcosystemActorClaim.admin,
        requestKind: AgentEcosystemRequestKind.consequentialAction,
      ),
    );

    expect(
      decision.status,
      AgentEcosystemSafetyDecisionStatus.requireTrustedIdentity,
    );
    expect(decision.reasonCode, 'whatsapp_identity_not_admin_authority');
    expect(decision.grantsAdminAuthority, false);
  });

  test('Phone caller identity is not authority', () {
    final decision = policy.evaluate(
      request(
        channel: AgentEcosystemChannel.phone,
        actorClaim: AgentEcosystemActorClaim.owner,
        requestKind: AgentEcosystemRequestKind.accountPrivateInformation,
      ),
    );

    expect(
      decision.status,
      AgentEcosystemSafetyDecisionStatus.requireTrustedIdentity,
    );
    expect(decision.reasonCode, 'caller_identity_not_authority');
  });

  test('Voice input is not automatic Owner authorization', () {
    final decision = policy.evaluate(
      request(
        channel: AgentEcosystemChannel.voice,
        actorClaim: AgentEcosystemActorClaim.owner,
        requestKind: AgentEcosystemRequestKind.consequentialAction,
      ),
    );

    expect(
      decision.status,
      AgentEcosystemSafetyDecisionStatus.requireTrustedIdentity,
    );
    expect(decision.reasonCode, 'voice_input_not_owner_authorization');
  });

  test('private account request requires trusted subject match', () {
    final decision = policy.evaluate(
      request(
        channel: AgentEcosystemChannel.appChat,
        requestKind: AgentEcosystemRequestKind.accountPrivateInformation,
        trustedIdentityVerified: true,
        trustedSubjectMatch: false,
      ),
    );

    expect(
      decision.status,
      AgentEcosystemSafetyDecisionStatus.blockSubjectMismatch,
    );
    expect(decision.mayMutateSourceRecord, false);
  });

  test('booking/order/payment factual answer requires verified evidence', () {
    final decision = policy.evaluate(
      request(
        channel: AgentEcosystemChannel.whatsapp,
        requestKind: AgentEcosystemRequestKind.factualBookingOrderPayment,
        trustedIdentityVerified: true,
        trustedSubjectMatch: true,
        verifiedBackendEvidence: false,
      ),
    );

    expect(
      decision.status,
      AgentEcosystemSafetyDecisionStatus.requireVerifiedEvidence,
    );
    expect(decision.verifiedEvidenceRequired, true);
    expect(decision.maySendMessage, false);
  });

  test('verified factual evidence allows safe response only', () {
    final decision = policy.evaluate(
      request(
        channel: AgentEcosystemChannel.phone,
        requestKind: AgentEcosystemRequestKind.factualBookingOrderPayment,
        trustedIdentityVerified: true,
        trustedSubjectMatch: true,
        verifiedBackendEvidence: true,
      ),
    );

    expect(
      decision.status,
      AgentEcosystemSafetyDecisionStatus.allowSafeResponse,
    );
    expect(decision.mayExecuteBusinessAction, false);
  });

  test('consequential action requires full control chain', () {
    final decision = policy.evaluate(
      request(
        channel: AgentEcosystemChannel.appChat,
        actorClaim: AgentEcosystemActorClaim.owner,
        requestKind: AgentEcosystemRequestKind.consequentialAction,
        trustedIdentityVerified: true,
        trustedSubjectMatch: true,
        permissionVerified: true,
        approvalVerified: false,
        runtimeGateVerified: true,
      ),
    );

    expect(
      decision.status,
      AgentEcosystemSafetyDecisionStatus.requireControlChain,
    );
    expect(decision.controlChainRequired, true);
    expect(decision.mayConsumeApproval, false);
  });

  test('complete control chain grants handoff eligibility, not execution', () {
    final decision = policy.evaluate(
      request(
        channel: AgentEcosystemChannel.voice,
        actorClaim: AgentEcosystemActorClaim.owner,
        requestKind: AgentEcosystemRequestKind.consequentialAction,
        trustedIdentityVerified: true,
        trustedSubjectMatch: true,
        permissionVerified: true,
        approvalVerified: true,
        runtimeGateVerified: true,
      ),
    );

    expect(
      decision.status,
      AgentEcosystemSafetyDecisionStatus.eligibleControlledHandoff,
    );
    expect(
      decision.routeTo,
      AgentEcosystemRoutingTarget.controlledExecutionHandoff,
    );
    expect(decision.mayExecuteBusinessAction, false);
    expect(decision.mayConsumeApproval, false);
    expect(decision.mayGrantPermission, false);
    expect(decision.mayOverrideRuntimeGate, false);
  });

  test(
    'Emergency Stop fails closed before identity/evidence/control routing',
    () {
      final decision = policy.evaluate(
        request(
          channel: AgentEcosystemChannel.email,
          actorClaim: AgentEcosystemActorClaim.owner,
          requestKind: AgentEcosystemRequestKind.consequentialAction,
          trustedIdentityVerified: true,
          trustedSubjectMatch: true,
          verifiedBackendEvidence: true,
          permissionVerified: true,
          approvalVerified: true,
          runtimeGateVerified: true,
          emergencyStopActive: true,
        ),
      );

      expect(
        decision.status,
        AgentEcosystemSafetyDecisionStatus.blockEmergencyStop,
      );
      expect(decision.routeTo, AgentEcosystemRoutingTarget.blocked);
    },
  );

  test('module kill switch fails closed before routing', () {
    final decision = policy.evaluate(
      request(channel: AgentEcosystemChannel.whatsapp, moduleEnabled: false),
    );

    expect(
      decision.status,
      AgentEcosystemSafetyDecisionStatus.blockModuleDisabled,
    );
    expect(decision.routeTo, AgentEcosystemRoutingTarget.blocked);
  });

  test('shared policy has zero execution or production authority', () {
    expect(policy.policyOnly, true);
    expect(policy.executesBusinessAction, false);
    expect(policy.consumesApproval, false);
    expect(policy.grantsPermission, false);
    expect(policy.overridesRuntimeGate, false);
    expect(policy.callsProvider, false);
    expect(policy.sendsMessage, false);
    expect(policy.readsFirestore, false);
    expect(policy.writesFirestore, false);
    expect(policy.activatesProduction, false);
  });
}
