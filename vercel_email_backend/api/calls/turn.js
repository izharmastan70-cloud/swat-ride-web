import { FieldValue } from 'firebase-admin/firestore';
import { sendVoiceLineHeartbeat } from '../../src/services/ai_voice_agent_pool_service.js';
import { advanceVoiceIntake } from '../../src/services/tier1_voice_intake_slot_extractor_service.js';
import { listActiveVehicleInventory } from '../../src/services/vehicle_inventory_query_service.js';
import { errorResponse, firestore, requirePbxWebhook, text } from './_shared.js';

export default async function handler(request, response) {
  if (request.method !== 'POST') return response.status(405).json({ ok: false, code: 'METHOD_NOT_ALLOWED' });
  try {
    requirePbxWebhook(request);
    const firestoreInstance = firestore();
    const payload = request.body ?? {};
    const callSessionId = text(payload.callSessionId, 'CALL_SESSION_ID', 160);
    const transcript = text(payload.transcript, 'TRANSCRIPT', 500);
    const sessionReference = firestoreInstance.collection('ai_voice_call_sessions').doc(callSessionId);
    const session = await sessionReference.get();
    if (!session.exists || session.data()?.status !== 'intake') throw new Error('VOICE_CALL_SESSION_NOT_IN_INTAKE');
    const inventory = await listActiveVehicleInventory({ firestore: firestoreInstance });
    if (!inventory.length) throw new Error('NO_ACTIVE_VEHICLES');
    const intake = advanceVoiceIntake({
      filledSlots: session.data()?.filledSlots ?? {},
      transcript,
      activeVehicleInventory: inventory,
    });
    await sessionReference.update({
      filledSlots: intake.filledSlots,
      status: intake.complete ? 'ready_for_dispatch' : 'intake',
      activeVehicleIds: inventory.map((vehicle) => vehicle.vehicleId),
      updatedAt: FieldValue.serverTimestamp(),
    });
    await sendVoiceLineHeartbeat({ firestore: firestoreInstance, callSessionId });
    return response.status(200).json({
      ok: true,
      complete: intake.complete,
      promptText: intake.promptText,
      missingSlot: intake.missingSlot,
      error: intake.error ?? null,
    });
  } catch (error) {
    return errorResponse(response, error);
  }
}