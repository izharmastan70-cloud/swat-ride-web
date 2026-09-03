class AgentPrivacyExportDeliveryStatus {
  AgentPrivacyExportDeliveryStatus._();

  static const String readyForTrustedAdapter = 'READY_FOR_TRUSTED_ADAPTER';

  static const String blockedNoUserGesture = 'BLOCKED_NO_USER_GESTURE';

  static const String blockedInvalidPackage = 'BLOCKED_INVALID_PACKAGE';

  static const String blockedInvalidInput = 'BLOCKED_INVALID_INPUT';

  static const Set<String> values = <String>{
    readyForTrustedAdapter,
    blockedNoUserGesture,
    blockedInvalidPackage,
    blockedInvalidInput,
  };
}

class AgentPrivacyExportDeliveryLimits {
  AgentPrivacyExportDeliveryLimits._();

  static const int maximumRecordsPerPackage = 5000;
  static const int maximumFieldCountPerRecord = 100;
  static const int maximumFieldKeyLength = 120;
  static const int maximumTextValueLength = 20000;
  static const int maximumPackageBytes = 25 * 1024 * 1024;
}

class AgentPrivacyExportMimeType {
  AgentPrivacyExportMimeType._();

  static const String json = 'application/json';
  static const String csv = 'text/csv';
  static const String zip = 'application/zip';
}
