class AgentProviderPrivacyBoundary {
  AgentProviderPrivacyBoundary._();

  static const String externalOnline = 'EXTERNAL_ONLINE';
  static const String localPrivate = 'LOCAL_PRIVATE';

  static const Set<String> values = <String>{externalOnline, localPrivate};
}

class AgentProviderDataSensitivity {
  AgentProviderDataSensitivity._();

  static const String publicData = 'PUBLIC';
  static const String operational = 'OPERATIONAL';
  static const String personal = 'PERSONAL';
  static const String sensitive = 'SENSITIVE';
  static const String restricted = 'RESTRICTED';

  static const Set<String> values = <String>{
    publicData,
    operational,
    personal,
    sensitive,
    restricted,
  };
}

class AgentProviderRestrictedDataClass {
  AgentProviderRestrictedDataClass._();

  static const String rawPrompt = 'RAW_PROMPT';
  static const String rawConversation = 'RAW_CONVERSATION';
  static const String authToken = 'AUTH_TOKEN';
  static const String password = 'PASSWORD';
  static const String apiSecret = 'API_SECRET';
  static const String paymentCard = 'PAYMENT_CARD';
  static const String cvv = 'CVV';
  static const String pin = 'PIN';
  static const String cnicImage = 'CNIC_IMAGE';
  static const String passportImage = 'PASSPORT_IMAGE';
  static const String precisePrivateLocation = 'PRECISE_PRIVATE_LOCATION';
  static const String privateHealthRecord = 'PRIVATE_HEALTH_RECORD';
  static const String privateEmergencyEvidence = 'PRIVATE_EMERGENCY_EVIDENCE';
  static const String privateComplaintEvidence = 'PRIVATE_COMPLAINT_EVIDENCE';

  static const Set<String> values = <String>{
    rawPrompt,
    rawConversation,
    authToken,
    password,
    apiSecret,
    paymentCard,
    cvv,
    pin,
    cnicImage,
    passportImage,
    precisePrivateLocation,
    privateHealthRecord,
    privateEmergencyEvidence,
    privateComplaintEvidence,
  };
}

class AgentProviderSensitiveTaskClass {
  AgentProviderSensitiveTaskClass._();

  static const String normal = 'NORMAL';
  static const String identitySensitive = 'IDENTITY_SENSITIVE';
  static const String paymentSensitive = 'PAYMENT_SENSITIVE';
  static const String healthSensitive = 'HEALTH_SENSITIVE';
  static const String emergencySensitive = 'EMERGENCY_SENSITIVE';
  static const String adminSecuritySensitive = 'ADMIN_SECURITY_SENSITIVE';

  static const Set<String> values = <String>{
    normal,
    identitySensitive,
    paymentSensitive,
    healthSensitive,
    emergencySensitive,
    adminSecuritySensitive,
  };
}

class AgentProviderPrivacyProjectionStatus {
  AgentProviderPrivacyProjectionStatus._();

  static const String eligibleForProviderRouting =
      'ELIGIBLE_FOR_PROVIDER_ROUTING';

  static const String blockedInvalidRequest = 'BLOCKED_INVALID_REQUEST';

  static const String blockedMinimumDataPolicy = 'BLOCKED_MINIMUM_DATA_POLICY';

  static const String blockedRestrictedData = 'BLOCKED_RESTRICTED_DATA';

  static const String blockedSensitiveExternalProvider =
      'BLOCKED_SENSITIVE_EXTERNAL_PROVIDER';

  static const String blockedBoundaryMismatch = 'BLOCKED_BOUNDARY_MISMATCH';

  static const Set<String> values = <String>{
    eligibleForProviderRouting,
    blockedInvalidRequest,
    blockedMinimumDataPolicy,
    blockedRestrictedData,
    blockedSensitiveExternalProvider,
    blockedBoundaryMismatch,
  };
}

class AgentProviderPrivacyProjectionLimits {
  AgentProviderPrivacyProjectionLimits._();

  static const int idMax = 200;
  static const int maxReferenceIds = 8;
  static const int maxRestrictedDataFlags = 14;
  static const int maxReasonCodes = 16;
}
