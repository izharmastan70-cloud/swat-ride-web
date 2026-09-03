// SWAT RIDE - UNIVERSAL SAFETY & SOS MODELS
//
// Central safety models for:
// - Normal Ride
// - Driver
// - Student Ride
// - Food Delivery
// - Restaurant Partner
// - Cargo
// - Hotel
// - Tourism / Tours
// - Tour Guide
// - Hotel Owner / Staff
// - School Coordinator
// - Admin / Safety Agent
//
// Important:
// Every module will use these shared models.
// Do not create separate SOS models for each module.

/// SWAT RIDE service/module types supported by the universal safety system.
enum SafetyServiceType {
  general,
  normalRide,
  driver,
  studentRide,
  foodDelivery,
  restaurantPartner,
  cargoDelivery,
  parcelDelivery,
  hotelBooking,
  hotelStay,
  tourBooking,
  activeTour,
  tourismDriver,
  tourGuide,
  schoolTransport,
}

/// Role of the person who creates or is involved in a safety incident.
enum SafetyUserRole {
  customer,
  passenger,
  normalDriver,
  foodCustomer,
  foodDeliveryRider,
  restaurantOwner,
  restaurantStaff,
  cargoCustomer,
  cargoDriver,
  parcelCustomer,
  parcelDriver,
  parent,
  guardian,
  student,
  studentDriver,
  schoolCoordinator,
  schoolStaff,
  hotelGuest,
  hotelOwner,
  hotelStaff,
  tourCustomer,
  tourismDriver,
  tourGuide,
  admin,
  safetyAgent,
  superAdmin,
  unknown,
}

/// Current lifecycle status of a safety incident.
enum SafetyIncidentStatus {
  created,
  alertSent,
  acknowledged,
  agentAssigned,
  contactingUser,
  emergencyServiceContacted,
  responding,
  userMarkedSafe,
  underInvestigation,
  resolved,
  falseAlarm,
  closed,
}

/// Severity level used by the safety admin and escalation system.
enum SafetySeverity {
  low,
  medium,
  high,
  critical,
}

/// Universal emergency categories.
///
/// Some categories are common to every module, while others are used only
/// for a specific service such as Student Ride, Hotel, Tour, Cargo or Food.
enum SafetyEmergencyCategory {
  // Common emergencies
  immediateDanger,
  medicalEmergency,
  accident,
  physicalThreat,
  harassment,
  robbery,
  theft,
  unsafeLocation,
  unableToContact,
  other,

  // Ride / Driver
  dangerousDriving,
  routeDeviation,
  driverMismatch,
  vehicleMismatch,
  passengerThreat,
  suspectedKidnapping,
  vehicleBreakdown,

  // Student Ride
  childMissing,
  unauthorizedGuardian,
  childMedicalEmergency,
  studentNotPickedUp,
  studentNotDropped,
  schoolArrivalNotConfirmed,
  unauthorizedHandover,
  childLeftInVehicle,

  // Food Delivery
  unsafeDeliveryLocation,
  customerThreatToRider,
  riderThreatToCustomer,
  unsafeCashCollection,
  orderTamperingConcern,
  deliveryRiderAccident,

  // Cargo / Parcel
  cargoTheftAttempt,
  cargoDamage,
  cargoVehicleHijacking,
  receiverLocationUnsafe,
  dangerousGoodsDetected,
  deliveryOtpProblem,

  // Hotel
  fireOrSmoke,
  unauthorizedRoomAccess,
  hotelStaffThreat,
  violentGuest,
  evacuationRequired,
  unsafeRoom,
  guestMissing,

  // Tour / Tourism
  touristMissing,
  groupSeparated,
  guideUnreachable,
  tourismDriverUnreachable,
  unsafeWeather,
  unsafeRoad,
  mountainEmergency,
  groupEmergency,
}

