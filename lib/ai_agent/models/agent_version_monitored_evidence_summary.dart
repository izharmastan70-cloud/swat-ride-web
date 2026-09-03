import '../constants/agent_version_full_rollout_constants.dart';
import '../constants/agent_versioning_constants.dart';

class AgentVersionMonitoredEvidenceSummary {
  AgentVersionMonitoredEvidenceSummary({
    required this.summaryId,
    required this.summaryFingerprintSha256,
    required this.versionId,
    required this.agentId,
    required this.artifactFingerprintSha256,
    required this.rolloutId,
    required this.rolloutScopeSha256,
    required this.limitedRolloutPercent,
    required this.healthyWindowCount,
    required this.totalCompletedObservationCount,
    required this.rollbackRequestCount,
    required this.holdWindowCount,
    required this.outstandingOwnerAlertCount,
    required this.monitoringPipelineHealthy,
    required this.coreAppIsolationVerified,
    required this.completedAtUtc,
  }) {
    validate();
  }

  final String summaryId;
  final String summaryFingerprintSha256;

  final String versionId;
  final String agentId;
  final String artifactFingerprintSha256;

  final String rolloutId;
  final String rolloutScopeSha256;
  final double limitedRolloutPercent;

  final int healthyWindowCount;
  final int totalCompletedObservationCount;
  final int rollbackRequestCount;
  final int holdWindowCount;
  final int outstandingOwnerAlertCount;

  final bool monitoringPipelineHealthy;
  final bool coreAppIsolationVerified;

  final DateTime completedAtUtc;

  bool get sufficientEvidence =>
      healthyWindowCount >=
          AgentVersionFullRolloutPolicy.minimumHealthyMonitoringWindows &&
      totalCompletedObservationCount >=
          AgentVersionFullRolloutPolicy.minimumCompletedObservations;

  bool get cleanForFullRolloutEligibility =>
      sufficientEvidence &&
      rollbackRequestCount == 0 &&
      holdWindowCount == 0 &&
      outstandingOwnerAlertCount == 0 &&
      monitoringPipelineHealthy &&
      coreAppIsolationVerified;

  bool get metadataOnly => true;
  bool get rawPromptStored => false;
  bool get rawConversationStored => false;
  bool get privatePayloadStored => false;
  bool get secretsStored => false;
  bool get tokensStored => false;

  bool get lifecycleTransitionPerformed => false;
  bool get trafficRoutingPerformed => false;
  bool get deploymentPerformed => false;
  bool get productionActivationPerformed => false;
  bool get autoModeAuthorized => false;
  bool get approvalConsumed => false;
  bool get permissionGranted => false;
  bool get businessWritePerformed => false;

  void validate() {
    final RegExp opaqueIdPattern = RegExp(r'^[A-Za-z0-9_.:-]+$');
    final RegExp sha256Pattern = RegExp(r'^[A-Fa-f0-9]{64}$');

    bool safeId(String value) =>
        value.isNotEmpty &&
        value == value.trim() &&
        value.length <= AgentVersionContract.opaqueIdMaxLength &&
        opaqueIdPattern.hasMatch(value);

    if (!safeId(summaryId) ||
        !safeId(versionId) ||
        !safeId(agentId) ||
        !safeId(rolloutId) ||
        !sha256Pattern.hasMatch(summaryFingerprintSha256) ||
        !sha256Pattern.hasMatch(artifactFingerprintSha256) ||
        !sha256Pattern.hasMatch(rolloutScopeSha256) ||
        limitedRolloutPercent <= 0 ||
        limitedRolloutPercent > 5 ||
        healthyWindowCount < 0 ||
        totalCompletedObservationCount < 0 ||
        rollbackRequestCount < 0 ||
        holdWindowCount < 0 ||
        outstandingOwnerAlertCount < 0 ||
        !completedAtUtc.isUtc) {
      throw const FormatException(
        'Invalid monitored Agent version evidence summary.',
      );
    }
  }
}
