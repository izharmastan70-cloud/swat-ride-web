import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_cross_agent_supervisor_contract_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_cross_agent_supervisor_coordination_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_cross_agent_supervisor_conflict_assessment.dart';
import 'package:swat_ride/ai_agent/models/agent_cross_agent_supervisor_conflict_finding.dart';
import 'package:swat_ride/ai_agent/models/agent_cross_agent_supervisor_coordination_request.dart';
import 'package:swat_ride/ai_agent/models/agent_cross_agent_supervisor_owner_candidate.dart';
import 'package:swat_ride/ai_agent/models/agent_cross_agent_supervisor_priority_context.dart';
import 'package:swat_ride/ai_agent/models/agent_cross_agent_supervisor_security_snapshot.dart';
import 'package:swat_ride/ai_agent/services/agent_cross_agent_supervisor_coordination_service.dart';
import 'package:swat_ride/ai_agent/services/agent_cross_agent_supervisor_priority_policy.dart';
import 'package:swat_ride/ai_agent/services/agent_cross_agent_supervisor_safe_ownership_policy.dart';

void main() {
  const AgentCrossAgentSupervisorPriorityPolicy priorityPolicy =
      AgentCrossAgentSupervisorPriorityPolicy();

  const AgentCrossAgentSupervisorSafeOwnershipPolicy ownershipPolicy =
      AgentCrossAgentSupervisorSafeOwnershipPolicy();

  const AgentCrossAgentSupervisorCoordinationService service =
      AgentCrossAgentSupervisorCoordinationService();

  AgentCrossAgentSupervisorSecuritySnapshot security({
    bool permission = true,
    bool approval = true,
    bool runtime = true,
    bool guardian = true,
    bool ownerControl = true,
    bool masterAi = true,
    bool emergencyClear = true,
    bool costBudget = true,
    bool audit = true,
    bool restricted = false,
    bool ownerAuthority = true,
  }) {
    return AgentCrossAgentSupervisorSecuritySnapshot(
      permissionDecisionRef: 'permission:1',
      approvalDecisionRef: 'approval:1',
      runtimeGateDecisionRef: 'runtime:1',
      guardianSecurityDecisionRef: 'guardian:1',
      ownerSuperAdminControlRef: 'owner:1',
      masterAiControlRef: 'master:1',
      emergencyStopDecisionRef: 'emergency:1',
      costBudgetDecisionRef: 'budget:1',
      mandatoryAuditDecisionRef: 'audit:1',
      permissionSatisfied: permission,
      approvalSatisfied: approval,
      runtimeGateSatisfied: runtime,
      guardianSecuritySatisfied: guardian,
      ownerSuperAdminControlSatisfied: ownerControl,
      masterAiControlSatisfied: masterAi,
      emergencyStopClear: emergencyClear,
      costBudgetSatisfied: costBudget,
      mandatoryAuditSatisfied: audit,
      restrictedAction: restricted,
      ownerAdminAuthorityPresent: ownerAuthority,
    );
  }

  AgentCrossAgentSupervisorConflictAssessment conflict({bool clean = true}) {
    if (clean) {
      return AgentCrossAgentSupervisorConflictAssessment(
        status: AgentCrossAgentSupervisorDecisionStatus.observeOnly,
        findings: const <AgentCrossAgentSupervisorConflictFinding>[],
        recommendHold: false,
        recommendStop: false,
        escalateOwnerAdmin: false,
        reasonCodes: const <String>['clean'],
      );
    }

    return AgentCrossAgentSupervisorConflictAssessment(
      status: AgentCrossAgentSupervisorDecisionStatus.recommendHoldAndEscalate,
      findings: const <AgentCrossAgentSupervisorConflictFinding>[
        AgentCrossAgentSupervisorConflictFinding(
          type: 'CONFLICTING_OUTCOME',
          primaryClaimId: 'claim:1',
          relatedClaimId: 'claim:2',
          reasonCode: 'conflict',
        ),
      ],
      recommendHold: true,
      recommendStop: false,
      escalateOwnerAdmin: true,
      reasonCodes: const <String>['conflict'],
    );
  }

  AgentCrossAgentSupervisorOwnerCandidate candidate({
    required String id,
    required String agentId,
    bool primary = false,
    bool enabled = true,
    bool healthy = true,
    bool roleEligible = true,
    bool moduleEligible = true,
    bool scopeEligible = true,
    bool securityEligible = true,
    String moduleId = 'ride',
    String actionId = 'read:ride',
  }) {
    return AgentCrossAgentSupervisorOwnerCandidate(
      candidateId: id,
      agentId: agentId,
      agentRoleId: agentId,
      moduleId: moduleId,
      actionId: actionId,
      enabled: enabled,
      healthy: healthy,
      authoritativeRoleEligible: roleEligible,
      authoritativeModuleEligible: moduleEligible,
      authoritativeScopeEligible: scopeEligible,
      authoritativeSecurityEligible: securityEligible,
      primaryForTask: primary,
    );
  }

  AgentCrossAgentSupervisorCoordinationRequest request({
    AgentCrossAgentSupervisorPriorityContext priority =
        const AgentCrossAgentSupervisorPriorityContext(
          trustedPriorityMetadata: true,
          emergencyOrSecurity: false,
          approvedSensitive: false,
          customerSupport: false,
          backgroundWork: false,
        ),
    AgentCrossAgentSupervisorSecuritySnapshot? securitySnapshot,
    AgentCrossAgentSupervisorConflictAssessment? conflictAssessment,
    List<AgentCrossAgentSupervisorOwnerCandidate>? candidates,
  }) {
    return AgentCrossAgentSupervisorCoordinationRequest(
      requestId: 'coord:req:1',
      taskId: 'task:1',
      moduleId: 'ride',
      actionId: 'read:ride',
      priorityContext: priority,
      securitySnapshot: securitySnapshot ?? security(),
      conflictAssessment: conflictAssessment ?? conflict(),
      ownerCandidates:
          candidates ??
          <AgentCrossAgentSupervisorOwnerCandidate>[
            candidate(id: 'candidate:1', agentId: 'ride_agent', primary: true),
          ],
    );
  }

  group('Phase 60 Step 1D ownership/priority/safe coordination', () {
    test('5 coordination priority classes are locked', () {
      expect(AgentCrossAgentCoordinationPriority.values.length, 5);
      expect(
        AgentCrossAgentCoordinationPriority.orderedHighestFirst.first,
        AgentCrossAgentCoordinationPriority.criticalEmergencySecurity,
      );
      expect(
        AgentCrossAgentCoordinationPriority.orderedHighestFirst.last,
        AgentCrossAgentCoordinationPriority.lowBackground,
      );
    });

    test('6 ownership states are locked', () {
      expect(AgentCrossAgentOwnershipStatus.values.length, 6);
    });

    test('emergency/security gets highest coordination priority', () {
      final value = priorityPolicy.classify(
        const AgentCrossAgentSupervisorPriorityContext(
          trustedPriorityMetadata: true,
          emergencyOrSecurity: true,
          approvedSensitive: true,
          customerSupport: true,
          backgroundWork: true,
        ),
      );

      expect(
        value,
        AgentCrossAgentCoordinationPriority.criticalEmergencySecurity,
      );
    });

    test('approved sensitive outranks customer support', () {
      final value = priorityPolicy.classify(
        const AgentCrossAgentSupervisorPriorityContext(
          trustedPriorityMetadata: true,
          emergencyOrSecurity: false,
          approvedSensitive: true,
          customerSupport: true,
          backgroundWork: false,
        ),
      );

      expect(value, AgentCrossAgentCoordinationPriority.highApprovedSensitive);
    });

    test('customer support outranks normal/background', () {
      final value = priorityPolicy.classify(
        const AgentCrossAgentSupervisorPriorityContext(
          trustedPriorityMetadata: true,
          emergencyOrSecurity: false,
          approvedSensitive: false,
          customerSupport: true,
          backgroundWork: true,
        ),
      );

      expect(value, AgentCrossAgentCoordinationPriority.mediumCustomerSupport);
    });

    test('normal operational used when no special flag', () {
      final value = priorityPolicy.classify(
        const AgentCrossAgentSupervisorPriorityContext(
          trustedPriorityMetadata: true,
          emergencyOrSecurity: false,
          approvedSensitive: false,
          customerSupport: false,
          backgroundWork: false,
        ),
      );

      expect(value, AgentCrossAgentCoordinationPriority.normalOperational);
    });

    test('background work gets lowest priority', () {
      final value = priorityPolicy.classify(
        const AgentCrossAgentSupervisorPriorityContext(
          trustedPriorityMetadata: true,
          emergencyOrSecurity: false,
          approvedSensitive: false,
          customerSupport: false,
          backgroundWork: true,
        ),
      );

      expect(value, AgentCrossAgentCoordinationPriority.lowBackground);
    });

    test('untrusted priority metadata is held', () {
      final result = service.coordinate(
        request(
          priority: const AgentCrossAgentSupervisorPriorityContext(
            trustedPriorityMetadata: false,
            emergencyOrSecurity: true,
            approvedSensitive: false,
            customerSupport: false,
            backgroundWork: false,
          ),
        ),
      );

      expect(
        result.status,
        AgentCrossAgentOwnershipStatus.holdUntrustedPriority,
      );
      expect(result.recommendHold, true);
      expect(result.recommendedOwnerAgentId, isNull);
    });

    test('critical priority cannot bypass Permission failure', () {
      final result = service.coordinate(
        request(
          priority: const AgentCrossAgentSupervisorPriorityContext(
            trustedPriorityMetadata: true,
            emergencyOrSecurity: true,
            approvedSensitive: false,
            customerSupport: false,
            backgroundWork: false,
          ),
          securitySnapshot: security(permission: false),
        ),
      );

      expect(result.status, AgentCrossAgentOwnershipStatus.holdSecurity);
      expect(result.recommendHold, true);
      expect(result.recommendedOwnerAgentId, isNull);
    });

    test('critical priority cannot bypass Emergency Stop', () {
      final result = service.coordinate(
        request(
          priority: const AgentCrossAgentSupervisorPriorityContext(
            trustedPriorityMetadata: true,
            emergencyOrSecurity: true,
            approvedSensitive: false,
            customerSupport: false,
            backgroundWork: false,
          ),
          securitySnapshot: security(emergencyClear: false),
        ),
      );

      expect(result.status, AgentCrossAgentOwnershipStatus.holdSecurity);
    });

    test('restricted sensitive task requires Approval/Owner authority', () {
      final result = service.coordinate(
        request(
          priority: const AgentCrossAgentSupervisorPriorityContext(
            trustedPriorityMetadata: true,
            emergencyOrSecurity: false,
            approvedSensitive: true,
            customerSupport: false,
            backgroundWork: false,
          ),
          securitySnapshot: security(
            restricted: true,
            approval: false,
            ownerAuthority: false,
          ),
        ),
      );

      expect(result.status, AgentCrossAgentOwnershipStatus.holdSecurity);
      expect(result.recommendedOwnerAgentId, isNull);
    });

    test('Step 1C conflict blocks ownership recommendation', () {
      final result = service.coordinate(
        request(conflictAssessment: conflict(clean: false)),
      );

      expect(result.status, AgentCrossAgentOwnershipStatus.holdConflict);
      expect(result.recommendHold, true);
      expect(result.escalationRecommended, true);
      expect(result.recommendedOwnerAgentId, isNull);
    });

    test('unique authoritative primary owner is recommended', () {
      final result = service.coordinate(
        request(
          candidates: <AgentCrossAgentSupervisorOwnerCandidate>[
            candidate(id: 'candidate:1', agentId: 'ride_agent', primary: true),
            candidate(id: 'candidate:2', agentId: 'support_agent'),
          ],
        ),
      );

      expect(result.status, AgentCrossAgentOwnershipStatus.ownerRecommended);
      expect(result.recommendedOwnerAgentId, 'ride_agent');
      expect(result.recommendHold, false);
    });

    test('sole eligible owner is recommended without primary flag', () {
      final result = service.coordinate(
        request(
          candidates: <AgentCrossAgentSupervisorOwnerCandidate>[
            candidate(id: 'candidate:1', agentId: 'ride_agent', primary: false),
          ],
        ),
      );

      expect(result.status, AgentCrossAgentOwnershipStatus.ownerRecommended);
      expect(result.recommendedOwnerAgentId, 'ride_agent');
    });

    test('multiple eligible owners without primary => HOLD', () {
      final result = service.coordinate(
        request(
          candidates: <AgentCrossAgentSupervisorOwnerCandidate>[
            candidate(id: 'candidate:1', agentId: 'ride_agent'),
            candidate(id: 'candidate:2', agentId: 'support_agent'),
          ],
        ),
      );

      expect(result.status, AgentCrossAgentOwnershipStatus.holdAmbiguousOwner);
      expect(result.recommendHold, true);
      expect(result.escalationRecommended, true);
      expect(result.recommendedOwnerAgentId, isNull);
    });

    test('multiple primary owners => HOLD ambiguous', () {
      final result = service.coordinate(
        request(
          candidates: <AgentCrossAgentSupervisorOwnerCandidate>[
            candidate(id: 'candidate:1', agentId: 'ride_agent', primary: true),
            candidate(
              id: 'candidate:2',
              agentId: 'support_agent',
              primary: true,
            ),
          ],
        ),
      );

      expect(result.status, AgentCrossAgentOwnershipStatus.holdAmbiguousOwner);
    });

    test('disabled candidate cannot own task', () {
      final result = service.coordinate(
        request(
          candidates: <AgentCrossAgentSupervisorOwnerCandidate>[
            candidate(
              id: 'candidate:1',
              agentId: 'ride_agent',
              primary: true,
              enabled: false,
            ),
          ],
        ),
      );

      expect(result.status, AgentCrossAgentOwnershipStatus.holdNoEligibleOwner);
    });

    test('unhealthy candidate cannot own task', () {
      final result = service.coordinate(
        request(
          candidates: <AgentCrossAgentSupervisorOwnerCandidate>[
            candidate(
              id: 'candidate:1',
              agentId: 'ride_agent',
              primary: true,
              healthy: false,
            ),
          ],
        ),
      );

      expect(result.status, AgentCrossAgentOwnershipStatus.holdNoEligibleOwner);
    });

    test('role-ineligible candidate cannot own task', () {
      final result = service.coordinate(
        request(
          candidates: <AgentCrossAgentSupervisorOwnerCandidate>[
            candidate(
              id: 'candidate:1',
              agentId: 'ride_agent',
              roleEligible: false,
            ),
          ],
        ),
      );

      expect(result.status, AgentCrossAgentOwnershipStatus.holdNoEligibleOwner);
    });

    test('scope-ineligible candidate cannot own task', () {
      final result = service.coordinate(
        request(
          candidates: <AgentCrossAgentSupervisorOwnerCandidate>[
            candidate(
              id: 'candidate:1',
              agentId: 'ride_agent',
              scopeEligible: false,
            ),
          ],
        ),
      );

      expect(result.status, AgentCrossAgentOwnershipStatus.holdNoEligibleOwner);
    });

    test('security-ineligible candidate cannot own task', () {
      final result = service.coordinate(
        request(
          candidates: <AgentCrossAgentSupervisorOwnerCandidate>[
            candidate(
              id: 'candidate:1',
              agentId: 'ride_agent',
              securityEligible: false,
            ),
          ],
        ),
      );

      expect(result.status, AgentCrossAgentOwnershipStatus.holdNoEligibleOwner);
    });

    test('candidate must exactly match task module/action', () {
      final result = service.coordinate(
        request(
          candidates: <AgentCrossAgentSupervisorOwnerCandidate>[
            candidate(
              id: 'candidate:1',
              agentId: 'food_agent',
              moduleId: 'food',
              actionId: 'read:food',
              primary: true,
            ),
          ],
        ),
      );

      expect(result.status, AgentCrossAgentOwnershipStatus.holdNoEligibleOwner);
    });

    test('candidate metadata grants no authority itself', () {
      final value = candidate(
        id: 'candidate:1',
        agentId: 'ride_agent',
        primary: true,
      );

      expect(value.supervisorGrantedEligibility, false);
      expect(value.supervisorGrantedPrimaryOwnership, false);
      expect(value.grantsPermission, false);
      expect(value.createsApproval, false);
      expect(value.expandsScope, false);
      expect(value.assignsRole, false);
      expect(value.executesBusinessAction, false);
      expect(value.mutatesTaskOwnership, false);
    });

    test('priority context cannot self-promote or bypass security', () {
      const value = AgentCrossAgentSupervisorPriorityContext(
        trustedPriorityMetadata: true,
        emergencyOrSecurity: true,
        approvedSensitive: false,
        customerSupport: false,
        backgroundWork: false,
      );

      expect(value.agentSelfPromotionAllowed, false);
      expect(value.userTextCanSetPriorityDirectly, false);
      expect(value.providerOutputCanSetPriorityDirectly, false);
      expect(value.priorityCanBypassSecurity, false);
      expect(value.priorityCanCreateApproval, false);
      expect(value.priorityCanGrantPermission, false);
    });

    test('priority policy has complete security no-bypass locks', () {
      expect(priorityPolicy.trustedMetadataRequired, true);
      expect(priorityPolicy.highestRiskPriorityWins, true);
      expect(priorityPolicy.emergencySecurityAboveApprovedSensitive, true);
      expect(priorityPolicy.approvedSensitiveAboveCustomerSupport, true);
      expect(priorityPolicy.customerSupportAboveNormalOperational, true);
      expect(priorityPolicy.normalOperationalAboveBackground, true);

      expect(priorityPolicy.agentSelfPromotionForbidden, true);
      expect(priorityPolicy.rawUserTextPriorityAuthorityForbidden, true);
      expect(priorityPolicy.providerOutputPriorityAuthorityForbidden, true);

      expect(priorityPolicy.priorityCanBypassPermission, false);
      expect(priorityPolicy.priorityCanBypassApproval, false);
      expect(priorityPolicy.priorityCanBypassRuntimeGate, false);
      expect(priorityPolicy.priorityCanBypassGuardianSecurity, false);
      expect(priorityPolicy.priorityCanBypassEmergencyStop, false);
      expect(priorityPolicy.priorityCanBypassOwnerAdminControls, false);
      expect(priorityPolicy.priorityCanBypassMasterAiControls, false);
      expect(priorityPolicy.priorityCanBypassCostBudget, false);
      expect(priorityPolicy.priorityCanBypassMandatoryAudit, false);
    });

    test('ownership policy is recommendation-only', () {
      expect(ownershipPolicy.authoritativeEligibilityRequired, true);
      expect(ownershipPolicy.exactModuleMatchRequired, true);
      expect(ownershipPolicy.exactActionMatchRequired, true);
      expect(ownershipPolicy.enabledHealthyRequired, true);
      expect(ownershipPolicy.uniquePrimaryPreferred, true);
      expect(ownershipPolicy.ambiguityFailsClosed, true);

      expect(ownershipPolicy.grantsPermission, false);
      expect(ownershipPolicy.createsApproval, false);
      expect(ownershipPolicy.expandsScope, false);
      expect(ownershipPolicy.assignsPrivilegedRole, false);
      expect(ownershipPolicy.mutatesTaskOwner, false);
      expect(ownershipPolicy.mutatesQueue, false);
      expect(ownershipPolicy.executesBusinessAction, false);
      expect(ownershipPolicy.persistenceImplementedHere, false);
    });

    test('coordination decision never mutates owner/queue/security', () {
      final result = service.coordinate(request());

      expect(result.ownerRecommendationOnly, true);
      expect(result.taskOwnerMutatedHere, false);
      expect(result.queueMutatedHere, false);
      expect(result.priorityPersistedHere, false);
      expect(result.securityAuthorityAlwaysAboveSupervisor, true);
      expect(result.priorityCanBypassSecurity, false);
      expect(result.priorityCanBypassApproval, false);
      expect(result.priorityCanBypassEmergencyStop, false);

      expect(result.grantsPermission, false);
      expect(result.createsApproval, false);
      expect(result.consumesApproval, false);
      expect(result.expandsScope, false);
      expect(result.assignsPrivilegedRole, false);
      expect(result.authorizesBusinessExecution, false);
      expect(result.executesBusinessAction, false);

      expect(result.modifiesSecurityEngine, false);
      expect(result.mutatesRouting, false);
      expect(result.mutatesProviderState, false);
      expect(result.mutatesBudget, false);
      expect(result.persistsDecision, false);
    });

    test('service permanent authority boundaries remain locked', () {
      expect(service.ownerRecommendationOnly, true);
      expect(service.taskOwnerMutationImplementedHere, false);
      expect(service.queueMutationImplementedHere, false);
      expect(service.priorityMutationImplementedHere, false);
      expect(service.securityAuthorityAlwaysAboveSupervisor, true);
      expect(service.priorityCanNeverBypassSecurity, true);
      expect(service.conflictMustBeClearBeforeOwnership, true);
      expect(service.authoritativeEligibilityRequired, true);

      expect(service.supervisorCanGrantPermission, false);
      expect(service.supervisorCanCreateApproval, false);
      expect(service.supervisorCanExpandScope, false);
      expect(service.supervisorCanAssignPrivilegedRole, false);
      expect(service.supervisorCanExecuteBusinessAction, false);
      expect(service.supervisorCanModifySecurityEngine, false);
    });

    test('core app failure isolation remains required', () {
      expect(service.coreAppContinuesIfCoordinationFails, true);
    });

    test('later Phase 60 ownership remains separate', () {
      expect(service.step1EOwnerAdminAttentionSeparate, true);
      expect(service.step1FLoopFailureIsolationSeparate, true);
      expect(service.step1GFinalAdversarialSeparate, true);
    });
  });
}
