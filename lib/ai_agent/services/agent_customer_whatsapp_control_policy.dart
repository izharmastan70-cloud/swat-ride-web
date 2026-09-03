import '../constants/agent_customer_whatsapp_constants.dart';

class AgentCustomerWhatsAppControlDecision {
  const AgentCustomerWhatsAppControlDecision({
    required this.allowed,
    required this.reason,
  });

  final bool allowed;
  final String reason;
}

class AgentCustomerWhatsAppControlPolicy {
  const AgentCustomerWhatsAppControlPolicy();

  static const bool whatsappMessageIsAuthority = false;
  static const bool permissionEngineRequiredForActions = true;
  static const bool approvalEngineRequiredWhenActionRequiresApproval = true;
  static const bool runtimeGateRequiredForActions = true;
  static const bool auditRequiredForAuthorizedActions = true;

  static const bool verifiedBackendRequiredForFare = true;
  static const bool verifiedBackendRequiredForDriverStatus = true;
  static const bool verifiedBackendRequiredForPaymentStatus = true;
  static const bool verifiedBackendRequiredForBookingStatus = true;
  static const bool verifiedBackendRequiredForAvailability = true;

  static const bool mayGuessFare = false;
  static const bool mayGuessDriver = false;
  static const bool mayGuessPayment = false;
  static const bool mayGuessBookingStatus = false;
  static const bool mayGuessAvailability = false;

  static const bool mayCollectOtp = false;
  static const bool mayCollectPassword = false;
  static const bool mayCollectApiKey = false;
  static const bool mayCollectPaymentCredential = false;

  static const bool bulkSpamAllowed = false;
  static const bool phishingAllowed = false;
  static const bool socialEngineeringAllowed = false;

  static const bool providerHardCodingAllowed = false;
  static const bool paidCodeAiAllowedForNormalReplies = false;

  static const bool callAgentOneSmsRuleChanged = false;
  static const bool phase46OwnerAuthorityIncluded = false;
  static const bool phase47EmergencyAuthorityIncluded = false;

  static const List<String> providerPriority =
      AgentCustomerWhatsAppProviderPolicy.priority;

  AgentCustomerWhatsAppControlDecision authorizeMasterToggle({
    required String actorRole,
  }) {
    final String normalized = actorRole.trim().toLowerCase();

    if (AgentCustomerWhatsAppActorRole.controlPlaneRoles.contains(normalized)) {
      return const AgentCustomerWhatsAppControlDecision(
        allowed: true,
        reason:
            'Admin/Super Admin may control the Customer WhatsApp Agent switch.',
      );
    }

    return const AgentCustomerWhatsAppControlDecision(
      allowed: false,
      reason:
          'Only Admin or Super Admin may control the Customer WhatsApp Agent switch.',
    );
  }

  bool requiresCustomerVerification({
    required bool sensitiveAccountDataRequested,
    required bool sensitiveBookingDataRequested,
    required bool paymentInformationRequested,
  }) {
    return sensitiveAccountDataRequested ||
        sensitiveBookingDataRequested ||
        paymentInformationRequested;
  }

  bool canUseBackendFact({required bool backendVerified}) {
    return backendVerified;
  }

  bool mayExecuteBusinessAction({
    required bool permissionPassed,
    required bool approvalRequired,
    required bool approvalPassed,
    required bool runtimeGatePassed,
  }) {
    if (!permissionPassed || !runtimeGatePassed) {
      return false;
    }

    if (approvalRequired && !approvalPassed) {
      return false;
    }

    return true;
  }
}
