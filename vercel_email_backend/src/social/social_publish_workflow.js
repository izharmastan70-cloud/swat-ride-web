import { requireApprovedSocialPublish } from './social_publish_approval_guard.js';

export async function publishApprovedSocialDraft({ firestore, draftId, actorIdentity, authorizeSuperAdmin, providers } = {}) {
  const actorId = String(actorIdentity?.uid || '').trim();
  const approval = await requireApprovedSocialPublish({ firestore, draftId, actorId, authorizeSuperAdmin: () => authorizeSuperAdmin(actorIdentity) });
  const draftSnapshot = await firestore.collection('social_content_drafts').doc(draftId).get();
  if (!draftSnapshot.exists) throw new Error('SOCIAL_DRAFT_NOT_FOUND');
  const draft = draftSnapshot.data();
  const provider = providers?.[draft.platform];
  if (!provider || typeof provider.publish !== 'function') throw new Error('SOCIAL_PROVIDER_NOT_CONFIGURED');

  const jobReference = firestore.collection('social_publish_jobs').doc(draftId);
  const existingJob = await jobReference.get();
  if (existingJob.exists && existingJob.data()?.status === 'published') return existingJob.data();

  await jobReference.set({ draftId, platform: draft.platform, status: 'publishing', approvedBy: approval.approvedBy, updatedAt: new Date() }, { merge: true });
  const result = await provider.publish(draft);
  const job = { draftId, platform: draft.platform, status: 'published', providerPostId: result.providerPostId, publishedAt: new Date(), updatedAt: new Date() };
  await jobReference.set(job, { merge: true });
  await firestore.collection('social_audit_log').add({ action: 'publish', draftId, actorId, platform: draft.platform, at: new Date() });
  return job;
}