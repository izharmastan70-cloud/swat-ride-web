class AgentEmergencyWhatsAppVerifiedSafetySnapshot {
  const AgentEmergencyWhatsAppVerifiedSafetySnapshot({
    required this.incidentSourceVerified,
    required this.hasActiveIncident,
    required this.eligibleSosContactCountVerified,
    this.status,
    this.category,
    this.severity,
    this.serviceType,
    this.initiatedByRole,
    this.locationStatus,
    this.adminAcknowledged,
    this.emergencyServiceCalled,
    this.trustedContactsAlerted,
    this.userMarkedSafe,
    this.isTestIncident,
    this.createdAt,
    this.updatedAt,
    this.eligibleSosContactCount,
    this.unavailableReason = '',
  });

  const AgentEmergencyWhatsAppVerifiedSafetySnapshot.unavailable({
    required String reason,
  }) : incidentSourceVerified = false,
       hasActiveIncident = false,
       eligibleSosContactCountVerified = false,
       status = null,
       category = null,
       severity = null,
       serviceType = null,
       initiatedByRole = null,
       locationStatus = null,
       adminAcknowledged = null,
       emergencyServiceCalled = null,
       trustedContactsAlerted = null,
       userMarkedSafe = null,
       isTestIncident = null,
       createdAt = null,
       updatedAt = null,
       eligibleSosContactCount = null,
       unavailableReason = reason;

  final bool incidentSourceVerified;
  final bool hasActiveIncident;

  final String? status;
  final String? category;
  final String? severity;
  final String? serviceType;
  final String? initiatedByRole;
  final String? locationStatus;

  final bool? adminAcknowledged;
  final bool? emergencyServiceCalled;
  final bool? trustedContactsAlerted;
  final bool? userMarkedSafe;
  final bool? isTestIncident;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  final bool eligibleSosContactCountVerified;
  final int? eligibleSosContactCount;

  final String unavailableReason;

  /// Deliberate privacy denials.
  bool get exactLocationIncluded => false;
  bool get locationHistoryIncluded => false;
  bool get personNameIncluded => false;
  bool get personPhoneIncluded => false;
  bool get vehicleIdentityIncluded => false;
  bool get incidentDescriptionIncluded => false;
  bool get referenceIdIncluded => false;
  bool get incidentIdIncluded => false;
  bool get adminIdentityIncluded => false;
  bool get assignedSafetyAgentIdentityIncluded => false;
  bool get adminNotesIncluded => false;
  bool get evidenceReferencesIncluded => false;
  bool get rawMetadataIncluded => false;
  bool get medicalProfileIncluded => false;
  bool get trustedContactNamesIncluded => false;
  bool get trustedContactPhonesIncluded => false;
  bool get silentSosFlagIncluded => false;

  Map<String, dynamic> toSafeMap() {
    return <String, dynamic>{
      'incidentSourceVerified': incidentSourceVerified,
      'hasActiveIncident': hasActiveIncident,
      'status': status,
      'category': category,
      'severity': severity,
      'serviceType': serviceType,
      'initiatedByRole': initiatedByRole,
      'locationStatus': locationStatus,
      'adminAcknowledged': adminAcknowledged,
      'emergencyServiceCalled': emergencyServiceCalled,
      'trustedContactsAlerted': trustedContactsAlerted,
      'userMarkedSafe': userMarkedSafe,
      'isTestIncident': isTestIncident,
      'createdAt': createdAt?.toUtc().toIso8601String(),
      'updatedAt': updatedAt?.toUtc().toIso8601String(),
      'eligibleSosContactCountVerified': eligibleSosContactCountVerified,
      'eligibleSosContactCount': eligibleSosContactCount,
      'unavailableReason': unavailableReason,
      'exactLocationIncluded': false,
      'personPhoneIncluded': false,
      'medicalProfileIncluded': false,
      'trustedContactPhonesIncluded': false,
      'businessMutationAuthorized': false,
      'externalSendAuthorized': false,
      'emergencyCallAuthorized': false,
      'providerCallAuthorized': false,
      'deploymentAuthorized': false,
    };
  }
}
