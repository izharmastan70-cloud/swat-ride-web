import '../constants/agent_action_ids.dart';
import '../data/initial_agent_roles_seed.dart';
import '../models/agent_call_training_closeout.dart';
import '../models/agent_call_training_evidence.dart';
import '../models/agent_call_training_release_candidate.dart';
import '../models/agent_role.dart';
import 'agent_call_training_release_candidate_gate.dart';

class AgentCallTrainingReadinessCloseout {
  const AgentCallTrainingReadinessCloseout({
    this.releaseGate = const AgentCallTrainingReleaseCandidateGate(),
  });

  final AgentCallTrainingReleaseCandidateGate releaseGate;

  AgentCallTrainingCloseout closePhase50({required DateTime closedAt}) {
    final DateTime at = closedAt.toUtc();

    final AgentCallTrainingReleaseCandidateDecision decision = releaseGate
        .evaluateCoreCandidate(evaluatedAt: at);

    final AgentCallTrainingEvidence evidence = decision.evidence;

    final AgentRole callRole = buildInitialAgentRoles().firstWhere(
      (AgentRole role) => role.roleId == 'call_agent',
    );

    const Set<String> expectedActions = <String>{
      AgentActionId.createCallRideBooking,
      AgentActionId.readCallExistingRide,
      AgentActionId.readCallFoodOrderStatus,
      AgentActionId.readCallTourBookingStatus,
    };

    final List<String> actualActions = List<String>.from(
      callRole.allowedActions,
    )..sort();

    final bool permissionBoundaryVerified =
        actualActions.length == 4 &&
        actualActions.toSet().containsAll(expectedActions) &&
        expectedActions.containsAll(actualActions);

    final bool canonicalBaselineVerified =
        evidence.canonicalBaselinePassed &&
        evidence.canonicalScenarioCount == 10 &&
        evidence.canonicalPassedCount == 10 &&
        evidence.canonicalAverageScorePercent == 100;

    final bool adversarialCoverageVerified =
        evidence.adversarialScenarioCount == 10 &&
        evidence.requiredAdversarialFamilies.length == 10 &&
        evidence.coveredAdversarialFamilies.length == 10 &&
        evidence.allAdversarialFailuresDetected &&
        evidence.noUnexpectedAdversarialPasses &&
        evidence.coverageGatePassed;

    final bool immutableEvidenceVerified =
        evidence.structurallyImmutable &&
        !evidence.cryptographicallySigned &&
        !evidence.persistedToTrustedBackend &&
        evidence.integrityFingerprint.isNotEmpty;

    final bool ready =
        decision.eligibleForHumanReview &&
        permissionBoundaryVerified &&
        canonicalBaselineVerified &&
        adversarialCoverageVerified &&
        immutableEvidenceVerified;

    final AgentCallTrainingCloseout closeout = AgentCallTrainingCloseout(
      status: ready
          ? AgentCallTrainingCloseoutStatus.readyForHumanReview
          : AgentCallTrainingCloseoutStatus.blocked,
      phase: 'PHASE_50_CALL_TRAINING',
      completedSteps: const <String>['1A', '1B', '1C', '1D', '1E', '1F', '1G'],
      releaseCandidateDecision: decision,
      callAgentActions: actualActions,
      permissionBoundaryVerified: permissionBoundaryVerified,
      canonicalBaselineVerified: canonicalBaselineVerified,
      adversarialCoverageVerified: adversarialCoverageVerified,
      immutableEvidenceVerified: immutableEvidenceVerified,
      fullTrainingFoundationReady: ready,
      closedAt: at,
    );

    closeout.validate();
    return closeout;
  }

  bool get humanReviewRequired => true;
  bool get productionCallActivationAllowed => false;
  bool get providerExecutionAllowed => false;
  bool get telephonyExecutionAllowed => false;
  bool get sttExecutionAllowed => false;
  bool get ttsExecutionAllowed => false;
  bool get smsExecutionAllowed => false;
  bool get productionDataAccessAllowed => false;
  bool get runtimeActionAllowed => false;
  bool get businessWriteAllowed => false;
  bool get approvalConsumptionAllowed => false;
  bool get permissionGrantAllowed => false;
  bool get promptMutationAllowed => false;
  bool get modelTrainingAllowed => false;
  bool get deploymentAllowed => false;
}
