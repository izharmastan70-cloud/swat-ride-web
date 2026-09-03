'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  createLocalMessageRelayHandler,
} = require('../src/handlers/local_message_relay_boundary');

const secret = 'relay-secret-with-at-least-thirty-two-characters';

function createHandler({ enabled = true, sender } = {}) {
  return createLocalMessageRelayHandler({
    relaySecret: secret,
    allowedSourceIps: ['10.0.0.4'],
    isRelayEnabled: async () => enabled,
    sendMessage: sender || (async () => ({ ok: true })),
  });
}

function validRequest() {
  return {
    headers: { 'x-relay-secret': secret },
    sourceIp: '10.0.0.4',
    body: {
      callSessionId: 'call-session-a',
      recipientPhone: '+923001234567',
      messageBody: 'Your driver is on the way.',
      channel: 'whatsapp',
    },
  };
}

test('relay rejects missing or invalid backend secret before delivery', async () => {
  let delivered = false;
  const handler = createHandler({ sender: async () => {
    delivered = true;
    return { ok: true };
  } });

  const result = await handler({ ...validRequest(), headers: {} });
  assert.equal(result.code, 'RELAY_UNAUTHORIZED');
  assert.equal(delivered, false);
});

test('relay rejects a source outside the firewall allowlist', async () => {
  const result = await createHandler()({
    ...validRequest(),
    sourceIp: '198.51.100.10',
  });
  assert.equal(result.code, 'RELAY_SOURCE_DENIED');
});

test('relay pauses delivery when Super Admin has disabled messaging', async () => {
  let delivered = false;
  const handler = createHandler({ enabled: false, sender: async () => {
    delivered = true;
    return { ok: true };
  } });

  const result = await handler(validRequest());
  assert.equal(result.code, 'RELAY_PAUSED_BY_SUPER_ADMIN');
  assert.equal(delivered, false);
});

test('relay forwards a valid session-bound request once', async () => {
  let payload;
  const handler = createHandler({ sender: async (request) => {
    payload = request;
    return { ok: true };
  } });

  const result = await handler(validRequest());
  assert.equal(result.code, 'RELAY_ACCEPTED');
  assert.equal(payload.callSessionId, 'call-session-a');
  assert.equal(payload.recipientPhone, '+923001234567');
});