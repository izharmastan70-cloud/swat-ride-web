import '../models/agent_call_training_evidence.dart';
import '../models/agent_call_training_release_candidate.dart';
import 'agent_call_training_evidence_builder.dart';

class AgentCallTrainingReleaseCandidateGate {
  const AgentCallTrainingReleaseCandidateGate({
    this.evidenceBuilder = const AgentCallTrainingEvidenceBuilder(),
  });

  final AgentCallTrainingEvidenceBuilder evidenceBuilder;

  AgentCallTrainingReleaseCandidateDecision evaluateCoreCandidate({
    required DateTime evaluatedAt,
  }) {
    final AgentCallTrainingEvidence evidence = evidenceBuilder
        .buildCoreEvidence(recordedAt: evaluatedAt);

    return evaluateEvidence(evidence: evidence, evaluatedAt: evaluatedAt);
  }

  AgentCallTrainingReleaseCandidateDecision evaluateEvidence({
    required AgentCallTrainingEvidence evidence,
    required DateTime evaluatedAt,
  }) {
    evidence.validate();

    final bool eligible = evidence.technicalEvidencePassed;

    final AgentCallTrainingReleaseCandidateDecision decision =
        AgentCallTrainingReleaseCandidateDecision(
          status: eligible
              ? AgentCallTrainingReleaseCandidateStatus.eligibleForHumanReview
              : AgentCallTrainingReleaseCandidateStatus.blocked,
          reason: eligible
              ? 'Technical Call-training evidence passed. '
                    'Candidate is eligible for explicit human review only; '
                    'no approval, training, prompt change, deployment, or '
                    'production activation is implied.'
              : 'Technical Call-training evidence is incomplete or failed. '
                    'Candidate remains blocked and cannot proceed to human '
                    'release review.',
          evidence: evidence,
          evaluatedAt: evaluatedAt.toUtc(),
        );

    decision.validate();
    return decision;
  }

  bool get humanReviewRequired => true;
  bool get autoApprovalAllowed => false;
  bool get providerExecutionAllowed => false;
  bool get runtimeActionAllowed => false;
  bool get productionDataAccessAllowed => false;
  bool get businessWriteAllowed => false;
  bool get approvalConsumptionAllowed => false;
  bool get permissionGrantAllowed => false;
  bool get promptMutationAllowed => false;
  bool get modelTrainingAllowed => false;
  bool get deploymentAllowed => false;
  bool get productionActivationAllowed => false;
}
