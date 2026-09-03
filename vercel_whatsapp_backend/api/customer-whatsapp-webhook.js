'use strict';

const crypto = require('crypto');

const {
  buildRuntimeConfig,
  createRuntimeFromEnvironment,
} = require('../src/config/phase45_customer_whatsapp_runtime_config');
const {
  createCustomerWhatsAppInboundHandler,
  processProviderNeutralInbound,
} = require('../src/handlers/provider_neutral_customer_whatsapp_inbound_boundary');
const {
  createWhatsAppAiAgentBridge,
} = require('../src/handlers/whatsapp_ai_agent_bridge');

function safeJsonParse(value) {
  if (!value) return {};
  if (typeof value === 'object') return value;
  if (typeof value !== 'string') return {};

  try {
    return JSON.parse(value);
  } catch (_) {
    return {};
  }
}

function buildWebhookHash(payload) {
  return crypto.createHash('sha256').update(JSON.stringify(payload)).digest('hex');
}

function buildVerificationEvidence({ providerId, requestHeaders, sharedSecret }) {
  const signature =
    requestHeaders['x-webhook-secret'] ||
    requestHeaders['x-whatsapp-signature'] ||
    requestHeaders['x-signature'] ||
    requestHeaders['x-provider-signature'] ||
    '';

  const signatureVerified = Boolean(sharedSecret) && Boolean(signature) && signature === sharedSecret;

  return {
    providerId: String(providerId || '').trim(),
    signatureVerified,
    verificationEvidenceId: `whatsapp-${Date.now()}-${Math.random().toString(16).slice(2)}`,
    verifiedAtMs: Date.now(),
  };
}

async function createReplayStore() {
  const map = new Map();

  return {
    async reserveIfAbsent({ eventId, payloadHash }) {
      const existing = map.get(eventId);
      if (existing) {
        if (existing.payloadHash !== payloadHash) {
          return { status: 'CONFLICT' };
        }
        return { status: 'DUPLICATE' };
      }

      map.set(eventId, { payloadHash });
      return { status: 'RESERVED' };
    },
  };
}

module.exports = async function customerWhatsAppWebhook(request, response) {
  if (request.method !== 'POST') {
    response.setHeader('allow', 'POST');
    response.status(405).json({ ok: false, code: 'METHOD_NOT_ALLOWED' });
    return;
  }

  const payload = safeJsonParse(request.body);
  const runtime = createRuntimeFromEnvironment();

  if (runtime.providerSelected !== true || runtime.inboundNetworkEnabled !== true || runtime.webhookRouteEnabled !== true) {
    response.status(503).json({
      ok: false,
      code: 'WHATSAPP_AGENT_DISABLED',
      rideStatusUnaffected: true,
    });
    return;
  }

  const secret = process.env.CUSTOMER_WHATSAPP_WEBHOOK_SECRET || '';
  const providerId = String(payload.providerId || payload.provider || request.headers['x-provider-id'] || 'meta').trim() || 'meta';
  const senderPhone = String(payload.from || payload.senderPhone || payload.phone || '').trim();
  const messageBody = String(payload.text || payload.messageBody || payload.body || '').trim();
  const eventId = String(payload.eventId || payload.id || `whatsapp-${Date.now()}`).trim();
  const conversationId = String(payload.conversationId || payload.chatId || payload.conversationRefHash || `${providerId}:${senderPhone || 'unknown'}`).trim();

  const verificationEvidence = buildVerificationEvidence({
    providerId,
    requestHeaders: request.headers || {},
    sharedSecret: secret,
  });

  const metadata = {
    eventId,
    providerId,
    payloadHash: buildWebhookHash(payload),
    conversationRefHash: conversationId,
    senderRefHash: senderPhone || `anon:${eventId}`,
    receivedAtMs: Date.now(),
  };

  if (!verificationEvidence.signatureVerified) {
    response.status(403).json({
      ok: false,
      code: 'WEBHOOK_SIGNATURE_INVALID',
      rideStatusUnaffected: true,
    });
    return;
  }

  const boundaryResult = await processProviderNeutralInbound({
    runtime,
    rawMetadata: metadata,
    verificationEvidence,
    replayStore: await createReplayStore(),
    nowMs: Date.now(),
  });

  if (!boundaryResult.accepted) {
    response.status(boundaryResult.code === 'DUPLICATE_EVENT_IGNORED' ? 200 : 403).json({
      ok: false,
      code: boundaryResult.code,
      duplicate: Boolean(boundaryResult.duplicate),
      rideStatusUnaffected: true,
    });
    return;
  }

  const bridge = createWhatsAppAiAgentBridge({
    runtime,
    backendServices: {
      async resolveCustomerContext({ senderPhone }) {
        return {
          senderPhone,
          isAuthenticated: false,
          isRegistered: false,
        };
      },
      async createSupportTicket({ senderPhone, messageBody: nextBody, eventId: nextEventId }) {
        return {
          ok: true,
          ticketId: `ws-${nextEventId}`,
          status: 'queued',
          senderPhone,
          messageBody: nextBody,
        };
      },
      async sendResponse({ to, message }) {
        return {
          ok: true,
          providerId,
          to,
          message,
          messageId: `reply-${Date.now()}`,
        };
      },
    },
  });

  const result = await bridge.processInboundMessage({
    eventId,
    providerId,
    senderRefHash: senderPhone || `anon:${eventId}`,
    conversationRefHash: conversationId,
    messageBody,
  });

  response.status(200).json({
    ok: result.ok,
    accepted: true,
    code: result.code || 'WHATSAPP_MESSAGE_PROCESSED',
    route: result.route,
    classification: result.classification,
    responseMessage: result.responseMessage,
    rideStatusUnaffected: true,
    eventId,
  });
};

module.exports.default = module.exports;