/// Source page from which Safety Center or SOS was opened.
///
/// This makes it easier to know where the emergency started.
enum SafetySourcePage {
  unknown,
  home,
  mainMenu,
  bookingDetails,
  driverAssigned,
  driverArriving,
  activeRide,
  activeDelivery,
  orderTracking,
  cargoTracking,
  studentTracking,
  hotelBookingDetails,
  activeHotelStay,
  activeTour,
  tourismDriverDashboard,
  tourGuideDashboard,
  driverDashboard,
  foodRiderDashboard,
  historyDetails,
  completedService,
}

/// Current network state during the emergency.
enum SafetyNetworkStatus {
  unknown,
  online,
  weak,
  offline,
}

/// Current GPS/location permission and availability state.
enum SafetyLocationStatus {
  unknown,
  available,
  permissionDenied,
  permissionDeniedForever,
  gpsDisabled,
  unavailable,
}

/// Universal geographical location snapshot.
class SafetyLocation {
  const SafetyLocation({
    required this.latitude,
    required this.longitude,
    this.address = '',
    this.placeName = '',
    this.accuracy,
    this.speed,
    this.heading,
    this.recordedAt,
    this.isLastKnownLocation = false,
  });

  final double latitude;
  final double longitude;

  final String address;
  final String placeName;

  final double? accuracy;
  final double? speed;
  final double? heading;

  final DateTime? recordedAt;

  /// True when live GPS was unavailable and a previous location was used.
  final bool isLastKnownLocation;

  bool get isValid {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  SafetyLocation copyWith({
    double? latitude,
    double? longitude,
    String? address,
    String? placeName,
    double? accuracy,
    double? speed,
    double? heading,
    DateTime? recordedAt,
    bool? isLastKnownLocation,
  }) {
    return SafetyLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      placeName: placeName ?? this.placeName,
      accuracy: accuracy ?? this.accuracy,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      recordedAt: recordedAt ?? this.recordedAt,
      isLastKnownLocation:
          isLastKnownLocation ?? this.isLastKnownLocation,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'placeName': placeName,
      'accuracy': accuracy,
      'speed': speed,
      'heading': heading,
      'recordedAt': recordedAt?.toIso8601String(),
      'isLastKnownLocation': isLastKnownLocation,
    };
  }

  factory SafetyLocation.fromMap(Map<String, dynamic> map) {
    return SafetyLocation(
      latitude: _asDouble(map['latitude']),
      longitude: _asDouble(map['longitude']),
      address: _asString(map['address']),
      placeName: _asString(map['placeName']),
      accuracy: _asNullableDouble(map['accuracy']),
      speed: _asNullableDouble(map['speed']),
      heading: _asNullableDouble(map['heading']),
      recordedAt: _asDateTime(map['recordedAt']),
      isLastKnownLocation: _asBool(map['isLastKnownLocation']),
    );
  }
}

/// Safe snapshot of a person involved in the incident.
///
/// A snapshot is used so that changing a profile later does not change
/// the original emergency record.
class SafetyPersonSnapshot {
  const SafetyPersonSnapshot({
    required this.userId,
    required this.role,
    this.fullName = '',
    this.phoneNumber = '',
    this.profileImageUrl = '',
    this.rating,
    this.isVerified = false,
    this.extraData = const <String, dynamic>{},
  });

  final String userId;
  final SafetyUserRole role;

  final String fullName;
  final String phoneNumber;
  final String profileImageUrl;

  final double? rating;
  final bool isVerified;

  /// Module-specific safe information.
  ///
  /// Examples:
  /// - parent relationship
  /// - hotel staff position
  /// - school coordinator name
  /// - guide licence number
  final Map<String, dynamic> extraData;

