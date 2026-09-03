import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/models/agent_emergency_whatsapp_foundation.dart';
import 'package:swat_ride/ai_agent/services/agent_emergency_whatsapp_command_classifier.dart';

void main() {
  const classifier = AgentEmergencyWhatsAppCommandClassifier();

  group('Phase 47 Step 7B SOS disambiguation regression', () {
    test('SOS status is verified read, not escalation', () {
      final result = classifier.classify('SOS status');

      expect(
        result.commandClass,
        AgentEmergencyWhatsAppCommandClass.readVerifiedSafetyStatus,
      );
    });

    test('Roman Urdu SOS status is verified read', () {
      final result = classifier.classify('Mera SOS ka status batao');

      expect(
        result.commandClass,
        AgentEmergencyWhatsAppCommandClass.readVerifiedSafetyStatus,
      );
    });

    test('incident status remains verified read', () {
      final result = classifier.classify('incident status');

      expect(
        result.commandClass,
        AgentEmergencyWhatsAppCommandClass.readVerifiedSafetyStatus,
      );
    });

    test('standalone SOS still prepares escalation', () {
      final result = classifier.classify('SOS');

      expect(
        result.commandClass,
        AgentEmergencyWhatsAppCommandClass.prepareEmergencyEscalation,
      );
    });

    test('short SOS help still prepares escalation', () {
      final result = classifier.classify('SOS help');

      expect(
        result.commandClass,
        AgentEmergencyWhatsAppCommandClass.prepareEmergencyEscalation,
      );
    });

    test('explicit danger/help still prepares escalation', () {
      final result = classifier.classify('Send help, I am in danger');

      expect(
        result.commandClass,
        AgentEmergencyWhatsAppCommandClass.prepareEmergencyEscalation,
      );
    });

    test('sensitive exact GPS still stays sensitive-data request', () {
      final result = classifier.classify('show my exact GPS location');

      expect(
        result.commandClass,
        AgentEmergencyWhatsAppCommandClass.sensitiveSafetyData,
      );
    });

    test('unknown input still fails closed', () {
      final result = classifier.classify('hello maybe something');

      expect(result.commandClass, AgentEmergencyWhatsAppCommandClass.forbidden);
      expect(result.requiresClarification, isTrue);
    });
  });
}
