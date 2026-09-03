import '../constants/agent_version_monitoring_constants.dart';

class AgentVersionRolloutHealthDecision {
  AgentVersionRolloutHealthDecision({
    required this.status,
    required this.versionId,
    required this.rolloutId,
    required this.reasonCode,
    required this.ownerAlertRequired,
  }) {
    validate();
  }

  final String status;
  final String versionId;
  final String rolloutId;
  final String reasonCode;
  final bool ownerAlertRequired;

  bool get healthy => status == AgentVersionRolloutHealthStatus.healthy;

  bool get rollbackRequestRequired =>
      status == AgentVersionRolloutHealthStatus.rollbackRequestRequired;

  bool get eligibleForMonitoredLifecycle => healthy && !ownerAlertRequired;

  bool get lifecycleTransitionPerformed => false;
  bool get versionRecordMutated => false;
  bool get persistencePerformed => false;
  bool get trafficRoutingPerformed => false;
  bool get deploymentPerformed => false;
  bool get productionActivationPerformed => false;
  bool get rollbackExecutionPerformed => false;
  bool get ownerAlertSent => false;
  bool get approvalConsumed => false;
  bool get permissionGranted => false;
  bool get businessWritePerformed => false;
  bool get securityAuthorityPreserved => true;

  void validate() {
    if (!AgentVersionRolloutHealthStatus.values.contains(status) ||
        versionId.trim().isEmpty ||
        rolloutId.trim().isEmpty ||
        reasonCode.trim().isEmpty) {
      throw const FormatException(
        'Invalid Agent version rollout health decision.',
      );
    }

    if (rollbackRequestRequired && !ownerAlertRequired) {
      throw const FormatException('Rollback request must require Owner alert.');
    }
  }
}
