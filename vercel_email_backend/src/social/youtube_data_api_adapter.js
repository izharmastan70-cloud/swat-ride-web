export function createYouTubeDataApiAdapter({ accessToken, fetchFn = fetch } = {}) {
  return { async publish(draft) {
    if (!accessToken || !draft.videoUrl) throw new Error('YOUTUBE_PROVIDER_NOT_CONFIGURED');
    const response = await fetchFn('https://www.googleapis.com/upload/youtube/v3/videos?part=snippet,status&uploadType=resumable', { method: 'POST', headers: { authorization: `Bearer ${accessToken}`, 'content-type': 'application/json' }, body: JSON.stringify({ snippet: { title: draft.title, description: draft.caption, tags: draft.hashtags }, status: { privacyStatus: 'private' } }) });
    const uploadUrl = response.headers.get('location');
    if (!response.ok || !uploadUrl) throw new Error('YOUTUBE_UPLOAD_SESSION_REJECTED');
    const upload = await fetchFn(uploadUrl, { method: 'PUT', headers: { 'content-type': 'video/*' }, body: await (await fetchFn(draft.videoUrl)).arrayBuffer() });
    const body = await upload.json().catch(() => ({}));
    if (!upload.ok || !body.id) throw new Error('YOUTUBE_PUBLISH_REJECTED');
    return { providerPostId: body.id };
  }};
}