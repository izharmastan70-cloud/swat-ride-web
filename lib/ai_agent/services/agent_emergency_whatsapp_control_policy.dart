class AgentEmergencyWhatsAppControlDecision {
  const AgentEmergencyWhatsAppControlDecision._({
    required this.allowed,
    required this.reason,
  });

  const AgentEmergencyWhatsAppControlDecision.allow(String reason)
    : this._(allowed: true, reason: reason);

  const AgentEmergencyWhatsAppControlDecision.deny(String reason)
    : this._(allowed: false, reason: reason);

  final bool allowed;
  final String reason;

  bool get providerTransportChanged => false;
  bool get customerWhatsAppAuthorityChanged => false;
  bool get ownerWhatsAppAuthorityChanged => false;
  bool get universalSafetyAvailabilityChanged => false;
}

class AgentEmergencyWhatsAppControlPolicy {
  const AgentEmergencyWhatsAppControlPolicy();

  AgentEmergencyWhatsAppControlDecision authorizeMasterToggle({
    required String actorRole,
  }) {
    final String normalized = actorRole.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '',
    );

    if (normalized == 'admin' || normalized == 'superadmin') {
      return const AgentEmergencyWhatsAppControlDecision.allow(
        'Admin/Super Admin may change only the Emergency WhatsApp Agent switch.',
      );
    }

    return const AgentEmergencyWhatsAppControlDecision.deny(
      'Only Admin or Super Admin may change the Emergency WhatsApp Agent switch.',
    );
  }
}
