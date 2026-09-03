export async function requireApprovedSocialPublish({ firestore, draftId, actorId, authorizeSuperAdmin } = {}) {
  if (!firestore || !draftId || !actorId || typeof authorizeSuperAdmin !== 'function') {
    throw new Error('SOCIAL_APPROVAL_GUARD_CONFIGURATION_INVALID');
  }
  const authorization = await authorizeSuperAdmin(actorId);
  if (!authorization?.authorized) throw new Error('SOCIAL_PUBLISH_NOT_SUPER_ADMIN');
  const approval = await firestore.collection('social_publish_approvals').doc(draftId).get();
  const data = approval.data() || {};
  if (!approval.exists || data.status !== 'approved' || data.approvedBy !== actorId) {
    throw new Error('SOCIAL_PUBLISH_APPROVAL_REQUIRED');
  }
  return data;
}