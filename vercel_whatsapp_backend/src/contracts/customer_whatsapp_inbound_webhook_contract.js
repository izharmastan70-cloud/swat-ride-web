'use strict';

const MAX_EVENT_ID_LENGTH = 200;
const MAX_HASH_LENGTH = 256;
const MAX_PROVIDER_ID_LENGTH = 100;

function normalizeInboundWebhookMetadata(input) {
  if (!input || typeof input !== 'object') {
    throw new Error('Inbound webhook metadata object is required.');
  }

  const eventId = String(input.eventId || '').trim();
  const providerId = String(input.providerId || '').trim();
  const payloadHash = String(input.payloadHash || '').trim();
  const conversationRefHash =
    String(input.conversationRefHash || '').trim();
  const senderRefHash =
    String(input.senderRefHash || '').trim();
  const receivedAtMs = Number(input.receivedAtMs);

  if (
    !eventId ||
    !providerId ||
    !payloadHash ||
    !conversationRefHash ||
    !senderRefHash
  ) {
    throw new Error('Inbound webhook binding metadata is incomplete.');
  }

  if (
    eventId.length > MAX_EVENT_ID_LENGTH ||
    providerId.length > MAX_PROVIDER_ID_LENGTH ||
    payloadHash.length > MAX_HASH_LENGTH
  ) {
    throw new Error('Inbound webhook metadata exceeds safe limits.');
  }

  if (!Number.isSafeInteger(receivedAtMs) || receivedAtMs <= 0) {
    throw new Error('Valid receivedAtMs is required.');
  }

  return Object.freeze({
    eventId,
    providerId,
    payloadHash,
    conversationRefHash,
    senderRefHash,
    receivedAtMs,
  });
}

module.exports = {
  normalizeInboundWebhookMetadata,
};