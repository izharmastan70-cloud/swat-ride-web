import '../constants/agent_versioning_constants.dart';

class AgentVersionChangeClassification {
  const AgentVersionChangeClassification({
    required this.changeType,
    required this.risk,
    required this.versionable,
    required this.offlineEvaluationRequired,
    required this.humanApprovalRequired,
    required this.securityReviewRequired,
  });

  final String changeType;
  final String risk;
  final bool versionable;
  final bool offlineEvaluationRequired;
  final bool humanApprovalRequired;
  final bool securityReviewRequired;

  bool get blockedProtectedAuthority =>
      risk == AgentVersionChangeRisk.blockedProtectedAuthority;

  bool get mayDirectlyDeploy => false;
  bool get mayActivateProduction => false;
  bool get mayTrainModel => false;
  bool get mayMutatePrompt => false;
  bool get mayGrantPermission => false;
  bool get mayConsumeApproval => false;
  bool get mayWriteBusinessData => false;
  bool get mayChangeProviderPolicy => false;
  bool get mayChangeCostLimits => false;
  bool get mayChangeProductionAuthority => false;

  void validate() {
    if (!AgentVersionChangeType.values.contains(changeType) ||
        !AgentVersionChangeRisk.values.contains(risk)) {
      throw const FormatException(
        'Invalid Agent version change classification.',
      );
    }

    if (blockedProtectedAuthority && versionable) {
      throw const FormatException(
        'Protected authority change cannot be versionable.',
      );
    }

    if (versionable && !offlineEvaluationRequired) {
      throw const FormatException(
        'Versionable Agent change must require offline evaluation.',
      );
    }

    if (risk == AgentVersionChangeRisk.high &&
        (!humanApprovalRequired || !securityReviewRequired)) {
      throw const FormatException(
        'High-risk Agent version change requires human and security review.',
      );
    }
  }
}
