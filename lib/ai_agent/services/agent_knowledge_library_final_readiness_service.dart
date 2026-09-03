import '../constants/agent_knowledge_library_closeout_constants.dart';
import '../models/agent_knowledge_library_readiness_report.dart';

class AgentKnowledgeLibraryFinalReadinessService {
  const AgentKnowledgeLibraryFinalReadinessService();

  AgentKnowledgeLibraryReadinessReport evaluate({
    required bool step1BContractClean,
    required bool step1CIngestionClean,
    required bool step1DRetrievalClean,
    required bool step1EConflictCitationClean,
    required bool step1FPrivacyLanguageWhatsAppClean,
    required bool adversarialGateClean,
    required bool failureIsolationClean,
  }) {
    final bool allFoundationsClean =
        step1BContractClean &&
        step1CIngestionClean &&
        step1DRetrievalClean &&
        step1EConflictCitationClean &&
        step1FPrivacyLanguageWhatsAppClean;

    if (!allFoundationsClean) {
      final AgentKnowledgeLibraryReadinessReport report =
          AgentKnowledgeLibraryReadinessReport(
            status: AgentKnowledgeLibraryReadinessStatus.blockedSafetyContract,
            foundationReady: false,
            productionActive: false,
            adversarialGateClean: adversarialGateClean,
            failureIsolationClean: failureIsolationClean,
            reasonCodes: const <String>[
              'phase57_foundation_contract_incomplete',
              'fail_closed',
              'production_activation_blocked',
            ],
          );

      report.validateStructure();
      return report;
    }

    if (!adversarialGateClean || !failureIsolationClean) {
      final AgentKnowledgeLibraryReadinessReport report =
          AgentKnowledgeLibraryReadinessReport(
            status:
                AgentKnowledgeLibraryReadinessStatus.blockedAdversarialScenario,
            foundationReady: false,
            productionActive: false,
            adversarialGateClean: adversarialGateClean,
            failureIsolationClean: failureIsolationClean,
            reasonCodes: const <String>[
              'adversarial_or_failure_isolation_not_clean',
              'fail_closed',
              'production_activation_blocked',
            ],
          );

      report.validateStructure();
      return report;
    }

    final AgentKnowledgeLibraryReadinessReport report =
        AgentKnowledgeLibraryReadinessReport(
          status: AgentKnowledgeLibraryReadinessStatus
              .foundationReadyNotProductionActive,
          foundationReady: true,
          productionActive: false,
          adversarialGateClean: true,
          failureIsolationClean: true,
          reasonCodes: const <String>[
            'step1b_item_source_scope_version_clean',
            'step1c_ingestion_approval_staleness_clean',
            'step1d_scope_ranking_no_answer_clean',
            'step1e_precedence_conflict_citation_clean',
            'step1f_privacy_language_owner_whatsapp_read_clean',
            'adversarial_gate_clean',
            'failure_isolation_clean',
            'knowledge_information_only',
            'no_answer_instead_of_guess',
            'no_business_authority',
            'no_production_connector_activation',
            'foundation_ready_not_production_active',
          ],
        );

    report.validateStructure();
    return report;
  }

  bool get phase57FoundationComplete => true;
  bool get productionActivationDeferred => true;
  bool get databaseIndexConnectorDeferred => true;
  bool get rawContentRetrievalConnectorDeferred => true;
  bool get providerConnectorDeferred => true;
  bool get trustedBackendPersistenceDeferred => true;
  bool get ownerWhatsAppSendDeferred => true;
  bool get conversationGroundingStillRequired => true;
  bool get responseGuardStillRequired => true;
  bool get phase55VideoCatalogStillSeparate => true;
  bool get phase62TrainingDeploymentStillSeparate => true;
  bool get phase63PrivacyRetentionUiStillSeparate => true;

  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get expandsScope => false;
  bool get executesBusinessAction => false;
  bool get writesBusinessData => false;
  bool get writesIndex => false;
  bool get sendsWhatsApp => false;
  bool get invokesProvider => false;
  bool get persistsReadiness => false;
}
