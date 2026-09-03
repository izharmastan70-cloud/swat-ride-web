import '../constants/agent_omnichannel_constants.dart';

class AgentOmnichannelIdentityContext {
  const AgentOmnichannelIdentityContext({
    required this.subjectRef,
    required this.assurance,
    required this.verifiedByTrustedBoundary,
    required this.strongReauthSatisfied,
    required this.fromChannelClaimOnly,
  });

  /// Pseudonymous/stable subject reference. Raw phone/email/CNIC should not
  /// be required by the omnichannel contract.
  final String subjectRef;
  final String assurance;
  final bool verifiedByTrustedBoundary;
  final bool strongReauthSatisfied;

  /// True when identity is merely claimed in channel content/metadata and
  /// has not been proven by a trusted identity boundary.
  final bool fromChannelClaimOnly;

  bool get isTrustedIdentity =>
      verifiedByTrustedBoundary &&
      !fromChannelClaimOnly &&
      (assurance == AgentOmnichannelIdentityAssurance.verifiedSession ||
          assurance == AgentOmnichannelIdentityAssurance.strongReauth);

  bool get hasStrongReauth =>
      isTrustedIdentity &&
      assurance == AgentOmnichannelIdentityAssurance.strongReauth &&
      strongReauthSatisfied;

  bool get identityIsAuthority => false;
  bool get mayGrantPermission => false;
  bool get mayConsumeApproval => false;
  bool get mayWriteBusinessData => false;

  void validate() {
    if (subjectRef.trim().isEmpty ||
        !AgentOmnichannelIdentityAssurance.values.contains(assurance)) {
      throw const AgentOmnichannelContractException(
        'Omnichannel identity context is structurally invalid.',
      );
    }

    if (fromChannelClaimOnly && verifiedByTrustedBoundary) {
      throw const AgentOmnichannelContractException(
        'Channel-only identity claim cannot also be trusted identity proof.',
      );
    }

    if (assurance == AgentOmnichannelIdentityAssurance.verifiedSession &&
        !verifiedByTrustedBoundary) {
      throw const AgentOmnichannelContractException(
        'Verified-session assurance requires a trusted identity boundary.',
      );
    }

    if (assurance == AgentOmnichannelIdentityAssurance.strongReauth &&
        (!verifiedByTrustedBoundary || !strongReauthSatisfied)) {
      throw const AgentOmnichannelContractException(
        'Strong re-auth assurance requires trusted verification and completion.',
      );
    }

    if (strongReauthSatisfied && !verifiedByTrustedBoundary) {
      throw const AgentOmnichannelContractException(
        'Strong re-auth cannot be satisfied without trusted verification.',
      );
    }
  }

  Map<String, dynamic> toSafeMap() {
    validate();

    return Map<String, dynamic>.unmodifiable(<String, dynamic>{
      'assurance': assurance,
      'verifiedByTrustedBoundary': verifiedByTrustedBoundary,
      'strongReauthSatisfied': strongReauthSatisfied,
      'fromChannelClaimOnly': fromChannelClaimOnly,
      'isTrustedIdentity': isTrustedIdentity,
      'hasStrongReauth': hasStrongReauth,
      'identityIsAuthority': false,
      'mayGrantPermission': false,
      'mayConsumeApproval': false,
      'mayWriteBusinessData': false,
    });
  }
}

class AgentOmnichannelPrivacyContext {
  const AgentOmnichannelPrivacyContext({
    required this.sanitizedText,
    required this.containsRawSecrets,
    required this.containsPaymentCredentials,
    required this.containsAuthToken,
    required this.containsGovernmentId,
    required this.containsUnredactedContactDetails,
    required this.redactionApplied,
  });

  final String sanitizedText;
  final bool containsRawSecrets;
  final bool containsPaymentCredentials;
  final bool containsAuthToken;
  final bool containsGovernmentId;
  final bool containsUnredactedContactDetails;
  final bool redactionApplied;

  bool get safeForRouting =>
      sanitizedText.trim().isNotEmpty &&
      !containsRawSecrets &&
      !containsPaymentCredentials &&
      !containsAuthToken &&
      !containsGovernmentId &&
      !containsUnredactedContactDetails;

  bool get privacyDataIsAuthority => false;
  bool get mayGrantPermission => false;
  bool get mayWriteBusinessData => false;

  void validate() {
    if (sanitizedText.trim().isEmpty) {
      throw const AgentOmnichannelContractException(
        'Omnichannel privacy context requires sanitized text.',
      );
    }
  }

  Map<String, dynamic> toSafeMap() {
    validate();

    return Map<String, dynamic>.unmodifiable(<String, dynamic>{
      'safeForRouting': safeForRouting,
      'redactionApplied': redactionApplied,
      'containsRawSecrets': containsRawSecrets,
      'containsPaymentCredentials': containsPaymentCredentials,
      'containsAuthToken': containsAuthToken,
      'containsGovernmentId': containsGovernmentId,
      'containsUnredactedContactDetails': containsUnredactedContactDetails,
      'privacyDataIsAuthority': false,
      'mayGrantPermission': false,
      'mayWriteBusinessData': false,
    });
  }
}

class AgentOmnichannelContractException implements Exception {
  const AgentOmnichannelContractException(this.message);

  final String message;

  @override
  String toString() => 'AgentOmnichannelContractException: $message';
}
