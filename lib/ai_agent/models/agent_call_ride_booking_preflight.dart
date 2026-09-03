import 'agent_call_ride_booking_execution_contract.dart';

class AgentCallRideBookingPreflightStatus {
  AgentCallRideBookingPreflightStatus._();

  static const String verified = 'VERIFIED';
  static const String unavailable = 'UNAVAILABLE';

  static const Set<String> values = <String>{verified, unavailable};
}

class AgentCallRideBookingResolvedLocation {
  const AgentCallRideBookingResolvedLocation({
    required this.referenceId,
    required this.displayText,
    required this.latitude,
    required this.longitude,
    required this.source,
  });

  final String referenceId;
  final String displayText;
  final double latitude;
  final double longitude;

  /// Trusted resolver/source identifier. Free-form call text is not a
  /// sufficient production location source by itself.
  final String source;

  bool get isResolved =>
      referenceId.trim().isNotEmpty &&
      displayText.trim().isNotEmpty &&
      source.trim().isNotEmpty &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  void validate() {
    if (!isResolved) {
      throw const AgentCallRideBookingPreflightException(
        'Trusted resolved location is required.',
      );
    }
  }
}

class AgentCallRideBookingResolvedVehicle {
  const AgentCallRideBookingResolvedVehicle({
    required this.vehicleId,
    required this.vehicleType,
    required this.vehicleName,
    required this.source,
  });

  final String vehicleId;
  final String vehicleType;
  final String vehicleName;
  final String source;

  bool get isResolved =>
      vehicleId.trim().isNotEmpty &&
      vehicleType.trim().isNotEmpty &&
      vehicleName.trim().isNotEmpty &&
      source.trim().isNotEmpty;

  void validate() {
    if (!isResolved) {
      throw const AgentCallRideBookingPreflightException(
        'Trusted resolved vehicle is required.',
      );
    }
  }
}

class AgentCallRideBookingFareSnapshot {
  const AgentCallRideBookingFareSnapshot({
    required this.distanceKm,
    required this.estimatedMinutes,
    required this.baseFare,
    required this.estimatedFare,
    required this.adminCommissionAmount,
    required this.usedTestingRouteBypass,
  });

  final double distanceKm;
  final int estimatedMinutes;
  final double baseFare;
  final double estimatedFare;
  final double adminCommissionAmount;
  final bool usedTestingRouteBypass;

  void validate() {
    if (distanceKm < 0 ||
        estimatedMinutes < 0 ||
        baseFare < 0 ||
        estimatedFare < 0 ||
        adminCommissionAmount < 0) {
      throw const AgentCallRideBookingPreflightException(
        'Preflight fare values cannot be negative.',
      );
    }
  }
}

class AgentCallRideBookingPreflightRequest {
  const AgentCallRideBookingPreflightRequest({
    required this.preflightId,
    required this.pickup,
    required this.destination,
    required this.vehicle,
    required this.now,
    this.validFor = const Duration(minutes: 5),
  });

  final String preflightId;
  final AgentCallRideBookingResolvedLocation pickup;
  final AgentCallRideBookingResolvedLocation destination;
  final AgentCallRideBookingResolvedVehicle vehicle;
  final DateTime now;
  final Duration validFor;

  void validate() {
    if (preflightId.trim().isEmpty) {
      throw const AgentCallRideBookingPreflightException(
        'Preflight ID is required.',
      );
    }

    pickup.validate();
    destination.validate();
    vehicle.validate();

    if (pickup.referenceId.trim() == destination.referenceId.trim()) {
      throw const AgentCallRideBookingPreflightException(
        'Pickup and destination references must be different.',
      );
    }

    if (validFor <= Duration.zero || validFor > const Duration(minutes: 10)) {
      throw const AgentCallRideBookingPreflightException(
        'Preflight validity must be greater than zero and at most 10 minutes.',
      );
    }
  }
}

class AgentCallRideBookingPreflightResult {
  const AgentCallRideBookingPreflightResult({
    required this.status,
    required this.code,
    required this.preflightId,
    required this.pickup,
    required this.destination,
    required this.vehicle,
    required this.driverAvailable,
    required this.rideServiceAvailable,
    required this.verifiedAt,
    required this.expiresAt,
    this.fare,
  });

  final String status;
  final String code;
  final String preflightId;

  final AgentCallRideBookingResolvedLocation pickup;
  final AgentCallRideBookingResolvedLocation destination;
  final AgentCallRideBookingResolvedVehicle vehicle;

  final AgentCallRideBookingFareSnapshot? fare;
  final bool driverAvailable;
  final bool rideServiceAvailable;

  final DateTime verifiedAt;
  final DateTime expiresAt;

  bool get isVerified => status == AgentCallRideBookingPreflightStatus.verified;
  bool get isUnavailable =>
      status == AgentCallRideBookingPreflightStatus.unavailable;

  bool get usesTestingRouteBypass => fare?.usedTestingRouteBypass ?? false;

  bool isFreshAt(DateTime now) =>
      expiresAt.toUtc().isAfter(now.toUtc()) &&
      !verifiedAt.toUtc().isAfter(now.toUtc());

  AgentCallRideFareVerification toExecutionFareVerification() {
    if (!isVerified || fare == null) {
      throw const AgentCallRideBookingPreflightException(
        'Only VERIFIED preflight can become execution fare verification.',
      );
    }

    final AgentCallRideBookingFareSnapshot value = fare!;

    return AgentCallRideFareVerification(
      pickupReferenceId: pickup.referenceId.trim(),
      destinationReferenceId: destination.referenceId.trim(),
      vehicleId: vehicle.vehicleId.trim(),
      vehicleType: vehicle.vehicleType.trim(),
      distanceKm: value.distanceKm,
      estimatedMinutes: value.estimatedMinutes,
      baseFare: value.baseFare,
      estimatedFare: value.estimatedFare,
      adminCommissionAmount: value.adminCommissionAmount,
      driverAvailable: driverAvailable,
      rideServiceAvailable: rideServiceAvailable,
      usedTestingRouteBypass: value.usedTestingRouteBypass,
      verifiedAt: verifiedAt,
      expiresAt: expiresAt,
    );
  }

  void validate() {
    if (!AgentCallRideBookingPreflightStatus.values.contains(status) ||
        code.trim().isEmpty ||
        preflightId.trim().isEmpty) {
      throw const AgentCallRideBookingPreflightException(
        'Invalid Call Ride Booking preflight result.',
      );
    }

    pickup.validate();
    destination.validate();
    vehicle.validate();

    if (!expiresAt.toUtc().isAfter(verifiedAt.toUtc())) {
      throw const AgentCallRideBookingPreflightException(
        'Preflight expiry must be after verification time.',
      );
    }

    if (isVerified) {
      if (fare == null || !rideServiceAvailable || !driverAvailable) {
        throw const AgentCallRideBookingPreflightException(
          'VERIFIED preflight requires fare, ride service and driver availability.',
        );
      }

      fare!.validate();
    }
  }

  bool get writesRide => false;
  bool get writesFirestore => false;
  bool get createsApproval => false;
  bool get changesPricing => false;
  bool get changesDriverState => false;
  bool get sendsSms => false;
  bool get invokesTelephonyProvider => false;
}

class AgentCallRideBookingPreflightException implements Exception {
  const AgentCallRideBookingPreflightException(this.message);

  final String message;

  @override
  String toString() => 'AgentCallRideBookingPreflightException: $message';
}
