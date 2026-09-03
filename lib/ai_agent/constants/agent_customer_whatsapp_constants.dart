class AgentCustomerWhatsAppActorRole {
  AgentCustomerWhatsAppActorRole._();

  static const String admin = 'admin';
  static const String superAdmin = 'super_admin';

  static const Set<String> controlPlaneRoles = <String>{admin, superAdmin};
}

class AgentCustomerWhatsAppService {
  AgentCustomerWhatsAppService._();

  static const String ride = 'RIDE';
  static const String food = 'FOOD';
  static const String hotel = 'HOTEL';
  static const String tour = 'TOUR';
  static const String cargo = 'CARGO';

  static const Set<String> values = <String>{ride, food, hotel, tour, cargo};
}

class AgentCustomerWhatsAppLanguage {
  AgentCustomerWhatsAppLanguage._();

  static const String urdu = 'URDU';
  static const String pashto = 'PASHTO';
  static const String english = 'ENGLISH';

  static const Set<String> values = <String>{urdu, pashto, english};
}

class AgentCustomerWhatsAppRequestState {
  AgentCustomerWhatsAppRequestState._();

  static const String received = 'RECEIVED';
  static const String needsVerification = 'NEEDS_VERIFICATION';
  static const String needsClarification = 'NEEDS_CLARIFICATION';
  static const String needsApproval = 'NEEDS_APPROVAL';
  static const String safeReplyReady = 'SAFE_REPLY_READY';
  static const String escalate = 'ESCALATE';
  static const String blocked = 'BLOCKED';

  static const Set<String> values = <String>{
    received,
    needsVerification,
    needsClarification,
    needsApproval,
    safeReplyReady,
    escalate,
    blocked,
  };
}

class AgentCustomerWhatsAppProviderPolicy {
  AgentCustomerWhatsAppProviderPolicy._();

  static const String structuredBackend = 'STRUCTURED_BACKEND';
  static const String freeOnlineAi = 'FREE_ONLINE_AI';
  static const String localAi = 'LOCAL_AI';
  static const String paidAi = 'PAID_AI';

  static const List<String> priority = <String>[
    structuredBackend,
    freeOnlineAi,
    localAi,
    paidAi,
  ];
}
