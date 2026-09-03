'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');

const {
  PHASE45_CUSTOMER_WHATSAPP_RUNTIME,
  assertSafeDefaultRuntime,
} = require('../src/config/phase45_customer_whatsapp_runtime_config');

const {
  evaluateProductionActivation,
} = require('../src/config/phase45_production_activation_contract');

const {
  validateWebhookVerificationEvidence,
} = require('../src/security/customer_whatsapp_webhook_verification_evidence');

const {
  ReplayReservationStatus,
} = require('../src/security/customer_whatsapp_replay_guard');

const {
  processProviderNeutralInbound,
} = require('../src/handlers/provider_neutral_customer_whatsapp_inbound_boundary');

function verifiedRuntime() {
  return {
    providerId: 'provider-test',
    providerSelected: true,
    inboundNetworkEnabled: true,
    webhookRouteEnabled: true,
  };
}

function evidence(nowMs) {
  return {
    providerId: 'provider-test',
    signatureVerified: true,
    verificationEvidenceId: 'evidence-1',
    verifiedAtMs: nowMs,
  };
}

function metadata(nowMs) {
  return {
    eventId: 'event-1',
    providerId: 'provider-test',
    payloadHash: 'payload-hash-1',
    conversationRefHash: 'conversation-hash-1',
    senderRefHash: 'sender-hash-1',
    receivedAtMs: nowMs,
  };
}

test('safe runtime has no selected provider/network/send/deploy', () => {
  assert.equal(assertSafeDefaultRuntime(), true);
  assert.equal(PHASE45_CUSTOMER_WHATSAPP_RUNTIME.providerSelected, false);
  assert.equal(PHASE45_CUSTOMER_WHATSAPP_RUNTIME.providerId, '');
  assert.equal(PHASE45_CUSTOMER_WHATSAPP_RUNTIME.inboundNetworkEnabled, false);
  assert.equal(PHASE45_CUSTOMER_WHATSAPP_RUNTIME.outboundNetworkEnabled, false);
  assert.equal(PHASE45_CUSTOMER_WHATSAPP_RUNTIME.webhookRouteEnabled, false);
  assert.equal(PHASE45_CUSTOMER_WHATSAPP_RUNTIME.liveSendEnabled, false);
  assert.equal(PHASE45_CUSTOMER_WHATSAPP_RUNTIME.businessExecutionEnabled, false);
  assert.equal(PHASE45_CUSTOMER_WHATSAPP_RUNTIME.deployNow, false);
});

test('production activation remains denied until every gate is explicit', () => {
  const empty = evaluateProductionActivation({});
  assert.equal(empty.allowed, false);
  assert.ok(empty.missing.length >= 10);

  const ready = evaluateProductionActivation({
    providerSelected: true,
    serverSecretsConfigured: true,
    providerSignatureVerifierConfigured: true,
    persistentReplayStoreConfigured: true,
    inboundIdempotencyConfigured: true,
    webhookRouteConfigured: true,
    currentProviderPolicyReviewed: true,
    customerConsentPolicyConfigured: true,
    outboundTransportConfigured: true,
    ownerExplicitActivation: true,
  });

  assert.equal(ready.allowed, true);
  assert.deepEqual(ready.missing, []);
});

test('signature verification evidence is mandatory and provider-bound', () => {
  const nowMs = Date.now();

  assert.equal(
    validateWebhookVerificationEvidence({
      evidence: {
        ...evidence(nowMs),
        signatureVerified: false,
      },
      expectedProviderId: 'provider-test',
      nowMs,
    }).code,
    'SIGNATURE_NOT_VERIFIED',
  );

  assert.equal(
    validateWebhookVerificationEvidence({
      evidence: {
        ...evidence(nowMs),
        providerId: 'other-provider',
      },
      expectedProviderId: 'provider-test',
      nowMs,
    }).code,
    'PROVIDER_BINDING_MISMATCH',
  );
});

