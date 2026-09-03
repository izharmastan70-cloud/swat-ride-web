import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_cross_agent_supervisor_resilience_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_cross_agent_supervisor_handoff_hop.dart';
import 'package:swat_ride/ai_agent/models/agent_cross_agent_supervisor_resilience_input.dart';
import 'package:swat_ride/ai_agent/services/agent_cross_agent_supervisor_failure_isolation_policy.dart';
import 'package:swat_ride/ai_agent/services/agent_cross_agent_supervisor_loop_deadlock_detection_policy.dart';
import 'package:swat_ride/ai_agent/services/agent_cross_agent_supervisor_resilience_service.dart';

void main() {
  const AgentCrossAgentSupervisorLoopDeadlockDetectionPolicy detectionPolicy =
      AgentCrossAgentSupervisorLoopDeadlockDetectionPolicy();

  const AgentCrossAgentSupervisorFailureIsolationPolicy failureIsolationPolicy =
      AgentCrossAgentSupervisorFailureIsolationPolicy();

  const AgentCrossAgentSupervisorResilienceService service =
      AgentCrossAgentSupervisorResilienceService();

  AgentCrossAgentSupervisorHandoffHop hop({
    required String id,
    required String from,
    required String to,
    required int index,
    String taskId = 'task:1',
    String progress = 'progress:1',
    String failure = 'failure:none',
  }) {
    return AgentCrossAgentSupervisorHandoffHop(
      handoffId: id,
      taskId: taskId,
      fromAgentId: from,
      toAgentId: to,
      sequenceIndex: index,
      progressMarker: progress,
      failureFingerprint: failure,
    );
  }

  AgentCrossAgentSupervisorResilienceInput input({
    List<AgentCrossAgentSupervisorHandoffHop> handoffs =
        const <AgentCrossAgentSupervisorHandoffHop>[],
    int retries = 0,
    int repeatedFailure = 0,
    int ownershipFlips = 0,
    int undoAttempts = 0,
    int noProgressCycles = 0,
    bool providerAvailable = true,
    bool supervisorHealthy = true,
    bool securitySatisfied = true,
  }) {
    return AgentCrossAgentSupervisorResilienceInput(
      requestId: 'resilience:req:1',
      taskId: 'task:1',
      handoffs: handoffs,
      retryCount: retries,
      repeatedFailureFingerprintCount: repeatedFailure,
      ownershipFlipCount: ownershipFlips,
      undoAttemptCount: undoAttempts,
      noProgressCycles: noProgressCycles,
      providerAvailable: providerAvailable,
      supervisorHealthy: supervisorHealthy,
      authoritativeSecuritySatisfied: securitySatisfied,
    );
  }

  group('Phase 60 Step 1F deadlock/loop/failure isolation/anti-fighting', () {
    test('9 resilience states are locked', () {
      expect(AgentCrossAgentSupervisorResilienceStatus.values.length, 9);
    });

    test('clean input remains clean', () {
      final result = service.assess(input());

      expect(result.status, AgentCrossAgentSupervisorResilienceStatus.clean);
      expect(result.clean, true);
      expect(result.recommendHold, false);
      expect(result.recommendStop, false);
      expect(result.coreAppContinues, true);
    });

    test('A to B to A handoff loop is detected', () {
      final value = input(
        handoffs: <AgentCrossAgentSupervisorHandoffHop>[
          hop(id: 'hop:1', from: 'agent_a', to: 'agent_b', index: 1),
          hop(id: 'hop:2', from: 'agent_b', to: 'agent_a', index: 2),
        ],
      );

      expect(detectionPolicy.hasAgentLoop(value), true);

      final result = service.assess(value);
      expect(result.status, AgentCrossAgentSupervisorResilienceStatus.holdLoop);
      expect(result.recommendHold, true);
      expect(result.escalationRecommended, true);
    });

    test('longer A-B-C-A loop is detected', () {
      final value = input(
        handoffs: <AgentCrossAgentSupervisorHandoffHop>[
          hop(id: 'hop:1', from: 'agent_a', to: 'agent_b', index: 1),
          hop(id: 'hop:2', from: 'agent_b', to: 'agent_c', index: 2),
          hop(id: 'hop:3', from: 'agent_c', to: 'agent_a', index: 3),
        ],
      );

      expect(detectionPolicy.hasAgentLoop(value), true);
    });

    test('linear A-B-C-D chain is not a loop', () {
      final value = input(
        handoffs: <AgentCrossAgentSupervisorHandoffHop>[
          hop(id: 'hop:1', from: 'agent_a', to: 'agent_b', index: 1),
          hop(id: 'hop:2', from: 'agent_b', to: 'agent_c', index: 2),
          hop(id: 'hop:3', from: 'agent_c', to: 'agent_d', index: 3),
        ],
      );

      expect(detectionPolicy.hasAgentLoop(value), false);
    });

    test('3 no-progress cycles trigger deadlock HOLD', () {
      final result = service.assess(input(noProgressCycles: 3));

      expect(
        result.status,
        AgentCrossAgentSupervisorResilienceStatus.holdDeadlock,
      );
      expect(result.recommendHold, true);
      expect(result.escalationRecommended, true);
    });

    test('8 handoffs trigger excessive-handoff deadlock', () {
      final List<AgentCrossAgentSupervisorHandoffHop> hops =
          <AgentCrossAgentSupervisorHandoffHop>[];

      for (int i = 0; i < 8; i++) {
        hops.add(
          hop(
            id: 'hop:$i',
            from: 'agent_$i',
            to: 'agent_${i + 1}',
            index: i + 1,
          ),
        );
      }

      final result = service.assess(input(handoffs: hops));

      expect(
        result.status,
        AgentCrossAgentSupervisorResilienceStatus.holdDeadlock,
      );
    });

    test('retry count 5 triggers retry storm', () {
      final result = service.assess(input(retries: 5));

      expect(
        result.status,
        AgentCrossAgentSupervisorResilienceStatus.holdRetryStorm,
      );
      expect(result.recommendHold, true);
    });

    test('same failure fingerprint repeated 3 times triggers storm', () {
      final result = service.assess(input(repeatedFailure: 3));

      expect(
        result.status,
        AgentCrossAgentSupervisorResilienceStatus.holdRetryStorm,
      );
    });

    test('below retry thresholds stays clean', () {
      final result = service.assess(input(retries: 4, repeatedFailure: 2));

      expect(result.status, AgentCrossAgentSupervisorResilienceStatus.clean);
    });

    test('3 ownership flips trigger anti-Agent-fighting STOP', () {
      final result = service.assess(input(ownershipFlips: 3));

      expect(
        result.status,
        AgentCrossAgentSupervisorResilienceStatus.stopAgentFighting,
      );
      expect(result.recommendStop, true);
      expect(result.escalationRecommended, true);
    });

    test('2 undo attempts trigger anti-Agent-fighting STOP', () {
      final result = service.assess(input(undoAttempts: 2));

      expect(
        result.status,
        AgentCrossAgentSupervisorResilienceStatus.stopAgentFighting,
      );
      expect(result.recommendStop, true);
    });

    test('Agent-fighting outranks loop HOLD', () {
      final result = service.assess(
        input(
          ownershipFlips: 3,
          handoffs: <AgentCrossAgentSupervisorHandoffHop>[
            hop(id: 'hop:1', from: 'agent_a', to: 'agent_b', index: 1),
            hop(id: 'hop:2', from: 'agent_b', to: 'agent_a', index: 2),
          ],
        ),
      );

      expect(
        result.status,
        AgentCrossAgentSupervisorResilienceStatus.stopAgentFighting,
      );
    });

    test('security failure blocks all resilience continuation', () {
      final result = service.assess(
        input(securitySatisfied: false, retries: 99, ownershipFlips: 99),
      );

      expect(
        result.status,
        AgentCrossAgentSupervisorResilienceStatus.holdSecurity,
      );
      expect(result.recommendHold, true);
      expect(result.recommendStop, false);
      expect(result.coreAppContinues, true);
    });

    test('provider failure degrades AI but core app continues', () {
      final result = service.assess(input(providerAvailable: false));

      expect(
        result.status,
        AgentCrossAgentSupervisorResilienceStatus.degradedProviderFailure,
      );
      expect(result.recommendHold, true);
      expect(result.aiCoordinationDegraded, true);
      expect(result.coreAppContinues, true);
    });

    test('Supervisor failure degrades coordination but core continues', () {
      final result = service.assess(input(supervisorHealthy: false));

      expect(
        result.status,
        AgentCrossAgentSupervisorResilienceStatus.degradedSupervisorFailure,
      );
      expect(result.recommendHold, true);
      expect(result.escalationRecommended, true);
      expect(result.aiCoordinationDegraded, true);
      expect(result.coreAppContinues, true);
    });

    test('invalid duplicate handoff IDs fail closed', () {
      final result = service.assess(
        input(
          handoffs: <AgentCrossAgentSupervisorHandoffHop>[
            hop(id: 'hop:same', from: 'agent_a', to: 'agent_b', index: 1),
            hop(id: 'hop:same', from: 'agent_b', to: 'agent_c', index: 2),
          ],
        ),
      );

      expect(
        result.status,
        AgentCrossAgentSupervisorResilienceStatus.holdInvalidMetadata,
      );
      expect(result.recommendHold, true);
      expect(result.escalationRecommended, true);
    });

    test('non-increasing handoff sequence fails closed', () {
      final result = service.assess(
        input(
          handoffs: <AgentCrossAgentSupervisorHandoffHop>[
            hop(id: 'hop:1', from: 'agent_a', to: 'agent_b', index: 2),
            hop(id: 'hop:2', from: 'agent_b', to: 'agent_c', index: 1),
          ],
        ),
      );

      expect(
        result.status,
        AgentCrossAgentSupervisorResilienceStatus.holdInvalidMetadata,
      );
    });

    test('cross-task handoff metadata fails closed', () {
      final result = service.assess(
        input(
          handoffs: <AgentCrossAgentSupervisorHandoffHop>[
            hop(
              id: 'hop:1',
              from: 'agent_a',
              to: 'agent_b',
              index: 1,
              taskId: 'task:other',
            ),
          ],
        ),
      );

      expect(
        result.status,
        AgentCrossAgentSupervisorResilienceStatus.holdInvalidMetadata,
      );
    });

    test('handoff hop is metadata-only and executes nothing', () {
      final value = hop(id: 'hop:1', from: 'agent_a', to: 'agent_b', index: 1);

      expect(value.metadataOnly, true);
      expect(value.containsRawUserMessage, false);
      expect(value.containsRawConversation, false);
      expect(value.containsPrivatePayload, false);
      expect(value.containsSecret, false);
      expect(value.executesHandoff, false);
      expect(value.mutatesTask, false);
      expect(value.mutatesOwner, false);
      expect(value.persistsHop, false);
    });

    test('resilience input grants no authority', () {
      final value = input();

      expect(value.containsRawUserMessage, false);
      expect(value.containsRawConversation, false);
      expect(value.containsPrivatePayload, false);
      expect(value.containsProviderSecret, false);
      expect(value.grantsPermission, false);
      expect(value.createsApproval, false);
      expect(value.authorizesExecution, false);
    });

    test('detector covers all loop/deadlock/storm/fighting families', () {
      expect(detectionPolicy.detectsAtoBtoALoop, true);
      expect(detectionPolicy.detectsLongerAgentRevisitLoop, true);
      expect(detectionPolicy.detectsNoProgressDeadlock, true);
      expect(detectionPolicy.detectsExcessiveHandoffDeadlock, true);
      expect(detectionPolicy.detectsRetryStorm, true);
      expect(detectionPolicy.detectsRepeatedFailureStorm, true);
      expect(detectionPolicy.detectsOwnershipFlipFighting, true);
      expect(detectionPolicy.detectsUndoAttemptFighting, true);
    });

    test('detector itself performs no rollback/task mutation', () {
      expect(detectionPolicy.executesRollbackHere, false);
      expect(detectionPolicy.mutatesTaskHere, false);
      expect(detectionPolicy.mutatesOwnerHere, false);
      expect(detectionPolicy.persistenceImplementedHere, false);
    });

    test('failure isolation keeps core app alive', () {
      expect(failureIsolationPolicy.providerFailureStopsCoreApp, false);
      expect(failureIsolationPolicy.supervisorFailureStopsCoreApp, false);
      expect(failureIsolationPolicy.conflictDetectorFailureStopsCoreApp, false);
      expect(failureIsolationPolicy.attentionLayerFailureStopsCoreApp, false);
      expect(failureIsolationPolicy.providerFailureMayHoldAiCoordination, true);
      expect(
        failureIsolationPolicy.supervisorFailureMayHoldAiCoordination,
        true,
      );
    });

    test('failure fallback can never bypass security controls', () {
      expect(failureIsolationPolicy.fallbackMayBypassSecurity, false);
      expect(failureIsolationPolicy.fallbackMayBypassPermission, false);
      expect(failureIsolationPolicy.fallbackMayBypassApproval, false);
      expect(failureIsolationPolicy.fallbackMayBypassRuntimeGate, false);
      expect(failureIsolationPolicy.fallbackMayBypassGuardianSecurity, false);
      expect(failureIsolationPolicy.fallbackMayBypassEmergencyStop, false);
      expect(failureIsolationPolicy.fallbackMayBypassCostBudget, false);
      expect(failureIsolationPolicy.fallbackMayBypassMandatoryAudit, false);
    });

    test('failure isolation cannot activate Paid/provider or budget', () {
      expect(
        failureIsolationPolicy.autoProviderActivationImplementedHere,
        false,
      );
      expect(failureIsolationPolicy.autoPaidEscalationImplementedHere, false);
      expect(failureIsolationPolicy.budgetIncreaseImplementedHere, false);
      expect(failureIsolationPolicy.securityOverrideImplementedHere, false);
      expect(failureIsolationPolicy.businessExecutionImplementedHere, false);
      expect(failureIsolationPolicy.persistenceImplementedHere, false);
    });

    test('assessment remains recommendation-only/no mutation', () {
      final result = service.assess(input());

      expect(result.recommendationOnly, true);
      expect(result.securityAuthorityAlwaysAboveSupervisor, true);
      expect(result.grantsPermission, false);
      expect(result.createsApproval, false);
      expect(result.consumesApproval, false);
      expect(result.expandsScope, false);
      expect(result.assignsPrivilegedRole, false);
      expect(result.authorizesBusinessExecution, false);
      expect(result.executesBusinessAction, false);

      expect(result.executesRollback, false);
      expect(result.switchesProvider, false);
      expect(result.mutatesQueue, false);
      expect(result.mutatesTaskOwner, false);
      expect(result.mutatesRouting, false);
      expect(result.mutatesBudget, false);
      expect(result.modifiesSecurityEngine, false);
      expect(result.persistsAssessment, false);
    });

    test('service permanent authority boundaries remain locked', () {
      expect(service.recommendationOnly, true);
      expect(service.securityAuthorityAlwaysAboveSupervisor, true);
      expect(service.detectsLoopsBeforeFurtherCoordination, true);
      expect(service.detectsDeadlockBeforeFurtherCoordination, true);
      expect(service.detectsRetryStormBeforeFurtherCoordination, true);
      expect(service.detectsAgentFightingBeforeFurtherCoordination, true);

      expect(service.providerFailureIsolatedFromCoreApp, true);
      expect(service.supervisorFailureIsolatedFromCoreApp, true);
      expect(service.coreAppAlwaysContinues, true);

      expect(service.supervisorCanGrantPermission, false);
      expect(service.supervisorCanCreateApproval, false);
      expect(service.supervisorCanExpandScope, false);
      expect(service.supervisorCanExecuteRollback, false);
      expect(service.supervisorCanSwitchProvider, false);
      expect(service.supervisorCanActivatePaidAi, false);
      expect(service.supervisorCanIncreaseBudget, false);
      expect(service.supervisorCanExecuteBusinessAction, false);
      expect(service.supervisorCanModifySecurityEngine, false);

      expect(service.queueMutationImplementedHere, false);
      expect(service.taskOwnerMutationImplementedHere, false);
      expect(service.persistenceImplementedHere, false);
    });

    test('Step 1G remains separate', () {
      expect(service.step1GFinalAdversarialSeparate, true);
    });
  });
}
