import '../constants/agent_guardian_observability_constants.dart';
import '../models/agent_guardian_authoritative_gate_handoff.dart';
import '../models/agent_guardian_monitoring_assessment.dart';
import '../models/agent_guardian_security_observability_snapshot.dart';
import '../models/agent_guardian_security_policy_envelope.dart';

class AgentGuardianObservabilityService {
  const AgentGuardianObservabilityService();

  AgentGuardianMonitoringAssessment assess({
    required String assessmentId,
    required AgentGuardianAuthoritativeGateHandoff handoff,
    required AgentGuardianSecurityObservabilitySnapshot snapshot,
    required DateTime generatedAt,
  }) {
    try {
      snapshot.validateStructure();
    } on AgentGuardianSecurityObservabilitySnapshotException {
      return _failClosed(
        assessmentId: assessmentId,
        handoff: handoff,
        snapshotId: snapshot.snapshotId,
        generatedAt: generatedAt,
        reasonCodes: const <String>[
          AgentGuardianMonitoringReason.invalidObservabilitySnapshot,
          AgentGuardianMonitoringReason.authoritativeChecksStillPending,
          AgentGuardianMonitoringReason.safeEvidenceOnly,
        ],
        humanReviewRequired: true,
      );
    }

    try {
      handoff.envelope.validateStructure();
    } on AgentGuardianSecurityPolicyEnvelopeException {
      return _failClosed(
        assessmentId: assessmentId,
        handoff: handoff,
        snapshotId: snapshot.snapshotId,
        generatedAt: generatedAt,
        reasonCodes: const <String>[
          AgentGuardianMonitoringReason.policyEnvelopeBlocked,
          AgentGuardianMonitoringReason.authoritativeChecksStillPending,
          AgentGuardianMonitoringReason.safeEvidenceOnly,
        ],
        humanReviewRequired: true,
      );
    }

    if (handoff.blocked || handoff.envelope.blocked) {
      return _failClosed(
        assessmentId: assessmentId,
        handoff: handoff,
        snapshotId: snapshot.snapshotId,
        generatedAt: generatedAt,
        reasonCodes: <String>[
          if (handoff.blocked)
            AgentGuardianMonitoringReason.policyHandoffBlocked,
          if (handoff.envelope.blocked)
            AgentGuardianMonitoringReason.policyEnvelopeBlocked,
          AgentGuardianMonitoringReason.authoritativeChecksStillPending,
          AgentGuardianMonitoringReason.safeEvidenceOnly,
        ],
        humanReviewRequired: true,
      );
    }

    final List<String> reasons = <String>[
      AgentGuardianMonitoringReason.authoritativeChecksStillPending,
      AgentGuardianMonitoringReason.safeEvidenceOnly,
    ];

    final List<String> unhealthyRequiredControls = <String>[];
    final List<String> unknownRequiredControls = <String>[];

    _assessRequiredControl(
      required: handoff.permissionEngineRequired,
      healthy: snapshot.permissionEngineHealthy,
      controlId: 'permission_engine',
      unhealthyReason:
          AgentGuardianMonitoringReason.requiredPermissionEngineUnhealthy,
      unknownReason:
          AgentGuardianMonitoringReason.requiredPermissionEngineUnknown,
      reasons: reasons,
      unhealthyRequiredControls: unhealthyRequiredControls,
      unknownRequiredControls: unknownRequiredControls,
    );

    _assessRequiredControl(
      required: handoff.approvalEngineRequired,
      healthy: snapshot.approvalEngineHealthy,
      controlId: 'approval_engine',
      unhealthyReason:
          AgentGuardianMonitoringReason.requiredApprovalEngineUnhealthy,
      unknownReason:
          AgentGuardianMonitoringReason.requiredApprovalEngineUnknown,
      reasons: reasons,
      unhealthyRequiredControls: unhealthyRequiredControls,
      unknownRequiredControls: unknownRequiredControls,
    );

    _assessRequiredControl(
      required: handoff.runtimeGateRequired,
      healthy: snapshot.runtimeGateHealthy,
      controlId: 'runtime_gate',
      unhealthyReason:
          AgentGuardianMonitoringReason.requiredRuntimeGateUnhealthy,
      unknownReason: AgentGuardianMonitoringReason.requiredRuntimeGateUnknown,
      reasons: reasons,
      unhealthyRequiredControls: unhealthyRequiredControls,
      unknownRequiredControls: unknownRequiredControls,
    );

    _assessRequiredControl(
      required: handoff.emergencySecurityReviewRequired,
      healthy: snapshot.emergencySecurityReviewHealthy,
      controlId: 'emergency_security_review',
      unhealthyReason:
          AgentGuardianMonitoringReason.requiredEmergencyReviewUnhealthy,
      unknownReason:
          AgentGuardianMonitoringReason.requiredEmergencyReviewUnknown,
      reasons: reasons,
      unhealthyRequiredControls: unhealthyRequiredControls,
      unknownRequiredControls: unknownRequiredControls,
    );

    _assessRequiredControl(
      required: handoff.humanSecurityReviewRequired,
      healthy: snapshot.humanSecurityReviewAvailable,
      controlId: 'human_security_review',
      unhealthyReason:
          AgentGuardianMonitoringReason.requiredHumanReviewUnavailable,
      unknownReason: AgentGuardianMonitoringReason.requiredHumanReviewUnknown,
      reasons: reasons,
      unhealthyRequiredControls: unhealthyRequiredControls,
      unknownRequiredControls: unknownRequiredControls,
    );

    final bool requiredControlFailure =
        unhealthyRequiredControls.isNotEmpty ||
        unknownRequiredControls.isNotEmpty;

    if (requiredControlFailure) {
      return AgentGuardianMonitoringAssessment(
        status: AgentGuardianMonitoringStatus.failClosedRecommended,
        assessmentId: assessmentId,
        snapshotId: snapshot.snapshotId,
        handoffId: handoff.handoffId,
        envelopeId: handoff.envelope.envelopeId,
        correlationId: handoff.envelope.correlationId,
        pseudonymousSubjectRef: handoff.envelope.pseudonymousSubjectRef,
        severity: handoff.envelope.severity,
        failClosedRecommended: true,
        humanSecurityReviewRequired: true,
        authoritativeChecksStillPending: true,
        reasonCodes: reasons,
        unhealthyRequiredControls: unhealthyRequiredControls,
        unknownRequiredControls: unknownRequiredControls,
        generatedAt: generatedAt,
      );
    }

    final bool nonRequiredDegraded = _hasNonRequiredDegradation(
      handoff: handoff,
      snapshot: snapshot,
    );

    if (nonRequiredDegraded) {
      reasons.add(AgentGuardianMonitoringReason.nonRequiredControlDegraded);
    }

    return AgentGuardianMonitoringAssessment(
      status: nonRequiredDegraded
          ? AgentGuardianMonitoringStatus.degraded
          : AgentGuardianMonitoringStatus.healthy,
      assessmentId: assessmentId,
      snapshotId: snapshot.snapshotId,
      handoffId: handoff.handoffId,
      envelopeId: handoff.envelope.envelopeId,
      correlationId: handoff.envelope.correlationId,
      pseudonymousSubjectRef: handoff.envelope.pseudonymousSubjectRef,
      severity: handoff.envelope.severity,
      failClosedRecommended: false,
      humanSecurityReviewRequired: handoff.humanSecurityReviewRequired,
      authoritativeChecksStillPending: true,
      reasonCodes: reasons,
      unhealthyRequiredControls: const <String>[],
      unknownRequiredControls: const <String>[],
      generatedAt: generatedAt,
    );
  }

