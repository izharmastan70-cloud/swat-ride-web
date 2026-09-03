import assert from 'node:assert/strict';
import test from 'node:test';
import { createInstagramGraphAdapter } from '../src/social/instagram_graph_adapter.js';

test('Instagram adapter discovers the business account and publishes its media container', async () => {
  const calls = [];
  const logs = [];
  const responses = [
    { ok: true, status: 200, body: { instagram_business_account: { id: '17841400000000000' } } },
    { ok: true, status: 200, body: { id: '17900000000000000' } },
    { ok: true, status: 200, body: { id: '18000000000000000' } },
  ];
  const adapter = createInstagramGraphAdapter({
    pageId: '1358808947308489',
    accessToken: 'test-token',
    logger: { info: (message, details) => logs.push({ message, details }), error: () => {} },
    fetchFn: async (url, options) => {
      calls.push({ url: String(url), options });
      const response = responses.shift();
      return { ...response, json: async () => response.body };
    },
  });

  const result = await adapter.publish({ imageUrl: 'https://cdn.example.com/swat-ride.jpg', caption: 'Ride safely with Swat Ride.' });

  assert.deepEqual(result, { providerPostId: '18000000000000000' });
  assert.equal(calls[0].url, 'https://graph.facebook.com/v26.0/1358808947308489?fields=instagram_business_account&access_token=test-token');
  assert.equal(calls[0].options.method, 'GET');
  assert.equal(calls[1].url, 'https://graph.facebook.com/v26.0/17841400000000000/media');
  assert.deepEqual(Object.fromEntries(new URLSearchParams(calls[1].options.body)), { image_url: 'https://cdn.example.com/swat-ride.jpg', caption: 'Ride safely with Swat Ride.', access_token: 'test-token' });
  assert.equal(calls[2].url, 'https://graph.facebook.com/v26.0/17841400000000000/media_publish');
  assert.deepEqual(Object.fromEntries(new URLSearchParams(calls[2].options.body)), { creation_id: '17900000000000000', access_token: 'test-token' });
  assert.deepEqual(logs.at(-1), { message: 'Instagram Business post published', details: { instagramAccountId: '17841400000000000', providerPostId: '18000000000000000' } });
});

test('Instagram adapter logs account discovery failure without exposing the access token', async () => {
  const errors = [];
  const adapter = createInstagramGraphAdapter({
    pageId: '1358808947308489',
    accessToken: 'test-token',
    logger: { info: () => {}, error: (message, details) => errors.push({ message, details }) },
    fetchFn: async () => ({ ok: false, status: 400, json: async () => ({ error: { message: 'Page is not linked to an Instagram Business account.' } }) }),
  });

  await assert.rejects(() => adapter.publish({ imageUrl: 'https://cdn.example.com/swat-ride.jpg', caption: 'Ride safely with Swat Ride.' }), /INSTAGRAM_ACCOUNT_DISCOVERY_REJECTED/);
  assert.deepEqual(errors, [{ message: 'Instagram Business account discovery failed', details: { pageId: '1358808947308489', status: 400, error: 'Page is not linked to an Instagram Business account.' } }]);
});