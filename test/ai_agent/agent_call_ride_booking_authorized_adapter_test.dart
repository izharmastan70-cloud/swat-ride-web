import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/models/agent_call_ride_booking_draft.dart';
import 'package:swat_ride/ai_agent/models/agent_call_ride_booking_execution_contract.dart';
import 'package:swat_ride/ai_agent/services/agent_call_ride_booking_authorized_adapter.dart';

AgentCallRideBookingDraft _draft({
  bool confirmed = true,
  String vehicleType = 'car',
}) {
  return AgentCallRideBookingDraft(
    customerName: 'Test Caller',
    contactPhoneMasked: '03******567',
    pickup: 'Mingora',
    destination: 'Saidu Sharif',
    vehicleType: vehicleType,
    customerConfirmed: confirmed,
  );
}

AgentCallRideFareVerification _fare({
  bool driverAvailable = true,
  bool rideServiceAvailable = true,
  bool testingRoute = false,
  String vehicleType = 'car',
  DateTime? verifiedAt,
  DateTime? expiresAt,
}) {
  final DateTime verified = verifiedAt ?? DateTime.utc(2026, 8, 18, 6, 30);

  return AgentCallRideFareVerification(
    pickupReferenceId: 'pickup-ref-1',
    destinationReferenceId: 'destination-ref-1',
    vehicleId: 'vehicle-1',
    vehicleType: vehicleType,
    distanceKm: 5.5,
    estimatedMinutes: 15,
    baseFare: 150,
    estimatedFare: 350,
    adminCommissionAmount: 35,
    driverAvailable: driverAvailable,
    rideServiceAvailable: rideServiceAvailable,
    usedTestingRouteBypass: testingRoute,
    verifiedAt: verified,
    expiresAt: expiresAt ?? verified.add(const Duration(minutes: 5)),
  );
}

AgentCallRideBookingAuthorization _auth({
  bool master = true,
  bool runtime = true,
  bool permission = true,
  bool dedicatedAction = true,
  bool callerBound = true,
  bool contactBound = true,
  bool idempotencyReserved = true,
}) {
  final bool allowed =
      master &&
      runtime &&
      permission &&
      dedicatedAction &&
      callerBound &&
      contactBound &&
      idempotencyReserved;

  return AgentCallRideBookingAuthorization(
    callAgentMasterEnabled: master,
    runtimeAllowed: runtime,
    permissionAllowed: permission,
    dedicatedBookingActionAllowed: dedicatedAction,
    trustedCallerBound: callerBound,
    trustedContactBound: contactBound,
    idempotencyKeyReserved: idempotencyReserved,
    reason: allowed ? '' : 'blocked by test authority',
  );
}

AgentCallRideBookingExecutionRequest _request({
  String mode = AgentCallRideBookingExecutionMode.production,
  bool confirmed = true,
  bool driverAvailable = true,
  bool rideServiceAvailable = true,
  bool testingRoute = false,
  AgentCallRideBookingAuthorization? authorization,
  DateTime? verifiedAt,
  DateTime? expiresAt,
}) {
  return AgentCallRideBookingExecutionRequest(
    executionId: 'call-booking-exec-1',
    idempotencyKey: 'call-session-1:booking-1',
    mode: mode,
    trustedCallerReferenceId: 'caller-ref-1',
    trustedContactReferenceId: 'contact-ref-1',
    draft: _draft(confirmed: confirmed),
    fareVerification: _fare(
      driverAvailable: driverAvailable,
      rideServiceAvailable: rideServiceAvailable,
      testingRoute: testingRoute,
      verifiedAt: verifiedAt,
      expiresAt: expiresAt,
    ),
    authorization: authorization ?? _auth(),
    createdAt: DateTime.utc(2026, 8, 18, 6, 31),
  );
}

