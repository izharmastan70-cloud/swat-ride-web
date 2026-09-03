class AgentProviderExpansionReadinessStatus {
  AgentProviderExpansionReadinessStatus._();

  static const String foundationReadyNotProductionActive =
      'FOUNDATION_READY_NOT_PRODUCTION_ACTIVE';

  static const String blockedSafetyContract = 'BLOCKED_SAFETY_CONTRACT';

  static const String blockedAdversarialScenario =
      'BLOCKED_ADVERSARIAL_SCENARIO';

  static const String isolateProviderFailure = 'ISOLATE_PROVIDER_FAILURE';

  static const Set<String> values = <String>{
    foundationReadyNotProductionActive,
    blockedSafetyContract,
    blockedAdversarialScenario,
    isolateProviderFailure,
  };
}

class AgentProviderExpansionAdversarialType {
  AgentProviderExpansionAdversarialType._();

  static const String promptInjection = 'PROMPT_INJECTION';
  static const String providerOutputClaimsAuthority =
      'PROVIDER_OUTPUT_CLAIMS_AUTHORITY';
  static const String clientSecretInjection = 'CLIENT_SECRET_INJECTION';
  static const String directProviderUrlAttempt = 'DIRECT_PROVIDER_URL_ATTEMPT';
  static const String rawPrivatePayload = 'RAW_PRIVATE_PAYLOAD';
  static const String paymentCredentialPayload = 'PAYMENT_CREDENTIAL_PAYLOAD';
  static const String identityDocumentPayload = 'IDENTITY_DOCUMENT_PAYLOAD';
  static const String privateHealthPayload = 'PRIVATE_HEALTH_PAYLOAD';
  static const String emergencyEvidencePayload = 'EMERGENCY_EVIDENCE_PAYLOAD';
  static const String sensitiveExternalTask = 'SENSITIVE_EXTERNAL_TASK';
  static const String bypassMinimization = 'BYPASS_MINIMIZATION';
  static const String bypassRedaction = 'BYPASS_REDACTION';
  static const String contextWindowOverflow = 'CONTEXT_WINDOW_OVERFLOW';
  static const String unsupportedCapability = 'UNSUPPORTED_CAPABILITY';
  static const String forcePaidEnable = 'FORCE_PAID_ENABLE';
  static const String bypassAskBeforePaid = 'BYPASS_ASK_BEFORE_PAID';
  static const String bypassPaidBudget = 'BYPASS_PAID_BUDGET';
  static const String duplicateCostAccounting = 'DUPLICATE_COST_ACCOUNTING';
  static const String automaticBudgetIncrease = 'AUTOMATIC_BUDGET_INCREASE';
  static const String automaticLimitOverride = 'AUTOMATIC_LIMIT_OVERRIDE';
  static const String productionActivationAttempt =
      'PRODUCTION_ACTIVATION_ATTEMPT';
  static const String providerFailure = 'PROVIDER_FAILURE';
  static const String providerTimeout = 'PROVIDER_TIMEOUT';
  static const String providerRateLimit = 'PROVIDER_RATE_LIMIT';
  static const String circuitOpen = 'CIRCUIT_OPEN';
  static const String accountingFailure = 'ACCOUNTING_FAILURE';

  static const Set<String> values = <String>{
    promptInjection,
    providerOutputClaimsAuthority,
    clientSecretInjection,
    directProviderUrlAttempt,
    rawPrivatePayload,
    paymentCredentialPayload,
    identityDocumentPayload,
    privateHealthPayload,
    emergencyEvidencePayload,
    sensitiveExternalTask,
    bypassMinimization,
    bypassRedaction,
    contextWindowOverflow,
    unsupportedCapability,
    forcePaidEnable,
    bypassAskBeforePaid,
    bypassPaidBudget,
    duplicateCostAccounting,
    automaticBudgetIncrease,
    automaticLimitOverride,
    productionActivationAttempt,
    providerFailure,
    providerTimeout,
    providerRateLimit,
    circuitOpen,
    accountingFailure,
  };

  static const Set<String> isolatedFailureTypes = <String>{
    providerFailure,
    providerTimeout,
    providerRateLimit,
    circuitOpen,
    accountingFailure,
  };
}

class AgentProviderExpansionCloseoutLimits {
  AgentProviderExpansionCloseoutLimits._();

  static const int idMax = 220;
  static const int maxReasonCodes = 20;
}
