import '../constants/agent_provider_expansion_closeout_constants.dart';
import '../models/agent_provider_expansion_adversarial_scenario.dart';
import '../models/agent_provider_expansion_readiness_input.dart';
import '../models/agent_provider_expansion_readiness_report.dart';
import 'agent_provider_expansion_adversarial_gate.dart';

class AgentProviderExpansionFinalReadinessService {
  const AgentProviderExpansionFinalReadinessService({
    this.adversarialGate = const AgentProviderExpansionAdversarialGate(),
  });

  final AgentProviderExpansionAdversarialGate adversarialGate;

  AgentProviderExpansionReadinessReport evaluate({
    required AgentProviderExpansionReadinessInput input,
    required List<AgentProviderExpansionAdversarialScenario>
    adversarialScenarios,
  }) {
    if (!input.allSafetyContractsClean) {
      return _report(
        status: AgentProviderExpansionReadinessStatus.blockedSafetyContract,
        reasons: const <String>[
          'one_or_more_phase58_safety_contracts_not_clean',
          'fail_closed',
          'production_activation_not_allowed',
        ],
      );
    }

    for (final AgentProviderExpansionAdversarialScenario scenario
        in adversarialScenarios) {
      final String result = adversarialGate.evaluate(scenario);

      if (result ==
          AgentProviderExpansionReadinessStatus.blockedAdversarialScenario) {
        return _report(
          status:
              AgentProviderExpansionReadinessStatus.blockedAdversarialScenario,
          reasons: <String>[
            'adversarial_scenario_blocked',
            'scenario:${scenario.type}',
            'fail_closed',
            'production_activation_not_allowed',
          ],
        );
      }
    }

    final bool isolatedProviderFailure = adversarialScenarios.any(
      (AgentProviderExpansionAdversarialScenario scenario) =>
          scenario.detected &&
          AgentProviderExpansionAdversarialType.isolatedFailureTypes.contains(
            scenario.type,
          ),
    );

    if (isolatedProviderFailure) {
      return _report(
        status: AgentProviderExpansionReadinessStatus.isolateProviderFailure,
        reasons: const <String>[
          'provider_or_accounting_failure_isolated',
          'ai_provider_path_not_available',
          'core_app_continues',
          'production_activation_not_allowed',
        ],
      );
    }

    return _report(
      status: AgentProviderExpansionReadinessStatus
          .foundationReadyNotProductionActive,
      reasons: <String>[
        'phase58_safety_contracts_clean',
        'adversarial_closeout_clean',
        'provider_failure_isolation_clean',
        'free_local_paid_policy_preserved',
        'paid_cost_controls_preserved',
        'privacy_minimization_preserved',
        'trusted_backend_boundary_preserved',
        'client_secrets_absent',
        'direct_provider_calls_absent',
        if (!input.productionDependenciesConfigured)
          'production_provider_dependencies_deferred',
        'phase59_quality_evaluator_separate',
        'phase62_deployment_separate',
        'phase63_privacy_retention_separate',
        'phase65_final_safety_audit_separate',
        'phase66_production_rollout_separate',
      ],
    );
  }

  AgentProviderExpansionReadinessReport _report({
    required String status,
    required List<String> reasons,
  }) {
    final AgentProviderExpansionReadinessReport report =
        AgentProviderExpansionReadinessReport(
          status: status,
          phaseComplete:
              status ==
              AgentProviderExpansionReadinessStatus
                  .foundationReadyNotProductionActive,
          reasonCodes: reasons,
        );

    report.validateStructure();
    return report;
  }

  bool get freeOnlineFirstPreserved => true;
  bool get localOptionalPreserved => true;
  bool get paidLastEscalationPreserved => true;
  bool get paidOnOffPreserved => true;
  bool get askBeforePaidPreserved => true;
  bool get budgetLimitsPreserved => true;
  bool get costLogsPreserved => true;
  bool get minimumContextPreserved => true;
  bool get privacyMinimizationPreserved => true;
  bool get backendOnlySecretsPreserved => true;
  bool get providerFailureIsolationPreserved => true;
  bool get coreAppContinuationPreserved => true;

  bool get productionProviderActivationImplementedHere => false;
  bool get providerInvocationImplementedHere => false;
  bool get credentialStorageImplementedHere => false;
  bool get trustedBackendPersistenceImplementedHere => false;
  bool get providerQualityEvaluationOwnedHere => false;

  bool get phase59OwnsProviderQualityEvaluator => true;
  bool get phase62DeploymentSeparate => true;
  bool get phase63PrivacyRetentionSeparate => true;
  bool get phase65FinalSafetyAuditSeparate => true;
  bool get phase66ProductionRolloutSeparate => true;

  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get expandsScope => false;
  bool get executesBusinessAction => false;
  bool get writesBusinessData => false;
  bool get mutatesBudget => false;
}
