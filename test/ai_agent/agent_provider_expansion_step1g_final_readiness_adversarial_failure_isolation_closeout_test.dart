import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_provider_expansion_closeout_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_provider_expansion_adversarial_scenario.dart';
import 'package:swat_ride/ai_agent/models/agent_provider_expansion_readiness_input.dart';
import 'package:swat_ride/ai_agent/services/agent_provider_expansion_adversarial_gate.dart';
import 'package:swat_ride/ai_agent/services/agent_provider_expansion_final_readiness_service.dart';

void main() {
  const AgentProviderExpansionAdversarialGate gate =
      AgentProviderExpansionAdversarialGate();

  const AgentProviderExpansionFinalReadinessService service =
      AgentProviderExpansionFinalReadinessService();

  const AgentProviderExpansionReadinessInput cleanInput =
      AgentProviderExpansionReadinessInput(
        providerContractClean: true,
        safeActivationBoundaryClean: true,
        routingFailoverClean: true,
        circuitBreakerClean: true,
        coreAppFailureIsolationClean: true,
        taskCapabilityMatrixClean: true,
        modelCompatibilityClean: true,
        contextTokenBoundaryClean: true,
        privacyProjectionClean: true,
        sensitiveTaskRestrictionClean: true,
        trustedBackendHandoffClean: true,
        usageAccountingClean: true,
        costLogBoundaryClean: true,
        paidControlsPreserved: true,
        clientSecretsAbsent: true,
        directProviderCallsAbsent: true,
        permissionAuthorityAbsent: true,
        approvalAuthorityAbsent: true,
        businessAuthorityAbsent: true,
        productionProviderConnectorConfigured: false,
        productionCredentialsConfigured: false,
        trustedBackendPersistenceConfigured: false,
      );

  AgentProviderExpansionAdversarialScenario scenario(
    String type, {
    bool detected = true,
  }) {
    return AgentProviderExpansionAdversarialScenario(
      scenarioId: 'scenario:$type',
      type: type,
      detected: detected,
    );
  }

  group('Phase 58 Step 1G closeout', () {
    test('4 readiness statuses are locked', () {
      expect(AgentProviderExpansionReadinessStatus.values.length, 4);
    });

    test('26 adversarial/failure scenario types are locked', () {
      expect(AgentProviderExpansionAdversarialType.values.length, 26);
    });

    test('5 provider/accounting failures are isolation types', () {
      expect(
        AgentProviderExpansionAdversarialType.isolatedFailureTypes.length,
        5,
      );
    });

    test('clean Phase 58 contracts produce foundation-ready status', () {
      final report = service.evaluate(
        input: cleanInput,
        adversarialScenarios:
            const <AgentProviderExpansionAdversarialScenario>[],
      );

      expect(report.foundationReady, true);
      expect(report.phaseComplete, true);
      expect(
        report.status,
        AgentProviderExpansionReadinessStatus
            .foundationReadyNotProductionActive,
      );
    });

    test('foundation ready never means production active', () {
      final report = service.evaluate(
        input: cleanInput,
        adversarialScenarios:
            const <AgentProviderExpansionAdversarialScenario>[],
      );

      expect(report.productionActive, false);
      expect(report.realProviderInvocationEnabled, false);
      expect(report.clientSideProviderSecretsEnabled, false);
      expect(report.trustedBackendPersistenceEnabledHere, false);
    });

    test('unclean safety contract fails closed', () {
      const bad = AgentProviderExpansionReadinessInput(
        providerContractClean: false,
        safeActivationBoundaryClean: true,
        routingFailoverClean: true,
        circuitBreakerClean: true,
        coreAppFailureIsolationClean: true,
        taskCapabilityMatrixClean: true,
        modelCompatibilityClean: true,
        contextTokenBoundaryClean: true,
        privacyProjectionClean: true,
        sensitiveTaskRestrictionClean: true,
        trustedBackendHandoffClean: true,
        usageAccountingClean: true,
        costLogBoundaryClean: true,
        paidControlsPreserved: true,
        clientSecretsAbsent: true,
        directProviderCallsAbsent: true,
        permissionAuthorityAbsent: true,
        approvalAuthorityAbsent: true,
        businessAuthorityAbsent: true,
        productionProviderConnectorConfigured: false,
        productionCredentialsConfigured: false,
        trustedBackendPersistenceConfigured: false,
      );

      final report = service.evaluate(
        input: bad,
        adversarialScenarios:
            const <AgentProviderExpansionAdversarialScenario>[],
      );

      expect(
        report.status,
        AgentProviderExpansionReadinessStatus.blockedSafetyContract,
      );
      expect(report.phaseComplete, false);
    });

    test('all non-failure adversarial attacks fail closed', () {
      for (final String type in AgentProviderExpansionAdversarialType.values) {
        if (AgentProviderExpansionAdversarialType.isolatedFailureTypes.contains(
          type,
        )) {
          continue;
        }

        expect(
          gate.evaluate(scenario(type)),
          AgentProviderExpansionReadinessStatus.blockedAdversarialScenario,
          reason: type,
        );
      }
    });

    test('provider/accounting failures are isolated', () {
      for (final String type
          in AgentProviderExpansionAdversarialType.isolatedFailureTypes) {
        expect(
          gate.evaluate(scenario(type)),
          AgentProviderExpansionReadinessStatus.isolateProviderFailure,
          reason: type,
        );
      }
    });

    test('undetected scenario does not block foundation readiness', () {
      expect(
        gate.evaluate(
          scenario(
            AgentProviderExpansionAdversarialType.promptInjection,
            detected: false,
          ),
        ),
        AgentProviderExpansionReadinessStatus
            .foundationReadyNotProductionActive,
      );
    });

    test('prompt injection can never claim authority', () {
      expect(gate.promptInjectionNeverAuthority, true);
    });

    test('provider output can never claim authority', () {
      expect(gate.providerOutputNeverAuthority, true);
    });

    test('client-side secrets remain forbidden', () {
      expect(gate.secretsNeverClientSide, true);
    });

    test('restricted payload can never become provider input', () {
      expect(gate.restrictedPayloadNeverProviderInput, true);
    });

    test('sensitive external task fails closed', () {
      expect(gate.sensitiveExternalTaskFailsClosed, true);
    });

    test('paid controls cannot be bypassed', () {
      expect(gate.paidControlsCannotBeBypassed, true);
    });

    test('duplicate accounting remains blocked', () {
      expect(gate.duplicateAccountingBlocked, true);
    });

    test('budget cannot auto increase', () {
      expect(gate.budgetCannotAutoIncrease, true);
    });

    test('cost limits cannot auto override', () {
      expect(gate.limitsCannotAutoOverride, true);
    });

    test('production activation attempt is blocked in Phase 58', () {
      expect(gate.productionActivationAttemptBlocked, true);
    });

    test('provider failures remain isolated from core app', () {
      expect(gate.providerFailuresAreIsolated, true);
      expect(gate.coreAppContinuesOnProviderFailure, true);
    });

    test('gate adds no provider or business authority', () {
      expect(gate.invokesProvider, false);
      expect(gate.grantsPermission, false);
      expect(gate.consumesApproval, false);
      expect(gate.expandsScope, false);
      expect(gate.executesBusinessAction, false);
      expect(gate.mutatesBudget, false);
      expect(gate.persistsAdversarialResult, false);
    });

    test('detected provider failure returns isolate status', () {
      final report = service.evaluate(
        input: cleanInput,
        adversarialScenarios: <AgentProviderExpansionAdversarialScenario>[
          scenario(AgentProviderExpansionAdversarialType.providerFailure),
        ],
      );

      expect(
        report.status,
        AgentProviderExpansionReadinessStatus.isolateProviderFailure,
      );
      expect(report.phaseComplete, false);
      expect(report.coreAppContinuesOnProviderFailure, true);
    });

    test('detected timeout returns isolate status', () {
      final report = service.evaluate(
        input: cleanInput,
        adversarialScenarios: <AgentProviderExpansionAdversarialScenario>[
          scenario(AgentProviderExpansionAdversarialType.providerTimeout),
        ],
      );

      expect(
        report.status,
        AgentProviderExpansionReadinessStatus.isolateProviderFailure,
      );
    });

    test('detected budget bypass blocks readiness', () {
      final report = service.evaluate(
        input: cleanInput,
        adversarialScenarios: <AgentProviderExpansionAdversarialScenario>[
          scenario(AgentProviderExpansionAdversarialType.bypassPaidBudget),
        ],
      );

      expect(
        report.status,
        AgentProviderExpansionReadinessStatus.blockedAdversarialScenario,
      );
    });

    test('detected production activation attempt blocks readiness', () {
      final report = service.evaluate(
        input: cleanInput,
        adversarialScenarios: <AgentProviderExpansionAdversarialScenario>[
          scenario(
            AgentProviderExpansionAdversarialType.productionActivationAttempt,
          ),
        ],
      );

      expect(
        report.status,
        AgentProviderExpansionReadinessStatus.blockedAdversarialScenario,
      );
    });

    test('readiness report cannot expand authority', () {
      final report = service.evaluate(
        input: cleanInput,
        adversarialScenarios:
            const <AgentProviderExpansionAdversarialScenario>[],
      );

      expect(report.permissionsExpanded, false);
      expect(report.approvalsConsumed, false);
      expect(report.businessActionsExecuted, false);
      expect(report.paidBudgetAutoIncreased, false);
      expect(report.paidAiAutoEnabled, false);
      expect(report.providerQualityEvaluatorImplementedHere, false);
    });

    test('later phase ownership remains separate', () {
      final report = service.evaluate(
        input: cleanInput,
        adversarialScenarios:
            const <AgentProviderExpansionAdversarialScenario>[],
      );

      expect(report.phase59QualityEvaluatorSeparate, true);
      expect(report.phase62DeploymentSeparate, true);
      expect(report.phase63PrivacyRetentionSeparate, true);
      expect(report.phase65FinalSafetyAuditSeparate, true);
      expect(report.phase66ProductionRolloutSeparate, true);
    });

    test('service preserves Free Local Paid and safety policies', () {
      expect(service.freeOnlineFirstPreserved, true);
      expect(service.localOptionalPreserved, true);
      expect(service.paidLastEscalationPreserved, true);
      expect(service.paidOnOffPreserved, true);
      expect(service.askBeforePaidPreserved, true);
      expect(service.budgetLimitsPreserved, true);
      expect(service.costLogsPreserved, true);
      expect(service.minimumContextPreserved, true);
      expect(service.privacyMinimizationPreserved, true);
      expect(service.backendOnlySecretsPreserved, true);
      expect(service.providerFailureIsolationPreserved, true);
      expect(service.coreAppContinuationPreserved, true);
    });

    test('service implements no production provider connector', () {
      expect(service.productionProviderActivationImplementedHere, false);
      expect(service.providerInvocationImplementedHere, false);
      expect(service.credentialStorageImplementedHere, false);
      expect(service.trustedBackendPersistenceImplementedHere, false);
      expect(service.providerQualityEvaluationOwnedHere, false);
    });

    test('service adds no Permission Approval Scope Business authority', () {
      expect(service.grantsPermission, false);
      expect(service.consumesApproval, false);
      expect(service.expandsScope, false);
      expect(service.executesBusinessAction, false);
      expect(service.writesBusinessData, false);
      expect(service.mutatesBudget, false);
    });
  });
}
