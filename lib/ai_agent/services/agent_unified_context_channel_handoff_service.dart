import '../constants/agent_omnichannel_constants.dart';
import '../models/agent_unified_context_channel_handoff.dart';
import '../models/agent_unified_context_continuity_evidence.dart';
import '../models/agent_unified_context_prompt_projection.dart';

class AgentUnifiedContextChannelHandoffService {
  const AgentUnifiedContextChannelHandoffService();

  static const Map<String, String> _channelByRole = <String, String>{
    'support_agent': AgentOmnichannelChannel.appChat,
    'customer_whatsapp_agent': AgentOmnichannelChannel.customerWhatsApp,
    'owner_whatsapp_agent': AgentOmnichannelChannel.ownerWhatsApp,
    'emergency_whatsapp_agent': AgentOmnichannelChannel.emergencyWhatsApp,
    'email_agent': AgentOmnichannelChannel.email,
    'call_agent': AgentOmnichannelChannel.phoneCall,
    'voice_super_admin_agent': AgentOmnichannelChannel.ownerVoice,
  };

  AgentUnifiedContextChannelHandoff prepare({
    required String handoffId,
    required String subjectRef,
    required String requestedPurpose,
    required String sourceChannel,
    required String targetChannel,
    required String targetRoleId,
    required AgentUnifiedContextPromptProjection projection,
    required AgentUnifiedContextContinuityEvidence continuityEvidence,
    required bool phase51ChannelControlAllowed,
    required bool targetChannelAvailable,
    required bool phase51FailureIsolationIntact,
  }) {
    try {
      continuityEvidence.validateStructure();
    } on AgentUnifiedContextContinuityEvidenceException {
      return _blocked(
        handoffId: handoffId,
        subjectRef: subjectRef,
        requestedPurpose: requestedPurpose,
        sourceChannel: sourceChannel,
        targetChannel: targetChannel,
        targetRoleId: targetRoleId,
        reasonCode: AgentUnifiedContextChannelHandoffReason.invalidEvidence,
      );
    }

    if (!projection.ready) {
      return _blocked(
        handoffId: handoffId,
        subjectRef: subjectRef,
        requestedPurpose: requestedPurpose,
        sourceChannel: sourceChannel,
        targetChannel: targetChannel,
        targetRoleId: targetRoleId,
        reasonCode:
            AgentUnifiedContextChannelHandoffReason.sourceProjectionNotReady,
      );
    }

    if (projection.requestingSubjectRef != subjectRef) {
      return _blocked(
        handoffId: handoffId,
        subjectRef: subjectRef,
        requestedPurpose: requestedPurpose,
        sourceChannel: sourceChannel,
        targetChannel: targetChannel,
        targetRoleId: targetRoleId,
        reasonCode: AgentUnifiedContextChannelHandoffReason.subjectMismatch,
      );
    }

    if (projection.requestedPurpose != requestedPurpose) {
      return _blocked(
        handoffId: handoffId,
        subjectRef: subjectRef,
        requestedPurpose: requestedPurpose,
        sourceChannel: sourceChannel,
        targetChannel: targetChannel,
        targetRoleId: targetRoleId,
        reasonCode: AgentUnifiedContextChannelHandoffReason.purposeMismatch,
      );
    }

    final String? expectedTargetChannel = _channelByRole[targetRoleId];

    if (expectedTargetChannel == null ||
        expectedTargetChannel != targetChannel) {
      return _blocked(
        handoffId: handoffId,
        subjectRef: subjectRef,
        requestedPurpose: requestedPurpose,
        sourceChannel: sourceChannel,
        targetChannel: targetChannel,
        targetRoleId: targetRoleId,
        reasonCode: AgentUnifiedContextChannelHandoffReason.roleChannelMismatch,
      );
    }

    if (!phase51ChannelControlAllowed) {
      return _isolatedFailure(
        handoffId: handoffId,
        subjectRef: subjectRef,
        requestedPurpose: requestedPurpose,
        sourceChannel: sourceChannel,
        targetChannel: targetChannel,
        targetRoleId: targetRoleId,
        reasonCode:
            AgentUnifiedContextChannelHandoffReason.phase51ControlBlocked,
      );
    }

    if (!targetChannelAvailable) {
      return _isolatedFailure(
        handoffId: handoffId,
        subjectRef: subjectRef,
        requestedPurpose: requestedPurpose,
        sourceChannel: sourceChannel,
        targetChannel: targetChannel,
        targetRoleId: targetRoleId,
        reasonCode:
            AgentUnifiedContextChannelHandoffReason.targetChannelUnavailable,
      );
    }

    if (!phase51FailureIsolationIntact) {
      return _blocked(
        handoffId: handoffId,
        subjectRef: subjectRef,
        requestedPurpose: requestedPurpose,
        sourceChannel: sourceChannel,
        targetChannel: targetChannel,
        targetRoleId: targetRoleId,
        reasonCode: AgentUnifiedContextChannelHandoffReason
            .phase51FailureIsolationMissing,
      );
    }

    if (continuityEvidence.currentChannel != targetChannel) {
      return _blocked(
        handoffId: handoffId,
        subjectRef: subjectRef,
        requestedPurpose: requestedPurpose,
        sourceChannel: sourceChannel,
        targetChannel: targetChannel,
        targetRoleId: targetRoleId,
        reasonCode: AgentUnifiedContextChannelHandoffReason
            .evidenceCurrentChannelMismatch,
      );
    }

    if (!continuityEvidence.phase51ContinuityMetadataOnly ||
        continuityEvidence.phase51CarriesMessageHistory ||
        continuityEvidence.phase51CarriesSharedCustomerContext) {
      return _blocked(
        handoffId: handoffId,
        subjectRef: subjectRef,
        requestedPurpose: requestedPurpose,
        sourceChannel: sourceChannel,
        targetChannel: targetChannel,
        targetRoleId: targetRoleId,
        reasonCode: AgentUnifiedContextChannelHandoffReason
            .phase51MetadataBoundaryInvalid,
      );
    }

    if (!continuityEvidence.samePseudonymousSubject) {
      return _blocked(
        handoffId: handoffId,
        subjectRef: subjectRef,
        requestedPurpose: requestedPurpose,
        sourceChannel: sourceChannel,
        targetChannel: targetChannel,
        targetRoleId: targetRoleId,
        reasonCode:
            AgentUnifiedContextChannelHandoffReason.subjectContinuityUntrusted,
      );
    }

    if (!continuityEvidence.trustedIdentityContinuity) {
      return _blocked(
        handoffId: handoffId,
        subjectRef: subjectRef,
        requestedPurpose: requestedPurpose,
        sourceChannel: sourceChannel,
        targetChannel: targetChannel,
        targetRoleId: targetRoleId,
        reasonCode:
            AgentUnifiedContextChannelHandoffReason.identityContinuityUntrusted,
      );
    }

    if (continuityEvidence.isCrossChannel &&
        !continuityEvidence.withinContinuityWindow) {
      return _blocked(
        handoffId: handoffId,
        subjectRef: subjectRef,
        requestedPurpose: requestedPurpose,
        sourceChannel: sourceChannel,
        targetChannel: targetChannel,
        targetRoleId: targetRoleId,
        reasonCode:
            AgentUnifiedContextChannelHandoffReason.continuityWindowExpired,
      );
    }

    if (!continuityEvidence.replayAssessmentPassed) {
      return _blocked(
        handoffId: handoffId,
        subjectRef: subjectRef,
        requestedPurpose: requestedPurpose,
        sourceChannel: sourceChannel,
        targetChannel: targetChannel,
        targetRoleId: targetRoleId,
        reasonCode: AgentUnifiedContextChannelHandoffReason.replaySafetyFailed,
      );
    }

    if (_isEmergencyChannel(sourceChannel) ||
        _isEmergencyChannel(targetChannel) ||
        continuityEvidence.emergencySafeTriageOnly) {
      if (sourceChannel != targetChannel ||
          !_isEmergencyChannel(targetChannel)) {
        return _blocked(
          handoffId: handoffId,
          subjectRef: subjectRef,
          requestedPurpose: requestedPurpose,
          sourceChannel: sourceChannel,
          targetChannel: targetChannel,
          targetRoleId: targetRoleId,
          reasonCode: AgentUnifiedContextChannelHandoffReason
              .emergencyContinuityIsolated,
        );
      }
    }

    if (_channelDomain(sourceChannel) != _channelDomain(targetChannel)) {
      return _blocked(
        handoffId: handoffId,
        subjectRef: subjectRef,
        requestedPurpose: requestedPurpose,
        sourceChannel: sourceChannel,
        targetChannel: targetChannel,
        targetRoleId: targetRoleId,
        reasonCode:
            AgentUnifiedContextChannelHandoffReason.channelDomainMismatch,
      );
    }

    final bool hasLimitations =
        projection.hasOmissions || projection.hasUnresolvedRequiredKeys;

    return AgentUnifiedContextChannelHandoff(
      status: hasLimitations
          ? AgentUnifiedContextChannelHandoffStatus.preparedWithLimitations
          : AgentUnifiedContextChannelHandoffStatus.prepared,
      reasonCode: hasLimitations
          ? AgentUnifiedContextChannelHandoffReason.unresolvedProjection
          : AgentUnifiedContextChannelHandoffReason.prepared,
      handoffId: handoffId,
      subjectRef: subjectRef,
      requestedPurpose: requestedPurpose,
      sourceChannel: sourceChannel,
      targetChannel: targetChannel,
      targetRoleId: targetRoleId,
      projection: projection,
      failureContainedToHandoff: true,
      otherChannelsRemainAvailable: true,
      coreSwatRideRemainsAvailable: true,
    );
  }

