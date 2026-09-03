import '../constants/agent_ecosystem_control_chain_constants.dart';

class AgentEcosystemControlChainDecision {
  AgentEcosystemControlChainDecision({
    required this.status,
    required this.routeTo,
    required this.reasonCode,
  }) {
    validate();
  }

  final String status;
  final String routeTo;
  final String reasonCode;

  bool get failClosed =>
      status != AgentEcosystemControlDecisionStatus.eligibleControlledHandoff;

  bool get controlledHandoffOnly =>
      status == AgentEcosystemControlDecisionStatus.eligibleControlledHandoff;

  bool get mayConsumeApproval => false;
  bool get mayGrantPermission => false;
  bool get mayOverrideRuntimeGate => false;
  bool get mayDisableEmergencyStop => false;
  bool get mayEnableModule => false;
  bool get mayCallProvider => false;
  bool get maySendMessage => false;
  bool get mayWriteFirestore => false;
  bool get mayExecuteBusinessAction => false;
  bool get mayActivateProduction => false;

  void validate() {
    if (!AgentEcosystemControlDecisionStatus.values.contains(status) ||
        routeTo.trim().isEmpty ||
        reasonCode.trim().isEmpty) {
      throw const FormatException('Invalid ecosystem control-chain decision.');
    }
  }
}