  SafetyPersonSnapshot copyWith({
    String? userId,
    SafetyUserRole? role,
    String? fullName,
    String? phoneNumber,
    String? profileImageUrl,
    double? rating,
    bool? isVerified,
    Map<String, dynamic>? extraData,
  }) {
    return SafetyPersonSnapshot(
      userId: userId ?? this.userId,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      rating: rating ?? this.rating,
      isVerified: isVerified ?? this.isVerified,
      extraData: extraData ?? this.extraData,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'userId': userId,
      'role': role.name,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'rating': rating,
      'isVerified': isVerified,
      'extraData': extraData,
    };
  }

  factory SafetyPersonSnapshot.fromMap(Map<String, dynamic> map) {
    return SafetyPersonSnapshot(
      userId: _asString(map['userId']),
      role: safetyUserRoleFromString(
        _asString(map['role']),
      ),
      fullName: _asString(map['fullName']),
      phoneNumber: _asString(map['phoneNumber']),
      profileImageUrl: _asString(map['profileImageUrl']),
      rating: _asNullableDouble(map['rating']),
      isVerified: _asBool(map['isVerified']),
      extraData: _asMap(map['extraData']),
    );
  }
}

/// Universal vehicle snapshot.
///
/// This works for normal ride vehicles, school vans, cargo trucks,
/// food delivery bikes and tourism vehicles.
class SafetyVehicleSnapshot {
  const SafetyVehicleSnapshot({
    required this.vehicleId,
    this.vehicleType = '',
    this.vehicleNumber = '',
    this.vehicleModel = '',
    this.vehicleColor = '',
    this.registrationNumber = '',
    this.imageUrl = '',
    this.extraData = const <String, dynamic>{},
  });

  final String vehicleId;
  final String vehicleType;
  final String vehicleNumber;
  final String vehicleModel;
  final String vehicleColor;
  final String registrationNumber;
  final String imageUrl;

  final Map<String, dynamic> extraData;

  SafetyVehicleSnapshot copyWith({
    String? vehicleId,
    String? vehicleType,
    String? vehicleNumber,
    String? vehicleModel,
    String? vehicleColor,
    String? registrationNumber,
    String? imageUrl,
    Map<String, dynamic>? extraData,
  }) {
    return SafetyVehicleSnapshot(
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      registrationNumber:
          registrationNumber ?? this.registrationNumber,
      imageUrl: imageUrl ?? this.imageUrl,
      extraData: extraData ?? this.extraData,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'vehicleId': vehicleId,
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      'vehicleModel': vehicleModel,
      'vehicleColor': vehicleColor,
      'registrationNumber': registrationNumber,
      'imageUrl': imageUrl,
      'extraData': extraData,
    };
  }

  factory SafetyVehicleSnapshot.fromMap(
    Map<String, dynamic> map,
  ) {
    return SafetyVehicleSnapshot(
      vehicleId: _asString(map['vehicleId']),
      vehicleType: _asString(map['vehicleType']),
      vehicleNumber: _asString(map['vehicleNumber']),
      vehicleModel: _asString(map['vehicleModel']),
      vehicleColor: _asString(map['vehicleColor']),
      registrationNumber:
          _asString(map['registrationNumber']),
      imageUrl: _asString(map['imageUrl']),
      extraData: _asMap(map['extraData']),
    );
  }
}

/// Context provided by any module when opening Universal Safety Center.
///
/// Every module will build this context and pass it to the shared
/// Yango-style Safety Center.
class SafetyContext {
  const SafetyContext({
    required this.serviceType,
    required this.referenceId,
    required this.initiatedByUserId,
    required this.initiatedByRole,
    this.sourcePage = SafetySourcePage.unknown,
    this.referenceStatus = '',
    this.primaryPerson,
    this.secondaryPerson,
    this.relatedPeople = const <SafetyPersonSnapshot>[],
    this.vehicle,
    this.currentLocation,
    this.pickupLocation,
    this.destinationLocation,
    this.serviceTitle = '',
    this.serviceSubtitle = '',
    this.paymentMethod = '',
    this.metadata = const <String, dynamic>{},
  });

