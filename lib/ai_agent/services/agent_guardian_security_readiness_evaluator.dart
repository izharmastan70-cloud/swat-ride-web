import '../models/agent_guardian_adversarial_case.dart';
import '../models/agent_guardian_adversarial_verification_result.dart';
import '../models/agent_guardian_security_readiness_report.dart';
import 'agent_guardian_adversarial_verification_service.dart';

class AgentGuardianSecurityReadinessEvaluator {
  const AgentGuardianSecurityReadinessEvaluator({
    this.adversarialVerificationService =
        const AgentGuardianAdversarialVerificationService(),
  });

  final AgentGuardianAdversarialVerificationService
  adversarialVerificationService;

  AgentGuardianSecurityReadinessReport evaluate({
    required DateTime generatedAt,
    required bool callAgentLockedActionSetPreserved,
  }) {
    final List<AgentGuardianAdversarialCase> cases =
        adversarialVerificationService.buildLockedCoverage();

    final List<AgentGuardianAdversarialVerificationResult> results =
        adversarialVerificationService.verifyLockedCoverage();

    final int uniqueCoverageCount = cases
        .map((AgentGuardianAdversarialCase item) => item.scenarioId)
        .toSet()
        .length;

    final bool exactCoverage =
        cases.length == 14 && uniqueCoverageCount == 14 && results.length == 14;

    final bool allPassed =
        exactCoverage &&
        results.every(
          (AgentGuardianAdversarialVerificationResult result) =>
              result.passed && result.expectedOutcomeMet,
        );

    final bool failureIsolationVerified = results.every(
      (AgentGuardianAdversarialVerificationResult result) =>
          result.coreAppAvailable &&
          result.otherChannelsAvailable &&
          result.authoritativeControlsRemainIndependent &&
          result.guardianFailureIsolated,
    );

    final bool recommendationOnlyVerified = results.every(
      (AgentGuardianAdversarialVerificationResult result) =>
          result.recommendationOnly &&
          !result.guardianIsFinalEnforcer &&
          !result.invokesPermissionEngine &&
          !result.invokesApprovalEngine &&
          !result.invokesRuntimeGate &&
          !result.invokesEmergencyStop &&
          !result.executesBlock &&
          !result.executesEscalation &&
          !result.createsIncident &&
          !result.invokesProvider &&
          !result.invokesTargetAgent &&
          !result.writesBusinessData &&
          !result.persistsResult,
    );

    final bool failClosedMonitoringVerified = results.any(
      (AgentGuardianAdversarialVerificationResult result) =>
          result.failClosedRecommended,
    );

    final bool foundationReady =
        exactCoverage &&
        allPassed &&
        failureIsolationVerified &&
        recommendationOnlyVerified &&
        failClosedMonitoringVerified &&
        callAgentLockedActionSetPreserved;

    final AgentGuardianSecurityReadinessReport report =
        AgentGuardianSecurityReadinessReport(
          status: foundationReady
              ? AgentGuardianSecurityReadinessStatus
                    .foundationReadyNotProductionActive
              : AgentGuardianSecurityReadinessStatus.blockedNotReady,
          guardianFoundationReady: foundationReady,
          productionActive: false,
          adversarialCoverageCount: uniqueCoverageCount,
          allAdversarialCasesPassed: allPassed,
          failClosedMonitoringVerified: failClosedMonitoringVerified,
          failureIsolationVerified: failureIsolationVerified,
          safeEvidenceOnlyVerified: recommendationOnlyVerified,
          authoritativeControlsRemainFinal: true,
          authoritativeChecksRemainRequired: true,
          guardianIsFinalEnforcer: false,
          permissionApprovalRuntimeBypassAllowed: false,
          phase54IncidentResponseImplemented: false,
          persistentGuardianMonitoringImplemented: false,
          securityAuditPersistenceImplemented: false,
          providerExecutionImplemented: false,
          targetAgentExecutionImplemented: false,
          businessWriteImplemented: false,
          rawSensitiveEvidenceAllowed: false,
          coreAppFailureCoupledToGuardian: false,
          otherChannelFailureCoupledToGuardian: false,
          callAgentLockedActionSetPreserved: callAgentLockedActionSetPreserved,
          generatedAt: generatedAt,
          readinessEvidenceCodes: <String>[
            'guardian_steps_1b_to_1f_verified',
            'adversarial_coverage_14',
            if (allPassed) 'adversarial_all_passed',
            if (failClosedMonitoringVerified) 'fail_closed_monitoring_verified',
            if (failureIsolationVerified) 'failure_isolation_verified',
            if (recommendationOnlyVerified) 'recommendation_only_verified',
            'authoritative_controls_final',
            'authoritative_checks_required',
            'production_not_active',
            'phase54_incident_response_not_implemented',
            'guardian_persistence_not_implemented',
            'provider_execution_not_implemented',
            'business_write_not_implemented',
            if (callAgentLockedActionSetPreserved)
              'call_agent_exact_four_preserved',
          ],
        );

    report.validateStructure();
    return report;
  }

  bool get readinessEvaluatorOnly => true;
  bool get activatesProductionGuardian => false;
  bool get guardianIsFinalEnforcer => false;
  bool get invokesPermissionEngine => false;
  bool get invokesApprovalEngine => false;
  bool get invokesRuntimeGate => false;
  bool get invokesEmergencyStop => false;
  bool get bypassesAuthoritativeControls => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get marksRuntimeAllowed => false;
  bool get executesBlock => false;
  bool get executesEscalation => false;
  bool get createsIncident => false;
  bool get implementsIncidentResponse => false;
  bool get writesSecurityAuditPersistence => false;
  bool get invokesProvider => false;
  bool get invokesTargetAgent => false;
  bool get writesBusinessData => false;
  bool get persistsReadinessReport => false;
  bool get canBreakCoreApp => false;
  bool get canBreakOtherChannels => false;
}
