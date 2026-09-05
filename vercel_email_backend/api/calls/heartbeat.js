import { sendVoiceLineHeartbeat } from '../../src/services/ai_voice_agent_pool_service.js';
import { errorResponse, firestore, requirePbxWebhook, text } from './_shared.js';

export default async function handler(request, response) {
  if (request.method !== 'POST') return response.status(405).json({ ok: false, code: 'METHOD_NOT_ALLOWED' });
  try {
    requirePbxWebhook(request);
    const callSessionId = text(request.body?.callSessionId, 'CALL_SESSION_ID', 160);
    await sendVoiceLineHeartbeat({ firestore: firestore(), callSessionId });
    return response.status(200).json({ ok: true });
  } catch (error) {
    return errorResponse(response, error);
  }
}