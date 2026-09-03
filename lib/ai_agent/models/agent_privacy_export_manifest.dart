class AgentPrivacyExportManifest {
  AgentPrivacyExportManifest({
    required this.exportId,
    required this.format,
    required this.suggestedFileName,
    required this.includedDataKinds,
    required this.redactedProjectionOnly,
    required this.restrictedCriticalExcluded,
    required this.protectedEvidenceExcluded,
  }) {
    validate();
  }

  final String exportId;
  final String format;
  final String suggestedFileName;
  final List<String> includedDataKinds;

  final bool redactedProjectionOnly;
  final bool restrictedCriticalExcluded;
  final bool protectedEvidenceExcluded;

  bool get previewOnly => true;
  bool get containsRawUserPayload => false;
  bool get containsSecrets => false;
  bool get containsTokens => false;
  bool get containsPaymentCredentials => false;
  bool get containsRawCallRecording => false;

  bool get fileGenerated => false;
  bool get downloadDelivered => false;

  void validate() {
    if (exportId.trim().isEmpty ||
        format.trim().isEmpty ||
        suggestedFileName.trim().isEmpty ||
        includedDataKinds.isEmpty ||
        !redactedProjectionOnly ||
        !restrictedCriticalExcluded ||
        !protectedEvidenceExcluded) {
      throw const FormatException('Invalid Agent privacy export manifest.');
    }
  }
}
