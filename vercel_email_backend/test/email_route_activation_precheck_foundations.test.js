import assert from 'node:assert/strict';
import test from 'node:test';

import {
  EMAIL_DRAFT_BINDING_ALGORITHM,
  validateExactEmailApprovalActionScope,
} from '../src/security/email_approval_action_scope_validator.js';

import {
  FirebaseAdminEmailMasterToggleRechecker,
} from '../src/security/firebase_admin_email_master_toggle_rechecker.js';

import {
  EMAIL_SENDER_SETUP_POLICY,
  EMAIL_SENDER_SETUP_STATUS,
  classifyEmailSenderSetup,
  mayRequestRealSenderSetup,
} from '../src/config/email_sender_setup_workflow_contract.js';

class FakeSnapshot {
  constructor(data) {
    this._data = data;
    this.exists = data !== undefined;
  }

  data() {
    return this._data;
  }
}

class FakeFirestore {
  constructor(data) {
    this.data = data;
    this.requestedCollection = '';
    this.requestedDocument = '';
  }

  collection(name) {
    this.requestedCollection = name;

    return {
      doc: (id) => {
        this.requestedDocument = id;

        return {
          get: async () =>
            new FakeSnapshot(this.data),
        };
      },
    };
  }
}

function validScope() {
  return {
    authorizationRequestId: 'authorization_1',
    draftId: 'draft_1',
    binding: {
      algorithm: EMAIL_DRAFT_BINDING_ALGORITHM,
      fingerprint: 'fingerprint_1',
      draftId: 'draft_1',
      exactDraftMatchRequired: true,
    },
    exactDraftMatchRequired: true,
    oneActionOnly: true,
    oneTimeConsumptionRequired: true,
  };
}

function validate(scope) {
  return validateExactEmailApprovalActionScope({
    scope,
    authorizationRequestId: 'authorization_1',
    draftId: 'draft_1',
    bindingFingerprint: 'fingerprint_1',
  });
}

test('exact Email approval actionScope accepts the Flutter six-key contract', () => {
  const result = validate(validScope());

  assert.equal(result.ok, true);
  assert.equal(
      result.code,
      'EMAIL_APPROVAL_SCOPE_EXACT_MATCH');
});

test('approval actionScope rejects any extra field including message content', () => {
  const scope = {
    ...validScope(),
    subject: 'must-not-enter-approval-scope',
  };

  const result = validate(scope);

  assert.equal(result.ok, false);
  assert.equal(
      result.code,
      'EMAIL_APPROVAL_SCOPE_KEYS_MISMATCH');
});

test('approval binding rejects extra keys and wrong binding algorithm', () => {
  const extraBinding = validScope();

  extraBinding.binding = {
    ...extraBinding.binding,
    providerSecret: 'must-not-exist',
  };

  assert.equal(
      validate(extraBinding).code,
      'EMAIL_APPROVAL_BINDING_KEYS_MISMATCH');

  const wrongAlgorithm = validScope();

  wrongAlgorithm.binding = {
    ...wrongAlgorithm.binding,
    algorithm: 'WRONG_ALGORITHM',
  };

  assert.equal(
      validate(wrongAlgorithm).code,
      'EMAIL_APPROVAL_SCOPE_VALUE_MISMATCH');
});

test('approval actionScope requires all three boolean safety invariants', () => {
  for (const field of [
    'exactDraftMatchRequired',
    'oneActionOnly',
    'oneTimeConsumptionRequired',
  ]) {
    const scope = validScope();
    scope[field] = false;

    assert.equal(
        validate(scope).ok,
        false,
        field);
  }

  const bindingScope = validScope();
  bindingScope.binding.exactDraftMatchRequired = false;

  assert.equal(validate(bindingScope).ok, false);
});

