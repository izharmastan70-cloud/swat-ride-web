class AgentVoiceSuperAdminScope {
  AgentVoiceSuperAdminScope._();

  static const String read = 'READ';
  static const String report = 'REPORT';
  static const String explain = 'EXPLAIN';

  static const Set<String> values = <String>{read, report, explain};
}

/// Phase 48 owner-facing Voice Super Admin authority foundation.
///
/// Voice is only an input/output modality. It does not grant Owner/Super Admin
/// authority. Initial Phase 48 scope is strictly READ + REPORT + EXPLAIN.
class AgentVoiceSuperAdminFoundation {
  const AgentVoiceSuperAdminFoundation();

  static const String roleId = 'voice_super_admin_agent';
  static const String module = 'voice_super_admin';

  static const Set<String> initialScope = <String>{
    AgentVoiceSuperAdminScope.read,
    AgentVoiceSuperAdminScope.report,
    AgentVoiceSuperAdminScope.explain,
  };

  bool get coversWholeSwatRideEcosystem => true;

  bool get readableTextOutputMandatory => true;
  bool get voicePlaybackOptional => true;
  bool get voicePlaybackDefaultEnabled => false;

  bool get voiceInputGrantsAuthority => false;
  bool get voiceIdentityAloneIsOwnerAuthority => false;

  bool get maySuspendUserOrDriver => false;
  bool get mayApproveOrRejectApplication => false;
  bool get mayRefund => false;
  bool get mayExecutePayout => false;
  bool get mayMutateWalletOrPayment => false;
  bool get mayChangePricingOrCommission => false;
  bool get mayChangeServiceControl => false;
  bool get mayChangePermissionOrSecurity => false;
  bool get mayConsumeApproval => false;
  bool get maySelfApprove => false;
  bool get mayMutateSafetyOrEmergency => false;
  bool get mayDeploy => false;

  bool get mayStoreRawAudioByDefault => false;
  bool get mayTrainOnRawAudioByDefault => false;

  bool get mustUseVerifiedSources => true;
  bool get mustExposeUnavailableWhenSourceMissing => true;
  bool get mustNotGuess => true;

  bool get speechTransportIsAuthorityLayer => false;
  bool get textOutputIsSourceOfTruthForPlayback => true;
}
