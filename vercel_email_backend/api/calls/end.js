import { FieldValue } from 'firebase-admin/firestore';
import { releaseVoiceLine } from '../../src/services/ai_voice_agent_pool_service.js';
import { errorResponse, firestore, requirePbxWebhook, text } from './_shared.js';

export default async function handler(request, response) {
  if (request.method !== 'POST') return response.status(405).json({ ok: false, code: 'METHOD_NOT_ALLOWED' });
  try {
    requirePbxWebhook(request);
    const firestoreInstance = firestore();
    const callSessionId = text(request.body?.callSessionId, 'CALL_SESSION_ID', 160);
    const release = await releaseVoiceLine({ firestore: firestoreInstance, callSessionId });
    await firestoreInstance.collection('ai_voice_call_sessions').doc(callSessionId).set({
      status: 'ended',
      endedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    return response.status(200).json({ ok: true, released: release.released });
  } catch (error) {
    return errorResponse(response, error);
  }
}