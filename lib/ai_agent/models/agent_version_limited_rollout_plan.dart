import '../constants/agent_version_rollout_constants.dart';
import '../constants/agent_versioning_constants.dart';

class AgentVersionLimitedRolloutPlan {
  AgentVersionLimitedRolloutPlan({
    required this.rolloutId,
    required this.versionId,
    required this.agentId,
    required this.artifactFingerprintSha256,
    required this.rolloutScopeSha256,
    required this.cohortId,
    required this.requestedPercent,
  }) {
    validate();
  }

  final String rolloutId;
  final String versionId;
  final String agentId;
  final String artifactFingerprintSha256;
  final String rolloutScopeSha256;
  final String cohortId;
  final double requestedPercent;

  bool get metadataOnly => true;
  bool get eligibilityPlanOnly => true;

  bool get rolloutExecutionPerformed => false;
  bool get productionTrafficRouted => false;
  bool get productionActivationPerformed => false;
  bool get deploymentPerformed => false;
  bool get automaticKeepPerformed => false;
  bool get automaticRollbackPerformed => false;

  void validate() {
    final RegExp opaqueIdPattern = RegExp(r'^[A-Za-z0-9_.:-]+$');
    final RegExp sha256Pattern = RegExp(r'^[A-Fa-f0-9]{64}$');

    bool safeId(String value) =>
        value.isNotEmpty &&
        value == value.trim() &&
        value.length <= AgentVersionContract.opaqueIdMaxLength &&
        opaqueIdPattern.hasMatch(value);

    if (!safeId(rolloutId) ||
        !safeId(versionId) ||
        !safeId(agentId) ||
        !safeId(cohortId) ||
        !sha256Pattern.hasMatch(artifactFingerprintSha256) ||
        !sha256Pattern.hasMatch(rolloutScopeSha256) ||
        requestedPercent <= 0 ||
        requestedPercent >
            AgentVersionLimitedRolloutPolicy.maximumEligiblePercent) {
      throw const FormatException('Invalid limited-rollout eligibility plan.');
    }
  }
}