  String _channelDomain(String channel) {
    if (channel == AgentOmnichannelChannel.appChat ||
        channel == AgentOmnichannelChannel.customerWhatsApp ||
        channel == AgentOmnichannelChannel.email ||
        channel == AgentOmnichannelChannel.phoneCall) {
      return 'CUSTOMER';
    }

    if (channel == AgentOmnichannelChannel.ownerWhatsApp ||
        channel == AgentOmnichannelChannel.ownerVoice) {
      return 'OWNER';
    }

    if (channel == AgentOmnichannelChannel.emergencyWhatsApp) {
      return 'EMERGENCY';
    }

    return 'UNKNOWN';
  }

  bool _isEmergencyChannel(String channel) {
    return channel == AgentOmnichannelChannel.emergencyWhatsApp;
  }

  AgentUnifiedContextChannelHandoff _blocked({
    required String handoffId,
    required String subjectRef,
    required String requestedPurpose,
    required String sourceChannel,
    required String targetChannel,
    required String targetRoleId,
    required String reasonCode,
  }) {
    return AgentUnifiedContextChannelHandoff(
      status: AgentUnifiedContextChannelHandoffStatus.blocked,
      reasonCode: reasonCode,
      handoffId: handoffId,
      subjectRef: subjectRef,
      requestedPurpose: requestedPurpose,
      sourceChannel: sourceChannel,
      targetChannel: targetChannel,
      targetRoleId: targetRoleId,
      projection: null,
      failureContainedToHandoff: true,
      otherChannelsRemainAvailable: true,
      coreSwatRideRemainsAvailable: true,
    );
  }

