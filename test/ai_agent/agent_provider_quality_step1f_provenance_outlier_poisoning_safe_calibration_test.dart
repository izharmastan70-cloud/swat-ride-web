import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_provider_expansion_contract_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_provider_quality_evidence_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_provider_quality_signal_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_provider_quality_evidence.dart';
import 'package:swat_ride/ai_agent/models/agent_provider_quality_evidence_batch.dart';
import 'package:swat_ride/ai_agent/services/agent_provider_quality_evidence_provenance_policy.dart';
import 'package:swat_ride/ai_agent/services/agent_provider_quality_outlier_poisoning_policy.dart';
import 'package:swat_ride/ai_agent/services/agent_provider_quality_safe_calibration_policy.dart';

void main() {
  const AgentProviderQualityEvidenceProvenancePolicy provenancePolicy =
      AgentProviderQualityEvidenceProvenancePolicy();

  const AgentProviderQualityOutlierPoisoningPolicy outlierPolicy =
      AgentProviderQualityOutlierPoisoningPolicy();

  const AgentProviderQualitySafeCalibrationPolicy calibrationPolicy =
      AgentProviderQualitySafeCalibrationPolicy();

  AgentProviderQualityEvidence evidence(
    int index,
    double score, {
    String observationIdPrefix = 'obs',
    String idempotencyPrefix = 'idem',
    bool trusted = true,
    bool privacySafe = true,
    bool hardSafety = false,
    String providerId = 'provider:free:a',
    String modelReference = 'model:a',
    String taskType = 'GENERAL_REASONING',
    String family = AgentProviderQualitySignalFamily.reliability,
  }) {
    return AgentProviderQualityEvidence(
      observationId: '$observationIdPrefix:$index',
      idempotencyKey: '$idempotencyPrefix:$index',
      provenanceReference: 'prov:$index',
      evaluatorVersionReference: 'evaluator:v1',
      providerId: providerId,
      modelReference: modelReference,
      providerTier: AgentProviderExpansionTier.freeOnline,
      taskType: taskType,
      family: family,
      source: AgentProviderQualitySignalSource.trustedBackendObserved,
      normalizedScore: score,
      ageHours: 24,
      trustedObservation: trusted,
      privacySafeMetadata: privacySafe,
      hardSafetyViolation: hardSafety,
    );
  }

  AgentProviderQualityEvidenceBatch batch(
    List<double> scores, {
    bool hardSafetyLast = false,
  }) {
    return AgentProviderQualityEvidenceBatch(
      evidence: <AgentProviderQualityEvidence>[
        for (int i = 0; i < scores.length; i++)
          evidence(
            i,
            scores[i],
            hardSafety: hardSafetyLast && i == scores.length - 1,
          ),
      ],
    );
  }

  group('Phase 59 Step 1F provenance/outlier/calibration', () {
    test('5 evidence statuses are locked', () {
      expect(AgentProviderQualityEvidenceStatus.values.length, 5);
    });

    test('4 calibration statuses are locked', () {
      expect(AgentProviderQualityCalibrationStatus.values.length, 4);
    });

    test('trusted privacy-safe evidence is accepted', () {
      expect(
        provenancePolicy.evaluateEvidence(evidence(0, 90)),
        AgentProviderQualityEvidenceStatus.accepted,
      );
    });

    test('untrusted evidence is rejected', () {
      expect(
        provenancePolicy.evaluateEvidence(evidence(0, 90, trusted: false)),
        AgentProviderQualityEvidenceStatus.rejectedUntrusted,
      );
    });

    test('privacy-unsafe evidence is rejected', () {
      expect(
        provenancePolicy.evaluateEvidence(evidence(0, 90, privacySafe: false)),
        AgentProviderQualityEvidenceStatus.rejectedPrivacyUnsafe,
      );
    });

    test('duplicate observation id is rejected by batch', () {
      final value = AgentProviderQualityEvidenceBatch(
        evidence: <AgentProviderQualityEvidence>[
          evidence(0, 90),
          evidence(1, 91, observationIdPrefix: 'obs:0:dup'),
        ],
      );

      // Force exact duplicate with an explicit second record.
      final duplicate = AgentProviderQualityEvidenceBatch(
        evidence: <AgentProviderQualityEvidence>[
          evidence(0, 90),
          AgentProviderQualityEvidence(
            observationId: 'obs:0',
            idempotencyKey: 'idem:other',
            provenanceReference: 'prov:other',
            evaluatorVersionReference: 'evaluator:v1',
            providerId: 'provider:free:a',
            modelReference: 'model:a',
            providerTier: AgentProviderExpansionTier.freeOnline,
            taskType: 'GENERAL_REASONING',
            family: AgentProviderQualitySignalFamily.reliability,
            source: AgentProviderQualitySignalSource.trustedBackendObserved,
            normalizedScore: 91,
            ageHours: 24,
            trustedObservation: true,
            privacySafeMetadata: true,
            hardSafetyViolation: false,
          ),
        ],
      );

      expect(value.hasDuplicateObservationId, false);
      expect(duplicate.hasDuplicateObservationId, true);
      expect(duplicate.validateStructure, throwsFormatException);
    });

    test('duplicate idempotency key is rejected', () {
      final duplicate = AgentProviderQualityEvidenceBatch(
        evidence: <AgentProviderQualityEvidence>[
          evidence(0, 90),
          AgentProviderQualityEvidence(
            observationId: 'obs:other',
            idempotencyKey: 'idem:0',
            provenanceReference: 'prov:other',
            evaluatorVersionReference: 'evaluator:v1',
            providerId: 'provider:free:a',
            modelReference: 'model:a',
            providerTier: AgentProviderExpansionTier.freeOnline,
            taskType: 'GENERAL_REASONING',
            family: AgentProviderQualitySignalFamily.reliability,
            source: AgentProviderQualitySignalSource.trustedBackendObserved,
            normalizedScore: 91,
            ageHours: 24,
            trustedObservation: true,
            privacySafeMetadata: true,
            hardSafetyViolation: false,
          ),
        ],
      );

      expect(duplicate.hasDuplicateIdempotencyKey, true);
      expect(duplicate.validateStructure, throwsFormatException);
    });

    test('mixed provider/model/task/family binding is rejected', () {
      final mixed = AgentProviderQualityEvidenceBatch(
        evidence: <AgentProviderQualityEvidence>[
          evidence(0, 90),
          evidence(1, 91, providerId: 'provider:free:b'),
        ],
      );

      expect(mixed.validateStructure, throwsFormatException);
    });

    test('single extreme numeric outlier is excluded', () {
      final result = outlierPolicy.assess(batch(<double>[90, 91, 89, 90, 10]));

      expect(result.medianScore, 90);
      expect(result.excludedOutlierCount, 1);
      expect(result.acceptedCount, 4);
      expect(result.poisoningSuspected, false);
    });

    test('hard safety evidence is never removed as outlier', () {
      final result = outlierPolicy.assess(
        batch(<double>[90, 91, 89, 90, 5], hardSafetyLast: true),
      );

      expect(result.hardSafetyObservationIds, contains('obs:4'));
      expect(result.excludedOutlierObservationIds, isNot(contains('obs:4')));
      expect(result.hardSafetyCanBeExcludedAsOutlier, false);
    });

    test('excessive outlier share is poisoning suspected', () {
      final result = outlierPolicy.assess(
        batch(<double>[90, 90, 90, 10, 10, 10, 10]),
      );

      expect(result.poisoningSuspected, true);
    });

    test('clean evidence calibrates score', () {
      final result = calibrationPolicy.calibrate(
        batch: batch(<double>[82, 83, 84, 85]),
        referenceScore: 80,
      );

      expect(result.status, AgentProviderQualityCalibrationStatus.calibrated);
      expect(result.calibratedScore, greaterThan(80));
      expect(result.calibratedScore, lessThanOrEqualTo(85));
    });

    test('upward calibration shift is capped to 5 points', () {
      final result = calibrationPolicy.calibrate(
        batch: batch(<double>[100, 100, 100, 100]),
        referenceScore: 70,
      );

      expect(result.calibratedScore, 75);
      expect(result.shiftPoints, 5);
    });

    test('downward calibration shift is capped to 5 points', () {
      final result = calibrationPolicy.calibrate(
        batch: batch(<double>[50, 50, 50, 50]),
        referenceScore: 90,
      );

      expect(result.calibratedScore, 85);
      expect(result.shiftPoints, -5);
    });

    test('insufficient clean evidence holds reference score', () {
      final result = calibrationPolicy.calibrate(
        batch: batch(<double>[90, 91, 10]),
        referenceScore: 80,
      );

      expect(
        result.status,
        AgentProviderQualityCalibrationStatus.insufficientEvidence,
      );
      expect(result.calibratedScore, 80);
    });

    test('hard safety evidence blocks numeric calibration', () {
      final result = calibrationPolicy.calibrate(
        batch: batch(<double>[95, 95, 95, 5], hardSafetyLast: true),
        referenceScore: 90,
      );

      expect(
        result.status,
        AgentProviderQualityCalibrationStatus.hardSafetyBlock,
      );
      expect(result.hardSafetyBlocked, true);
      expect(result.calibratedScore, 90);
    });

    test('poisoning suspected holds reference score', () {
      final result = calibrationPolicy.calibrate(
        batch: batch(<double>[90, 90, 90, 10, 10, 10, 10]),
        referenceScore: 80,
      );

      expect(
        result.status,
        AgentProviderQualityCalibrationStatus.blockedPoisoningSuspected,
      );
      expect(result.poisoningSuspected, true);
      expect(result.calibratedScore, 80);
    });

    test('evidence contains no raw payload and no authority', () {
      final value = evidence(0, 90);

      expect(value.containsRawPrompt, false);
      expect(value.containsRawConversation, false);
      expect(value.containsRawProviderResponse, false);
      expect(value.containsPrivatePayload, false);
      expect(value.containsApiSecret, false);
      expect(value.containsAuthToken, false);

      expect(value.invokesProvider, false);
      expect(value.mutatesRouting, false);
      expect(value.changesProviderState, false);
      expect(value.mutatesBudget, false);
      expect(value.changesSecret, false);
      expect(value.deploysModel, false);
      expect(value.persistsEvidence, false);
      expect(value.grantsPermission, false);
      expect(value.consumesApproval, false);
      expect(value.executesBusinessAction, false);
    });

    test('provenance policy locks anti-replay/privacy rules', () {
      expect(provenancePolicy.opaqueProvenanceRequired, true);
      expect(provenancePolicy.evaluatorVersionReferenceRequired, true);
      expect(provenancePolicy.idempotencyKeyRequired, true);
      expect(provenancePolicy.duplicateObservationRejected, true);
      expect(provenancePolicy.duplicateIdempotencyRejected, true);
      expect(provenancePolicy.trustedObservationRequired, true);
      expect(provenancePolicy.privacySafeMetadataRequired, true);
      expect(provenancePolicy.rawPromptForbidden, true);
      expect(provenancePolicy.rawConversationForbidden, true);
      expect(provenancePolicy.rawProviderResponseForbidden, true);
      expect(provenancePolicy.privatePayloadForbidden, true);
    });

    test('outlier policy locks poisoning safety', () {
      expect(outlierPolicy.medianBasedOutlierDetection, true);
      expect(outlierPolicy.hardSafetyEvidenceNeverExcludedAsOutlier, true);
      expect(outlierPolicy.poisoningShareFailsClosed, true);
      expect(outlierPolicy.deduplicationRequiredBeforeCalibration, true);
      expect(outlierPolicy.insufficientCleanEvidenceCannotCalibrate, true);
    });

    test('calibration policy keeps authoritative gates', () {
      expect(calibrationPolicy.trustedProvenanceRequired, true);
      expect(calibrationPolicy.deduplicationRequired, true);
      expect(calibrationPolicy.privacySafeMetadataRequired, true);
      expect(calibrationPolicy.outlierResistanceRequired, true);
      expect(calibrationPolicy.hardSafetyNeverFiltered, true);
      expect(calibrationPolicy.calibrationShiftCapped, true);
      expect(calibrationPolicy.poisoningFailsClosed, true);
      expect(calibrationPolicy.insufficientEvidenceHoldsReferenceScore, true);

      expect(calibrationPolicy.freeLocalPaidOrderStillAuthoritative, true);
      expect(calibrationPolicy.paidControlsStillAuthoritative, true);
      expect(
        calibrationPolicy.privacyCapabilityCircuitBackendStillAuthoritative,
        true,
      );
    });

    test('calibration decision has no execution authority', () {
      final result = calibrationPolicy.calibrate(
        batch: batch(<double>[82, 83, 84, 85]),
        referenceScore: 80,
      );

      expect(result.recommendationMetadataOnly, true);
      expect(result.mayInvokeProvider, false);
      expect(result.mayMutateRouting, false);
      expect(result.mayEnableProvider, false);
      expect(result.mayDisableProvider, false);
      expect(result.mayMutateBudget, false);
      expect(result.mayChangeSecret, false);
      expect(result.mayDeployModel, false);
      expect(result.mayGrantPermission, false);
      expect(result.mayConsumeApproval, false);
      expect(result.mayExecuteBusinessAction, false);
      expect(result.persistsDecision, false);
    });

    test('policies add no provider/write/business authority', () {
      expect(provenancePolicy.providerInvocationImplementedHere, false);
      expect(provenancePolicy.routingMutationImplementedHere, false);
      expect(provenancePolicy.providerStateMutationImplementedHere, false);
      expect(provenancePolicy.budgetMutationImplementedHere, false);
      expect(provenancePolicy.persistenceImplementedHere, false);
      expect(provenancePolicy.executesBusinessAction, false);

      expect(outlierPolicy.providerInvocationImplementedHere, false);
      expect(outlierPolicy.routingMutationImplementedHere, false);
      expect(outlierPolicy.providerStateMutationImplementedHere, false);
      expect(outlierPolicy.budgetMutationImplementedHere, false);
      expect(outlierPolicy.persistenceImplementedHere, false);
      expect(outlierPolicy.executesBusinessAction, false);

      expect(calibrationPolicy.providerInvocationImplementedHere, false);
      expect(calibrationPolicy.automaticRoutingMutationImplementedHere, false);
      expect(calibrationPolicy.providerEnableDisableImplementedHere, false);
      expect(calibrationPolicy.budgetMutationImplementedHere, false);
      expect(calibrationPolicy.secretMutationImplementedHere, false);
      expect(calibrationPolicy.deploymentImplementedHere, false);
      expect(calibrationPolicy.persistenceImplementedHere, false);
      expect(calibrationPolicy.grantsPermission, false);
      expect(calibrationPolicy.consumesApproval, false);
      expect(calibrationPolicy.expandsScope, false);
      expect(calibrationPolicy.executesBusinessAction, false);
    });

    test('later phase ownership remains separate', () {
      expect(calibrationPolicy.phase60CrossAgentSupervisorSeparate, true);
      expect(calibrationPolicy.phase61PerformanceDashboardSeparate, true);
      expect(calibrationPolicy.phase62VersioningDeploymentSeparate, true);
      expect(calibrationPolicy.phase63PrivacyRetentionSeparate, true);
    });
  });
}
