import '../constants/agent_ecosystem_resilience_safety_constants.dart';

class AgentEcosystemResilienceSafetyDecision {
  AgentEcosystemResilienceSafetyDecision({
    required this.status,
    required this.routeTo,
    required this.reasonCode,
    required this.auditRequired,
  }) {
    validate();
  }

  final String status;
  final String routeTo;
  final String reasonCode;
  final bool auditRequired;

  bool get failClosed => status.startsWith('BLOCK_');

  bool get mayTrainModel => false;
  bool get mayReplaceProductionPrompt => false;
  bool get mayActivateVersion => false;
  bool get mayDeployProduction => false;
  bool get mayExecuteRollback => false;
  bool get mayCallPrimaryProvider => false;
  bool get mayCallFallbackProvider => false;
  bool get mayChangeProviderPolicy => false;
  bool get mayChangeCostLimits => false;
  bool get mayConsumeApproval => false;
  bool get mayGrantPermission => false;
  bool get mayWriteBusinessData => false;
  bool get mayDisableCoreSwatRide => false;

  void validate() {
    if (!AgentEcosystemResilienceDecisionStatus.values.contains(status) ||
        routeTo.trim().isEmpty ||
        reasonCode.trim().isEmpty) {
      throw const FormatException(
        'Invalid ecosystem resilience safety decision.',
      );
    }
  }
}
