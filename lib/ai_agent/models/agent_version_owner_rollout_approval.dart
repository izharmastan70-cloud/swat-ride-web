import '../constants/agent_version_rollout_constants.dart';
import '../constants/agent_versioning_constants.dart';

class AgentVersionOwnerRolloutApproval {
  AgentVersionOwnerRolloutApproval({
    required this.approvalId,
    required this.versionId,
    required this.agentId,
    required this.artifactFingerprintSha256,
    required this.rolloutScopeSha256,
    required this.approvedByRole,
    required this.maximumRolloutPercent,
    required this.approvedAtUtc,
    required this.expiresAtUtc,
  }) {
    validate();
  }

  final String approvalId;
  final String versionId;
  final String agentId;
  final String artifactFingerprintSha256;
  final String rolloutScopeSha256;
  final String approvedByRole;
  final double maximumRolloutPercent;
  final DateTime approvedAtUtc;
  final DateTime expiresAtUtc;

  bool get explicitOwnerApproval => approvedByRole == 'OWNER';
  bool get metadataOnly => true;

  bool get approvalEngineConsumptionPerformed => false;
  bool get productionActivationAuthorized => false;
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
        !safeId(versionId) ||
        !safeId(agentId) ||
        !sha256Pattern.hasMatch(artifactFingerprintSha256) ||
        !sha256Pattern.hasMatch(rolloutScopeSha256) ||
        approvedByRole != 'OWNER' ||
        maximumRolloutPercent <= 0 ||
        maximumRolloutPercent >
            AgentVersionLimitedRolloutPolicy.maximumEligiblePercent ||
        !approvedAtUtc.isUtc ||
        !expiresAtUtc.isUtc ||
        !expiresAtUtc.isAfter(approvedAtUtc) ||
        validity >
            AgentVersionLimitedRolloutPolicy.maximumOwnerApprovalValidity) {
      throw const FormatException(
        'Invalid explicit Owner rollout approval metadata.',
      );
    }
  }
}
