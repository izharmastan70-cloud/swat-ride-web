// SWAT RIDE - UNIVERSAL SAFETY & SOS CONFIGURATION
//
// Central configuration for:
// - All customers
// - All drivers and delivery riders
// - Parents, guardians and students
// - Restaurant partners
// - Hotel guests, owners and staff
// - Tour customers, guides and tourism drivers
// - Cargo and parcel users/drivers
// - Admin and safety agents
//
// All modules will read the same configuration.
// Module-specific settings can still be enabled or disabled separately.

import '../models/safety_models.dart';

/// Controls whether a particular safety feature is available.
class SafetyFeatureSettings {
  const SafetyFeatureSettings({
    this.sosEnabled = true,
    this.safetyCenterEnabled = true,
    this.tripSharingEnabled = true,
    this.trustedContactsEnabled = true,
    this.emergencyCallEnabled = true,
    this.safetySupportEnabled = true,
    this.safetyReportsEnabled = true,
    this.silentSosEnabled = false,
    this.locationTrackingEnabled = true,
    this.routeDeviationDetectionEnabled = false,
    this.offlineQueueEnabled = true,
    this.smsFallbackEnabled = false,
    this.testModeEnabled = true,
  });

  final bool sosEnabled;
  final bool safetyCenterEnabled;
  final bool tripSharingEnabled;
  final bool trustedContactsEnabled;
  final bool emergencyCallEnabled;
  final bool safetySupportEnabled;
  final bool safetyReportsEnabled;
  final bool silentSosEnabled;
  final bool locationTrackingEnabled;
  final bool routeDeviationDetectionEnabled;
  final bool offlineQueueEnabled;
  final bool smsFallbackEnabled;

  /// When true, SOS incidents are marked as test incidents and real
  /// emergency-service calls must not be triggered automatically.
  final bool testModeEnabled;

  SafetyFeatureSettings copyWith({
    bool? sosEnabled,
    bool? safetyCenterEnabled,
    bool? tripSharingEnabled,
    bool? trustedContactsEnabled,
    bool? emergencyCallEnabled,
    bool? safetySupportEnabled,
    bool? safetyReportsEnabled,
    bool? silentSosEnabled,
    bool? locationTrackingEnabled,
    bool? routeDeviationDetectionEnabled,
    bool? offlineQueueEnabled,
    bool? smsFallbackEnabled,
    bool? testModeEnabled,
  }) {
    return SafetyFeatureSettings(
      sosEnabled: sosEnabled ?? this.sosEnabled,
      safetyCenterEnabled:
          safetyCenterEnabled ?? this.safetyCenterEnabled,
      tripSharingEnabled:
          tripSharingEnabled ?? this.tripSharingEnabled,
      trustedContactsEnabled:
          trustedContactsEnabled ?? this.trustedContactsEnabled,
      emergencyCallEnabled:
          emergencyCallEnabled ?? this.emergencyCallEnabled,
      safetySupportEnabled:
          safetySupportEnabled ?? this.safetySupportEnabled,
      safetyReportsEnabled:
          safetyReportsEnabled ?? this.safetyReportsEnabled,
      silentSosEnabled:
          silentSosEnabled ?? this.silentSosEnabled,
      locationTrackingEnabled:
          locationTrackingEnabled ?? this.locationTrackingEnabled,
      routeDeviationDetectionEnabled:
          routeDeviationDetectionEnabled ??
              this.routeDeviationDetectionEnabled,
      offlineQueueEnabled:
          offlineQueueEnabled ?? this.offlineQueueEnabled,
      smsFallbackEnabled:
          smsFallbackEnabled ?? this.smsFallbackEnabled,
      testModeEnabled:
          testModeEnabled ?? this.testModeEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'sosEnabled': sosEnabled,
      'safetyCenterEnabled': safetyCenterEnabled,
      'tripSharingEnabled': tripSharingEnabled,
      'trustedContactsEnabled': trustedContactsEnabled,
      'emergencyCallEnabled': emergencyCallEnabled,
      'safetySupportEnabled': safetySupportEnabled,
      'safetyReportsEnabled': safetyReportsEnabled,
      'silentSosEnabled': silentSosEnabled,
      'locationTrackingEnabled': locationTrackingEnabled,
      'routeDeviationDetectionEnabled':
          routeDeviationDetectionEnabled,
      'offlineQueueEnabled': offlineQueueEnabled,
      'smsFallbackEnabled': smsFallbackEnabled,
      'testModeEnabled': testModeEnabled,
    };
  }

