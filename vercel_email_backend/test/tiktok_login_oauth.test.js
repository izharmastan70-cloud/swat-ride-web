import assert from 'node:assert/strict';
import test from 'node:test';
import { createTikTokAuthorizationRequest, exchangeTikTokAuthorizationCode, verifyTikTokAuthorizationState } from '../src/social/tiktok_login_oauth.js';

const environment = {
  TIKTOK_CLIENT_KEY: 'client-key',
  TIKTOK_CLIENT_SECRET: 'client-secret',
  TIKTOK_OAUTH_REDIRECT_URI: 'https://api.example.com/api/social/tiktok/callback',
  TIKTOK_OAUTH_STATE_SECRET: 'state-secret',
};

test('TikTok OAuth authorization request targets the official endpoint with signed state', () => {
  const request = createTikTokAuthorizationRequest(environment);
  const url = new URL(request.url);
  assert.equal(url.origin + url.pathname, 'https://www.tiktok.com/v2/auth/authorize/');
  assert.equal(url.searchParams.get('client_key'), 'client-key');
  assert.equal(url.searchParams.get('redirect_uri'), environment.TIKTOK_OAUTH_REDIRECT_URI);
  assert.equal(url.searchParams.get('scope'), 'user.info.basic,video.publish');
  assert.equal(verifyTikTokAuthorizationState({ state: request.state, signedState: request.signedState, stateSecret: environment.TIKTOK_OAUTH_STATE_SECRET }), true);
  assert.equal(verifyTikTokAuthorizationState({ state: 'tampered', signedState: request.signedState, stateSecret: environment.TIKTOK_OAUTH_STATE_SECRET }), false);
});

test('TikTok OAuth exchanges codes without returning access tokens', async () => {
  const identity = await exchangeTikTokAuthorizationCode({
    code: 'authorization-code',
    environment,
    fetchFn: async (url, options) => {
      assert.equal(url, 'https://open.tiktokapis.com/v2/oauth/token/');
      assert.deepEqual(Object.fromEntries(new URLSearchParams(options.body)), {
        client_key: 'client-key', client_secret: 'client-secret', code: 'authorization-code', grant_type: 'authorization_code', redirect_uri: environment.TIKTOK_OAUTH_REDIRECT_URI,
      });
      return { ok: true, json: async () => ({ access_token: 'private-token', open_id: 'open-id', expires_in: 86400 }) };
    },
  });
  assert.deepEqual(identity, { openId: 'open-id', expiresIn: 86400 });
});