  /// Ride, Food, Cargo, Student, Hotel, Tour etc.
  final SafetyServiceType serviceType;

  /// Related ride ID, order ID, booking ID, tour ID etc.
  final String referenceId;

  /// User who opened or activated Safety Center.
  final String initiatedByUserId;
  final SafetyUserRole initiatedByRole;

  /// Page from which Safety Center was opened.
  final SafetySourcePage sourcePage;

  /// Current booking/order/ride status.
  final String referenceStatus;

  /// Main related person.
  ///
  /// Examples:
  /// - driver
  /// - delivery rider
  /// - hotel guest
  /// - tour guide
  final SafetyPersonSnapshot? primaryPerson;

  /// Secondary related person.
  ///
  /// Examples:
  /// - passenger
  /// - parent
  /// - tourism driver
  /// - hotel owner
  final SafetyPersonSnapshot? secondaryPerson;

  /// Other people involved.
  ///
  /// Examples:
  /// - students
  /// - group tourists
  /// - school coordinator
  /// - hotel staff
  final List<SafetyPersonSnapshot> relatedPeople;

  final SafetyVehicleSnapshot? vehicle;

  final SafetyLocation? currentLocation;
  final SafetyLocation? pickupLocation;
  final SafetyLocation? destinationLocation;

  final String serviceTitle;
  final String serviceSubtitle;
  final String paymentMethod;

  /// Module-specific information.
  ///
  /// Examples:
  /// Ride:
  ///   fare, distance, ETA
  ///
  /// Student:
  ///   schoolId, guardianId, attendance status
  ///
  /// Food:
  ///   restaurantId, cash amount
  ///
  /// Cargo:
  ///   cargo category, declared value
  ///
  /// Hotel:
  ///   hotelId, roomId, room number
  ///
  /// Tour:
  ///   packageId, guideId, group members
  final Map<String, dynamic> metadata;

  SafetyContext copyWith({
    SafetyServiceType? serviceType,
    String? referenceId,
    String? initiatedByUserId,
    SafetyUserRole? initiatedByRole,
    SafetySourcePage? sourcePage,
    String? referenceStatus,
    SafetyPersonSnapshot? primaryPerson,
    SafetyPersonSnapshot? secondaryPerson,
    List<SafetyPersonSnapshot>? relatedPeople,
    SafetyVehicleSnapshot? vehicle,
    SafetyLocation? currentLocation,
    SafetyLocation? pickupLocation,
    SafetyLocation? destinationLocation,
    String? serviceTitle,
    String? serviceSubtitle,
    String? paymentMethod,
    Map<String, dynamic>? metadata,
  }) {
    return SafetyContext(
      serviceType: serviceType ?? this.serviceType,
      referenceId: referenceId ?? this.referenceId,
      initiatedByUserId:
          initiatedByUserId ?? this.initiatedByUserId,
      initiatedByRole:
          initiatedByRole ?? this.initiatedByRole,
      sourcePage: sourcePage ?? this.sourcePage,
      referenceStatus:
          referenceStatus ?? this.referenceStatus,
      primaryPerson: primaryPerson ?? this.primaryPerson,
      secondaryPerson:
          secondaryPerson ?? this.secondaryPerson,
      relatedPeople: relatedPeople ?? this.relatedPeople,
      vehicle: vehicle ?? this.vehicle,
      currentLocation:
          currentLocation ?? this.currentLocation,
      pickupLocation:
          pickupLocation ?? this.pickupLocation,
      destinationLocation:
          destinationLocation ?? this.destinationLocation,
      serviceTitle: serviceTitle ?? this.serviceTitle,
      serviceSubtitle:
          serviceSubtitle ?? this.serviceSubtitle,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'serviceType': serviceType.name,
      'referenceId': referenceId,
      'initiatedByUserId': initiatedByUserId,
      'initiatedByRole': initiatedByRole.name,
      'sourcePage': sourcePage.name,
      'referenceStatus': referenceStatus,
      'primaryPerson': primaryPerson?.toMap(),
      'secondaryPerson': secondaryPerson?.toMap(),
      'relatedPeople': relatedPeople
          .map((SafetyPersonSnapshot person) => person.toMap())
          .toList(),
      'vehicle': vehicle?.toMap(),
      'currentLocation': currentLocation?.toMap(),
      'pickupLocation': pickupLocation?.toMap(),
      'destinationLocation': destinationLocation?.toMap(),
      'serviceTitle': serviceTitle,
      'serviceSubtitle': serviceSubtitle,
      'paymentMethod': paymentMethod,
      'metadata': metadata,
    };
  }

