import '../constants/agent_provider_expansion_contract_constants.dart';

class AgentProviderExpansionContract {
  AgentProviderExpansionContract({
    required this.providerId,
    required this.displayName,
    required this.tier,
    required this.enabled,
    required this.backendOnly,
    required this.secretReferenceId,
    required this.defaultModelReference,
    required Set<String> capabilities,
  }) : capabilities = Set<String>.unmodifiable(capabilities);

  final String providerId;
  final String displayName;
  final String tier;
  final bool enabled;
  final bool backendOnly;

  /// Opaque trusted-backend secret/config reference only.
  /// Never the secret/token/key itself.
  final String secretReferenceId;

  /// Opaque provider model identifier/reference only.
  final String defaultModelReference;

  final Set<String> capabilities;

  bool get secretReferenceOnly => true;
  bool get containsRawApiKey => false;
  bool get containsRawToken => false;
  bool get containsRawSecret => false;
  bool get clientMayReadSecret => false;
  bool get clientMayActivateProvider => false;

  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get expandsScope => false;
  bool get executesBusinessAction => false;
  bool get writesBusinessData => false;
  bool get invokesProvider => false;
  bool get persistsContract => false;

  void validateStructure() {
    if (!_validId(providerId) ||
        displayName.trim().isEmpty ||
        displayName.length > AgentProviderExpansionLimits.displayNameMax ||
        !AgentProviderExpansionTier.values.contains(tier) ||
        !_validRef(
          secretReferenceId,
          AgentProviderExpansionLimits.secretRefMax,
        ) ||
        !_validRef(
          defaultModelReference,
          AgentProviderExpansionLimits.modelRefMax,
        ) ||
        capabilities.isEmpty ||
        capabilities.length > AgentProviderExpansionLimits.maxCapabilities ||
        capabilities.any(
          (String capability) =>
              !AgentProviderExpansionCapability.values.contains(capability),
        )) {
      throw const FormatException('Invalid provider expansion contract.');
    }
  }

  bool _validId(String value) {
    final String trimmed = value.trim();

    return trimmed.isNotEmpty &&
        trimmed.length <= AgentProviderExpansionLimits.idMax &&
        RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(trimmed);
  }

  bool _validRef(String value, int maxLength) {
    final String trimmed = value.trim();

    return trimmed.isNotEmpty &&
        trimmed.length <= maxLength &&
        !trimmed.contains(' ') &&
        !trimmed.toLowerCase().startsWith('sk-') &&
        !trimmed.toLowerCase().startsWith('bearer ');
  }
}
