import '../constants/agent_versioning_constants.dart';

class AgentVersionTestEnvironmentEvidence {
  AgentVersionTestEnvironmentEvidence({
    required this.evidenceId,
    required this.versionId,
    required this.agentId,
    required this.artifactFingerprintSha256,
    required this.evaluationRunId,
    required this.environmentId,
    required this.buildPassed,
    required this.analyzePassed,
    required this.targetedTestsPassed,
    required this.fullRegressionPassed,
    required this.securityBoundaryPassed,
    required this.failureIsolationPassed,
    required this.syntheticOrApprovedNonPrivateDataOnly,
    required this.productionTrafficUsed,
    required this.providerExecutionUsed,
    required this.coreAppIsolationVerified,
    required this.startedAtUtc,
    required this.completedAtUtc,
  }) {
    validate();
  }

  final String evidenceId;
  final String versionId;
  final String agentId;
  final String artifactFingerprintSha256;
  final String evaluationRunId;
  final String environmentId;

  final bool buildPassed;
  final bool analyzePassed;
  final bool targetedTestsPassed;
  final bool fullRegressionPassed;
  final bool securityBoundaryPassed;
  final bool failureIsolationPassed;

  final bool syntheticOrApprovedNonPrivateDataOnly;
  final bool productionTrafficUsed;
  final bool providerExecutionUsed;
  final bool coreAppIsolationVerified;

  final DateTime startedAtUtc;
  final DateTime completedAtUtc;

  bool get allTechnicalChecksPassed =>
      buildPassed &&
      analyzePassed &&
      targetedTestsPassed &&
      fullRegressionPassed &&
      securityBoundaryPassed &&
      failureIsolationPassed &&
      coreAppIsolationVerified;

  bool get privacySafe =>
      syntheticOrApprovedNonPrivateDataOnly &&
      !productionTrafficUsed &&
      !providerExecutionUsed;

  bool get metadataOnly => true;
  bool get rawPromptStored => false;
  bool get privateConversationStored => false;
  bool get secretsStored => false;
  bool get authTokenStored => false;
  bool get approvalTokenStored => false;
  bool get permissionTokenStored => false;

  bool get deploysVersion => false;
  bool get activatesProduction => false;
  bool get routesProductionTraffic => false;
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

    if (!safeId(evidenceId) ||
        !safeId(versionId) ||
        !safeId(agentId) ||
        !safeId(evaluationRunId) ||
        !safeId(environmentId) ||
        !sha256Pattern.hasMatch(artifactFingerprintSha256) ||
        !startedAtUtc.isUtc ||
        !completedAtUtc.isUtc ||
        completedAtUtc.isBefore(startedAtUtc)) {
      throw const FormatException(
        'Invalid Agent version test-environment evidence.',
      );
    }
  }
}
