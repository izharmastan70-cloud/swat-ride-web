import '../constants/agent_privacy_access_scope_constants.dart';
import '../constants/agent_privacy_control_export_constants.dart';
import '../constants/agent_privacy_retention_classification_constants.dart';

class AgentPrivacyExportRequest {
  AgentPrivacyExportRequest({
    required this.exportId,
    required this.requestedByRole,
    required this.requesterRef,
    required this.subjectRef,
    required this.exportScope,
    required this.format,
    required this.domain,
    required this.requestedDataKinds,
    required this.redactedProjectionConfirmed,
    required this.strictDomainAuthorizationConfirmed,
    required this.requestedAtUtc,
  }) {
    validate();
  }

  final String exportId;
  final String requestedByRole;

  /// Opaque references only.
  final String requesterRef;
  final String subjectRef;

  final String exportScope;
  final String format;
  final String domain;

  final List<String> requestedDataKinds;

  /// Must refer to data that has already passed the privacy/redaction layer.
  final bool redactedProjectionConfirmed;

  /// Required for Student/Safety/financial data.
  final bool strictDomainAuthorizationConfirmed;

  final DateTime requestedAtUtc;

  bool get rawPayloadStored => false;
  bool get secretsStored => false;
  bool get tokensStored => false;
  bool get paymentCredentialsStored => false;

  void validate() {
    final idPattern = RegExp(r'^[A-Za-z0-9_.:-]+$');

    bool safeId(String value) =>
        value.isNotEmpty &&
        value == value.trim() &&
        value.length <= AgentPrivacyControlSettingsLimits.opaqueIdMaxLength &&
        idPattern.hasMatch(value);

    final uniqueKinds = requestedDataKinds.toSet();

    if (!safeId(exportId) ||
        !safeId(requesterRef) ||
        !safeId(subjectRef) ||
        !AgentPrivacyControlRole.values.contains(requestedByRole) ||
        !AgentPrivacyExportScope.values.contains(exportScope) ||
        !AgentPrivacyExportFormat.values.contains(format) ||
        !AgentPrivacyAccessDomain.values.contains(domain) ||
        requestedDataKinds.isEmpty ||
        requestedDataKinds.length >
            AgentPrivacyControlSettingsLimits.maximumExportKinds ||
        uniqueKinds.length != requestedDataKinds.length ||
        !requestedDataKinds.every(AgentPrivacyDataKind.values.contains) ||
        !requestedAtUtc.isUtc) {
      throw const FormatException('Invalid Agent privacy export request.');
    }
  }
}
