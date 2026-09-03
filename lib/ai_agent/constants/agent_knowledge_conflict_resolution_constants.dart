import 'agent_knowledge_library_contract_constants.dart';

class AgentKnowledgeConflictStatus {
  AgentKnowledgeConflictStatus._();

  static const String readyForGrounding = 'READY_FOR_GROUNDING';

  static const String noAnswerInvalidInput = 'NO_ANSWER_INVALID_INPUT';

  static const String noAnswerNoCitableSource = 'NO_ANSWER_NO_CITABLE_SOURCE';

  static const String noAnswerUnresolvedConflict =
      'NO_ANSWER_UNRESOLVED_CONFLICT';

  static const String noAnswerPrecedenceAmbiguous =
      'NO_ANSWER_PRECEDENCE_AMBIGUOUS';

  static const Set<String> values = <String>{
    readyForGrounding,
    noAnswerInvalidInput,
    noAnswerNoCitableSource,
    noAnswerUnresolvedConflict,
    noAnswerPrecedenceAmbiguous,
  };
}

class AgentKnowledgePrecedence {
  AgentKnowledgePrecedence._();

  static const Map<String, int> authority = <String, int>{
    AgentKnowledgeAuthorityClass.systemVerified: 500,
    AgentKnowledgeAuthorityClass.ownerApproved: 400,
    AgentKnowledgeAuthorityClass.adminApproved: 300,
    AgentKnowledgeAuthorityClass.curatedInternal: 200,
    AgentKnowledgeAuthorityClass.verifiedExternal: 100,
  };

  static const Map<String, int> sourceType = <String, int>{
    AgentKnowledgeSourceType.policy: 110,
    AgentKnowledgeSourceType.verifiedFeatureState: 105,
    AgentKnowledgeSourceType.serviceReference: 100,
    AgentKnowledgeSourceType.safetyGuidance: 100,
    AgentKnowledgeSourceType.pricingPaymentReference: 95,
    AgentKnowledgeSourceType.helpFaq: 90,
    AgentKnowledgeSourceType.partnerRoleGuidance: 85,
    AgentKnowledgeSourceType.videoEducationReference: 80,
    AgentKnowledgeSourceType.approvedTrainingReference: 75,
    AgentKnowledgeSourceType.ownerAdminInternalReference: 70,
    AgentKnowledgeSourceType.trustedExternalReference: 60,
  };
}

class AgentKnowledgeConflictLimits {
  AgentKnowledgeConflictLimits._();

  static const int idMax = 256;
  static const int maxCandidates = 48;
  static const int maxCitations = 6;
  static const int maxReasonCodes = 16;
}
