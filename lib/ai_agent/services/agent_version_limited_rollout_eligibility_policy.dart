import '../constants/agent_version_rollout_constants.dart';
import '../constants/agent_versioning_constants.dart';
import '../models/agent_version_limited_rollout_eligibility.dart';
import '../models/agent_version_limited_rollout_plan.dart';
import '../models/agent_version_owner_rollout_approval.dart';
import '../models/agent_version_record.dart';
import '../models/agent_version_test_environment_evidence.dart';
import 'agent_version_test_environment_readiness_policy.dart';

class AgentVersionLimitedRolloutEligibilityPolicy {
  const AgentVersionLimitedRolloutEligibilityPolicy({
    this.testReadinessPolicy =
        const AgentVersionTestEnvironmentReadinessPolicy(),
  });

  final AgentVersionTestEnvironmentReadinessPolicy testReadinessPolicy;

  AgentVersionLimitedRolloutEligibility evaluate({
    required AgentVersionRecord version,
    required AgentVersionTestEnvironmentEvidence testEvidence,
    required AgentVersionOwnerRolloutApproval ownerApproval,
    required AgentVersionLimitedRolloutPlan plan,
    required DateTime evaluatedAtUtc,
  }) {
    try {
      version.validate();
      testEvidence.validate();
      ownerApproval.validate();
      plan.validate();

      if (!evaluatedAtUtc.isUtc) {
        throw const FormatException('Evaluation time must be UTC.');
      }
    } catch (_) {
      return _decision(
        versionId: version.versionId,
        rolloutId: plan.rolloutId,
        requestedPercent: plan.requestedPercent,
        status: AgentVersionLimitedRolloutEligibilityStatus.blockedInvalidInput,
        reason: 'invalid_limited_rollout_input',
      );
    }

    if (version.status != AgentVersionLifecycleStatus.testReady) {
      return _decision(
        versionId: version.versionId,
        rolloutId: plan.rolloutId,
        requestedPercent: plan.requestedPercent,
        status:
            AgentVersionLimitedRolloutEligibilityStatus.blockedVersionStatus,
        reason: 'version_not_test_ready',
      );
    }

    final AgentVersionTestEnvironmentReadinessDecision testDecision =
        testReadinessPolicy.evaluate(
          version: version,
          evidence: testEvidence,
          evaluatedAtUtc: evaluatedAtUtc,
        );

    if (!testDecision.ready) {
      return _decision(
        versionId: version.versionId,
        rolloutId: plan.rolloutId,
        requestedPercent: plan.requestedPercent,
        status:
            AgentVersionLimitedRolloutEligibilityStatus.blockedTestEnvironment,
        reason: testDecision.reasonCode,
      );
    }

    if (!_sameVersionIdentity(
      version: version,
      ownerApproval: ownerApproval,
      plan: plan,
    )) {
      return _decision(
        versionId: version.versionId,
        rolloutId: plan.rolloutId,
        requestedPercent: plan.requestedPercent,
        status:
            AgentVersionLimitedRolloutEligibilityStatus.blockedOwnerApproval,
        reason: 'owner_approval_version_identity_mismatch',
      );
    }

    if (ownerApproval.approvedAtUtc.isAfter(
      evaluatedAtUtc.add(
        AgentVersionTestEnvironmentPolicy.maximumFutureClockSkew,
      ),
    )) {
      return _decision(
        versionId: version.versionId,
        rolloutId: plan.rolloutId,
        requestedPercent: plan.requestedPercent,
        status: AgentVersionLimitedRolloutEligibilityStatus.blockedClockSkew,
        reason: 'owner_approval_clock_skew',
      );
    }

    if (!evaluatedAtUtc.isBefore(ownerApproval.expiresAtUtc)) {
      return _decision(
        versionId: version.versionId,
        rolloutId: plan.rolloutId,
        requestedPercent: plan.requestedPercent,
        status:
            AgentVersionLimitedRolloutEligibilityStatus.blockedApprovalExpired,
        reason: 'owner_approval_expired',
      );
    }

    if (!ownerApproval.explicitOwnerApproval) {
      return _decision(
        versionId: version.versionId,
        rolloutId: plan.rolloutId,
        requestedPercent: plan.requestedPercent,
        status:
            AgentVersionLimitedRolloutEligibilityStatus.blockedOwnerApproval,
        reason: 'explicit_owner_approval_required',
      );
    }

    if (ownerApproval.rolloutScopeSha256 != plan.rolloutScopeSha256) {
      return _decision(
        versionId: version.versionId,
        rolloutId: plan.rolloutId,
        requestedPercent: plan.requestedPercent,
        status:
            AgentVersionLimitedRolloutEligibilityStatus.blockedScopeMismatch,
        reason: 'rollout_scope_mismatch',
      );
    }

    if (plan.requestedPercent > ownerApproval.maximumRolloutPercent ||
        plan.requestedPercent >
            AgentVersionLimitedRolloutPolicy.maximumEligiblePercent) {
      return _decision(
        versionId: version.versionId,
        rolloutId: plan.rolloutId,
        requestedPercent: plan.requestedPercent,
        status: AgentVersionLimitedRolloutEligibilityStatus.blockedPercent,
        reason: 'limited_rollout_percent_not_approved',
      );
    }

    return _decision(
      versionId: version.versionId,
      rolloutId: plan.rolloutId,
      requestedPercent: plan.requestedPercent,
      status: AgentVersionLimitedRolloutEligibilityStatus.eligible,
      reason: 'limited_rollout_eligible_not_executed',
    );
  }

  bool _sameVersionIdentity({
    required AgentVersionRecord version,
    required AgentVersionOwnerRolloutApproval ownerApproval,
    required AgentVersionLimitedRolloutPlan plan,
  }) {
    return ownerApproval.versionId == version.versionId &&
        ownerApproval.agentId == version.agentId &&
        ownerApproval.artifactFingerprintSha256 ==
            version.artifactFingerprintSha256 &&
        plan.versionId == version.versionId &&
        plan.agentId == version.agentId &&
        plan.artifactFingerprintSha256 == version.artifactFingerprintSha256;
  }

  AgentVersionLimitedRolloutEligibility _decision({
    required String versionId,
    required String rolloutId,
    required double requestedPercent,
    required String status,
    required String reason,
  }) {
    return AgentVersionLimitedRolloutEligibility(
      status: status,
      versionId: versionId,
      rolloutId: rolloutId,
      requestedPercent: requestedPercent,
      reasonCode: reason,
    );
  }

  bool get persistsEligibility => false;
  bool get consumesApprovalEngineApproval => false;
  bool get routesProductionTraffic => false;
  bool get executesRollout => false;
  bool get deploysVersion => false;
  bool get activatesProduction => false;
  bool get automaticKeepAllowed => false;
  bool get automaticRollbackAllowed => false;
  bool get trainsModel => false;
  bool get mutatesPrompt => false;
  bool get grantsPermission => false;
  bool get mutatesSecurity => false;
  bool get writesBusinessData => false;
}
