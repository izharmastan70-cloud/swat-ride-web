class AgentEcosystemChannel {
  AgentEcosystemChannel._();

  static const String appChat = 'APP_CHAT';
  static const String email = 'EMAIL';
  static const String whatsapp = 'WHATSAPP';
  static const String phone = 'PHONE';
  static const String voice = 'VOICE';

  static const Set<String> values = <String>{
    appChat,
    email,
    whatsapp,
    phone,
    voice,
  };
}

class AgentEcosystemActorClaim {
  AgentEcosystemActorClaim._();

  static const String customer = 'CUSTOMER';
  static const String owner = 'OWNER';
  static const String admin = 'ADMIN';
  static const String anonymous = 'ANONYMOUS';

  static const Set<String> values = <String>{customer, owner, admin, anonymous};
}

class AgentEcosystemRequestKind {
  AgentEcosystemRequestKind._();

  static const String publicInformation = 'PUBLIC_INFORMATION';
  static const String accountPrivateInformation = 'ACCOUNT_PRIVATE_INFORMATION';
  static const String factualBookingOrderPayment =
      'FACTUAL_BOOKING_ORDER_PAYMENT';
  static const String consequentialAction = 'CONSEQUENTIAL_ACTION';

  static const Set<String> values = <String>{
    publicInformation,
    accountPrivateInformation,
    factualBookingOrderPayment,
    consequentialAction,
  };
}

class AgentEcosystemSafetyDecisionStatus {
  AgentEcosystemSafetyDecisionStatus._();

  static const String allowSafeResponse = 'ALLOW_SAFE_RESPONSE';
  static const String blockEmergencyStop = 'BLOCK_EMERGENCY_STOP';
  static const String blockModuleDisabled = 'BLOCK_MODULE_DISABLED';
  static const String requireTrustedIdentity = 'REQUIRE_TRUSTED_IDENTITY';
  static const String blockSubjectMismatch = 'BLOCK_SUBJECT_MISMATCH';
  static const String requireVerifiedEvidence = 'REQUIRE_VERIFIED_EVIDENCE';
  static const String requireControlChain = 'REQUIRE_CONTROL_CHAIN';
  static const String eligibleControlledHandoff = 'ELIGIBLE_CONTROLLED_HANDOFF';

  static const Set<String> values = <String>{
    allowSafeResponse,
    blockEmergencyStop,
    blockModuleDisabled,
    requireTrustedIdentity,
    blockSubjectMismatch,
    requireVerifiedEvidence,
    requireControlChain,
    eligibleControlledHandoff,
  };
}

class AgentEcosystemRoutingTarget {
  AgentEcosystemRoutingTarget._();

  static const String safeResponse = 'SAFE_RESPONSE';
  static const String trustedIdentityGate = 'TRUSTED_IDENTITY_GATE';
  static const String verifiedEvidenceGate = 'VERIFIED_EVIDENCE_GATE';
  static const String permissionApprovalRuntimeGate =
      'PERMISSION_APPROVAL_RUNTIME_GATE';
  static const String controlledExecutionHandoff =
      'CONTROLLED_EXECUTION_HANDOFF';
  static const String blocked = 'BLOCKED';
}