  factory SafetyContext.fromMap(Map<String, dynamic> map) {
    return SafetyContext(
      serviceType: safetyServiceTypeFromString(
        _asString(map['serviceType']),
      ),
      referenceId: _asString(map['referenceId']),
      initiatedByUserId:
          _asString(map['initiatedByUserId']),
      initiatedByRole: safetyUserRoleFromString(
        _asString(map['initiatedByRole']),
      ),
      sourcePage: safetySourcePageFromString(
        _asString(map['sourcePage']),
      ),
      referenceStatus:
          _asString(map['referenceStatus']),
      primaryPerson: _personFromDynamic(map['primaryPerson']),
      secondaryPerson:
          _personFromDynamic(map['secondaryPerson']),
      relatedPeople:
          _personListFromDynamic(map['relatedPeople']),
      vehicle: _vehicleFromDynamic(map['vehicle']),
      currentLocation:
          _locationFromDynamic(map['currentLocation']),
      pickupLocation:
          _locationFromDynamic(map['pickupLocation']),
      destinationLocation:
          _locationFromDynamic(map['destinationLocation']),
      serviceTitle: _asString(map['serviceTitle']),
      serviceSubtitle:
          _asString(map['serviceSubtitle']),
      paymentMethod: _asString(map['paymentMethod']),
      metadata: _asMap(map['metadata']),
    );
  }
}

/// Main universal SOS/safety incident model.
///
/// Every service will store incidents using the same central structure.
class SafetyIncidentModel {
  const SafetyIncidentModel({
    required this.incidentId,
    required this.context,
    required this.category,
    required this.severity,
    required this.status,
    required this.createdAt,
    this.description = '',
    this.currentLocation,
    this.lastKnownLocation,
    this.locationHistory = const <SafetyLocation>[],
    this.networkStatus = SafetyNetworkStatus.unknown,
    this.locationStatus = SafetyLocationStatus.unknown,
    this.isSilentSos = false,
    this.isTestIncident = false,
    this.adminAcknowledged = false,
    this.adminAcknowledgedBy = '',
    this.assignedSafetyAgentId = '',
    this.emergencyServiceCalled = false,
    this.trustedContactsAlerted = false,
    this.userMarkedSafe = false,
    this.falseAlarm = false,
    this.routeDeviationDetected = false,
    this.updatedAt,
    this.acknowledgedAt,
    this.resolvedAt,
    this.resolutionReason = '',
    this.adminNotes = const <String>[],
    this.evidenceReferences = const <String>[],
    this.metadata = const <String, dynamic>{},
  });

  final String incidentId;
  final SafetyContext context;

  final SafetyEmergencyCategory category;
  final SafetySeverity severity;
  final SafetyIncidentStatus status;

  final String description;

  final SafetyLocation? currentLocation;
  final SafetyLocation? lastKnownLocation;
  final List<SafetyLocation> locationHistory;

  final SafetyNetworkStatus networkStatus;
  final SafetyLocationStatus locationStatus;

  final bool isSilentSos;
  final bool isTestIncident;

  final bool adminAcknowledged;
  final String adminAcknowledgedBy;
  final String assignedSafetyAgentId;

