import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_ecosystem_control_chain_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_ecosystem_control_chain_request.dart';
import 'package:swat_ride/ai_agent/services/agent_ecosystem_control_chain_policy.dart';

void main() {
  const policy = AgentEcosystemControlChainPolicy();

  AgentEcosystemControlChainRequest request({
    String actorClaim = AgentEcosystemControlActor.owner,
    bool trustedIdentityVerified = true,
    bool trustedSubjectMatch = true,
    bool permissionAllowed = true,
    bool selfPermissionEscalationRequested = false,
    bool approvalRequired = true,
    bool approvalPresent = true,
    bool approvalFresh = true,
    bool approvalBindingMatch = true,
    bool selfApprovalAttempted = false,
    bool runtimeGateAllowed = true,
    bool emergencyStopActive = false,
    bool moduleEnabled = true,
  }) {
    return AgentEcosystemControlChainRequest(
      actorClaim: actorClaim,
      trustedIdentityVerified: trustedIdentityVerified,
      trustedSubjectMatch: trustedSubjectMatch,
      permissionAllowed: permissionAllowed,
      selfPermissionEscalationRequested: selfPermissionEscalationRequested,
      approvalRequired: approvalRequired,
      approvalPresent: approvalPresent,
      approvalFresh: approvalFresh,
      approvalBindingMatch: approvalBindingMatch,
      selfApprovalAttempted: selfApprovalAttempted,
      runtimeGateAllowed: runtimeGateAllowed,
      emergencyStopActive: emergencyStopActive,
      moduleEnabled: moduleEnabled,
    );
  }

  test('complete external control chain yields handoff only', () {
    final decision = policy.evaluate(request());

    expect(
      decision.status,
      AgentEcosystemControlDecisionStatus.eligibleControlledHandoff,
    );
    expect(decision.controlledHandoffOnly, true);
    expect(decision.mayExecuteBusinessAction, false);
    expect(decision.mayConsumeApproval, false);
  });

  test('Emergency Stop overrides otherwise complete chain', () {
    final decision = policy.evaluate(request(emergencyStopActive: true));

    expect(
      decision.status,
      AgentEcosystemControlDecisionStatus.blockEmergencyStop,
    );
    expect(decision.routeTo, AgentEcosystemControlRoute.blocked);
    expect(decision.failClosed, true);
  });

  test('module kill switch overrides otherwise complete chain', () {
    final decision = policy.evaluate(request(moduleEnabled: false));

    expect(
      decision.status,
      AgentEcosystemControlDecisionStatus.blockModuleDisabled,
    );
    expect(decision.failClosed, true);
  });

  test('fake Owner claim fails closed before Permission/Approval', () {
    final decision = policy.evaluate(
      request(
        actorClaim: AgentEcosystemControlActor.owner,
        trustedIdentityVerified: false,
      ),
    );

    expect(
      decision.status,
      AgentEcosystemControlDecisionStatus.blockUntrustedPrivilegedIdentity,
    );
    expect(decision.reasonCode, 'fake_or_unverified_owner_claim');
    expect(decision.mayGrantPermission, false);
  });

  test('unauthorized Admin claim fails closed', () {
    final decision = policy.evaluate(
      request(
        actorClaim: AgentEcosystemControlActor.admin,
        trustedIdentityVerified: false,
      ),
    );

    expect(
      decision.status,
      AgentEcosystemControlDecisionStatus.blockUntrustedPrivilegedIdentity,
    );
    expect(decision.reasonCode, 'unauthorized_or_unverified_admin_claim');
  });

  test('trusted subject mismatch blocks cross-subject action', () {
    final decision = policy.evaluate(request(trustedSubjectMatch: false));

    expect(
      decision.status,
      AgentEcosystemControlDecisionStatus.blockSubjectMismatch,
    );
    expect(decision.mayExecuteBusinessAction, false);
  });

  test('Permission denied fails closed', () {
    final decision = policy.evaluate(request(permissionAllowed: false));

    expect(
      decision.status,
      AgentEcosystemControlDecisionStatus.blockPermissionDenied,
    );
    expect(decision.routeTo, AgentEcosystemControlRoute.permissionGate);
  });

  test('Agent cannot self-escalate Permission', () {
    final decision = policy.evaluate(
      request(
        actorClaim: AgentEcosystemControlActor.agent,
        permissionAllowed: false,
        selfPermissionEscalationRequested: true,
      ),
    );

    expect(
      decision.status,
      AgentEcosystemControlDecisionStatus.blockSelfPermissionEscalation,
    );
    expect(decision.reasonCode, 'agent_cannot_self_grant_permission');
  });

  test('required Approval missing fails closed', () {
    final decision = policy.evaluate(request(approvalPresent: false));

    expect(
      decision.status,
      AgentEcosystemControlDecisionStatus.blockApprovalMissing,
    );
  });

  test('expired/already-consumed Approval fails closed', () {
    final decision = policy.evaluate(request(approvalFresh: false));

    expect(
      decision.status,
      AgentEcosystemControlDecisionStatus.blockApprovalExpired,
    );
    expect(decision.reasonCode, 'approval_expired_or_already_consumed');
  });

  test('Approval fingerprint/action binding mismatch blocks replay', () {
    final decision = policy.evaluate(request(approvalBindingMatch: false));

    expect(
      decision.status,
      AgentEcosystemControlDecisionStatus.blockApprovalBindingMismatch,
    );
    expect(
      decision.reasonCode,
      'approval_fingerprint_or_action_binding_mismatch',
    );
  });

  test('Agent/actor self-approval attempt fails closed', () {
    final decision = policy.evaluate(request(selfApprovalAttempted: true));

    expect(
      decision.status,
      AgentEcosystemControlDecisionStatus.blockSelfApproval,
    );
    expect(decision.reasonCode, 'self_approval_forbidden');
  });

  test('Runtime Gate deny fails closed after Permission/Approval', () {
    final decision = policy.evaluate(request(runtimeGateAllowed: false));

    expect(
      decision.status,
      AgentEcosystemControlDecisionStatus.blockRuntimeGate,
    );
    expect(decision.routeTo, AgentEcosystemControlRoute.runtimeGate);
  });

  test('non-Approval action still requires Permission + Runtime Gate', () {
    final allowed = policy.evaluate(request(approvalRequired: false));

    expect(
      allowed.status,
      AgentEcosystemControlDecisionStatus.eligibleControlledHandoff,
    );

    final denied = policy.evaluate(
      request(approvalRequired: false, permissionAllowed: false),
    );

    expect(
      denied.status,
      AgentEcosystemControlDecisionStatus.blockPermissionDenied,
    );
  });

  test('control-chain policy has zero authority of its own', () {
    expect(policy.policyOnly, true);
    expect(policy.consumesApproval, false);
    expect(policy.grantsPermission, false);
    expect(policy.overridesRuntimeGate, false);
    expect(policy.disablesEmergencyStop, false);
    expect(policy.enablesModule, false);
    expect(policy.callsProvider, false);
    expect(policy.sendsMessage, false);
    expect(policy.readsFirestore, false);
    expect(policy.writesFirestore, false);
    expect(policy.executesBusinessAction, false);
    expect(policy.activatesProduction, false);
  });
}
