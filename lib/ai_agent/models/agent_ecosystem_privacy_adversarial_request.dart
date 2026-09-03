import '../constants/agent_ecosystem_privacy_adversarial_constants.dart';

class AgentEcosystemPrivacyAdversarialRequest {
  AgentEcosystemPrivacyAdversarialRequest({
    required this.attackType,
    required this.domain,
    required this.promptInjectionDetected,
    required this.secretExtractionRequested,
    required this.trustedSessionVerified,
    required this.sessionFresh,
    required this.sessionSubjectMatch,
    required this.crossCustomerRequested,
    required this.requestedDataScopeAllowed,
    required this.minimumNecessaryVerified,
    required this.redactionVerified,
    required this.strictSensitiveDomainAuthorized,
    required this.providerHandoffRequested,
    required this.providerPrivacyProjectionVerified,
  }) {
    validate();
  }

  final String attackType;
  final String domain;

  final bool promptInjectionDetected;
  final bool secretExtractionRequested;

  final bool trustedSessionVerified;
  final bool sessionFresh;
  final bool sessionSubjectMatch;

  final bool crossCustomerRequested;
  final bool requestedDataScopeAllowed;
  final bool minimumNecessaryVerified;
  final bool redactionVerified;

  final bool strictSensitiveDomainAuthorized;

  final bool providerHandoffRequested;
  final bool providerPrivacyProjectionVerified;

  bool get sessionClaimAloneGrantsAuthority => false;
  bool get userTextGrantsAuthority => false;

  void validate() {
    if (!AgentEcosystemPrivacyAttackType.values.contains(attackType) ||
        !AgentEcosystemPrivacyDomain.values.contains(domain)) {
      throw const FormatException(
        'Invalid ecosystem privacy adversarial request.',
      );
    }
  }
}
