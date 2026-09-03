import '../constants/agent_versioning_constants.dart';

class AgentVersionLimitedRolloutObservation {
  AgentVersionLimitedRolloutObservation({
    required this.observationId,
    required this.rolloutId,
    required this.versionId,
    required this.agentId,
    required this.artifactFingerprintSha256,
    required this.rolloutScopeSha256,
    required this.rolloutPercent,
    required this.completedObservationCount,
    required this.successfulObservationCount,
    required this.failedObservationCount,
    required this.criticalCrashCount,
    required this.regressionDetected,
    required this.safetyViolationCount,
    required this.privacyViolationCount,
    required this.securityViolationCount,
    required this.permissionViolationCount,
    required this.approvalBypassCount,
    required this.businessWriteViolationCount,
    required this.coreAppIsolationVerified,
    required this.monitoringPipelineHealthy,
    required this.windowStartedAtUtc,
    required this.windowCompletedAtUtc,
  }) {
    validate();
  }

  final String observationId;
  final String rolloutId;
  final String versionId;
  final String agentId;
  final String artifactFingerprintSha256;
  final String rolloutScopeSha256;
  final double rolloutPercent;

  final int completedObservationCount;
  final int successfulObservationCount;
  final int failedObservationCount;

  final int criticalCrashCount;
  final bool regressionDetected;
  final int safetyViolationCount;
  final int privacyViolationCount;
  final int securityViolationCount;
  final int permissionViolationCount;
  final int approvalBypassCount;
  final int businessWriteViolationCount;

  final bool coreAppIsolationVerified;
  final bool monitoringPipelineHealthy;

  final DateTime windowStartedAtUtc;
  final DateTime windowCompletedAtUtc;

  bool get countsConsistent =>
      completedObservationCount ==
      successfulObservationCount + failedObservationCount;

  bool get criticalSafetySignal =>
      criticalCrashCount > 0 ||
      regressionDetected ||
      safetyViolationCount > 0 ||
      privacyViolationCount > 0 ||
      securityViolationCount > 0 ||
      permissionViolationCount > 0 ||
      approvalBypassCount > 0 ||
      businessWriteViolationCount > 0 ||
      !coreAppIsolationVerified;

  bool get metadataOnly => true;
  bool get rawPromptStored => false;
  bool get rawConversationStored => false;
  bool get privatePayloadStored => false;
  bool get secretsStored => false;
  bool get authTokenStored => false;
  bool get approvalTokenStored => false;
  bool get permissionTokenStored => false;

  bool get routesTraffic => false;
  bool get deploysVersion => false;
  bool get activatesProduction => false;
  bool get trainsModel => false;
  bool get mutatesPrompt => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get writesBusinessData => false;

  void validate() {
    final RegExp opaqueIdPattern = RegExp(r'^[A-Za-z0-9_.:-]+$');
    final RegExp sha256Pattern = RegExp(r'^[A-Fa-f0-9]{64}$');

    bool safeId(String value) =>
        value.isNotEmpty &&
        value == value.trim() &&
        value.length <= AgentVersionContract.opaqueIdMaxLength &&
        opaqueIdPattern.hasMatch(value);

    if (!safeId(observationId) ||
        !safeId(rolloutId) ||
        !safeId(versionId) ||
        !safeId(agentId) ||
        !sha256Pattern.hasMatch(artifactFingerprintSha256) ||
        !sha256Pattern.hasMatch(rolloutScopeSha256) ||
        rolloutPercent <= 0 ||
        rolloutPercent > 5 ||
        completedObservationCount < 0 ||
        successfulObservationCount < 0 ||
        failedObservationCount < 0 ||
        criticalCrashCount < 0 ||
        safetyViolationCount < 0 ||
        privacyViolationCount < 0 ||
        securityViolationCount < 0 ||
        permissionViolationCount < 0 ||
        approvalBypassCount < 0 ||
        businessWriteViolationCount < 0 ||
        !countsConsistent ||
        !windowStartedAtUtc.isUtc ||
        !windowCompletedAtUtc.isUtc ||
        windowCompletedAtUtc.isBefore(windowStartedAtUtc)) {
      throw const FormatException(
        'Invalid Agent version limited-rollout observation.',
      );
    }
  }
}
