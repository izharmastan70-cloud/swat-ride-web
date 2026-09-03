import '../constants/agent_versioning_closeout_constants.dart';

class AgentVersioningFinalReadinessReport {
  AgentVersioningFinalReadinessReport({
    required this.contractVersion,
    required this.status,
    required this.reasonCode,
  }) {
    validate();
  }

  final String contractVersion;
  final String status;
  final String reasonCode;

  bool get foundationReadyNotProductionActive =>
      status ==
      AgentVersioningCloseoutContract.foundationReadyNotProductionActive;

  bool get phase66Required => true;

  bool get productionActive => false;
  bool get deploymentPerformed => false;
  bool get productionActivationPerformed => false;
  bool get autoModeAuthorized => false;
  bool get fullSafeAutoAuthorized => false;

  bool get modelTrainingPerformed => false;
  bool get promptMutationPerformed => false;
  bool get rollbackExecutionPerformed => false;
  bool get exactBackupRestorePerformed => false;

  bool get approvalConsumed => false;
  bool get permissionGranted => false;
  bool get runtimeGateOverridden => false;
  bool get securityOverridden => false;
  bool get businessWritePerformed => false;

  bool get coreAppCanContinue => true;

  void validate() {
    if (contractVersion != AgentVersioningCloseoutContract.contractVersion ||
        !AgentVersioningCloseoutContract.statuses.contains(status) ||
        reasonCode.trim().isEmpty) {
      throw const FormatException('Invalid Phase 62 final readiness report.');
    }
  }
}
