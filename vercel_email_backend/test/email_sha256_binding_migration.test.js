import assert from 'node:assert/strict';
import test from 'node:test';

import {
  EMAIL_DRAFT_BINDING_ALGORITHM,
  validateExactEmailApprovalActionScope,
} from '../src/security/email_approval_action_scope_validator.js';

const authorizationRequestId =
    'auth_sha256_migration';

const draftId =
    'draft_sha256_migration';

const bindingFingerprint =
    'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';

function scopeWithAlgorithm(algorithm) {
  return {
    authorizationRequestId,
    draftId,
    binding: {
      algorithm,
      fingerprint:
          bindingFingerprint,
      draftId,
      exactDraftMatchRequired:
          true,
    },
    exactDraftMatchRequired:
        true,
    oneActionOnly:
        true,
    oneTimeConsumptionRequired:
        true,
  };
}

test('server approval validator locks SHA-256 canonical binding V2', () => {
  assert.equal(
      EMAIL_DRAFT_BINDING_ALGORITHM,
      'CANONICAL_JSON_SHA256_BASE64URL_V2');
});

test('server accepts exact SHA-256 V2 approval binding contract', () => {
  const result =
      validateExactEmailApprovalActionScope({
        scope:
            scopeWithAlgorithm(
                EMAIL_DRAFT_BINDING_ALGORITHM),
        authorizationRequestId,
        draftId,
        bindingFingerprint,
      });

  assert.equal(
      result.ok,
      true);

  assert.equal(
      result.code,
      'EMAIL_APPROVAL_SCOPE_EXACT_MATCH');
});

test('server explicitly rejects legacy reversible Base64 V1 binding', () => {
  const result =
      validateExactEmailApprovalActionScope({
        scope:
            scopeWithAlgorithm(
                'CANONICAL_JSON_BASE64URL_V1'),
        authorizationRequestId,
        draftId,
        bindingFingerprint,
      });

  assert.equal(
      result.ok,
      false);

  assert.equal(
      result.code,
      'EMAIL_APPROVAL_SCOPE_VALUE_MISMATCH');
});