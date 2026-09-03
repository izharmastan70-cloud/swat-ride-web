class AgentPrivacySensitivityTier {
  AgentPrivacySensitivityTier._();

  static const String internal = 'INTERNAL';
  static const String private = 'PRIVATE';
  static const String highlySensitive = 'HIGHLY_SENSITIVE';
  static const String restrictedCritical = 'RESTRICTED_CRITICAL';

  static const Set<String> values = <String>{
    internal,
    private,
    highlySensitive,
    restrictedCritical,
  };

  static int rank(String value) {
    switch (value) {
      case internal:
        return 1;
      case private:
        return 2;
      case highlySensitive:
        return 3;
      case restrictedCritical:
        return 4;
      default:
        return 999;
    }
  }
}

class AgentPrivacyDataKind {
  AgentPrivacyDataKind._();

  static const String operationalMetadata = 'OPERATIONAL_METADATA';
  static const String chatContent = 'CHAT_CONTENT';
  static const String callTranscript = 'CALL_TRANSCRIPT';
  static const String callRecording = 'CALL_RECORDING';
  static const String emailContent = 'EMAIL_CONTENT';
  static const String whatsappContent = 'WHATSAPP_CONTENT';

  static const String personalContact = 'PERSONAL_CONTACT';
  static const String preciseLocation = 'PRECISE_LOCATION';

  static const String studentData = 'STUDENT_DATA';
  static const String safetyEmergencyData = 'SAFETY_EMERGENCY_DATA';
  static const String financialData = 'FINANCIAL_DATA';

  static const String authSecret = 'AUTH_SECRET';
  static const String apiCredential = 'API_CREDENTIAL';
  static const String paymentCredential = 'PAYMENT_CREDENTIAL';

  static const String auditEvidence = 'AUDIT_EVIDENCE';
  static const String securityEvidence = 'SECURITY_EVIDENCE';
  static const String financeEvidence = 'FINANCE_EVIDENCE';

  static const Set<String> values = <String>{
    operationalMetadata,
    chatContent,
    callTranscript,
    callRecording,
    emailContent,
    whatsappContent,
    personalContact,
    preciseLocation,
    studentData,
    safetyEmergencyData,
    financialData,
    authSecret,
    apiCredential,
    paymentCredential,
    auditEvidence,
    securityEvidence,
    financeEvidence,
  };
}

class AgentPrivacyTrainingMode {
  AgentPrivacyTrainingMode._();

  static const String syntheticOnly = 'SYNTHETIC_ONLY';
  static const String redactedConsentRequired = 'REDACTED_CONSENT_REQUIRED';
  static const String ineligibleSensitive = 'INELIGIBLE_SENSITIVE';
  static const String ineligibleSecret = 'INELIGIBLE_SECRET';

  static const Set<String> values = <String>{
    syntheticOnly,
    redactedConsentRequired,
    ineligibleSensitive,
    ineligibleSecret,
  };
}

class AgentPrivacyAccessMode {
  AgentPrivacyAccessMode._();

  static const String minimumNecessary = 'MINIMUM_NECESSARY';
  static const String verifiedProjectionOnly = 'VERIFIED_PROJECTION_ONLY';
  static const String blockedRaw = 'BLOCKED_RAW';

  static const Set<String> values = <String>{
    minimumNecessary,
    verifiedProjectionOnly,
    blockedRaw,
  };
}

class AgentPrivacyChannel {
  AgentPrivacyChannel._();

  static const String chat = 'CHAT';
  static const String callTranscript = 'CALL_TRANSCRIPT';
  static const String callRecording = 'CALL_RECORDING';
  static const String email = 'EMAIL';
  static const String whatsappAi = 'WHATSAPP_AI';

  static const Set<String> values = <String>{
    chat,
    callTranscript,
    callRecording,
    email,
    whatsappAi,
  };
}

class AgentPrivacyRetentionMode {
  AgentPrivacyRetentionMode._();

  static const String ownerConfigurable = 'OWNER_CONFIGURABLE';
  static const String disabledByDefault = 'DISABLED_BY_DEFAULT';

  static const Set<String> values = <String>{
    ownerConfigurable,
    disabledByDefault,
  };
}