void main() {
  const AgentCallRideBookingAuthorizedAdapter adapter =
      AgentCallRideBookingAuthorizedAdapter();

  final DateTime now = DateTime.utc(2026, 8, 18, 6, 31);

  group('Phase 49 Step 1B Call Ride Booking adapter contract', () {
    test(
      'fully satisfied production request becomes ready for trusted backend',
      () async {
        final AgentCallRideBookingExecutionResult result = await adapter
            .prepareForTrustedBackend(request: _request(), now: now);

        expect(result.isReadyForTrustedBackend, isTrue);
        expect(result.rideId, isNull);
        expect(result.realRideWritePerformed, isFalse);
      },
    );

    test('customer confirmation is mandatory', () async {
      final AgentCallRideBookingExecutionResult result = await adapter
          .prepareForTrustedBackend(
            request: _request(confirmed: false),
            now: now,
          );

      expect(result.isBlocked, isTrue);
      expect(result.code, 'CUSTOMER_CONFIRMATION_REQUIRED');
    });

    test('testing route can never authorize production booking', () async {
      final AgentCallRideBookingExecutionResult result = await adapter
          .prepareForTrustedBackend(
            request: _request(testingRoute: true),
            now: now,
          );

      expect(result.isBlocked, isTrue);
      expect(result.code, 'PRODUCTION_ROUTE_VERIFICATION_REQUIRED');
    });

    test('test mode never creates real ride', () async {
      final AgentCallRideBookingExecutionResult result = await adapter
          .prepareForTrustedBackend(
            request: _request(mode: AgentCallRideBookingExecutionMode.test),
            now: now,
          );

      expect(result.isBlocked, isTrue);
      expect(result.code, 'TEST_MODE_REAL_BOOKING_DISABLED');
    });

    test('missing dedicated write authority fails closed', () async {
      final AgentCallRideBookingExecutionResult result = await adapter
          .prepareForTrustedBackend(
            request: _request(authorization: _auth(dedicatedAction: false)),
            now: now,
          );

      expect(result.isBlocked, isTrue);
      expect(result.code, 'CALL_BOOKING_AUTHORIZATION_BLOCKED');
    });

    test('driver and ride service availability both gate booking', () async {
      final AgentCallRideBookingExecutionResult noDriver = await adapter
          .prepareForTrustedBackend(
            request: _request(driverAvailable: false),
            now: now,
          );

      final AgentCallRideBookingExecutionResult serviceOff = await adapter
          .prepareForTrustedBackend(
            request: _request(rideServiceAvailable: false),
            now: now,
          );

      expect(noDriver.code, 'NO_MATCHING_DRIVER_AVAILABLE');
      expect(serviceOff.code, 'RIDE_SERVICE_UNAVAILABLE');
    });

    test('expired fare verification fails closed', () async {
      final DateTime verified = DateTime.utc(2026, 8, 18, 6);

      final AgentCallRideBookingExecutionResult result = await adapter
          .prepareForTrustedBackend(
            request: _request(
              verifiedAt: verified,
              expiresAt: verified.add(const Duration(minutes: 5)),
            ),
            now: DateTime.utc(2026, 8, 18, 6, 10),
          );

      expect(result.isBlocked, isTrue);
      expect(result.code, 'FARE_VERIFICATION_EXPIRED');
    });

    test('vehicle mismatch is rejected by contract validation', () async {
      final AgentCallRideBookingExecutionRequest request =
          AgentCallRideBookingExecutionRequest(
            executionId: 'exec-mismatch',
            idempotencyKey: 'session:mismatch',
            mode: AgentCallRideBookingExecutionMode.production,
            trustedCallerReferenceId: 'caller-ref',
            trustedContactReferenceId: 'contact-ref',
            draft: _draft(vehicleType: 'car'),
            fareVerification: _fare(vehicleType: 'bike'),
            authorization: _auth(),
            createdAt: now,
          );

      expect(
        () => adapter.prepareForTrustedBackend(request: request, now: now),
        throwsA(isA<AgentCallRideBookingContractException>()),
      );
    });

    test('adapter exposes no real write/provider/admin authority', () {
      expect(adapter.writesFirestore, isFalse);
      expect(adapter.writesRide, isFalse);
      expect(adapter.usesCurrentFirebaseUserAsCaller, isFalse);
      expect(adapter.createsApproval, isFalse);
      expect(adapter.consumesApproval, isFalse);
      expect(adapter.changesPricing, isFalse);
      expect(adapter.changesCommission, isFalse);
      expect(adapter.changesPayment, isFalse);
      expect(adapter.sendsSms, isFalse);
      expect(adapter.invokesTelephonyProvider, isFalse);
      expect(adapter.invokesSpeechToTextProvider, isFalse);
      expect(adapter.invokesTextToSpeechProvider, isFalse);
      expect(adapter.storesRawAudio, isFalse);
      expect(adapter.deploys, isFalse);

      expect(adapter.requiresDedicatedWriteAction, isTrue);
      expect(adapter.requiresTrustedCallerBinding, isTrue);
      expect(adapter.requiresTrustedContactBinding, isTrue);
      expect(adapter.requiresIdempotencyReservation, isTrue);
      expect(adapter.requiresFreshVerifiedFare, isTrue);
      expect(adapter.requiresDriverAvailability, isTrue);
      expect(adapter.requiresRideServiceAvailability, isTrue);
      expect(adapter.requiresExplicitCustomerConfirmation, isTrue);
      expect(adapter.rejectsTestingRouteForProduction, isTrue);
    });
  });
}
