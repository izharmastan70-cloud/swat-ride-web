'use strict';

const {
  normalizeInboundWebhookMetadata,
} = require('../contracts/customer_whatsapp_inbound_webhook_contract');

const {
  validateWebhookVerificationEvidence,
} = require('../security/customer_whatsapp_webhook_verification_evidence');

const {
  ReplayReservationStatus,
  reserveInboundEvent,
} = require('../security/customer_whatsapp_replay_guard');

async function processProviderNeutralInbound({
  runtime,
  rawMetadata,
  verificationEvidence,
  replayStore,
  nowMs,
}) {
  if (!runtime || runtime.providerSelected !== true) {
    return Object.freeze({
      accepted: false,
      code: 'PROVIDER_NOT_SELECTED',
    });
  }

  if (
    runtime.inboundNetworkEnabled !== true ||
    runtime.webhookRouteEnabled !== true
  ) {
    return Object.freeze({
      accepted: false,
      code: 'INBOUND_RUNTIME_DISABLED',
    });
  }

  const metadata =
    normalizeInboundWebhookMetadata(rawMetadata);

  if (metadata.providerId !== runtime.providerId) {
    return Object.freeze({
      accepted: false,
      code: 'PROVIDER_METADATA_MISMATCH',
    });
  }

  const verification =
    validateWebhookVerificationEvidence({
      evidence: verificationEvidence,
      expectedProviderId: runtime.providerId,
      nowMs,
    });

  if (!verification.ok) {
    return Object.freeze({
      accepted: false,
      code: verification.code,
    });
  }

  const reservation =
    await reserveInboundEvent({
      replayStore,
      eventId: metadata.eventId,
      payloadHash: metadata.payloadHash,
    });

  if (reservation.status === ReplayReservationStatus.DUPLICATE) {
    return Object.freeze({
      accepted: false,
      duplicate: true,
      code: 'DUPLICATE_EVENT_IGNORED',
    });
  }

  if (reservation.status === ReplayReservationStatus.CONFLICT) {
    return Object.freeze({
      accepted: false,
      duplicate: false,
      code: 'EVENT_ID_PAYLOAD_CONFLICT',
    });
  }

  return Object.freeze({
    accepted: true,
    duplicate: false,
    code: 'VERIFIED_INBOUND_RESERVED',
    event: Object.freeze({
      eventId: metadata.eventId,
      providerId: metadata.providerId,
      conversationRefHash: metadata.conversationRefHash,
      senderRefHash: metadata.senderRefHash,
      payloadHash: metadata.payloadHash,
      verificationEvidenceId:
        verification.verificationEvidenceId,
    }),
    // This boundary does NOT invoke AI, business tools, or outbound send.
    aiInvoked: false,
    businessActionExecuted: false,
    outboundMessageSent: false,
  });
}

async function createCustomerWhatsAppInboundHandler({
  runtime,
  replayStore,
  nowMs = Date.now(),
  onAccepted,
} = {}) {
  if (!runtime || typeof runtime !== 'object') {
    throw new Error('Runtime configuration is required for customer WhatsApp inbound handler.');
  }

  return async function handleInboundRequest({ rawMetadata, verificationEvidence }) {
    const result = await processProviderNeutralInbound({
      runtime,
      rawMetadata,
      verificationEvidence,
      replayStore,
      nowMs,
    });

    if (result.accepted && typeof onAccepted === 'function') {
      await onAccepted(result);
    }

    return result;
  };
}

module.exports = {
  createCustomerWhatsAppInboundHandler,
  processProviderNeutralInbound,
};