  final bool emergencyServiceCalled;
  final bool trustedContactsAlerted;
  final bool userMarkedSafe;
  final bool falseAlarm;
  final bool routeDeviationDetected;

  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? acknowledgedAt;
  final DateTime? resolvedAt;

  final String resolutionReason;

  final List<String> adminNotes;
  final List<String> evidenceReferences;

  final Map<String, dynamic> metadata;

  bool get isActive {
    return status != SafetyIncidentStatus.resolved &&
        status != SafetyIncidentStatus.falseAlarm &&
        status != SafetyIncidentStatus.closed;
  }

  bool get isCritical {
    return severity == SafetySeverity.critical;
  }

  SafetyIncidentModel copyWith({
    String? incidentId,
    SafetyContext? context,
    SafetyEmergencyCategory? category,
    SafetySeverity? severity,
    SafetyIncidentStatus? status,
    String? description,
    SafetyLocation? currentLocation,
    SafetyLocation? lastKnownLocation,
    List<SafetyLocation>? locationHistory,
    SafetyNetworkStatus? networkStatus,
    SafetyLocationStatus? locationStatus,
    bool? isSilentSos,
    bool? isTestIncident,
    bool? adminAcknowledged,
    String? adminAcknowledgedBy,
    String? assignedSafetyAgentId,
    bool? emergencyServiceCalled,
    bool? trustedContactsAlerted,
    bool? userMarkedSafe,
    bool? falseAlarm,
    bool? routeDeviationDetected,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? acknowledgedAt,
    DateTime? resolvedAt,
    String? resolutionReason,
    List<String>? adminNotes,
    List<String>? evidenceReferences,
    Map<String, dynamic>? metadata,
  }) {
    return SafetyIncidentModel(
      incidentId: incidentId ?? this.incidentId,
      context: context ?? this.context,
      category: category ?? this.category,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      description: description ?? this.description,
      currentLocation:
          currentLocation ?? this.currentLocation,
      lastKnownLocation:
          lastKnownLocation ?? this.lastKnownLocation,
      locationHistory:
          locationHistory ?? this.locationHistory,
      networkStatus: networkStatus ?? this.networkStatus,
      locationStatus:
          locationStatus ?? this.locationStatus,
      isSilentSos: isSilentSos ?? this.isSilentSos,
      isTestIncident:
          isTestIncident ?? this.isTestIncident,
      adminAcknowledged:
          adminAcknowledged ?? this.adminAcknowledged,
      adminAcknowledgedBy:
          adminAcknowledgedBy ?? this.adminAcknowledgedBy,
      assignedSafetyAgentId:
          assignedSafetyAgentId ??
              this.assignedSafetyAgentId,
      emergencyServiceCalled:
          emergencyServiceCalled ??
              this.emergencyServiceCalled,
      trustedContactsAlerted:
          trustedContactsAlerted ??
              this.trustedContactsAlerted,
      userMarkedSafe:
          userMarkedSafe ?? this.userMarkedSafe,
      falseAlarm: falseAlarm ?? this.falseAlarm,
      routeDeviationDetected:
          routeDeviationDetected ??
              this.routeDeviationDetected,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      acknowledgedAt:
          acknowledgedAt ?? this.acknowledgedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolutionReason:
          resolutionReason ?? this.resolutionReason,
      adminNotes: adminNotes ?? this.adminNotes,
      evidenceReferences:
          evidenceReferences ?? this.evidenceReferences,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'incidentId': incidentId,
      'context': context.toMap(),
      'serviceType': context.serviceType.name,
      'referenceId': context.referenceId,
      'initiatedByUserId': context.initiatedByUserId,
      'initiatedByRole': context.initiatedByRole.name,
      'category': category.name,
      'severity': severity.name,
      'status': status.name,
      'description': description,
      'currentLocation': currentLocation?.toMap(),
      'lastKnownLocation': lastKnownLocation?.toMap(),
      'locationHistory': locationHistory
          .map((SafetyLocation location) => location.toMap())
          .toList(),
      'networkStatus': networkStatus.name,
      'locationStatus': locationStatus.name,
      'isSilentSos': isSilentSos,
      'isTestIncident': isTestIncident,
      'adminAcknowledged': adminAcknowledged,
      'adminAcknowledgedBy': adminAcknowledgedBy,
      'assignedSafetyAgentId': assignedSafetyAgentId,
      'emergencyServiceCalled': emergencyServiceCalled,
      'trustedContactsAlerted': trustedContactsAlerted,
      'userMarkedSafe': userMarkedSafe,
      'falseAlarm': falseAlarm,
      'routeDeviationDetected': routeDeviationDetected,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'acknowledgedAt': acknowledgedAt?.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'resolutionReason': resolutionReason,
      'adminNotes': adminNotes,
      'evidenceReferences': evidenceReferences,
      'metadata': metadata,
    };
  }

