import '../constants/agent_provider_privacy_projection_constants.dart';

class AgentProviderSensitiveTaskRestrictionPolicy {
  const AgentProviderSensitiveTaskRestrictionPolicy();

  bool externalProviderAllowed({
    required String sensitiveTaskClass,
    required String dataSensitivity,
  }) {
    if (!AgentProviderSensitiveTaskClass.values.contains(sensitiveTaskClass) ||
        !AgentProviderDataSensitivity.values.contains(dataSensitivity)) {
      return false;
    }

    if (sensitiveTaskClass != AgentProviderSensitiveTaskClass.normal) {
      return false;
    }

    return dataSensitivity == AgentProviderDataSensitivity.publicData ||
        dataSensitivity == AgentProviderDataSensitivity.operational;
  }

  bool localPrivateProviderAllowed({
    required String sensitiveTaskClass,
    required String dataSensitivity,
  }) {
    if (!AgentProviderSensitiveTaskClass.values.contains(sensitiveTaskClass) ||
        !AgentProviderDataSensitivity.values.contains(dataSensitivity)) {
      return false;
    }

    return dataSensitivity != AgentProviderDataSensitivity.restricted;
  }

  bool get identitySensitiveExternalBlocked => true;
  bool get paymentSensitiveExternalBlocked => true;
  bool get healthSensitiveExternalBlocked => true;
  bool get emergencySensitiveExternalBlocked => true;
  bool get adminSecuritySensitiveExternalBlocked => true;
  bool get restrictedDataAlwaysBlockedFromProviderProjection => true;
  bool get localPrivateStillRequiresMinimization => true;
  bool get providerBoundaryDoesNotGrantAuthority => true;
  bool get invokesProvider => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get executesBusinessAction => false;
  bool get persistsPolicy => false;
}
