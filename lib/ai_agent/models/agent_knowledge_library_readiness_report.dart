import '../constants/agent_knowledge_library_closeout_constants.dart';

class AgentKnowledgeLibraryReadinessReport {
  AgentKnowledgeLibraryReadinessReport({
    required this.status,
    required this.foundationReady,
    required this.productionActive,
    required this.adversarialGateClean,
    required this.failureIsolationClean,
    required List<String> reasonCodes,
  }) : reasonCodes = List<String>.unmodifiable(reasonCodes);

  final String status;
  final bool foundationReady;
  final bool productionActive;
  final bool adversarialGateClean;
  final bool failureIsolationClean;
  final List<String> reasonCodes;

  bool get readyNotActive =>
      status ==
          AgentKnowledgeLibraryReadinessStatus
              .foundationReadyNotProductionActive &&
      foundationReady &&
      !productionActive &&
      adversarialGateClean &&
      failureIsolationClean;

  bool get knowledgeIsInformationOnly => true;
  bool get noAnswerInsteadOfGuess => true;
  bool get scopeMustStayPreauthorized => true;
  bool get approvalMustStayExternal => true;
  bool get permissionMustStayExternal => true;
  bool get businessActionsStayExternal => true;
  bool get coreAppFailureIsolationRequired => true;
  bool get realDatabaseIndexConnectorActive => false;
  bool get realRawContentRetrievalActive => false;
  bool get realProviderConnectorActive => false;
  bool get ownerWhatsAppSendActive => false;
  bool get productionPersistenceActive => false;

  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get expandsScope => false;
  bool get executesBusinessAction => false;
  bool get writesBusinessData => false;
  bool get sendsWhatsApp => false;
  bool get invokesProvider => false;
  bool get persistsReport => false;

  void validateStructure() {
    if (!AgentKnowledgeLibraryReadinessStatus.values.contains(status) ||
        reasonCodes.isEmpty ||
        reasonCodes.length > AgentKnowledgeCloseoutLimits.maxReasonCodes) {
      throw const FormatException(
        'Invalid knowledge library readiness report.',
      );
    }

    if (status ==
            AgentKnowledgeLibraryReadinessStatus
                .foundationReadyNotProductionActive &&
        productionActive) {
      throw const FormatException(
        'Foundation-ready status cannot be production-active.',
      );
    }
  }
}
