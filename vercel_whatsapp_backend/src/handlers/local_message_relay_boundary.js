'use strict';

const { isAuthenticatedRelayRequest } =
    require('../security/relay_request_authenticator');

const MAX_MESSAGE_LENGTH = 4096;

function createLocalMessageRelayHandler({
  relaySecret = process.env.LOCAL_MESSAGE_RELAY_SECRET,
  isRelayEnabled,
  sendMessage,
  allowedSourceIps = [],
} = {}) {
  if (typeof isRelayEnabled !== 'function' || typeof sendMessage !== 'function') {
    throw new Error('Relay enablement check and sender are required.');
  }

  return async function handleRelayRequest({ headers = {}, sourceIp = '', body } = {}) {
    const providedSecret = headers['x-relay-secret'] || headers['X-Relay-Secret'];
    if (!isAuthenticatedRelayRequest({ providedSecret, expectedSecret: relaySecret })) {
      return Object.freeze({ ok: false, status: 401, code: 'RELAY_UNAUTHORIZED' });
    }
    if (allowedSourceIps.length > 0 && !allowedSourceIps.includes(sourceIp)) {
      return Object.freeze({ ok: false, status: 403, code: 'RELAY_SOURCE_DENIED' });
    }
    if (await isRelayEnabled() !== true) {
      return Object.freeze({ ok: false, status: 503, code: 'RELAY_PAUSED_BY_SUPER_ADMIN' });
    }
    if (!body || typeof body !== 'object' || typeof body.callSessionId !== 'string' ||
        body.callSessionId.trim().length === 0 || typeof body.recipientPhone !== 'string' ||
        typeof body.messageBody !== 'string' || body.messageBody.trim().length === 0 ||
        body.messageBody.length > MAX_MESSAGE_LENGTH) {
      return Object.freeze({ ok: false, status: 400, code: 'RELAY_REQUEST_INVALID' });
    }

    const result = await sendMessage({
      callSessionId: body.callSessionId.trim(),
      recipientPhone: body.recipientPhone,
      messageBody: body.messageBody.trim(),
      channel: body.channel === 'sms' ? 'sms' : 'whatsapp',
    });
    return Object.freeze({ ok: result?.ok === true, status: result?.ok === true ? 202 : 502,
      code: result?.ok === true ? 'RELAY_ACCEPTED' : 'RELAY_DELIVERY_FAILED' });
  };
}

module.exports = { createLocalMessageRelayHandler };