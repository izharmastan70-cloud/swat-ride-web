import '../constants/agent_privacy_access_scope_constants.dart';

class AgentPrivacyDataAccessDecision {
  AgentPrivacyDataAccessDecision({
    required this.status,
    required this.requestId,
    required this.agentId,
    required this.domain,
    required this.projectionMode,
    required this.allowedDataKinds,
    required this.reasonCode,
  }) {
    validate();
  }

  final String status;
  final String requestId;
  final String agentId;
  final String domain;
  final String projectionMode;

  final List<String> allowedDataKinds;

  final String reasonCode;

  bool get granted =>
      status == AgentPrivacyDataAccessStatus.grantedMinimumNecessary ||
      status == AgentPrivacyDataAccessStatus.grantedVerifiedProjectionOnly;

  bool get verifiedProjectionOnly =>
      projectionMode == AgentPrivacyProjectionMode.verifiedProjectionOnly;

  bool get metadataOnly => true;

  bool get rawPayloadReturned => false;
  bool get userDataFetched => false;
  bool get firestoreReadPerformed => false;
  bool get firestoreWritePerformed => false;
  bool get providerCalled => false;
  bool get runtimePermissionGranted => false;
  bool get approvalConsumed => false;
  bool get businessExecutionPerformed => false;
  bool get trainingPerformed => false;
  bool get deletionPerformed => false;
  bool get retentionMutationPerformed => false;

  void validate() {
    if (!AgentPrivacyDataAccessStatus.values.contains(status) ||
        !AgentPrivacyProjectionMode.values.contains(projectionMode) ||
        requestId.trim().isEmpty ||
        agentId.trim().isEmpty ||
        !AgentPrivacyAccessDomain.values.contains(domain) ||
        reasonCode.trim().isEmpty) {
      throw const FormatException(
        'Invalid Agent privacy data-access decision.',
      );
    }

    if (!granted && allowedDataKinds.isNotEmpty) {
      throw const FormatException(
        'Blocked privacy decision cannot expose allowed data kinds.',
      );
    }

    if (granted && allowedDataKinds.isEmpty) {
      throw const FormatException(
        'Granted privacy decision requires minimum-necessary data kinds.',
      );
    }
  }
}
