import assert from 'node:assert/strict';
import test from 'node:test';
import { createFacebookGraphAdapter } from '../src/social/facebook_graph_adapter.js';

test('Facebook adapter posts a draft to the configured Page feed', async () => {
  const calls = [];
  const logger = { info: (message, details) => calls.push({ message, details }), error: () => {} };
  const adapter = createFacebookGraphAdapter({
    pageId: '1358808947308489',
    accessToken: 'test-token',
    logger,
    fetchFn: async (url, options) => {
      calls.push({ url, options });
      return { ok: true, status: 200, json: async () => ({ id: '1358808947308489_123' }) };
    },
  });

  const result = await adapter.publish({ caption: 'Ride safely with Swat Ride.' });

  assert.deepEqual(result, { providerPostId: '1358808947308489_123' });
  assert.equal(calls[0].url, 'https://graph.facebook.com/v26.0/1358808947308489/feed');
  assert.equal(calls[0].options.method, 'POST');
  assert.equal(calls[0].options.headers['content-type'], 'application/x-www-form-urlencoded');
  assert.deepEqual(Object.fromEntries(new URLSearchParams(calls[0].options.body)), { message: 'Ride safely with Swat Ride.', access_token: 'test-token' });
  assert.deepEqual(calls[1], { message: 'Facebook Page post published', details: { pageId: '1358808947308489', providerPostId: '1358808947308489_123' } });
});

test('Facebook adapter logs Graph API failures without logging the access token', async () => {
  const errors = [];
  const adapter = createFacebookGraphAdapter({
    pageId: '1358808947308489',
    accessToken: 'test-token',
    logger: { info: () => {}, error: (message, details) => errors.push({ message, details }) },
    fetchFn: async () => ({ ok: false, status: 400, json: async () => ({ error: { message: 'Invalid OAuth access token.' } }) }),
  });

  await assert.rejects(() => adapter.publish({ caption: 'Ride safely with Swat Ride.' }), /FACEBOOK_PUBLISH_REJECTED/);
  assert.deepEqual(errors, [{ message: 'Facebook Page post was rejected', details: { pageId: '1358808947308489', status: 400, error: 'Invalid OAuth access token.' } }]);
});