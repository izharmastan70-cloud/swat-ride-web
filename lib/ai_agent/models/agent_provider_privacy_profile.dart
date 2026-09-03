import '../constants/agent_provider_privacy_projection_constants.dart';

class AgentProviderPrivacyProfile {
  const AgentProviderPrivacyProfile({
    required this.providerId,
    required this.privacyBoundary,
    required this.backendOnly,
    required this.enabled,
  });

  final String providerId;
  final String privacyBoundary;
  final bool backendOnly;
  final bool enabled;

  bool get externalOnline =>
      privacyBoundary == AgentProviderPrivacyBoundary.externalOnline;

  bool get localPrivate =>
      privacyBoundary == AgentProviderPrivacyBoundary.localPrivate;

  bool get metadataOnly => true;
  bool get containsRawApiKey => false;
  bool get containsRawToken => false;
  bool get containsRawSecret => false;
  bool get clientMayExecuteProvider => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get expandsScope => false;
  bool get executesBusinessAction => false;
  bool get persistsProfile => false;

  void validateStructure() {
    if (providerId.trim().isEmpty ||
        !AgentProviderPrivacyBoundary.values.contains(privacyBoundary)) {
      throw const FormatException('Invalid provider privacy profile.');
    }
  }
}