  factory SafetyIncidentModel.fromMap(
    Map<String, dynamic> map,
  ) {
    final DateTime createdAt =
        _asDateTime(map['createdAt']) ?? DateTime.now();

    return SafetyIncidentModel(
      incidentId: _asString(map['incidentId']),
      context: SafetyContext.fromMap(
        _asMap(map['context']),
      ),
      category: safetyEmergencyCategoryFromString(
        _asString(map['category']),
      ),
      severity: safetySeverityFromString(
        _asString(map['severity']),
      ),
      status: safetyIncidentStatusFromString(
        _asString(map['status']),
      ),
      description: _asString(map['description']),
      currentLocation:
          _locationFromDynamic(map['currentLocation']),
      lastKnownLocation:
          _locationFromDynamic(map['lastKnownLocation']),
      locationHistory:
          _locationListFromDynamic(map['locationHistory']),
      networkStatus: safetyNetworkStatusFromString(
        _asString(map['networkStatus']),
      ),
      locationStatus: safetyLocationStatusFromString(
        _asString(map['locationStatus']),
      ),
      isSilentSos: _asBool(map['isSilentSos']),
      isTestIncident: _asBool(map['isTestIncident']),
      adminAcknowledged:
          _asBool(map['adminAcknowledged']),
      adminAcknowledgedBy:
          _asString(map['adminAcknowledgedBy']),
      assignedSafetyAgentId:
          _asString(map['assignedSafetyAgentId']),
      emergencyServiceCalled:
          _asBool(map['emergencyServiceCalled']),
      trustedContactsAlerted:
          _asBool(map['trustedContactsAlerted']),
      userMarkedSafe: _asBool(map['userMarkedSafe']),
      falseAlarm: _asBool(map['falseAlarm']),
      routeDeviationDetected:
          _asBool(map['routeDeviationDetected']),
      createdAt: createdAt,
      updatedAt: _asDateTime(map['updatedAt']),
      acknowledgedAt:
          _asDateTime(map['acknowledgedAt']),
      resolvedAt: _asDateTime(map['resolvedAt']),
      resolutionReason:
          _asString(map['resolutionReason']),
      adminNotes: _asStringList(map['adminNotes']),
      evidenceReferences:
          _asStringList(map['evidenceReferences']),
      metadata: _asMap(map['metadata']),
    );
  }
}

// -----------------------------------------------------------------------------
// ENUM PARSING HELPERS
// -----------------------------------------------------------------------------

SafetyServiceType safetyServiceTypeFromString(String value) {
  return SafetyServiceType.values.firstWhere(
    (SafetyServiceType item) => item.name == value,
    orElse: () => SafetyServiceType.general,
  );
}

SafetyUserRole safetyUserRoleFromString(String value) {
  return SafetyUserRole.values.firstWhere(
    (SafetyUserRole item) => item.name == value,
    orElse: () => SafetyUserRole.unknown,
  );
}

