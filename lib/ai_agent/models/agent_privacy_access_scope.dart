import '../constants/agent_privacy_access_scope_constants.dart';
import '../constants/agent_privacy_retention_classification_constants.dart';

class AgentPrivacyAccessScope {
  AgentPrivacyAccessScope({
    required this.scopeId,
    required this.agentId,
    required this.allowedDataKinds,
    required this.allowedDomains,
    required this.maximumSensitivityTier,
    required this.protectedEvidenceProjectionAllowed,
    required this.validUntilUtc,
  }) {
    validate();
  }

  final String scopeId;
  final String agentId;

  final Set<String> allowedDataKinds;
  final Set<String> allowedDomains;

  final String maximumSensitivityTier;

  final bool protectedEvidenceProjectionAllowed;

  final DateTime validUntilUtc;

  bool get metadataOnly => true;

  bool get runtimePermissionGranted => false;
  bool get approvalAuthorityGranted => false;
  bool get businessExecutionGranted => false;
  bool get providerExecutionGranted => false;
  bool get dataReadPerformed => false;
  bool get firestoreReadPerformed => false;
  bool get firestoreWritePerformed => false;
  bool get retentionMutationPerformed => false;
  bool get deletionPerformed => false;

  void validate() {
    final RegExp safeIdPattern = RegExp(r'^[A-Za-z0-9_.:-]+$');

    bool safeId(String value) =>
        value.isNotEmpty &&
        value == value.trim() &&
        value.length <= AgentPrivacyAccessScopeLimits.opaqueIdMaxLength &&
        safeIdPattern.hasMatch(value);

    if (!safeId(scopeId) ||
        !safeId(agentId) ||
        allowedDataKinds.isEmpty ||
        allowedDomains.isEmpty ||
        allowedDataKinds.length != allowedDataKinds.toSet().length ||
        allowedDomains.length != allowedDomains.toSet().length ||
        !allowedDataKinds.every(AgentPrivacyDataKind.values.contains) ||
        !allowedDomains.every(AgentPrivacyAccessDomain.values.contains) ||
        !AgentPrivacySensitivityTier.values.contains(maximumSensitivityTier) ||
        !validUntilUtc.isUtc) {
      throw const FormatException('Invalid Agent privacy access scope.');
    }
  }
}