  factory SafetyFeatureSettings.fromMap(
    Map<String, dynamic> map,
  ) {
    return SafetyFeatureSettings(
      sosEnabled: _asBool(map['sosEnabled'], true),
      safetyCenterEnabled:
          _asBool(map['safetyCenterEnabled'], true),
      tripSharingEnabled:
          _asBool(map['tripSharingEnabled'], true),
      trustedContactsEnabled:
          _asBool(map['trustedContactsEnabled'], true),
      emergencyCallEnabled:
          _asBool(map['emergencyCallEnabled'], true),
      safetySupportEnabled:
          _asBool(map['safetySupportEnabled'], true),
      safetyReportsEnabled:
          _asBool(map['safetyReportsEnabled'], true),
      silentSosEnabled:
          _asBool(map['silentSosEnabled'], false),
      locationTrackingEnabled:
          _asBool(map['locationTrackingEnabled'], true),
      routeDeviationDetectionEnabled:
          _asBool(
        map['routeDeviationDetectionEnabled'],
        false,
      ),
      offlineQueueEnabled:
          _asBool(map['offlineQueueEnabled'], true),
      smsFallbackEnabled:
          _asBool(map['smsFallbackEnabled'], false),
      testModeEnabled:
          _asBool(map['testModeEnabled'], true),
    );
  }
}

/// Admin-configurable emergency phone numbers.
///
/// These values are placeholders until the owner/admin enters verified
/// regional emergency numbers in the admin panel.
class SafetyEmergencyNumbers {
  const SafetyEmergencyNumbers({
    this.police = '',
    this.ambulance = '',
    this.fire = '',
    this.rescue = '',
    this.roadEmergency = '',
    this.swatRideSafetySupport = '',
    this.generalEmergency = '',
  });

  final String police;
  final String ambulance;
  final String fire;
  final String rescue;
  final String roadEmergency;
  final String swatRideSafetySupport;
  final String generalEmergency;

  SafetyEmergencyNumbers copyWith({
    String? police,
    String? ambulance,
    String? fire,
    String? rescue,
    String? roadEmergency,
    String? swatRideSafetySupport,
    String? generalEmergency,
  }) {
    return SafetyEmergencyNumbers(
      police: police ?? this.police,
      ambulance: ambulance ?? this.ambulance,
      fire: fire ?? this.fire,
      rescue: rescue ?? this.rescue,
      roadEmergency:
          roadEmergency ?? this.roadEmergency,
      swatRideSafetySupport:
          swatRideSafetySupport ??
              this.swatRideSafetySupport,
      generalEmergency:
          generalEmergency ?? this.generalEmergency,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'police': police,
      'ambulance': ambulance,
      'fire': fire,
      'rescue': rescue,
      'roadEmergency': roadEmergency,
      'swatRideSafetySupport': swatRideSafetySupport,
      'generalEmergency': generalEmergency,
    };
  }

  factory SafetyEmergencyNumbers.fromMap(
    Map<String, dynamic> map,
  ) {
    return SafetyEmergencyNumbers(
      police: _asString(map['police']),
      ambulance: _asString(map['ambulance']),
      fire: _asString(map['fire']),
      rescue: _asString(map['rescue']),
      roadEmergency: _asString(map['roadEmergency']),
      swatRideSafetySupport:
          _asString(map['swatRideSafetySupport']),
      generalEmergency:
          _asString(map['generalEmergency']),
    );
  }
}

/// Rules that determine automatic alerts and escalation.
class SafetyEscalationSettings {
  const SafetyEscalationSettings({
    this.sosCountdownSeconds = 3,
    this.adminAcknowledgementSeconds = 30,
    this.agentEscalationSeconds = 60,
    this.locationUpdateSeconds = 15,
    this.routeDeviationMeters = 1000,
    this.unexpectedStopMinutes = 10,
    this.offlineWarningMinutes = 5,
    this.maximumTrustedContacts = 3,
  });

