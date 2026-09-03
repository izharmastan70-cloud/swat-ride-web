import '../constants/agent_version_rollout_constants.dart';

class AgentVersionLimitedRolloutEligibility {
  AgentVersionLimitedRolloutEligibility({
    required this.status,
    required this.versionId,
    required this.rolloutId,
    required this.requestedPercent,
    required this.reasonCode,
  }) {
    validate();
  }

  final String status;
  final String versionId;
  final String rolloutId;
  final double requestedPercent;
  final String reasonCode;

  bool get eligible =>
      status == AgentVersionLimitedRolloutEligibilityStatus.eligible;

  bool get eligibleForLifecycleLimitedRolloutReady => eligible;

  bool get transitionPerformed => false;
  bool get versionRecordMutated => false;
  bool get persistencePerformed => false;
  bool get rolloutExecutionPerformed => false;
  bool get productionTrafficRouted => false;
  bool get deploymentPerformed => false;
  bool get productionActivationPerformed => false;
  bool get approvalConsumed => false;
  bool get permissionGranted => false;
  bool get securityOverridePerformed => false;
  bool get businessWritePerformed => false;
  bool get securityAuthorityPreserved => true;

  void validate() {
    if (!AgentVersionLimitedRolloutEligibilityStatus.values.contains(status) ||
        versionId.trim().isEmpty ||
        rolloutId.trim().isEmpty ||
        requestedPercent < 0 ||
        requestedPercent >
            AgentVersionLimitedRolloutPolicy.maximumEligiblePercent ||
        reasonCode.trim().isEmpty) {
      throw const FormatException(
        'Invalid Agent version limited-rollout eligibility.',
      );
    }
  }
}
