import '../constants/agent_evaluation_constants.dart';
import '../models/agent_call_training_dataset.dart';
import '../models/agent_call_training_evaluation.dart';

class AgentCallTrainingHarness {
  const AgentCallTrainingHarness();

  AgentCallTrainingObservation canonicalObservationFor(
    AgentCallTrainingScenario scenario,
  ) {
    scenario.validate();

    final bool safeFallback =
        scenario.expectedEvaluationDecision ==
        AgentEvaluationExpectedDecision.safeFallback;

    final bool refusal =
        scenario.expectedEvaluationDecision ==
        AgentEvaluationExpectedDecision.refuse;

    final bool escalation =
        scenario.expectedEvaluationDecision ==
        AgentEvaluationExpectedDecision.escalate;

    return AgentCallTrainingObservation(
      actualDecision: scenario.expectedEvaluationDecision,
      actualActionId: scenario.expectedActionId,
      actualEscalationLevel: scenario.expectedEscalationLevel,
      behaviorSummary:
          'Canonical synthetic offline observation for '
          '${scenario.scenarioId}.',
      usedTrustedBinding: scenario.requiresTrustedBinding,
      usedFreshVerification: scenario.requiresFreshVerification,
      obtainedCustomerConfirmation:
          scenario.requiresCustomerConfirmation && !safeFallback,
      protectedPrivateData: true,
      usedSafeFallback: safeFallback,
      refused: refusal,
      escalated: escalation,
      completedTask: !safeFallback && !refusal && !escalation,
      wroteBusinessData: false,
      grantedPermission: false,
      usedTranscriptAsAuthority: false,
      usedLiveProvider: false,
      deployed: false,
    );
  }

  Map<String, AgentCallTrainingObservation> canonicalObservationsFor(
    AgentCallTrainingDataset dataset,
  ) {
    dataset.validate();

    return <String, AgentCallTrainingObservation>{
      for (final AgentCallTrainingScenario scenario in dataset.scenarios)
        if (scenario.enabled)
          scenario.scenarioId: canonicalObservationFor(scenario),
    };
  }

  bool get usesSyntheticFixturesOnly => true;
  bool get readsProductionConversations => false;
  bool get providerExecutionAllowed => false;
  bool get telephonyAllowed => false;
  bool get sttAllowed => false;
  bool get ttsAllowed => false;
  bool get smsAllowed => false;
  bool get firestoreAccessAllowed => false;
  bool get runtimeActionAllowed => false;
  bool get businessWriteAllowed => false;
  bool get approvalConsumptionAllowed => false;
  bool get permissionGrantAllowed => false;
  bool get transcriptAuthorityAllowed => false;
  bool get promptMutationAllowed => false;
  bool get modelTrainingAllowed => false;
  bool get deploymentAllowed => false;
}
