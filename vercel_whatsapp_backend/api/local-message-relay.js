'use strict';

const admin = require('firebase-admin');
const {
  createLocalMessageRelayHandler,
} = require('../src/handlers/local_message_relay_boundary');

const controlDocumentPath = 'app_config/super_admin_operational_controls';
const requestTimeoutMs = 10000;

function firebaseApp() {
  if (admin.apps.length > 0) return admin.app();
  const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON || '');
  return admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}

function configuredSourceIps() {
  return (process.env.LOCAL_MESSAGE_RELAY_SOURCE_IPS || '')
      .split(',')
      .map((value) => value.trim())
      .filter(Boolean);
}

function clientIp(request) {
  const forwarded = String(request.headers['x-forwarded-for'] || '')
      .split(',')[0]
      .trim();
  return forwarded || request.socket?.remoteAddress || '';
}

async function forwardToLocalGateway(message) {
  const url = process.env.LOCAL_MESSAGE_RELAY_URL;
  const secret = process.env.LOCAL_MESSAGE_RELAY_DOWNSTREAM_SECRET;
  if (!url || !secret) return { ok: false };

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), requestTimeoutMs);
  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'x-relay-secret': secret,
      },
      body: JSON.stringify(message),
      signal: controller.signal,
    });
    return { ok: response.ok };
  } finally {
    clearTimeout(timeout);
  }
}

const handleRelay = createLocalMessageRelayHandler({
  isRelayEnabled: async () => {
    const snapshot = await firebaseApp().firestore().doc(controlDocumentPath).get();
    return snapshot.data()?.localMessagingRelayEnabled !== false;
  },
  sendMessage: forwardToLocalGateway,
  allowedSourceIps: configuredSourceIps(),
});

module.exports = async (request, response) => {
  if (request.method !== 'POST') {
    response.setHeader('allow', 'POST');
    response.status(405).json({ ok: false, code: 'METHOD_NOT_ALLOWED' });
    return;
  }

  try {
    const result = await handleRelay({
      headers: request.headers,
      sourceIp: clientIp(request),
      body: request.body,
    });
    response.status(result.status).json(result);
  } catch (error) {
    console.error('Local message relay failed', error);
    response.status(503).json({ ok: false, code: 'RELAY_UNAVAILABLE' });
  }
};