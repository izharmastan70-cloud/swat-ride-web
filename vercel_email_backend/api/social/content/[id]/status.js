import { routeError, socialRuntime } from '../../../../src/social/social_route_runtime.js';

export default async function handler(request, response) {
  if (request.method !== 'GET') return response.status(405).json({ ok: false, code: 'METHOD_NOT_ALLOWED' });
  try {
    const runtime = socialRuntime();
    await runtime.identity(request);
    const draftId = String(request.query.id || '').trim();
    const job = await runtime.firestore.collection('social_publish_jobs').doc(draftId).get();
    return response.status(200).json({ ok: true, draftId, status: job.exists ? job.data() : { status: 'draft' } });
  } catch (error) { return routeError(response, error); }
}