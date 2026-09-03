class AgentVoiceSuperAdminCapabilityStatus {
  AgentVoiceSuperAdminCapabilityStatus._();

  static const String verifiedAvailable = 'VERIFIED_AVAILABLE';
  static const String unavailable = 'UNAVAILABLE';
  static const String notConnected = 'NOT_CONNECTED';

  static const Set<String> values = <String>{
    verifiedAvailable,
    unavailable,
    notConnected,
  };

  static bool isValid(String value) => values.contains(value);
}

class AgentVoiceSuperAdminModule {
  AgentVoiceSuperAdminModule._();

  static const String normalRide = 'NORMAL_RIDE';
  static const String driver = 'DRIVER';
  static const String food = 'FOOD';
  static const String restaurant = 'RESTAURANT';
  static const String hotel = 'HOTEL';
  static const String tour = 'TOUR';
  static const String cargo = 'CARGO';
  static const String parcel = 'PARCEL';
  static const String studentRide = 'STUDENT_RIDE';
  static const String finance = 'FINANCE';
  static const String applications = 'APPLICATIONS';
  static const String complaintsSupport = 'COMPLAINTS_SUPPORT';
  static const String safetySos = 'SAFETY_SOS';
  static const String aiHealth = 'AI_HEALTH';
  static const String aiUsageCost = 'AI_USAGE_COST';
  static const String securityAudit = 'SECURITY_AUDIT';
  static const String systemHealth = 'SYSTEM_HEALTH';
  static const String ownerPeriodicSummary = 'OWNER_PERIODIC_SUMMARY';
}

class AgentVoiceSuperAdminModuleCapability {
  const AgentVoiceSuperAdminModuleCapability({
    required this.moduleId,
    required this.status,
    required this.evidenceSource,
    required this.note,
  });

  final String moduleId;
  final String status;
  final String evidenceSource;
  final String note;

  bool get isVerifiedAvailable =>
      status == AgentVoiceSuperAdminCapabilityStatus.verifiedAvailable;

  bool get mustSurfaceUnavailable => !isVerifiedAvailable;

  void validate() {
    if (moduleId.trim().isEmpty ||
        !AgentVoiceSuperAdminCapabilityStatus.isValid(status) ||
        evidenceSource.trim().isEmpty ||
        note.trim().isEmpty) {
      throw const AgentVoiceSuperAdminModuleCapabilityException(
        'Voice Super Admin module capability is invalid.',
      );
    }
  }
}

/// Initial Phase 48 matrix based only on Step 1A evidence.
///
/// VERIFIED_AVAILABLE here means an existing narrowly-scoped read-only AI
/// connector is already present. It does NOT mean Voice transport is active.
///
/// NOT_CONNECTED means the business/module may exist, but Voice Super Admin has
/// no verified owner-facing adapter yet. It must report UNAVAILABLE rather than
/// invent data.
class AgentVoiceSuperAdminInitialCapabilityMatrix {
  AgentVoiceSuperAdminInitialCapabilityMatrix._();