  final int sosCountdownSeconds;
  final int adminAcknowledgementSeconds;
  final int agentEscalationSeconds;
  final int locationUpdateSeconds;
  final int routeDeviationMeters;
  final int unexpectedStopMinutes;
  final int offlineWarningMinutes;
  final int maximumTrustedContacts;

  SafetyEscalationSettings copyWith({
    int? sosCountdownSeconds,
    int? adminAcknowledgementSeconds,
    int? agentEscalationSeconds,
    int? locationUpdateSeconds,
    int? routeDeviationMeters,
    int? unexpectedStopMinutes,
    int? offlineWarningMinutes,
    int? maximumTrustedContacts,
  }) {
    return SafetyEscalationSettings(
      sosCountdownSeconds:
          sosCountdownSeconds ?? this.sosCountdownSeconds,
      adminAcknowledgementSeconds:
          adminAcknowledgementSeconds ??
              this.adminAcknowledgementSeconds,
      agentEscalationSeconds:
          agentEscalationSeconds ??
              this.agentEscalationSeconds,
      locationUpdateSeconds:
          locationUpdateSeconds ??
              this.locationUpdateSeconds,
      routeDeviationMeters:
          routeDeviationMeters ??
              this.routeDeviationMeters,
      unexpectedStopMinutes:
          unexpectedStopMinutes ??
              this.unexpectedStopMinutes,
      offlineWarningMinutes:
          offlineWarningMinutes ??
              this.offlineWarningMinutes,
      maximumTrustedContacts:
          maximumTrustedContacts ??
              this.maximumTrustedContacts,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'sosCountdownSeconds': sosCountdownSeconds,
      'adminAcknowledgementSeconds':
          adminAcknowledgementSeconds,
      'agentEscalationSeconds': agentEscalationSeconds,
      'locationUpdateSeconds': locationUpdateSeconds,
      'routeDeviationMeters': routeDeviationMeters,
      'unexpectedStopMinutes': unexpectedStopMinutes,
      'offlineWarningMinutes': offlineWarningMinutes,
      'maximumTrustedContacts': maximumTrustedContacts,
    };
  }

  factory SafetyEscalationSettings.fromMap(
    Map<String, dynamic> map,
  ) {
    return SafetyEscalationSettings(
      sosCountdownSeconds:
          _asInt(map['sosCountdownSeconds'], 3),
      adminAcknowledgementSeconds:
          _asInt(map['adminAcknowledgementSeconds'], 30),
      agentEscalationSeconds:
          _asInt(map['agentEscalationSeconds'], 60),
      locationUpdateSeconds:
          _asInt(map['locationUpdateSeconds'], 15),
      routeDeviationMeters:
          _asInt(map['routeDeviationMeters'], 1000),
      unexpectedStopMinutes:
          _asInt(map['unexpectedStopMinutes'], 10),
      offlineWarningMinutes:
          _asInt(map['offlineWarningMinutes'], 5),
      maximumTrustedContacts:
          _asInt(map['maximumTrustedContacts'], 3),
    );
  }
}

/// Module-specific safety availability.
///
/// Every service can be controlled independently without an app update.
class SafetyServiceSettings {
  const SafetyServiceSettings({
    required this.serviceType,
    this.enabled = true,
    this.customerSosEnabled = true,
    this.providerSosEnabled = true,
    this.ownerOrPartnerSosEnabled = true,
    this.activeServiceSafetyButtonEnabled = true,
    this.completedServiceReportEnabled = true,
    this.historySafetyEnabled = true,
    this.availableCategories =
        const <SafetyEmergencyCategory>[],
  });

  final SafetyServiceType serviceType;

  final bool enabled;
  final bool customerSosEnabled;
  final bool providerSosEnabled;
  final bool ownerOrPartnerSosEnabled;
  final bool activeServiceSafetyButtonEnabled;
  final bool completedServiceReportEnabled;
  final bool historySafetyEnabled;

  final List<SafetyEmergencyCategory> availableCategories;

