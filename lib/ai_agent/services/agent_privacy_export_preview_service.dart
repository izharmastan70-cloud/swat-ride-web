import '../constants/agent_privacy_control_export_constants.dart';
import '../models/agent_privacy_export_decision.dart';
import '../models/agent_privacy_export_manifest.dart';

class AgentPrivacyExportPreviewService {
  const AgentPrivacyExportPreviewService();

  AgentPrivacyExportManifest buildPreview(AgentPrivacyExportDecision decision) {
    decision.validate();

    if (!decision.eligibleForSafeExportPackage) {
      throw const FormatException(
        'Blocked export decision cannot produce a download preview.',
      );
    }

    final extension = _extensionFor(decision.format);

    return AgentPrivacyExportManifest(
      exportId: decision.exportId,
      format: decision.format,
      suggestedFileName:
          'swat_ride_privacy_export_${_safeFileToken(decision.exportId)}.$extension',
      includedDataKinds: List<String>.unmodifiable(decision.allowedDataKinds),
      redactedProjectionOnly: true,
      restrictedCriticalExcluded: true,
      protectedEvidenceExcluded: true,
    );
  }

  String _extensionFor(String format) {
    switch (format) {
      case AgentPrivacyExportFormat.json:
        return 'json';
      case AgentPrivacyExportFormat.csv:
        return 'csv';
      case AgentPrivacyExportFormat.zipPackage:
        return 'zip';
      default:
        throw const FormatException('Unsupported export format.');
    }
  }

  String _safeFileToken(String value) {
    return value.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
  }

  bool get previewOnly => true;
  bool get fetchesUserData => false;
  bool get generatesFile => false;
  bool get deliversDownload => false;
  bool get writesFilesystem => false;
  bool get writesFirestore => false;
  bool get callsProvider => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get deletesData => false;
}
