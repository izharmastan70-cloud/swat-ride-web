import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/models/agent_emergency_whatsapp_foundation.dart';

void main() {
  group('Phase 47 Emergency WhatsApp security foundation', () {
    test('role is isolated and no message/phone grants authority', () {
      const foundation = AgentEmergencyWhatsAppFoundation();

      expect(
        AgentEmergencyWhatsAppFoundation.roleId,
        'emergency_whatsapp_agent',
      );
      expect(AgentEmergencyWhatsAppFoundation.module, 'emergency_whatsapp');
      expect(foundation.messageGrantsAuthority, isFalse);
      expect(foundation.phoneNumberMatchAloneIsAuthority, isFalse);
      expect(foundation.customerWhatsAppAuthorityInherited, isFalse);
      expect(foundation.ownerWhatsAppAuthorityInherited, isFalse);
      expect(foundation.emergencyAuthorityGrantedToOtherWhatsAppRoles, isFalse);
    });

    test('WhatsApp cannot directly mutate Universal Safety', () {
      const foundation = AgentEmergencyWhatsAppFoundation();

      expect(foundation.arbitrarySafetyFirestoreAccessAllowed, isFalse);
      expect(foundation.mayCreateSafetyIncidentFromMessage, isFalse);
      expect(foundation.mayAcknowledgeIncident, isFalse);
      expect(foundation.mayAssignSafetyAgent, isFalse);
      expect(foundation.mayResolveIncident, isFalse);
      expect(foundation.mayMarkUserSafe, isFalse);
      expect(foundation.mayUpdateEmergencyLocation, isFalse);
      expect(foundation.mayModifyTrustedContacts, isFalse);
    });

    test('sensitive emergency data is default deny', () {
      const foundation = AgentEmergencyWhatsAppFoundation();
      const scope = AgentEmergencyWhatsAppSensitiveDataScope();

      expect(foundation.mayExposeExactGpsByDefault, isFalse);
      expect(foundation.mayExposeTrustedContactPhoneByDefault, isFalse);
      expect(foundation.mayExposeMedicalProfileByDefault, isFalse);
      expect(scope.anySensitiveDataAllowed, isFalse);
    });

    test('verified safety status requires account verified identity', () {
      const policy =
          AgentEmergencyWhatsAppCommandPolicy.readVerifiedSafetyStatus();

      expect(
        policy.commandClass,
        AgentEmergencyWhatsAppCommandClass.readVerifiedSafetyStatus,
      );
      expect(policy.requiresAccountVerifiedIdentity, isTrue);
      expect(policy.requiresPermissionEngine, isTrue);
      expect(policy.requiresRuntimeGate, isTrue);
      expect(policy.requiresApprovalEngine, isFalse);
      expect(policy.requiresAudit, isTrue);
      expect(policy.requiresExplicitSensitiveDataScope, isFalse);
      expect(policy.mayExecuteDirectly, isFalse);
    });

    test('emergency escalation preserves existing approval boundary', () {
      const policy =
          AgentEmergencyWhatsAppCommandPolicy.prepareEmergencyEscalation();

      expect(
        policy.commandClass,
        AgentEmergencyWhatsAppCommandClass.prepareEmergencyEscalation,
      );
      expect(policy.requiresAccountVerifiedIdentity, isTrue);
      expect(policy.requiresPermissionEngine, isTrue);
      expect(policy.requiresRuntimeGate, isTrue);
      expect(policy.requiresApprovalEngine, isTrue);
      expect(policy.requiresAudit, isTrue);
      expect(policy.mayExecuteDirectly, isFalse);
      expect(policy.maySendExternalAlert, isFalse);
      expect(policy.mayPlaceEmergencyCall, isFalse);
    });

    test('sensitive data requires explicit scope plus central gates', () {
      const policy = AgentEmergencyWhatsAppCommandPolicy.sensitiveSafetyData();

      expect(
        policy.commandClass,
        AgentEmergencyWhatsAppCommandClass.sensitiveSafetyData,
      );
      expect(policy.requiresAccountVerifiedIdentity, isTrue);
      expect(policy.requiresPermissionEngine, isTrue);
      expect(policy.requiresRuntimeGate, isTrue);
      expect(policy.requiresAudit, isTrue);
      expect(policy.requiresExplicitSensitiveDataScope, isTrue);
      expect(policy.mayExecuteDirectly, isFalse);
    });

    test('unknown command fails closed', () {
      const foundation = AgentEmergencyWhatsAppFoundation();

      final policy = foundation.policyFor(
        readsVerifiedSafetyStatus: false,
        preparesEmergencyEscalation: false,
        requestsSensitiveSafetyData: false,
        permanentlyForbidden: false,
      );

      expect(policy.commandClass, AgentEmergencyWhatsAppCommandClass.forbidden);
      expect(policy.requiresApprovalEngine, isTrue);
      expect(policy.mayExecuteDirectly, isFalse);
    });

    test('account verified exact channel can read verified safety data', () {
      final now = DateTime.utc(2026, 8, 18, 0, 0);
      final binding = AgentEmergencyWhatsAppSessionBinding(
        subjectType: AgentEmergencyWhatsAppSubjectType.customer,
        principalUid: 'user_1',
        conversationId: 'conversation_1',
        senderBindingId: 'sender_binding_1',
        sessionId: 'session_1',
        verificationLevel:
            AgentEmergencyWhatsAppVerificationLevel.accountVerified,
        verifiedAt: now.subtract(const Duration(minutes: 1)),
        expiresAt: now.add(const Duration(minutes: 10)),
      );

      expect(
        binding.canReadVerifiedSafetyData(
          now: now,
          expectedConversationId: 'conversation_1',
          expectedSenderBindingId: 'sender_binding_1',
          expectedSessionId: 'session_1',
        ),
        isTrue,
      );
    });

    test('channel-bound-only identity cannot read verified incident data', () {
      final now = DateTime.utc(2026, 8, 18, 0, 0);
      final binding = AgentEmergencyWhatsAppSessionBinding(
        subjectType: AgentEmergencyWhatsAppSubjectType.customer,
        principalUid: 'user_1',
        conversationId: 'conversation_1',
        senderBindingId: 'sender_binding_1',
        sessionId: 'session_1',
        verificationLevel: AgentEmergencyWhatsAppVerificationLevel.channelBound,
        verifiedAt: now.subtract(const Duration(minutes: 1)),
        expiresAt: now.add(const Duration(minutes: 10)),
      );

      expect(
        binding.canReadVerifiedSafetyData(
          now: now,
          expectedConversationId: 'conversation_1',
          expectedSenderBindingId: 'sender_binding_1',
          expectedSessionId: 'session_1',
        ),
        isFalse,
      );
    });

    test('exact channel mismatch fails closed', () {
      final now = DateTime.utc(2026, 8, 18, 0, 0);
      final binding = AgentEmergencyWhatsAppSessionBinding(
        subjectType: AgentEmergencyWhatsAppSubjectType.provider,
        principalUid: 'driver_1',
        conversationId: 'conversation_1',
        senderBindingId: 'sender_binding_1',
        sessionId: 'session_1',
        verificationLevel:
            AgentEmergencyWhatsAppVerificationLevel.accountVerified,
        verifiedAt: now.subtract(const Duration(minutes: 1)),
        expiresAt: now.add(const Duration(minutes: 10)),
      );

      expect(
        binding.canReadVerifiedSafetyData(
          now: now,
          expectedConversationId: 'wrong_conversation',
          expectedSenderBindingId: 'sender_binding_1',
          expectedSessionId: 'session_1',
        ),
        isFalse,
      );
    });

    test('transport and external emergency actions remain disabled', () {
      const foundation = AgentEmergencyWhatsAppFoundation();

      expect(foundation.maySendWhatsApp, isFalse);
      expect(foundation.mayPlaceEmergencyCall, isFalse);
      expect(foundation.maySendSms, isFalse);
      expect(foundation.mayCallProvider, isFalse);
      expect(foundation.mayHandleLiveWebhook, isFalse);
      expect(foundation.mayDeploy, isFalse);
    });

    test('credential-like fields are blocked', () {
      const foundation = AgentEmergencyWhatsAppFoundation();

      for (final key in <String>[
        'otp',
        'password',
        'passcode',
        'PIN',
        'cvv',
        'card_number',
        'access_token',
        'api-key',
        'secret',
        'private_key',
        'Authorization',
        'cookie',
      ]) {
        expect(foundation.isReservedCredentialField(key), isTrue, reason: key);
      }

      expect(foundation.isReservedCredentialField('incidentId'), isFalse);
      expect(foundation.isReservedCredentialField('serviceType'), isFalse);
    });
  });
}
