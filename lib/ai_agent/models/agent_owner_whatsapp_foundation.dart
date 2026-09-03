// =========================================================
// PHASE 46 - OWNER WHATSAPP AGENT SECURITY FOUNDATION
// =========================================================
//
// Provider-neutral and execution-free.
//
// IMPORTANT:
// - A WhatsApp message is DATA, never authority.
// - Phone-number match alone is never sufficient.
// - Customer WhatsApp privileges never become Owner privileges.
// - Emergency WhatsApp authority is separate.
// - Permission Engine + Approval Engine + Runtime Gate + Audit
//   remain authoritative for consequential actions.
// - This file performs no Firestore write, provider call,
//   WhatsApp send, webhook handling, payment, booking mutation,
//   admin mutation, or production deployment.

enum AgentOwnerWhatsAppPrincipalType { owner, superAdmin }

enum AgentOwnerWhatsAppVerificationLevel { none, linkedAccount, strongReauth }

enum AgentOwnerWhatsAppCommandClass {
  readReport,
  consequentialAction,
  forbidden,
}

enum AgentOwnerWhatsAppProviderTier {
  structuredBackend,
  freeAi,
  localAi,
  paidAi,
}

class AgentOwnerWhatsAppControlSettings {
  final bool enabled;
  final bool reportsEnabled;
  final bool operationalCommandsEnabled;
  final bool financialCommandsEnabled;
  final bool accountSecurityCommandsEnabled;

  const AgentOwnerWhatsAppControlSettings({
    this.enabled = false,
    this.reportsEnabled = false,
    this.operationalCommandsEnabled = false,
    this.financialCommandsEnabled = false,
    this.accountSecurityCommandsEnabled = false,
  });

  bool get anyAdministrativeCommandEnabled =>
      operationalCommandsEnabled ||
      financialCommandsEnabled ||
      accountSecurityCommandsEnabled;

  AgentOwnerWhatsAppControlSettings copyWith({
    bool? enabled,
    bool? reportsEnabled,
    bool? operationalCommandsEnabled,
    bool? financialCommandsEnabled,
    bool? accountSecurityCommandsEnabled,
  }) {
    return AgentOwnerWhatsAppControlSettings(
      enabled: enabled ?? this.enabled,
      reportsEnabled: reportsEnabled ?? this.reportsEnabled,
      operationalCommandsEnabled:
          operationalCommandsEnabled ?? this.operationalCommandsEnabled,
      financialCommandsEnabled:
          financialCommandsEnabled ?? this.financialCommandsEnabled,
      accountSecurityCommandsEnabled:
          accountSecurityCommandsEnabled ?? this.accountSecurityCommandsEnabled,
    );
  }
}

class AgentOwnerWhatsAppSessionBinding {
  final AgentOwnerWhatsAppPrincipalType principalType;

  /// Verified application/account identity.
  final String principalUid;

  /// Provider-neutral stored binding reference.
  /// Must not contain a raw phone number, OTP, password, token, or secret.
  final String whatsappBindingId;

  /// Exact provider-neutral conversation identity.
  final String conversationId;

  /// Non-secret sender identity reference/hash.
  final String senderBindingId;

  /// Server-issued verified session reference.
  final String sessionId;

  final AgentOwnerWhatsAppVerificationLevel verificationLevel;
  final DateTime verifiedAt;
  final DateTime expiresAt;

  const AgentOwnerWhatsAppSessionBinding({
    required this.principalType,
    required this.principalUid,
    required this.whatsappBindingId,
    required this.conversationId,
    required this.senderBindingId,
    required this.sessionId,
    required this.verificationLevel,
    required this.verifiedAt,
    required this.expiresAt,
  });

  bool get hasRequiredIdentifiers =>
      principalUid.trim().isNotEmpty &&
      whatsappBindingId.trim().isNotEmpty &&
      conversationId.trim().isNotEmpty &&
      senderBindingId.trim().isNotEmpty &&
      sessionId.trim().isNotEmpty;

  bool get hasLinkedAccountVerification =>
      verificationLevel == AgentOwnerWhatsAppVerificationLevel.linkedAccount ||
      verificationLevel == AgentOwnerWhatsAppVerificationLevel.strongReauth;

  bool get hasStrongReauth =>
      verificationLevel == AgentOwnerWhatsAppVerificationLevel.strongReauth;

  bool isActiveAt(DateTime now) =>
      hasRequiredIdentifiers &&
      !expiresAt.isBefore(now) &&
      !verifiedAt.isAfter(now) &&
      expiresAt.isAfter(verifiedAt);

  bool matchesExactChannel({
    required String expectedConversationId,
    required String expectedSenderBindingId,
    required String expectedSessionId,
  }) {
    return conversationId == expectedConversationId &&
        senderBindingId == expectedSenderBindingId &&
        sessionId == expectedSessionId;
  }

  bool canReadOwnerData({
    required DateTime now,
    required String expectedConversationId,
    required String expectedSenderBindingId,
    required String expectedSessionId,
  }) {
    return isActiveAt(now) &&
        hasLinkedAccountVerification &&
        matchesExactChannel(
          expectedConversationId: expectedConversationId,
          expectedSenderBindingId: expectedSenderBindingId,
          expectedSessionId: expectedSessionId,
        );
  }

