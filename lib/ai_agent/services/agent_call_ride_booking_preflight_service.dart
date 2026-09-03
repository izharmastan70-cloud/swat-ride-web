import '../../driver/services/driver_availability_service.dart';
import '../../models/location_model.dart';
import '../../models/ride_pricing_model.dart';
import '../../models/vehicle_model.dart';
import '../../services/ride_pricing_service.dart';
import '../../services/ride_service_control_service.dart';
import '../models/agent_call_ride_booking_preflight.dart';

abstract class AgentCallRidePricingPreflightGateway {
  Future<AgentCallRideBookingFareSnapshot> estimate({
    required LocationModel pickup,
    required LocationModel destination,
    required VehicleModel vehicle,
  });
}

class AgentCallRidePricingServiceGateway
    implements AgentCallRidePricingPreflightGateway {
  AgentCallRidePricingServiceGateway({RidePricingService? service})
    : service = service ?? RidePricingService();

  final RidePricingService service;

  @override
  Future<AgentCallRideBookingFareSnapshot> estimate({
    required LocationModel pickup,
    required LocationModel destination,
    required VehicleModel vehicle,
  }) async {
    final RideFareEstimate estimate = await service.estimateFare(
      pickup: pickup,
      destination: destination,
      vehicle: vehicle,
    );

    return AgentCallRideBookingFareSnapshot(
      distanceKm: estimate.distanceKm,
      estimatedMinutes: estimate.estimatedMinutes,
      baseFare: estimate.baseFare,
      estimatedFare: estimate.estimatedFare,
      adminCommissionAmount: estimate.adminCommissionAmount,
      usedTestingRouteBypass: estimate.usedTestingRouteBypass,
    );
  }
}

abstract class AgentCallDriverAvailabilityPreflightGateway {
  Future<bool> hasAvailableDriver({required String vehicleType});
}

class AgentCallDriverAvailabilityServiceGateway
    implements AgentCallDriverAvailabilityPreflightGateway {
  AgentCallDriverAvailabilityServiceGateway({
    DriverAvailabilityService? service,
  }) : service = service ?? DriverAvailabilityService();

  final DriverAvailabilityService service;

  @override
  Future<bool> hasAvailableDriver({required String vehicleType}) {
    return service.hasAvailableDriver(vehicleType: vehicleType);
  }
}

abstract class AgentCallRideServiceControlPreflightGateway {
  Future<bool> canCreateNewRide();
}

class AgentCallRideServiceControlGateway
    implements AgentCallRideServiceControlPreflightGateway {
  AgentCallRideServiceControlGateway({RideServiceControlService? service})
    : service = service ?? RideServiceControlService();

  final RideServiceControlService service;

  @override
  Future<bool> canCreateNewRide() {
    return service.canCreateNewRide();
  }
}

abstract class AgentCallRideBookingDomainResolverGateway {
  Future<LocationModel> resolveLocation(
    AgentCallRideBookingResolvedLocation location,
  );

  Future<VehicleModel> resolveVehicle(
    AgentCallRideBookingResolvedVehicle vehicle,
  );
}

/// Phase 49 Step 1C verified preflight.
///
/// This service performs only the safe prerequisites needed before the Step 1B
/// execution contract can become ready:
/// - trusted location resolution;
/// - exact vehicle resolution;
/// - Ride service-control check;
/// - driver availability check;
/// - fare estimation with provenance.
///
/// It does NOT create a Ride, does NOT write Firestore, and does NOT invoke
/// telephony/STT/TTS/SMS/payment/admin mutation.
class AgentCallRideBookingPreflightService {
  const AgentCallRideBookingPreflightService({
    required this.domainResolver,
    required this.pricingGateway,
    required this.driverAvailabilityGateway,
    required this.rideServiceControlGateway,
  });

  final AgentCallRideBookingDomainResolverGateway domainResolver;
  final AgentCallRidePricingPreflightGateway pricingGateway;
  final AgentCallDriverAvailabilityPreflightGateway driverAvailabilityGateway;
  final AgentCallRideServiceControlPreflightGateway rideServiceControlGateway;

  Future<AgentCallRideBookingPreflightResult> verify({
    required AgentCallRideBookingPreflightRequest request,
  }) async {
    request.validate();

    final bool rideServiceAvailable = await rideServiceControlGateway
        .canCreateNewRide();

    if (!rideServiceAvailable) {
      return _unavailable(
        request: request,
        code: 'RIDE_SERVICE_UNAVAILABLE',
        rideServiceAvailable: false,
        driverAvailable: false,
      );
    }

    final LocationModel pickup = await domainResolver.resolveLocation(
      request.pickup,
    );

    final LocationModel destination = await domainResolver.resolveLocation(
      request.destination,
    );

    final VehicleModel vehicle = await domainResolver.resolveVehicle(
      request.vehicle,
    );

    final bool driverAvailable = await driverAvailabilityGateway
        .hasAvailableDriver(vehicleType: request.vehicle.vehicleType.trim());

    if (!driverAvailable) {
      return _unavailable(
        request: request,
        code: 'NO_MATCHING_DRIVER_AVAILABLE',
        rideServiceAvailable: true,
        driverAvailable: false,
      );
    }

    final AgentCallRideBookingFareSnapshot fare = await pricingGateway.estimate(
      pickup: pickup,
      destination: destination,
      vehicle: vehicle,
    );

    fare.validate();

    final AgentCallRideBookingPreflightResult result =
        AgentCallRideBookingPreflightResult(
          status: AgentCallRideBookingPreflightStatus.verified,
          code: fare.usedTestingRouteBypass
              ? 'VERIFIED_TEST_ROUTE_ESTIMATE'
              : 'VERIFIED_PRODUCTION_ROUTE_ESTIMATE',
          preflightId: request.preflightId.trim(),
          pickup: request.pickup,
          destination: request.destination,
          vehicle: request.vehicle,
          fare: fare,
          driverAvailable: true,
          rideServiceAvailable: true,
          verifiedAt: request.now,
          expiresAt: request.now.add(request.validFor),
        );

    result.validate();
    return result;
  }

  AgentCallRideBookingPreflightResult _unavailable({
    required AgentCallRideBookingPreflightRequest request,
    required String code,
    required bool rideServiceAvailable,
    required bool driverAvailable,
  }) {
    final AgentCallRideBookingPreflightResult result =
        AgentCallRideBookingPreflightResult(
          status: AgentCallRideBookingPreflightStatus.unavailable,
          code: code,
          preflightId: request.preflightId.trim(),
          pickup: request.pickup,
          destination: request.destination,
          vehicle: request.vehicle,
          driverAvailable: driverAvailable,
          rideServiceAvailable: rideServiceAvailable,
          verifiedAt: request.now,
          expiresAt: request.now.add(request.validFor),
        );

    result.validate();
    return result;
  }

  bool get writesRide => false;
  bool get writesFirestore => false;
  bool get usesCurrentFirebaseUserAsCaller => false;
  bool get createsApproval => false;
  bool get consumesApproval => false;
  bool get changesPricing => false;
  bool get changesCommission => false;
  bool get changesPayment => false;
  bool get changesDriverState => false;
  bool get sendsSms => false;
  bool get invokesTelephonyProvider => false;
  bool get invokesSpeechToTextProvider => false;
  bool get invokesTextToSpeechProvider => false;
  bool get storesRawAudio => false;
  bool get deploys => false;
}
