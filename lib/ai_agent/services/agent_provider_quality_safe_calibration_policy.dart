import '../constants/agent_provider_quality_evidence_constants.dart';
import '../models/agent_provider_quality_calibration_decision.dart';
import '../models/agent_provider_quality_evidence.dart';
import '../models/agent_provider_quality_evidence_batch.dart';
import 'agent_provider_quality_evidence_provenance_policy.dart';
import 'agent_provider_quality_outlier_poisoning_policy.dart';

class AgentProviderQualitySafeCalibrationPolicy {
  const AgentProviderQualitySafeCalibrationPolicy({
    this.provenancePolicy =
        const AgentProviderQualityEvidenceProvenancePolicy(),
    this.outlierPolicy = const AgentProviderQualityOutlierPoisoningPolicy(),
  });

  final AgentProviderQualityEvidenceProvenancePolicy provenancePolicy;
  final AgentProviderQualityOutlierPoisoningPolicy outlierPolicy;

  AgentProviderQualityCalibrationDecision calibrate({
    required AgentProviderQualityEvidenceBatch batch,
    required double referenceScore,
  }) {
    final double safeReference = referenceScore.clamp(0.0, 100.0).toDouble();

    try {
      batch.validateStructure();
    } catch (_) {
      return _decision(
        status: AgentProviderQualityCalibrationStatus.blockedPoisoningSuspected,
        referenceScore: safeReference,
        robustScore: safeReference,
        calibratedScore: safeReference,
        acceptedCount: 0,
        excludedCount: 0,
        poisoningSuspected: true,
        hardSafetyBlocked: false,
        reasons: const <String>[
          'invalid_or_duplicate_evidence_batch',
          'fail_closed',
        ],
      );
    }

    final List<AgentProviderQualityEvidence> acceptedProvenance = batch.evidence
        .where(
          (AgentProviderQualityEvidence value) =>
              provenancePolicy.evaluateEvidence(value) ==
              AgentProviderQualityEvidenceStatus.accepted,
        )
        .toList(growable: false);

    final bool hasHardSafety = acceptedProvenance.any(
      (AgentProviderQualityEvidence value) => value.hardSafetyViolation,
    );

    if (hasHardSafety) {
      return _decision(
        status: AgentProviderQualityCalibrationStatus.hardSafetyBlock,
        referenceScore: safeReference,
        robustScore: safeReference,
        calibratedScore: safeReference,
        acceptedCount: acceptedProvenance.length,
        excludedCount: 0,
        poisoningSuspected: false,
        hardSafetyBlocked: true,
        reasons: const <String>[
          'hard_safety_evidence_present',
          'hard_safety_never_removed_as_outlier',
          'numeric_calibration_cannot_soften_safety_failure',
          'fail_closed',
        ],
      );
    }

    final outlier = outlierPolicy.assess(batch);

    if (outlier.poisoningSuspected) {
      return _decision(
        status: AgentProviderQualityCalibrationStatus.blockedPoisoningSuspected,
        referenceScore: safeReference,
        robustScore: outlier.medianScore,
        calibratedScore: safeReference,
        acceptedCount: outlier.acceptedCount,
        excludedCount: outlier.excludedOutlierCount,
        poisoningSuspected: true,
        hardSafetyBlocked: false,
        reasons: const <String>[
          'outlier_or_duplicate_pattern_suggests_poisoning',
          'hold_existing_quality_score',
          'fail_closed',
        ],
      );
    }

    final Set<String> acceptedIds = outlier.acceptedObservationIds.toSet();

    final List<AgentProviderQualityEvidence> clean = acceptedProvenance
        .where(
          (AgentProviderQualityEvidence value) =>
              acceptedIds.contains(value.observationId),
        )
        .toList(growable: false);

    if (clean.length <
        AgentProviderQualityEvidencePolicyConfig.minCalibrationEvidence) {
      return _decision(
        status: AgentProviderQualityCalibrationStatus.insufficientEvidence,
        referenceScore: safeReference,
        robustScore: outlier.medianScore,
        calibratedScore: safeReference,
        acceptedCount: clean.length,
        excludedCount: outlier.excludedOutlierCount,
        poisoningSuspected: false,
        hardSafetyBlocked: false,
        reasons: const <String>[
          'insufficient_clean_evidence_after_provenance_outlier_checks',
          'hold_existing_quality_score',
        ],
      );
    }

    final double robustMean =
        clean
            .map((AgentProviderQualityEvidence value) => value.normalizedScore)
            .reduce((double a, double b) => a + b) /
        clean.length;

    final double rawShift = robustMean - safeReference;

    final double cappedShift = rawShift
        .clamp(
          -AgentProviderQualityEvidencePolicyConfig.maxCalibrationShiftPoints,
          AgentProviderQualityEvidencePolicyConfig.maxCalibrationShiftPoints,
        )
        .toDouble();

    final double calibrated = (safeReference + cappedShift)
        .clamp(0.0, 100.0)
        .toDouble();

    return _decision(
      status: AgentProviderQualityCalibrationStatus.calibrated,
      referenceScore: safeReference,
      robustScore: robustMean,
      calibratedScore: calibrated,
      acceptedCount: clean.length,
      excludedCount: outlier.excludedOutlierCount,
      poisoningSuspected: false,
      hardSafetyBlocked: false,
      reasons: const <String>[
        'trusted_privacy_safe_deduplicated_evidence',
        'numeric_outliers_excluded',
        'calibration_shift_capped',
        'quality_recommendation_metadata_only',
      ],
    );
  }

