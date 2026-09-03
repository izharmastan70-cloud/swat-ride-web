import '../constants/agent_version_full_rollout_constants.dart';
import '../constants/agent_versioning_constants.dart';

class AgentVersionKnownGoodRollbackReadiness {
  AgentVersionKnownGoodRollbackReadiness({
    required this.readinessId,
    required this.readinessFingerprintSha256,
    required this.currentVersionId,
    required this.rollbackTargetVersionId,
    required this.rollbackTargetArtifactFingerprintSha256,
    required this.backupManifestId,
    required this.backupScopeSha256,
    required this.expectedRollbackScopeSha256,
    required this.backupVerified,
    required this.restoreValidationPassed,
    required this.securityBoundaryVerified,
    required this.coreAppIsolationVerified,
    required this.verifiedAtUtc,
  }) {
    validate();
  }

  final String readinessId;
  final String readinessFingerprintSha256;

  final String currentVersionId;
  final String rollbackTargetVersionId;
  final String rollbackTargetArtifactFingerprintSha256;

  final String backupManifestId;
  final String backupScopeSha256;
  final String expectedRollbackScopeSha256;

  final bool backupVerified;
  final bool restoreValidationPassed;
  final bool securityBoundaryVerified;
  final bool coreAppIsolationVerified;

  final DateTime verifiedAtUtc;

  bool get exactScopeMatched =>
      backupScopeSha256 == expectedRollbackScopeSha256;

  bool get technicallyReady =>
      backupVerified &&
      restoreValidationPassed &&
      securityBoundaryVerified &&
      coreAppIsolationVerified &&
      exactScopeMatched;

  bool get metadataOnly => true;
  bool get rawBackupContentsStored => false;
  bool get rawPromptStored => false;
  bool get privatePayloadStored => false;
  bool get secretsStored => false;

  bool get exactBackupRestorePerformed => false;
  bool get rollbackExecutionPerformed => false;
  bool get automaticRollbackPerformed => false;
  bool get deploymentPerformed => false;
  bool get productionActivationPerformed => false;
  bool get trafficRoutingPerformed => false;
  bool get lifecycleMutationPerformed => false;
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

    if (!safeId(readinessId) ||
        !safeId(currentVersionId) ||
        !safeId(rollbackTargetVersionId) ||
        !safeId(backupManifestId) ||
        !sha256Pattern.hasMatch(readinessFingerprintSha256) ||
        !sha256Pattern.hasMatch(rollbackTargetArtifactFingerprintSha256) ||
        !sha256Pattern.hasMatch(backupScopeSha256) ||
        !sha256Pattern.hasMatch(expectedRollbackScopeSha256) ||
        currentVersionId == rollbackTargetVersionId ||
        !verifiedAtUtc.isUtc) {
      throw const FormatException(
        'Invalid known-good rollback readiness metadata.',
      );
    }
  }
}

class AgentVersionKnownGoodRollbackReadinessDecision {
  const AgentVersionKnownGoodRollbackReadinessDecision({
    required this.status,
    required this.reasonCode,
  });

  final String status;
  final String reasonCode;

  bool get ready =>
      status == AgentVersionKnownGoodRollbackReadinessStatus.ready;

  bool get rollbackExecutionPerformed => false;
  bool get deploymentPerformed => false;
  bool get productionActivationPerformed => false;
  bool get trafficRoutingPerformed => false;
  bool get approvalConsumed => false;
  bool get permissionGranted => false;
  bool get businessWritePerformed => false;
}
