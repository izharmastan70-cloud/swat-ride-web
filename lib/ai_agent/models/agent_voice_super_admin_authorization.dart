enum AgentVoiceSuperAdminPrincipalType { owner, superAdmin }

enum AgentVoiceSuperAdminVerificationLevel { none, linkedAccount, strongReauth }

/// Exact authenticated application-session binding for Voice Super Admin.
///
/// Voice/audio/text content is never used as identity or authority.
class AgentVoiceSuperAdminSessionBinding {
  const AgentVoiceSuperAdminSessionBinding({
    required this.principalType,
    required this.principalUid,
    required this.deviceBindingId,
    required this.sessionId,
    required this.verificationLevel,
    required this.verifiedAt,
    required this.expiresAt,
  });

  final AgentVoiceSuperAdminPrincipalType principalType;
  final String principalUid;

  /// Provider-neutral app/device binding reference.
  /// Must not contain password, OTP, PIN, access token or other secret.
  final String deviceBindingId;

  /// Server/application-authenticated session reference.
  final String sessionId;

  final AgentVoiceSuperAdminVerificationLevel verificationLevel;
  final DateTime verifiedAt;
  final DateTime expiresAt;

  bool get hasRequiredIdentifiers =>
      principalUid.trim().isNotEmpty &&
      deviceBindingId.trim().isNotEmpty &&
      sessionId.trim().isNotEmpty;

  bool get hasLinkedAccountVerification =>
      verificationLevel ==
          AgentVoiceSuperAdminVerificationLevel.linkedAccount ||
      verificationLevel == AgentVoiceSuperAdminVerificationLevel.strongReauth;

  bool get hasStrongReauth =>
      verificationLevel == AgentVoiceSuperAdminVerificationLevel.strongReauth;

  bool isActiveAt(DateTime now) =>
      hasRequiredIdentifiers &&
      !verifiedAt.isAfter(now) &&
      !expiresAt.isBefore(now) &&
      expiresAt.isAfter(verifiedAt);

  bool matchesExactSession({
    required String expectedDeviceBindingId,
    required String expectedSessionId,
  }) =>
      deviceBindingId == expectedDeviceBindingId &&
      sessionId == expectedSessionId;

  bool canReadOwnerData({
    required DateTime now,
    required String expectedDeviceBindingId,
    required String expectedSessionId,
  }) =>
      isActiveAt(now) &&
      hasLinkedAccountVerification &&
      matchesExactSession(
        expectedDeviceBindingId: expectedDeviceBindingId,
        expectedSessionId: expectedSessionId,
      );

  bool get voiceContentGrantsAuthority => false;
  bool get textContentGrantsAuthority => false;
  bool get biometricOrVoiceprintAloneGrantsAuthority => false;
}

class AgentVoiceSuperAdminAuthorizationRequest {
  const AgentVoiceSuperAdminAuthorizationRequest({
    required this.actionId,
    required this.actorId,
    required this.expectedDeviceBindingId,
    required this.expectedSessionId,
  });

  final String actionId;
  final String actorId;
  final String expectedDeviceBindingId;
  final String expectedSessionId;

  bool get isStructurallyValid =>
      actionId.trim().isNotEmpty &&
      actorId.trim().isNotEmpty &&
      expectedDeviceBindingId.trim().isNotEmpty &&
      expectedSessionId.trim().isNotEmpty;
}