test('Email master toggle rechecker reads exact agent_settings/master path', async () => {
  const firestore =
      new FakeFirestore({
        emailAgentEnabled: true,
      });

  const rechecker =
      new FirebaseAdminEmailMasterToggleRechecker({
        firestore,
      });

  const result =
      await rechecker.recheckEmailAgentEnabled();

  assert.equal(result.ok, true);
  assert.equal(result.enabled, true);
  assert.equal(
      firestore.requestedCollection,
      'agent_settings');
  assert.equal(
      firestore.requestedDocument,
      'master');
});

test('missing or OFF Email master setting fails closed', async () => {
  const missing =
      new FirebaseAdminEmailMasterToggleRechecker({
        firestore: new FakeFirestore(undefined),
      });

  const missingResult =
      await missing.recheckEmailAgentEnabled();

  assert.equal(missingResult.ok, false);
  assert.equal(missingResult.enabled, false);

  const off =
      new FirebaseAdminEmailMasterToggleRechecker({
        firestore: new FakeFirestore({
          emailAgentEnabled: false,
        }),
      });

  const offResult =
      await off.recheckEmailAgentEnabled();

  assert.equal(offResult.ok, false);
  assert.equal(offResult.enabled, false);
  assert.equal(
      offResult.reason,
      'EMAIL_AGENT_MASTER_SWITCH_OFF');
});

test('sender setup remains server-only and needs no real sender during source tests', () => {
  assert.equal(
      EMAIL_SENDER_SETUP_POLICY.clientMayCreateVerifiedSender,
      false);
  assert.equal(
      EMAIL_SENDER_SETUP_POLICY.clientMayUpdateVerifiedSender,
      false);
  assert.equal(
      EMAIL_SENDER_SETUP_POLICY.verificationServerOnly,
      true);
  assert.equal(
      EMAIL_SENDER_SETUP_POLICY.sourceTestsRequireRealSender,
      false);
  assert.equal(
      EMAIL_SENDER_SETUP_POLICY.sourceTestsRequireProviderSecret,
      false);
  assert.equal(
      EMAIL_SENDER_SETUP_POLICY.sourceTestsMaySendEmail,
      false);
  assert.equal(
      EMAIL_SENDER_SETUP_POLICY.liveSendMustRemainOffDuringSetup,
      true);
});

test('sender setup classification requires SERVER_PROVIDER_VERIFIED evidence', () => {
  assert.equal(
      classifyEmailSenderSetup(null),
      EMAIL_SENDER_SETUP_STATUS.notConfigured);

  assert.equal(
      classifyEmailSenderSetup({
        enabled: true,
        verifiedAt: {
          synthetic: true,
        },
        verificationSource: 'CLIENT_ASSERTED',
      }),
      EMAIL_SENDER_SETUP_STATUS.pendingProviderVerification);

  assert.equal(
      classifyEmailSenderSetup({
        enabled: false,
        verifiedAt: {
          synthetic: true,
        },
        verificationSource: 'SERVER_PROVIDER_VERIFIED',
      }),
      EMAIL_SENDER_SETUP_STATUS.verifiedDisabled);

  assert.equal(
      classifyEmailSenderSetup({
        enabled: true,
        verifiedAt: {
          synthetic: true,
        },
        verificationSource: 'SERVER_PROVIDER_VERIFIED',
      }),
      EMAIL_SENDER_SETUP_STATUS.verifiedEnabled);
});

test('real sender setup is not requested until server precheck foundations are ready and live send is OFF', () => {
  assert.equal(
      mayRequestRealSenderSetup({
        exactApprovalScopeValidatorReady: true,
        masterToggleRecheckerReady: true,
        firebaseAdminAdaptersReady: true,
        liveSendEnabled: false,
      }),
      true);

  assert.equal(
      mayRequestRealSenderSetup({
        exactApprovalScopeValidatorReady: true,
        masterToggleRecheckerReady: true,
        firebaseAdminAdaptersReady: true,
        liveSendEnabled: true,
      }),
      false);
});