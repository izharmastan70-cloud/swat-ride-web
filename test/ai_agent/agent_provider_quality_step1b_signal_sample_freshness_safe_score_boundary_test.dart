import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_provider_expansion_contract_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_provider_quality_signal_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_provider_quality_signal.dart';
import 'package:swat_ride/ai_agent/services/agent_provider_quality_score_boundary_policy.dart';
import 'package:swat_ride/ai_agent/services/agent_provider_quality_signal_policy.dart';

void main() {
  const AgentProviderQualitySignalPolicy signalPolicy =
      AgentProviderQualitySignalPolicy();

  const AgentProviderQualityScoreBoundaryPolicy scorePolicy =
      AgentProviderQualityScoreBoundaryPolicy();

  AgentProviderQualitySignal signal({
    String family = AgentProviderQualitySignalFamily.reliability,
    String source = AgentProviderQualitySignalSource.trustedBackendObserved,
    double score = 90,
    int samples = 120,
    int ageHours = 24,
    bool trusted = true,
    bool privacySafe = true,
    bool hardSafetyViolation = false,
    bool capabilityEligible = true,
    bool privacyEligible = true,
  }) {
    return AgentProviderQualitySignal(
      signalId: 'quality:signal:001',
      providerId: 'provider:free:a',
      modelReference: 'model_ref:free:a',
      providerTier: AgentProviderExpansionTier.freeOnline,
      taskType: 'GENERAL_REASONING',
      family: family,
      source: source,
      normalizedScore: score,
      sampleCount: samples,
      ageHours: ageHours,
      trustedObservation: trusted,
      privacySafeMetadata: privacySafe,
      hardSafetyViolation: hardSafetyViolation,
      capabilityEligible: capabilityEligible,
      privacyEligible: privacyEligible,
    );
  }

  group('Phase 59 Step 1B quality signal boundary', () {
    test('8 quality signal families are locked', () {
      expect(AgentProviderQualitySignalFamily.values.length, 8);
    });

    test('3 quality signal sources are locked', () {
      expect(AgentProviderQualitySignalSource.values.length, 3);
    });

    test('3 sample sufficiency levels are locked', () {
      expect(AgentProviderQualitySampleSufficiency.values.length, 3);
    });

    test('3 freshness levels are locked', () {
      expect(AgentProviderQualityFreshness.values.length, 3);
    });

    test('5 recommendation states are locked', () {
      expect(AgentProviderQualityRecommendation.values.length, 5);
    });

    test('strong current high score can recommend prefer', () {
      final assessment = scorePolicy.evaluate(signal());

      expect(
        assessment.boundary.recommendation,
        AgentProviderQualityRecommendation.prefer,
      );
      expect(assessment.qualityEligible, true);
    });

    test('small sample cannot create strong preference', () {
      final assessment = scorePolicy.evaluate(signal(samples: 5, score: 99));

      expect(
        assessment.boundary.recommendation,
        AgentProviderQualityRecommendation.insufficientEvidence,
      );
    });

    test('sufficient but not strong sample cannot prefer', () {
      final assessment = scorePolicy.evaluate(signal(samples: 30, score: 99));

      expect(
        assessment.boundary.recommendation,
        AgentProviderQualityRecommendation.neutral,
      );
    });

    test('aging evidence cannot create strong prefer', () {
      final assessment = scorePolicy.evaluate(
        signal(samples: 150, ageHours: 300, score: 95),
      );

      expect(
        assessment.boundary.recommendation,
        AgentProviderQualityRecommendation.neutral,
      );
    });

    test('stale evidence becomes insufficient', () {
      final assessment = scorePolicy.evaluate(
        signal(samples: 500, ageHours: 1000, score: 99),
      );

      expect(
        assessment.boundary.recommendation,
        AgentProviderQualityRecommendation.insufficientEvidence,
      );
    });

    test('hard safety violation is ineligible regardless score', () {
      final assessment = scorePolicy.evaluate(
        signal(score: 100, samples: 1000, hardSafetyViolation: true),
      );

      expect(
        assessment.boundary.recommendation,
        AgentProviderQualityRecommendation.ineligible,
      );
      expect(assessment.qualityEligible, false);
    });

    test('capability ineligible is hard quality ineligible', () {
      final assessment = scorePolicy.evaluate(
        signal(capabilityEligible: false),
      );

      expect(
        assessment.boundary.recommendation,
        AgentProviderQualityRecommendation.ineligible,
      );
    });

    test('privacy ineligible is hard quality ineligible', () {
      final assessment = scorePolicy.evaluate(signal(privacyEligible: false));

      expect(
        assessment.boundary.recommendation,
        AgentProviderQualityRecommendation.ineligible,
      );
    });

    test('untrusted observation is ineligible', () {
      final assessment = scorePolicy.evaluate(signal(trusted: false));

      expect(
        assessment.boundary.recommendation,
        AgentProviderQualityRecommendation.ineligible,
      );
    });

    test('non privacy-safe metadata is ineligible', () {
      final assessment = scorePolicy.evaluate(signal(privacySafe: false));

      expect(
        assessment.boundary.recommendation,
        AgentProviderQualityRecommendation.ineligible,
      );
    });

    test('neutral score band stays neutral', () {
      final assessment = scorePolicy.evaluate(signal(score: 70));

      expect(
        assessment.boundary.recommendation,
        AgentProviderQualityRecommendation.neutral,
      );
    });

    test('low score with sufficient fresh evidence may deprioritize', () {
      final assessment = scorePolicy.evaluate(
        signal(score: 40, samples: 100, ageHours: 10),
      );

      expect(
        assessment.boundary.recommendation,
        AgentProviderQualityRecommendation.deprioritize,
      );
    });

    test('signal stores no raw prompt/response/private payload', () {
      final value = signal();

      expect(value.containsRawPrompt, false);
      expect(value.containsRawConversation, false);
      expect(value.containsRawProviderResponse, false);
      expect(value.containsPrivatePayload, false);
      expect(value.containsApiSecret, false);
      expect(value.containsAuthToken, false);
    });

    test('signal cannot invoke provider or mutate authority', () {
      final value = signal();

      expect(value.invokesProvider, false);
      expect(value.changesProviderEnabledState, false);
      expect(value.changesBudget, false);
      expect(value.changesSecret, false);
      expect(value.deploysModel, false);
      expect(value.grantsPermission, false);
      expect(value.consumesApproval, false);
      expect(value.expandsScope, false);
      expect(value.executesBusinessAction, false);
      expect(value.persistsSignal, false);
    });

    test('signal policy locks trusted/privacy-safe metadata only', () {
      expect(signalPolicy.trustedObservedMetadataRequired, true);
      expect(signalPolicy.privacySafeMetadataRequired, true);
      expect(signalPolicy.rawPromptForbidden, true);
      expect(signalPolicy.rawConversationForbidden, true);
      expect(signalPolicy.rawProviderResponseForbidden, true);
      expect(signalPolicy.privatePayloadForbidden, true);
    });

    test('signal policy locks sample/freshness safety', () {
      expect(signalPolicy.objectiveAndSubjectiveSignalsRemainSeparated, true);
      expect(signalPolicy.smallSampleStrongPreferenceForbidden, true);
      expect(signalPolicy.staleEvidenceStrongPreferenceForbidden, true);
      expect(signalPolicy.safetyViolationAlwaysQualityIneligible, true);
    });

    test('signal policy has no provider/change authority', () {
      expect(signalPolicy.providerInvocationImplementedHere, false);
      expect(signalPolicy.providerEnableDisableImplementedHere, false);
      expect(signalPolicy.budgetMutationImplementedHere, false);
      expect(signalPolicy.secretMutationImplementedHere, false);
      expect(signalPolicy.modelDeploymentImplementedHere, false);
      expect(signalPolicy.persistenceImplementedHere, false);
      expect(signalPolicy.grantsPermission, false);
      expect(signalPolicy.consumesApproval, false);
      expect(signalPolicy.expandsScope, false);
      expect(signalPolicy.executesBusinessAction, false);
    });

    test('quality recommendation cannot override Phase58 gates', () {
      final boundary = scorePolicy.evaluate(signal()).boundary;

      expect(boundary.recommendationOnly, true);
      expect(boundary.mayOverrideProviderTierOrder, false);
      expect(boundary.mayOverridePaidAiOnOff, false);
      expect(boundary.mayOverrideAskBeforePaid, false);
      expect(boundary.mayOverrideBudgetLimit, false);
      expect(boundary.mayOverridePrivacyGate, false);
      expect(boundary.mayOverrideCapabilityGate, false);
      expect(boundary.mayOverrideCircuitBreaker, false);
      expect(boundary.mayOverrideBackendBoundary, false);
    });

    test('quality boundary cannot change provider/business authority', () {
      final boundary = scorePolicy.evaluate(signal()).boundary;

      expect(boundary.mayEnableProvider, false);
      expect(boundary.mayDisableProvider, false);
      expect(boundary.mayChangeSecret, false);
      expect(boundary.mayDeployModel, false);
      expect(boundary.mayInvokeProvider, false);
      expect(boundary.mayExecuteBusinessAction, false);
      expect(boundary.mayGrantPermission, false);
      expect(boundary.mayConsumeApproval, false);
      expect(boundary.mayMutateBudget, false);
    });

    test('assessment remains metadata only', () {
      final assessment = scorePolicy.evaluate(signal());

      expect(assessment.metadataOnly, true);
      expect(assessment.invokesProvider, false);
      expect(assessment.changesProviderState, false);
      expect(assessment.mutatesBudget, false);
      expect(assessment.grantsPermission, false);
      expect(assessment.consumesApproval, false);
      expect(assessment.executesBusinessAction, false);
      expect(assessment.persistsAssessment, false);
    });

    test('score policy keeps Phase58 gates authoritative', () {
      expect(scorePolicy.qualityRecommendationOnly, true);
      expect(scorePolicy.freeLocalPaidOrderStillAuthoritative, true);
      expect(scorePolicy.paidOnOffStillAuthoritative, true);
      expect(scorePolicy.askBeforePaidStillAuthoritative, true);
      expect(scorePolicy.budgetStillAuthoritative, true);
      expect(scorePolicy.privacyStillAuthoritative, true);
      expect(scorePolicy.capabilityStillAuthoritative, true);
      expect(scorePolicy.circuitBreakerStillAuthoritative, true);
      expect(scorePolicy.backendBoundaryStillAuthoritative, true);
      expect(scorePolicy.safetyAlwaysOutranksQualityScore, true);
      expect(scorePolicy.costEfficiencyNeverOutranksSafety, true);
    });

    test('score policy cannot invoke/enable/deploy/change budget', () {
      expect(scorePolicy.providerInvocationImplementedHere, false);
      expect(scorePolicy.providerEnableDisableImplementedHere, false);
      expect(scorePolicy.automaticRoutingMutationImplementedHere, false);
      expect(scorePolicy.budgetMutationImplementedHere, false);
      expect(scorePolicy.secretMutationImplementedHere, false);
      expect(scorePolicy.deploymentImplementedHere, false);
      expect(scorePolicy.persistenceImplementedHere, false);
    });

    test('score policy adds no Permission Approval Business authority', () {
      expect(scorePolicy.grantsPermission, false);
      expect(scorePolicy.consumesApproval, false);
      expect(scorePolicy.expandsScope, false);
      expect(scorePolicy.executesBusinessAction, false);
    });

    test('later phase ownership remains separate', () {
      expect(scorePolicy.phase60CrossAgentSupervisorSeparate, true);
      expect(scorePolicy.phase61PerformanceDashboardSeparate, true);
      expect(scorePolicy.phase62VersioningDeploymentSeparate, true);
      expect(scorePolicy.phase63PrivacyRetentionSeparate, true);
    });
  });
}
