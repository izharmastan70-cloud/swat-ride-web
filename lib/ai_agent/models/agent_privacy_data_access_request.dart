import '../constants/agent_privacy_access_scope_constants.dart';
import '../constants/agent_privacy_retention_classification_constants.dart';

class AgentPrivacyDataAccessRequest {
  AgentPrivacyDataAccessRequest({
    required this.requestId,
    required this.agentId,
    required this.domain,
    required this.purpose,
    required this.requestedDataKinds,
    required this.requestedAtUtc,
  }) {
    validate();
  }

  final String requestId;
  final String agentId;
  final String domain;
  final String purpose;
  final List<String> requestedDataKinds;
  final DateTime requestedAtUtc;

  bool get requestsPayload => false;
  bool get metadataRequestOnly => true;

  void validate() {
    final RegExp safeIdPattern = RegExp(r'^[A-Za-z0-9_.:-]+$');

    bool safeId(String value) =>
        value.isNotEmpty &&
        value == value.trim() &&
        value.length <= AgentPrivacyAccessScopeLimits.opaqueIdMaxLength &&
        safeIdPattern.hasMatch(value);

    final Set<String> uniqueKinds = requestedDataKinds.toSet();

    if (!safeId(requestId) ||
        !safeId(agentId) ||
        !AgentPrivacyAccessDomain.values.contains(domain) ||
        !AgentPrivacyAccessPurpose.values.contains(purpose) ||
        requestedDataKinds.isEmpty ||
        requestedDataKinds.length >
            AgentPrivacyAccessScopeLimits.maximumRequestedDataKinds ||
        uniqueKinds.length != requestedDataKinds.length ||
        !requestedDataKinds.every(AgentPrivacyDataKind.values.contains) ||
        !requestedAtUtc.isUtc) {
      throw const FormatException('Invalid Agent privacy data-access request.');
    }
  }
}
