function endpoint(path) { return `https://graph.facebook.com/v26.0/${path}`; }
export function createFacebookGraphAdapter({ pageId, accessToken, fetchFn = fetch, logger = console } = {}) {
  return { async publish(draft) {
    if (!pageId || !accessToken) throw new Error('FACEBOOK_PROVIDER_NOT_CONFIGURED');
    const response = await fetchFn(endpoint(`${pageId}/feed`), {
      method: 'POST',
      headers: { 'content-type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({ message: draft.caption, access_token: accessToken }).toString(),
    });
    const body = await response.json().catch(() => ({}));
    if (!response.ok || !body.id) {
      logger.error('Facebook Page post was rejected', { pageId, status: response.status, error: body.error?.message || 'Unknown Graph API error' });
      throw new Error('FACEBOOK_PUBLISH_REJECTED');
    }
    logger.info('Facebook Page post published', { pageId, providerPostId: body.id });
    return { providerPostId: body.id };
  }};
}