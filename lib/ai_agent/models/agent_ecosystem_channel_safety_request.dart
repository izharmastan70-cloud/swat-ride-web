import '../constants/agent_ecosystem_channel_safety_constants.dart';

class AgentEcosystemChannelSafetyRequest {
  AgentEcosystemChannelSafetyRequest({
    required this.channel,
    required this.actorClaim,
    required this.requestKind,
    required this.trustedIdentityVerified,
    required this.trustedSubjectMatch,
    required this.verifiedBackendEvidence,
    required this.permissionVerified,
    required this.approvalVerified,
    required this.runtimeGateVerified,
    required this.emergencyStopActive,
    required this.moduleEnabled,
  }) {
    validate();
  }

  final String channel;
  final String actorClaim;
  final String requestKind;

  final bool trustedIdentityVerified;
  final bool trustedSubjectMatch;
  final bool verifiedBackendEvidence;

  final bool permissionVerified;
  final bool approvalVerified;
  final bool runtimeGateVerified;

  final bool emergencyStopActive;
  final bool moduleEnabled;

  bool get transportIdentityClaimOnly => true;
  bool get channelClaimGrantsAuthority => false;

  void validate() {
    if (!AgentEcosystemChannel.values.contains(channel) ||
        !AgentEcosystemActorClaim.values.contains(actorClaim) ||
        !AgentEcosystemRequestKind.values.contains(requestKind)) {
      throw const FormatException(
        'Invalid final ecosystem channel safety request.',
      );
    }
  }
}