  AgentProviderQualityCalibrationDecision _decision({
    required String status,
    required double referenceScore,
    required double robustScore,
    required double calibratedScore,
    required int acceptedCount,
    required int excludedCount,
    required bool poisoningSuspected,
    required bool hardSafetyBlocked,
    required List<String> reasons,
  }) {
    final AgentProviderQualityCalibrationDecision result =
        AgentProviderQualityCalibrationDecision(
          status: status,
          referenceScore: referenceScore,
          robustEvidenceScore: robustScore.clamp(0.0, 100.0).toDouble(),
          calibratedScore: calibratedScore.clamp(0.0, 100.0).toDouble(),
          shiftPoints: calibratedScore - referenceScore,
          acceptedEvidenceCount: acceptedCount,
          excludedOutlierCount: excludedCount,
          poisoningSuspected: poisoningSuspected,
          hardSafetyBlocked: hardSafetyBlocked,
          reasonCodes: reasons,
        );

    result.validateStructure();
    return result;
  }

  bool get trustedProvenanceRequired => true;
  bool get deduplicationRequired => true;
  bool get privacySafeMetadataRequired => true;
  bool get outlierResistanceRequired => true;
  bool get hardSafetyNeverFiltered => true;
  bool get calibrationShiftCapped => true;
  bool get poisoningFailsClosed => true;
  bool get insufficientEvidenceHoldsReferenceScore => true;

  bool get freeLocalPaidOrderStillAuthoritative => true;
  bool get paidControlsStillAuthoritative => true;
  bool get privacyCapabilityCircuitBackendStillAuthoritative => true;

  bool get providerInvocationImplementedHere => false;
  bool get automaticRoutingMutationImplementedHere => false;
  bool get providerEnableDisableImplementedHere => false;
  bool get budgetMutationImplementedHere => false;
  bool get secretMutationImplementedHere => false;
  bool get deploymentImplementedHere => false;
  bool get persistenceImplementedHere => false;

  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get expandsScope => false;
  bool get executesBusinessAction => false;

  bool get phase60CrossAgentSupervisorSeparate => true;
  bool get phase61PerformanceDashboardSeparate => true;
  bool get phase62VersioningDeploymentSeparate => true;
  bool get phase63PrivacyRetentionSeparate => true;
}
