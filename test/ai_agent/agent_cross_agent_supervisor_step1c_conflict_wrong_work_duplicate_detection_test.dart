import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_cross_agent_supervisor_contract_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_cross_agent_supervisor_conflict_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_cross_agent_supervisor_conflict_input.dart';
import 'package:swat_ride/ai_agent/models/agent_cross_agent_supervisor_work_claim.dart';
import 'package:swat_ride/ai_agent/services/agent_cross_agent_supervisor_conflict_detection_policy.dart';
import 'package:swat_ride/ai_agent/services/agent_cross_agent_supervisor_conflict_service.dart';

void main() {
  const AgentCrossAgentSupervisorConflictDetectionPolicy policy =
      AgentCrossAgentSupervisorConflictDetectionPolicy();

  const AgentCrossAgentSupervisorConflictService service =
      AgentCrossAgentSupervisorConflictService();

  AgentCrossAgentSupervisorWorkClaim claim({
    required String claimId,
    required String agentId,
    String taskId = 'task:1',
    String agentRoleId = 'ride_agent',
    String moduleId = 'ride',
    String actionId = 'read:ride',
    String targetResourceRef = 'ride:123',
    String workFingerprint = 'fp:default',
    String idempotencyKey = 'idem:default',
    String intendedOutcome = 'outcome:read',
    String lifecycleStatus = AgentCrossAgentWorkLifecycleStatus.active,
    bool roleEligible = true,
    bool moduleEligible = true,
    bool scopeEligible = true,
    bool authoritativeSecuritySatisfied = true,
  }) {
    return AgentCrossAgentSupervisorWorkClaim(
      claimId: claimId,
      taskId: taskId,
      agentId: agentId,
      agentRoleId: agentRoleId,
      moduleId: moduleId,
      actionId: actionId,
      targetResourceRef: targetResourceRef,
      workFingerprint: workFingerprint,
      idempotencyKey: idempotencyKey,
      intendedOutcome: intendedOutcome,
      lifecycleStatus: lifecycleStatus,
      roleEligible: roleEligible,
      moduleEligible: moduleEligible,
      scopeEligible: scopeEligible,
      authoritativeSecuritySatisfied: authoritativeSecuritySatisfied,
    );
  }

  AgentCrossAgentSupervisorConflictInput input(
    List<AgentCrossAgentSupervisorWorkClaim> claims,
  ) {
    return AgentCrossAgentSupervisorConflictInput(claims: claims);
  }

  group('Phase 60 Step 1C conflict/wrong-work/duplicate detection', () {
    test('7 conflict types are locked', () {
      expect(AgentCrossAgentConflictType.values.length, 7);
    });

    test('4 lifecycle states are locked', () {
      expect(AgentCrossAgentWorkLifecycleStatus.values.length, 4);
    });

    test('clean independent work remains observe-only', () {
      final result = service.assess(
        input(<AgentCrossAgentSupervisorWorkClaim>[
          claim(
            claimId: 'claim:1',
            agentId: 'ride_agent',
            taskId: 'task:ride',
            targetResourceRef: 'ride:1',
            workFingerprint: 'fp:ride:1',
            idempotencyKey: 'idem:ride:1',
          ),
          claim(
            claimId: 'claim:2',
            agentId: 'food_agent',
            agentRoleId: 'food_agent',
            moduleId: 'food',
            taskId: 'task:food',
            actionId: 'read:food',
            targetResourceRef: 'order:1',
            workFingerprint: 'fp:food:1',
            idempotencyKey: 'idem:food:1',
            intendedOutcome: 'outcome:food:read',
          ),
        ]),
      );

      expect(
        result.status,
        AgentCrossAgentSupervisorDecisionStatus.observeOnly,
      );
      expect(result.clean, true);
      expect(result.recommendHold, false);
      expect(result.recommendStop, false);
    });

    test('duplicate work fingerprint produces HOLD', () {
      final result = service.assess(
        input(<AgentCrossAgentSupervisorWorkClaim>[
          claim(
            claimId: 'claim:1',
            agentId: 'ride_agent',
            workFingerprint: 'fp:same',
            idempotencyKey: 'idem:1',
          ),
          claim(
            claimId: 'claim:2',
            agentId: 'support_agent',
            agentRoleId: 'support_agent',
            workFingerprint: 'fp:same',
            idempotencyKey: 'idem:2',
          ),
        ]),
      );

      expect(
        result.status,
        AgentCrossAgentSupervisorDecisionStatus.recommendHold,
      );
      expect(result.recommendHold, true);
      expect(result.recommendStop, false);
      expect(
        result.findings.any(
          (finding) =>
              finding.type == AgentCrossAgentConflictType.duplicateWork,
        ),
        true,
      );
    });

    test('duplicate idempotency key produces HOLD', () {
      final result = service.assess(
        input(<AgentCrossAgentSupervisorWorkClaim>[
          claim(
            claimId: 'claim:1',
            agentId: 'ride_agent',
            workFingerprint: 'fp:1',
            idempotencyKey: 'idem:same',
          ),
          claim(
            claimId: 'claim:2',
            agentId: 'support_agent',
            agentRoleId: 'support_agent',
            workFingerprint: 'fp:2',
            idempotencyKey: 'idem:same',
          ),
        ]),
      );

      expect(result.recommendHold, true);
      expect(result.recommendStop, false);
    });

    test('same task/target contradictory outcomes => HOLD + escalation', () {
      final result = service.assess(
        input(<AgentCrossAgentSupervisorWorkClaim>[
          claim(
            claimId: 'claim:1',
            agentId: 'finance_agent',
            agentRoleId: 'finance_agent',
            actionId: 'review:refund',
            workFingerprint: 'fp:approve',
            idempotencyKey: 'idem:approve',
            intendedOutcome: 'refund:approve',
          ),
          claim(
            claimId: 'claim:2',
            agentId: 'support_agent',
            agentRoleId: 'support_agent',
            actionId: 'review:refund',
            workFingerprint: 'fp:reject',
            idempotencyKey: 'idem:reject',
            intendedOutcome: 'refund:reject',
          ),
        ]),
      );

      expect(
        result.status,
        AgentCrossAgentSupervisorDecisionStatus.recommendHoldAndEscalate,
      );
      expect(result.recommendHold, true);
      expect(result.escalateOwnerAdmin, true);
      expect(
        result.findings.any(
          (finding) =>
              finding.type == AgentCrossAgentConflictType.conflictingOutcome,
        ),
        true,
      );
    });

    test('wrong role eligibility => STOP + escalation', () {
      final result = service.assess(
        input(<AgentCrossAgentSupervisorWorkClaim>[
          claim(claimId: 'claim:1', agentId: 'food_agent', roleEligible: false),
        ]),
      );

      expect(
        result.status,
        AgentCrossAgentSupervisorDecisionStatus.recommendStopAndEscalate,
      );
      expect(result.recommendStop, true);
      expect(result.escalateOwnerAdmin, true);
    });

    test('wrong module eligibility => STOP + escalation', () {
      final result = service.assess(
        input(<AgentCrossAgentSupervisorWorkClaim>[
          claim(
            claimId: 'claim:1',
            agentId: 'ride_agent',
            moduleEligible: false,
          ),
        ]),
      );

      expect(result.recommendStop, true);
      expect(
        result.findings.any(
          (finding) => finding.type == AgentCrossAgentConflictType.wrongModule,
        ),
        true,
      );
    });

    test('wrong scope eligibility => STOP + escalation', () {
      final result = service.assess(
        input(<AgentCrossAgentSupervisorWorkClaim>[
          claim(
            claimId: 'claim:1',
            agentId: 'ride_agent',
            scopeEligible: false,
          ),
        ]),
      );

      expect(result.recommendStop, true);
      expect(
        result.findings.any(
          (finding) => finding.type == AgentCrossAgentConflictType.wrongScope,
        ),
        true,
      );
    });

    test('authoritative security failure is wrong-work STOP', () {
      final result = service.assess(
        input(<AgentCrossAgentSupervisorWorkClaim>[
          claim(
            claimId: 'claim:1',
            agentId: 'ride_agent',
            authoritativeSecuritySatisfied: false,
          ),
        ]),
      );

      expect(result.recommendStop, true);
      expect(result.escalateOwnerAdmin, true);
    });

    test('completed task replay => HOLD', () {
      final result = service.assess(
        input(<AgentCrossAgentSupervisorWorkClaim>[
          claim(
            claimId: 'claim:1',
            agentId: 'ride_agent',
            lifecycleStatus: AgentCrossAgentWorkLifecycleStatus.completed,
          ),
        ]),
      );

      expect(
        result.status,
        AgentCrossAgentSupervisorDecisionStatus.recommendHold,
      );
      expect(
        result.findings.any(
          (finding) =>
              finding.type == AgentCrossAgentConflictType.staleOrReplayWork,
        ),
        true,
      );
    });

    test('cancelled task replay => HOLD', () {
      final result = service.assess(
        input(<AgentCrossAgentSupervisorWorkClaim>[
          claim(
            claimId: 'claim:1',
            agentId: 'ride_agent',
            lifecycleStatus: AgentCrossAgentWorkLifecycleStatus.cancelled,
          ),
        ]),
      );

      expect(result.recommendHold, true);
    });

    test('expired task replay => HOLD', () {
      final result = service.assess(
        input(<AgentCrossAgentSupervisorWorkClaim>[
          claim(
            claimId: 'claim:1',
            agentId: 'ride_agent',
            lifecycleStatus: AgentCrossAgentWorkLifecycleStatus.expired,
          ),
        ]),
      );

      expect(result.recommendHold, true);
    });

    test('wrong-work outranks duplicate HOLD', () {
      final result = service.assess(
        input(<AgentCrossAgentSupervisorWorkClaim>[
          claim(
            claimId: 'claim:1',
            agentId: 'ride_agent',
            workFingerprint: 'fp:same',
            idempotencyKey: 'idem:1',
            scopeEligible: false,
          ),
          claim(
            claimId: 'claim:2',
            agentId: 'support_agent',
            agentRoleId: 'support_agent',
            workFingerprint: 'fp:same',
            idempotencyKey: 'idem:2',
          ),
        ]),
      );

      expect(result.recommendStop, true);
      expect(result.escalateOwnerAdmin, true);
    });

    test('duplicate claim IDs make input fail closed', () {
      final result = service.assess(
        input(<AgentCrossAgentSupervisorWorkClaim>[
          claim(
            claimId: 'claim:same',
            agentId: 'ride_agent',
            workFingerprint: 'fp:1',
            idempotencyKey: 'idem:1',
          ),
          claim(
            claimId: 'claim:same',
            agentId: 'support_agent',
            agentRoleId: 'support_agent',
            workFingerprint: 'fp:2',
            idempotencyKey: 'idem:2',
          ),
        ]),
      );

      expect(
        result.status,
        AgentCrossAgentSupervisorDecisionStatus.recommendHoldAndEscalate,
      );
      expect(result.recommendHold, true);
      expect(result.escalateOwnerAdmin, true);
    });

    test('claim uses metadata only and calculates no authority', () {
      final value = claim(claimId: 'claim:1', agentId: 'ride_agent');

      expect(value.containsRawUserMessage, false);
      expect(value.containsRawConversation, false);
      expect(value.containsRawPrivatePayload, false);
      expect(value.containsRawApprovalToken, false);
      expect(value.containsRawPermissionToken, false);
      expect(value.supervisorComputedRoleAuthority, false);
      expect(value.supervisorComputedScopeAuthority, false);
      expect(value.supervisorComputedSecurityAuthority, false);
      expect(value.executesBusinessAction, false);
      expect(value.mutatesTask, false);
      expect(value.persistsClaim, false);
    });

    test('policy detects required conflict families', () {
      expect(policy.detectsDuplicateWork, true);
      expect(policy.detectsStaleReplayWork, true);
      expect(policy.detectsConflictingOutcome, true);
      expect(policy.detectsWrongModule, true);
      expect(policy.detectsWrongScope, true);
      expect(policy.detectsUnauthorizedRoleWork, true);
    });

    test('policy consumes authoritative eligibility, never computes it', () {
      expect(policy.consumesAuthoritativeEligibilityOnly, true);
      expect(policy.computesPermissionAuthority, false);
      expect(policy.computesApprovalAuthority, false);
      expect(policy.computesRuntimeAuthority, false);
      expect(policy.assignsTaskOwnership, false);
    });

    test('policy adds no execution/security/write authority', () {
      expect(policy.providerInvocationImplementedHere, false);
      expect(policy.businessExecutionImplementedHere, false);
      expect(policy.routingMutationImplementedHere, false);
      expect(policy.securityMutationImplementedHere, false);
      expect(policy.persistenceImplementedHere, false);
    });

    test('assessment remains recommendation only', () {
      final result = service.assess(
        input(<AgentCrossAgentSupervisorWorkClaim>[
          claim(claimId: 'claim:1', agentId: 'ride_agent'),
        ]),
      );

      expect(result.recommendationOnly, true);
      expect(result.securityAuthorityAlwaysAboveSupervisor, true);
      expect(result.taskOwnershipAssignedHere, false);
      expect(result.grantsPermission, false);
      expect(result.createsApproval, false);
      expect(result.consumesApproval, false);
      expect(result.expandsScope, false);
      expect(result.assignsRole, false);
      expect(result.authorizesExecution, false);
      expect(result.executesBusinessAction, false);
    });

    test('assessment cannot mutate security/routing/task ownership', () {
      final result = service.assess(
        input(<AgentCrossAgentSupervisorWorkClaim>[
          claim(claimId: 'claim:1', agentId: 'ride_agent'),
        ]),
      );

      expect(result.modifiesSecurityEngine, false);
      expect(result.mutatesRouting, false);
      expect(result.mutatesTask, false);
      expect(result.mutatesTaskOwnership, false);
      expect(result.persistsAssessment, false);
    });

    test('service authority boundaries remain locked', () {
      expect(service.detectsBeforeBusinessExecution, true);
      expect(service.duplicateExecutionPreventionRecommendationOnly, true);
      expect(service.conflictResolutionAuthorityImplementedHere, false);
      expect(service.taskOwnershipAssignmentImplementedHere, false);
      expect(service.securityAuthorityAlwaysAboveSupervisor, true);

      expect(service.supervisorCanGrantPermission, false);
      expect(service.supervisorCanCreateApproval, false);
      expect(service.supervisorCanExpandScope, false);
      expect(service.supervisorCanExecuteBusinessAction, false);
      expect(service.supervisorCanModifySecurityEngine, false);
    });

    test('core app failure isolation remains required', () {
      expect(service.coreAppContinuesIfConflictDetectorFails, true);
    });

    test('later Phase 60 responsibilities remain separate', () {
      expect(service.step1DTaskOwnershipSeparate, true);
      expect(service.step1EOwnerAdminAttentionSeparate, true);
      expect(service.step1FLoopFailureIsolationSeparate, true);
      expect(service.step1GFinalAdversarialSeparate, true);
    });
  });
}
