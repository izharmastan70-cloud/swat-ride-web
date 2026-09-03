import '../constants/agent_content_provider_privacy_safety_constants.dart';

class AgentContentPrivacySafeGenerationContext {
  AgentContentPrivacySafeGenerationContext({
    required this.requestId,
    required this.module,
    required this.feature,
    required this.audience,
    required this.language,
    required this.draftType,
    required List<String> groundedFactReferenceIds,
    required List<String> privacyRiskFlags,
  }) : groundedFactReferenceIds = List<String>.unmodifiable(
         groundedFactReferenceIds,
       ),
       privacyRiskFlags = List<String>.unmodifiable(privacyRiskFlags);

  final String requestId;
  final String module;
  final String feature;
  final String audience;
  final String language;
  final String draftType;
  final List<String> groundedFactReferenceIds;
  final List<String> privacyRiskFlags;

  bool get metadataOnlyProjection => true;
  bool get containsRawPrompt => false;
  bool get containsRawConversation => false;
  bool get containsPhone => false;
  bool get containsEmail => false;
  bool get containsCnic => false;
  bool get containsAuthToken => false;
  bool get containsPassword => false;
  bool get containsPaymentCard => false;
  bool get containsCvv => false;
  bool get containsPin => false;
  bool get containsPreciseLocation => false;
  bool get containsPrivateComplaintEvidence => false;
  bool get containsSecrets => false;
  bool get providerGetsAuthority => false;
  bool get providerGetsApprovalState => false;
  bool get providerGetsBusinessWriteAccess => false;
  bool get persistsContext => false;

  bool get privacySafe => privacyRiskFlags.every(
    (String flag) => !AgentContentPrivacyRisk.forbidden.contains(flag),
  );

  void validateStructure() {
    if (requestId.trim().isEmpty ||
        requestId.length > AgentContentCostLimits.maxRequestIdLength) {
      throw const FormatException('Invalid privacy-safe request ID.');
    }

    if (!_safeField(module) ||
        !_safeField(feature) ||
        !_safeField(audience) ||
        !_safeField(language) ||
        !_safeField(draftType)) {
      throw const FormatException('Invalid privacy-safe metadata field.');
    }

    if (groundedFactReferenceIds.length >
        AgentContentCostLimits.maxContextFields) {
      throw const FormatException('Too many grounded references.');
    }

    if (privacyRiskFlags.length > AgentContentCostLimits.maxContextFields) {
      throw const FormatException('Too many privacy flags.');
    }
  }

  bool _safeField(String value) {
    final String trimmed = value.trim();

    return trimmed.isNotEmpty &&
        trimmed.length <= AgentContentCostLimits.maxContextFieldLength &&
        !RegExp(r'[\u0000-\u001F]').hasMatch(trimmed);
  }
}
