import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_action_ids.dart';
import 'package:swat_ride/ai_agent/constants/agent_call_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_evaluation_constants.dart';
import 'package:swat_ride/ai_agent/data/initial_agent_roles_seed.dart';
import 'package:swat_ride/ai_agent/models/agent_call_training_dataset.dart';
import 'package:swat_ride/ai_agent/models/agent_evaluation_case.dart';
import 'package:swat_ride/ai_agent/models/agent_role.dart';
import 'package:swat_ride/ai_agent/services/agent_call_training_catalog.dart';

void main() {
  group('Phase 50 Step 1B Call training dataset contract', () {
    test('core Call training dataset validates and is versioned', () {
      final AgentCallTrainingDataset dataset =
          AgentCallTrainingCatalog.datasetV1;

      expect(dataset.datasetId, 'call_training_core_v1');
      expect(dataset.version, 1);
      expect(dataset.scenarios.length, 10);
      expect(dataset.validate, returnsNormally);
      expect(AgentCallTrainingCatalog.validateCoreDataset, returnsNormally);
    });

    test('dataset covers all four Phase 49 Call capabilities', () {
      final Set<String> capabilities = AgentCallTrainingCatalog
          .datasetV1
          .scenarios
          .map((AgentCallTrainingScenario scenario) => scenario.capability)
          .toSet();

      expect(capabilities, containsAll(AgentCallTrainingCapability.values));
      expect(AgentCallTrainingCapability.values.length, 4);
    });

    test('dataset is synthetic offline and grants no runtime authority', () {
      final AgentCallTrainingDataset dataset =
          AgentCallTrainingCatalog.datasetV1;

      expect(dataset.usesLiveTelephony, isFalse);
      expect(dataset.usesStt, isFalse);
      expect(dataset.usesTts, isFalse);
      expect(dataset.usesSms, isFalse);
      expect(dataset.usesProductionBusinessData, isFalse);
      expect(dataset.silentlySelfTrains, isFalse);
      expect(dataset.autoDeploys, isFalse);
      expect(dataset.expandsPermissions, isFalse);
      expect(dataset.transcriptIsAuthority, isFalse);

      final Map<String, dynamic> manifest = dataset.toSafeManifest();

      expect(manifest['mode'], AgentCallTrainingDatasetMode.syntheticOffline);
      expect(manifest['expandsPermissions'], isFalse);
      expect(manifest['transcriptIsAuthority'], isFalse);
    });

    test('every scenario inherits locked privacy and authority rules', () {
      for (final AgentCallTrainingScenario scenario
          in AgentCallTrainingCatalog.datasetV1.scenarios) {
        expect(scenario.isSyntheticOnly, isTrue);
        expect(scenario.isRuntimeExecutable, isFalse);
        expect(scenario.mayTrainModel, isFalse);
        expect(scenario.mayChangePrompt, isFalse);
        expect(scenario.mayDeploy, isFalse);
        expect(scenario.mayConsumeApproval, isFalse);
        expect(scenario.mayGrantAuthority, isFalse);
        expect(scenario.mustProtectPrivateData, isTrue);
        expect(scenario.mustNotWriteBusinessData, isTrue);
        expect(scenario.mustNotGrantPermission, isTrue);
        expect(scenario.mustNotUseTranscriptAsAuthority, isTrue);
        expect(scenario.mustNotUseLiveProvider, isTrue);
      }
    });

    test('Phase 42 evaluation mapping stays synthetic and non-executable', () {
      final List<AgentEvaluationCase> cases = AgentCallTrainingCatalog.datasetV1
          .toEvaluationCases();

      expect(cases.length, AgentCallTrainingCatalog.datasetV1.scenarios.length);

      for (final AgentEvaluationCase evaluationCase in cases) {
        expect(evaluationCase.roleId, 'call_agent');
        expect(evaluationCase.module, 'call');
        expect(evaluationCase.fixtureSafety.safeForEvaluation, isTrue);
        expect(evaluationCase.isRuntimeExecutable, isFalse);
        expect(evaluationCase.mayGrantPermission, isFalse);
        expect(evaluationCase.mayConsumeApproval, isFalse);
        expect(evaluationCase.mayWriteBusinessData, isFalse);
        expect(evaluationCase.mayChangePrompt, isFalse);
        expect(evaluationCase.mayTrainModel, isFalse);
        expect(evaluationCase.mayDeploy, isFalse);
        expect(evaluationCase.expectation.mustProtectPrivateData, isTrue);
        expect(evaluationCase.expectation.mustNotWrite, isTrue);
        expect(evaluationCase.expectation.mustNotDeploy, isTrue);
      }
    });

    test('normal status cases are read-only evaluation decisions', () {
      final List<AgentCallTrainingScenario> scenarios =
          AgentCallTrainingCatalog.datasetV1.scenarios;

      for (final String capability in <String>[
        AgentCallTrainingCapability.existingRideStatus,
        AgentCallTrainingCapability.foodOrderStatus,
        AgentCallTrainingCapability.tourBookingStatus,
      ]) {
        final AgentCallTrainingScenario scenario = scenarios.firstWhere(
          (AgentCallTrainingScenario value) =>
              value.capability == capability &&
              value.expectedActionId.isNotEmpty,
        );

        expect(
          scenario.expectedEvaluationDecision,
          AgentEvaluationExpectedDecision.answerReadOnly,
        );
        expect(scenario.expectedEscalationLevel, AgentCallEscalationLevel.ai);
        expect(scenario.requiresTrustedBinding, isTrue);
        expect(scenario.requiresFreshVerification, isTrue);
      }
    });

    test('Ride booking training keeps confirmation requirement explicit', () {
      final List<AgentCallTrainingScenario> rideScenarios =
          AgentCallTrainingCatalog.datasetV1.scenarios
              .where(
                (AgentCallTrainingScenario value) =>
                    value.capability == AgentCallTrainingCapability.rideBooking,
              )
              .toList();

      expect(rideScenarios.length, 2);
      expect(
        rideScenarios.every(
          (AgentCallTrainingScenario value) =>
              value.requiresCustomerConfirmation,
        ),
        isTrue,
      );

      expect(
        rideScenarios.any(
          (AgentCallTrainingScenario value) =>
              value.expectedEvaluationDecision ==
              AgentEvaluationExpectedDecision.safeFallback,
        ),
        isTrue,
      );
    });

    test('high-risk scenarios preserve Phase 49 escalation ladder', () {
      final List<AgentCallTrainingScenario> scenarios =
          AgentCallTrainingCatalog.datasetV1.scenarios;

      final AgentCallTrainingScenario payment = scenarios.firstWhere(
        (AgentCallTrainingScenario value) =>
            value.scenarioId.contains('payment_dispute'),
      );

      final AgentCallTrainingScenario emergency = scenarios.firstWhere(
        (AgentCallTrainingScenario value) =>
            value.scenarioId.contains('emergency'),
      );

      final AgentCallTrainingScenario fraud = scenarios.firstWhere(
        (AgentCallTrainingScenario value) => value.scenarioId.contains('fraud'),
      );

      expect(
        payment.expectedEscalationLevel,
        AgentCallEscalationLevel.managerAdmin,
      );
      expect(
        emergency.expectedEscalationLevel,
        AgentCallEscalationLevel.managerAdmin,
      );
      expect(fraud.expectedEscalationLevel, AgentCallEscalationLevel.owner);

      expect(
        payment.expectedEvaluationDecision,
        AgentEvaluationExpectedDecision.escalate,
      );
      expect(
        emergency.expectedEvaluationDecision,
        AgentEvaluationExpectedDecision.escalate,
      );
      expect(
        fraud.expectedEvaluationDecision,
        AgentEvaluationExpectedDecision.escalate,
      );
    });

    test('transcript-alone authority attempt fails closed', () {
      final AgentCallTrainingScenario scenario = AgentCallTrainingCatalog
          .datasetV1
          .scenarios
          .firstWhere(
            (AgentCallTrainingScenario value) =>
                value.scenarioId == 'transcript_authority_rejected_v1',
          );

      expect(scenario.expectedActionId, isEmpty);
      expect(
        scenario.expectedEscalationLevel,
        AgentCallEscalationLevel.humanSupport,
      );
      expect(
        scenario.expectedEvaluationDecision,
        AgentEvaluationExpectedDecision.safeFallback,
      );
      expect(scenario.mustNotUseTranscriptAsAuthority, isTrue);
    });

    test('private-data extraction attempt is refused', () {
      final AgentCallTrainingScenario scenario = AgentCallTrainingCatalog
          .datasetV1
          .scenarios
          .firstWhere(
            (AgentCallTrainingScenario value) =>
                value.scenarioId == 'private_data_extraction_refusal_v1',
          );

      expect(scenario.expectedActionId, isEmpty);
      expect(
        scenario.expectedEvaluationDecision,
        AgentEvaluationExpectedDecision.refuse,
      );

      final AgentEvaluationCase evaluationCase = scenario.toEvaluationCase(
        createdAt: AgentCallTrainingCatalog.datasetV1.createdAt,
      );

      expect(evaluationCase.expectation.mustRefuse, isTrue);
      expect(evaluationCase.expectation.mustProtectPrivateData, isTrue);
    });

    test('scenario action IDs never exceed four Phase 49 actions', () {
      const Set<String> allowedActions = <String>{
        AgentActionId.createCallRideBooking,
        AgentActionId.readCallExistingRide,
        AgentActionId.readCallFoodOrderStatus,
        AgentActionId.readCallTourBookingStatus,
      };

      for (final AgentCallTrainingScenario scenario
          in AgentCallTrainingCatalog.datasetV1.scenarios) {
        if (scenario.expectedActionId.isEmpty) {
          continue;
        }

        expect(allowedActions, contains(scenario.expectedActionId));
      }
    });

    test(
      'call_agent permissions remain exactly four after training contract',
      () {
        final AgentRole role = buildInitialAgentRoles().firstWhere(
          (AgentRole value) => value.roleId == 'call_agent',
        );

        expect(role.allowedActions, <String>[
          AgentActionId.createCallRideBooking,
          AgentActionId.readCallExistingRide,
          AgentActionId.readCallFoodOrderStatus,
          AgentActionId.readCallTourBookingStatus,
        ]);
      },
    );

    test('duplicate scenario IDs are rejected', () {
      final AgentCallTrainingDataset source =
          AgentCallTrainingCatalog.datasetV1;

      final AgentCallTrainingDataset invalid = AgentCallTrainingDataset(
        datasetId: 'invalid_duplicate_dataset',
        version: 1,
        createdAt: source.createdAt,
        scenarios: <AgentCallTrainingScenario>[
          source.scenarios.first,
          source.scenarios.first,
          ...source.scenarios.skip(1),
        ],
      );

      expect(
        invalid.validate,
        throwsA(isA<AgentCallTrainingDatasetException>()),
      );
    });

    test('missing one Phase 49 capability is rejected', () {
      final AgentCallTrainingDataset source =
          AgentCallTrainingCatalog.datasetV1;

      final AgentCallTrainingDataset invalid = AgentCallTrainingDataset(
        datasetId: 'invalid_missing_tour',
        version: 1,
        createdAt: source.createdAt,
        scenarios: source.scenarios
            .where(
              (AgentCallTrainingScenario value) =>
                  value.capability !=
                  AgentCallTrainingCapability.tourBookingStatus,
            )
            .toList(),
      );

      expect(
        invalid.validate,
        throwsA(isA<AgentCallTrainingDatasetException>()),
      );
    });
  });
}
