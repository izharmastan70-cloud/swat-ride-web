import { publishApprovedSocialDraft } from '../../../../src/social/social_publish_workflow.js';
import { routeError, socialRuntime } from '../../../../src/social/social_route_runtime.js';

export default async function handler(request, response) {
  if (request.method !== 'POST') return response.status(405).json({ ok: false, code: 'METHOD_NOT_ALLOWED' });
  try {
    const runtime = socialRuntime();
    const identity = await runtime.identity(request);
    const job = await publishApprovedSocialDraft({ firestore: runtime.firestore, draftId: String(request.query.id || '').trim(), actorIdentity: identity, authorizeSuperAdmin: runtime.authorizeSuperAdmin, providers: runtime.providers });
    return response.status(200).json({ ok: true, job });
  } catch (error) { return routeError(response, error); }
}