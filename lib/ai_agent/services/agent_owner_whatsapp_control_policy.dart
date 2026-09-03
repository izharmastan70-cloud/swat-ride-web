class AgentOwnerWhatsAppControlDecision {
  const AgentOwnerWhatsAppControlDecision({
    required this.allowed,
    required this.reason,
  });

  final bool allowed;
  final String reason;
}

class AgentOwnerWhatsAppControlPolicy {
  const AgentOwnerWhatsAppControlPolicy();

  static const Set<String> controlPlaneRoles = <String>{'admin', 'super_admin'};

  static const bool whatsappMessageIsAuthority = false;
  static const bool phoneNumberMatchAloneIsAuthority = false;
  static const bool permissionEngineRequiredForActions = true;
  static const bool approvalEngineRequiredForConsequentialActions = true;
  static const bool runtimeGateRequiredForActions = true;
  static const bool auditRequiredForAuthorizedActions = true;
  static const bool customerPrivilegeInheritanceAllowed = false;
  static const bool emergencyWhatsappAuthorityIncluded = false;
  static const bool providerHardCodingAllowed = false;
  static const bool liveTransportEnabledByDefault = false;
  static const bool directBusinessExecutionAllowed = false;
  static const bool deployAllowed = false;

  AgentOwnerWhatsAppControlDecision authorizeMasterToggle({
    required String actorRole,
  }) {
    final String normalized = actorRole.trim().toLowerCase();

    if (controlPlaneRoles.contains(normalized)) {
      return const AgentOwnerWhatsAppControlDecision(
        allowed: true,
        reason:
            'Admin/Super Admin may control the Owner WhatsApp Agent switch.',
      );
    }

    return const AgentOwnerWhatsAppControlDecision(
      allowed: false,
      reason:
          'Only Admin or Super Admin may control the Owner WhatsApp Agent switch.',
    );
  }
}
