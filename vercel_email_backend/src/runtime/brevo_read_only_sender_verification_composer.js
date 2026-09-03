import {
  prepareBrevoProviderSecretFromEnvironment,
} from '../config/brevo_provider_sensitive_environment.js';

import {
  BrevoSenderStatusReadOnlyAdapter,
} from '../providers/brevo_sender_status_read_only_adapter.js';

import {
  evaluateBrevoSenderVerificationSnapshot,
} from '../security/brevo_sender_verification_evidence_evaluator.js';

function disabledResult(code) {
  return Object.freeze({
    ok:
        false,
    verificationAttempted:
        false,
    trustedEvidenceEligible:
        false,
    evidence:
        null,
    providerWriteAllowed:
        false,
    emailSendAllowed:
        false,
    liveSendAllowed:
        false,
    firestoreWriteAllowed:
        false,
    code,
  });
}

export class BrevoReadOnlySenderVerificationComposer {
  constructor({
    environment,
    fetchImpl,
    expectedSender,
    readOnlyVerificationEnabled = false,
  }) {
    this.environment =
        environment;

    this.fetchImpl =
        fetchImpl;

    this.expectedSender =
        expectedSender;

    this.readOnlyVerificationEnabled =
        readOnlyVerificationEnabled === true;
  }

  get providerWriteAllowed() {
    return false;
  }

  get emailSendAllowed() {
    return false;
  }

  get liveSendAllowed() {
    return false;
  }

  get firestoreWriteAllowed() {
    return false;
  }

  async verifyExpectedSender() {
    // FAIL CLOSED:
    // This isolated composition is disabled unless an explicit server-side
    // read-only verification gate is enabled by a later activation step.
    if (this.readOnlyVerificationEnabled !== true) {
      return disabledResult(
          'BREVO_READ_ONLY_VERIFICATION_DISABLED');
    }

    if (!this.expectedSender ||
        typeof this.expectedSender.senderIdentityId !== 'string' ||
        typeof this.expectedSender.fromAddress !== 'string' ||
        typeof this.expectedSender.displayName !== 'string') {
      return disabledResult(
          'BREVO_EXPECTED_SENDER_CONFIG_INVALID');
    }

    const secretPreparation =
        prepareBrevoProviderSecretFromEnvironment(
            this.environment);

    if (secretPreparation.ok !== true ||
        !secretPreparation.secret) {
      return Object.freeze({
        ...disabledResult(
            secretPreparation.code),
        verificationAttempted:
            false,
      });
    }

    const adapter =
        new BrevoSenderStatusReadOnlyAdapter({
          fetchImpl:
              this.fetchImpl,
          apiKeySecret:
              secretPreparation.secret,
          networkAllowed:
              true,
        });

    if (adapter.ready !== true) {
      return disabledResult(
          'BREVO_READ_ONLY_ADAPTER_NOT_READY');
    }

    const snapshot =
        await adapter.fetchSenderStatusSnapshot();

    if (snapshot.ok !== true) {
      return Object.freeze({
        ok:
            false,
        verificationAttempted:
            snapshot.networkAttempted === true,
        trustedEvidenceEligible:
            false,
        evidence:
            null,
        providerWriteAllowed:
            false,
        emailSendAllowed:
            false,
        liveSendAllowed:
            false,
        firestoreWriteAllowed:
            false,
        code:
            snapshot.code,
      });
    }

    const evaluation =
        evaluateBrevoSenderVerificationSnapshot({
          providerResponse:
              snapshot.providerResponse,
          expectedSender:
              this.expectedSender,
          sourceContext:
              snapshot.sourceContext,
          observedAt:
              new Date(),
        });

    return Object.freeze({
      ok:
          evaluation.ok === true,
      verificationAttempted:
          true,
      trustedEvidenceEligible:
          evaluation.eligibleForTrustedEvidence === true,
      evidence:
          evaluation.evidence ?? null,
      providerWriteAllowed:
          false,
      emailSendAllowed:
          false,
      liveSendAllowed:
          false,
      firestoreWriteAllowed:
          false,
      code:
          evaluation.code,
    });
  }
}