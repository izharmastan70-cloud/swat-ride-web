import '../constants/agent_version_monitoring_constants.dart';
import '../models/agent_version_limited_rollout_eligibility.dart';
import '../models/agent_version_limited_rollout_observation.dart';
import '../models/agent_version_limited_rollout_plan.dart';
import '../models/agent_version_record.dart';
import '../models/agent_version_rollout_health_decision.dart';

class AgentVersionRolloutHealthMonitoringPolicy {
  const AgentVersionRolloutHealthMonitoringPolicy();

  AgentVersionRolloutHealthDecision evaluate({
    required AgentVersionRecord version,
    required AgentVersionLimitedRolloutEligibility eligibility,
    required AgentVersionLimitedRolloutPlan plan,
    required AgentVersionLimitedRolloutObservation observation,
    required DateTime evaluatedAtUtc,
  }) {
    try {
      version.validate();
      eligibility.validate();
      plan.validate();
      observation.validate();

      if (!evaluatedAtUtc.isUtc) {
        throw const FormatException('Evaluation time must be UTC.');
      }
    } catch (_) {
      return _decision(
        versionId: version.versionId,
        rolloutId: plan.rolloutId,
        status: AgentVersionRolloutHealthStatus.holdInvalidEvidence,
        reason: 'invalid_monitoring_evidence',
        ownerAlertRequired: false,
      );
    }

    if (!eligibility.eligible) {
      return _decision(
        versionId: version.versionId,
        rolloutId: plan.rolloutId,
        status: AgentVersionRolloutHealthStatus.holdInvalidEvidence,
        reason: 'limited_rollout_not_eligible',
        ownerAlertRequired: false,
      );
    }

    if (!_identityMatches(
      version: version,
      eligibility: eligibility,
      plan: plan,
      observation: observation,
    )) {
      return _decision(
        versionId: version.versionId,
        rolloutId: plan.rolloutId,
        status: AgentVersionRolloutHealthStatus.holdIdentityMismatch,
        reason: 'monitoring_identity_mismatch',
        ownerAlertRequired: false,
      );
    }

    if (observation.windowCompletedAtUtc.isAfter(
      evaluatedAtUtc.add(
        AgentVersionRolloutMonitoringPolicy.maximumFutureClockSkew,
      ),
    )) {
      return _decision(
        versionId: version.versionId,
        rolloutId: plan.rolloutId,
        status: AgentVersionRolloutHealthStatus.holdClockSkew,
        reason: 'monitoring_clock_skew',
        ownerAlertRequired: false,
      );
    }

    if (evaluatedAtUtc.difference(observation.windowCompletedAtUtc) >
        AgentVersionRolloutMonitoringPolicy.maximumObservationAge) {
      return _decision(
        versionId: version.versionId,
        rolloutId: plan.rolloutId,
        status: AgentVersionRolloutHealthStatus.holdStaleEvidence,
        reason: 'stale_monitoring_evidence',
        ownerAlertRequired: false,
      );
    }

    if (!observation.monitoringPipelineHealthy) {
      return _decision(
        versionId: version.versionId,
        rolloutId: plan.rolloutId,
        status: AgentVersionRolloutHealthStatus.holdInsufficientEvidence,
        reason: 'monitoring_pipeline_unhealthy',
        ownerAlertRequired: true,
      );
    }

    if (observation.criticalSafetySignal) {
      return _decision(
        versionId: version.versionId,
        rolloutId: plan.rolloutId,
        status: AgentVersionRolloutHealthStatus.rollbackRequestRequired,
        reason: _criticalReason(observation),
        ownerAlertRequired: true,
      );
    }

    if (observation.completedObservationCount <
        AgentVersionRolloutMonitoringPolicy
            .minimumHealthyCompletedObservations) {
      return _decision(
        versionId: version.versionId,
        rolloutId: plan.rolloutId,
        status: AgentVersionRolloutHealthStatus.holdInsufficientEvidence,
        reason: 'monitoring_sample_insufficient',
        ownerAlertRequired: false,
      );
    }

    if (observation.failedObservationCount > 0) {
      return _decision(
        versionId: version.versionId,
        rolloutId: plan.rolloutId,
        status: AgentVersionRolloutHealthStatus.rollbackRequestRequired,
        reason: 'limited_rollout_failure_detected',
        ownerAlertRequired: true,
      );
    }

    return _decision(
      versionId: version.versionId,
      rolloutId: plan.rolloutId,
      status: AgentVersionRolloutHealthStatus.healthy,
      reason: 'limited_rollout_health_clean',
      ownerAlertRequired: false,
    );
  }

  bool _identityMatches({
    required AgentVersionRecord version,
    required AgentVersionLimitedRolloutEligibility eligibility,
    required AgentVersionLimitedRolloutPlan plan,
    required AgentVersionLimitedRolloutObservation observation,
  }) {
    return eligibility.versionId == version.versionId &&
        eligibility.rolloutId == plan.rolloutId &&
        plan.versionId == version.versionId &&
        plan.agentId == version.agentId &&
        plan.artifactFingerprintSha256 == version.artifactFingerprintSha256 &&
        observation.rolloutId == plan.rolloutId &&
        observation.versionId == version.versionId &&
        observation.agentId == version.agentId &&
        observation.artifactFingerprintSha256 ==
            version.artifactFingerprintSha256 &&
        observation.rolloutScopeSha256 == plan.rolloutScopeSha256 &&
        observation.rolloutPercent == plan.requestedPercent;
  }

  String _criticalReason(AgentVersionLimitedRolloutObservation observation) {
    if (observation.criticalCrashCount > 0) {
      return 'critical_crash_detected';
    }
    if (observation.regressionDetected) {
      return 'behavior_regression_detected';
    }
    if (observation.safetyViolationCount > 0) {
      return 'safety_violation_detected';
    }
    if (observation.privacyViolationCount > 0) {
      return 'privacy_violation_detected';
    }
    if (observation.securityViolationCount > 0) {
      return 'security_violation_detected';
    }
    if (observation.permissionViolationCount > 0) {
      return 'permission_violation_detected';
    }
    if (observation.approvalBypassCount > 0) {
      return 'approval_bypass_detected';
    }
    if (observation.businessWriteViolationCount > 0) {
      return 'business_write_violation_detected';
    }
    return 'core_app_failure_isolation_broken';
  }

  AgentVersionRolloutHealthDecision _decision({
    required String versionId,
    required String rolloutId,
    required String status,
    required String reason,
    required bool ownerAlertRequired,
  }) {
    return AgentVersionRolloutHealthDecision(
      status: status,
      versionId: versionId,
      rolloutId: rolloutId,
      reasonCode: reason,
      ownerAlertRequired: ownerAlertRequired,
    );
  }

  bool get persistsObservation => false;
  bool get routesTraffic => false;
  bool get deploysVersion => false;
  bool get activatesProduction => false;
  bool get transitionsLifecycle => false;
  bool get executesRollback => false;
  bool get sendsOwnerAlert => false;
  bool get consumesApproval => false;
  bool get grantsPermission => false;
  bool get mutatesSecurity => false;
  bool get writesBusinessData => false;
}
