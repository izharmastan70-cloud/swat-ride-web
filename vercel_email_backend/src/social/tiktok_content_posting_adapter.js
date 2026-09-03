function tiktokError(body) {
  return body.error?.message || body.error?.code || body.message || 'Unknown TikTok API error';
}

function hasTikTokError(body) {
  const code = body.error?.code;
  return Boolean(code && code !== 'ok');
}

export function createTikTokContentPostingAdapter({ accessToken, fetchFn = fetch, logger = console } = {}) {
  return { async publish(draft) {
    if (!accessToken || !draft.videoUrl) throw new Error('TIKTOK_PROVIDER_NOT_CONFIGURED');
    const response = await fetchFn('https://open.tiktokapis.com/v2/post/publish/video/init/', {
      method: 'POST',
      headers: { authorization: `Bearer ${accessToken}`, 'content-type': 'application/json' },
      body: JSON.stringify({
        post_info: { title: draft.caption, privacy_level: 'PUBLIC_TO_EVERYONE' },
        source_info: { source: 'PULL_FROM_URL', video_url: draft.videoUrl },
      }),
    });
    const body = await response.json().catch(() => ({}));
    const postId = body?.data?.publish_id;
    if (!response.ok || hasTikTokError(body) || !postId) {
      logger.error('TikTok Direct Post initialization failed', { status: response.status, error: tiktokError(body) });
      throw new Error('TIKTOK_PUBLISH_REJECTED');
    }
    logger.info('TikTok Direct Post initialized', { providerPostId: postId });
    return { providerPostId: postId };
  }};
}