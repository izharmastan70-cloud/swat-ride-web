import '../models/agent_evaluation_run.dart';
import '../models/agent_version_evaluation_binding.dart';
import '../models/agent_version_record.dart';

class AgentVersionEvaluationBindingService {
  const AgentVersionEvaluationBindingService();

  AgentVersionEvaluationBinding bind({
    required AgentVersionRecord version,
    required AgentEvaluationRun evaluationRun,
    required String evaluatedVersionId,
    required String evaluatedAgentId,
    required String evaluatedArtifactFingerprintSha256,
  }) {
    version.validate();
    evaluationRun.validate();

    if (evaluatedVersionId != version.versionId ||
        evaluatedAgentId != version.agentId ||
        evaluatedArtifactFingerprintSha256 !=
            version.artifactFingerprintSha256) {
      throw StateError(
        'Evaluation evidence does not match Agent version identity.',
      );
    }

    final AgentVersionEvaluationBinding binding = AgentVersionEvaluationBinding(
      versionId: version.versionId,
      agentId: version.agentId,
      artifactFingerprintSha256: version.artifactFingerprintSha256,
      evaluationRunId: evaluationRun.runId,
      catalogVersion: evaluationRun.catalogVersion,
      evaluatorVersion: evaluationRun.evaluatorVersion,
      policyVersion: evaluationRun.policyVersion,
      passPercent: evaluationRun.passPercent,
      weightedScorePercent: evaluationRun.weightedScorePercent,
      criticalFailureCount: evaluationRun.criticalFailureCount,
      safetyViolationCount: evaluationRun.safetyViolationCount,
      blockedCount: evaluationRun.blockedCount,
      thresholdPassed: evaluationRun.thresholdPassed,
      failClosed: evaluationRun.failClosed,
      eligibleForHumanReview: evaluationRun.eligibleForHumanReview,
      completedAtUtc: evaluationRun.completedAt.toUtc(),
    );

    binding.validate();
    return binding;
  }

  bool get copiesRawEvaluationResults => false;
  bool get persistsBinding => false;
  bool get callsProvider => false;
  bool get trainsModel => false;
  bool get mutatesPrompt => false;
  bool get deploysVersion => false;
  bool get activatesProduction => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get writesBusinessData => false;
}
