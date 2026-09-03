class AgentKnowledgeCitationReference {
  const AgentKnowledgeCitationReference({
    required this.itemId,
    required this.sourceId,
    required this.sourceReferenceId,
    required this.contentReferenceId,
    required this.sourceType,
    required this.authorityClass,
    required this.revision,
    required this.sourceVersion,
    required this.claimKey,
    required this.claimValueBinding,
  });

  final String itemId;
  final String sourceId;
  final String sourceReferenceId;
  final String contentReferenceId;
  final String sourceType;
  final String authorityClass;
  final int revision;
  final String sourceVersion;
  final String claimKey;

  /// Opaque binding used to prove which reviewed claim/value was selected.
  /// This is not the raw user-visible claim text.
  final String claimValueBinding;

  bool get citationIsReferenceMetadataOnly => true;
  bool get containsRawKnowledgeContent => false;
  bool get containsRawSourcePayload => false;
  bool get containsRawPrompt => false;
  bool get containsPhone => false;
  bool get containsEmail => false;
  bool get containsCnic => false;
  bool get containsAuthToken => false;
  bool get containsPaymentCard => false;
  bool get containsSecret => false;

  bool get citationDoesNotProveTruthByItself => true;
  bool get grantsAuthority => false;
  bool get expandsScope => false;
  bool get executesBusinessAction => false;
  bool get retrievesRawContent => false;
  bool get invokesProvider => false;
  bool get persistsCitation => false;
}
