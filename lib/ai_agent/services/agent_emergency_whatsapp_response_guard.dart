import '../models/agent_emergency_whatsapp_foundation.dart';
import '../models/agent_emergency_whatsapp_prepared_escalation.dart';
import '../models/agent_emergency_whatsapp_verified_safety_snapshot.dart';
import 'agent_emergency_whatsapp_command_classifier.dart';

class AgentEmergencyWhatsAppSafeResponse {
  const AgentEmergencyWhatsAppSafeResponse({
    required this.visibleText,
    required this.usedVerifiedFactsOnly,
    required this.mustNotInvent,
    required this.requiresClarification,
    required this.sensitiveDataWithheld,
    required this.escalationOnlyPrepared,
  });

  final String visibleText;
  final bool usedVerifiedFactsOnly;
  final bool mustNotInvent;
  final bool requiresClarification;
  final bool sensitiveDataWithheld;
  final bool escalationOnlyPrepared;

  bool get mayGrantAuthority => false;
  bool get mayCreateApproval => false;
  bool get mayConsumeApproval => false;
  bool get mayWriteSafetyData => false;
  bool get maySendWhatsApp => false;
  bool get maySendSms => false;
  bool get mayPlaceEmergencyCall => false;
  bool get mayCallProvider => false;
  bool get mayDeploy => false;
}

class AgentEmergencyWhatsAppResponseGuard {
  const AgentEmergencyWhatsAppResponseGuard();

  AgentEmergencyWhatsAppSafeResponse build({
    required AgentEmergencyWhatsAppCommandClassification classification,
    AgentEmergencyWhatsAppVerifiedSafetySnapshot? snapshot,
    AgentEmergencyWhatsAppPreparedEscalation? preparedEscalation,
  }) {
    switch (classification.commandClass) {
      case AgentEmergencyWhatsAppCommandClass.readVerifiedSafetyStatus:
        return _verifiedStatusResponse(snapshot);

      case AgentEmergencyWhatsAppCommandClass.prepareEmergencyEscalation:
        return _escalationResponse(preparedEscalation);

      case AgentEmergencyWhatsAppCommandClass.sensitiveSafetyData:
        return const AgentEmergencyWhatsAppSafeResponse(
          visibleText:
              'Requested exact location, trusted-contact phone or medical data is not available through this Emergency WhatsApp safety boundary.',
          usedVerifiedFactsOnly: true,
          mustNotInvent: true,
          requiresClarification: false,
          sensitiveDataWithheld: true,
          escalationOnlyPrepared: false,
        );

      case AgentEmergencyWhatsAppCommandClass.forbidden:
        return AgentEmergencyWhatsAppSafeResponse(
          visibleText: classification.requiresClarification
              ? 'I cannot safely determine that emergency command from the message. Please ask for verified safety status or clearly request emergency help.'
              : 'That request is not allowed through the Emergency WhatsApp safety boundary.',
          usedVerifiedFactsOnly: true,
          mustNotInvent: true,
          requiresClarification: classification.requiresClarification,
          sensitiveDataWithheld: false,
          escalationOnlyPrepared: false,
        );
    }
  }

  AgentEmergencyWhatsAppSafeResponse _verifiedStatusResponse(
    AgentEmergencyWhatsAppVerifiedSafetySnapshot? snapshot,
  ) {
    if (snapshot == null || !snapshot.incidentSourceVerified) {
      return const AgentEmergencyWhatsAppSafeResponse(
        visibleText:
            'Verified safety status is currently unavailable. I will not guess the incident status, severity or contact-alert state.',
        usedVerifiedFactsOnly: true,
        mustNotInvent: true,
        requiresClarification: false,
        sensitiveDataWithheld: false,
        escalationOnlyPrepared: false,
      );
    }

    if (!snapshot.hasActiveIncident) {
      return const AgentEmergencyWhatsAppSafeResponse(
        visibleText:
            'Verified safety data does not show an active safety incident right now.',
        usedVerifiedFactsOnly: true,
        mustNotInvent: true,
        requiresClarification: false,
        sensitiveDataWithheld: false,
        escalationOnlyPrepared: false,
      );
    }

    final List<String> facts = <String>[
      'A verified active safety incident exists.',
    ];

    if (snapshot.status != null && snapshot.status!.trim().isNotEmpty) {
      facts.add('Status: ${snapshot.status!.trim()}.');
    }

    if (snapshot.severity != null && snapshot.severity!.trim().isNotEmpty) {
      facts.add('Severity: ${snapshot.severity!.trim()}.');
    }

    if (snapshot.category != null && snapshot.category!.trim().isNotEmpty) {
      facts.add('Category: ${snapshot.category!.trim()}.');
    }

    if (snapshot.adminAcknowledged != null) {
      facts.add(
        snapshot.adminAcknowledged!
            ? 'Admin acknowledgment is verified.'
            : 'Admin acknowledgment is not verified yet.',
      );
    }

    if (snapshot.emergencyServiceCalled != null) {
      facts.add(
        snapshot.emergencyServiceCalled!
            ? 'Emergency-service call flag is verified as true.'
            : 'Emergency-service call flag is verified as false.',
      );
    }

    if (snapshot.trustedContactsAlerted != null) {
      facts.add(
        snapshot.trustedContactsAlerted!
            ? 'Trusted-contact alert flag is verified as true.'
            : 'Trusted-contact alert flag is verified as false.',
      );
    }

    if (snapshot.userMarkedSafe != null) {
      facts.add(
        snapshot.userMarkedSafe!
            ? 'User-safe flag is verified as true.'
            : 'User-safe flag is verified as false.',
      );
    }

    if (snapshot.eligibleSosContactCountVerified &&
        snapshot.eligibleSosContactCount != null) {
      facts.add(
        'Eligible SOS contact count: ${snapshot.eligibleSosContactCount}.',
      );
    }

    facts.add(
      'Exact GPS, phone numbers and medical details are withheld by this privacy boundary.',
    );

    return AgentEmergencyWhatsAppSafeResponse(
      visibleText: facts.join(' '),
      usedVerifiedFactsOnly: true,
      mustNotInvent: true,
      requiresClarification: false,
      sensitiveDataWithheld: true,
      escalationOnlyPrepared: false,
    );
  }

  AgentEmergencyWhatsAppSafeResponse _escalationResponse(
    AgentEmergencyWhatsAppPreparedEscalation? prepared,
  ) {
    if (prepared == null) {
      return const AgentEmergencyWhatsAppSafeResponse(
        visibleText:
            'Emergency escalation has not been prepared. No SOS, message, SMS or call has been sent.',
        usedVerifiedFactsOnly: true,
        mustNotInvent: true,
        requiresClarification: false,
        sensitiveDataWithheld: false,
        escalationOnlyPrepared: false,
      );
    }

    return const AgentEmergencyWhatsAppSafeResponse(
      visibleText:
          'Emergency escalation is prepared and still requires approval. No SOS mutation, WhatsApp/SMS message, provider request or emergency call has been executed.',
      usedVerifiedFactsOnly: true,
      mustNotInvent: true,
      requiresClarification: false,
      sensitiveDataWithheld: false,
      escalationOnlyPrepared: true,
    );
  }
}
