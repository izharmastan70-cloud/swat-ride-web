import crypto from 'node:crypto';

export function verifySocialWebhook({ rawBody, signature, secret } = {}) {
  if (!rawBody || !signature || !secret) return false;
  const expected = `sha256=${crypto.createHmac('sha256', secret).update(rawBody).digest('hex')}`;
  const received = String(signature);
  return received.length === expected.length && crypto.timingSafeEqual(Buffer.from(received), Buffer.from(expected));
}