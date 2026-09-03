import { createSocialContentDraft } from '../../../src/social/social_content_agent_service.js';
import { routeError, socialRuntime } from '../../../src/social/social_route_runtime.js';

export default async function handler(request, response) {
  if (request.method !== 'POST') return response.status(405).json({ ok: false, code: 'METHOD_NOT_ALLOWED' });
  try {
    const runtime = socialRuntime();
    const identity = await runtime.identity(request);
    const draft = createSocialContentDraft(request.body || {});
    const reference = runtime.firestore.collection('social_content_drafts').doc();
    await reference.set({ ...draft, draftId: reference.id, createdBy: identity.uid, createdAt: new Date(), updatedAt: new Date() });
    await runtime.firestore.collection('social_audit_log').add({ action: 'draft_created', draftId: reference.id, actorId: identity.uid, at: new Date() });
    return response.status(201).json({ ok: true, draftId: reference.id, draft });
  } catch (error) { return routeError(response, error); }
}