import '../constants/agent_omnichannel_constants.dart';
import 'agent_omnichannel_identity_privacy.dart';

class AgentOmnichannelRawIngress {
  const AgentOmnichannelRawIngress({
    required this.rawIngressId,
    required this.channel,
    required this.externalMessageRef,
    required this.intendedAgentRoleId,
    required this.receivedAt,
    required this.sanitizedText,
    required this.subjectRef,
    required this.identityAssurance,
    required this.verifiedByTrustedBoundary,
    required this.strongReauthSatisfied,
    required this.fromChannelClaimOnly,
    required this.containsRawSecrets,
    required this.containsPaymentCredentials,
    required this.containsAuthToken,
    required this.containsGovernmentId,
    required this.containsUnredactedContactDetails,
    required this.redactionApplied,
  });

  final String rawIngressId;
  final String channel;
  final String externalMessageRef;
  final String intendedAgentRoleId;
  final DateTime receivedAt;

  /// Already privacy-filtered text. Provider adapters must not place raw
  /// credentials/secrets into this field.
  final String sanitizedText;

  /// Pseudonymous identity reference only.
  final String subjectRef;
  final String identityAssurance;
  final bool verifiedByTrustedBoundary;
  final bool strongReauthSatisfied;
  final bool fromChannelClaimOnly;

  final bool containsRawSecrets;
  final bool containsPaymentCredentials;
  final bool containsAuthToken;
  final bool containsGovernmentId;
  final bool containsUnredactedContactDetails;
  final bool redactionApplied;

  bool get providerPayloadIsAuthority => false;
  bool get channelMetadataIsAuthority => false;
  bool get isRuntimeExecutable => false;
  bool get mayGrantPermission => false;
  bool get mayConsumeApproval => false;
  bool get mayWriteBusinessData => false;

  void validate() {
    if (rawIngressId.trim().isEmpty ||
        externalMessageRef.trim().isEmpty ||
        intendedAgentRoleId.trim().isEmpty ||
        sanitizedText.trim().isEmpty ||
        subjectRef.trim().isEmpty ||
        !AgentOmnichannelChannel.values.contains(channel) ||
        !AgentOmnichannelIdentityAssurance.values.contains(identityAssurance)) {
      throw const AgentOmnichannelContractException(
        'Raw omnichannel ingress is structurally invalid.',
      );
    }
  }
}
