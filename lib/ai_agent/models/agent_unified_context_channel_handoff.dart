import 'agent_unified_context_prompt_projection.dart';

class AgentUnifiedContextChannelHandoffStatus {
  AgentUnifiedContextChannelHandoffStatus._();

  static const String prepared = 'PREPARED';
  static const String preparedWithLimitations = 'PREPARED_WITH_LIMITATIONS';
  static const String blocked = 'BLOCKED';
  static const String isolatedFailure = 'ISOLATED_FAILURE';
}

class AgentUnifiedContextChannelHandoffReason {
  AgentUnifiedContextChannelHandoffReason._();

  static const String prepared = 'context_handoff_prepared';
  static const String invalidEvidence = 'invalid_continuity_evidence';
  static const String sourceProjectionNotReady = 'source_projection_not_ready';
  static const String subjectMismatch = 'handoff_subject_mismatch';
  static const String purposeMismatch = 'handoff_purpose_mismatch';
  static const String roleChannelMismatch = 'handoff_role_channel_mismatch';
  static const String phase51ControlBlocked = 'phase51_channel_control_blocked';
  static const String targetChannelUnavailable = 'target_channel_unavailable';
  static const String phase51FailureIsolationMissing =
      'phase51_failure_isolation_missing';
  static const String evidenceCurrentChannelMismatch =
      'continuity_current_channel_mismatch';
  static const String phase51MetadataBoundaryInvalid =
      'phase51_metadata_boundary_invalid';
  static const String subjectContinuityUntrusted =
      'subject_continuity_untrusted';
  static const String identityContinuityUntrusted =
      'identity_continuity_untrusted';
  static const String continuityWindowExpired = 'continuity_window_expired';
  static const String replaySafetyFailed = 'replay_safety_failed';
  static const String channelDomainMismatch = 'channel_domain_mismatch';
  static const String emergencyContinuityIsolated =
      'emergency_continuity_isolated';
  static const String unresolvedProjection =
      'projection_contains_unresolved_keys';
}

class AgentUnifiedContextChannelHandoff {
  AgentUnifiedContextChannelHandoff({
    required this.status,
    required this.reasonCode,
    required this.handoffId,
    required this.subjectRef,
    required this.requestedPurpose,
    required this.sourceChannel,
    required this.targetChannel,
    required this.targetRoleId,
    required this.projection,
    required this.failureContainedToHandoff,
    required this.otherChannelsRemainAvailable,
    required this.coreSwatRideRemainsAvailable,
  });

  final String status;
  final String reasonCode;
  final String handoffId;
  final String subjectRef;
  final String requestedPurpose;
  final String sourceChannel;
  final String targetChannel;
  final String targetRoleId;
  final AgentUnifiedContextPromptProjection? projection;

  final bool failureContainedToHandoff;
  final bool otherChannelsRemainAvailable;
  final bool coreSwatRideRemainsAvailable;

  bool get prepared =>
      status == AgentUnifiedContextChannelHandoffStatus.prepared ||
      status == AgentUnifiedContextChannelHandoffStatus.preparedWithLimitations;

  bool get blocked => status == AgentUnifiedContextChannelHandoffStatus.blocked;

  bool get isolatedFailure =>
      status == AgentUnifiedContextChannelHandoffStatus.isolatedFailure;

  bool get hasProjection => projection != null;

  bool get grantsAuthority => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get invokesProvider => false;
  bool get invokesTargetAgent => false;
  bool get invokesRuntimeGate => false;
  bool get writesBusinessData => false;
  bool get persistsHandoff => false;
  bool get activatesChannel => false;
  bool get changesChannelControl => false;

  String renderPreparedContextForTarget() {
    if (!prepared || projection == null) {
      return 'NO_UNIFIED_CONTEXT_HANDOFF';
    }

    return projection!.renderForPrompt();
  }

  Map<String, dynamic> toSafeMetadataMap() {
    return Map<String, dynamic>.unmodifiable(<String, dynamic>{
      'status': status,
      'reasonCode': reasonCode,
      'handoffId': handoffId,
      'subjectRef': subjectRef,
      'requestedPurpose': requestedPurpose,
      'sourceChannel': sourceChannel,
      'targetChannel': targetChannel,
      'targetRoleId': targetRoleId,
      'hasProjection': hasProjection,
      'projectionValuesIncluded': false,
      'failureContainedToHandoff': failureContainedToHandoff,
      'otherChannelsRemainAvailable': otherChannelsRemainAvailable,
      'coreSwatRideRemainsAvailable': coreSwatRideRemainsAvailable,
      'grantsAuthority': false,
      'grantsPermission': false,
      'consumesApproval': false,
      'invokesProvider': false,
      'invokesTargetAgent': false,
      'invokesRuntimeGate': false,
      'writesBusinessData': false,
      'persistsHandoff': false,
      'activatesChannel': false,
      'changesChannelControl': false,
    });
  }
}
