import 'dart:typed_data';

import '../constants/agent_privacy_export_delivery_constants.dart';

class AgentPrivacyExportDownloadPayload {
  AgentPrivacyExportDownloadPayload({
    required this.exportId,
    required this.fileName,
    required this.mimeType,
    required Uint8List bytes,
  }) : bytes = Uint8List.fromList(bytes) {
    validate();
  }

  final String exportId;
  final String fileName;
  final String mimeType;
  final Uint8List bytes;

  int get byteLength => bytes.length;

  bool get inMemoryOnly => true;
  bool get autoDownloadTriggered => false;
  bool get filesystemWritePerformed => false;
  bool get cloudUploadPerformed => false;
  bool get firestoreWritePerformed => false;

  void validate() {
    if (exportId.trim().isEmpty ||
        fileName.trim().isEmpty ||
        !<String>{
          AgentPrivacyExportMimeType.json,
          AgentPrivacyExportMimeType.csv,
          AgentPrivacyExportMimeType.zip,
        }.contains(mimeType) ||
        bytes.isEmpty ||
        bytes.length > AgentPrivacyExportDeliveryLimits.maximumPackageBytes) {
      throw const FormatException('Invalid privacy export download payload.');
    }
  }
}
