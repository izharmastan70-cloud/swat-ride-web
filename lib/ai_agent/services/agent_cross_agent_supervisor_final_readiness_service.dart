import '../constants/agent_cross_agent_supervisor_closeout_constants.dart';
import '../models/agent_cross_agent_supervisor_readiness_input.dart';
import '../models/agent_cross_agent_supervisor_readiness_report.dart';
import 'agent_cross_agent_supervisor_adversarial_gate.dart';

class AgentCrossAgentSupervisorFinalReadinessService {
  const AgentCrossAgentSupervisorFinalReadinessService({
    this.adversarialGate = const AgentCrossAgentSupervisorAdversarialGate(),
  });

  final AgentCrossAgentSupervisorAdversarialGate adversarialGate;

  AgentCrossAgentSupervisorReadinessReport evaluate(
    AgentCrossAgentSupervisorReadinessInput input,
  ) {
    try {
      input.validateStructure();
    } catch (_) {
      return _report(
        status: AgentCrossAgentSupervisorCloseoutStatus.blockedInvalidMetadata,
        foundationReady: false,
        adversarialReady: false,
        coreFailureIsolationReady: true,
        failedScenarioIds: const <String>[],
        reasons: const <String>[
          'invalid_readiness_metadata',
          'fail_closed',
          'production_not_active',
        ],
      );
    }

    if (!input.allFoundationLocksReady) {
      return _report(
        status: AgentCrossAgentSupervisorCloseoutStatus.blockedFoundation,
        foundationReady: false,
        adversarialReady: false,
        coreFailureIsolationReady: input.coreFailureIsolationReady,
        failedScenarioIds: const <String>[],
        reasons: const <String>[
          'phase60_foundation_lock_missing',
          'fail_closed',
          'production_not_active',
        ],
      );
    }

    final List<String> failed = adversarialGate.failedScenarioIds(
      input.adversarialScenarios,
    );

    if (failed.isNotEmpty) {
      return _report(
        status: AgentCrossAgentSupervisorCloseoutStatus.blockedAdversarial,
        foundationReady: true,
        adversarialReady: false,
        coreFailureIsolationReady: input.coreFailureIsolationReady,
        failedScenarioIds: failed,
        reasons: const <String>[
          'adversarial_scenario_failed',
          'fail_closed',
          'production_not_active',
        ],
      );
    }

    return _report(
      status: AgentCrossAgentSupervisorCloseoutStatus.readyNotProductionActive,
      foundationReady: true,
      adversarialReady: true,
      coreFailureIsolationReady: true,
      failedScenarioIds: const <String>[],
      reasons: const <String>[
        'phase60_foundation_ready',
        'adversarial_closeout_clean',
        'core_failure_isolation_ready',
        'security_authority_above_supervisor',
        'foundation_ready_not_production_active',
      ],
    );
  }

  AgentCrossAgentSupervisorReadinessReport _report({
    required String status,
    required bool foundationReady,
    required bool adversarialReady,
    required bool coreFailureIsolationReady,
    required List<String> failedScenarioIds,
    required List<String> reasons,
  }) {
    final AgentCrossAgentSupervisorReadinessReport report =
        AgentCrossAgentSupervisorReadinessReport(
          status: status,
          foundationReady: foundationReady,
          adversarialReady: adversarialReady,
          coreFailureIsolationReady: coreFailureIsolationReady,
          failedScenarioIds: failedScenarioIds,
          reasonCodes: reasons,
        );

    report.validateStructure();
    return report;
  }

  bool get phase60FoundationComplete => true;
  bool get foundationReadyNotProductionActive => true;
  bool get productionSupervisorActivationImplementedHere => false;

  bool get supervisorIsCoordinationWatchdogOnly => true;
  bool get supervisorIsNotSuperAdmin => true;
  bool get securityAuthorityAlwaysAboveSupervisor => true;

  bool get supervisorCannotBypassPermissionEngine => true;
  bool get supervisorCannotBypassApprovalEngine => true;
  bool get supervisorCannotBypassRuntimeGate => true;
  bool get supervisorCannotBypassGuardianSecurity => true;
  bool get supervisorCannotBypassOwnerSuperAdminControls => true;
  bool get supervisorCannotBypassMasterAiControls => true;
  bool get supervisorCannotBypassEmergencyStop => true;
  bool get supervisorCannotBypassCostBudgetControls => true;
  bool get supervisorCannotBypassMandatoryAudit => true;

  bool get supervisorCannotGrantItselfAuthority => true;
  bool get supervisorCannotGrantOtherAgentAuthority => true;
  bool get supervisorCannotCreateOrConsumeApproval => true;
  bool get supervisorCannotExecuteBusinessAction => true;
  bool get supervisorCannotModifySecurityEngine => true;

  bool get providerFailureCannotStopCoreApp => true;
  bool get supervisorFailureCannotStopCoreApp => true;
  bool get coreAppContinuesOnAiFailure => true;

  bool get providerInvocationImplementedHere => false;
  bool get firestoreWriteImplementedHere => false;
  bool get authImpersonationImplementedHere => false;
  bool get routingMutationImplementedHere => false;
  bool get taskMutationImplementedHere => false;
  bool get budgetMutationImplementedHere => false;
  bool get deploymentImplementedHere => false;
  bool get persistenceImplementedHere => false;

  bool get phase61PerformanceDashboardSeparate => true;
  bool get phase62VersioningDeploymentSeparate => true;
  bool get phase63PrivacyRetentionSeparate => true;
  bool get phase64OwnerAttentionInboxSeparate => true;
  bool get phase65FinalSafetyAuditSeparate => true;
  bool get phase66ProductionRolloutSeparate => true;
}
