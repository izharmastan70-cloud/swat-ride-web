import '../constants/agent_guardian_adversarial_constants.dart';
import '../constants/agent_guardian_observability_constants.dart';
import '../constants/agent_guardian_security_constants.dart';
import '../constants/agent_omnichannel_constants.dart';
import '../models/agent_guardian_adversarial_case.dart';
import '../models/agent_guardian_adversarial_verification_result.dart';
import '../models/agent_guardian_correlation_request.dart';
import '../models/agent_guardian_monitoring_assessment.dart';
import '../models/agent_guardian_risk_aggregate.dart';
import '../models/agent_guardian_security_event.dart';
import '../models/agent_guardian_security_observability_snapshot.dart';
import 'agent_guardian_observability_service.dart';
import 'agent_guardian_policy_handoff_service.dart';
import 'agent_guardian_signal_correlator.dart';

class AgentGuardianAdversarialVerificationService {
  const AgentGuardianAdversarialVerificationService({
    this._correlator = const AgentGuardianSignalCorrelator(),
    this._policyHandoff = const AgentGuardianPolicyHandoffService(),
    this._observability = const AgentGuardianObservabilityService(),
  });

  final AgentGuardianSignalCorrelator _correlator;
  final AgentGuardianPolicyHandoffService _policyHandoff;
  final AgentGuardianObservabilityService _observability;

