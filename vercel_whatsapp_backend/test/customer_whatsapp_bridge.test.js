'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const {
  classifyIncomingMessage,
  createWhatsAppAiAgentBridge,
} = require('../src/handlers/whatsapp_ai_agent_bridge');

test('classifyIncomingMessage identifies OTP/login requests', () => {
  assert.equal(classifyIncomingMessage('please send me the OTP code'), 'otp_login');
});

test('bridge keeps ride status messaging in-app while responding safely via WhatsApp', async () => {
  const bridge = createWhatsAppAiAgentBridge({
    runtime: { providerSelected: true, businessExecutionEnabled: false },
    backendServices: {
      resolveCustomerContext: async ({ senderPhone }) => ({ senderPhone, isAuthenticated: false }),
      createSupportTicket: async () => ({ ok: true, ticketId: 'T-1' }),
      sendResponse: async ({ message }) => ({ ok: true, message }),
    },
  });

  const result = await bridge.processInboundMessage({
    eventId: 'evt-ride-status-1',
    senderRefHash: '+923001234567',
    conversationRefHash: 'chat-ride-status',
    providerId: 'meta',
    messageBody: 'Where is my driver?',
  });

  assert.equal(result.ok, true);
  assert.equal(result.classification, 'ride_status');
  assert.equal(result.rideStatusUnaffected, true);
  assert.match(result.responseMessage, /app and Socket/i);
});

test('bridge replies with a safe login notice without triggering any ride mutation', async () => {
  const bridge = createWhatsAppAiAgentBridge({
    runtime: { providerSelected: true, businessExecutionEnabled: false },
    backendServices: {
      resolveCustomerContext: async ({ senderPhone }) => ({ senderPhone, isAuthenticated: false }),
      sendResponse: async ({ message }) => ({ ok: true, message }),
    },
  });

  const result = await bridge.processInboundMessage({
    eventId: 'evt-otp-1',
    senderRefHash: '+923001234567',
    conversationRefHash: 'chat-otp',
    providerId: 'meta',
    messageBody: 'I need the login OTP code',
  });

  assert.equal(result.ok, true);
  assert.equal(result.classification, 'otp_login');
  assert.match(result.responseMessage, /app OTP flow|in-app support/i);
});