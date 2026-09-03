import assert from 'node:assert/strict';
import test from 'node:test';
import { createSocialContentDraft } from '../src/social/social_content_agent_service.js';
import { verifySocialWebhook } from '../src/social/social_webhook_verifier.js';
import crypto from 'node:crypto';

test('content agent creates a Swat Ride tourism draft without publishing authority', () => {
  const draft = createSocialContentDraft({ platform: 'instagram', topic: 'Tour the Swat Valley', language: 'en' });
  assert.equal(draft.status, 'draft');
  assert.match(draft.caption, /safe, affordable/i);
  assert.equal(draft.script.length, 4);
});

test('social webhook HMAC verification accepts only the exact signature', () => {
  const rawBody = '{"event":"published"}';
  const secret = 'test-secret';
  const signature = `sha256=${crypto.createHmac('sha256', secret).update(rawBody).digest('hex')}`;
  assert.equal(verifySocialWebhook({ rawBody, signature, secret }), true);
  assert.equal(verifySocialWebhook({ rawBody, signature: 'sha256=bad', secret }), false);
});