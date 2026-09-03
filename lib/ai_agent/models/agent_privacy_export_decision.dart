import '../constants/agent_privacy_control_export_constants.dart';

class AgentPrivacyExportDecision {
  AgentPrivacyExportDecision({
    required this.status,
    required this.exportId,
    required this.format,
    required this.allowedDataKinds,
    required this.reasonCode,
  }) {
    validate();
  }

  final String status;
  final String exportId;
  final String format;
  final List<String> allowedDataKinds;
  final String reasonCode;

  bool get eligibleForSafeExportPackage =>
      status == AgentPrivacyExportStatus.eligibleForSafeExportPackage;

  bool get decisionOnly => true;

  bool get userDataFetched => false;
  bool get fileGenerated => false;
  bool get fileDownloaded => false;
  bool get rawPayloadReturned => false;
  bool get firestoreReadPerformed => false;
  bool get firestoreWritePerformed => false;
  bool get providerCalled => false;
  bool get permissionGranted => false;
  bool get approvalConsumed => false;
  bool get runtimeGateOverridden => false;
  bool get businessWritePerformed => false;
  bool get deletionPerformed => false;

  void validate() {
    if (!AgentPrivacyExportStatus.values.contains(status) ||
        !AgentPrivacyExportFormat.values.contains(format) ||
        exportId.trim().isEmpty ||
        reasonCode.trim().isEmpty) {
      throw const FormatException('Invalid Agent privacy export decision.');
    }

    if (!eligibleForSafeExportPackage && allowedDataKinds.isNotEmpty) {
      throw const FormatException(
        'Blocked export decision cannot expose allowed data kinds.',
      );
    }

    if (eligibleForSafeExportPackage && allowedDataKinds.isEmpty) {
      throw const FormatException(
        'Eligible export decision requires data kinds.',
      );
    }
  }
}
