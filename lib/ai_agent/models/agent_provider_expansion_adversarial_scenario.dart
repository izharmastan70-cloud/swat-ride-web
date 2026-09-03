import '../constants/agent_provider_expansion_closeout_constants.dart';

class AgentProviderExpansionAdversarialScenario {
  const AgentProviderExpansionAdversarialScenario({
    required this.scenarioId,
    required this.type,
    required this.detected,
  });

  final String scenarioId;
  final String type;
  final bool detected;

  bool get containsRawPayload => false;
  bool get invokesProvider => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get executesBusinessAction => false;
  bool get mutatesBudget => false;
  bool get persistsScenario => false;

  void validateStructure() {
    final String id = scenarioId.trim();

    if (id.isEmpty ||
        id.length > AgentProviderExpansionCloseoutLimits.idMax ||
        !RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(id) ||
        !AgentProviderExpansionAdversarialType.values.contains(type)) {
      throw const FormatException(
        'Invalid provider expansion adversarial scenario.',
      );
    }
  }
}
