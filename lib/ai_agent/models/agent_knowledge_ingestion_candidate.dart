class AgentKnowledgeIngestionCandidate {
  const AgentKnowledgeIngestionCandidate({
    required this.itemId,
    required this.revision,
    required this.sourceVersion,
    required this.contentBinding,
    required this.contentFingerprint,
    required this.supersedesItemId,
    required this.previousRevision,
    required this.deprecationAcknowledged,
    required this.duplicateFingerprintDetected,
  });

  final String itemId;
  final int revision;
  final String sourceVersion;
  final String contentBinding;
  final String contentFingerprint;
  final String supersedesItemId;
  final int previousRevision;
  final bool deprecationAcknowledged;
  final bool duplicateFingerprintDetected;

  bool get candidateIsMetadataOnly => true;
  bool get containsRawKnowledgeContent => false;
  bool get containsRawPrompt => false;
  bool get containsPrivatePayload => false;
  bool get writesIndex => false;
  bool get writesFirestore => false;
  bool get executesDeprecation => false;
  bool get executesApproval => false;
  bool get grantsAuthority => false;
  bool get executesBusinessAction => false;
  bool get persistsCandidate => false;

  bool get isSuperseding => supersedesItemId.trim().isNotEmpty;

  void validateStructure() {
    if (!_validId(itemId) ||
        !_validId(sourceVersion) ||
        !_validId(contentBinding) ||
        !_validId(contentFingerprint)) {
      throw const FormatException(
        'Invalid knowledge ingestion candidate identifiers.',
      );
    }

    if (revision <= 0 || previousRevision < 0) {
      throw const FormatException('Invalid knowledge ingestion revisions.');
    }

    if (isSuperseding && !_validId(supersedesItemId)) {
      throw const FormatException('Invalid superseded knowledge item ID.');
    }
  }

  bool _validId(String value) {
    final String trimmed = value.trim();

    return trimmed.isNotEmpty &&
        trimmed.length <= 256 &&
        RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(trimmed);
  }
}