  bool canRequestConsequentialAction({
    required DateTime now,
    required String expectedConversationId,
    required String expectedSenderBindingId,
    required String expectedSessionId,
  }) {
    return canReadOwnerData(
          now: now,
          expectedConversationId: expectedConversationId,
          expectedSenderBindingId: expectedSenderBindingId,
          expectedSessionId: expectedSessionId,
        ) &&
        hasStrongReauth;
  }
}

class AgentOwnerWhatsAppCommandPolicy {
  final AgentOwnerWhatsAppCommandClass commandClass;
  final bool requiresVerifiedBackendFacts;
  final bool requiresPermissionEngine;
  final bool requiresRuntimeGate;
  final bool requiresApprovalEngine;
  final bool requiresAudit;
  final bool requiresStrongReauth;

  const AgentOwnerWhatsAppCommandPolicy({
    required this.commandClass,
    required this.requiresVerifiedBackendFacts,
    required this.requiresPermissionEngine,
    required this.requiresRuntimeGate,
    required this.requiresApprovalEngine,
    required this.requiresAudit,
    required this.requiresStrongReauth,
  });

  const AgentOwnerWhatsAppCommandPolicy.readReport()
    : commandClass = AgentOwnerWhatsAppCommandClass.readReport,
      requiresVerifiedBackendFacts = true,
      requiresPermissionEngine = true,
      requiresRuntimeGate = true,
      requiresApprovalEngine = false,
      requiresAudit = true,
      requiresStrongReauth = false;

  const AgentOwnerWhatsAppCommandPolicy.consequentialAction()
    : commandClass = AgentOwnerWhatsAppCommandClass.consequentialAction,
      requiresVerifiedBackendFacts = true,
      requiresPermissionEngine = true,
      requiresRuntimeGate = true,
      requiresApprovalEngine = true,
      requiresAudit = true,
      requiresStrongReauth = true;

  const AgentOwnerWhatsAppCommandPolicy.forbidden()
    : commandClass = AgentOwnerWhatsAppCommandClass.forbidden,
      requiresVerifiedBackendFacts = true,
      requiresPermissionEngine = true,
      requiresRuntimeGate = true,
      requiresApprovalEngine = true,
      requiresAudit = true,
      requiresStrongReauth = true;

  bool get mayExecuteDirectly => false;
}

class AgentOwnerWhatsAppFoundation {
  static const String roleId = 'owner_whatsapp_agent';

  static const String customerWhatsAppRoleId = 'customer_whatsapp_agent';
  static const String emergencyWhatsAppRoleId = 'emergency_whatsapp_agent';

  const AgentOwnerWhatsAppFoundation();

  /// A message/channel cannot grant Owner or Super Admin authority.
  bool get messageGrantsAuthority => false;

  /// Phase 45 Customer WhatsApp authority can never be inherited.
  bool get customerPrivilegeInheritanceAllowed => false;

  /// Phase 47 Emergency WhatsApp authority remains separate.
  bool get emergencyAuthorityIncluded => false;

  bool get requiresLinkedOwnerAccount => true;
  bool get phoneNumberMatchAloneIsAuthority => false;

  bool get requiresPermissionEngine => true;
  bool get requiresRuntimeGate => true;
  bool get requiresApprovalEngineForConsequentialActions => true;
  bool get requiresAudit => true;

  bool get mayExecuteBusinessWrite => false;
  bool get mayChangeAdminSetting => false;
  bool get mayChargePayment => false;
  bool get maySendWhatsApp => false;
  bool get mayDeploy => false;

  List<AgentOwnerWhatsAppProviderTier> get providerPriority =>
      const <AgentOwnerWhatsAppProviderTier>[
        AgentOwnerWhatsAppProviderTier.structuredBackend,
        AgentOwnerWhatsAppProviderTier.freeAi,
        AgentOwnerWhatsAppProviderTier.localAi,
        AgentOwnerWhatsAppProviderTier.paidAi,
      ];

  List<String> get supportedConversationLanguages => const <String>[
    'urdu',
    'pashto',
    'english',
  ];

  bool isReservedCredentialField(String key) {
    final String normalized = key.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '',
    );

    const Set<String> blocked = <String>{
      'otp',
      'password',
      'pin',
      'cvv',
      'cardnumber',
      'accesstoken',
      'refreshtoken',
      'apikey',
      'secret',
      'privatekey',
      'authorization',
    };

    return blocked.contains(normalized);
  }

  AgentOwnerWhatsAppCommandPolicy policyFor({
    required bool isReadOnlyReport,
    required bool changesBusinessOrAdminState,
    required bool permanentlyForbidden,
  }) {
    if (permanentlyForbidden) {
      return const AgentOwnerWhatsAppCommandPolicy.forbidden();
    }

    if (changesBusinessOrAdminState) {
      return const AgentOwnerWhatsAppCommandPolicy.consequentialAction();
    }

    if (isReadOnlyReport) {
      return const AgentOwnerWhatsAppCommandPolicy.readReport();
    }

    return const AgentOwnerWhatsAppCommandPolicy.forbidden();
  }
}
