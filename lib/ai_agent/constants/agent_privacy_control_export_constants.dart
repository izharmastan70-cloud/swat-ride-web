class AgentPrivacyControlRole {
  AgentPrivacyControlRole._();

  static const String user = 'USER';
  static const String owner = 'OWNER';
  static const String superAdmin = 'SUPER_ADMIN';

  static const Set<String> values = <String>{user, owner, superAdmin};
}

class AgentPrivacyExportScope {
  AgentPrivacyExportScope._();

  static const String ownData = 'OWN_DATA';
  static const String authorizedScopedData = 'AUTHORIZED_SCOPED_DATA';

  static const Set<String> values = <String>{ownData, authorizedScopedData};
}

class AgentPrivacyExportFormat {
  AgentPrivacyExportFormat._();

  static const String json = 'JSON';
  static const String csv = 'CSV';
  static const String zipPackage = 'ZIP_PACKAGE';

  static const Set<String> values = <String>{json, csv, zipPackage};
}

class AgentPrivacyExportStatus {
  AgentPrivacyExportStatus._();

  static const String eligibleForSafeExportPackage =
      'ELIGIBLE_FOR_SAFE_EXPORT_PACKAGE';

  static const String blockedRoleScope = 'BLOCKED_ROLE_SCOPE';
  static const String blockedUnscopedData = 'BLOCKED_UNSCOPED_DATA';
  static const String blockedRestrictedCritical = 'BLOCKED_RESTRICTED_CRITICAL';
  static const String blockedProtectedEvidence = 'BLOCKED_PROTECTED_EVIDENCE';
  static const String blockedStrictDomain = 'BLOCKED_STRICT_DOMAIN';
  static const String blockedRedaction = 'BLOCKED_REDACTION';
  static const String blockedInvalidInput = 'BLOCKED_INVALID_INPUT';

  static const Set<String> values = <String>{
    eligibleForSafeExportPackage,
    blockedRoleScope,
    blockedUnscopedData,
    blockedRestrictedCritical,
    blockedProtectedEvidence,
    blockedStrictDomain,
    blockedRedaction,
    blockedInvalidInput,
  };
}

class AgentPrivacyControlSettingsLimits {
  AgentPrivacyControlSettingsLimits._();

  static const int opaqueIdMaxLength = 220;
  static const int maximumExportKinds = 12;
  static const Duration maximumFutureClockSkew = Duration(minutes: 5);
}
