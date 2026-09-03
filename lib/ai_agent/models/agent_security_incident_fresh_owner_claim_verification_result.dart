class AgentSecurityIncidentFreshOwnerClaimVerificationStatus {
  AgentSecurityIncidentFreshOwnerClaimVerificationStatus._();

  static const String verified = 'VERIFIED_FRESH_SUPER_ADMIN_CLAIM';
  static const String blocked = 'BLOCKED';
}

class AgentSecurityIncidentFreshOwnerAuthAgeBucket {
  AgentSecurityIncidentFreshOwnerAuthAgeBucket._();

  static const String fresh = 'FRESH_WITHIN_5_MINUTES';
  static const String stale = 'STALE_OVER_5_MINUTES';
  static const String futureSkew = 'FUTURE_AUTH_TIME';
  static const String unavailable = 'UNAVAILABLE';
}

class AgentSecurityIncidentFreshOwnerClaimVerificationResult {
  const AgentSecurityIncidentFreshOwnerClaimVerificationResult({
    required this.status,
    required this.reasonCode,
    required this.superAdminAccessVerified,
    required this.roleClaimVerified,
    required this.uidBindingVerified,
    required this.customClaimSourceVerified,
    required this.freshLoginVerified,
    required this.authAgeBucket,
    required this.boundedAuthAgeSeconds,
  });

  final String status;
  final String reasonCode;

  final bool superAdminAccessVerified;
  final bool roleClaimVerified;
  final bool uidBindingVerified;
  final bool customClaimSourceVerified;
  final bool freshLoginVerified;

  final String authAgeBucket;

  // 0..300 when fresh; 301 means "older than five minutes".
  // null means missing/future-skew/unavailable.
  final int? boundedAuthAgeSeconds;

  bool get verified =>
      status == AgentSecurityIncidentFreshOwnerClaimVerificationStatus.verified;

  bool get containsRawIdToken => false;
  bool get containsUid => false;
  bool get containsEmail => false;
  bool get containsPhone => false;
  bool get containsRawClaims => false;
  bool get persistsVerification => false;
  bool get writesFirestore => false;
  bool get mutatesAuthClaims => false;
  bool get attachesRuntime => false;
  bool get armsRepository => false;
  bool get createsIncident => false;
  bool get createsIdempotencyReceipt => false;
  bool get changesRolloutStage => false;
  bool get changesAgentMode => false;
  bool get changesEmergencyStop => false;
  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;
}
