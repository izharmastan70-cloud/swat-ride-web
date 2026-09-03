import '../constants/agent_provider_quality_closeout_constants.dart';

class AgentProviderQualityReadinessReport {
  AgentProviderQualityReadinessReport({
    required this.status,
    required this.foundationReady,
    required List<String> reasonCodes,
  }) : reasonCodes = List<String>.unmodifiable(reasonCodes);

  final String status;
  final bool foundationReady;
  final List<String> reasonCodes;

  bool get productionActive => false;
  bool get realProviderInvocationImplementedHere => false;
  bool get providerCredentialsImplementedHere => false;
  bool get trustedBackendPersistenceImplementedHere => false;
  bool get productionProviderActivationImplementedHere => false;

  bool get qualityRecommendationOnly => true;
  bool get coreAppContinuationPreserved => true;
  bool get qualityFailureCannotBreakCoreApp => true;

  bool get freeOnlineFirstPriority => true;
  bool get localAiOptionalFuture => true;
  bool get paidAiLastEscalation => true;
  bool get paidOnOffStillAuthoritative => true;
  bool get askBeforePaidStillAuthoritative => true;
  bool get budgetStillAuthoritative => true;
  bool get privacyStillAuthoritative => true;
  bool get capabilityStillAuthoritative => true;
  bool get circuitBreakerStillAuthoritative => true;
  bool get backendBoundaryStillAuthoritative => true;

  bool get mayGrantPermission => false;
  bool get mayConsumeApproval => false;
  bool get mayExpandScope => false;
  bool get mayExecuteBusinessAction => false;
  bool get mayMutateRouting => false;
  bool get mayEnableProvider => false;
  bool get mayDisableProvider => false;
  bool get mayMutateBudget => false;
  bool get mayChangeSecret => false;
  bool get mayDeployModel => false;

  bool get phase60CrossAgentSupervisorSeparate => true;
  bool get phase61PerformanceDashboardSeparate => true;
  bool get phase62VersioningDeploymentSeparate => true;
  bool get phase63PrivacyRetentionSeparate => true;
  bool get phase65FinalSafetyAuditSeparate => true;
  bool get phase66ProductionRolloutSeparate => true;

  void validateStructure() {
    if (!AgentProviderQualityReadinessStatus.values.contains(status) ||
        reasonCodes.isEmpty ||
        reasonCodes.length > 24) {
      throw const FormatException('Invalid provider quality readiness report.');
    }
  }
}
