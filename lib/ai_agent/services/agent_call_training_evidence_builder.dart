import '../constants/agent_action_ids.dart';
import '../data/initial_agent_roles_seed.dart';
import '../models/agent_call_training_evidence.dart';
import '../models/agent_role.dart';
import 'agent_call_training_coverage_gate.dart';
import 'agent_call_training_regression_runner.dart';

class AgentCallTrainingEvidenceBuilder {
  const AgentCallTrainingEvidenceBuilder({
    this.regressionRunner = const AgentCallTrainingRegressionRunner(),
    this.coverageGate = const AgentCallTrainingCoverageGate(),
  });

  final AgentCallTrainingRegressionRunner regressionRunner;
  final AgentCallTrainingCoverageGate coverageGate;

  AgentCallTrainingEvidence buildCoreEvidence({required DateTime recordedAt}) {
    final DateTime at = recordedAt.toUtc();

    final canonicalRun = regressionRunner.runCoreCanonical(evaluatedAt: at);

    final coverage = coverageGate.evaluate(evaluatedAt: at);

    final AgentRole callRole = buildInitialAgentRoles().firstWhere(
      (AgentRole role) => role.roleId == 'call_agent',
    );

    const List<String> expectedActions = <String>[
      AgentActionId.createCallRideBooking,
      AgentActionId.readCallExistingRide,
      AgentActionId.readCallFoodOrderStatus,
      AgentActionId.readCallTourBookingStatus,
    ];

    final List<String> actualActions = List<String>.from(
      callRole.allowedActions,
    );

    final bool permissionBoundaryVerified =
        actualActions.length == expectedActions.length &&
        actualActions.toSet().containsAll(expectedActions.toSet()) &&
        expectedActions.toSet().containsAll(actualActions.toSet());

    final List<String> requiredFamilies = coverage.requiredFamilies.toList()
      ..sort();

    final List<String> coveredFamilies = coverage.coveredFamilies.toList()
      ..sort();

    final List<String> actions = List<String>.from(actualActions)..sort();

    final String evidenceId =
        'call_training_evidence_v1_'
        '${canonicalRun.datasetId}_'
        'v${canonicalRun.datasetVersion}_'
        '${at.microsecondsSinceEpoch}';

    final AgentCallTrainingEvidence provisional = AgentCallTrainingEvidence(
      evidenceId: evidenceId,
      evidenceVersion: AgentCallTrainingEvidence.currentEvidenceVersion,
      datasetId: canonicalRun.datasetId,
      datasetVersion: canonicalRun.datasetVersion,
      runnerVersion: canonicalRun.runnerVersion,
      canonicalScenarioCount: canonicalRun.report.totalCount,
      canonicalPassedCount: canonicalRun.report.passedCount,
      canonicalAverageScorePercent: canonicalRun.report.averageScorePercent,
      canonicalBaselinePassed: canonicalRun.canonicalBaselinePassed,
      adversarialScenarioCount: coverage.adversarialReports.length,
      requiredAdversarialFamilies: requiredFamilies,
      coveredAdversarialFamilies: coveredFamilies,
      allAdversarialFailuresDetected: coverage.allAdversarialFailuresDetected,
      noUnexpectedAdversarialPasses: coverage.noUnexpectedAdversarialPasses,
      coverageGatePassed: coverage.gatePassed,
      callAgentActions: actions,
      permissionBoundaryVerified: permissionBoundaryVerified,
      recordedAt: at,
      integrityFingerprint: 'PENDING',
    );

    final String fingerprint = AgentCallTrainingEvidenceFingerprint.compute(
      provisional.canonicalFingerprintPayload(),
    );

    final AgentCallTrainingEvidence evidence = AgentCallTrainingEvidence(
      evidenceId: provisional.evidenceId,
      evidenceVersion: provisional.evidenceVersion,
      datasetId: provisional.datasetId,
      datasetVersion: provisional.datasetVersion,
      runnerVersion: provisional.runnerVersion,
      canonicalScenarioCount: provisional.canonicalScenarioCount,
      canonicalPassedCount: provisional.canonicalPassedCount,
      canonicalAverageScorePercent: provisional.canonicalAverageScorePercent,
      canonicalBaselinePassed: provisional.canonicalBaselinePassed,
      adversarialScenarioCount: provisional.adversarialScenarioCount,
      requiredAdversarialFamilies: provisional.requiredAdversarialFamilies,
      coveredAdversarialFamilies: provisional.coveredAdversarialFamilies,
      allAdversarialFailuresDetected:
          provisional.allAdversarialFailuresDetected,
      noUnexpectedAdversarialPasses: provisional.noUnexpectedAdversarialPasses,
      coverageGatePassed: provisional.coverageGatePassed,
      callAgentActions: provisional.callAgentActions,
      permissionBoundaryVerified: provisional.permissionBoundaryVerified,
      recordedAt: provisional.recordedAt,
      integrityFingerprint: fingerprint,
    );

    evidence.validate();
    return evidence;
  }

  bool get readsProductionConversations => false;
  bool get persistsEvidenceToBackend => false;
  bool get cryptographicallySignsEvidence => false;
  bool get providerExecutionAllowed => false;
  bool get runtimeActionAllowed => false;
  bool get businessWriteAllowed => false;
  bool get approvalConsumptionAllowed => false;
  bool get permissionGrantAllowed => false;
  bool get promptMutationAllowed => false;
  bool get modelTrainingAllowed => false;
  bool get deploymentAllowed => false;
}
