import '../constants/agent_privacy_consent_training_constants.dart';

class AgentPrivacyTrainingEligibility {
  AgentPrivacyTrainingEligibility({
    required this.status,
    required this.dataKind,
    required this.channel,
    required this.reasonCode,
    required this.usesRealData,
  }) {
    validate();
  }

  final String status;
  final String dataKind;
  final String channel;
  final String reasonCode;
  final bool usesRealData;

  bool get eligibleForRealDataReview =>
      status == AgentPrivacyTrainingEligibilityStatus.eligibleRealData;

  bool get eligibleSyntheticOnly =>
      status == AgentPrivacyTrainingEligibilityStatus.eligibleSyntheticOnly;

  bool get trainingPerformed => false;
  bool get modelMutationPerformed => false;
  bool get promptMutationPerformed => false;
  bool get providerCalled => false;
  bool get deploymentPerformed => false;
  bool get productionActivationPerformed => false;
  bool get permissionGranted => false;
  bool get approvalConsumed => false;
  bool get retentionMutationPerformed => false;
  bool get deletionPerformed => false;
  bool get businessWritePerformed => false;

  void validate() {
    if (!AgentPrivacyTrainingEligibilityStatus.values.contains(status) ||
        dataKind.trim().isEmpty ||
        channel.trim().isEmpty ||
        reasonCode.trim().isEmpty) {
      throw const FormatException('Invalid privacy training eligibility.');
    }

    if (eligibleSyntheticOnly && usesRealData) {
      throw const FormatException(
        'Synthetic-only eligibility cannot use real data.',
      );
    }
  }
}
