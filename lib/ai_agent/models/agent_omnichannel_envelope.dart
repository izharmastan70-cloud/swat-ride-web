import '../constants/agent_omnichannel_constants.dart';
import 'agent_omnichannel_identity_privacy.dart';

class AgentOmnichannelEnvelope {
  const AgentOmnichannelEnvelope({
    required this.envelopeId,
    required this.externalMessageRef,
    required this.channel,
    required this.intendedAgentRoleId,
    required this.receivedAt,
    required this.identity,
    required this.privacy,
  });

  final String envelopeId;

  /// Provider-neutral reference only. This is not a provider credential.
  final String externalMessageRef;

  final String channel;

  /// Routing intent only. It never grants the target agent new permissions.
  final String intendedAgentRoleId;

  final DateTime receivedAt;
  final AgentOmnichannelIdentityContext identity;
  final AgentOmnichannelPrivacyContext privacy;

  bool get channelContentIsAuthority => false;
  bool get identityIsAuthority => false;
  bool get isRuntimeExecutable => false;
  bool get mayGrantPermission => false;
  bool get mayConsumeApproval => false;
  bool get mayWriteBusinessData => false;
  bool get mayTrainModel => false;
  bool get mayChangePrompt => false;
  bool get mayDeploy => false;

  void validate() {
    if (envelopeId.trim().isEmpty ||
        externalMessageRef.trim().isEmpty ||
        intendedAgentRoleId.trim().isEmpty ||
        !AgentOmnichannelChannel.values.contains(channel)) {
      throw const AgentOmnichannelContractException(
        'Omnichannel envelope identity/channel/role is invalid.',
      );
    }

    identity.validate();
    privacy.validate();
  }

  Map<String, dynamic> toSafeMap() {
    validate();

    return Map<String, dynamic>.unmodifiable(<String, dynamic>{
      'envelopeId': envelopeId.trim(),
      'externalMessageRef': externalMessageRef.trim(),
      'channel': channel,
      'intendedAgentRoleId': intendedAgentRoleId.trim(),
      'receivedAt': receivedAt.toUtc().toIso8601String(),
      'identity': identity.toSafeMap(),
      'privacy': privacy.toSafeMap(),
      'channelContentIsAuthority': false,
      'identityIsAuthority': false,
      'isRuntimeExecutable': false,
      'mayGrantPermission': false,
      'mayConsumeApproval': false,
      'mayWriteBusinessData': false,
      'mayTrainModel': false,
      'mayChangePrompt': false,
      'mayDeploy': false,
    });
  }
}

class AgentOmnichannelIngressDecision {
  AgentOmnichannelIngressDecision({
    required this.acceptedForRouting,
    required this.requiresIdentityVerification,
    required this.requiresStrongReauthBeforeConsequentialAction,
    required this.emergencySafeTriageOnly,
    required List<String> reasonCodes,
  }) : reasonCodes = List<String>.unmodifiable(reasonCodes);

  final bool acceptedForRouting;
  final bool requiresIdentityVerification;
  final bool requiresStrongReauthBeforeConsequentialAction;
  final bool emergencySafeTriageOnly;
  final List<String> reasonCodes;

  bool get grantsAuthority => false;
  bool get executesBusinessAction => false;
  bool get consumesApproval => false;
  bool get mayTrainModel => false;
  bool get mayDeploy => false;

  void validate() {
    if (reasonCodes.isEmpty ||
        reasonCodes.any((String value) => value.trim().isEmpty)) {
      throw const AgentOmnichannelContractException(
        'Omnichannel ingress decision requires reason codes.',
      );
    }
  }

  Map<String, dynamic> toSafeMap() {
    validate();

    return Map<String, dynamic>.unmodifiable(<String, dynamic>{
      'acceptedForRouting': acceptedForRouting,
      'requiresIdentityVerification': requiresIdentityVerification,
      'requiresStrongReauthBeforeConsequentialAction':
          requiresStrongReauthBeforeConsequentialAction,
      'emergencySafeTriageOnly': emergencySafeTriageOnly,
      'reasonCodes': List<String>.unmodifiable(reasonCodes),
      'grantsAuthority': false,
      'executesBusinessAction': false,
      'consumesApproval': false,
      'mayTrainModel': false,
      'mayDeploy': false,
    });
  }
}