  SafetyServiceSettings copyWith({
    SafetyServiceType? serviceType,
    bool? enabled,
    bool? customerSosEnabled,
    bool? providerSosEnabled,
    bool? ownerOrPartnerSosEnabled,
    bool? activeServiceSafetyButtonEnabled,
    bool? completedServiceReportEnabled,
    bool? historySafetyEnabled,
    List<SafetyEmergencyCategory>? availableCategories,
  }) {
    return SafetyServiceSettings(
      serviceType: serviceType ?? this.serviceType,
      enabled: enabled ?? this.enabled,
      customerSosEnabled:
          customerSosEnabled ?? this.customerSosEnabled,
      providerSosEnabled:
          providerSosEnabled ?? this.providerSosEnabled,
      ownerOrPartnerSosEnabled:
          ownerOrPartnerSosEnabled ??
              this.ownerOrPartnerSosEnabled,
      activeServiceSafetyButtonEnabled:
          activeServiceSafetyButtonEnabled ??
              this.activeServiceSafetyButtonEnabled,
      completedServiceReportEnabled:
          completedServiceReportEnabled ??
              this.completedServiceReportEnabled,
      historySafetyEnabled:
          historySafetyEnabled ?? this.historySafetyEnabled,
      availableCategories:
          availableCategories ?? this.availableCategories,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'serviceType': serviceType.name,
      'enabled': enabled,
      'customerSosEnabled': customerSosEnabled,
      'providerSosEnabled': providerSosEnabled,
      'ownerOrPartnerSosEnabled':
          ownerOrPartnerSosEnabled,
      'activeServiceSafetyButtonEnabled':
          activeServiceSafetyButtonEnabled,
      'completedServiceReportEnabled':
          completedServiceReportEnabled,
      'historySafetyEnabled': historySafetyEnabled,
      'availableCategories': availableCategories
          .map(
            (SafetyEmergencyCategory category) =>
                category.name,
          )
          .toList(),
    };
  }

  factory SafetyServiceSettings.fromMap(
    Map<String, dynamic> map,
  ) {
    final List<SafetyEmergencyCategory> categories =
        <SafetyEmergencyCategory>[];

    final dynamic rawCategories = map['availableCategories'];

    if (rawCategories is List) {
      for (final dynamic value in rawCategories) {
        categories.add(
          safetyEmergencyCategoryFromString(
            value.toString(),
          ),
        );
      }
    }

    return SafetyServiceSettings(
      serviceType: safetyServiceTypeFromString(
        _asString(map['serviceType']),
      ),
      enabled: _asBool(map['enabled'], true),
      customerSosEnabled:
          _asBool(map['customerSosEnabled'], true),
      providerSosEnabled:
          _asBool(map['providerSosEnabled'], true),
      ownerOrPartnerSosEnabled:
          _asBool(
        map['ownerOrPartnerSosEnabled'],
        true,
      ),
      activeServiceSafetyButtonEnabled:
          _asBool(
        map['activeServiceSafetyButtonEnabled'],
        true,
      ),
      completedServiceReportEnabled:
          _asBool(
        map['completedServiceReportEnabled'],
        true,
      ),
      historySafetyEnabled:
          _asBool(map['historySafetyEnabled'], true),
      availableCategories: categories,
    );
  }
}

/// Main universal safety configuration.
class UniversalSafetyConfig {
  const UniversalSafetyConfig({
    required this.features,
    required this.emergencyNumbers,
    required this.escalation,
    required this.serviceSettings,
    this.configVersion = 1,
    this.updatedBy = '',
    this.updatedAt,
  });

  final SafetyFeatureSettings features;
  final SafetyEmergencyNumbers emergencyNumbers;
  final SafetyEscalationSettings escalation;

  final Map<SafetyServiceType, SafetyServiceSettings>
      serviceSettings;

  final int configVersion;
  final String updatedBy;
  final DateTime? updatedAt;

  SafetyServiceSettings settingsFor(
    SafetyServiceType serviceType,
  ) {
    return serviceSettings[serviceType] ??
        defaultSafetyServiceSettings(serviceType);
  }

  bool isServiceEnabled(
    SafetyServiceType serviceType,
  ) {
    return features.safetyCenterEnabled &&
        settingsFor(serviceType).enabled;
  }

