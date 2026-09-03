import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/models/agent_unified_context_readiness_report.dart';
import 'package:swat_ride/ai_agent/services/agent_unified_context_readiness_evaluator.dart';

void main() {
  const AgentUnifiedContextReadinessEvaluator evaluator =
      AgentUnifiedContextReadinessEvaluator();

  group('Phase 52 Step 1G final unified context readiness closeout', () {
    test(
      'all foundation checks produce foundation-ready not production-active',
      () {
        final AgentUnifiedContextReadinessReport report = evaluator.evaluate(
          step1BDataContractReady: true,
          step1CIdentityScopedAssemblyReady: true,
          step1DFreshnessConflictResolutionReady: true,
          step1EMinimumDisclosureProjectionReady: true,
          step1FContinuityFailureIsolationReady: true,
          phase51ContinuityBoundaryPreserved: true,
          callAgentExactFourActionsPreserved: true,
          permissionApprovalRuntimeAuthorityPreserved: true,
        );

        expect(
          report.status,
          AgentUnifiedContextReadinessStatus.foundationReadyNotProductionActive,
        );
        expect(report.foundationReady, isTrue);
        expect(report.productionReady, isFalse);
        expect(report.productionActive, isFalse);
      },
    );

    test('missing any foundation requirement fails closed', () {
      final AgentUnifiedContextReadinessReport report = evaluator.evaluate(
        step1BDataContractReady: true,
        step1CIdentityScopedAssemblyReady: true,
        step1DFreshnessConflictResolutionReady: true,
        step1EMinimumDisclosureProjectionReady: true,
        step1FContinuityFailureIsolationReady: false,
        phase51ContinuityBoundaryPreserved: true,
        callAgentExactFourActionsPreserved: true,
        permissionApprovalRuntimeAuthorityPreserved: true,
      );

      expect(report.status, AgentUnifiedContextReadinessStatus.blocked);
      expect(report.foundationReady, isFalse);
    });

    test('production activation gaps remain explicitly false', () {
      final AgentUnifiedContextReadinessReport report = evaluator.evaluate(
        step1BDataContractReady: true,
        step1CIdentityScopedAssemblyReady: true,
        step1DFreshnessConflictResolutionReady: true,
        step1EMinimumDisclosureProjectionReady: true,
        step1FContinuityFailureIsolationReady: true,
        phase51ContinuityBoundaryPreserved: true,
        callAgentExactFourActionsPreserved: true,
        permissionApprovalRuntimeAuthorityPreserved: true,
      );

      expect(report.productionContextPersistenceActive, isFalse);
      expect(report.fullConversationHistoryStoreActive, isFalse);
      expect(report.crossSubjectContextLoadingActive, isFalse);
      expect(report.providerExecutionActive, isFalse);
      expect(report.targetAgentInvocationActive, isFalse);
      expect(report.runtimeBusinessActionActive, isFalse);
      expect(report.businessWriteActive, isFalse);
      expect(report.phase63PrivacyRetentionControlCenterImplemented, isFalse);
      expect(report.productionUnifiedContextActive, isFalse);
    });

    test(
      'context foundation never becomes permission or execution authority',
      () {
        final AgentUnifiedContextReadinessReport report = evaluator.evaluate(
          step1BDataContractReady: true,
          step1CIdentityScopedAssemblyReady: true,
          step1DFreshnessConflictResolutionReady: true,
          step1EMinimumDisclosureProjectionReady: true,
          step1FContinuityFailureIsolationReady: true,
          phase51ContinuityBoundaryPreserved: true,
          callAgentExactFourActionsPreserved: true,
          permissionApprovalRuntimeAuthorityPreserved: true,
        );

        expect(report.grantsAuthority, isFalse);
        expect(report.grantsPermission, isFalse);
        expect(report.consumesApproval, isFalse);
        expect(report.invokesProvider, isFalse);
        expect(report.invokesTargetAgent, isFalse);
        expect(report.invokesRuntimeGate, isFalse);
        expect(report.writesBusinessData, isFalse);
        expect(report.persistsReport, isFalse);
      },
    );

    test('evaluator itself cannot activate production capabilities', () {
      expect(evaluator.activatesProductionUnifiedContext, isFalse);
      expect(evaluator.enablesContextPersistence, isFalse);
      expect(evaluator.enablesFullConversationHistoryStore, isFalse);
      expect(evaluator.enablesCrossSubjectContextLoading, isFalse);
      expect(evaluator.invokesProvider, isFalse);
      expect(evaluator.invokesTargetAgent, isFalse);
      expect(evaluator.invokesRuntimeGate, isFalse);
      expect(evaluator.writesBusinessData, isFalse);
      expect(evaluator.grantsPermission, isFalse);
      expect(evaluator.consumesApproval, isFalse);
      expect(evaluator.implementsPhase63PrivacyRetentionControlCenter, isFalse);
    });

    test('safe readiness metadata exposes no context payload', () {
      final AgentUnifiedContextReadinessReport report = evaluator.evaluate(
        step1BDataContractReady: true,
        step1CIdentityScopedAssemblyReady: true,
        step1DFreshnessConflictResolutionReady: true,
        step1EMinimumDisclosureProjectionReady: true,
        step1FContinuityFailureIsolationReady: true,
        phase51ContinuityBoundaryPreserved: true,
        callAgentExactFourActionsPreserved: true,
        permissionApprovalRuntimeAuthorityPreserved: true,
      );

      final Map<String, dynamic> map = report.toSafeMap();

      expect(map.containsKey('sanitizedValue'), isFalse);
      expect(map.containsKey('messageHistory'), isFalse);
      expect(map.containsKey('conversationTranscript'), isFalse);
      expect(map['productionReady'], isFalse);
      expect(map['productionActive'], isFalse);
      expect(map['invokesProvider'], isFalse);
      expect(map['writesBusinessData'], isFalse);
    });
  });
}
