import '../constants/agent_version_full_rollout_constants.dart';

class AgentVersionFullRolloutEligibility {
  AgentVersionFullRolloutEligibility({
    required this.status,
    required this.versionId,
    required this.reasonCode,
    required this.phase66Required,
  }) {
    validate();
  }

  final String status;
  final String versionId;
  final String reasonCode;
  final bool phase66Required;

  bool get eligible =>
      status == AgentVersionFullRolloutEligibilityStatus.eligible;

  bool get eligibleForLifecycleFullRolloutEligible => eligible;

  bool get foundationReadyNotProductionActive => eligible && phase66Required;

  bool get lifecycleTransitionPerformed => false;
  bool get versionRecordMutated => false;
  bool get persistencePerformed => false;
  bool get trafficRoutingPerformed => false;
  bool get deploymentPerformed => false;
  bool get productionActivationPerformed => false;
  bool get autoModeAuthorized => false;
  bool get fullSafeAutoAuthorized => false;
  bool get approvalConsumed => false;
  bool get permissionGranted => false;
  bool get securityOverridePerformed => false;
  bool get automaticKeepPerformed => false;
  bool get automaticRollbackPerformed => false;
  bool get businessWritePerformed => false;
  bool get securityAuthorityPreserved => true;

  void validate() {
    if (!AgentVersionFullRolloutEligibilityStatus.values.contains(status) ||
        versionId.trim().isEmpty ||
        reasonCode.trim().isEmpty) {
      throw const FormatException(
        'Invalid Agent version full-rollout eligibility.',
      );
    }

    if (eligible && !phase66Required) {
      throw const FormatException(
        'Full-rollout eligibility cannot bypass Phase 66.',
      );
    }
  }
}
