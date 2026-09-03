import '../constants/agent_knowledge_library_closeout_constants.dart';

class AgentKnowledgeLibraryAdversarialScenario {
  const AgentKnowledgeLibraryAdversarialScenario({
    required this.type,
    required this.requiresNoAnswer,
    required this.requiresFailureIsolation,
  });

  final String type;
  final bool requiresNoAnswer;
  final bool requiresFailureIsolation;

  bool get inputIsNeverAuthority => true;
  bool get mayGrantPermission => false;
  bool get mayConsumeApproval => false;
  bool get mayExpandScope => false;
  bool get mayExecuteBusinessAction => false;
  bool get mayWriteIndex => false;
  bool get maySendWhatsApp => false;
  bool get mayPersistKnowledge => false;

  void validateStructure() {
    if (!AgentKnowledgeAdversarialType.values.contains(type)) {
      throw const FormatException(
        'Unsupported knowledge adversarial scenario.',
      );
    }

    if (!requiresNoAnswer && !requiresFailureIsolation) {
      throw const FormatException(
        'Adversarial scenario must block or isolate.',
      );
    }
  }
}
