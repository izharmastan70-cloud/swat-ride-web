import '../constants/agent_provider_expansion_closeout_constants.dart';

class AgentProviderExpansionReadinessReport {
  AgentProviderExpansionReadinessReport({
    required this.status,
    required this.phaseComplete,
    required List<String> reasonCodes,
  }) : reasonCodes = List<String>.unmodifiable(reasonCodes);

  final String status;
  final bool phaseComplete;
  final List<String> reasonCodes;

  bool get foundationReady =>
      status ==
      AgentProviderExpansionReadinessStatus.foundationReadyNotProductionActive;

  bool get productionActive => false;
  bool get realProviderInvocationEnabled => false;
  bool get clientSideProviderSecretsEnabled => false;
  bool get trustedBackendPersistenceEnabledHere => false;
  bool get permissionsExpanded => false;
  bool get approvalsConsumed => false;
  bool get businessActionsExecuted => false;
  bool get paidBudgetAutoIncreased => false;
  bool get paidAiAutoEnabled => false;
  bool get providerQualityEvaluatorImplementedHere => false;

  bool get coreAppContinuesOnProviderFailure => true;
  bool get phase59QualityEvaluatorSeparate => true;
  bool get phase62DeploymentSeparate => true;
  bool get phase63PrivacyRetentionSeparate => true;
  bool get phase65FinalSafetyAuditSeparate => true;
  bool get phase66ProductionRolloutSeparate => true;

  void validateStructure() {
    if (!AgentProviderExpansionReadinessStatus.values.contains(status) ||
        reasonCodes.isEmpty ||
        reasonCodes.length >
            AgentProviderExpansionCloseoutLimits.maxReasonCodes) {
      throw const FormatException(
        'Invalid provider expansion readiness report.',
      );
    }
  }
}
