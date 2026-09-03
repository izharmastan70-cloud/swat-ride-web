enum AgentEmergencyWhatsAppSubjectType {
  customer,
  provider,
  ownerOrPartner,
  parentOrGuardian,
  unknown,
}

enum AgentEmergencyWhatsAppVerificationLevel {
  none,
  channelBound,
  accountVerified,
}

enum AgentEmergencyWhatsAppCommandClass {
  readVerifiedSafetyStatus,
  prepareEmergencyEscalation,
  sensitiveSafetyData,
  forbidden,
}

/// Exact provider-neutral channel/session binding.
///
/// IMPORTANT:
/// - raw phone number is deliberately not stored here;
/// - phone-number match alone is never authority;
/// - a WhatsApp message is input data, not authorization.
class AgentEmergencyWhatsAppSessionBinding {
  const AgentEmergencyWhatsAppSessionBinding({
    required this.subjectType,
    required this.principalUid,
    required this.conversationId,
    required this.senderBindingId,
    required this.sessionId,
    required this.verificationLevel,
    required this.verifiedAt,
    required this.expiresAt,
  });

  final AgentEmergencyWhatsAppSubjectType subjectType;
  final String principalUid;
  final String conversationId;
  final String senderBindingId;
  final String sessionId;
  final AgentEmergencyWhatsAppVerificationLevel verificationLevel;
  final DateTime verifiedAt;
  final DateTime expiresAt;

  bool get hasRequiredIdentifiers =>
      principalUid.trim().isNotEmpty &&
      conversationId.trim().isNotEmpty &&
      senderBindingId.trim().isNotEmpty &&
      sessionId.trim().isNotEmpty;

  bool get isAccountVerified =>
      verificationLevel ==
      AgentEmergencyWhatsAppVerificationLevel.accountVerified;

  bool isActiveAt(DateTime now) =>
      hasRequiredIdentifiers &&
      !verifiedAt.isAfter(now) &&
      expiresAt.isAfter(verifiedAt) &&
      !expiresAt.isBefore(now);

  bool matchesExactChannel({
    required String expectedConversationId,
    required String expectedSenderBindingId,
    required String expectedSessionId,
  }) =>
      conversationId == expectedConversationId &&
      senderBindingId == expectedSenderBindingId &&
      sessionId == expectedSessionId;

  bool canReadVerifiedSafetyData({
    required DateTime now,
    required String expectedConversationId,
    required String expectedSenderBindingId,
    required String expectedSessionId,
  }) =>
      isActiveAt(now) &&
      isAccountVerified &&
      matchesExactChannel(
        expectedConversationId: expectedConversationId,
        expectedSenderBindingId: expectedSenderBindingId,
        expectedSessionId: expectedSessionId,
      );
}

/// Privacy request for highly sensitive emergency data.
///
/// Exact location, trusted-contact phone numbers and medical profile are
/// default-deny. A future audited connector may turn on an individual scope
/// only after exact identity + ownership + consent/safety-necessity checks.
class AgentEmergencyWhatsAppSensitiveDataScope {
  const AgentEmergencyWhatsAppSensitiveDataScope({
    this.exactLocationAllowed = false,
    this.trustedContactPhoneAllowed = false,
    this.medicalProfileAllowed = false,
  });

  final bool exactLocationAllowed;
  final bool trustedContactPhoneAllowed;
  final bool medicalProfileAllowed;

  bool get anySensitiveDataAllowed =>
      exactLocationAllowed ||
      trustedContactPhoneAllowed ||
      medicalProfileAllowed;
}

class AgentEmergencyWhatsAppCommandPolicy {
  const AgentEmergencyWhatsAppCommandPolicy._({
    required this.commandClass,
    required this.requiresAccountVerifiedIdentity,
    required this.requiresPermissionEngine,
    required this.requiresRuntimeGate,
    required this.requiresApprovalEngine,
    required this.requiresAudit,
    required this.requiresExplicitSensitiveDataScope,
  });

  const AgentEmergencyWhatsAppCommandPolicy.readVerifiedSafetyStatus()
    : this._(
        commandClass:
            AgentEmergencyWhatsAppCommandClass.readVerifiedSafetyStatus,
        requiresAccountVerifiedIdentity: true,
        requiresPermissionEngine: true,
        requiresRuntimeGate: true,
        requiresApprovalEngine: false,
        requiresAudit: true,
        requiresExplicitSensitiveDataScope: false,
      );

  /// Current central `sendSafetyAlert` action is high-risk and approval-bound.
  /// Therefore Phase 47 does not weaken it merely because input came from
  /// WhatsApp.
  const AgentEmergencyWhatsAppCommandPolicy.prepareEmergencyEscalation()
    : this._(
        commandClass:
            AgentEmergencyWhatsAppCommandClass.prepareEmergencyEscalation,
        requiresAccountVerifiedIdentity: true,
        requiresPermissionEngine: true,
        requiresRuntimeGate: true,
        requiresApprovalEngine: true,
        requiresAudit: true,
        requiresExplicitSensitiveDataScope: false,
      );

