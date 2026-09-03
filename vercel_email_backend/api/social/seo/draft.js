import { generateSeoBlogDraft } from '../../../src/social/seo_blog_agent_service.js';
import { routeError, socialRuntime } from '../../../src/social/social_route_runtime.js';

export default async function handler(request, response) {
  if (request.method !== 'POST') return response.status(405).json({ ok: false, code: 'METHOD_NOT_ALLOWED' });
  try {
    const runtime = socialRuntime();
    const identity = await runtime.identity(request);
    const authorization = await runtime.authorizeSuperAdmin(identity);
    if (!authorization.authorized) throw new Error('SEO_BLOG_NOT_SUPER_ADMIN');
    const draft = await generateSeoBlogDraft(request.body || {});
    const reference = runtime.firestore.collection('seo_blog_drafts').doc();
    await reference.set({ ...draft, topic: request.body?.topic, status: 'draft', createdBy: identity.uid, createdAt: new Date(), updatedAt: new Date() });
    await runtime.firestore.collection('social_audit_log').add({ action: 'seo_blog_draft_created', draftId: reference.id, actorId: identity.uid, at: new Date() });
    console.info('SEO blog draft generated', { draftId: reference.id, topic: request.body?.topic });
    return response.status(201).json({ ok: true, draftId: reference.id, draft });
  } catch (error) { return routeError(response, error); }
}