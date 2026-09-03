import '../constants/agent_version_monitoring_constants.dart';

class AgentVersionRollbackTrigger {
  AgentVersionRollbackTrigger({
    required this.status,
    required this.currentVersionId,
    required this.rollbackTargetVersionId,
    required this.rolloutId,
    required this.reasonCode,
    required this.ownerAlertRequired,
  }) {
    validate();
  }

  final String status;
  final String currentVersionId;
  final String? rollbackTargetVersionId;
  final String rolloutId;
  final String reasonCode;
  final bool ownerAlertRequired;

  bool get required => status == AgentVersionRollbackTriggerStatus.required;

  bool get rollbackTargetKnown =>
      rollbackTargetVersionId != null &&
      rollbackTargetVersionId!.trim().isNotEmpty;

  bool get triggerOnly => true;
  bool get rollbackRequestedMetadataOnly => required;

  bool get exactBackupRestorePerformed => false;
  bool get rollbackExecutionPerformed => false;
  bool get lifecycleMutationPerformed => false;
  bool get persistencePerformed => false;
  bool get trafficRoutingPerformed => false;
  bool get deploymentPerformed => false;
  bool get productionActivationPerformed => false;
  bool get approvalConsumed => false;
  bool get permissionGranted => false;
  bool get ownerAlertSent => false;
  bool get automaticRollbackPerformed => false;
  bool get businessWritePerformed => false;

  void validate() {
    if (!AgentVersionRollbackTriggerStatus.values.contains(status) ||
        currentVersionId.trim().isEmpty ||
        rolloutId.trim().isEmpty ||
        reasonCode.trim().isEmpty) {
      throw const FormatException('Invalid Agent version rollback trigger.');
    }

    if (required && (!rollbackTargetKnown || !ownerAlertRequired)) {
      throw const FormatException(
        'Required rollback trigger needs known target and Owner alert.',
      );
    }
  }
}
