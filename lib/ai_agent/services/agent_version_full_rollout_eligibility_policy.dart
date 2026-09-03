import '../constants/agent_version_full_rollout_constants.dart';
import '../constants/agent_versioning_constants.dart';
import '../models/agent_version_full_rollout_eligibility.dart';
import '../models/agent_version_full_rollout_owner_approval.dart';
import '../models/agent_version_known_good_rollback_readiness.dart';
import '../models/agent_version_monitored_evidence_summary.dart';
import '../models/agent_version_record.dart';
import 'agent_version_known_good_rollback_readiness_policy.dart';

class AgentVersionFullRolloutEligibilityPolicy {
  const AgentVersionFullRolloutEligibilityPolicy({
    this.rollbackReadinessPolicy =
        const AgentVersionKnownGoodRollbackReadinessPolicy(),
  });

  final AgentVersionKnownGoodRollbackReadinessPolicy rollbackReadinessPolicy;

  AgentVersionFullRolloutEligibility evaluate({
    required AgentVersionRecord version,
    required AgentVersionMonitoredEvidenceSummary monitoring,
    required AgentVersionKnownGoodRollbackReadiness rollbackReadiness,
    required AgentVersionFullRolloutOwnerApproval ownerApproval,
    required DateTime evaluatedAtUtc,
  }) {
    try {
      version.validate();
      monitoring.validate();
      rollbackReadiness.validate();
      ownerApproval.validate();

      if (!evaluatedAtUtc.isUtc) {
        throw const FormatException('Evaluation time must be UTC.');
      }
    } catch (_) {
      return _decision(
        versionId: version.versionId,
        status: AgentVersionFullRolloutEligibilityStatus.blockedInvalidInput,
        reason: 'invalid_full_rollout_input',
      );
    }

    if (version.status != AgentVersionLifecycleStatus.monitored) {
      return _decision(
        versionId: version.versionId,
        status: AgentVersionFullRolloutEligibilityStatus.blockedVersionStatus,
        reason: 'version_not_monitored',
      );
    }

    if (!_monitoringIdentityMatches(version, monitoring)) {
      return _decision(
        versionId: version.versionId,
        status:
            AgentVersionFullRolloutEligibilityStatus.blockedIdentityMismatch,
        reason: 'monitoring_identity_mismatch',
      );
    }

    if (monitoring.completedAtUtc.isAfter(
      evaluatedAtUtc.add(AgentVersionFullRolloutPolicy.maximumFutureClockSkew),
    )) {
      return _decision(
        versionId: version.versionId,
        status: AgentVersionFullRolloutEligibilityStatus.blockedClockSkew,
        reason: 'monitoring_summary_clock_skew',
      );
    }

    if (evaluatedAtUtc.difference(monitoring.completedAtUtc) >
        AgentVersionFullRolloutPolicy.maximumMonitoringSummaryAge) {
      return _decision(
        versionId: version.versionId,
        status: AgentVersionFullRolloutEligibilityStatus.blockedMonitoring,
        reason: 'monitoring_summary_stale',
      );
    }

    if (!monitoring.cleanForFullRolloutEligibility) {
      return _decision(
        versionId: version.versionId,
        status: AgentVersionFullRolloutEligibilityStatus.blockedMonitoring,
        reason: _monitoringBlockReason(monitoring),
      );
    }

    final AgentVersionKnownGoodRollbackReadinessDecision rollbackDecision =
        rollbackReadinessPolicy.evaluate(
          currentVersion: version,
          readiness: rollbackReadiness,
          evaluatedAtUtc: evaluatedAtUtc,
        );

    if (!rollbackDecision.ready) {
      return _decision(
        versionId: version.versionId,
        status:
            AgentVersionFullRolloutEligibilityStatus.blockedRollbackReadiness,
        reason: rollbackDecision.reasonCode,
      );
    }

    if (!_approvalIdentityMatches(
      version: version,
      monitoring: monitoring,
      rollbackReadiness: rollbackReadiness,
      ownerApproval: ownerApproval,
    )) {
      return _decision(
        versionId: version.versionId,
        status: AgentVersionFullRolloutEligibilityStatus.blockedOwnerApproval,
        reason: 'full_rollout_owner_approval_mismatch',
      );
    }

    if (ownerApproval.approvedAtUtc.isAfter(
      evaluatedAtUtc.add(AgentVersionFullRolloutPolicy.maximumFutureClockSkew),
    )) {
      return _decision(
        versionId: version.versionId,
        status: AgentVersionFullRolloutEligibilityStatus.blockedClockSkew,
        reason: 'full_rollout_approval_clock_skew',
      );
    }

    if (!evaluatedAtUtc.isBefore(ownerApproval.expiresAtUtc)) {
      return _decision(
        versionId: version.versionId,
        status: AgentVersionFullRolloutEligibilityStatus.blockedApprovalExpired,
        reason: 'full_rollout_owner_approval_expired',
      );
    }

    if (!ownerApproval.explicitOwnerApproval ||
        !ownerApproval.separateFromLimitedRolloutApproval) {
      return _decision(
        versionId: version.versionId,
        status: AgentVersionFullRolloutEligibilityStatus.blockedOwnerApproval,
        reason: 'separate_explicit_owner_approval_required',
      );
    }

    return _decision(
      versionId: version.versionId,
      status: AgentVersionFullRolloutEligibilityStatus.eligible,
      reason: 'full_rollout_eligible_phase66_required',
    );
  }