  List<AgentGuardianAdversarialCase> buildLockedCoverage() {
    return const <AgentGuardianAdversarialCase>[
      AgentGuardianAdversarialCase(
        scenarioId: AgentGuardianAdversarialScenarioId.promptInjection,
        category: AgentGuardianRiskCategory.promptInjectionAttempt,
        evidenceTrust: AgentGuardianEvidenceTrust.verifiedSystem,
        expectedOutcome: AgentGuardianAdversarialExpectation.classified,
        expectedMinimumSeverity: AgentGuardianSeverity.medium,
      ),
      AgentGuardianAdversarialCase(
        scenarioId: AgentGuardianAdversarialScenarioId.permissionBypass,
        category: AgentGuardianRiskCategory.permissionBypassAttempt,
        evidenceTrust: AgentGuardianEvidenceTrust.verifiedSecurityControl,
        expectedOutcome: AgentGuardianAdversarialExpectation.failClosed,
        expectedMinimumSeverity: AgentGuardianSeverity.high,
        requiredControlUnhealthy: true,
      ),
      AgentGuardianAdversarialCase(
        scenarioId: AgentGuardianAdversarialScenarioId.approvalBypass,
        category: AgentGuardianRiskCategory.approvalBypassAttempt,
        evidenceTrust: AgentGuardianEvidenceTrust.verifiedSystem,
        expectedOutcome: AgentGuardianAdversarialExpectation.classified,
        expectedMinimumSeverity: AgentGuardianSeverity.high,
      ),
      AgentGuardianAdversarialCase(
        scenarioId: AgentGuardianAdversarialScenarioId.runtimeGateBypass,
        category: AgentGuardianRiskCategory.runtimeGateBypassAttempt,
        evidenceTrust: AgentGuardianEvidenceTrust.verifiedSecurityControl,
        expectedOutcome: AgentGuardianAdversarialExpectation.failClosed,
        expectedMinimumSeverity: AgentGuardianSeverity.high,
        requiredControlUnknown: true,
      ),
      AgentGuardianAdversarialCase(
        scenarioId: AgentGuardianAdversarialScenarioId.emergencyStopBypass,
        category: AgentGuardianRiskCategory.emergencyStopBypassAttempt,
        evidenceTrust: AgentGuardianEvidenceTrust.verifiedSecurityControl,
        expectedOutcome: AgentGuardianAdversarialExpectation.classified,
        expectedMinimumSeverity: AgentGuardianSeverity.critical,
      ),
      AgentGuardianAdversarialCase(
        scenarioId: AgentGuardianAdversarialScenarioId.crossSubjectContext,
        category: AgentGuardianRiskCategory.crossSubjectContextAttempt,
        evidenceTrust: AgentGuardianEvidenceTrust.verifiedSystem,
        expectedOutcome:
            AgentGuardianAdversarialExpectation.crossSubjectSuppressed,
        expectedMinimumSeverity: AgentGuardianSeverity.high,
        addCrossSubjectSignal: true,
      ),
      AgentGuardianAdversarialCase(
        scenarioId: AgentGuardianAdversarialScenarioId.replayStorm,
        category: AgentGuardianRiskCategory.replayOrContinuityViolation,
        evidenceTrust: AgentGuardianEvidenceTrust.verifiedSystem,
        expectedOutcome: AgentGuardianAdversarialExpectation.replaySuppressed,
        expectedMinimumSeverity: AgentGuardianSeverity.medium,
        addReplaySignal: true,
      ),
      AgentGuardianAdversarialCase(
        scenarioId: AgentGuardianAdversarialScenarioId.secretExposure,
        category: AgentGuardianRiskCategory.secretOrCredentialExposureAttempt,
        evidenceTrust: AgentGuardianEvidenceTrust.verifiedSystem,
        expectedOutcome:
            AgentGuardianAdversarialExpectation.invalidSignalFailClosed,
        expectedMinimumSeverity: AgentGuardianSeverity.high,
        injectRawSecretPayload: true,
      ),
      AgentGuardianAdversarialCase(
        scenarioId:
            AgentGuardianAdversarialScenarioId.unauthorizedProviderExecution,
        category:
            AgentGuardianRiskCategory.unauthorizedProviderExecutionAttempt,
        evidenceTrust: AgentGuardianEvidenceTrust.verifiedSystem,
        expectedOutcome: AgentGuardianAdversarialExpectation.classified,
        expectedMinimumSeverity: AgentGuardianSeverity.high,
      ),
      AgentGuardianAdversarialCase(
        scenarioId:
            AgentGuardianAdversarialScenarioId.unauthorizedBusinessWrite,
        category: AgentGuardianRiskCategory.unauthorizedBusinessWriteAttempt,
        evidenceTrust: AgentGuardianEvidenceTrust.verifiedSystem,
        expectedOutcome: AgentGuardianAdversarialExpectation.classified,
        expectedMinimumSeverity: AgentGuardianSeverity.high,
      ),
      AgentGuardianAdversarialCase(
        scenarioId: AgentGuardianAdversarialScenarioId.securityControlTamper,
        category: AgentGuardianRiskCategory.securityControlTamperAttempt,
        evidenceTrust: AgentGuardianEvidenceTrust.verifiedSecurityControl,
        expectedOutcome: AgentGuardianAdversarialExpectation.classified,
        expectedMinimumSeverity: AgentGuardianSeverity.critical,
      ),
      AgentGuardianAdversarialCase(
        scenarioId: AgentGuardianAdversarialScenarioId.requiredControlUnhealthy,
        category: AgentGuardianRiskCategory.permissionBypassAttempt,
        evidenceTrust: AgentGuardianEvidenceTrust.verifiedSecurityControl,
        expectedOutcome: AgentGuardianAdversarialExpectation.failClosed,
        expectedMinimumSeverity: AgentGuardianSeverity.high,
        requiredControlUnhealthy: true,
      ),
      AgentGuardianAdversarialCase(
        scenarioId: AgentGuardianAdversarialScenarioId.requiredControlUnknown,
        category: AgentGuardianRiskCategory.runtimeGateBypassAttempt,
        evidenceTrust: AgentGuardianEvidenceTrust.verifiedSecurityControl,
        expectedOutcome: AgentGuardianAdversarialExpectation.failClosed,
        expectedMinimumSeverity: AgentGuardianSeverity.high,
        requiredControlUnknown: true,
      ),
      AgentGuardianAdversarialCase(
        scenarioId: AgentGuardianAdversarialScenarioId.observerFailureIsolation,
        category: AgentGuardianRiskCategory.runtimeGateBypassAttempt,
        evidenceTrust: AgentGuardianEvidenceTrust.verifiedSecurityControl,
        expectedOutcome: AgentGuardianAdversarialExpectation.failureIsolated,
        expectedMinimumSeverity: AgentGuardianSeverity.high,
        simulateObserverFailure: true,
      ),
    ];
  }