SafetyIncidentStatus safetyIncidentStatusFromString(
  String value,
) {
  return SafetyIncidentStatus.values.firstWhere(
    (SafetyIncidentStatus item) => item.name == value,
    orElse: () => SafetyIncidentStatus.created,
  );
}

SafetySeverity safetySeverityFromString(String value) {
  return SafetySeverity.values.firstWhere(
    (SafetySeverity item) => item.name == value,
    orElse: () => SafetySeverity.medium,
  );
}

SafetyEmergencyCategory safetyEmergencyCategoryFromString(
  String value,
) {
  return SafetyEmergencyCategory.values.firstWhere(
    (SafetyEmergencyCategory item) => item.name == value,
    orElse: () => SafetyEmergencyCategory.other,
  );
}

SafetySourcePage safetySourcePageFromString(String value) {
  return SafetySourcePage.values.firstWhere(
    (SafetySourcePage item) => item.name == value,
    orElse: () => SafetySourcePage.unknown,
  );
}

SafetyNetworkStatus safetyNetworkStatusFromString(
  String value,
) {
  return SafetyNetworkStatus.values.firstWhere(
    (SafetyNetworkStatus item) => item.name == value,
    orElse: () => SafetyNetworkStatus.unknown,
  );
}

SafetyLocationStatus safetyLocationStatusFromString(
  String value,
) {
  return SafetyLocationStatus.values.firstWhere(
    (SafetyLocationStatus item) => item.name == value,
    orElse: () => SafetyLocationStatus.unknown,
  );
}

// -----------------------------------------------------------------------------
// SAFE DATA CONVERSION HELPERS
// -----------------------------------------------------------------------------

String _asString(dynamic value) {
  if (value == null) {
    return '';
  }

  return value.toString();
}

bool _asBool(dynamic value) {
  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  if (value is String) {
    return value.toLowerCase() == 'true' || value == '1';
  }

  return false;
}

double _asDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    return double.tryParse(value) ?? 0;
  }

  return 0;
}

double? _asNullableDouble(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    return double.tryParse(value);
  }

  return null;
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

  // Supports Firestore Timestamp without importing cloud_firestore here.
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

List<String> _asStringList(dynamic value) {
  if (value is! List) {
    return <String>[];
  }

  return value
      .where((dynamic item) => item != null)
      .map((dynamic item) => item.toString())
      .toList();
}

SafetyPersonSnapshot? _personFromDynamic(dynamic value) {
  final Map<String, dynamic> map = _asMap(value);

  if (map.isEmpty) {
    return null;
  }

  return SafetyPersonSnapshot.fromMap(map);
}

List<SafetyPersonSnapshot> _personListFromDynamic(
  dynamic value,
) {
  if (value is! List) {
    return <SafetyPersonSnapshot>[];
  }

  return value
      .map((dynamic item) => _asMap(item))
      .where((Map<String, dynamic> map) => map.isNotEmpty)
      .map(SafetyPersonSnapshot.fromMap)
      .toList();
}

SafetyVehicleSnapshot? _vehicleFromDynamic(dynamic value) {
  final Map<String, dynamic> map = _asMap(value);

  if (map.isEmpty) {
    return null;
  }

  return SafetyVehicleSnapshot.fromMap(map);
}

SafetyLocation? _locationFromDynamic(dynamic value) {
  final Map<String, dynamic> map = _asMap(value);

  if (map.isEmpty) {
    return null;
  }

  return SafetyLocation.fromMap(map);
}

List<SafetyLocation> _locationListFromDynamic(
  dynamic value,
) {
  if (value is! List) {
    return <SafetyLocation>[];
  }

  return value
      .map((dynamic item) => _asMap(item))
      .where((Map<String, dynamic> map) => map.isNotEmpty)
      .map(SafetyLocation.fromMap)
      .toList();
}