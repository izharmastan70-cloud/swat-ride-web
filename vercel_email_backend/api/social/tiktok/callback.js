import { exchangeTikTokAuthorizationCode, verifyTikTokAuthorizationState } from '../../../src/social/tiktok_login_oauth.js';

function cookieValue(request, name) {
  const entry = String(request.headers.cookie || '').split(';').map((value) => value.trim()).find((value) => value.startsWith(`${name}=`));
  return entry ? entry.slice(name.length + 1) : '';
}

export default async function handler(request, response) {
  if (request.method !== 'GET') return response.status(405).json({ ok: false, code: 'METHOD_NOT_ALLOWED' });
  const state = String(request.query.state || '');
  const signedState = cookieValue(request, 'tiktok_oauth_state');
  if (!verifyTikTokAuthorizationState({ state, signedState, stateSecret: process.env.TIKTOK_OAUTH_STATE_SECRET })) {
    console.error('TikTok OAuth callback rejected invalid state');
    return response.status(400).json({ ok: false, code: 'TIKTOK_OAUTH_STATE_INVALID' });
  }
  try {
    const identity = await exchangeTikTokAuthorizationCode({ code: String(request.query.code || '') });
    console.info('TikTok OAuth authorization completed', { openId: identity.openId, expiresIn: identity.expiresIn });
    response.setHeader('Set-Cookie', 'tiktok_oauth_state=; HttpOnly; Secure; SameSite=Lax; Path=/api/social/tiktok; Max-Age=0');
    return response.redirect(302, process.env.TIKTOK_OAUTH_SUCCESS_URL || '/');
  } catch (error) {
    console.error('TikTok OAuth token exchange failed', { code: error.message });
    return response.status(502).json({ ok: false, code: error.message });
  }
}