  AgentUnifiedContextChannelHandoff _isolatedFailure({
    required String handoffId,
    required String subjectRef,
    required String requestedPurpose,
    required String sourceChannel,
    required String targetChannel,
    required String targetRoleId,
    required String reasonCode,
  }) {
    return AgentUnifiedContextChannelHandoff(
      status: AgentUnifiedContextChannelHandoffStatus.isolatedFailure,
      reasonCode: reasonCode,
      handoffId: handoffId,
      subjectRef: subjectRef,
      requestedPurpose: requestedPurpose,
      sourceChannel: sourceChannel,
      targetChannel: targetChannel,
      targetRoleId: targetRoleId,
      projection: null,
      failureContainedToHandoff: true,
      otherChannelsRemainAvailable: true,
      coreSwatRideRemainsAvailable: true,
    );
  }

  bool get grantsAuthority => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get invokesProvider => false;
  bool get invokesTargetAgent => false;
  bool get invokesRuntimeGate => false;
  bool get writesBusinessData => false;
  bool get persistsContext => false;
  bool get persistsHandoff => false;
  bool get activatesChannel => false;
  bool get changesPhase51ChannelControl => false;
  bool get bypassesPhase51ContinuityPolicy => false;
  bool get bypassesPhase51ReplayGuard => false;
  bool get loadsFullConversationHistory => false;
}
