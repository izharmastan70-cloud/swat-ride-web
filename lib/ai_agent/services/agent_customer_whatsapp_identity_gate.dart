import '../models/agent_customer_whatsapp_identity_session.dart';

class AgentCustomerWhatsAppIdentityDecision {
  const AgentCustomerWhatsAppIdentityDecision({
    required this.allowed,
    required this.code,
    required this.requiresVerification,
    required this.requiresHumanEscalation,
  });

  final bool allowed;
  final String code;
  final bool requiresVerification;
  final bool requiresHumanEscalation;
}

class AgentCustomerWhatsAppIdentityGate {
  const AgentCustomerWhatsAppIdentityGate();

  AgentCustomerWhatsAppIdentityDecision evaluate({
    required AgentCustomerWhatsAppIdentitySession session,
    required String conversationId,
    required String senderRefHash,
    required DateTime now,
    required bool sensitiveCustomerDataRequested,
    required bool businessActionRequested,
  }) {
    try {
      session.validate();
    } catch (_) {
      return const AgentCustomerWhatsAppIdentityDecision(
        allowed: false,
        code: 'INVALID_IDENTITY_SESSION',
        requiresVerification: true,
        requiresHumanEscalation: true,
      );
    }

    if (session.isExpiredAt(now)) {
      return const AgentCustomerWhatsAppIdentityDecision(
        allowed: false,
        code: 'IDENTITY_SESSION_EXPIRED',
        requiresVerification: true,
        requiresHumanEscalation: false,
      );
    }

    if (!session.matchesConversation(
      expectedConversationId: conversationId,
      expectedSenderRefHash: senderRefHash,
    )) {
      return const AgentCustomerWhatsAppIdentityDecision(
        allowed: false,
        code: 'CONVERSATION_IDENTITY_MISMATCH',
        requiresVerification: true,
        requiresHumanEscalation: true,
      );
    }

    if (sensitiveCustomerDataRequested &&
        !session.mayReadSensitiveCustomerData) {
      return const AgentCustomerWhatsAppIdentityDecision(
        allowed: false,
        code: 'SENSITIVE_CUSTOMER_VERIFICATION_REQUIRED',
        requiresVerification: true,
        requiresHumanEscalation: false,
      );
    }

    if (businessActionRequested && !session.mayRequestCustomerBusinessAction) {
      return const AgentCustomerWhatsAppIdentityDecision(
        allowed: false,
        code: 'CUSTOMER_BINDING_REQUIRED_FOR_ACTION',
        requiresVerification: true,
        requiresHumanEscalation: false,
      );
    }

    return const AgentCustomerWhatsAppIdentityDecision(
      allowed: true,
      code: 'IDENTITY_SESSION_OK',
      requiresVerification: false,
      requiresHumanEscalation: false,
    );
  }
}