  const AgentEmergencyWhatsAppCommandPolicy.sensitiveSafetyData()
    : this._(
        commandClass: AgentEmergencyWhatsAppCommandClass.sensitiveSafetyData,
        requiresAccountVerifiedIdentity: true,
        requiresPermissionEngine: true,
        requiresRuntimeGate: true,
        requiresApprovalEngine: false,
        requiresAudit: true,
        requiresExplicitSensitiveDataScope: true,
      );

  const AgentEmergencyWhatsAppCommandPolicy.forbidden()
    : this._(
        commandClass: AgentEmergencyWhatsAppCommandClass.forbidden,
        requiresAccountVerifiedIdentity: true,
        requiresPermissionEngine: true,
        requiresRuntimeGate: true,
        requiresApprovalEngine: true,
        requiresAudit: true,
        requiresExplicitSensitiveDataScope: true,
      );

  final AgentEmergencyWhatsAppCommandClass commandClass;
  final bool requiresAccountVerifiedIdentity;
  final bool requiresPermissionEngine;
  final bool requiresRuntimeGate;
  final bool requiresApprovalEngine;
  final bool requiresAudit;
  final bool requiresExplicitSensitiveDataScope;

  bool get mayExecuteDirectly => false;
  bool get maySendExternalAlert => false;
  bool get mayPlaceEmergencyCall => false;
}

class AgentEmergencyWhatsAppFoundation {
  const AgentEmergencyWhatsAppFoundation();

  static const String roleId = 'emergency_whatsapp_agent';
  static const String module = 'emergency_whatsapp';

  static const String customerWhatsAppRoleId = 'customer_whatsapp_agent';
  static const String ownerWhatsAppRoleId = 'owner_whatsapp_agent';

  /// A message or phone-number match never grants authority.
  bool get messageGrantsAuthority => false;
  bool get phoneNumberMatchAloneIsAuthority => false;

  /// Other WhatsApp roles never inherit this channel's emergency privileges,
  /// and this role never inherits their customer/owner privileges.
  bool get customerWhatsAppAuthorityInherited => false;
  bool get ownerWhatsAppAuthorityInherited => false;
  bool get emergencyAuthorityGrantedToOtherWhatsAppRoles => false;

  /// Existing Universal Safety remains the source of truth.
  /// Phase 47 must use narrowly audited connectors rather than arbitrary
  /// Firestore access.
  bool get arbitrarySafetyFirestoreAccessAllowed => false;

  /// WhatsApp input cannot directly mutate the safety backend.
  bool get mayCreateSafetyIncidentFromMessage => false;
  bool get mayAcknowledgeIncident => false;
  bool get mayAssignSafetyAgent => false;
  bool get mayResolveIncident => false;
  bool get mayMarkUserSafe => false;
  bool get mayUpdateEmergencyLocation => false;
  bool get mayModifyTrustedContacts => false;

  /// Sensitive emergency data is default-deny.
  bool get mayExposeExactGpsByDefault => false;
  bool get mayExposeTrustedContactPhoneByDefault => false;
  bool get mayExposeMedicalProfileByDefault => false;

  /// Transport/provider remains off until trusted production activation.
  bool get maySendWhatsApp => false;
  bool get mayPlaceEmergencyCall => false;
  bool get maySendSms => false;
  bool get mayCallProvider => false;
  bool get mayHandleLiveWebhook => false;
  bool get mayDeploy => false;

  AgentEmergencyWhatsAppCommandPolicy policyFor({
    required bool readsVerifiedSafetyStatus,
    required bool preparesEmergencyEscalation,
    required bool requestsSensitiveSafetyData,
    required bool permanentlyForbidden,
  }) {
    if (permanentlyForbidden) {
      return const AgentEmergencyWhatsAppCommandPolicy.forbidden();
    }

    if (requestsSensitiveSafetyData) {
      return const AgentEmergencyWhatsAppCommandPolicy.sensitiveSafetyData();
    }

    if (preparesEmergencyEscalation) {
      return const AgentEmergencyWhatsAppCommandPolicy.prepareEmergencyEscalation();
    }

    if (readsVerifiedSafetyStatus) {
      return const AgentEmergencyWhatsAppCommandPolicy.readVerifiedSafetyStatus();
    }

    return const AgentEmergencyWhatsAppCommandPolicy.forbidden();
  }

  bool isReservedCredentialField(String key) {
    final String normalized = key.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '',
    );

    const Set<String> blocked = <String>{
      'otp',
      'password',
      'passcode',
      'pin',
      'cvv',
      'cvc',
      'cardnumber',
      'accesstoken',
      'refreshtoken',
      'apikey',
      'secret',
      'privatekey',
      'authorization',
      'cookie',
    };

    return blocked.contains(normalized);
  }
}
