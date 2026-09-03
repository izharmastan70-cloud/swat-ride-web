import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/models/agent_call_ride_booking_preflight.dart';
import 'package:swat_ride/ai_agent/services/agent_call_ride_booking_preflight_service.dart';
import 'package:swat_ride/models/location_model.dart';
import 'package:swat_ride/models/vehicle_model.dart';

class _FakeDomainResolver implements AgentCallRideBookingDomainResolverGateway {
  int locationCalls = 0;
  int vehicleCalls = 0;

  @override
  Future<LocationModel> resolveLocation(
    AgentCallRideBookingResolvedLocation location,
  ) async {
    locationCalls += 1;
    throw UnimplementedError(
      'Fake resolver object output is intentionally not needed when service-control or driver gate blocks.',
    );
  }

  @override
  Future<VehicleModel> resolveVehicle(
    AgentCallRideBookingResolvedVehicle vehicle,
  ) async {
    vehicleCalls += 1;
    throw UnimplementedError(
      'Fake resolver object output is intentionally not needed when service-control or driver gate blocks.',
    );
  }
}

class _NeverPricingGateway implements AgentCallRidePricingPreflightGateway {
  int calls = 0;

  @override
  Future<AgentCallRideBookingFareSnapshot> estimate({
    required LocationModel pickup,
    required LocationModel destination,
    required VehicleModel vehicle,
  }) async {
    calls += 1;
    throw StateError('Pricing should not be reached in this test.');
  }
}

class _DriverGateway implements AgentCallDriverAvailabilityPreflightGateway {
  _DriverGateway(this.available);

  final bool available;
  int calls = 0;

  @override
  Future<bool> hasAvailableDriver({required String vehicleType}) async {
    calls += 1;
    return available;
  }
}

class _ServiceControlGateway
    implements AgentCallRideServiceControlPreflightGateway {
  _ServiceControlGateway(this.available);

  final bool available;
  int calls = 0;

  @override
  Future<bool> canCreateNewRide() async {
    calls += 1;
    return available;
  }
}

AgentCallRideBookingPreflightRequest _request() {
  return AgentCallRideBookingPreflightRequest(
    preflightId: 'preflight-1',
    pickup: const AgentCallRideBookingResolvedLocation(
      referenceId: 'pickup-ref-1',
      displayText: 'Mingora',
      latitude: 34.7717,
      longitude: 72.3602,
      source: 'trusted_location_resolver',
    ),
    destination: const AgentCallRideBookingResolvedLocation(
      referenceId: 'destination-ref-1',
      displayText: 'Saidu Sharif',
      latitude: 34.7464,
      longitude: 72.3571,
      source: 'trusted_location_resolver',
    ),
    vehicle: const AgentCallRideBookingResolvedVehicle(
      vehicleId: 'vehicle-1',
      vehicleType: 'car',
      vehicleName: 'Car',
      source: 'vehicle_catalog',
    ),
    now: DateTime.utc(2026, 8, 18, 7),
  );
}

