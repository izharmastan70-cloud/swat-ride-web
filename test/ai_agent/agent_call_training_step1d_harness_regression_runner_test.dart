import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_call_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_evaluation_constants.dart';
import 'package:swat_ride/ai_agent/data/initial_agent_roles_seed.dart';
import 'package:swat_ride/ai_agent/models/agent_call_training_dataset.dart';
import 'package:swat_ride/ai_agent/models/agent_call_training_evaluation.dart';
import 'package:swat_ride/ai_agent/models/agent_call_training_regression_run.dart';
import 'package:swat_ride/ai_agent/models/agent_role.dart';
import 'package:swat_ride/ai_agent/services/agent_call_training_catalog.dart';
import 'package:swat_ride/ai_agent/services/agent_call_training_harness.dart';
import 'package:swat_ride/ai_agent/services/agent_call_training_regression_runner.dart';

void main() {
  const AgentCallTrainingHarness harness = AgentCallTrainingHarness();

  const AgentCallTrainingRegressionRunner runner =
      AgentCallTrainingRegressionRunner();

  final DateTime runAt = DateTime.utc(2026, 8, 18, 12, 47);

  AgentCallTrainingScenario scenario(String id) {
    return AgentCallTrainingCatalog.datasetV1.scenarios.firstWhere(
      (AgentCallTrainingScenario value) => value.scenarioId == id,
    );
  }

  group('Phase 50 Step 1D canonical Call training harness', () {
    test('canonical harness creates one observation per enabled scenario', () {
      final AgentCallTrainingDataset dataset =
          AgentCallTrainingCatalog.datasetV1;

      final Map<String, AgentCallTrainingObservation> observations = harness
          .canonicalObservationsFor(dataset);

      expect(observations.length, 10);
      expect(
        observations.keys.toSet(),
        dataset.scenarios
            .where((AgentCallTrainingScenario value) => value.enabled)
            .map((AgentCallTrainingScenario value) => value.scenarioId)
            .toSet(),
      );
    });

    test('every canonical observation is synthetic and side-effect free', () {
      final AgentCallTrainingDataset dataset =
          AgentCallTrainingCatalog.datasetV1;

      for (final AgentCallTrainingScenario item in dataset.scenarios) {
        final AgentCallTrainingObservation observation = harness
            .canonicalObservationFor(item);

        expect(observation.actualDecision, item.expectedEvaluationDecision);
        expect(observation.actualActionId, item.expectedActionId);
        expect(observation.actualEscalationLevel, item.expectedEscalationLevel);
        expect(observation.protectedPrivateData, isTrue);
        expect(observation.wroteBusinessData, isFalse);
        expect(observation.grantedPermission, isFalse);
        expect(observation.usedTranscriptAsAuthority, isFalse);
        expect(observation.usedLiveProvider, isFalse);
        expect(observation.deployed, isFalse);
      }
    });

    test('confirmed Ride canonical observation preserves confirmation', () {
      final AgentCallTrainingScenario item = scenario(
        'ride_booking_confirmed_safe_path_v1',
      );

      final AgentCallTrainingObservation observation = harness
          .canonicalObservationFor(item);

      expect(observation.usedTrustedBinding, isTrue);
      expect(observation.usedFreshVerification, isTrue);
      expect(observation.obtainedCustomerConfirmation, isTrue);
      expect(observation.completedTask, isTrue);
      expect(observation.usedSafeFallback, isFalse);
    });

    test('missing-confirmation Ride case uses safe fallback', () {
      final AgentCallTrainingScenario item = scenario(
        'ride_booking_missing_confirmation_v1',
      );

      final AgentCallTrainingObservation observation = harness
          .canonicalObservationFor(item);

      expect(
        observation.actualDecision,
        AgentEvaluationExpectedDecision.safeFallback,
      );
      expect(observation.usedSafeFallback, isTrue);
      expect(observation.obtainedCustomerConfirmation, isFalse);
      expect(observation.completedTask, isFalse);
    });

    test('read-only status cases use trusted/fresh AI path', () {
      for (final String id in <String>[
        'existing_ride_status_authorized_v1',
        'food_order_status_authorized_v1',
        'tour_booking_status_authorized_v1',
      ]) {
        final AgentCallTrainingScenario item = scenario(id);

        final AgentCallTrainingObservation observation = harness
            .canonicalObservationFor(item);

        expect(
          observation.actualDecision,
          AgentEvaluationExpectedDecision.answerReadOnly,
        );
        expect(observation.actualEscalationLevel, AgentCallEscalationLevel.ai);
        expect(observation.usedTrustedBinding, isTrue);
        expect(observation.usedFreshVerification, isTrue);
        expect(observation.completedTask, isTrue);
      }
    });

    test(
      'transcript-authority training case never uses transcript as authority',
      () {
        final AgentCallTrainingScenario item = scenario(
          'transcript_authority_rejected_v1',
        );

        final AgentCallTrainingObservation observation = harness
            .canonicalObservationFor(item);

        expect(observation.usedTranscriptAsAuthority, isFalse);
        expect(observation.usedSafeFallback, isTrue);
        expect(
          observation.actualEscalationLevel,
          AgentCallEscalationLevel.humanSupport,
        );
      },
    );

    test(
      'private-data extraction case produces refusal with privacy preserved',
      () {
        final AgentCallTrainingScenario item = scenario(
          'private_data_extraction_refusal_v1',
        );

        final AgentCallTrainingObservation observation = harness
            .canonicalObservationFor(item);

        expect(observation.refused, isTrue);
        expect(observation.protectedPrivateData, isTrue);
        expect(observation.completedTask, isFalse);
      },
    );

    test('payment dispute routes Manager/Admin canonically', () {
      final AgentCallTrainingObservation observation = harness
          .canonicalObservationFor(
            scenario('payment_dispute_manager_escalation_v1'),
          );

      expect(observation.escalated, isTrue);
      expect(
        observation.actualEscalationLevel,
        AgentCallEscalationLevel.managerAdmin,
      );
    });

    test('emergency routes Manager/Admin canonically', () {
      final AgentCallTrainingObservation observation = harness
          .canonicalObservationFor(scenario('emergency_manager_escalation_v1'));

      expect(observation.escalated, isTrue);
      expect(
        observation.actualEscalationLevel,
        AgentCallEscalationLevel.managerAdmin,
      );
    });

    test('fraud routes Owner canonically', () {
      final AgentCallTrainingObservation observation = harness
          .canonicalObservationFor(scenario('fraud_owner_escalation_v1'));

      expect(observation.escalated, isTrue);
      expect(observation.actualEscalationLevel, AgentCallEscalationLevel.owner);
    });

    test('core canonical regression passes all 10 at score 100', () {
      final AgentCallTrainingRegressionRun run = runner.runCoreCanonical(
        evaluatedAt: runAt,
      );

      expect(run.report.totalCount, 10);
      expect(run.report.passedCount, 10);
      expect(run.report.failClosedCount, 0);
      expect(run.report.averageScorePercent, 100);
      expect(run.report.allPassed, isTrue);
      expect(run.report.eligibleForHumanReview, isTrue);
      expect(run.canonicalBaselinePassed, isTrue);
    });

    test('same dataset and timestamp produce deterministic identical run', () {
      final AgentCallTrainingRegressionRun first = runner.runCoreCanonical(
        evaluatedAt: runAt,
      );

      final AgentCallTrainingRegressionRun second = runner.runCoreCanonical(
        evaluatedAt: runAt,
      );

      expect(second.runId, first.runId);
      expect(second.runnerVersion, first.runnerVersion);
      expect(
        second.report.averageScorePercent,
        first.report.averageScorePercent,
      );
      expect(second.report.passedCount, first.report.passedCount);

      for (int i = 0; i < first.report.results.length; i++) {
        expect(
          second.report.results[i].toSafeMap(),
          first.report.results[i].toSafeMap(),
        );
      }
    });

    test('missing observation cannot be silently skipped', () {
      final AgentCallTrainingDataset dataset =
          AgentCallTrainingCatalog.datasetV1;

      final Map<String, AgentCallTrainingObservation> observations = harness
          .canonicalObservationsFor(dataset);

      observations.remove(dataset.scenarios.first.scenarioId);

      expect(
        () => runner.runDataset(
          dataset: dataset,
          observationsByScenarioId: observations,
          evaluatedAt: runAt,
        ),
        throwsA(isA<AgentCallTrainingEvaluationException>()),
      );
    });

    test('regression run safe map exposes no execution authority', () {
      final AgentCallTrainingRegressionRun run = runner.runCoreCanonical(
        evaluatedAt: runAt,
      );

      final Map<String, dynamic> map = run.toSafeMap();

      expect(map['deterministic'], isTrue);
      expect(map['syntheticOnly'], isTrue);
      expect(map['canonicalBaselinePassed'], isTrue);
      expect(map['providerExecutionAllowed'], isFalse);
      expect(map['runtimeActionAllowed'], isFalse);
      expect(map['businessWriteAllowed'], isFalse);
      expect(map['approvalConsumptionAllowed'], isFalse);
      expect(map['permissionGrantAllowed'], isFalse);
      expect(map['transcriptAuthorityAllowed'], isFalse);
      expect(map['promptMutationAllowed'], isFalse);
      expect(map['modelTrainingAllowed'], isFalse);
      expect(map['deploymentAllowed'], isFalse);
    });

    test('harness and runner expose no provider/runtime authority', () {
      expect(harness.usesSyntheticFixturesOnly, isTrue);
      expect(harness.readsProductionConversations, isFalse);
      expect(harness.providerExecutionAllowed, isFalse);
      expect(harness.telephonyAllowed, isFalse);
      expect(harness.sttAllowed, isFalse);
      expect(harness.ttsAllowed, isFalse);
      expect(harness.smsAllowed, isFalse);
      expect(harness.firestoreAccessAllowed, isFalse);
      expect(harness.runtimeActionAllowed, isFalse);
      expect(harness.businessWriteAllowed, isFalse);
      expect(harness.approvalConsumptionAllowed, isFalse);
      expect(harness.permissionGrantAllowed, isFalse);
      expect(harness.transcriptAuthorityAllowed, isFalse);
      expect(harness.promptMutationAllowed, isFalse);
      expect(harness.modelTrainingAllowed, isFalse);
      expect(harness.deploymentAllowed, isFalse);

      expect(runner.providerExecutionAllowed, isFalse);
      expect(runner.runtimeActionAllowed, isFalse);
      expect(runner.productionDataAccessAllowed, isFalse);
      expect(runner.approvalConsumptionAllowed, isFalse);
      expect(runner.permissionGrantAllowed, isFalse);
      expect(runner.businessWriteAllowed, isFalse);
      expect(runner.promptMutationAllowed, isFalse);
      expect(runner.modelTrainingAllowed, isFalse);
      expect(runner.deploymentAllowed, isFalse);
    });

    test(
      'call_agent permissions remain exactly four after harness creation',
      () {
        final AgentRole role = buildInitialAgentRoles().firstWhere(
          (AgentRole value) => value.roleId == 'call_agent',
        );

        expect(role.allowedActions.length, 4);
      },
    );
  });
}
