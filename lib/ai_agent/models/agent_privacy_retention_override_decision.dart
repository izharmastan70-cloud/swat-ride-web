import '../constants/agent_privacy_deletion_retention_constants.dart';

class AgentPrivacyRetentionOverrideDecision {
  AgentPrivacyRetentionOverrideDecision({
    required this.status,
    required this.overrideId,
    required this.channel,
    required this.requestedDays,
    required this.reasonCode,
  }) {
    validate();
  }

  final String status;
  final String overrideId;
  final String channel;
  final int requestedDays;
  final String reasonCode;

  bool get eligibleForLaterSettingsReview =>
      status == AgentPrivacyRetentionOverrideStatus.eligibleFoundationOverride;

  bool get decisionOnly => true;
  bool get productionApplied => false;
  bool get firestoreWritePerformed => false;
  bool get retentionMutationPerformed => false;
  bool get deletionPerformed => false;
  bool get protectedEvidenceOverridePerformed => false;
  bool get permissionGranted => false;
  bool get approvalConsumed => false;
  bool get runtimeGateOverridden => false;

  void validate() {
    if (!AgentPrivacyRetentionOverrideStatus.values.contains(status) ||
        overrideId.trim().isEmpty ||
        channel.trim().isEmpty ||
        requestedDays < 0 ||
        reasonCode.trim().isEmpty) {
      throw const FormatException(
        'Invalid Agent privacy retention override decision.',
      );
    }
  }
}
