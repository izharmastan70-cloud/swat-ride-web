import { createTikTokAuthorizationRequest } from '../../../src/social/tiktok_login_oauth.js';

export default function handler(request, response) {
  if (request.method !== 'GET') return response.status(405).json({ ok: false, code: 'METHOD_NOT_ALLOWED' });
  try {
    const authorization = createTikTokAuthorizationRequest();
    response.setHeader('Set-Cookie', `tiktok_oauth_state=${authorization.signedState}; HttpOnly; Secure; SameSite=Lax; Path=/api/social/tiktok; Max-Age=600`);
    return response.redirect(302, authorization.url);
  } catch (error) {
    console.error('TikTok OAuth authorization start failed', { code: error.message });
    return response.status(500).json({ ok: false, code: error.message });
  }
}