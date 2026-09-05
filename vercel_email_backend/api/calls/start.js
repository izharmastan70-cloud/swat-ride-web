import { FieldValue } from 'firebase-admin/firestore';
import { acquireVoiceLine } from '../../src/services/ai_voice_agent_pool_service.js';
import { advanceVoiceIntake } from '../../src/services/tier1_voice_intake_slot_extractor_service.js';
import { listActiveVehicleInventory } from '../../src/services/vehicle_inventory_query_service.js';
import { errorResponse, firestore, optionalText, phone, requirePbxWebhook, requireVoiceBookingEnabled, text } from './_shared.js';

export default async function handler(request, response) {
  if (request.method !== 'POST') return response.status(405).json({ ok: false, code: 'METHOD_NOT_ALLOWED' });
  try {
    requirePbxWebhook(request);
    const firestoreInstance = firestore();
    await requireVoiceBookingEnabled(firestoreInstance);
    const payload = request.body ?? {};
    const callSessionId = text(payload.callSessionId, 'CALL_SESSION_ID', 160);
    const callerPhone = phone(payload.callerPhone);
    const gatewayId = optionalText(payload.gatewayId, 'GATEWAY_ID', 120);
    const pool = await acquireVoiceLine({ firestore: firestoreInstance, callSessionId, gatewayId });
    const inventory = await listActiveVehicleInventory({ firestore: firestoreInstance });
    if (!inventory.length) throw new Error('NO_ACTIVE_VEHICLES');
    const intake = advanceVoiceIntake({ activeVehicleInventory: inventory });
    await firestoreInstance.collection('ai_voice_call_sessions').doc(callSessionId).set({
      callSessionId,
      callerPhone,
      gatewayId,
      status: 'intake',
      filledSlots: {},
      activeVehicleIds: inventory.map((vehicle) => vehicle.vehicleId),
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    return response.status(200).json({ ok: true, callSessionId, alreadyHeld: pool.alreadyHeld, promptText: intake.promptText });
  } catch (error) {
    return errorResponse(response, error);
  }
}