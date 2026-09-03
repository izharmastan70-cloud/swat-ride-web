import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_cross_agent_supervisor_closeout_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_cross_agent_supervisor_adversarial_scenario.dart';
import 'package:swat_ride/ai_agent/models/agent_cross_agent_supervisor_readiness_input.dart';
import 'package:swat_ride/ai_agent/services/agent_cross_agent_supervisor_adversarial_gate.dart';
import 'package:swat_ride/ai_agent/services/agent_cross_agent_supervisor_final_readiness_service.dart';

void main() {
  const AgentCrossAgentSupervisorAdversarialGate gate =
      AgentCrossAgentSupervisorAdversarialGate();

  const AgentCrossAgentSupervisorFinalReadinessService service =
      AgentCrossAgentSupervisorFinalReadinessService();

  AgentCrossAgentSupervisorAdversarialScenario safeScenario(String id) {
    return AgentCrossAgentSupervisorAdversarialScenario(
      scenarioId: id,
      attempted: true,
      failClosed: true,
      securityAuthorityPreserved: true,
      coreAppContinues: true,
    );
  }

  List<AgentCrossAgentSupervisorAdversarialScenario> allSafeScenarios() {
    return AgentCrossAgentSupervisorAdversarialScenarioId.values
        .map(safeScenario)
        .toList(growable: false);
  }

  AgentCrossAgentSupervisorReadinessInput input({
    bool securityContractReady = true,
    bool conflictDetectionReady = true,
    bool safeCoordinationReady = true,
    bool ownerAdminAttentionReady = true,
    bool resilienceReady = true,
    bool securityAbove = true,
    bool neverSuperAdmin = true,
    bool noPermissionApproval = true,
    bool noBusinessExecution = true,
    bool noSecurityMutation = true,
    bool coreIsolation = true,
    List<AgentCrossAgentSupervisorAdversarialScenario>? scenarios,
  }) {
    return AgentCrossAgentSupervisorReadinessInput(
      readinessId: 'phase60:closeout:1',
      securityContractReady: securityContractReady,
      conflictDetectionReady: conflictDetectionReady,
      safeCoordinationReady: safeCoordinationReady,
      ownerAdminAttentionReady: ownerAdminAttentionReady,
      resilienceReady: resilienceReady,
      securityAuthorityAlwaysAboveSupervisor: securityAbove,
      supervisorNeverSuperAdmin: neverSuperAdmin,
      noPermissionOrApprovalAuthority: noPermissionApproval,
      noBusinessExecutionAuthority: noBusinessExecution,
      noSecurityMutationAuthority: noSecurityMutation,
      coreFailureIsolationReady: coreIsolation,
      adversarialScenarios: scenarios ?? allSafeScenarios(),
    );
  }

  group('Phase 60 Step 1G final readiness/adversarial closeout', () {
    test('4 closeout states are locked', () {
      expect(AgentCrossAgentSupervisorCloseoutStatus.values.length, 4);
    });

    test('19 adversarial scenario IDs are locked', () {
      expect(AgentCrossAgentSupervisorAdversarialScenarioId.values.length, 19);
    });

    test('all clean foundation/adversarial evidence => ready', () {
      final report = service.evaluate(input());

      expect(report.ready, true);
      expect(report.foundationReady, true);
      expect(report.adversarialReady, true);
      expect(report.coreFailureIsolationReady, true);
      expect(report.failedScenarioIds, isEmpty);
      expect(
        report.status,
        AgentCrossAgentSupervisorCloseoutStatus.readyNotProductionActive,
      );
    });

    test('readiness is explicitly NOT production activation', () {
      final report = service.evaluate(input());

      expect(report.foundationReadyNotProductionActive, true);
      expect(report.productionActive, false);
      expect(report.productionActivationImplementedHere, false);
      expect(service.foundationReadyNotProductionActive, true);
      expect(service.productionSupervisorActivationImplementedHere, false);
    });

    test('missing security contract fails closed', () {
      final report = service.evaluate(input(securityContractReady: false));

      expect(report.ready, false);
      expect(
        report.status,
        AgentCrossAgentSupervisorCloseoutStatus.blockedFoundation,
      );
    });

    test('missing conflict foundation fails closed', () {
      expect(
        service.evaluate(input(conflictDetectionReady: false)).ready,
        false,
      );
    });

    test('missing coordination foundation fails closed', () {
      expect(
        service.evaluate(input(safeCoordinationReady: false)).ready,
        false,
      );
    });

    test('missing attention foundation fails closed', () {
      expect(
        service.evaluate(input(ownerAdminAttentionReady: false)).ready,
        false,
      );
    });

    test('missing resilience foundation fails closed', () {
      expect(service.evaluate(input(resilienceReady: false)).ready, false);
    });

    test('security authority below Supervisor can never be ready', () {
      expect(service.evaluate(input(securityAbove: false)).ready, false);
    });

    test('Supervisor becoming Super Admin can never be ready', () {
      expect(service.evaluate(input(neverSuperAdmin: false)).ready, false);
    });

    test('Permission/Approval authority in Supervisor blocks readiness', () {
      expect(service.evaluate(input(noPermissionApproval: false)).ready, false);
    });

    test('business execution authority blocks readiness', () {
      expect(service.evaluate(input(noBusinessExecution: false)).ready, false);
    });

    test('security mutation authority blocks readiness', () {
      expect(service.evaluate(input(noSecurityMutation: false)).ready, false);
    });

    test('missing core failure isolation blocks readiness', () {
      expect(service.evaluate(input(coreIsolation: false)).ready, false);
    });

    for (final String scenarioId
        in AgentCrossAgentSupervisorAdversarialScenarioId.values) {
      test('$scenarioId must fail closed', () {
        final List<AgentCrossAgentSupervisorAdversarialScenario> scenarios =
            allSafeScenarios();

        final int index = scenarios.indexWhere(
          (AgentCrossAgentSupervisorAdversarialScenario value) =>
              value.scenarioId == scenarioId,
        );

        scenarios[index] = AgentCrossAgentSupervisorAdversarialScenario(
          scenarioId: scenarioId,
          attempted: true,
          failClosed: false,
          securityAuthorityPreserved: true,
          coreAppContinues: true,
        );

        final report = service.evaluate(input(scenarios: scenarios));

        expect(report.ready, false);
        expect(
          report.status,
          AgentCrossAgentSupervisorCloseoutStatus.blockedAdversarial,
        );
        expect(report.failedScenarioIds, contains(scenarioId));
      });
    }

    test('security authority loss fails adversarial gate', () {
      final scenario = AgentCrossAgentSupervisorAdversarialScenario(
        scenarioId: AgentCrossAgentSupervisorAdversarialScenarioId
            .supervisorAuthorityAbuse,
        attempted: true,
        failClosed: true,
        securityAuthorityPreserved: false,
        coreAppContinues: true,
      );

      expect(
        gate.allPass(<AgentCrossAgentSupervisorAdversarialScenario>[scenario]),
        false,
      );
    });

    test('core-app outage fails adversarial gate', () {
      final scenario = AgentCrossAgentSupervisorAdversarialScenario(
        scenarioId:
            AgentCrossAgentSupervisorAdversarialScenarioId.loopRetryStorm,
        attempted: true,
        failClosed: true,
        securityAuthorityPreserved: true,
        coreAppContinues: false,
      );

      expect(
        gate.allPass(<AgentCrossAgentSupervisorAdversarialScenario>[scenario]),
        false,
      );
    });

    test('scenario itself never grants authority/execution', () {
      final scenario = safeScenario(
        AgentCrossAgentSupervisorAdversarialScenarioId.fakeApproval,
      );

      expect(scenario.grantsPermission, false);
      expect(scenario.createsApproval, false);
      expect(scenario.grantsAuthority, false);
      expect(scenario.authorizesBusinessExecution, false);
      expect(scenario.modifiesSecurityControl, false);
      expect(scenario.mutatesBudget, false);
      expect(scenario.activatesProvider, false);
      expect(scenario.persistsScenario, false);
    });

    test('readiness input stores metadata only', () {
      final value = input();

      expect(value.containsRawUserMessage, false);
      expect(value.containsRawConversation, false);
      expect(value.containsPrivatePayload, false);
      expect(value.containsSecret, false);
      expect(value.containsRawApprovalToken, false);
      expect(value.containsRawPermissionToken, false);
    });

    test('adversarial gate explicit failure families are locked', () {
      expect(gate.fakeApprovalFailsClosed, true);
      expect(gate.privilegeEscalationFailsClosed, true);
      expect(gate.ownerAdminBypassFailsClosed, true);
      expect(gate.emergencyStopBypassFailsClosed, true);
      expect(gate.providerGeneratedAuthorityFailsClosed, true);
      expect(gate.permissionApprovalRuntimeGuardianBypassFailsClosed, true);
      expect(gate.masterAiCostBudgetAuditBypassFailsClosed, true);
      expect(gate.duplicateConflictLoopRetryFailsClosed, true);
      expect(gate.supervisorAuthorityAbuseFailsClosed, true);
      expect(gate.businessExecutionAttemptFailsClosed, true);
      expect(gate.securityWeakeningAttemptFailsClosed, true);
    });

    test('adversarial gate has no execution/write authority', () {
      expect(gate.providerInvocationImplementedHere, false);
      expect(gate.businessExecutionImplementedHere, false);
      expect(gate.securityMutationImplementedHere, false);
      expect(gate.persistenceImplementedHere, false);
    });

    test('final report has no authority or mutation capability', () {
      final report = service.evaluate(input());

      expect(report.supervisorIsSuperAdmin, false);
      expect(report.securityAuthorityAlwaysAboveSupervisor, true);

      expect(report.grantsPermission, false);
      expect(report.createsApproval, false);
      expect(report.consumesApproval, false);
      expect(report.grantsAuthority, false);
      expect(report.expandsScope, false);
      expect(report.assignsPrivilegedRole, false);
      expect(report.authorizesBusinessExecution, false);
      expect(report.executesBusinessAction, false);

      expect(report.modifiesSecurityEngine, false);
      expect(report.bypassesSecurityEngine, false);
      expect(report.mutatesRouting, false);
      expect(report.mutatesTaskOwner, false);
      expect(report.mutatesQueue, false);
      expect(report.mutatesProviderState, false);
      expect(report.mutatesBudget, false);
      expect(report.deploysAnything, false);
      expect(report.persistsReport, false);
    });

    test('final service locks all security hierarchy boundaries', () {
      expect(service.phase60FoundationComplete, true);
      expect(service.supervisorIsCoordinationWatchdogOnly, true);
      expect(service.supervisorIsNotSuperAdmin, true);
      expect(service.securityAuthorityAlwaysAboveSupervisor, true);

      expect(service.supervisorCannotBypassPermissionEngine, true);
      expect(service.supervisorCannotBypassApprovalEngine, true);
      expect(service.supervisorCannotBypassRuntimeGate, true);
      expect(service.supervisorCannotBypassGuardianSecurity, true);
      expect(service.supervisorCannotBypassOwnerSuperAdminControls, true);
      expect(service.supervisorCannotBypassMasterAiControls, true);
      expect(service.supervisorCannotBypassEmergencyStop, true);
      expect(service.supervisorCannotBypassCostBudgetControls, true);
      expect(service.supervisorCannotBypassMandatoryAudit, true);
    });

    test('final service cannot create authority/business action', () {
      expect(service.supervisorCannotGrantItselfAuthority, true);
      expect(service.supervisorCannotGrantOtherAgentAuthority, true);
      expect(service.supervisorCannotCreateOrConsumeApproval, true);
      expect(service.supervisorCannotExecuteBusinessAction, true);
      expect(service.supervisorCannotModifySecurityEngine, true);
    });

    test('provider/Supervisor failure can never stop core app', () {
      expect(service.providerFailureCannotStopCoreApp, true);
      expect(service.supervisorFailureCannotStopCoreApp, true);
      expect(service.coreAppContinuesOnAiFailure, true);
    });

    test('final closeout adds no production execution capability', () {
      expect(service.providerInvocationImplementedHere, false);
      expect(service.firestoreWriteImplementedHere, false);
      expect(service.authImpersonationImplementedHere, false);
      expect(service.routingMutationImplementedHere, false);
      expect(service.taskMutationImplementedHere, false);
      expect(service.budgetMutationImplementedHere, false);
      expect(service.deploymentImplementedHere, false);
      expect(service.persistenceImplementedHere, false);
    });

    test('later roadmap phases remain separate', () {
      expect(service.phase61PerformanceDashboardSeparate, true);
      expect(service.phase62VersioningDeploymentSeparate, true);
      expect(service.phase63PrivacyRetentionSeparate, true);
      expect(service.phase64OwnerAttentionInboxSeparate, true);
      expect(service.phase65FinalSafetyAuditSeparate, true);
      expect(service.phase66ProductionRolloutSeparate, true);
    });
  });
}
