import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_action_ids.dart';
import 'package:swat_ride/ai_agent/data/initial_agent_roles_seed.dart';
import 'package:swat_ride/ai_agent/models/agent_call_training_evidence.dart';
import 'package:swat_ride/ai_agent/models/agent_call_training_release_candidate.dart';
import 'package:swat_ride/ai_agent/models/agent_role.dart';
import 'package:swat_ride/ai_agent/services/agent_call_training_evidence_builder.dart';
import 'package:swat_ride/ai_agent/services/agent_call_training_release_candidate_gate.dart';

void main() {
  const AgentCallTrainingEvidenceBuilder builder =
      AgentCallTrainingEvidenceBuilder();

  const AgentCallTrainingReleaseCandidateGate gate =
      AgentCallTrainingReleaseCandidateGate();

  final DateTime evaluatedAt = DateTime.utc(2026, 8, 18, 13, 22);

  group('Phase 50 Step 1F release-candidate gate', () {
    test('core evidence captures passing canonical and adversarial proof', () {
      final AgentCallTrainingEvidence evidence = builder.buildCoreEvidence(
        recordedAt: evaluatedAt,
      );

      expect(evidence.evidenceVersion, 1);
      expect(evidence.datasetId, 'call_training_core_v1');
      expect(evidence.datasetVersion, 1);
      expect(evidence.canonicalScenarioCount, 10);
      expect(evidence.canonicalPassedCount, 10);
      expect(evidence.canonicalAverageScorePercent, 100);
      expect(evidence.canonicalBaselinePassed, isTrue);
      expect(evidence.adversarialScenarioCount, 10);
      expect(evidence.requiredAdversarialFamilies.length, 10);
      expect(evidence.coveredAdversarialFamilies.length, 10);
      expect(evidence.allAdversarialFailuresDetected, isTrue);
      expect(evidence.noUnexpectedAdversarialPasses, isTrue);
      expect(evidence.coverageGatePassed, isTrue);
      expect(evidence.permissionBoundaryVerified, isTrue);
      expect(evidence.callAgentActions.length, 4);
      expect(evidence.technicalEvidencePassed, isTrue);
    });

    test('evidence collections are immutable', () {
      final AgentCallTrainingEvidence evidence = builder.buildCoreEvidence(
        recordedAt: evaluatedAt,
      );

      expect(
        () => evidence.callAgentActions.add('unsafe'),
        throwsUnsupportedError,
      );

      expect(
        () => evidence.requiredAdversarialFamilies.add('unsafe'),
        throwsUnsupportedError,
      );

      expect(
        () => evidence.coveredAdversarialFamilies.add('unsafe'),
        throwsUnsupportedError,
      );
    });

    test('same inputs produce same deterministic integrity fingerprint', () {
      final AgentCallTrainingEvidence first = builder.buildCoreEvidence(
        recordedAt: evaluatedAt,
      );

      final AgentCallTrainingEvidence second = builder.buildCoreEvidence(
        recordedAt: evaluatedAt,
      );

      expect(second.integrityFingerprint, first.integrityFingerprint);

      expect(
        second.canonicalFingerprintPayload(),
        first.canonicalFingerprintPayload(),
      );

      expect(second.integrityFingerprint.length, 16);
    });

    test('fingerprint changes when evidence content changes', () {
      final AgentCallTrainingEvidence evidence = builder.buildCoreEvidence(
        recordedAt: evaluatedAt,
      );

      final String changedPayload =
          '${evidence.canonicalFingerprintPayload()}|changed=true';

      final String changedFingerprint =
          AgentCallTrainingEvidenceFingerprint.compute(changedPayload);

      expect(changedFingerprint, isNot(evidence.integrityFingerprint));
    });

    test('invalid fingerprint is rejected', () {
      final AgentCallTrainingEvidence source = builder.buildCoreEvidence(
        recordedAt: evaluatedAt,
      );

      final AgentCallTrainingEvidence invalid = AgentCallTrainingEvidence(
        evidenceId: source.evidenceId,
        evidenceVersion: source.evidenceVersion,
        datasetId: source.datasetId,
        datasetVersion: source.datasetVersion,
        runnerVersion: source.runnerVersion,
        canonicalScenarioCount: source.canonicalScenarioCount,
        canonicalPassedCount: source.canonicalPassedCount,
        canonicalAverageScorePercent: source.canonicalAverageScorePercent,
        canonicalBaselinePassed: source.canonicalBaselinePassed,
        adversarialScenarioCount: source.adversarialScenarioCount,
        requiredAdversarialFamilies: source.requiredAdversarialFamilies,
        coveredAdversarialFamilies: source.coveredAdversarialFamilies,
        allAdversarialFailuresDetected: source.allAdversarialFailuresDetected,
        noUnexpectedAdversarialPasses: source.noUnexpectedAdversarialPasses,
        coverageGatePassed: source.coverageGatePassed,
        callAgentActions: source.callAgentActions,
        permissionBoundaryVerified: source.permissionBoundaryVerified,
        recordedAt: source.recordedAt,
        integrityFingerprint: '0000000000000000',
      );

      expect(
        invalid.validate,
        throwsA(isA<AgentCallTrainingEvidenceException>()),
      );
    });

    test('core candidate is eligible for human review only', () {
      final AgentCallTrainingReleaseCandidateDecision decision = gate
          .evaluateCoreCandidate(evaluatedAt: evaluatedAt);

      expect(
        decision.status,
        AgentCallTrainingReleaseCandidateStatus.eligibleForHumanReview,
      );
      expect(decision.eligibleForHumanReview, isTrue);
      expect(decision.humanReviewRequired, isTrue);
      expect(decision.humanReviewCompleted, isFalse);
      expect(decision.humanApproved, isFalse);
      expect(decision.autoApprovalAllowed, isFalse);
    });

    test('human-review eligibility never means deployment authority', () {
      final AgentCallTrainingReleaseCandidateDecision decision = gate
          .evaluateCoreCandidate(evaluatedAt: evaluatedAt);

      expect(decision.eligibleForHumanReview, isTrue);
      expect(decision.mayGrantPermission, isFalse);
      expect(decision.mayConsumeApproval, isFalse);
      expect(decision.mayWriteBusinessData, isFalse);
      expect(decision.mayTrainModel, isFalse);
      expect(decision.mayChangePrompt, isFalse);
      expect(decision.mayDeploy, isFalse);
      expect(decision.mayActivateProduction, isFalse);
    });

    test('evidence explicitly does not fake backend persistence/signature', () {
      final AgentCallTrainingEvidence evidence = builder.buildCoreEvidence(
        recordedAt: evaluatedAt,
      );

      expect(evidence.structurallyImmutable, isTrue);
      expect(evidence.cryptographicallySigned, isFalse);
      expect(evidence.persistedToTrustedBackend, isFalse);
      expect(evidence.humanApproved, isFalse);
    });

    test('evidence safe map is read-only and truthful', () {
      final AgentCallTrainingEvidence evidence = builder.buildCoreEvidence(
        recordedAt: evaluatedAt,
      );

      final Map<String, dynamic> map = evidence.toSafeMap();

      expect(map['structurallyImmutable'], isTrue);
      expect(map['cryptographicallySigned'], isFalse);
      expect(map['persistedToTrustedBackend'], isFalse);
      expect(map['humanApproved'], isFalse);
      expect(map['technicalEvidencePassed'], isTrue);
      expect(map['mayTrainModel'], isFalse);
      expect(map['mayDeploy'], isFalse);

      expect(() => map['unsafe'] = true, throwsUnsupportedError);
    });

    test('release safe map keeps approval/deploy false', () {
      final AgentCallTrainingReleaseCandidateDecision decision = gate
          .evaluateCoreCandidate(evaluatedAt: evaluatedAt);

      final Map<String, dynamic> map = decision.toSafeMap();

      expect(map['eligibleForHumanReview'], isTrue);
      expect(map['humanReviewRequired'], isTrue);
      expect(map['humanReviewCompleted'], isFalse);
      expect(map['humanApproved'], isFalse);
      expect(map['autoApprovalAllowed'], isFalse);
      expect(map['mayTrainModel'], isFalse);
      expect(map['mayChangePrompt'], isFalse);
      expect(map['mayDeploy'], isFalse);
      expect(map['mayActivateProduction'], isFalse);

      expect(() => map['unsafe'] = true, throwsUnsupportedError);
    });

    test('evidence builder exposes no runtime/provider/deploy authority', () {
      expect(builder.readsProductionConversations, isFalse);
      expect(builder.persistsEvidenceToBackend, isFalse);
      expect(builder.cryptographicallySignsEvidence, isFalse);
      expect(builder.providerExecutionAllowed, isFalse);
      expect(builder.runtimeActionAllowed, isFalse);
      expect(builder.businessWriteAllowed, isFalse);
      expect(builder.approvalConsumptionAllowed, isFalse);
      expect(builder.permissionGrantAllowed, isFalse);
      expect(builder.promptMutationAllowed, isFalse);
      expect(builder.modelTrainingAllowed, isFalse);
      expect(builder.deploymentAllowed, isFalse);
    });

    test('release gate exposes human review but no automatic authority', () {
      expect(gate.humanReviewRequired, isTrue);
      expect(gate.autoApprovalAllowed, isFalse);
      expect(gate.providerExecutionAllowed, isFalse);
      expect(gate.runtimeActionAllowed, isFalse);
      expect(gate.productionDataAccessAllowed, isFalse);
      expect(gate.businessWriteAllowed, isFalse);
      expect(gate.approvalConsumptionAllowed, isFalse);
      expect(gate.permissionGrantAllowed, isFalse);
      expect(gate.promptMutationAllowed, isFalse);
      expect(gate.modelTrainingAllowed, isFalse);
      expect(gate.deploymentAllowed, isFalse);
      expect(gate.productionActivationAllowed, isFalse);
    });

    test('evidence records exactly the four Phase 49 Call actions', () {
      final AgentCallTrainingEvidence evidence = builder.buildCoreEvidence(
        recordedAt: evaluatedAt,
      );

      expect(evidence.callAgentActions.toSet(), <String>{
        AgentActionId.createCallRideBooking,
        AgentActionId.readCallExistingRide,
        AgentActionId.readCallFoodOrderStatus,
        AgentActionId.readCallTourBookingStatus,
      });
    });

    test('call_agent role remains exactly four actions', () {
      final AgentRole role = buildInitialAgentRoles().firstWhere(
        (AgentRole value) => value.roleId == 'call_agent',
      );

      expect(role.allowedActions.length, 4);
    });
  });
}
