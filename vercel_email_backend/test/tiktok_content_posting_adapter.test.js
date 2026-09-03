import assert from 'node:assert/strict';
import test from 'node:test';
import { createTikTokContentPostingAdapter } from '../src/social/tiktok_content_posting_adapter.js';

test('TikTok adapter initializes an official Direct Post video publication', async () => {
  const calls = [];
  const logs = [];
  const adapter = createTikTokContentPostingAdapter({
    accessToken: 'test-token',
    logger: { info: (message, details) => logs.push({ message, details }), error: () => {} },
    fetchFn: async (url, options) => {
      calls.push({ url, options });
      return { ok: true, status: 200, json: async () => ({ data: { publish_id: 'v_pub_123' }, error: { code: 'ok' } }) };
    },
  });

  const result = await adapter.publish({ videoUrl: 'https://cdn.example.com/swat-ride.mp4', caption: 'Explore Swat with Swat Ride.' });

  assert.deepEqual(result, { providerPostId: 'v_pub_123' });
  assert.equal(calls[0].url, 'https://open.tiktokapis.com/v2/post/publish/video/init/');
  assert.equal(calls[0].options.method, 'POST');
  assert.equal(calls[0].options.headers.authorization, 'Bearer test-token');
  assert.deepEqual(JSON.parse(calls[0].options.body), {
    post_info: { title: 'Explore Swat with Swat Ride.', privacy_level: 'PUBLIC_TO_EVERYONE' },
    source_info: { source: 'PULL_FROM_URL', video_url: 'https://cdn.example.com/swat-ride.mp4' },
  });
  assert.deepEqual(logs, [{ message: 'TikTok Direct Post initialized', details: { providerPostId: 'v_pub_123' } }]);
});

test('TikTok adapter rejects and logs API errors returned with HTTP success', async () => {
  const errors = [];
  const adapter = createTikTokContentPostingAdapter({
    accessToken: 'test-token',
    logger: { info: () => {}, error: (message, details) => errors.push({ message, details }) },
    fetchFn: async () => ({ ok: true, status: 200, json: async () => ({ error: { code: 'access_denied', message: 'Missing video.publish scope.' } }) }),
  });

  await assert.rejects(() => adapter.publish({ videoUrl: 'https://cdn.example.com/swat-ride.mp4', caption: 'Explore Swat with Swat Ride.' }), /TIKTOK_PUBLISH_REJECTED/);
  assert.deepEqual(errors, [{ message: 'TikTok Direct Post initialization failed', details: { status: 200, error: 'Missing video.publish scope.' } }]);
});