void main() {
  group('Phase 49 Step 1C verified booking preflight', () {
    test(
      'service-control failure stops before location/vehicle/fare work',
      () async {
        final resolver = _FakeDomainResolver();
        final pricing = _NeverPricingGateway();
        final driver = _DriverGateway(true);
        final serviceControl = _ServiceControlGateway(false);

        final service = AgentCallRideBookingPreflightService(
          domainResolver: resolver,
          pricingGateway: pricing,
          driverAvailabilityGateway: driver,
          rideServiceControlGateway: serviceControl,
        );

        final result = await service.verify(request: _request());

        expect(result.isUnavailable, isTrue);
        expect(result.code, 'RIDE_SERVICE_UNAVAILABLE');
        expect(serviceControl.calls, 1);
        expect(resolver.locationCalls, 0);
        expect(resolver.vehicleCalls, 0);
        expect(driver.calls, 0);
        expect(pricing.calls, 0);
      },
    );

    test(
      'request requires different trusted pickup and destination references',
      () {
        final AgentCallRideBookingPreflightRequest request =
            AgentCallRideBookingPreflightRequest(
              preflightId: 'same-location',
              pickup: const AgentCallRideBookingResolvedLocation(
                referenceId: 'same-ref',
                displayText: 'Mingora',
                latitude: 34.77,
                longitude: 72.36,
                source: 'trusted_location_resolver',
              ),
              destination: const AgentCallRideBookingResolvedLocation(
                referenceId: 'same-ref',
                displayText: 'Mingora',
                latitude: 34.77,
                longitude: 72.36,
                source: 'trusted_location_resolver',
              ),
              vehicle: const AgentCallRideBookingResolvedVehicle(
                vehicleId: 'vehicle-1',
                vehicleType: 'car',
                vehicleName: 'Car',
                source: 'vehicle_catalog',
              ),
              now: DateTime.utc(2026, 8, 18, 7),
            );

        expect(
          request.validate,
          throwsA(isA<AgentCallRideBookingPreflightException>()),
        );
      },
    );

    test('location requires trusted source and valid coordinates', () {
      const AgentCallRideBookingResolvedLocation location =
          AgentCallRideBookingResolvedLocation(
            referenceId: 'pickup-ref',
            displayText: 'Pickup',
            latitude: 91,
            longitude: 72,
            source: '',
          );

      expect(
        location.validate,
        throwsA(isA<AgentCallRideBookingPreflightException>()),
      );
    });

    test('resolved vehicle requires exact ID/type/name/source', () {
      const AgentCallRideBookingResolvedVehicle vehicle =
          AgentCallRideBookingResolvedVehicle(
            vehicleId: '',
            vehicleType: 'car',
            vehicleName: 'Car',
            source: 'vehicle_catalog',
          );

      expect(
        vehicle.validate,
        throwsA(isA<AgentCallRideBookingPreflightException>()),
      );
    });

    test(
      'testing-route provenance is preserved into Step 1B fare verification',
      () {
        final AgentCallRideBookingPreflightRequest request = _request();

        final result = AgentCallRideBookingPreflightResult(
          status: AgentCallRideBookingPreflightStatus.verified,
          code: 'VERIFIED_TEST_ROUTE_ESTIMATE',
          preflightId: request.preflightId,
          pickup: request.pickup,
          destination: request.destination,
          vehicle: request.vehicle,
          fare: const AgentCallRideBookingFareSnapshot(
            distanceKm: 5,
            estimatedMinutes: 12,
            baseFare: 150,
            estimatedFare: 300,
            adminCommissionAmount: 30,
            usedTestingRouteBypass: true,
          ),
          driverAvailable: true,
          rideServiceAvailable: true,
          verifiedAt: request.now,
          expiresAt: request.now.add(const Duration(minutes: 5)),
        );

        result.validate();

        final executionFare = result.toExecutionFareVerification();

        expect(executionFare.usedTestingRouteBypass, isTrue);
        expect(executionFare.driverAvailable, isTrue);
        expect(executionFare.rideServiceAvailable, isTrue);
        expect(executionFare.pickupReferenceId, 'pickup-ref-1');
        expect(executionFare.destinationReferenceId, 'destination-ref-1');
        expect(executionFare.vehicleId, 'vehicle-1');
      },
    );

    test(
      'unavailable result cannot become Step 1B execution fare verification',
      () {
        final AgentCallRideBookingPreflightRequest request = _request();

        final result = AgentCallRideBookingPreflightResult(
          status: AgentCallRideBookingPreflightStatus.unavailable,
          code: 'RIDE_SERVICE_UNAVAILABLE',
          preflightId: request.preflightId,
          pickup: request.pickup,
          destination: request.destination,
          vehicle: request.vehicle,
          driverAvailable: false,
          rideServiceAvailable: false,
          verifiedAt: request.now,
          expiresAt: request.now.add(const Duration(minutes: 5)),
        );

        expect(
          result.toExecutionFareVerification,
          throwsA(isA<AgentCallRideBookingPreflightException>()),
        );
      },
    );

    test('preflight exposes no write/provider/admin authority', () {
      final service = AgentCallRideBookingPreflightService(
        domainResolver: _FakeDomainResolver(),
        pricingGateway: _NeverPricingGateway(),
        driverAvailabilityGateway: _DriverGateway(false),
        rideServiceControlGateway: _ServiceControlGateway(false),
      );

      expect(service.writesRide, isFalse);
      expect(service.writesFirestore, isFalse);
      expect(service.usesCurrentFirebaseUserAsCaller, isFalse);
      expect(service.createsApproval, isFalse);
      expect(service.consumesApproval, isFalse);
      expect(service.changesPricing, isFalse);
      expect(service.changesCommission, isFalse);
      expect(service.changesPayment, isFalse);
      expect(service.changesDriverState, isFalse);
      expect(service.sendsSms, isFalse);
      expect(service.invokesTelephonyProvider, isFalse);
      expect(service.invokesSpeechToTextProvider, isFalse);
      expect(service.invokesTextToSpeechProvider, isFalse);
      expect(service.storesRawAudio, isFalse);
      expect(service.deploys, isFalse);
    });
  });
}
