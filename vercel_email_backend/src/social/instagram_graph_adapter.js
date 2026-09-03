function endpoint(path) { return `https://graph.facebook.com/v26.0/${path}`; }

function graphError(body) {
  return body.error?.message || 'Unknown Graph API error';
}

export function createInstagramGraphAdapter({ instagramAccountId, pageId, accessToken, fetchFn = fetch, logger = console } = {}) {
  async function resolveInstagramAccountId() {
    if (instagramAccountId) return instagramAccountId;
    if (!pageId || !accessToken) throw new Error('INSTAGRAM_PROVIDER_NOT_CONFIGURED');

    const discoveryUrl = new URL(endpoint(pageId));
    discoveryUrl.search = new URLSearchParams({ fields: 'instagram_business_account', access_token: accessToken }).toString();
    const discovery = await fetchFn(discoveryUrl, { method: 'GET' });
    const discoveryBody = await discovery.json().catch(() => ({}));
    const resolvedAccountId = discoveryBody.instagram_business_account?.id;
    if (!discovery.ok || !resolvedAccountId) {
      logger.error('Instagram Business account discovery failed', { pageId, status: discovery.status, error: graphError(discoveryBody) });
      throw new Error('INSTAGRAM_ACCOUNT_DISCOVERY_REJECTED');
    }
    logger.info('Instagram Business account discovered', { pageId, instagramAccountId: resolvedAccountId });
    return resolvedAccountId;
  }

  return { async publish(draft) {
    if (!accessToken || !draft.imageUrl) throw new Error('INSTAGRAM_PROVIDER_NOT_CONFIGURED');
    const accountId = await resolveInstagramAccountId();
    const media = await fetchFn(endpoint(`${accountId}/media`), {
      method: 'POST',
      headers: { 'content-type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({ image_url: draft.imageUrl, caption: draft.caption, access_token: accessToken }).toString(),
    });
    const mediaBody = await media.json().catch(() => ({}));
    if (!media.ok || !mediaBody.id) {
      logger.error('Instagram media container creation failed', { instagramAccountId: accountId, status: media.status, error: graphError(mediaBody) });
      throw new Error('INSTAGRAM_MEDIA_CREATE_REJECTED');
    }
    const publish = await fetchFn(endpoint(`${accountId}/media_publish`), {
      method: 'POST',
      headers: { 'content-type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({ creation_id: mediaBody.id, access_token: accessToken }).toString(),
    });
    const publishBody = await publish.json().catch(() => ({}));
    if (!publish.ok || !publishBody.id) {
      logger.error('Instagram media publication failed', { instagramAccountId: accountId, status: publish.status, error: graphError(publishBody) });
      throw new Error('INSTAGRAM_PUBLISH_REJECTED');
    }
    logger.info('Instagram Business post published', { instagramAccountId: accountId, providerPostId: publishBody.id });
    return { providerPostId: publishBody.id };
  }};
}
