import '../constants/agent_version_full_rollout_constants.dart';
import '../constants/agent_versioning_constants.dart';

class AgentVersionFullRolloutOwnerApproval {
  AgentVersionFullRolloutOwnerApproval({
    required this.approvalId,
    required this.limitedRolloutApprovalId,
    required this.versionId,
    required this.agentId,
    required this.artifactFingerprintSha256,
    required this.monitoringSummaryFingerprintSha256,
    required this.rollbackReadinessFingerprintSha256,
    required this.approvedByRole,
    required this.approvedAtUtc,
    required this.expiresAtUtc,
  }) {
    validate();
  }

  final String approvalId;
  final String limitedRolloutApprovalId;

  final String versionId;
  final String agentId;
  final String artifactFingerprintSha256;

  final String monitoringSummaryFingerprintSha256;
  final String rollbackReadinessFingerprintSha256;

  final String approvedByRole;
  final DateTime approvedAtUtc;
  final DateTime expiresAtUtc;

  bool get explicitOwnerApproval => approvedByRole == 'OWNER';

  bool get separateFromLimitedRolloutApproval =>
      approvalId != limitedRolloutApprovalId;

  bool get metadataOnly => true;

  bool get approvalEngineConsumptionPerformed => false;
  bool get phase66ProductionActivationAuthorized => false;
  bool get autoModeAuthorized => false;
  bool get productionTrafficRoutingAuthorized => false;
  bool get deploymentAuthorized => false;
  bool get automaticKeepAuthorized => false;
  bool get automaticRollbackAuthorized => false;
  bool get permissionGrantAuthorized => false;
  bool get securityOverrideAuthorized => false;

  void validate() {
    final RegExp opaqueIdPattern = RegExp(r'^[A-Za-z0-9_.:-]+$');
    final RegExp sha256Pattern = RegExp(r'^[A-Fa-f0-9]{64}$');

    bool safeId(String value) =>
        value.isNotEmpty &&
        value == value.trim() &&
        value.length <= AgentVersionContract.opaqueIdMaxLength &&
        opaqueIdPattern.hasMatch(value);

    final Duration validity = expiresAtUtc.difference(approvedAtUtc);

    if (!safeId(approvalId) ||
        !safeId(limitedRolloutApprovalId) ||
        !safeId(versionId) ||
        !safeId(agentId) ||
        !sha256Pattern.hasMatch(artifactFingerprintSha256) ||
        !sha256Pattern.hasMatch(monitoringSummaryFingerprintSha256) ||
        !sha256Pattern.hasMatch(rollbackReadinessFingerprintSha256) ||
        approvedByRole != 'OWNER' ||
        !separateFromLimitedRolloutApproval ||
        !approvedAtUtc.isUtc ||
        !expiresAtUtc.isUtc ||
        !expiresAtUtc.isAfter(approvedAtUtc) ||
        validity > AgentVersionFullRolloutPolicy.maximumOwnerApprovalValidity) {
      throw const FormatException(
        'Invalid separate Owner full-rollout approval metadata.',
      );
    }
  }
}
