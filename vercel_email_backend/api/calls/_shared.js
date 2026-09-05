import { timingSafeEqual } from 'node:crypto';
import { cert, getApp, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

export function text(value, name, maxLength = 240) {
  const normalized = typeof value === 'string' ? value.trim() : '';
  if (!normalized || normalized.length > maxLength) throw new Error(`INVALID_${name}`);
  return normalized;
}

export function optionalText(value, name, maxLength = 240) {
  if (value === undefined || value === null || value === '') return null;
  return text(value, name, maxLength);
}

export function phone(value) {
  const normalized = typeof value === 'string' ? value.replace(/\s/g, '') : '';
  if (!/^\+[1-9]\d{7,14}$/.test(normalized)) throw new Error('INVALID_CALLER_PHONE');
  return normalized;
}

export function number(value, name, minimum, maximum) {
  if (typeof value !== 'number' || !Number.isFinite(value) || value < minimum || value > maximum) {
    throw new Error(`INVALID_${name}`);
  }
  return value;
}

export function initializeFirebase() {
  try {
    return getApp('swat-ride-call-dispatch');
  } catch (_) {
    const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
    const projectId = process.env.SWAT_RIDE_FIREBASE_PROJECT_ID;
    if (!serviceAccountJson || !projectId) throw new Error('FIREBASE_ADMIN_CONFIGURATION_MISSING');
    return initializeApp({ credential: cert(JSON.parse(serviceAccountJson)), projectId }, 'swat-ride-call-dispatch');
  }
}

export function firestore() {
  return getFirestore(initializeFirebase());
}

export function requirePbxWebhook(request) {
  const expected = process.env.PBX_WEBHOOK_SECRET;
  const received = request.headers['x-pbx-webhook-secret'] ?? request.headers['x-voice-webhook-secret'];
  if (!expected || typeof received !== 'string') throw new Error('PBX_WEBHOOK_NOT_AUTHORIZED');
  const expectedBuffer = Buffer.from(expected);
  const receivedBuffer = Buffer.from(received);
  if (expectedBuffer.length !== receivedBuffer.length || !timingSafeEqual(expectedBuffer, receivedBuffer)) {
    throw new Error('PBX_WEBHOOK_NOT_AUTHORIZED');
  }
}

export async function requireVoiceBookingEnabled(firestoreInstance) {
  const controls = await firestoreInstance
    .collection('app_config')
    .doc('super_admin_operational_controls')
    .get();
  if (controls.data()?.phoneCallBookingEnabled === false) {
    throw new Error('PHONE_CALL_BOOKING_PAUSED_BY_SUPER_ADMIN');
  }
}

export async function isLocalMessagingRelayEnabled(firestoreInstance) {
  const controls = await firestoreInstance
    .collection('app_config')
    .doc('super_admin_operational_controls')
    .get();
  return controls.data()?.localMessagingRelayEnabled !== false;
}

export function errorResponse(response, error) {
  const code = String(error?.message ?? 'VOICE_WEBHOOK_FAILED');
  const status = code.startsWith('INVALID_') ? 400
    : code === 'PBX_WEBHOOK_NOT_AUTHORIZED' ? 401
      : code === 'AI_VOICE_AGENT_POOL_FULL' || code === 'PHONE_CALL_BOOKING_PAUSED_BY_SUPER_ADMIN' ? 503
        : ['DRIVER_NOT_AVAILABLE', 'NO_AVAILABLE_DRIVER', 'IDEMPOTENCY_KEY_ALREADY_IN_PROGRESS'].includes(code) ? 409
          : 500;
  return response.status(status).json({ ok: false, code });
}