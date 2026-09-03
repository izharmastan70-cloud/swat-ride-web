import '../constants/agent_production_rollout_snapshot_constants.dart';

class AgentProductionRolloutOwnerApproval {
  AgentProductionRolloutOwnerApproval({
    required this.approvalId,
    required this.ownerReferenceSha256,
    required this.snapshotFingerprintSha256,
    required this.requestedStage,
    required this.approvedAtUtc,
    required this.expiresAtUtc,
    required this.explicitOwnerApproval,
  }) {
    validate();
  }

  final String approvalId;

  /// Hashed Owner reference only; no raw identity/token stored here.
  final String ownerReferenceSha256;

  final String snapshotFingerprintSha256;
  final String requestedStage;
  final DateTime approvedAtUtc;
  final DateTime expiresAtUtc;
  final bool explicitOwnerApproval;

  bool get metadataOnly => true;
  bool get approvalEngineConsumptionPerformed => false;
  bool get permissionGranted => false;
  bool get runtimeGateOverridden => false;
  bool get rolloutActivated => false;
  bool get agentModeChanged => false;

  bool bindsSnapshot(String fingerprintSha256) =>
      snapshotFingerprintSha256 == fingerprintSha256.trim();

  void validate() {
    final RegExp sha256 = RegExp(r'^[A-Fa-f0-9]{64}$');

    if (approvalId.trim().isEmpty ||
        !sha256.hasMatch(ownerReferenceSha256) ||
        !sha256.hasMatch(snapshotFingerprintSha256) ||
        requestedStage != AgentProductionRolloutStage.monitorOnly ||
        !approvedAtUtc.isUtc ||
        !expiresAtUtc.isUtc ||
        !expiresAtUtc.isAfter(approvedAtUtc) ||
        expiresAtUtc.difference(approvedAtUtc) >
            AgentProductionRolloutSnapshotLimits.ownerApprovalMaxValidity ||
        !explicitOwnerApproval) {
      throw const FormatException(
        'Invalid production rollout Owner approval binding.',
      );
    }
  }
}