  bool _monitoringIdentityMatches(
    AgentVersionRecord version,
    AgentVersionMonitoredEvidenceSummary monitoring,
  ) {
    return monitoring.versionId == version.versionId &&
        monitoring.agentId == version.agentId &&
        monitoring.artifactFingerprintSha256 ==
            version.artifactFingerprintSha256;
  }

  bool _approvalIdentityMatches({
    required AgentVersionRecord version,
    required AgentVersionMonitoredEvidenceSummary monitoring,
    required AgentVersionKnownGoodRollbackReadiness rollbackReadiness,
    required AgentVersionFullRolloutOwnerApproval ownerApproval,
  }) {
    return ownerApproval.versionId == version.versionId &&
        ownerApproval.agentId == version.agentId &&
        ownerApproval.artifactFingerprintSha256 ==
            version.artifactFingerprintSha256 &&
        ownerApproval.monitoringSummaryFingerprintSha256 ==
            monitoring.summaryFingerprintSha256 &&
        ownerApproval.rollbackReadinessFingerprintSha256 ==
            rollbackReadiness.readinessFingerprintSha256;
  }

  String _monitoringBlockReason(
    AgentVersionMonitoredEvidenceSummary monitoring,
  ) {
    if (!monitoring.sufficientEvidence) {
      return 'monitoring_evidence_insufficient';
    }
    if (monitoring.rollbackRequestCount > 0) {
      return 'rollback_request_present';
    }
    if (monitoring.holdWindowCount > 0) {
      return 'monitoring_hold_present';
    }
    if (monitoring.outstandingOwnerAlertCount > 0) {
      return 'owner_alert_outstanding';
    }
    if (!monitoring.monitoringPipelineHealthy) {
      return 'monitoring_pipeline_unhealthy';
    }
    return 'core_app_isolation_not_verified';
  }

  AgentVersionFullRolloutEligibility _decision({
    required String versionId,
    required String status,
    required String reason,
  }) {
    return AgentVersionFullRolloutEligibility(
      status: status,
      versionId: versionId,
      reasonCode: reason,
      phase66Required: true,
    );
  }

  bool get phase66Required => true;
  bool get persistsEligibility => false;
  bool get transitionsLifecycle => false;
  bool get routesTraffic => false;
  bool get deploysVersion => false;
  bool get activatesProduction => false;
  bool get authorizesAutoMode => false;
  bool get authorizesFullSafeAuto => false;
  bool get consumesApprovalEngineApproval => false;
  bool get grantsPermission => false;
  bool get overridesRuntimeGate => false;
  bool get overridesSecurity => false;
  bool get automaticKeepAllowed => false;
  bool get automaticRollbackAllowed => false;
  bool get writesBusinessData => false;
}