  void _assessRequiredControl({
    required bool required,
    required bool? healthy,
    required String controlId,
    required String unhealthyReason,
    required String unknownReason,
    required List<String> reasons,
    required List<String> unhealthyRequiredControls,
    required List<String> unknownRequiredControls,
  }) {
    if (!required) {
      return;
    }

    if (healthy == false) {
      unhealthyRequiredControls.add(controlId);
      reasons.add(unhealthyReason);
      return;
    }

    if (healthy == null) {
      unknownRequiredControls.add(controlId);
      reasons.add(unknownReason);
    }
  }

  bool _hasNonRequiredDegradation({
    required AgentGuardianAuthoritativeGateHandoff handoff,
    required AgentGuardianSecurityObservabilitySnapshot snapshot,
  }) {
    final List<(bool required, bool? healthy)> controls = <(bool, bool?)>[
      (handoff.permissionEngineRequired, snapshot.permissionEngineHealthy),
      (handoff.approvalEngineRequired, snapshot.approvalEngineHealthy),
      (handoff.runtimeGateRequired, snapshot.runtimeGateHealthy),
      (
        handoff.emergencySecurityReviewRequired,
        snapshot.emergencySecurityReviewHealthy,
      ),
      (
        handoff.humanSecurityReviewRequired,
        snapshot.humanSecurityReviewAvailable,
      ),
    ];

    return controls.any(
      ((bool required, bool? healthy) entry) => !entry.$1 && entry.$2 == false,
    );
  }

  AgentGuardianMonitoringAssessment _failClosed({
    required String assessmentId,
    required AgentGuardianAuthoritativeGateHandoff handoff,
    required String snapshotId,
    required DateTime generatedAt,
    required List<String> reasonCodes,
    required bool humanReviewRequired,
  }) {
    return AgentGuardianMonitoringAssessment(
      status: AgentGuardianMonitoringStatus.failClosedRecommended,
      assessmentId: assessmentId,
      snapshotId: snapshotId,
      handoffId: handoff.handoffId,
      envelopeId: handoff.envelope.envelopeId,
      correlationId: handoff.envelope.correlationId,
      pseudonymousSubjectRef: handoff.envelope.pseudonymousSubjectRef,
      severity: handoff.envelope.severity,
      failClosedRecommended: true,
      humanSecurityReviewRequired: humanReviewRequired,
      authoritativeChecksStillPending: true,
      reasonCodes: reasonCodes,
      unhealthyRequiredControls: const <String>[],
      unknownRequiredControls: const <String>[],
      generatedAt: generatedAt,
    );
  }

  bool get recommendationOnly => true;
  bool get safeEvidenceOnly => true;
  bool get guardianIsFinalEnforcer => false;
  bool get invokesPermissionEngine => false;
  bool get invokesApprovalEngine => false;
  bool get invokesRuntimeGate => false;
  bool get invokesEmergencyStop => false;
  bool get bypassesPermissionEngine => false;
  bool get bypassesApprovalEngine => false;
  bool get bypassesRuntimeGate => false;
  bool get bypassesEmergencyStop => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get marksRuntimeAllowed => false;
  bool get executesBlock => false;
  bool get executesEscalation => false;
  bool get createsIncident => false;
  bool get implementsIncidentResponse => false;
  bool get writesAuditPersistence => false;
  bool get invokesSecurityAuditService => false;
  bool get mutatesSecurityControls => false;
  bool get invokesProvider => false;
  bool get invokesTargetAgent => false;
  bool get writesBusinessData => false;
  bool get persistsSnapshotOrAssessment => false;
}
