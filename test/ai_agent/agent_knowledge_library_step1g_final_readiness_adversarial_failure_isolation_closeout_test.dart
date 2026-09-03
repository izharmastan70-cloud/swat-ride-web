import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_knowledge_library_closeout_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_knowledge_library_adversarial_scenario.dart';
import 'package:swat_ride/ai_agent/services/agent_knowledge_library_adversarial_gate.dart';
import 'package:swat_ride/ai_agent/services/agent_knowledge_library_final_readiness_service.dart';

void main() {
  const AgentKnowledgeLibraryAdversarialGate adversarialGate =
      AgentKnowledgeLibraryAdversarialGate();

  const AgentKnowledgeLibraryFinalReadinessService readiness =
      AgentKnowledgeLibraryFinalReadinessService();

  group('Phase 57 Step 1G final closeout', () {
    test('24 adversarial scenarios are locked', () {
      expect(AgentKnowledgeAdversarialType.values.length, 24);
    });

    test('5 failure-isolation scenarios are isolated', () {
      for (final String type in <String>{
        AgentKnowledgeAdversarialType.retrievalFailure,
        AgentKnowledgeAdversarialType.conflictResolverFailure,
        AgentKnowledgeAdversarialType.groundingFailure,
        AgentKnowledgeAdversarialType.responseGuardFailure,
        AgentKnowledgeAdversarialType.providerFailure,
      }) {
        final decision = adversarialGate.evaluate(
          AgentKnowledgeLibraryAdversarialScenario(
            type: type,
            requiresNoAnswer: false,
            requiresFailureIsolation: true,
          ),
        );

        expect(decision, AgentKnowledgeAdversarialDecision.isolateFailure);
      }
    });

    test('all non-failure adversarial scenarios block to no-answer', () {
      final failureTypes = <String>{
        AgentKnowledgeAdversarialType.retrievalFailure,
        AgentKnowledgeAdversarialType.conflictResolverFailure,
        AgentKnowledgeAdversarialType.groundingFailure,
        AgentKnowledgeAdversarialType.responseGuardFailure,
        AgentKnowledgeAdversarialType.providerFailure,
      };

      for (final String type in AgentKnowledgeAdversarialType.values.where(
        (String value) => !failureTypes.contains(value),
      )) {
        final decision = adversarialGate.evaluate(
          AgentKnowledgeLibraryAdversarialScenario(
            type: type,
            requiresNoAnswer: true,
            requiresFailureIsolation: false,
          ),
        );

        expect(
          decision,
          AgentKnowledgeAdversarialDecision.blockNoAnswer,
          reason: 'Scenario must fail closed: $type',
        );
      }
    });

    test('prompt injection is non-authoritative and blocked', () {
      expect(adversarialGate.promptInjectionBlocked, true);
      expect(adversarialGate.allExternalInputsNonAuthoritative, true);
    });

    test('user cannot self-claim knowledge authority', () {
      expect(adversarialGate.userAuthorityClaimBlocked, true);
    });

    test('WhatsApp message cannot self-approve knowledge', () {
      expect(adversarialGate.whatsappApprovalClaimBlocked, true);
    });

    test('social comment cannot become policy authority', () {
      expect(adversarialGate.socialCommentPolicyClaimBlocked, true);
    });

    test('provider output cannot self-declare truth', () {
      expect(adversarialGate.providerOutputTruthClaimBlocked, true);
    });

    test('stale deprecated unapproved knowledge remains blocked', () {
      expect(adversarialGate.staleDeprecatedUnapprovedBlocked, true);
    });

    test('cross-scope leakage remains blocked', () {
      expect(adversarialGate.crossScopeLeakageBlocked, true);
    });

    test('equal precedence conflict remains no-answer', () {
      expect(adversarialGate.equalPrecedenceConflictNoAnswer, true);
    });

    test('language mismatch remains no-answer', () {
      expect(adversarialGate.languageMismatchNoAnswer, true);
    });

    test('private payload and secret exfiltration are blocked', () {
      expect(adversarialGate.privatePayloadBlocked, true);
      expect(adversarialGate.secretExfiltrationBlocked, true);
    });

    test('unauthorized Owner WhatsApp read is blocked', () {
      expect(adversarialGate.unauthorizedOwnerWhatsAppReadBlocked, true);
    });

    test('WhatsApp send attempt remains blocked in Phase 57', () {
      expect(adversarialGate.whatsappSendAttemptBlocked, true);
    });

    test('index write attempt remains blocked in Phase 57', () {
      expect(adversarialGate.indexWriteAttemptBlocked, true);
    });

    test('permission grant and approval consume attempts are blocked', () {
      expect(adversarialGate.permissionGrantAttemptBlocked, true);
      expect(adversarialGate.approvalConsumeAttemptBlocked, true);
    });

    test('business action attempt remains blocked', () {
      expect(adversarialGate.businessActionAttemptBlocked, true);
    });

    test('knowledge subsystem failures are isolated from core app', () {
      expect(adversarialGate.retrievalFailureIsolated, true);
      expect(adversarialGate.conflictResolverFailureIsolated, true);
      expect(adversarialGate.groundingFailureIsolated, true);
      expect(adversarialGate.responseGuardFailureIsolated, true);
      expect(adversarialGate.providerFailureIsolated, true);
      expect(adversarialGate.coreAppContinuesIfKnowledgeFails, true);
    });

    test('adversarial scenario grants no authority', () {
      const scenario = AgentKnowledgeLibraryAdversarialScenario(
        type: AgentKnowledgeAdversarialType.promptInjection,
        requiresNoAnswer: true,
        requiresFailureIsolation: false,
      );

      expect(scenario.inputIsNeverAuthority, true);
      expect(scenario.mayGrantPermission, false);
      expect(scenario.mayConsumeApproval, false);
      expect(scenario.mayExpandScope, false);
      expect(scenario.mayExecuteBusinessAction, false);
      expect(scenario.mayWriteIndex, false);
      expect(scenario.maySendWhatsApp, false);
      expect(scenario.mayPersistKnowledge, false);
    });

    test(
      'adversarial gate itself executes no authority/write/provider action',
      () {
        expect(adversarialGate.grantsPermission, false);
        expect(adversarialGate.consumesApproval, false);
        expect(adversarialGate.expandsScope, false);
        expect(adversarialGate.executesBusinessAction, false);
        expect(adversarialGate.writesIndex, false);
        expect(adversarialGate.sendsWhatsApp, false);
        expect(adversarialGate.invokesProvider, false);
        expect(adversarialGate.persistsDecision, false);
      },
    );

    test('all clean foundations produce ready-not-active status', () {
      final report = readiness.evaluate(
        step1BContractClean: true,
        step1CIngestionClean: true,
        step1DRetrievalClean: true,
        step1EConflictCitationClean: true,
        step1FPrivacyLanguageWhatsAppClean: true,
        adversarialGateClean: true,
        failureIsolationClean: true,
      );

      expect(report.readyNotActive, true);
      expect(
        report.status,
        AgentKnowledgeLibraryReadinessStatus.foundationReadyNotProductionActive,
      );
      expect(report.foundationReady, true);
      expect(report.productionActive, false);
    });

    test('missing foundation blocks readiness', () {
      final report = readiness.evaluate(
        step1BContractClean: true,
        step1CIngestionClean: true,
        step1DRetrievalClean: false,
        step1EConflictCitationClean: true,
        step1FPrivacyLanguageWhatsAppClean: true,
        adversarialGateClean: true,
        failureIsolationClean: true,
      );

      expect(
        report.status,
        AgentKnowledgeLibraryReadinessStatus.blockedSafetyContract,
      );
      expect(report.foundationReady, false);
      expect(report.productionActive, false);
    });

    test('adversarial failure blocks readiness', () {
      final report = readiness.evaluate(
        step1BContractClean: true,
        step1CIngestionClean: true,
        step1DRetrievalClean: true,
        step1EConflictCitationClean: true,
        step1FPrivacyLanguageWhatsAppClean: true,
        adversarialGateClean: false,
        failureIsolationClean: true,
      );

      expect(
        report.status,
        AgentKnowledgeLibraryReadinessStatus.blockedAdversarialScenario,
      );
      expect(report.foundationReady, false);
      expect(report.productionActive, false);
    });

    test('failure isolation failure blocks readiness', () {
      final report = readiness.evaluate(
        step1BContractClean: true,
        step1CIngestionClean: true,
        step1DRetrievalClean: true,
        step1EConflictCitationClean: true,
        step1FPrivacyLanguageWhatsAppClean: true,
        adversarialGateClean: true,
        failureIsolationClean: false,
      );

      expect(
        report.status,
        AgentKnowledgeLibraryReadinessStatus.blockedAdversarialScenario,
      );
      expect(report.foundationReady, false);
    });

    test('ready report keeps all production connectors inactive', () {
      final report = readiness.evaluate(
        step1BContractClean: true,
        step1CIngestionClean: true,
        step1DRetrievalClean: true,
        step1EConflictCitationClean: true,
        step1FPrivacyLanguageWhatsAppClean: true,
        adversarialGateClean: true,
        failureIsolationClean: true,
      );

      expect(report.realDatabaseIndexConnectorActive, false);
      expect(report.realRawContentRetrievalActive, false);
      expect(report.realProviderConnectorActive, false);
      expect(report.ownerWhatsAppSendActive, false);
      expect(report.productionPersistenceActive, false);
    });

    test('ready report preserves information-only/no-answer boundaries', () {
      final report = readiness.evaluate(
        step1BContractClean: true,
        step1CIngestionClean: true,
        step1DRetrievalClean: true,
        step1EConflictCitationClean: true,
        step1FPrivacyLanguageWhatsAppClean: true,
        adversarialGateClean: true,
        failureIsolationClean: true,
      );

      expect(report.knowledgeIsInformationOnly, true);
      expect(report.noAnswerInsteadOfGuess, true);
      expect(report.scopeMustStayPreauthorized, true);
      expect(report.approvalMustStayExternal, true);
      expect(report.permissionMustStayExternal, true);
      expect(report.businessActionsStayExternal, true);
      expect(report.coreAppFailureIsolationRequired, true);
    });

    test(
      'ready report executes no permission/approval/business/provider action',
      () {
        final report = readiness.evaluate(
          step1BContractClean: true,
          step1CIngestionClean: true,
          step1DRetrievalClean: true,
          step1EConflictCitationClean: true,
          step1FPrivacyLanguageWhatsAppClean: true,
          adversarialGateClean: true,
          failureIsolationClean: true,
        );

        expect(report.grantsPermission, false);
        expect(report.consumesApproval, false);
        expect(report.expandsScope, false);
        expect(report.executesBusinessAction, false);
        expect(report.writesBusinessData, false);
        expect(report.sendsWhatsApp, false);
        expect(report.invokesProvider, false);
        expect(report.persistsReport, false);
      },
    );

    test('readiness service locks Phase 57 closeout ownership', () {
      expect(readiness.phase57FoundationComplete, true);
      expect(readiness.productionActivationDeferred, true);
      expect(readiness.databaseIndexConnectorDeferred, true);
      expect(readiness.rawContentRetrievalConnectorDeferred, true);
      expect(readiness.providerConnectorDeferred, true);
      expect(readiness.trustedBackendPersistenceDeferred, true);
      expect(readiness.ownerWhatsAppSendDeferred, true);
      expect(readiness.conversationGroundingStillRequired, true);
      expect(readiness.responseGuardStillRequired, true);
      expect(readiness.phase55VideoCatalogStillSeparate, true);
      expect(readiness.phase62TrainingDeploymentStillSeparate, true);
      expect(readiness.phase63PrivacyRetentionUiStillSeparate, true);
    });

    test('readiness service adds no production authority', () {
      expect(readiness.grantsPermission, false);
      expect(readiness.consumesApproval, false);
      expect(readiness.expandsScope, false);
      expect(readiness.executesBusinessAction, false);
      expect(readiness.writesBusinessData, false);
      expect(readiness.writesIndex, false);
      expect(readiness.sendsWhatsApp, false);
      expect(readiness.invokesProvider, false);
      expect(readiness.persistsReadiness, false);
    });
  });
}
