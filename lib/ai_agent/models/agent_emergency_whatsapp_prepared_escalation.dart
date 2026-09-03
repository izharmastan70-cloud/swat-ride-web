class AgentEmergencyWhatsAppEscalationReasonCode {
  AgentEmergencyWhatsAppEscalationReasonCode._();

  static const String userRequestsEmergencyHelp =
      'USER_REQUESTS_EMERGENCY_HELP';
  static const String activeSafetyIncidentNeedsHumanReview =
      'ACTIVE_SAFETY_INCIDENT_NEEDS_HUMAN_REVIEW';
  static const String unableToConfirmSafety = 'UNABLE_TO_CONFIRM_SAFETY';
  static const String otherEmergencyConcern = 'OTHER_EMERGENCY_CONCERN';

  static const Set<String> values = <String>{
    userRequestsEmergencyHelp,
    activeSafetyIncidentNeedsHumanReview,
    unableToConfirmSafety,
    otherEmergencyConcern,
  };

  static bool isValid(String value) => values.contains(value);
}

/// Non-persisted preparation object only.
///
/// This is NOT an approval, NOT an SOS incident, NOT a provider handoff and
/// NOT execution authority. A trusted future server boundary must separately
/// provide inbound signature/replay/idempotency before a persistent approval
/// request may be created from Emergency WhatsApp.
class AgentEmergencyWhatsAppPreparedEscalation {
  const AgentEmergencyWhatsAppPreparedEscalation({
    required this.roleId,
    required this.module,
    required this.actionId,
    required this.principalUid,
    required this.subjectType,
    required this.reasonCode,
    required this.preparedAt,
    required this.validUntil,
  });

  final String roleId;
  final String module;
  final String actionId;
  final String principalUid;
  final String subjectType;
  final String reasonCode;
  final DateTime preparedAt;
  final DateTime validUntil;

  bool isValidAt(DateTime now) =>
      !preparedAt.isAfter(now) &&
      validUntil.isAfter(preparedAt) &&
      !validUntil.isBefore(now);

  /// Deliberately omitted sensitive / transport fields.
  bool get rawMessageIncluded => false;
  bool get rawPhoneIncluded => false;
  bool get conversationIdIncluded => false;
  bool get senderBindingIdIncluded => false;
  bool get sessionIdIncluded => false;
  bool get exactLocationIncluded => false;
  bool get trustedContactDetailsIncluded => false;
  bool get medicalProfileIncluded => false;
  bool get incidentIdIncluded => false;
  bool get referenceIdIncluded => false;

  /// Deliberately no authority.
  bool get persistentApprovalCreated => false;
  bool get approvalConsumed => false;
  bool get safetyIncidentCreated => false;
  bool get safetyIncidentMutated => false;
  bool get safetyAlertSent => false;
  bool get whatsappSent => false;
  bool get smsSent => false;
  bool get emergencyCallPlaced => false;
  bool get providerCalled => false;
  bool get liveWebhookHandled => false;
  bool get deploymentTriggered => false;

  Map<String, dynamic> toSafeMap() {
    return <String, dynamic>{
      'roleId': roleId,
      'module': module,
      'actionId': actionId,
      'principalUid': principalUid,
      'subjectType': subjectType,
      'reasonCode': reasonCode,
      'preparedAt': preparedAt.toUtc().toIso8601String(),
      'validUntil': validUntil.toUtc().toIso8601String(),
      'persistentApprovalCreated': false,
      'approvalConsumed': false,
      'safetyIncidentCreated': false,
      'safetyAlertSent': false,
      'whatsappSent': false,
      'smsSent': false,
      'emergencyCallPlaced': false,
      'providerCalled': false,
      'deploymentTriggered': false,
    };
  }
}
