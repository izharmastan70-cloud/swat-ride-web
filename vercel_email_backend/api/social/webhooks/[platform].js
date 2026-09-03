import { verifySocialWebhook } from '../../../src/social/social_webhook_verifier.js';
import { routeError, socialRuntime } from '../../../src/social/social_route_runtime.js';

const supportedPlatforms = new Set(['facebook', 'instagram', 'tiktok', 'youtube']);

export const config = {
  api: { bodyParser: false },
};

async function readRawBody(request) {
  if (Buffer.isBuffer(request.body)) return request.body.toString('utf8');
  if (typeof request.body === 'string') return request.body;
  const chunks = [];
  for await (const chunk of request) chunks.push(Buffer.from(chunk));
  return Buffer.concat(chunks).toString('utf8');
}

export default async function handler(request, response) {
  const platform = String(request.query.platform || '').toLowerCase();
  if (request.method === 'GET' && (platform === 'facebook' || platform === 'instagram')) {
    if (request.query['hub.verify_token'] !== process.env.META_WEBHOOK_VERIFY_TOKEN) return response.status(403).send('Forbidden');
    return response.status(200).send(request.query['hub.challenge'] || '');
  }
  if (request.method !== 'POST') return response.status(405).json({ ok: false, code: 'METHOD_NOT_ALLOWED' });
  try {
    if (!supportedPlatforms.has(platform)) throw new Error('SOCIAL_PLATFORM_UNSUPPORTED');
    const rawBody = await readRawBody(request);
    const payload = rawBody ? JSON.parse(rawBody) : {};
    const signature = request.headers['x-hub-signature-256'] || request.headers['x-tiktok-signature'] || request.headers['x-youtube-signature'];
    const secret = process.env[`${platform.toUpperCase()}_WEBHOOK_SECRET`];
    if (!verifySocialWebhook({ rawBody, signature, secret })) return response.status(403).json({ ok: false, code: 'WEBHOOK_SIGNATURE_INVALID' });
    const runtime = socialRuntime();
    await runtime.firestore.collection('social_webhook_events').add({ platform, payload, receivedAt: new Date() });
    return response.status(202).json({ ok: true, code: 'WEBHOOK_ACCEPTED' });
  } catch (error) { return routeError(response, error); }
}