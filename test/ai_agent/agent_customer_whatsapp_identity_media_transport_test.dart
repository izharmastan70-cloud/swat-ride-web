import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/models/agent_customer_whatsapp_identity_session.dart';
import 'package:swat_ride/ai_agent/models/agent_customer_whatsapp_media.dart';
import 'package:swat_ride/ai_agent/models/agent_customer_whatsapp_transport.dart';
import 'package:swat_ride/ai_agent/services/agent_customer_whatsapp_disabled_transport.dart';
import 'package:swat_ride/ai_agent/services/agent_customer_whatsapp_identity_gate.dart';

void main() {
  final DateTime baseTime = DateTime.utc(2026, 8, 17, 18);

  AgentCustomerWhatsAppIdentitySession session({
    String verificationLevel =
        AgentCustomerWhatsAppVerificationLevel.customerBound,
  }) {
    return AgentCustomerWhatsAppIdentitySession(
      sessionId: 'session-1',
      conversationId: 'conversation-A',
      senderRefHash: 'sender-hash-A',
      customerIdAlias:
          verificationLevel == AgentCustomerWhatsAppVerificationLevel.unverified
          ? ''
          : 'customer-alias-1',
      verificationLevel: verificationLevel,
      verificationEvidenceId:
          verificationLevel == AgentCustomerWhatsAppVerificationLevel.unverified
          ? ''
          : 'verification-evidence-1',
      createdAt: baseTime,
      expiresAt: baseTime.add(const Duration(hours: 1)),
    );
  }

  test(
    'session binding contains no authority/raw phone/OTP/password/provider secret',
    () {
      final AgentCustomerWhatsAppIdentitySession value = session();

      value.validate();

      expect(value.whatsappMessageGrantsAuthority, isFalse);
      expect(value.storesRawPhone, isFalse);
      expect(value.storesOtp, isFalse);
      expect(value.storesPassword, isFalse);
      expect(value.storesProviderSecret, isFalse);
    },
  );

  test('conversation and sender binding must match exactly', () {
    const AgentCustomerWhatsAppIdentityGate gate =
        AgentCustomerWhatsAppIdentityGate();

    final ok = gate.evaluate(
      session: session(),
      conversationId: 'conversation-A',
      senderRefHash: 'sender-hash-A',
      now: baseTime.add(const Duration(minutes: 10)),
      sensitiveCustomerDataRequested: false,
      businessActionRequested: false,
    );

    expect(ok.allowed, isTrue);

    final mismatch = gate.evaluate(
      session: session(),
      conversationId: 'conversation-B',
      senderRefHash: 'sender-hash-A',
      now: baseTime.add(const Duration(minutes: 10)),
      sensitiveCustomerDataRequested: false,
      businessActionRequested: false,
    );

    expect(mismatch.allowed, isFalse);
    expect(mismatch.code, 'CONVERSATION_IDENTITY_MISMATCH');
    expect(mismatch.requiresHumanEscalation, isTrue);
  });

  test('sensitive data requires sensitive verification level', () {
    const AgentCustomerWhatsAppIdentityGate gate =
        AgentCustomerWhatsAppIdentityGate();

    final customerBound = gate.evaluate(
      session: session(),
      conversationId: 'conversation-A',
      senderRefHash: 'sender-hash-A',
      now: baseTime.add(const Duration(minutes: 10)),
      sensitiveCustomerDataRequested: true,
      businessActionRequested: false,
    );

    expect(customerBound.allowed, isFalse);
    expect(customerBound.code, 'SENSITIVE_CUSTOMER_VERIFICATION_REQUIRED');

    final sensitiveVerified = gate.evaluate(
      session: session(
        verificationLevel:
            AgentCustomerWhatsAppVerificationLevel.sensitiveVerified,
      ),
      conversationId: 'conversation-A',
      senderRefHash: 'sender-hash-A',
      now: baseTime.add(const Duration(minutes: 10)),
      sensitiveCustomerDataRequested: true,
      businessActionRequested: false,
    );

    expect(sensitiveVerified.allowed, isTrue);
  });

  test('unverified WhatsApp sender cannot request business action', () {
    const AgentCustomerWhatsAppIdentityGate gate =
        AgentCustomerWhatsAppIdentityGate();

    final result = gate.evaluate(
      session: session(
        verificationLevel: AgentCustomerWhatsAppVerificationLevel.unverified,
      ),
      conversationId: 'conversation-A',
      senderRefHash: 'sender-hash-A',
      now: baseTime.add(const Duration(minutes: 10)),
      sensitiveCustomerDataRequested: false,
      businessActionRequested: true,
    );

    expect(result.allowed, isFalse);
    expect(result.code, 'CUSTOMER_BINDING_REQUIRED_FOR_ACTION');
  });

  test('expired session fails closed and requires re-verification', () {
    const AgentCustomerWhatsAppIdentityGate gate =
        AgentCustomerWhatsAppIdentityGate();

    final result = gate.evaluate(
      session: session(),
      conversationId: 'conversation-A',
      senderRefHash: 'sender-hash-A',
      now: baseTime.add(const Duration(hours: 2)),
      sensitiveCustomerDataRequested: false,
      businessActionRequested: false,
    );

    expect(result.allowed, isFalse);
    expect(result.code, 'IDENTITY_SESSION_EXPIRED');
    expect(result.requiresVerification, isTrue);
  });

  test(
    'image requires explicit workflow consent scan allowed type and size',
    () {
      const AgentCustomerWhatsAppMediaPolicy policy =
          AgentCustomerWhatsAppMediaPolicy();

      const allowed = AgentCustomerWhatsAppMediaDescriptor(
        attachmentId: 'image-1',
        kind: AgentCustomerWhatsAppMediaKind.image,
        workflowPurpose: 'ride_pickup_reference',
        userConsented: true,
        mimeType: 'image/jpeg',
        sizeBytes: 1024,
        securityScanPassed: true,
      );

      expect(policy.evaluate(allowed).allowed, isTrue);

      const noScan = AgentCustomerWhatsAppMediaDescriptor(
        attachmentId: 'image-2',
        kind: AgentCustomerWhatsAppMediaKind.image,
        workflowPurpose: 'support_evidence',
        userConsented: true,
        mimeType: 'image/jpeg',
        sizeBytes: 1024,
        securityScanPassed: false,
      );

      expect(policy.evaluate(noScan).allowed, isFalse);
      expect(policy.evaluate(noScan).code, 'SECURITY_SCAN_REQUIRED');
    },
  );

  test('executable or archive document is blocked', () {
    const AgentCustomerWhatsAppMediaPolicy policy =
        AgentCustomerWhatsAppMediaPolicy();

    const media = AgentCustomerWhatsAppMediaDescriptor(
      attachmentId: 'doc-1',
      kind: AgentCustomerWhatsAppMediaKind.document,
      workflowPurpose: 'support_document',
      userConsented: true,
      mimeType: 'application/x-msdownload',
      sizeBytes: 1024,
      securityScanPassed: true,
    );

    final decision = policy.evaluate(media);

    expect(decision.allowed, isFalse);
    expect(decision.code, 'EXECUTABLE_OR_ARCHIVE_BLOCKED');
    expect(decision.requiresHumanReview, isTrue);
  });

  test('location uses secure backend reference and no raw coordinates', () {
    const AgentCustomerWhatsAppMediaPolicy policy =
        AgentCustomerWhatsAppMediaPolicy();

    const media = AgentCustomerWhatsAppMediaDescriptor(
      attachmentId: 'location-1',
      kind: AgentCustomerWhatsAppMediaKind.location,
      workflowPurpose: 'ride_pickup',
      userConsented: true,
      locationReferenceId: 'secure-location-ref-1',
    );

    final decision = policy.evaluate(media);

    expect(decision.allowed, isTrue);
    expect(media.containsRawCoordinates, isFalse);
    expect(media.containsRawBytes, isFalse);
    expect(media.containsAuthority, isFalse);
  });

  test('provider-neutral outbound draft can never send by itself', () {
    final draft = AgentCustomerWhatsAppOutboundDraft(
      draftId: 'draft-1',
      conversationId: 'conversation-A',
      recipientRefHash: 'sender-hash-A',
      text: 'Your verified ride status is ready.',
      createdAt: baseTime,
    );

    draft.validate();

    expect(draft.maySend, isFalse);
    expect(draft.requiresTransportAuthorization, isTrue);
    expect(draft.allowsBulkBroadcast, isFalse);
    expect(draft.allowsRecipientRebinding, isFalse);
  });

  test('default disabled transport performs no network send', () async {
    const AgentCustomerWhatsAppDisabledTransport transport =
        AgentCustomerWhatsAppDisabledTransport();

    final draft = AgentCustomerWhatsAppOutboundDraft(
      draftId: 'draft-1',
      conversationId: 'conversation-A',
      recipientRefHash: 'sender-hash-A',
      text: 'Safe draft only.',
      createdAt: baseTime,
    );

    final receipt = await transport.sendDraft(draft);

    expect(transport.networkEnabled, isFalse);
    expect(transport.liveSendCapable, isFalse);
    expect(transport.providerSelected, isFalse);
    expect(transport.webhookEnabled, isFalse);
    expect(transport.inboundProviderNetworkEnabled, isFalse);
    expect(transport.outboundProviderNetworkEnabled, isFalse);

    expect(receipt.status, AgentCustomerWhatsAppTransportStatus.disabled);
    expect(receipt.providerMessageId, isEmpty);
  });

  test('inbound WhatsApp envelope is data, never authority', () {
    final envelope = AgentCustomerWhatsAppInboundEnvelope(
      messageId: 'message-1',
      conversationId: 'conversation-A',
      senderRefHash: 'sender-hash-A',
      text: 'Meri ride status kya hai?',
      media: const <AgentCustomerWhatsAppMediaDescriptor>[],
      receivedAt: baseTime,
    );

    envelope.validate();

    expect(envelope.grantsAuthority, isFalse);
    expect(envelope.containsRawPhone, isFalse);
    expect(envelope.containsProviderSecret, isFalse);
  });
}