test('provider must be selected before inbound event can advance', async () => {
  let storeCalls = 0;

  const result = await processProviderNeutralInbound({
    runtime: {
      providerId: '',
      providerSelected: false,
      inboundNetworkEnabled: false,
      webhookRouteEnabled: false,
    },
    rawMetadata: metadata(Date.now()),
    verificationEvidence: evidence(Date.now()),
    replayStore: {
      reserveIfAbsent: async () => {
        storeCalls += 1;
        return {
          status: ReplayReservationStatus.RESERVED,
        };
      },
    },
    nowMs: Date.now(),
  });

  assert.equal(result.accepted, false);
  assert.equal(result.code, 'PROVIDER_NOT_SELECTED');
  assert.equal(storeCalls, 0);
});

test('disabled webhook runtime fails before replay reservation', async () => {
  let storeCalls = 0;

  const runtime = {
    ...verifiedRuntime(),
    webhookRouteEnabled: false,
  };

  const nowMs = Date.now();

  const result = await processProviderNeutralInbound({
    runtime,
    rawMetadata: metadata(nowMs),
    verificationEvidence: evidence(nowMs),
    replayStore: {
      reserveIfAbsent: async () => {
        storeCalls += 1;
        return {
          status: ReplayReservationStatus.RESERVED,
        };
      },
    },
    nowMs,
  });

  assert.equal(result.accepted, false);
  assert.equal(result.code, 'INBOUND_RUNTIME_DISABLED');
  assert.equal(storeCalls, 0);
});

test('invalid signature fails before replay reservation', async () => {
  let storeCalls = 0;
  const nowMs = Date.now();

  const result = await processProviderNeutralInbound({
    runtime: verifiedRuntime(),
    rawMetadata: metadata(nowMs),
    verificationEvidence: {
      ...evidence(nowMs),
      signatureVerified: false,
    },
    replayStore: {
      reserveIfAbsent: async () => {
        storeCalls += 1;
        return {
          status: ReplayReservationStatus.RESERVED,
        };
      },
    },
    nowMs,
  });

  assert.equal(result.accepted, false);
  assert.equal(result.code, 'SIGNATURE_NOT_VERIFIED');
  assert.equal(storeCalls, 0);
});

test('duplicate inbound event is ignored and not processed twice', async () => {
  const nowMs = Date.now();

  const result = await processProviderNeutralInbound({
    runtime: verifiedRuntime(),
    rawMetadata: metadata(nowMs),
    verificationEvidence: evidence(nowMs),
    replayStore: {
      reserveIfAbsent: async () => ({
        status: ReplayReservationStatus.DUPLICATE,
      }),
    },
    nowMs,
  });

  assert.equal(result.accepted, false);
  assert.equal(result.duplicate, true);
  assert.equal(result.code, 'DUPLICATE_EVENT_IGNORED');
});

test('same event ID with conflicting payload hash fails closed', async () => {
  const nowMs = Date.now();

  const result = await processProviderNeutralInbound({
    runtime: verifiedRuntime(),
    rawMetadata: metadata(nowMs),
    verificationEvidence: evidence(nowMs),
    replayStore: {
      reserveIfAbsent: async () => ({
        status: ReplayReservationStatus.CONFLICT,
      }),
    },
    nowMs,
  });

  assert.equal(result.accepted, false);
  assert.equal(result.duplicate, false);
  assert.equal(result.code, 'EVENT_ID_PAYLOAD_CONFLICT');
});

test('verified new inbound event is only reserved, not executed or replied to', async () => {
  const nowMs = Date.now();

  const result = await processProviderNeutralInbound({
    runtime: verifiedRuntime(),
    rawMetadata: metadata(nowMs),
    verificationEvidence: evidence(nowMs),
    replayStore: {
      reserveIfAbsent: async ({ eventId, payloadHash }) => {
        assert.equal(eventId, 'event-1');
        assert.equal(payloadHash, 'payload-hash-1');

        return {
          status: ReplayReservationStatus.RESERVED,
        };
      },
    },
    nowMs,
  });

  assert.equal(result.accepted, true);
  assert.equal(result.code, 'VERIFIED_INBOUND_RESERVED');
  assert.equal(result.aiInvoked, false);
  assert.equal(result.businessActionExecuted, false);
  assert.equal(result.outboundMessageSent, false);
  assert.equal(result.event.senderRefHash, 'sender-hash-1');
  assert.equal(result.event.conversationRefHash, 'conversation-hash-1');
});