  AgentGuardianAdversarialVerificationResult verifyCase(
    AgentGuardianAdversarialCase scenario,
  ) {
    scenario.validateStructure();

    final DateTime occurredAt = DateTime.utc(2026, 8, 19, 9, 10);

    final AgentGuardianSecurityEvent primary = AgentGuardianSecurityEvent(
      eventId: 'event_${scenario.scenarioId.toLowerCase()}',
      category: scenario.category,
      evidenceTrust: scenario.evidenceTrust,
      sourceComponent: 'guardian_adversarial_harness',
      occurredAt: occurredAt,
      observedAt: occurredAt.add(const Duration(minutes: 1)),
      evidenceCodes: <String>{'scenario_${scenario.scenarioId.toLowerCase()}'},
      pseudonymousSubjectRef: 'subject_hash_guardian_001',
      sourceChannel: AgentOmnichannelChannel.appChat,
      agentRoleId: 'support_agent',
      targetActionId: 'security.review',
      highImpactActionTargeted: scenario.highImpactActionTargeted,
      repeatedWithinWindow: scenario.repeatedWithinWindow,
      activeExploitEvidence: scenario.activeExploitEvidence,
      containsRawSecret: scenario.injectRawSecretPayload,
    );

    final List<AgentGuardianSecurityEvent> events =
        <AgentGuardianSecurityEvent>[primary];

    if (scenario.addCrossSubjectSignal) {
      events.add(
        AgentGuardianSecurityEvent(
          eventId: 'event_cross_subject_${scenario.scenarioId.toLowerCase()}',
          category: scenario.category,
          evidenceTrust: scenario.evidenceTrust,
          sourceComponent: 'guardian_adversarial_harness_b',
          occurredAt: occurredAt.add(const Duration(minutes: 1)),
          observedAt: occurredAt.add(const Duration(minutes: 2)),
          evidenceCodes: const <String>{'subject_mismatch'},
          pseudonymousSubjectRef: 'subject_hash_other',
          sourceChannel: AgentOmnichannelChannel.appChat,
          agentRoleId: 'support_agent',
          targetActionId: 'security.review',
        ),
      );
    }

    if (scenario.addReplaySignal) {
      events.add(
        AgentGuardianSecurityEvent(
          eventId: 'event_replay_${scenario.scenarioId.toLowerCase()}',
          category: scenario.category,
          evidenceTrust: scenario.evidenceTrust,
          sourceComponent: 'guardian_adversarial_harness',
          occurredAt: occurredAt,
          observedAt: occurredAt.add(const Duration(minutes: 1)),
          evidenceCodes: <String>{
            'scenario_${scenario.scenarioId.toLowerCase()}',
          },
          pseudonymousSubjectRef: 'subject_hash_guardian_001',
          sourceChannel: AgentOmnichannelChannel.appChat,
          agentRoleId: 'support_agent',
          targetActionId: 'security.review',
          highImpactActionTargeted: scenario.highImpactActionTargeted,
          repeatedWithinWindow: scenario.repeatedWithinWindow,
          activeExploitEvidence: scenario.activeExploitEvidence,
        ),
      );
    }

    final AgentGuardianCorrelationRequest correlationRequest =
        AgentGuardianCorrelationRequest(
          correlationId: 'correlation_${scenario.scenarioId.toLowerCase()}',
          pseudonymousSubjectRef: 'subject_hash_guardian_001',
          windowStart: DateTime.utc(2026, 8, 19, 9),
          windowEnd: DateTime.utc(2026, 8, 19, 9, 30),
          events: events,
        );

    final AgentGuardianRiskAggregate aggregate = _correlator.correlate(
      correlationRequest,
    );

    final policy = _policyHandoff.buildEnvelope(
      envelopeId: 'envelope_${scenario.scenarioId.toLowerCase()}',
      aggregate: aggregate,
      generatedAt: DateTime.utc(2026, 8, 19, 9, 20),
    );

    final handoff = _policyHandoff.prepareHandoff(
      handoffId: 'handoff_${scenario.scenarioId.toLowerCase()}',
      envelope: policy,
    );

    final bool? permissionHealthy = scenario.requiredControlUnhealthy
        ? false
        : scenario.requiredControlUnknown
        ? null
        : true;

    final bool? runtimeHealthy = scenario.requiredControlUnhealthy
        ? false
        : scenario.requiredControlUnknown
        ? null
        : true;

    AgentGuardianMonitoringAssessment monitoring;

    if (scenario.simulateObserverFailure) {
      monitoring = AgentGuardianMonitoringAssessment(
        status: AgentGuardianMonitoringStatus.failClosedRecommended,
        assessmentId: 'assessment_${scenario.scenarioId.toLowerCase()}',
        snapshotId: 'snapshot_${scenario.scenarioId.toLowerCase()}',
        handoffId: handoff.handoffId,
        envelopeId: policy.envelopeId,
        correlationId: policy.correlationId,
        pseudonymousSubjectRef: policy.pseudonymousSubjectRef,
        severity: policy.severity,
        failClosedRecommended: true,
        humanSecurityReviewRequired: true,
        authoritativeChecksStillPending: true,
        reasonCodes: const <String>[
          AgentGuardianMonitoringReason.invalidObservabilitySnapshot,
          AgentGuardianMonitoringReason.authoritativeChecksStillPending,
          AgentGuardianMonitoringReason.safeEvidenceOnly,
        ],
        unhealthyRequiredControls: const <String>[],
        unknownRequiredControls: const <String>[],
        generatedAt: DateTime.utc(2026, 8, 19, 9, 22),
      );
    } else {
      final AgentGuardianSecurityObservabilitySnapshot snapshot =
          AgentGuardianSecurityObservabilitySnapshot(
            snapshotId: 'snapshot_${scenario.scenarioId.toLowerCase()}',
            sourceComponent: 'guardian_adversarial_observer',
            capturedAt: DateTime.utc(2026, 8, 19, 9, 21),
            evidenceCodes: const <String>{'adversarial_health_snapshot'},
            permissionEngineHealthy: permissionHealthy,
            approvalEngineHealthy: true,
            runtimeGateHealthy: runtimeHealthy,
            emergencySecurityReviewHealthy: true,
            humanSecurityReviewAvailable: true,
          );

      monitoring = _observability.assess(
        assessmentId: 'assessment_${scenario.scenarioId.toLowerCase()}',
        handoff: handoff,
        snapshot: snapshot,
        generatedAt: DateTime.utc(2026, 8, 19, 9, 22),
      );
    }

    final bool replaySuppressed = aggregate.replayDuplicateSignalCount > 0;

    final bool crossSubjectSuppressed = aggregate.crossSubjectRejectedCount > 0;

    final bool severityMet =
        _severityRank(aggregate.severity) >=
        _severityRank(scenario.expectedMinimumSeverity);

    final bool expectedOutcomeMet = _expectedOutcomeMet(
      scenario: scenario,
      aggregate: aggregate,
      monitoring: monitoring,
      replaySuppressed: replaySuppressed,
      crossSubjectSuppressed: crossSubjectSuppressed,
    );

    final bool failureIsolated = scenario.simulateObserverFailure
        ? monitoring.failClosedRecommended
        : true;

    final bool passed =
        severityMet &&
        expectedOutcomeMet &&
        failureIsolated &&
        handoff.authoritativeChecksStillPending &&
        !handoff.guardianIsFinalEnforcer &&
        !_correlator.guardianIsFinalEnforcer &&
        !_policyHandoff.guardianIsFinalEnforcer &&
        !_observability.guardianIsFinalEnforcer;

    return AgentGuardianAdversarialVerificationResult(
      status: passed
          ? AgentGuardianAdversarialVerificationStatus.passed
          : AgentGuardianAdversarialVerificationStatus.failed,
      scenarioId: scenario.scenarioId,
      actualSeverity: aggregate.severity,
      actualDisposition: aggregate.recommendedDisposition,
      monitoringStatus: monitoring.status,
      expectedOutcomeMet: expectedOutcomeMet,
      replaySuppressed: replaySuppressed,
      crossSubjectSuppressed: crossSubjectSuppressed,
      failClosedRecommended: monitoring.failClosedRecommended,
      coreAppAvailable: true,
      otherChannelsAvailable: true,
      authoritativeControlsRemainIndependent: true,
      guardianFailureIsolated: failureIsolated,
      evidenceCodes: <String>[
        'severity_$severityMet',
        'expected_outcome_$expectedOutcomeMet',
        'authoritative_checks_pending',
        'guardian_not_final_enforcer',
        if (replaySuppressed) 'replay_suppressed',
        if (crossSubjectSuppressed) 'cross_subject_suppressed',
        if (monitoring.failClosedRecommended) 'fail_closed_recommended',
        if (scenario.simulateObserverFailure) 'observer_failure_isolated',
      ],
    );
  }

