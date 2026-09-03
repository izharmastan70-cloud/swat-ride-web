/**
 * WhatsApp to AI Agent Bridge
 *
 * Processes inbound WhatsApp messages and routes them to a safe support layer
 * without affecting the core Swat Ride app/Socket.io ride status path.
 */

'use strict';

const MAX_MESSAGE_ID_LENGTH = 100;
const MAX_MESSAGE_BODY_LENGTH = 4096;

function nonEmptyString(value) {
  return typeof value === 'string' && value.trim().length > 0;
}

function normalizeMessageText(value) {
  if (typeof value !== 'string') return '';
  const normalized = value.trim();
  return normalized.length > MAX_MESSAGE_BODY_LENGTH
    ? normalized.slice(0, MAX_MESSAGE_BODY_LENGTH)
    : normalized;
}

function classifyIncomingMessage(messageText = '') {
  const text = normalizeMessageText(messageText).toLowerCase();
  if (!text) return 'empty';

  if (/(otp|one[- ]time password|verification code|login code|verify my number|login)/i.test(text)) {
    return 'otp_login';
  }

  if (/(ride status|trip status|driver|pickup|drop|dropoff|cancel ride|booking|book a ride|fare|eta|where is my driver|on the way)/i.test(text)) {
    return 'ride_status';
  }

  if (/(help|support|issue|problem|complaint|refund|payment|billing|charge|driver behavior|report)/i.test(text)) {
    return 'support';
  }

  if (/(hi|hello|hey|good morning|good evening|thanks|thank you)/i.test(text)) {
    return 'greeting';
  }

  return 'general';
}

