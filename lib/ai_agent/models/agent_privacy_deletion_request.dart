import '../constants/agent_privacy_deletion_retention_constants.dart';
import '../constants/agent_privacy_retention_classification_constants.dart';

class AgentPrivacyDeletionRequest {
  AgentPrivacyDeletionRequest({
    required this.requestId,
    required this.recordReferenceSha256,
    required this.dataKind,
    required this.recordClass,
    required this.retentionExpiredByCanonicalEngine,
    required this.protectedEvidence,
    required this.legalOrSecurityHold,
    required this.requestedAtUtc,
  }) {
    validate();
  }

  final String requestId;

  /// Hash only. Raw customer/record id is intentionally not required here.
  final String recordReferenceSha256;

  final String dataKind;
  final String recordClass;

  /// Must come from the existing canonical retention decision layer.
  final bool retentionExpiredByCanonicalEngine;

  final bool protectedEvidence;
  final bool legalOrSecurityHold;

  final DateTime requestedAtUtc;

  bool get metadataOnly => true;
  bool get rawRecordIdentifierStored => false;
  bool get rawPayloadStored => false;
  bool get deletionPerformed => false;
  bool get purgePerformed => false;

  void validate() {
    final RegExp safeIdPattern = RegExp(r'^[A-Za-z0-9_.:-]+$');

    final RegExp sha256Pattern = RegExp(r'^[A-Fa-f0-9]{64}$');

    bool safeId(String value) =>
        value.isNotEmpty &&
        value == value.trim() &&
        value.length <= AgentPrivacyDeletionLimits.opaqueIdMaxLength &&
        safeIdPattern.hasMatch(value);

    if (!safeId(requestId) ||
        !sha256Pattern.hasMatch(recordReferenceSha256) ||
        !AgentPrivacyDataKind.values.contains(dataKind) ||
        !AgentPrivacyDeletionRecordClass.values.contains(recordClass) ||
        !requestedAtUtc.isUtc) {
      throw const FormatException('Invalid Agent privacy deletion request.');
    }
  }
}
