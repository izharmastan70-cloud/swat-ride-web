import '../constants/agent_privacy_deletion_retention_constants.dart';

class AgentPrivacyDeletionDecision {
  AgentPrivacyDeletionDecision({
    required this.status,
    required this.requestId,
    required this.reasonCode,
  }) {
    validate();
  }

  final String status;
  final String requestId;
  final String reasonCode;

  bool get eligibleForLaterDeletionReview =>
      status == AgentPrivacyDeletionStatus.eligibleTransientReview;

  bool get decisionOnly => true;
  bool get deletionPerformed => false;
  bool get purgePerformed => false;
  bool get firestoreWritePerformed => false;
  bool get providerCalled => false;
  bool get permissionGranted => false;
  bool get approvalConsumed => false;
  bool get runtimeGateOverridden => false;
  bool get businessWritePerformed => false;

  void validate() {
    if (!AgentPrivacyDeletionStatus.values.contains(status) ||
        requestId.trim().isEmpty ||
        reasonCode.trim().isEmpty) {
      throw const FormatException('Invalid Agent privacy deletion decision.');
    }
  }
}
