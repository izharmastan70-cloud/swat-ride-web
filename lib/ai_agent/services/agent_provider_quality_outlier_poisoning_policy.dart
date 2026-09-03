import '../constants/agent_provider_quality_evidence_constants.dart';
import '../models/agent_provider_quality_evidence.dart';
import '../models/agent_provider_quality_evidence_batch.dart';
import '../models/agent_provider_quality_outlier_assessment.dart';
import 'agent_provider_quality_evidence_provenance_policy.dart';

class AgentProviderQualityOutlierPoisoningPolicy {
  const AgentProviderQualityOutlierPoisoningPolicy({
    this.provenancePolicy =
        const AgentProviderQualityEvidenceProvenancePolicy(),
  });

  final AgentProviderQualityEvidenceProvenancePolicy provenancePolicy;

  AgentProviderQualityOutlierAssessment assess(
    AgentProviderQualityEvidenceBatch batch,
  ) {
    try {
      batch.validateStructure();
    } catch (_) {
      return AgentProviderQualityOutlierAssessment(
        medianScore: 0,
        acceptedObservationIds: const <String>[],
        excludedOutlierObservationIds: const <String>[],
        hardSafetyObservationIds: const <String>[],
        poisoningSuspected: true,
      );
    }

    final List<AgentProviderQualityEvidence> trusted = batch.evidence
        .where(
          (AgentProviderQualityEvidence value) =>
              provenancePolicy.evaluateEvidence(value) ==
              AgentProviderQualityEvidenceStatus.accepted,
        )
        .toList(growable: false);

    if (trusted.isEmpty) {
      return AgentProviderQualityOutlierAssessment(
        medianScore: 0,
        acceptedObservationIds: const <String>[],
        excludedOutlierObservationIds: const <String>[],
        hardSafetyObservationIds: const <String>[],
        poisoningSuspected: true,
      );
    }

    final List<double> sortedScores =
        trusted
            .map((AgentProviderQualityEvidence value) => value.normalizedScore)
            .toList(growable: false)
          ..sort();

    final double median = _median(sortedScores);

    final List<String> accepted = <String>[];
    final List<String> excluded = <String>[];
    final List<String> hardSafety = <String>[];

    for (final AgentProviderQualityEvidence value in trusted) {
      if (value.hardSafetyViolation) {
        hardSafety.add(value.observationId);
        accepted.add(value.observationId);
        continue;
      }

      final double distance = (value.normalizedScore - median).abs();

      if (distance >
          AgentProviderQualityEvidencePolicyConfig.outlierDistancePoints) {
        excluded.add(value.observationId);
      } else {
        accepted.add(value.observationId);
      }
    }

    final double outlierShare = trusted.isEmpty
        ? 1
        : excluded.length / trusted.length;

    final bool poisoningSuspected =
        !provenancePolicy.batchPassesDeduplication(batch) ||
        outlierShare > AgentProviderQualityEvidencePolicyConfig.maxOutlierShare;

    final AgentProviderQualityOutlierAssessment result =
        AgentProviderQualityOutlierAssessment(
          medianScore: median,
          acceptedObservationIds: accepted,
          excludedOutlierObservationIds: excluded,
          hardSafetyObservationIds: hardSafety,
          poisoningSuspected: poisoningSuspected,
        );

    result.validateStructure();
    return result;
  }

  double _median(List<double> values) {
    final int middle = values.length ~/ 2;

    if (values.length.isOdd) {
      return values[middle];
    }

    return (values[middle - 1] + values[middle]) / 2;
  }

  bool get medianBasedOutlierDetection => true;
  bool get hardSafetyEvidenceNeverExcludedAsOutlier => true;
  bool get poisoningShareFailsClosed => true;
  bool get deduplicationRequiredBeforeCalibration => true;
  bool get insufficientCleanEvidenceCannotCalibrate => true;

  bool get providerInvocationImplementedHere => false;
  bool get routingMutationImplementedHere => false;
  bool get providerStateMutationImplementedHere => false;
  bool get budgetMutationImplementedHere => false;
  bool get persistenceImplementedHere => false;
  bool get executesBusinessAction => false;
}