  bool canUseCustomerSos(
    SafetyServiceType serviceType,
  ) {
    final SafetyServiceSettings settings =
        settingsFor(serviceType);

    return features.sosEnabled &&
        settings.enabled &&
        settings.customerSosEnabled;
  }

  bool canUseProviderSos(
    SafetyServiceType serviceType,
  ) {
    final SafetyServiceSettings settings =
        settingsFor(serviceType);

    return features.sosEnabled &&
        settings.enabled &&
        settings.providerSosEnabled;
  }

  bool canUseOwnerOrPartnerSos(
    SafetyServiceType serviceType,
  ) {
    final SafetyServiceSettings settings =
        settingsFor(serviceType);

    return features.sosEnabled &&
        settings.enabled &&
        settings.ownerOrPartnerSosEnabled;
  }

  UniversalSafetyConfig copyWith({
    SafetyFeatureSettings? features,
    SafetyEmergencyNumbers? emergencyNumbers,
    SafetyEscalationSettings? escalation,
    Map<SafetyServiceType, SafetyServiceSettings>?
        serviceSettings,
    int? configVersion,
    String? updatedBy,
    DateTime? updatedAt,
  }) {
    return UniversalSafetyConfig(
      features: features ?? this.features,
      emergencyNumbers:
          emergencyNumbers ?? this.emergencyNumbers,
      escalation: escalation ?? this.escalation,
      serviceSettings:
          serviceSettings ?? this.serviceSettings,
      configVersion: configVersion ?? this.configVersion,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> mappedServices =
        <String, dynamic>{};

    for (final MapEntry<
            SafetyServiceType,
            SafetyServiceSettings> entry
        in serviceSettings.entries) {
      mappedServices[entry.key.name] =
          entry.value.toMap();
    }

    return <String, dynamic>{
      'features': features.toMap(),
      'emergencyNumbers': emergencyNumbers.toMap(),
      'escalation': escalation.toMap(),
      'serviceSettings': mappedServices,
      'configVersion': configVersion,
      'updatedBy': updatedBy,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory UniversalSafetyConfig.fromMap(
    Map<String, dynamic> map,
  ) {
    final Map<SafetyServiceType, SafetyServiceSettings>
        parsedSettings =
        <SafetyServiceType, SafetyServiceSettings>{};

    final Map<String, dynamic> rawServices =
        _asMap(map['serviceSettings']);

    for (final MapEntry<String, dynamic> entry
        in rawServices.entries) {
      final Map<String, dynamic> serviceMap =
          _asMap(entry.value);

      final SafetyServiceType serviceType =
          safetyServiceTypeFromString(entry.key);

      parsedSettings[serviceType] =
          SafetyServiceSettings.fromMap(
        <String, dynamic>{
          ...serviceMap,
          'serviceType': serviceType.name,
        },
      );
    }

    return UniversalSafetyConfig(
      features: SafetyFeatureSettings.fromMap(
        _asMap(map['features']),
      ),
      emergencyNumbers:
          SafetyEmergencyNumbers.fromMap(
        _asMap(map['emergencyNumbers']),
      ),
      escalation:
          SafetyEscalationSettings.fromMap(
        _asMap(map['escalation']),
      ),
      serviceSettings: parsedSettings.isEmpty
          ? defaultUniversalSafetyConfig()
              .serviceSettings
          : parsedSettings,
      configVersion:
          _asInt(map['configVersion'], 1),
      updatedBy: _asString(map['updatedBy']),
      updatedAt: _asDateTime(map['updatedAt']),
    );
  }
}

/// Default settings used before Firestore/admin settings are loaded.
UniversalSafetyConfig defaultUniversalSafetyConfig() {
  final Map<SafetyServiceType, SafetyServiceSettings>
      services =
      <SafetyServiceType, SafetyServiceSettings>{};

  for (final SafetyServiceType serviceType
      in SafetyServiceType.values) {
    services[serviceType] =
        defaultSafetyServiceSettings(serviceType);
  }

  return UniversalSafetyConfig(
    features: const SafetyFeatureSettings(
      sosEnabled: true,
      safetyCenterEnabled: true,
      tripSharingEnabled: true,
      trustedContactsEnabled: true,
      emergencyCallEnabled: true,
      safetySupportEnabled: true,
      safetyReportsEnabled: true,
      silentSosEnabled: false,
      locationTrackingEnabled: true,
      routeDeviationDetectionEnabled: false,
      offlineQueueEnabled: true,
      smsFallbackEnabled: false,

      // Keep true while development/testing is in progress.
      testModeEnabled: true,
    ),
    emergencyNumbers:
        const SafetyEmergencyNumbers(),
    escalation:
        const SafetyEscalationSettings(),
    serviceSettings: services,
    configVersion: 1,
  );
}

/// Default service categories and permissions.
///
/// These defaults will later be editable from the admin panel.
SafetyServiceSettings defaultSafetyServiceSettings(
  SafetyServiceType serviceType,
) {
  switch (serviceType) {
    case SafetyServiceType.normalRide:
    case SafetyServiceType.driver:
      return SafetyServiceSettings(
        serviceType: serviceType,
        availableCategories: const <
            SafetyEmergencyCategory>[
          SafetyEmergencyCategory.immediateDanger,
          SafetyEmergencyCategory.medicalEmergency,
          SafetyEmergencyCategory.accident,
          SafetyEmergencyCategory.dangerousDriving,
          SafetyEmergencyCategory.routeDeviation,
          SafetyEmergencyCategory.driverMismatch,
          SafetyEmergencyCategory.vehicleMismatch,
          SafetyEmergencyCategory.passengerThreat,
          SafetyEmergencyCategory.physicalThreat,
          SafetyEmergencyCategory.harassment,
          SafetyEmergencyCategory.robbery,
          SafetyEmergencyCategory.suspectedKidnapping,
          SafetyEmergencyCategory.vehicleBreakdown,
          SafetyEmergencyCategory.other,
        ],
      );

    case SafetyServiceType.studentRide:
    case SafetyServiceType.schoolTransport:
      return SafetyServiceSettings(
        serviceType: serviceType,
        availableCategories: const <
            SafetyEmergencyCategory>[
          SafetyEmergencyCategory.childMissing,
          SafetyEmergencyCategory.unauthorizedGuardian,
          SafetyEmergencyCategory.childMedicalEmergency,
          SafetyEmergencyCategory.accident,
          SafetyEmergencyCategory.routeDeviation,
          SafetyEmergencyCategory.studentNotPickedUp,
          SafetyEmergencyCategory.studentNotDropped,
          SafetyEmergencyCategory.schoolArrivalNotConfirmed,
          SafetyEmergencyCategory.unauthorizedHandover,
          SafetyEmergencyCategory.childLeftInVehicle,
          SafetyEmergencyCategory.vehicleBreakdown,
          SafetyEmergencyCategory.other,
        ],
      );

    case SafetyServiceType.foodDelivery:
    case SafetyServiceType.restaurantPartner:
      return SafetyServiceSettings(
        serviceType: serviceType,
        availableCategories: const <
            SafetyEmergencyCategory>[
          SafetyEmergencyCategory.immediateDanger,
          SafetyEmergencyCategory.medicalEmergency,
          SafetyEmergencyCategory.deliveryRiderAccident,
          SafetyEmergencyCategory.unsafeDeliveryLocation,
          SafetyEmergencyCategory.customerThreatToRider,
          SafetyEmergencyCategory.riderThreatToCustomer,
          SafetyEmergencyCategory.unsafeCashCollection,
          SafetyEmergencyCategory.orderTamperingConcern,
          SafetyEmergencyCategory.robbery,
          SafetyEmergencyCategory.other,
        ],
      );

    case SafetyServiceType.cargoDelivery:
    case SafetyServiceType.parcelDelivery:
      return SafetyServiceSettings(
        serviceType: serviceType,
        availableCategories: const <
            SafetyEmergencyCategory>[
          SafetyEmergencyCategory.immediateDanger,
          SafetyEmergencyCategory.accident,
          SafetyEmergencyCategory.cargoTheftAttempt,
          SafetyEmergencyCategory.cargoDamage,
          SafetyEmergencyCategory.cargoVehicleHijacking,
          SafetyEmergencyCategory.receiverLocationUnsafe,
          SafetyEmergencyCategory.dangerousGoodsDetected,
          SafetyEmergencyCategory.deliveryOtpProblem,
          SafetyEmergencyCategory.vehicleBreakdown,
          SafetyEmergencyCategory.robbery,
          SafetyEmergencyCategory.other,
        ],
      );

    case SafetyServiceType.hotelBooking:
    case SafetyServiceType.hotelStay:
      return SafetyServiceSettings(
        serviceType: serviceType,
        availableCategories: const <
            SafetyEmergencyCategory>[
          SafetyEmergencyCategory.medicalEmergency,
          SafetyEmergencyCategory.fireOrSmoke,
          SafetyEmergencyCategory.unauthorizedRoomAccess,
          SafetyEmergencyCategory.harassment,
          SafetyEmergencyCategory.theft,
          SafetyEmergencyCategory.hotelStaffThreat,
          SafetyEmergencyCategory.violentGuest,
          SafetyEmergencyCategory.evacuationRequired,
          SafetyEmergencyCategory.unsafeRoom,
          SafetyEmergencyCategory.guestMissing,
          SafetyEmergencyCategory.other,
        ],
      );

    case SafetyServiceType.tourBooking:
    case SafetyServiceType.activeTour:
    case SafetyServiceType.tourismDriver:
    case SafetyServiceType.tourGuide:
      return SafetyServiceSettings(
        serviceType: serviceType,
        availableCategories: const <
            SafetyEmergencyCategory>[
          SafetyEmergencyCategory.medicalEmergency,
          SafetyEmergencyCategory.accident,
          SafetyEmergencyCategory.touristMissing,
          SafetyEmergencyCategory.groupSeparated,
          SafetyEmergencyCategory.guideUnreachable,
          SafetyEmergencyCategory.tourismDriverUnreachable,
          SafetyEmergencyCategory.unsafeWeather,
          SafetyEmergencyCategory.unsafeRoad,
          SafetyEmergencyCategory.mountainEmergency,
          SafetyEmergencyCategory.groupEmergency,
          SafetyEmergencyCategory.vehicleBreakdown,
          SafetyEmergencyCategory.robbery,
          SafetyEmergencyCategory.other,
        ],
      );

    case SafetyServiceType.general:
      return const SafetyServiceSettings(
        serviceType: SafetyServiceType.general,
        availableCategories: <
            SafetyEmergencyCategory>[
          SafetyEmergencyCategory.immediateDanger,
          SafetyEmergencyCategory.medicalEmergency,
          SafetyEmergencyCategory.accident,
          SafetyEmergencyCategory.physicalThreat,
          SafetyEmergencyCategory.harassment,
          SafetyEmergencyCategory.robbery,
          SafetyEmergencyCategory.theft,
          SafetyEmergencyCategory.unsafeLocation,
          SafetyEmergencyCategory.other,
        ],
      );
  }
}

// -----------------------------------------------------------------------------
// SAFE CONVERSION HELPERS
// -----------------------------------------------------------------------------

String _asString(dynamic value) {
  if (value == null) {
    return '';
  }

  return value.toString();
}

bool _asBool(
  dynamic value,
  bool fallback,
) {
  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  if (value is String) {
    final String normalized =
        value.trim().toLowerCase();

    if (normalized == 'true' || normalized == '1') {
      return true;
    }

    if (normalized == 'false' || normalized == '0') {
      return false;
    }
  }

  return fallback;
}

int _asInt(
  dynamic value,
  int fallback,
) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }

  return fallback;
}

DateTime? _asDateTime(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is DateTime) {
    return value;
  }

  if (value is String) {
    return DateTime.tryParse(value);
  }

  try {
    final dynamic converted = value.toDate();

    if (converted is DateTime) {
      return converted;
    }
  } catch (_) {
    // Unsupported date format.
  }

  return null;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return Map<String, dynamic>.from(value);
  }

  if (value is Map) {
    return value.map<String, dynamic>(
      (dynamic key, dynamic mapValue) {
        return MapEntry<String, dynamic>(
          key.toString(),
          mapValue,
        );
      },
    );
  }

  return <String, dynamic>{};
}