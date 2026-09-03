import '../constants/agent_ecosystem_privacy_adversarial_constants.dart';
import '../models/agent_ecosystem_privacy_adversarial_decision.dart';
import '../models/agent_ecosystem_privacy_adversarial_request.dart';

class AgentEcosystemPrivacyAdversarialPolicy {
  const AgentEcosystemPrivacyAdversarialPolicy();

  AgentEcosystemPrivacyAdversarialDecision evaluate(
    AgentEcosystemPrivacyAdversarialRequest request,
  ) {
    request.validate();

    if (request.promptInjectionDetected ||
        request.attackType == AgentEcosystemPrivacyAttackType.promptInjection) {
      return _blocked(
        status: AgentEcosystemPrivacyDecisionStatus.blockPromptInjection,
        reasonCode:
            'untrusted_instruction_cannot_override_system_security_or_authority',
      );
    }

    if (request.secretExtractionRequested ||
        request.attackType ==
            AgentEcosystemPrivacyAttackType.secretExtraction) {
      return _blocked(
        status: AgentEcosystemPrivacyDecisionStatus.blockSecretExtraction,
        reasonCode: 'secret_token_credential_extraction_forbidden',
      );
    }

    if (!request.trustedSessionVerified ||
        request.attackType == AgentEcosystemPrivacyAttackType.stolenSession &&
            !request.trustedSessionVerified) {
      return AgentEcosystemPrivacyAdversarialDecision(
        status: AgentEcosystemPrivacyDecisionStatus.blockUntrustedSession,
        routeTo: AgentEcosystemPrivacyRoute.trustedSessionGate,
        reasonCode: 'stolen_replayed_or_unverified_customer_session_blocked',
      );
    }

    if (!request.sessionFresh) {
      return AgentEcosystemPrivacyAdversarialDecision(
        status: AgentEcosystemPrivacyDecisionStatus.blockStaleSession,
        routeTo: AgentEcosystemPrivacyRoute.trustedSessionGate,
        reasonCode: 'stale_or_expired_session_blocked',
      );
    }

    if (!request.sessionSubjectMatch) {
      return AgentEcosystemPrivacyAdversarialDecision(
        status: AgentEcosystemPrivacyDecisionStatus.blockSessionSubjectMismatch,
        routeTo: AgentEcosystemPrivacyRoute.trustedSessionGate,
        reasonCode: 'session_subject_does_not_match_requested_subject',
      );
    }

    if (request.crossCustomerRequested ||
        request.attackType ==
            AgentEcosystemPrivacyAttackType.crossCustomerData) {
      return _blocked(
        status: AgentEcosystemPrivacyDecisionStatus.blockCrossCustomer,
        reasonCode: 'cross_customer_or_cross_subject_data_access_forbidden',
      );
    }

    if (!request.requestedDataScopeAllowed) {
      return AgentEcosystemPrivacyAdversarialDecision(
        status: AgentEcosystemPrivacyDecisionStatus.blockScope,
        routeTo: AgentEcosystemPrivacyRoute.privacyScopeGate,
        reasonCode: 'requested_data_outside_authorized_scope',
      );
    }

    if (!request.minimumNecessaryVerified) {
      return AgentEcosystemPrivacyAdversarialDecision(
        status: AgentEcosystemPrivacyDecisionStatus.blockMinimumNecessary,
        routeTo: AgentEcosystemPrivacyRoute.privacyScopeGate,
        reasonCode: 'minimum_necessary_projection_required',
      );
    }

    if (!request.redactionVerified) {
      return AgentEcosystemPrivacyAdversarialDecision(
        status: AgentEcosystemPrivacyDecisionStatus.blockRedaction,
        routeTo: AgentEcosystemPrivacyRoute.privacyScopeGate,
        reasonCode: 'sensitive_data_redaction_required',
      );
    }

    final strictDomain =
        request.domain == AgentEcosystemPrivacyDomain.student ||
        request.domain == AgentEcosystemPrivacyDomain.safety ||
        request.domain == AgentEcosystemPrivacyDomain.financial;

    if (strictDomain && !request.strictSensitiveDomainAuthorized) {
      return AgentEcosystemPrivacyAdversarialDecision(
        status: AgentEcosystemPrivacyDecisionStatus.blockSensitiveDomain,
        routeTo: AgentEcosystemPrivacyRoute.sensitiveDomainGate,
        reasonCode: 'strict_student_safety_financial_authorization_required',
      );
    }

    if (request.providerHandoffRequested &&
        !request.providerPrivacyProjectionVerified) {
      return AgentEcosystemPrivacyAdversarialDecision(
        status:
            AgentEcosystemPrivacyDecisionStatus.blockProviderPrivacyProjection,
        routeTo: AgentEcosystemPrivacyRoute.providerPrivacyGate,
        reasonCode:
            'provider_minimum_necessary_redacted_projection_not_verified',
      );
    }

    return AgentEcosystemPrivacyAdversarialDecision(
      status: AgentEcosystemPrivacyDecisionStatus.safeProjectionEligible,
      routeTo: AgentEcosystemPrivacyRoute.safeProjection,
      reasonCode: 'privacy_checks_passed_safe_projection_eligibility_only',
    );
  }

  AgentEcosystemPrivacyAdversarialDecision _blocked({
    required String status,
    required String reasonCode,
  }) {
    return AgentEcosystemPrivacyAdversarialDecision(
      status: status,
      routeTo: AgentEcosystemPrivacyRoute.blocked,
      reasonCode: reasonCode,
    );
  }

  bool get policyOnly => true;
  bool get readsSecretStore => false;
  bool get validatesSessionAgainstBackend => false;
  bool get grantsIdentityAuthority => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get overridesRuntimeGate => false;
  bool get readsFirestore => false;
  bool get writesFirestore => false;
  bool get callsProvider => false;
  bool get sendsPrivateData => false;
  bool get executesBusinessAction => false;
  bool get activatesProduction => false;
}
