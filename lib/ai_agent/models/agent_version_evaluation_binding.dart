import '../constants/agent_version_lifecycle_constants.dart';
import '../constants/agent_versioning_constants.dart';

class AgentVersionEvaluationBinding {
  AgentVersionEvaluationBinding({
    required this.versionId,
    required this.agentId,
    required this.artifactFingerprintSha256,
    required this.evaluationRunId,
    required this.catalogVersion,
    required this.evaluatorVersion,
    required this.policyVersion,
    required this.passPercent,
    required this.weightedScorePercent,
    required this.criticalFailureCount,
    required this.safetyViolationCount,
    required this.blockedCount,
    required this.thresholdPassed,
    required this.failClosed,
    required this.eligibleForHumanReview,
    required this.completedAtUtc,
  }) {
    validate();
  }

  final String versionId;
  final String agentId;
  final String artifactFingerprintSha256;

  final String evaluationRunId;
  final String catalogVersion;
  final String evaluatorVersion;
  final String policyVersion;

  final double passPercent;
  final double weightedScorePercent;
  final int criticalFailureCount;
  final int safetyViolationCount;
  final int blockedCount;

  final bool thresholdPassed;
  final bool failClosed;
  final bool eligibleForHumanReview;
  final DateTime completedAtUtc;

  bool get metadataOnly => true;
  bool get immutableEvidenceReference => true;
  bool get phase42EvidenceReused => true;

  bool get rawEvaluationResultsCopied => false;
  bool get rawPromptStored => false;
  bool get privateConversationStored => false;
  bool get secretsStored => false;
  bool get authTokenStored => false;
  bool get approvalTokenStored => false;
  bool get permissionTokenStored => false;

  bool get minimumScoresPassed =>
      passPercent >= AgentVersionEvaluationGate.minimumPassPercent &&
      weightedScorePercent >=
          AgentVersionEvaluationGate.minimumWeightedScorePercent;

  bool get cleanForOfflinePromotion =>
      thresholdPassed &&
      !failClosed &&
      eligibleForHumanReview &&
      blockedCount == 0 &&
      criticalFailureCount == 0 &&
      safetyViolationCount == 0 &&
      minimumScoresPassed;

  bool get deploymentAllowed => false;
  bool get productionActivationAllowed => false;
  bool get modelTrainingAllowed => false;
  bool get promptMutationAllowed => false;
  bool get permissionGrantAllowed => false;
  bool get approvalConsumptionAllowed => false;
  bool get businessWriteAllowed => false;

  void validate() {
    final RegExp opaqueIdPattern = RegExp(r'^[A-Za-z0-9_.:-]+$');
    final RegExp sha256Pattern = RegExp(r'^[A-Fa-f0-9]{64}$');

    bool safeId(String value) =>
        value.isNotEmpty &&
        value == value.trim() &&
        value.length <= AgentVersionContract.opaqueIdMaxLength &&
        opaqueIdPattern.hasMatch(value);

    if (!safeId(versionId) ||
        !safeId(agentId) ||
        !safeId(evaluationRunId) ||
        !safeId(catalogVersion) ||
        !safeId(evaluatorVersion) ||
        !safeId(policyVersion) ||
        !sha256Pattern.hasMatch(artifactFingerprintSha256) ||
        passPercent < 0 ||
        passPercent > 100 ||
        weightedScorePercent < 0 ||
        weightedScorePercent > 100 ||
        criticalFailureCount < 0 ||
        safetyViolationCount < 0 ||
        blockedCount < 0 ||
        !completedAtUtc.isUtc) {
      throw const FormatException('Invalid Agent version evaluation binding.');
    }
  }
}
