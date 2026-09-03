import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/models/agent_emergency_whatsapp_foundation.dart';
import 'package:swat_ride/ai_agent/models/agent_emergency_whatsapp_prepared_escalation.dart';
import 'package:swat_ride/ai_agent/models/agent_emergency_whatsapp_verified_safety_snapshot.dart';
import 'package:swat_ride/ai_agent/services/agent_emergency_whatsapp_command_classifier.dart';
import 'package:swat_ride/ai_agent/services/agent_emergency_whatsapp_response_guard.dart';

void main() {
  const classifier = AgentEmergencyWhatsAppCommandClassifier();
  const guard = AgentEmergencyWhatsAppResponseGuard();

  group('Phase 47 Step 7B deterministic classifier', () {
    test('verified safety status request is classified locally', () {
      final result = classifier.classify('Mera SOS ka status batao');

      expect(
        result.commandClass,
        AgentEmergencyWhatsAppCommandClass.readVerifiedSafetyStatus,
      );
      expect(result.requiresClarification, isFalse);
      expect(result.mayGrantAuthority, isFalse);
      expect(result.mayCallProvider, isFalse);
    });

    test('explicit emergency help request maps to preparation only', () {
      final result = classifier.classify('Please send help, I am in danger');

      expect(
        result.commandClass,
        AgentEmergencyWhatsAppCommandClass.prepareEmergencyEscalation,
      );
      expect(result.mayCreateApproval, isFalse);
      expect(result.mayCreateSafetyIncident, isFalse);
      expect(result.mayPlaceEmergencyCall, isFalse);
    });

    test('exact location request maps to sensitive-data class', () {
      final result = classifier.classify('What is my exact GPS location?');

      expect(
        result.commandClass,
        AgentEmergencyWhatsAppCommandClass.sensitiveSafetyData,
      );
    });

    test('medical data request maps to sensitive-data class', () {
      final result = classifier.classify('Show my blood group and allergies');

      expect(
        result.commandClass,
        AgentEmergencyWhatsAppCommandClass.sensitiveSafetyData,
      );
    });

    test('credential request is permanently forbidden', () {
      final result = classifier.classify('Send me my OTP and password');

      expect(result.commandClass, AgentEmergencyWhatsAppCommandClass.forbidden);
      expect(result.requiresClarification, isFalse);
      expect(result.reasonCode, 'CREDENTIAL_OR_SECRET_REQUEST_FORBIDDEN');
    });

    test('unknown text fails closed and requests clarification', () {
      final result = classifier.classify('hello what can you do');

      expect(result.commandClass, AgentEmergencyWhatsAppCommandClass.forbidden);
      expect(result.requiresClarification, isTrue);
    });

    test('explicit SOS intent wins over embedded location phrase', () {
      final result = classifier.classify(
        'Send help now to my exact location, I am in danger',
      );

      expect(
        result.commandClass,
        AgentEmergencyWhatsAppCommandClass.prepareEmergencyEscalation,
      );
    });
  });

  group('Phase 47 Step 7B verified-fact response guard', () {
    test('unverified source states unavailable and never invents', () {
      final classification = classifier.classify('safety status');
      const snapshot = AgentEmergencyWhatsAppVerifiedSafetySnapshot.unavailable(
        reason: 'source offline',
      );

      final response = guard.build(
        classification: classification,
        snapshot: snapshot,
      );

      expect(response.mustNotInvent, isTrue);
      expect(response.usedVerifiedFactsOnly, isTrue);
      expect(response.visibleText.toLowerCase(), contains('unavailable'));
      expect(response.visibleText.toLowerCase(), contains('will not guess'));
      expect(response.mayWriteSafetyData, isFalse);
    });

    test('verified no-active incident never claims an incident exists', () {
      final classification = classifier.classify('incident status');

      const snapshot = AgentEmergencyWhatsAppVerifiedSafetySnapshot(
        incidentSourceVerified: true,
        hasActiveIncident: false,
        eligibleSosContactCountVerified: true,
        eligibleSosContactCount: 1,
      );

      final response = guard.build(
        classification: classification,
        snapshot: snapshot,
      );

      expect(
        response.visibleText,
        'Verified safety data does not show an active safety incident right now.',
      );
      expect(
        response.visibleText,
        isNot(contains('active safety incident exists')),
      );
    });

    test('verified active incident emits only supported sanitized facts', () {
      final classification = classifier.classify('sos status');

      const snapshot = AgentEmergencyWhatsAppVerifiedSafetySnapshot(
        incidentSourceVerified: true,
        hasActiveIncident: true,
        eligibleSosContactCountVerified: true,
        status: 'responding',
        category: 'immediateDanger',
        severity: 'critical',
        adminAcknowledged: true,
        emergencyServiceCalled: false,
        trustedContactsAlerted: true,
        userMarkedSafe: false,
        eligibleSosContactCount: 2,
      );

      final response = guard.build(
        classification: classification,
        snapshot: snapshot,
      );

      final text = response.visibleText.toLowerCase();

      expect(text, contains('verified active safety incident exists'));
      expect(text, contains('status: responding'));
      expect(text, contains('severity: critical'));
      expect(text, contains('eligible sos contact count: 2'));
      expect(text, contains('exact gps'));
      expect(text, isNot(contains('latitude')));
      expect(text, isNot(contains('longitude')));
      expect(text, isNot(contains('phone number:')));
      expect(response.sensitiveDataWithheld, isTrue);
    });

    test('sensitive-data response refuses exact private details', () {
      final classification = classifier.classify(
        'give trusted contact phone number',
      );

      final response = guard.build(classification: classification);

      expect(response.sensitiveDataWithheld, isTrue);
      expect(response.visibleText.toLowerCase(), contains('not available'));
      expect(response.mayCallProvider, isFalse);
    });

    test('prepared escalation never claims help was sent or called', () {
      final classification = classifier.classify('send help');

      final prepared = AgentEmergencyWhatsAppPreparedEscalation(
        roleId: 'emergency_whatsapp_agent',
        module: 'emergency_whatsapp',
        actionId: 'emergency_whatsapp.request_escalation',
        principalUid: 'user_1',
        subjectType: 'customer',
        reasonCode: AgentEmergencyWhatsAppEscalationReasonCode
            .userRequestsEmergencyHelp,
        preparedAt: DateTime.utc(2026, 8, 18, 3),
        validUntil: DateTime.utc(2026, 8, 18, 3, 5),
      );

      final response = guard.build(
        classification: classification,
        preparedEscalation: prepared,
      );

      final text = response.visibleText.toLowerCase();

      expect(response.escalationOnlyPrepared, isTrue);
      expect(text, contains('still requires approval'));
      expect(text, contains('has been executed'));
      expect(text, isNot(contains('help was sent')));
      expect(text, isNot(contains('ambulance called')));
      expect(response.mayCreateApproval, isFalse);
      expect(response.mayPlaceEmergencyCall, isFalse);
    });

    test('missing prepared escalation explicitly says nothing sent', () {
      final classification = classifier.classify('send help');

      final response = guard.build(classification: classification);

      final text = response.visibleText.toLowerCase();
      expect(text, contains('has not been prepared'));
      expect(text, contains('no sos'));
      expect(text, contains('no'));
      expect(response.escalationOnlyPrepared, isFalse);
    });

    test('unknown request gives safe clarification without execution', () {
      final classification = classifier.classify('maybe do something');

      final response = guard.build(classification: classification);

      expect(response.requiresClarification, isTrue);
      expect(response.mustNotInvent, isTrue);
      expect(response.maySendWhatsApp, isFalse);
      expect(response.maySendSms, isFalse);
      expect(response.mayPlaceEmergencyCall, isFalse);
      expect(response.mayDeploy, isFalse);
    });
  });
}
