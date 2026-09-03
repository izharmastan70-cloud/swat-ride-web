import '../constants/agent_cross_agent_supervisor_conflict_constants.dart';
import '../models/agent_cross_agent_supervisor_conflict_finding.dart';
import '../models/agent_cross_agent_supervisor_conflict_input.dart';
import '../models/agent_cross_agent_supervisor_work_claim.dart';

class AgentCrossAgentSupervisorConflictDetectionPolicy {
  const AgentCrossAgentSupervisorConflictDetectionPolicy();

  List<AgentCrossAgentSupervisorConflictFinding> detect(
    AgentCrossAgentSupervisorConflictInput input,
  ) {
    input.validateStructure();

    final List<AgentCrossAgentSupervisorConflictFinding> findings =
        <AgentCrossAgentSupervisorConflictFinding>[];

    for (final AgentCrossAgentSupervisorWorkClaim claim in input.claims) {
      if (!claim.roleEligible) {
        findings.add(
          AgentCrossAgentSupervisorConflictFinding(
            type: AgentCrossAgentConflictType.unauthorizedRoleWork,
            primaryClaimId: claim.claimId,
            relatedClaimId: null,
            reasonCode: 'authoritative_role_eligibility_failed',
          ),
        );
      }

      if (!claim.moduleEligible) {
        findings.add(
          AgentCrossAgentSupervisorConflictFinding(
            type: AgentCrossAgentConflictType.wrongModule,
            primaryClaimId: claim.claimId,
            relatedClaimId: null,
            reasonCode: 'authoritative_module_eligibility_failed',
          ),
        );
      }

      if (!claim.scopeEligible || !claim.authoritativeSecuritySatisfied) {
        findings.add(
          AgentCrossAgentSupervisorConflictFinding(
            type: AgentCrossAgentConflictType.wrongScope,
            primaryClaimId: claim.claimId,
            relatedClaimId: null,
            reasonCode: !claim.scopeEligible
                ? 'authoritative_scope_eligibility_failed'
                : 'authoritative_security_requirement_failed',
          ),
        );
      }

      if (!claim.active) {
        findings.add(
          AgentCrossAgentSupervisorConflictFinding(
            type: AgentCrossAgentConflictType.staleOrReplayWork,
            primaryClaimId: claim.claimId,
            relatedClaimId: null,
            reasonCode: 'non_active_task_claim_cannot_be_reexecuted',
          ),
        );
      }
    }

    for (int i = 0; i < input.claims.length; i++) {
      final AgentCrossAgentSupervisorWorkClaim a = input.claims[i];

      for (int j = i + 1; j < input.claims.length; j++) {
        final AgentCrossAgentSupervisorWorkClaim b = input.claims[j];

        final bool sameTask = a.taskId == b.taskId;
        final bool sameTarget = a.targetResourceRef == b.targetResourceRef;
        final bool sameAction = a.actionId == b.actionId;

        final bool duplicateFingerprint =
            a.workFingerprint == b.workFingerprint ||
            a.idempotencyKey == b.idempotencyKey;

        if (sameTask && sameTarget && sameAction && duplicateFingerprint) {
          findings.add(
            AgentCrossAgentSupervisorConflictFinding(
              type: AgentCrossAgentConflictType.duplicateWork,
              primaryClaimId: a.claimId,
              relatedClaimId: b.claimId,
              reasonCode: 'duplicate_or_replayed_work_fingerprint',
            ),
          );
          continue;
        }

        final bool contradictoryOutcome =
            sameTask && sameTarget && a.intendedOutcome != b.intendedOutcome;

        if (contradictoryOutcome) {
          findings.add(
            AgentCrossAgentSupervisorConflictFinding(
              type: AgentCrossAgentConflictType.conflictingOutcome,
              primaryClaimId: a.claimId,
              relatedClaimId: b.claimId,
              reasonCode: 'same_task_target_has_conflicting_outcomes',
            ),
          );
        }
      }
    }

    return List<AgentCrossAgentSupervisorConflictFinding>.unmodifiable(
      findings,
    );
  }

  bool get detectsDuplicateWork => true;
  bool get detectsStaleReplayWork => true;
  bool get detectsConflictingOutcome => true;
  bool get detectsWrongModule => true;
  bool get detectsWrongScope => true;
  bool get detectsUnauthorizedRoleWork => true;

  bool get consumesAuthoritativeEligibilityOnly => true;
  bool get computesPermissionAuthority => false;
  bool get computesApprovalAuthority => false;
  bool get computesRuntimeAuthority => false;
  bool get assignsTaskOwnership => false;

  bool get providerInvocationImplementedHere => false;
  bool get businessExecutionImplementedHere => false;
  bool get routingMutationImplementedHere => false;
  bool get securityMutationImplementedHere => false;
  bool get persistenceImplementedHere => false;
}
