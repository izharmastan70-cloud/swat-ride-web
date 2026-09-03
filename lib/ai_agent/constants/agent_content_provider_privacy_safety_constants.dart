class AgentContentProviderClass {
  AgentContentProviderClass._();

  static const String templateOrCode = 'template_or_code';
  static const String freeOnline = 'free_online';
  static const String localOptional = 'local_optional';
  static const String paid = 'paid';

  static const Set<String> values = <String>{
    templateOrCode,
    freeOnline,
    localOptional,
    paid,
  };
}

class AgentContentProviderRouteStatus {
  AgentContentProviderRouteStatus._();

  static const String useTemplateOrCode = 'USE_TEMPLATE_OR_CODE';
  static const String useFreeOnline = 'USE_FREE_ONLINE';
  static const String useLocalOptional = 'USE_LOCAL_OPTIONAL';
  static const String paidApprovalRequired = 'PAID_APPROVAL_REQUIRED';
  static const String usePaid = 'USE_PAID';
  static const String paidDisabled = 'PAID_DISABLED';
  static const String paidBudgetBlocked = 'PAID_BUDGET_BLOCKED';
  static const String privacyBlocked = 'PRIVACY_BLOCKED';
  static const String adversarialBlocked = 'ADVERSARIAL_BLOCKED';
  static const String providerUnavailableDraftOnly =
      'PROVIDER_UNAVAILABLE_DRAFT_ONLY';

  static const Set<String> values = <String>{
    useTemplateOrCode,
    useFreeOnline,
    useLocalOptional,
    paidApprovalRequired,
    usePaid,
    paidDisabled,
    paidBudgetBlocked,
    privacyBlocked,
    adversarialBlocked,
    providerUnavailableDraftOnly,
  };
}

class AgentContentPrivacyRisk {
  AgentContentPrivacyRisk._();

  static const String safe = 'safe';
  static const String rawConversation = 'raw_conversation';
  static const String phone = 'phone';
  static const String email = 'email';
  static const String cnic = 'cnic';
  static const String authToken = 'auth_token';
  static const String password = 'password';
  static const String paymentCard = 'payment_card';
  static const String cvv = 'cvv';
  static const String pin = 'pin';
  static const String preciseLocation = 'precise_location';
  static const String privateComplaintEvidence = 'private_complaint_evidence';

  static const Set<String> forbidden = <String>{
    rawConversation,
    phone,
    email,
    cnic,
    authToken,
    password,
    paymentCard,
    cvv,
    pin,
    preciseLocation,
    privateComplaintEvidence,
  };
}

class AgentContentAdversarialScenario {
  AgentContentAdversarialScenario._();

  static const String fakeClaim = 'fake_claim';
  static const String fakeReview = 'fake_review';
  static const String fakeMetric = 'fake_metric';
  static const String fakeAvailability = 'fake_availability';
  static const String fakeOffer = 'fake_offer';
  static const String bypassReview = 'bypass_review';
  static const String bypassApproval = 'bypass_approval';
  static const String directPublish = 'direct_publish';
  static const String directSend = 'direct_send';
  static const String refundExecution = 'refund_execution';
  static const String walletMutation = 'wallet_mutation';
  static const String pricingMutation = 'pricing_mutation';
  static const String permissionMutation = 'permission_mutation';
  static const String secretExfiltration = 'secret_exfiltration';
  static const String privateDataExposure = 'private_data_exposure';
  static const String providerPolicyOverride = 'provider_policy_override';
  static const String costLimitOverride = 'cost_limit_override';
  static const String selfTrainingOverride = 'self_training_override';
  static const String realProofMisrepresentation =
      'real_proof_misrepresentation';
  static const String rageBaitManipulation = 'rage_bait_manipulation';

  static const Set<String> values = <String>{
    fakeClaim,
    fakeReview,
    fakeMetric,
    fakeAvailability,
    fakeOffer,
    bypassReview,
    bypassApproval,
    directPublish,
    directSend,
    refundExecution,
    walletMutation,
    pricingMutation,
    permissionMutation,
    secretExfiltration,
    privateDataExposure,
    providerPolicyOverride,
    costLimitOverride,
    selfTrainingOverride,
    realProofMisrepresentation,
    rageBaitManipulation,
  };
}

class AgentContentCostLimits {
  AgentContentCostLimits._();

  static const int maxRequestIdLength = 180;
  static const int maxContextFieldLength = 2000;
  static const int maxContextFields = 20;
  static const int maxReasonCodes = 16;
}
