class AgentProviderPrivacySafeProjection {
  AgentProviderPrivacySafeProjection({
    required this.requestId,
    required this.taskType,
    required this.providerId,
    required this.privacyBoundary,
    required this.dataSensitivity,
    required List<String> contextReferenceIds,
  }) : contextReferenceIds = List<String>.unmodifiable(contextReferenceIds);

  final String requestId;
  final String taskType;
  final String providerId;
  final String privacyBoundary;
  final String dataSensitivity;
  final List<String> contextReferenceIds;

  bool get referenceMetadataOnly => true;
  bool get minimumNecessaryDataOnly => true;
  bool get redactionRequiredBeforeProjection => true;

  bool get containsRawPrompt => false;
  bool get containsRawConversation => false;
  bool get containsRawUserMessage => false;
  bool get containsPhoneNumber => false;
  bool get containsEmailAddress => false;
  bool get containsAuthToken => false;
  bool get containsPassword => false;
  bool get containsApiSecret => false;
  bool get containsPaymentCard => false;
  bool get containsCvv => false;
  bool get containsPin => false;
  bool get containsIdentityDocumentImage => false;
  bool get containsPrecisePrivateLocation => false;
  bool get containsPrivateHealthRecord => false;
  bool get containsPrivateEmergencyEvidence => false;
  bool get containsPrivateComplaintEvidence => false;

  bool get invokesProvider => false;
  bool get activatesProvider => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get expandsScope => false;
  bool get executesBusinessAction => false;
  bool get writesBusinessData => false;
  bool get chargesCost => false;
  bool get mutatesBudget => false;
  bool get persistsProjection => false;
}