function createWhatsAppAiAgentBridge({
  backendServices = {},
  runtime = null,
  maxRetries = 2,
} = {}) {
  if (!backendServices || typeof backendServices !== 'object') {
    throw new Error('Backend services object is required for the WhatsApp AI bridge.');
  }

  const failedResult = (code, reason) => Object.freeze({
    ok: false,
    processed: false,
    code,
    reason,
  });

  const routeMessage = async ({
    classification,
    messageBody,
    providerId,
    eventId,
    senderRefHash,
    conversationRefHash,
    customerContext,
  }) => {
    if (
      runtime &&
      runtime.providerSelected === true &&
      runtime.businessExecutionEnabled === true &&
      typeof backendServices.executeBusinessAction === 'function'
    ) {
      const businessAction = await backendServices.executeBusinessAction({
        classification,
        messageBody,
        providerId,
        eventId,
        senderRefHash,
        conversationRefHash,
        customerContext,
      });

      if (businessAction && businessAction.ok) {
        return {
          route: 'business_action',
          backendAction: businessAction.action || 'business_action',
          responseMessage: businessAction.responseMessage || 'Your request is being handled by the support team.',
        };
      }
    }

    switch (classification) {
      case 'otp_login':
        return {
          route: 'login_policy_notice',
          backendAction: 'login_notice_only',
          responseMessage:
            'WhatsApp login/OTP is still pending in this build. Please continue with the app OTP flow or the in-app support channel. Ride updates remain in the Swat Ride app and live Socket.io feed.',
        };

      case 'ride_status':
        return {
          route: 'ride_status_guidance',
          backendAction: 'status_guidance',
          responseMessage:
            'For safety and consistency, live ride status, ETA, and driver updates stay in the Swat Ride app and Socket.io feed. Please open the app to view your trip status.',
        };

      case 'support': {
        if (typeof backendServices.createSupportTicket === 'function') {
          const ticket = await backendServices.createSupportTicket({
            senderPhone: customerContext.senderPhone || senderRefHash,
            messageBody,
            providerId,
            eventId,
            conversationId: conversationRefHash,
          });

          if (ticket && ticket.ok) {
            return {
              route: 'support_ticket',
              backendAction: 'support_ticket',
              responseMessage:
                'Thanks for reaching out. We created a support request and will follow up through the app or the registered contact method.',
            };
          }
        }

        return {
          route: 'support_fallback',
          backendAction: 'support_queue',
          responseMessage:
            'We received your message. Please continue in the Swat Ride app support flow so our team can assist you securely.',
        };
      }

      case 'greeting':
        return {
          route: 'greeting',
          backendAction: 'chat_ack',
          responseMessage:
            'Hello! Swat Ride support is available in the app and through secure support channels. Ride updates are not sent via WhatsApp for safety.',
        };

      default:
        return {
          route: 'general_assistant',
          backendAction: 'faq',
          responseMessage:
            'Thanks for your message. For ride, OTP, booking, and trip updates, please continue in the Swat Ride app. WhatsApp remains limited to safe support and OTP/login notices in this build.',
        };
    }
  };

  const processInboundMessage = async (inboundEvent) => {
    try {
      if (!inboundEvent || typeof inboundEvent !== 'object') {
        return failedResult('EVENT_INVALID', 'Inbound event object is required.');
      }

      const eventId = String(inboundEvent.eventId || inboundEvent.id || '').trim();
      const senderRefHash = String(inboundEvent.senderRefHash || inboundEvent.senderPhone || '').trim();
      const conversationRefHash = String(inboundEvent.conversationRefHash || inboundEvent.conversationId || '').trim();
      const providerId = String(inboundEvent.providerId || '').trim();
      const messageBody = normalizeMessageText(
        inboundEvent.messageBody || inboundEvent.text || inboundEvent.body || '',
      );

      if (!eventId || eventId.length > MAX_MESSAGE_ID_LENGTH) {
        return failedResult('EVENT_ID_MISSING', 'A valid eventId is required.');
      }

      if (!senderRefHash) {
        return failedResult('SENDER_REF_MISSING', 'Sender reference is required.');
      }

      if (!conversationRefHash) {
        return failedResult('CONVERSATION_REF_MISSING', 'Conversation reference is required.');
      }

      const customerContext =
        typeof backendServices.resolveCustomerContext === 'function'
          ? await backendServices.resolveCustomerContext({
              senderPhone: senderRefHash,
              eventId,
              conversationId: conversationRefHash,
              messageBody,
            })
          : { senderPhone: senderRefHash };

      const classification = classifyIncomingMessage(messageBody);
      const routeDecision = await routeMessage({
        classification,
        messageBody,
        providerId,
        eventId,
        senderRefHash,
        conversationRefHash,
        customerContext,
      });

      if (typeof backendServices.sendResponse === 'function' && routeDecision.responseMessage) {
        try {
          await backendServices.sendResponse({
            to: customerContext.senderPhone || senderRefHash,
            providerId,
            conversationId: conversationRefHash,
            eventId,
            message: routeDecision.responseMessage,
            classification,
            rideStatusUnaffected: true,
          });
        } catch (error) {
          console.warn('WhatsApp outbound reply failed:', error?.message || error);
        }
      }

      return Object.freeze({
        ok: true,
        processed: true,
        eventId,
        providerId,
        classification,
        route: routeDecision.route,
        backendAction: routeDecision.backendAction,
        responseMessage: routeDecision.responseMessage,
        rideStatusUnaffected: true,
        responseGenerated: true,
      });
    } catch (error) {
      console.error('WhatsApp AI bridge processing failed:', error);
      return failedResult('BRIDGE_EXCEPTION', `Unexpected error: ${error?.message || 'unknown'}`);
    }
  };

  return {
    processInboundMessage,
    routeMessage,
    classifyIncomingMessage,
  };
}

class WhatsAppToAiAgentBridge {
  constructor(options = {}) {
    this._bridge = createWhatsAppAiAgentBridge(options);
  }

  async processInboundMessage(inboundEvent) {
    return this._bridge.processInboundMessage(inboundEvent);
  }
}

module.exports = {
  MAX_MESSAGE_ID_LENGTH,
  MAX_MESSAGE_BODY_LENGTH,
  classifyIncomingMessage,
  createWhatsAppAiAgentBridge,
  WhatsAppToAiAgentBridge,
};

module.exports.default = WhatsAppToAiAgentBridge;
