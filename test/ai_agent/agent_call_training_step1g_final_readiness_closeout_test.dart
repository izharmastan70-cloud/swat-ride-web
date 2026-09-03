import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_action_ids.dart';
import 'package:swat_ride/ai_agent/data/initial_agent_roles_seed.dart';
import 'package:swat_ride/ai_agent/models/agent_call_training_closeout.dart';
import 'package:swat_ride/ai_agent/models/agent_role.dart';
import 'package:swat_ride/ai_agent/services/agent_call_training_readiness_closeout.dart';

void main() {
  const AgentCallTrainingReadinessCloseout closeoutService =
      AgentCallTrainingReadinessCloseout();

  final DateTime closedAt = DateTime.utc(2026, 8, 18, 13, 40);

  group('Phase 50 Step 1G final Call training closeout', () {
    test('final closeout includes exactly Steps 1A-1G', () {
      final AgentCallTrainingCloseout closeout = closeoutService.closePhase50(
        closedAt: closedAt,
      );

      expect(closeout.completedSteps.length, 7);
      expect(closeout.completedSteps.toSet(), <String>{
        '1A',
        '1B',
        '1C',
        '1D',
        '1E',
        '1F',
        '1G',
      });
    });

    test('final closeout is ready for explicit human review', () {
      final AgentCallTrainingCloseout closeout = closeoutService.closePhase50(
        closedAt: closedAt,
      );

      expect(
        closeout.status,
        AgentCallTrainingCloseoutStatus.readyForHumanReview,
      );
      expect(closeout.fullTrainingFoundationReady, isTrue);
      expect(closeout.readyForHumanReview, isTrue);
      expect(closeout.humanReviewRequired, isTrue);
      expect(closeout.humanReviewCompleted, isFalse);
      expect(closeout.humanApproved, isFalse);
    });

    test('canonical 10/10 baseline is verified at closeout', () {
      final AgentCallTrainingCloseout closeout = closeoutService.closePhase50(
        closedAt: closedAt,
      );

      expect(closeout.canonicalBaselineVerified, isTrue);
      expect(
        closeout.releaseCandidateDecision.evidence.canonicalScenarioCount,
        10,
      );
      expect(
        closeout.releaseCandidateDecision.evidence.canonicalPassedCount,
        10,
      );
      expect(
        closeout.releaseCandidateDecision.evidence.canonicalAverageScorePercent,
        100,
      );
    });

    test('adversarial 10-family coverage is verified at closeout', () {
      final AgentCallTrainingCloseout closeout = closeoutService.closePhase50(
        closedAt: closedAt,
      );

      final evidence = closeout.releaseCandidateDecision.evidence;

      expect(closeout.adversarialCoverageVerified, isTrue);
      expect(evidence.adversarialScenarioCount, 10);
      expect(evidence.requiredAdversarialFamilies.length, 10);
      expect(evidence.coveredAdversarialFamilies.length, 10);
      expect(evidence.allAdversarialFailuresDetected, isTrue);
      expect(evidence.noUnexpectedAdversarialPasses, isTrue);
      expect(evidence.coverageGatePassed, isTrue);
    });

    test('immutable evidence boundary is verified truthfully', () {
      final AgentCallTrainingCloseout closeout = closeoutService.closePhase50(
        closedAt: closedAt,
      );

      final evidence = closeout.releaseCandidateDecision.evidence;

      expect(closeout.immutableEvidenceVerified, isTrue);
      expect(evidence.structurallyImmutable, isTrue);
      expect(evidence.integrityFingerprint, isNotEmpty);
      expect(evidence.cryptographicallySigned, isFalse);
      expect(evidence.persistedToTrustedBackend, isFalse);
    });

    test('call_agent remains exact Phase 49 four-action boundary', () {
      final AgentCallTrainingCloseout closeout = closeoutService.closePhase50(
        closedAt: closedAt,
      );

      expect(closeout.permissionBoundaryVerified, isTrue);
      expect(closeout.callAgentActions.length, 4);
      expect(closeout.callAgentActions.toSet(), <String>{
        AgentActionId.createCallRideBooking,
        AgentActionId.readCallExistingRide,
        AgentActionId.readCallFoodOrderStatus,
        AgentActionId.readCallTourBookingStatus,
      });
    });

    test('training closeout never claims production Call is live', () {
      final AgentCallTrainingCloseout closeout = closeoutService.closePhase50(
        closedAt: closedAt,
      );

      expect(closeout.productionCallLive, isFalse);
      expect(closeout.telephonyConnected, isFalse);
      expect(closeout.sttConnected, isFalse);
      expect(closeout.ttsConnected, isFalse);
      expect(closeout.smsConnected, isFalse);
    });

    test('training closeout grants no runtime or deployment authority', () {
      final AgentCallTrainingCloseout closeout = closeoutService.closePhase50(
        closedAt: closedAt,
      );

      expect(closeout.mayGrantPermission, isFalse);
      expect(closeout.mayConsumeApproval, isFalse);
      expect(closeout.mayWriteBusinessData, isFalse);
      expect(closeout.mayTrainModel, isFalse);
      expect(closeout.mayChangePrompt, isFalse);
      expect(closeout.mayDeploy, isFalse);
      expect(closeout.mayActivateProduction, isFalse);
    });

    test('closeout safe map is immutable and production-truthful', () {
      final AgentCallTrainingCloseout closeout = closeoutService.closePhase50(
        closedAt: closedAt,
      );

      final Map<String, dynamic> map = closeout.toSafeMap();

      expect(
        map['status'],
        AgentCallTrainingCloseoutStatus.readyForHumanReview,
      );
      expect(map['fullTrainingFoundationReady'], isTrue);
      expect(map['humanReviewRequired'], isTrue);
      expect(map['humanApproved'], isFalse);
      expect(map['productionCallLive'], isFalse);
      expect(map['trustedBackendEvidencePersisted'], isFalse);
      expect(map['evidenceCryptographicallySigned'], isFalse);
      expect(map['mayTrainModel'], isFalse);
      expect(map['mayDeploy'], isFalse);
      expect(map['mayActivateProduction'], isFalse);

      expect(() => map['unsafe'] = true, throwsUnsupportedError);
    });

    test('closeout service exposes no provider/runtime authority', () {
      expect(closeoutService.humanReviewRequired, isTrue);
      expect(closeoutService.productionCallActivationAllowed, isFalse);
      expect(closeoutService.providerExecutionAllowed, isFalse);
      expect(closeoutService.telephonyExecutionAllowed, isFalse);
      expect(closeoutService.sttExecutionAllowed, isFalse);
      expect(closeoutService.ttsExecutionAllowed, isFalse);
      expect(closeoutService.smsExecutionAllowed, isFalse);
      expect(closeoutService.productionDataAccessAllowed, isFalse);
      expect(closeoutService.runtimeActionAllowed, isFalse);
      expect(closeoutService.businessWriteAllowed, isFalse);
      expect(closeoutService.approvalConsumptionAllowed, isFalse);
      expect(closeoutService.permissionGrantAllowed, isFalse);
      expect(closeoutService.promptMutationAllowed, isFalse);
      expect(closeoutService.modelTrainingAllowed, isFalse);
      expect(closeoutService.deploymentAllowed, isFalse);
    });

    test('actual role seed still has exactly four Call actions', () {
      final AgentRole role = buildInitialAgentRoles().firstWhere(
        (AgentRole value) => value.roleId == 'call_agent',
      );

      expect(role.allowedActions.length, 4);
    });
  });
}
