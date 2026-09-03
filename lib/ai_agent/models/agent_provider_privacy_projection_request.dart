import '../constants/agent_provider_privacy_projection_constants.dart';

class AgentProviderPrivacyProjectionRequest {
  AgentProviderPrivacyProjectionRequest({
    required this.requestId,
    required this.taskType,
    required this.sensitiveTaskClass,
    required this.dataSensitivity,
    required this.minimumNecessaryDataConfirmed,
    required this.redactionCompleted,
    required List<String> contextReferenceIds,
    required Set<String> restrictedDataFlags,
  }) : contextReferenceIds = List<String>.unmodifiable(contextReferenceIds),
       restrictedDataFlags = Set<String>.unmodifiable(restrictedDataFlags);

  final String requestId;
  final String taskType;
  final String sensitiveTaskClass;
  final String dataSensitivity;
  final bool minimumNecessaryDataConfirmed;
  final bool redactionCompleted;

  /// Opaque references only. No raw prompt/conversation/private payload.
  final List<String> contextReferenceIds;

  /// Flags describe what unsafe data was detected before projection.
  final Set<String> restrictedDataFlags;

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
  bool get containsPrivateHealthRecord => false;
  bool get containsPrivateEmergencyEvidence => false;

  bool get invokesProvider => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get expandsScope => false;
  bool get executesBusinessAction => false;
  bool get persistsRequest => false;

  void validateStructure() {
    if (!_validId(requestId) ||
        taskType.trim().isEmpty ||
        !AgentProviderSensitiveTaskClass.values.contains(sensitiveTaskClass) ||
        !AgentProviderDataSensitivity.values.contains(dataSensitivity) ||
        contextReferenceIds.isEmpty ||
        contextReferenceIds.length >
            AgentProviderPrivacyProjectionLimits.maxReferenceIds ||
        contextReferenceIds.any((String value) => !_validId(value)) ||
        restrictedDataFlags.length >
            AgentProviderPrivacyProjectionLimits.maxRestrictedDataFlags ||
        restrictedDataFlags.any(
          (String value) =>
              !AgentProviderRestrictedDataClass.values.contains(value),
        )) {
      throw const FormatException(
        'Invalid provider privacy projection request.',
      );
    }
  }

  bool _validId(String value) {
    final String trimmed = value.trim();

    return trimmed.isNotEmpty &&
        trimmed.length <= AgentProviderPrivacyProjectionLimits.idMax &&
        RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(trimmed);
  }
}
