import '../constants/agent_provider_expansion_closeout_constants.dart';
import '../models/agent_provider_expansion_adversarial_scenario.dart';

class AgentProviderExpansionAdversarialGate {
  const AgentProviderExpansionAdversarialGate();

  String evaluate(AgentProviderExpansionAdversarialScenario scenario) {
    try {
      scenario.validateStructure();
    } catch (_) {
      return AgentProviderExpansionReadinessStatus.blockedAdversarialScenario;
    }

    if (!scenario.detected) {
      return AgentProviderExpansionReadinessStatus
          .foundationReadyNotProductionActive;
    }

    if (AgentProviderExpansionAdversarialType.isolatedFailureTypes.contains(
      scenario.type,
    )) {
      return AgentProviderExpansionReadinessStatus.isolateProviderFailure;
    }

    return AgentProviderExpansionReadinessStatus.blockedAdversarialScenario;
  }

  bool get providerOutputNeverAuthority => true;
  bool get promptInjectionNeverAuthority => true;
  bool get secretsNeverClientSide => true;
  bool get restrictedPayloadNeverProviderInput => true;
  bool get sensitiveExternalTaskFailsClosed => true;
  bool get paidControlsCannotBeBypassed => true;
  bool get duplicateAccountingBlocked => true;
  bool get budgetCannotAutoIncrease => true;
  bool get limitsCannotAutoOverride => true;
  bool get productionActivationAttemptBlocked => true;
  bool get providerFailuresAreIsolated => true;
  bool get coreAppContinuesOnProviderFailure => true;

  bool get invokesProvider => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get expandsScope => false;
  bool get executesBusinessAction => false;
  bool get mutatesBudget => false;
  bool get persistsAdversarialResult => false;
}
