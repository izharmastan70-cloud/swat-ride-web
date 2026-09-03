import '../constants/agent_privacy_retention_classification_constants.dart';
import '../models/agent_channel_retention_policy.dart';

class AgentChannelRetentionPolicyService {
  const AgentChannelRetentionPolicyService();

  AgentChannelRetentionPolicy policyFor(String channel) {
    switch (channel) {
      case AgentPrivacyChannel.chat:
        return AgentChannelRetentionPolicy(
          channel: channel,
          retentionMode: AgentPrivacyRetentionMode.ownerConfigurable,
          foundationDefaultDays: 30,
          maximumOwnerConfigurableDays: 90,
          rawContentRetentionEnabledByDefault: true,
          redactionRequiredForTraining: true,
          explicitConsentRequiredForTraining: true,
          trainingMode: AgentPrivacyTrainingMode.redactedConsentRequired,
        );

      case AgentPrivacyChannel.callTranscript:
        return AgentChannelRetentionPolicy(
          channel: channel,
          retentionMode: AgentPrivacyRetentionMode.ownerConfigurable,
          foundationDefaultDays: 14,
          maximumOwnerConfigurableDays: 30,
          rawContentRetentionEnabledByDefault: true,
          redactionRequiredForTraining: true,
          explicitConsentRequiredForTraining: true,
          trainingMode: AgentPrivacyTrainingMode.redactedConsentRequired,
        );

      case AgentPrivacyChannel.callRecording:
        return AgentChannelRetentionPolicy(
          channel: channel,
          retentionMode: AgentPrivacyRetentionMode.disabledByDefault,
          foundationDefaultDays: 0,
          maximumOwnerConfigurableDays: 7,
          rawContentRetentionEnabledByDefault: false,
          redactionRequiredForTraining: true,
          explicitConsentRequiredForTraining: true,
          trainingMode: AgentPrivacyTrainingMode.ineligibleSensitive,
        );

      case AgentPrivacyChannel.email:
        return AgentChannelRetentionPolicy(
          channel: channel,
          retentionMode: AgentPrivacyRetentionMode.ownerConfigurable,
          foundationDefaultDays: 30,
          maximumOwnerConfigurableDays: 90,
          rawContentRetentionEnabledByDefault: true,
          redactionRequiredForTraining: true,
          explicitConsentRequiredForTraining: true,
          trainingMode: AgentPrivacyTrainingMode.redactedConsentRequired,
        );

      case AgentPrivacyChannel.whatsappAi:
        return AgentChannelRetentionPolicy(
          channel: channel,
          retentionMode: AgentPrivacyRetentionMode.ownerConfigurable,
          foundationDefaultDays: 30,
          maximumOwnerConfigurableDays: 90,
          rawContentRetentionEnabledByDefault: true,
          redactionRequiredForTraining: true,
          explicitConsentRequiredForTraining: true,
          trainingMode: AgentPrivacyTrainingMode.redactedConsentRequired,
        );

      default:
        throw const FormatException('Unknown Agent privacy retention channel.');
    }
  }

  bool get foundationOnly => true;
  bool get appliesProductionSetting => false;
  bool get overridesProtectedEvidenceRetention => false;
  bool get deletesData => false;
  bool get purgesData => false;
  bool get writesFirestore => false;
  bool get expandsRuntimePermissions => false;
  bool get consumesApproval => false;
  bool get trainsModel => false;
  bool get deploysTrainingChange => false;
}
