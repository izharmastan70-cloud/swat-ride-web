import crypto from 'node:crypto';

const authorizationEndpoint = 'https://www.tiktok.com/v2/auth/authorize/';
const tokenEndpoint = 'https://open.tiktokapis.com/v2/oauth/token/';

function required(value, name) {
  if (!value) throw new Error(`TIKTOK_OAUTH_${name}_MISSING`);
  return value;
}

function signature(value, secret) {
  return crypto.createHmac('sha256', secret).update(value).digest('base64url');
}

export function createTikTokAuthorizationRequest(environment = process.env) {
  const clientKey = required(environment.TIKTOK_CLIENT_KEY, 'CLIENT_KEY');
  const redirectUri = required(environment.TIKTOK_OAUTH_REDIRECT_URI, 'REDIRECT_URI');
  const stateSecret = required(environment.TIKTOK_OAUTH_STATE_SECRET, 'STATE_SECRET');
  const state = crypto.randomBytes(32).toString('base64url');
  const url = new URL(authorizationEndpoint);
  url.search = new URLSearchParams({
    client_key: clientKey,
    response_type: 'code',
    scope: 'user.info.basic,video.publish',
    redirect_uri: redirectUri,
    state,
  }).toString();
  return { state, signedState: `${state}.${signature(state, stateSecret)}`, url: url.toString() };
}

export function verifyTikTokAuthorizationState({ state, signedState, stateSecret } = {}) {
  const [cookieState, cookieSignature, extra] = String(signedState || '').split('.');
  if (!state || !cookieState || !cookieSignature || extra) return false;
  const expected = signature(cookieState, stateSecret || '');
  const stateBuffer = Buffer.from(String(state));
  const cookieStateBuffer = Buffer.from(cookieState);
  const signatureBuffer = Buffer.from(cookieSignature);
  const expectedBuffer = Buffer.from(expected);
  return stateBuffer.length === cookieStateBuffer.length
    && signatureBuffer.length === expectedBuffer.length
    && crypto.timingSafeEqual(stateBuffer, cookieStateBuffer)
    && crypto.timingSafeEqual(signatureBuffer, expectedBuffer);
}

export async function exchangeTikTokAuthorizationCode({ code, environment = process.env, fetchFn = fetch } = {}) {
  const clientKey = required(environment.TIKTOK_CLIENT_KEY, 'CLIENT_KEY');
  const clientSecret = required(environment.TIKTOK_CLIENT_SECRET, 'CLIENT_SECRET');
  const redirectUri = required(environment.TIKTOK_OAUTH_REDIRECT_URI, 'REDIRECT_URI');
  if (!code) throw new Error('TIKTOK_OAUTH_CODE_MISSING');
  const response = await fetchFn(tokenEndpoint, {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({ client_key: clientKey, client_secret: clientSecret, code, grant_type: 'authorization_code', redirect_uri: redirectUri }).toString(),
  });
  const body = await response.json().catch(() => ({}));
  if (!response.ok || body.error || !body.access_token) throw new Error('TIKTOK_OAUTH_TOKEN_EXCHANGE_REJECTED');
  return { openId: body.open_id, expiresIn: body.expires_in };
}