  static const List<AgentVoiceSuperAdminModuleCapability>
  values = <AgentVoiceSuperAdminModuleCapability>[
    AgentVoiceSuperAdminModuleCapability(
      moduleId: AgentVoiceSuperAdminModule.normalRide,
      status: AgentVoiceSuperAdminCapabilityStatus.verifiedAvailable,
      evidenceSource: 'agent_ride_read_only_connector.dart',
      note: 'Existing read-only Ride connector discovered in Step 1A.',
    ),
    AgentVoiceSuperAdminModuleCapability(
      moduleId: AgentVoiceSuperAdminModule.driver,
      status: AgentVoiceSuperAdminCapabilityStatus.verifiedAvailable,
      evidenceSource: 'agent_driver_read_only_connector.dart',
      note: 'Existing read-only Driver connector discovered in Step 1A.',
    ),
    AgentVoiceSuperAdminModuleCapability(
      moduleId: AgentVoiceSuperAdminModule.food,
      status: AgentVoiceSuperAdminCapabilityStatus.verifiedAvailable,
      evidenceSource: 'agent_food_order_read_only_connector.dart',
      note: 'Existing read-only Food Order connector discovered in Step 1A.',
    ),
    AgentVoiceSuperAdminModuleCapability(
      moduleId: AgentVoiceSuperAdminModule.restaurant,
      status: AgentVoiceSuperAdminCapabilityStatus.verifiedAvailable,
      evidenceSource: 'agent_restaurant_read_only_connector.dart',
      note: 'Existing read-only Restaurant connector discovered in Step 1A.',
    ),
    AgentVoiceSuperAdminModuleCapability(
      moduleId: AgentVoiceSuperAdminModule.hotel,
      status: AgentVoiceSuperAdminCapabilityStatus.verifiedAvailable,
      evidenceSource: 'agent_hotel_booking_read_only_connector.dart',
      note: 'Existing read-only Hotel Booking connector discovered in Step 1A.',
    ),
    AgentVoiceSuperAdminModuleCapability(
      moduleId: AgentVoiceSuperAdminModule.tour,
      status: AgentVoiceSuperAdminCapabilityStatus.verifiedAvailable,
      evidenceSource: 'agent_tour_booking_read_only_connector.dart',
      note: 'Existing read-only Tour Booking connector discovered in Step 1A.',
    ),
    AgentVoiceSuperAdminModuleCapability(
      moduleId: AgentVoiceSuperAdminModule.systemHealth,
      status: AgentVoiceSuperAdminCapabilityStatus.verifiedAvailable,
      evidenceSource: 'agent_core_read_only_connector.dart',
      note: 'Existing core read-only connector provides authorized core reads.',
    ),
    AgentVoiceSuperAdminModuleCapability(
      moduleId: AgentVoiceSuperAdminModule.cargo,
      status: AgentVoiceSuperAdminCapabilityStatus.notConnected,
      evidenceSource: 'agent_cargo_connector_stub.dart',
      note: 'Cargo business module exists but AI connector is still a stub.',
    ),
    AgentVoiceSuperAdminModuleCapability(
      moduleId: AgentVoiceSuperAdminModule.parcel,
      status: AgentVoiceSuperAdminCapabilityStatus.notConnected,
      evidenceSource: 'phase48_step1a_audit',
      note: 'No verified Voice Super Admin Parcel read adapter confirmed.',
    ),
    AgentVoiceSuperAdminModuleCapability(
      moduleId: AgentVoiceSuperAdminModule.studentRide,
      status: AgentVoiceSuperAdminCapabilityStatus.notConnected,
      evidenceSource: 'agent_student_connector_stub.dart',
      note:
          'Student Ride business module exists but AI connector is still a stub.',
    ),
    AgentVoiceSuperAdminModuleCapability(
      moduleId: AgentVoiceSuperAdminModule.finance,
      status: AgentVoiceSuperAdminCapabilityStatus.notConnected,
      evidenceSource: 'phase48_step1a_audit',
      note:
          'Finance sources exist, but no verified Voice Super Admin read adapter is connected yet.',
    ),
    AgentVoiceSuperAdminModuleCapability(
      moduleId: AgentVoiceSuperAdminModule.applications,
      status: AgentVoiceSuperAdminCapabilityStatus.notConnected,
      evidenceSource: 'phase48_step1a_audit',
      note:
          'Application data exists, but a read-only Voice Super Admin adapter is not verified yet.',
    ),
    AgentVoiceSuperAdminModuleCapability(
      moduleId: AgentVoiceSuperAdminModule.complaintsSupport,
      status: AgentVoiceSuperAdminCapabilityStatus.notConnected,
      evidenceSource: 'phase48_step1a_audit',
      note:
          'Support actions exist, but a consolidated owner read adapter is not verified yet.',
    ),
    AgentVoiceSuperAdminModuleCapability(
      moduleId: AgentVoiceSuperAdminModule.safetySos,
      status: AgentVoiceSuperAdminCapabilityStatus.notConnected,
      evidenceSource: 'phase47_verified_safety_boundary',
      note:
          'Phase 47 Safety read is privacy-scoped; Voice Super Admin must not inherit it automatically.',
    ),
    AgentVoiceSuperAdminModuleCapability(
      moduleId: AgentVoiceSuperAdminModule.aiHealth,
      status: AgentVoiceSuperAdminCapabilityStatus.notConnected,
      evidenceSource: 'phase48_step1a_audit',
      note:
          'AI health sources exist but are not yet composed into a verified Voice Super Admin adapter.',
    ),
    AgentVoiceSuperAdminModuleCapability(
      moduleId: AgentVoiceSuperAdminModule.aiUsageCost,
      status: AgentVoiceSuperAdminCapabilityStatus.notConnected,
      evidenceSource: 'phase48_step1a_audit',
      note:
          'AI usage/cost controls exist but no verified owner read adapter is connected yet.',
    ),
    AgentVoiceSuperAdminModuleCapability(
      moduleId: AgentVoiceSuperAdminModule.securityAudit,
      status: AgentVoiceSuperAdminCapabilityStatus.notConnected,
      evidenceSource: 'phase48_step1a_audit',
      note:
          'Audit/security data exists but needs an owner-safe read adapter before Voice exposure.',
    ),
    AgentVoiceSuperAdminModuleCapability(
      moduleId: AgentVoiceSuperAdminModule.ownerPeriodicSummary,
      status: AgentVoiceSuperAdminCapabilityStatus.notConnected,
      evidenceSource: 'phase48_step1a_audit',
      note:
          'Full daily/weekly/monthly ecosystem composition is not connected yet.',
    ),
  ];

  static AgentVoiceSuperAdminModuleCapability byModule(String moduleId) {
    return values.firstWhere(
      (AgentVoiceSuperAdminModuleCapability value) =>
          value.moduleId == moduleId,
      orElse: () => AgentVoiceSuperAdminModuleCapability(
        moduleId: moduleId,
        status: AgentVoiceSuperAdminCapabilityStatus.unavailable,
        evidenceSource: 'unknown_module',
        note:
            'Module is not recognized by the initial Voice Super Admin capability matrix.',
      ),
    );
  }
}

class AgentVoiceSuperAdminModuleCapabilityException implements Exception {
  const AgentVoiceSuperAdminModuleCapabilityException(this.message);

  final String message;

  @override
  String toString() =>
      'AgentVoiceSuperAdminModuleCapabilityException: $message';
}
