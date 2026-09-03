class AgentOmnichannelChannel {
  AgentOmnichannelChannel._();

  static const String appChat = 'APP_CHAT';
  static const String customerWhatsApp = 'CUSTOMER_WHATSAPP';
  static const String ownerWhatsApp = 'OWNER_WHATSAPP';
  static const String emergencyWhatsApp = 'EMERGENCY_WHATSAPP';
  static const String email = 'EMAIL';
  static const String phoneCall = 'PHONE_CALL';
  static const String ownerVoice = 'OWNER_VOICE';

  static const Set<String> values = <String>{
    appChat,
    customerWhatsApp,
    ownerWhatsApp,
    emergencyWhatsApp,
    email,
    phoneCall,
    ownerVoice,
  };
}

class AgentOmnichannelIdentityAssurance {
  AgentOmnichannelIdentityAssurance._();

  static const String anonymous = 'ANONYMOUS';
  static const String asserted = 'ASSERTED';
  static const String verifiedSession = 'VERIFIED_SESSION';
  static const String strongReauth = 'STRONG_REAUTH';

  static const Set<String> values = <String>{
    anonymous,
    asserted,
    verifiedSession,
    strongReauth,
  };
}

class AgentOmnichannelIngressReason {
  AgentOmnichannelIngressReason._();

  static const String accepted = 'accepted';
  static const String channelRoleMismatch = 'channel_role_mismatch';
  static const String privacyFilterRequired = 'privacy_filter_required';
  static const String identityVerificationRequired =
      'identity_verification_required';
  static const String strongReauthRequired = 'strong_reauth_required';
  static const String emergencyUnverifiedSafeTriage =
      'emergency_unverified_safe_triage';
}
