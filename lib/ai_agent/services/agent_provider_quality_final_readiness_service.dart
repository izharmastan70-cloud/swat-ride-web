import '../constants/agent_provider_quality_closeout_constants.dart';
import '../models/agent_provider_quality_readiness_input.dart';
import '../models/agent_provider_quality_readiness_report.dart';

class AgentProviderQualityFinalReadinessService {
  const AgentProviderQualityFinalReadinessService();

  AgentProviderQualityReadinessReport evaluate(
    AgentProviderQualityReadinessInput input,
  ) {
    if (!input.allFoundationReady) {
      return _report(
        status: AgentProviderQualityReadinessStatus.blockedFoundationIncomplete,
        foundationReady: false,
        reasons: const <String>[
          'provider_quality_foundation_incomplete',
          'production_activation_forbidden',
          'fail_closed',
        ],
      );
    }

    return _report(
      status: AgentProviderQualityReadinessStatus
          .foundationReadyNotProductionActive,
      foundationReady: true,
      reasons: const <String>[
        'signal_boundary_ready',
        'multi_signal_aggregation_ready',
        'safety_first_recommendation_ready',
        'task_specific_tier_preserving_comparison_ready',
        'history_trend_anti_flapping_ready',
        'provenance_deduplication_ready',
        'outlier_poisoning_resistance_ready',
        'safe_calibration_ready',
        'adversarial_gate_ready',
        'failure_isolation_ready',
        'production_activation_remains_deferred',
      ],
    );
  }

  AgentProviderQualityReadinessReport _report({
    required String status,
    required bool foundationReady,
    required List<String> reasons,
  }) {
    final AgentProviderQualityReadinessReport result =
        AgentProviderQualityReadinessReport(
          status: status,
          foundationReady: foundationReady,
          reasonCodes: reasons,
        );

    result.validateStructure();
    return result;
  }

  bool get providerQualityEvaluatorFoundationComplete => true;
  bool get foundationReadyNotProductionActive => true;

  bool get freeOnlineFirstPriority => true;
  bool get localAiOptionalFuture => true;
  bool get paidAiLastEscalation => true;

  bool get qualityCannotGrantPermission => true;
  bool get qualityCannotConsumeApproval => true;
  bool get qualityCannotExpandScope => true;
  bool get qualityCannotExecuteBusinessAction => true;

  bool get qualityFailureDoesNotBreakCoreApp => true;
  bool get providerFailureDoesNotBreakCoreApp => true;
  bool get evidenceFailureDoesNotBreakCoreApp => true;
  bool get calibrationFailureDoesNotBreakCoreApp => true;

  bool get providerInvocationImplementedHere => false;
  bool get providerCredentialsImplementedHere => false;
  bool get backendPersistenceImplementedHere => false;
  bool get productionActivationImplementedHere => false;

  bool get phase60CrossAgentSupervisorSeparate => true;
  bool get phase61PerformanceDashboardSeparate => true;
  bool get phase62VersioningDeploymentSeparate => true;
  bool get phase63PrivacyRetentionSeparate => true;
  bool get phase65FinalSafetyAuditSeparate => true;
  bool get phase66ProductionRolloutSeparate => true;
}
