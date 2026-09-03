import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_performance_dashboard_closeout_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_performance_dashboard_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_performance_dashboard_privacy_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_performance_scoring_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_performance_dashboard_adversarial_scenario.dart';
import 'package:swat_ride/ai_agent/models/agent_performance_dashboard_agent_summary.dart';
import 'package:swat_ride/ai_agent/models/agent_performance_dashboard_read_model.dart';
import 'package:swat_ride/ai_agent/models/agent_performance_dashboard_readiness_input.dart';
import 'package:swat_ride/ai_agent/models/agent_performance_dashboard_safe_projection.dart';
import 'package:swat_ride/ai_agent/services/agent_performance_dashboard_adversarial_gate.dart';
import 'package:swat_ride/ai_agent/services/agent_performance_dashboard_final_readiness_service.dart';
import 'package:swat_ride/ai_agent/services/agent_performance_dashboard_safe_projection_service.dart';

void main() {
  const AgentPerformanceDashboardSafeProjectionService projectionService =
      AgentPerformanceDashboardSafeProjectionService();

  const AgentPerformanceDashboardAdversarialGate adversarialGate =
      AgentPerformanceDashboardAdversarialGate();

  const AgentPerformanceDashboardFinalReadinessService readinessService =
      AgentPerformanceDashboardFinalReadinessService();

  final DateTime evaluatedAtUtc = DateTime.utc(2026, 8, 24, 0, 0);
  final DateTime freshGeneratedAtUtc = evaluatedAtUtc.subtract(
    const Duration(minutes: 10),
  );

  AgentPerformanceDashboardAgentSummary summary({
    String agentId = 'ride_agent',
    String cohortKey = 'support:v1',
    String windowId = 'LAST_7_DAYS',
  }) {
    return AgentPerformanceDashboardAgentSummary(
      agentId: agentId,
      cohortKey: cohortKey,
      windowId: windowId,
      scoreContractVersion: AgentPerformanceScoreContract.version,
      scoreStatus: AgentPerformanceScoreStatus.scoredHighConfidence,
      overallScore: 90,
      confidence: AgentPerformanceScoreConfidence.high,
      comparisonEligible: true,
      includedScorableMetricIds: AgentPerformanceScoreContract.scorableMetricIds
          .toList(),
      contextMetricValues: const <String, double>{},
      insufficientContextMetricIds: const <String>{},
    );
  }

  AgentPerformanceDashboardReadModel readySource({
    String queryId = 'dashboard:closeout',
    List<AgentPerformanceDashboardAgentSummary>? summaries,
  }) {
    final List<AgentPerformanceDashboardAgentSummary> values =
        summaries ?? <AgentPerformanceDashboardAgentSummary>[summary()];

    return AgentPerformanceDashboardReadModel(
      status: AgentPerformanceDashboardStatus.ready,
      queryId: queryId,
      summaries: values,
      totalMatchedBeforeLimit: values.length,
      truncated: false,
      reasonCode: 'read_only_dashboard_projection_ready',
    );
  }

  AgentPerformanceDashboardAdversarialScenario scenarioFromProjection({
    required String scenarioId,
    required AgentPerformanceDashboardSafeProjection projection,
  }) {
    return AgentPerformanceDashboardAdversarialScenario(
      scenarioId: scenarioId,
      projectionStatus: projection.status,
      visibleSummaryCount: projection.summaries.length,
      coreAppContinues: true,
      rawExceptionTextExposed: projection.rawExceptionTextExposed,
      rawPromptExposed: projection.rawPromptExposed,
      privatePayloadExposed: projection.privatePayloadExposed,
      secretExposed: projection.secretExposed,
      authTokenExposed: projection.authTokenExposed,
      approvalTokenExposed: projection.approvalTokenExposed,
      permissionTokenExposed: projection.permissionTokenExposed,
      globalLeaderboardCreated: projection.globalLeaderboardCreated,
      permanentRankAssigned: projection.permanentRankAssigned,
      disciplinaryDecisionMade: projection.disciplinaryDecisionMade,
      routingDecisionMade: projection.routingDecisionMade,
      payDecisionMade: projection.payDecisionMade,
      accessDecisionMade: projection.accessDecisionMade,
      grantsPermission: projection.grantsPermission,
      createsApproval: projection.createsApproval,
      expandsScope: projection.expandsScope,
      assignsRole: projection.assignsRole,
      grantsOwnerAuthority: projection.grantsOwnerAuthority,
      authorizesBusinessExecution: projection.authorizesBusinessExecution,
      executesBusinessAction: projection.executesBusinessAction,
      mutatesAgentState: projection.mutatesAgentState,
      mutatesRouting: projection.mutatesRouting,
      mutatesBudget: projection.mutatesBudget,
      persistsState: projection.persistsProjection,
    );
  }

  List<AgentPerformanceDashboardAdversarialScenario> safeScenarios() {
    final fresh = projectionService.build(
      source: readySource(),
      snapshotGeneratedAtUtc: freshGeneratedAtUtc,
      evaluatedAtUtc: evaluatedAtUtc,
    );

    final unsafeIdentifier = projectionService.build(
      source: readySource(queryId: 'user@example.com'),
      snapshotGeneratedAtUtc: freshGeneratedAtUtc,
      evaluatedAtUtc: evaluatedAtUtc,
    );

    final malformed = projectionService.build(
      source: readySource(
        summaries: <AgentPerformanceDashboardAgentSummary>[
          summary(),
          summary(agentId: ''),
        ],
      ),
      snapshotGeneratedAtUtc: freshGeneratedAtUtc,
      evaluatedAtUtc: evaluatedAtUtc,
    );

    final stale = projectionService.build(
      source: readySource(),
      snapshotGeneratedAtUtc: evaluatedAtUtc.subtract(
        const Duration(minutes: 31),
      ),
      evaluatedAtUtc: evaluatedAtUtc,
    );

    final clockSkew = projectionService.build(
      source: readySource(),
      snapshotGeneratedAtUtc: evaluatedAtUtc.add(const Duration(minutes: 6)),
      evaluatedAtUtc: evaluatedAtUtc,
    );

    final duplicate = projectionService.build(
      source: readySource(
        summaries: <AgentPerformanceDashboardAgentSummary>[
          summary(),
          summary(),
        ],
      ),
      snapshotGeneratedAtUtc: freshGeneratedAtUtc,
      evaluatedAtUtc: evaluatedAtUtc,
    );

    final isolationBudget = projectionService.build(
      source: readySource(
        summaries: List<AgentPerformanceDashboardAgentSummary>.generate(
          AgentPerformanceDashboardPrivacyLimits.maxIsolatedFailures + 1,
          (int index) => summary(agentId: ''),
        ),
      ),
      snapshotGeneratedAtUtc: freshGeneratedAtUtc,
      evaluatedAtUtc: evaluatedAtUtc,
    );

    final blockedSource = projectionService.build(
      source: AgentPerformanceDashboardReadModel(
        status: AgentPerformanceDashboardStatus.blockedInvalidInput,
        queryId: 'dashboard:blocked',
        summaries: const <AgentPerformanceDashboardAgentSummary>[],
        totalMatchedBeforeLimit: 0,
        truncated: false,
        reasonCode: 'private_backend_detail_must_not_escape',
      ),
      snapshotGeneratedAtUtc: freshGeneratedAtUtc,
      evaluatedAtUtc: evaluatedAtUtc,
    );

    return <AgentPerformanceDashboardAdversarialScenario>[
      scenarioFromProjection(
        scenarioId:
            AgentPerformanceDashboardCloseoutScenarioId.freshSafeVisibility,
        projection: fresh,
      ),
      scenarioFromProjection(
        scenarioId:
            AgentPerformanceDashboardCloseoutScenarioId.unsafeIdentifierPrivacy,
        projection: unsafeIdentifier,
      ),
      scenarioFromProjection(
        scenarioId: AgentPerformanceDashboardCloseoutScenarioId
            .malformedSummaryIsolation,
        projection: malformed,
      ),
      scenarioFromProjection(
        scenarioId: AgentPerformanceDashboardCloseoutScenarioId.staleSnapshot,
        projection: stale,
      ),
      scenarioFromProjection(
        scenarioId: AgentPerformanceDashboardCloseoutScenarioId.futureClockSkew,
        projection: clockSkew,
      ),
      scenarioFromProjection(
        scenarioId: AgentPerformanceDashboardCloseoutScenarioId
            .duplicateSummaryIdentity,
        projection: duplicate,
      ),
      scenarioFromProjection(
        scenarioId:
            AgentPerformanceDashboardCloseoutScenarioId.isolationBudgetExceeded,
        projection: isolationBudget,
      ),
      scenarioFromProjection(
        scenarioId: AgentPerformanceDashboardCloseoutScenarioId.blockedSource,
        projection: blockedSource,
      ),
      AgentPerformanceDashboardAdversarialScenario(
        scenarioId: AgentPerformanceDashboardCloseoutScenarioId
            .leaderboardAuthorityAbuse,
        projectionStatus:
            AgentPerformanceDashboardSafeProjectionStatus.blockedSource,
        visibleSummaryCount: 0,
        coreAppContinues: true,
      ),
      AgentPerformanceDashboardAdversarialScenario(
        scenarioId:
            AgentPerformanceDashboardCloseoutScenarioId.securityAuthorityAbuse,
        projectionStatus:
            AgentPerformanceDashboardSafeProjectionStatus.blockedSource,
        visibleSummaryCount: 0,
        coreAppContinues: true,
      ),
    ];
  }

  AgentPerformanceDashboardReadinessInput readyInput({
    List<AgentPerformanceDashboardAdversarialScenario>? scenarios,
    bool step1BReady = true,
    bool step1CReady = true,
    bool step1DReady = true,
    bool step1EReady = true,
    bool step1FReady = true,
    bool securityReady = true,
    bool failureIsolationReady = true,
    bool callAgentExactFour = true,
    bool productionActivationRequested = false,
    String closeoutId = 'phase61:dashboard:closeout',
    String contractVersion = AgentPerformanceDashboardCloseoutContract.version,
  }) {
    return AgentPerformanceDashboardReadinessInput(
      closeoutId: closeoutId,
      contractVersion: contractVersion,
      step1BMetricContractReady: step1BReady,
      step1CAggregationReady: step1CReady,
      step1DScoringFairnessReady: step1DReady,
      step1EReadModelVisibilityReady: step1EReady,
      step1FPrivacyFailureFreshnessReady: step1FReady,
      securityAuthorityAboveDashboard: securityReady,
      coreFailureIsolationReady: failureIsolationReady,
      callAgentExactFourPreserved: callAgentExactFour,
      productionActivationRequested: productionActivationRequested,
      scenarios: scenarios ?? safeScenarios(),
    );
  }

  group('Phase 61 Step 1G adversarial evidence', () {
    test('required scenario catalog is exact and bounded', () {
      expect(AgentPerformanceDashboardCloseoutScenarioId.required.length, 10);
      expect(
        AgentPerformanceDashboardCloseoutContract.maxScenarios,
        greaterThanOrEqualTo(
          AgentPerformanceDashboardCloseoutScenarioId.required.length,
        ),
      );
    });

    test('all safe adversarial scenarios pass gate', () {
      final scenarios = safeScenarios();

      expect(scenarios.length, 10);

      for (final scenario in scenarios) {
        expect(
          adversarialGate.passes(scenario),
          true,
          reason: scenario.scenarioId,
        );
      }
    });

    test('sensitive-data exposure fails gate', () {
      const scenario = AgentPerformanceDashboardAdversarialScenario(
        scenarioId: AgentPerformanceDashboardCloseoutScenarioId.blockedSource,
        projectionStatus:
            AgentPerformanceDashboardSafeProjectionStatus.blockedSource,
        visibleSummaryCount: 0,
        coreAppContinues: true,
        secretExposed: true,
      );

      expect(adversarialGate.passes(scenario), false);
    });

    test('leaderboard creation fails gate', () {
      const scenario = AgentPerformanceDashboardAdversarialScenario(
        scenarioId: AgentPerformanceDashboardCloseoutScenarioId
            .leaderboardAuthorityAbuse,
        projectionStatus:
            AgentPerformanceDashboardSafeProjectionStatus.blockedSource,
        visibleSummaryCount: 0,
        coreAppContinues: true,
        globalLeaderboardCreated: true,
      );

      expect(adversarialGate.passes(scenario), false);
    });

    test('security authority mutation fails gate', () {
      const scenario = AgentPerformanceDashboardAdversarialScenario(
        scenarioId:
            AgentPerformanceDashboardCloseoutScenarioId.securityAuthorityAbuse,
        projectionStatus:
            AgentPerformanceDashboardSafeProjectionStatus.blockedSource,
        visibleSummaryCount: 0,
        coreAppContinues: true,
        grantsPermission: true,
        mutatesSecurity: true,
      );

      expect(adversarialGate.passes(scenario), false);
    });

    test('core app failure propagation fails gate', () {
      const scenario = AgentPerformanceDashboardAdversarialScenario(
        scenarioId: AgentPerformanceDashboardCloseoutScenarioId.blockedSource,
        projectionStatus:
            AgentPerformanceDashboardSafeProjectionStatus.blockedSource,
        visibleSummaryCount: 0,
        coreAppContinues: false,
      );

      expect(adversarialGate.passes(scenario), false);
    });
  });

  group('Phase 61 Step 1G final readiness fail-closed boundary', () {
    test('all verified locks produce foundation ready only', () {
      final report = readinessService.evaluate(readyInput());

      expect(
        report.status,
        AgentPerformanceDashboardCloseoutStatus.foundationReady,
      );
      expect(report.foundationReady, true);
      expect(report.adversarialReady, true);
      expect(report.coreFailureIsolationReady, true);
      expect(report.failedScenarioIds, isEmpty);
      expect(report.productionActive, false);
      expect(report.productionActivationPerformed, false);
      expect(report.securityAuthorityAlwaysAboveDashboard, true);
    });

    test('missing foundation lock fails closed', () {
      final report = readinessService.evaluate(readyInput(step1FReady: false));

      expect(
        report.status,
        AgentPerformanceDashboardCloseoutStatus.blockedFoundation,
      );
      expect(report.foundationReady, false);
      expect(report.productionActive, false);
    });

    test('production activation request fails closed', () {
      final report = readinessService.evaluate(
        readyInput(productionActivationRequested: true),
      );

      expect(
        report.status,
        AgentPerformanceDashboardCloseoutStatus.blockedProductionActivation,
      );
      expect(report.productionActive, false);
    });

    test('missing required adversarial evidence fails closed', () {
      final scenarios = safeScenarios()
          .where(
            (scenario) =>
                scenario.scenarioId !=
                AgentPerformanceDashboardCloseoutScenarioId.futureClockSkew,
          )
          .toList();

      final report = readinessService.evaluate(
        readyInput(scenarios: scenarios),
      );

      expect(
        report.status,
        AgentPerformanceDashboardCloseoutStatus.blockedAdversarial,
      );
      expect(
        report.failedScenarioIds,
        contains(AgentPerformanceDashboardCloseoutScenarioId.futureClockSkew),
      );
    });

    test('one adversarial safety failure blocks closeout', () {
      final scenarios = safeScenarios();
      final index = scenarios.indexWhere(
        (scenario) =>
            scenario.scenarioId ==
            AgentPerformanceDashboardCloseoutScenarioId
                .leaderboardAuthorityAbuse,
      );

      scenarios[index] = const AgentPerformanceDashboardAdversarialScenario(
        scenarioId: AgentPerformanceDashboardCloseoutScenarioId
            .leaderboardAuthorityAbuse,
        projectionStatus:
            AgentPerformanceDashboardSafeProjectionStatus.blockedSource,
        visibleSummaryCount: 0,
        coreAppContinues: true,
        permanentRankAssigned: true,
      );

      final report = readinessService.evaluate(
        readyInput(scenarios: scenarios),
      );

      expect(
        report.status,
        AgentPerformanceDashboardCloseoutStatus.blockedAdversarial,
      );
      expect(
        report.failedScenarioIds,
        contains(
          AgentPerformanceDashboardCloseoutScenarioId.leaderboardAuthorityAbuse,
        ),
      );
    });

    test(
      'duplicate scenario id returns invalid metadata without exception',
      () {
        final scenarios = safeScenarios();
        scenarios.add(scenarios.first);

        final report = readinessService.evaluate(
          readyInput(scenarios: scenarios),
        );

        expect(
          report.status,
          AgentPerformanceDashboardCloseoutStatus.blockedInvalidMetadata,
        );
        expect(report.rawExceptionTextExposed, false);
        expect(report.productionActive, false);
      },
    );

    test('invalid contract version returns safe blocked report', () {
      final report = readinessService.evaluate(
        readyInput(contractVersion: 'wrong-version'),
      );

      expect(
        report.status,
        AgentPerformanceDashboardCloseoutStatus.blockedInvalidMetadata,
      );
      expect(report.rawExceptionTextExposed, false);
      expect(report.privatePayloadExposed, false);
      expect(report.secretExposed, false);
    });

    test('private-looking closeout id is redacted on blocked report', () {
      final report = readinessService.evaluate(
        readyInput(closeoutId: 'owner@example.com'),
      );

      expect(
        report.status,
        AgentPerformanceDashboardCloseoutStatus.blockedInvalidMetadata,
      );
      expect(report.closeoutId, 'redacted:phase61_closeout');
      expect(report.privatePayloadExposed, false);
      expect(report.secretExposed, false);
    });
  });

  group('Phase 61 Step 1G no authority / no production activation', () {
    test(
      'ready report grants no ranking, discipline, routing or pay power',
      () {
        final report = readinessService.evaluate(readyInput());

        expect(report.globalLeaderboardCreated, false);
        expect(report.permanentRankAssigned, false);
        expect(report.disciplinaryDecisionMade, false);
        expect(report.routingDecisionMade, false);
        expect(report.payDecisionMade, false);
        expect(report.accessDecisionMade, false);
      },
    );

    test(
      'ready report grants no Permission Approval Owner or business power',
      () {
        final report = readinessService.evaluate(readyInput());

        expect(report.grantsPermission, false);
        expect(report.createsApproval, false);
        expect(report.expandsScope, false);
        expect(report.assignsRole, false);
        expect(report.grantsOwnerAuthority, false);
        expect(report.authorizesBusinessExecution, false);
        expect(report.executesBusinessAction, false);
      },
    );

    test('ready report performs no protected mutation or persistence', () {
      final report = readinessService.evaluate(readyInput());

      expect(report.mutatesAgentState, false);
      expect(report.mutatesRouting, false);
      expect(report.mutatesBudget, false);
      expect(report.mutatesSecurity, false);
      expect(report.persistsState, false);
      expect(report.productionActive, false);
    });

    test('gate itself exposes no authority or persistence', () {
      expect(adversarialGate.propagatesExceptionText, false);
      expect(adversarialGate.grantsPermission, false);
      expect(adversarialGate.createsApproval, false);
      expect(adversarialGate.createsLeaderboard, false);
      expect(adversarialGate.createsPermanentRank, false);
      expect(adversarialGate.executesBusinessAction, false);
      expect(adversarialGate.mutatesSecurity, false);
      expect(adversarialGate.persistenceImplementedHere, false);
    });
  });
}