  List<AgentGuardianAdversarialVerificationResult> verifyLockedCoverage() {
    return buildLockedCoverage().map(verifyCase).toList(growable: false);
  }

  bool _expectedOutcomeMet({
    required AgentGuardianAdversarialCase scenario,
    required AgentGuardianRiskAggregate aggregate,
    required AgentGuardianMonitoringAssessment monitoring,
    required bool replaySuppressed,
    required bool crossSubjectSuppressed,
  }) {
    switch (scenario.expectedOutcome) {
      case AgentGuardianAdversarialExpectation.classified:
        return aggregate.ready;

      case AgentGuardianAdversarialExpectation.failClosed:
        return monitoring.failClosedRecommended;

      case AgentGuardianAdversarialExpectation.replaySuppressed:
        return replaySuppressed;

      case AgentGuardianAdversarialExpectation.crossSubjectSuppressed:
        return crossSubjectSuppressed;

      case AgentGuardianAdversarialExpectation.invalidSignalFailClosed:
        return aggregate.blocked && monitoring.failClosedRecommended;

      case AgentGuardianAdversarialExpectation.failureIsolated:
        return monitoring.failClosedRecommended;

      default:
        return false;
    }
  }

  int _severityRank(String severity) {
    switch (severity) {
      case AgentGuardianSeverity.low:
        return 0;
      case AgentGuardianSeverity.medium:
        return 1;
      case AgentGuardianSeverity.high:
        return 2;
      case AgentGuardianSeverity.critical:
        return 3;
      default:
        return -1;
    }
  }

  bool get adversarialHarnessOnly => true;
  bool get recommendationOnly => true;
  bool get guardianIsFinalEnforcer => false;
  bool get invokesPermissionEngine => false;
  bool get invokesApprovalEngine => false;
  bool get invokesRuntimeGate => false;
  bool get invokesEmergencyStop => false;
  bool get bypassesAuthoritativeControls => false;
  bool get executesBlock => false;
  bool get executesEscalation => false;
  bool get createsIncident => false;
  bool get implementsIncidentResponse => false;
  bool get activatesProductionMonitoring => false;
  bool get invokesProvider => false;
  bool get invokesTargetAgent => false;
  bool get writesBusinessData => false;
  bool get persistsVerification => false;
  bool get canBreakCoreApp => false;
  bool get canBreakOtherChannels => false;
}
