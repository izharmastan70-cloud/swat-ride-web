import { routeError, socialRuntime } from '../../../../src/social/social_route_runtime.js';

export default async function handler(request, response) {
  if (request.method !== 'POST') return response.status(405).json({ ok: false, code: 'METHOD_NOT_ALLOWED' });
  try {
    const runtime = socialRuntime();
    const identity = await runtime.identity(request);
    const authorization = await runtime.authorizeSuperAdmin(identity);
    if (!authorization.authorized) throw new Error('SOCIAL_PUBLISH_NOT_SUPER_ADMIN');
    const draftId = String(request.query.id || '').trim();
    const draft = await runtime.firestore.collection('social_content_drafts').doc(draftId).get();
    if (!draft.exists) throw new Error('SOCIAL_DRAFT_NOT_FOUND');
    await runtime.firestore.collection('social_publish_approvals').doc(draftId).set({ draftId, status: 'approved', approvedBy: identity.uid, approvedAt: new Date() });
    await runtime.firestore.collection('social_audit_log').add({ action: 'draft_approved', draftId, actorId: identity.uid, at: new Date() });
    return response.status(200).json({ ok: true, draftId, status: 'approved' });
  } catch (error) { return routeError(response, error); }
}