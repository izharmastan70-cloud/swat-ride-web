import '../constants/agent_knowledge_library_closeout_constants.dart';
import '../models/agent_knowledge_library_adversarial_scenario.dart';

class AgentKnowledgeLibraryAdversarialGate {
  const AgentKnowledgeLibraryAdversarialGate();

  String evaluate(AgentKnowledgeLibraryAdversarialScenario scenario) {
    scenario.validateStructure();

    if (_failureIsolationTypes.contains(scenario.type)) {
      return AgentKnowledgeAdversarialDecision.isolateFailure;
    }

    return AgentKnowledgeAdversarialDecision.blockNoAnswer;
  }

  static const Set<String> _failureIsolationTypes = <String>{
    AgentKnowledgeAdversarialType.retrievalFailure,
    AgentKnowledgeAdversarialType.conflictResolverFailure,
    AgentKnowledgeAdversarialType.groundingFailure,
    AgentKnowledgeAdversarialType.responseGuardFailure,
    AgentKnowledgeAdversarialType.providerFailure,
  };

  bool get allExternalInputsNonAuthoritative => true;
  bool get promptInjectionBlocked => true;
  bool get userAuthorityClaimBlocked => true;
  bool get whatsappApprovalClaimBlocked => true;
  bool get socialCommentPolicyClaimBlocked => true;
  bool get providerOutputTruthClaimBlocked => true;
  bool get staleDeprecatedUnapprovedBlocked => true;
  bool get crossScopeLeakageBlocked => true;
  bool get equalPrecedenceConflictNoAnswer => true;
  bool get languageMismatchNoAnswer => true;
  bool get privatePayloadBlocked => true;
  bool get secretExfiltrationBlocked => true;
  bool get unauthorizedOwnerWhatsAppReadBlocked => true;
  bool get whatsappSendAttemptBlocked => true;
  bool get indexWriteAttemptBlocked => true;
  bool get permissionGrantAttemptBlocked => true;
  bool get approvalConsumeAttemptBlocked => true;
  bool get businessActionAttemptBlocked => true;

  bool get retrievalFailureIsolated => true;
  bool get conflictResolverFailureIsolated => true;
  bool get groundingFailureIsolated => true;
  bool get responseGuardFailureIsolated => true;
  bool get providerFailureIsolated => true;
  bool get coreAppContinuesIfKnowledgeFails => true;

  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get expandsScope => false;
  bool get executesBusinessAction => false;
  bool get writesIndex => false;
  bool get sendsWhatsApp => false;
  bool get invokesProvider => false;
  bool get persistsDecision => false;
}
