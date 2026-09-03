import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_action_ids.dart';
import 'package:swat_ride/ai_agent/models/agent_call_ride_booking_customer_confirmation.dart';
import 'package:swat_ride/ai_agent/models/agent_call_ride_booking_draft.dart';
import 'package:swat_ride/ai_agent/models/agent_call_ride_booking_execution_contract.dart';
import 'package:swat_ride/ai_agent/services/agent_call_ride_booking_authorized_adapter.dart';
import 'package:swat_ride/ai_agent/services/agent_call_ride_booking_customer_confirmation_boundary.dart';

class _FakeTrustedConfirmationGateway
    implements AgentCallRideBookingCustomerConfirmationGateway {
  int calls = 0;
  bool throwError = false;
  bool oneTimeConsumed = true;
  String source =
      AgentCallRideBookingCustomerConfirmationVerification.trustedBackendSource;

  Duration lifetime = const Duration(minutes: 1);
  Duration issuedOffset = Duration.zero;
  Duration expiryOffset = Duration.zero;

  AgentCallRideBookingCustomerConfirmationScope Function(
    AgentCallRideBookingCustomerConfirmationScope scope,
  )?
  mutateScope;

  @override
  Future<AgentCallRideBookingCustomerConfirmationVerification>
  verifyAndConsume({
    required String tokenReferenceId,
    required AgentCallRideBookingCustomerConfirmationScope expectedScope,
    required DateTime now,
  }) async {
    calls += 1;

    if (throwError) {
      throw StateError('test gateway failure');
    }

    final DateTime verifiedAt = now.toUtc().add(issuedOffset);

    final DateTime expiresAt = verifiedAt.add(lifetime).add(expiryOffset);

    return AgentCallRideBookingCustomerConfirmationVerification(
      status: AgentCallRideBookingCustomerConfirmationStatus.verified,
      code: 'TEST_VERIFIED',
      tokenReferenceId: tokenReferenceId,
      verificationSource: source,
      oneTimeConsumed: oneTimeConsumed,
      scope: mutateScope?.call(expectedScope) ?? expectedScope,
      verifiedAt: verifiedAt,
      expiresAt: expiresAt,
      reason: '',
    );
  }
}

AgentCallRideBookingDraft _draft({bool confirmed = true}) {
  return AgentCallRideBookingDraft(
    customerName: 'Test Customer',
    contactPhoneMasked: '03******123',
    pickup: 'Trusted Pickup',
    destination: 'Trusted Destination',
    vehicleType: 'car',
    customerConfirmed: confirmed,
  );
}

AgentCallRideFareVerification _fare({
  DateTime? verifiedAt,
  DateTime? expiresAt,
  double estimatedFare = 650,
}) {
  final DateTime verified = verifiedAt ?? DateTime.utc(2026, 8, 18, 8, 0);

  return AgentCallRideFareVerification(
    pickupReferenceId: 'pickup-ref-1',
    destinationReferenceId: 'destination-ref-1',
    vehicleId: 'vehicle-1',
    vehicleType: 'car',
    distanceKm: 12.5,
    estimatedMinutes: 25,
    baseFare: 150,
    estimatedFare: estimatedFare,
    adminCommissionAmount: 65,
    driverAvailable: true,
    rideServiceAvailable: true,
    usedTestingRouteBypass: false,
    verifiedAt: verified,
    expiresAt: expiresAt ?? verified.add(const Duration(minutes: 5)),
  );
}

AgentCallRideBookingAuthorization _authorization() {
  return const AgentCallRideBookingAuthorization(
    callAgentMasterEnabled: true,
    runtimeAllowed: true,
    permissionAllowed: true,
    dedicatedBookingActionAllowed: true,
    trustedCallerBound: true,
    trustedContactBound: true,
    idempotencyKeyReserved: true,
    reason: '',
  );
}

AgentCallRideBookingExecutionRequest _request({
  bool confirmed = true,
  AgentCallRideFareVerification? fare,
}) {
  return AgentCallRideBookingExecutionRequest(
    executionId: 'execution-1',
    idempotencyKey: 'call-session-1:booking-1',
    mode: AgentCallRideBookingExecutionMode.production,
    trustedCallerReferenceId: 'caller-ref-1',
    trustedContactReferenceId: 'contact-ref-1',
    draft: _draft(confirmed: confirmed),
    fareVerification: fare ?? _fare(),
    authorization: _authorization(),
    createdAt: DateTime.utc(2026, 8, 18, 8, 0, 30),
  );
}

AgentCallRideBookingCustomerConfirmationBoundary _boundary(
  _FakeTrustedConfirmationGateway gateway,
) {
  return AgentCallRideBookingCustomerConfirmationBoundary(
    confirmationGateway: gateway,
  );
}

void main() {
  final DateTime now = DateTime.utc(2026, 8, 18, 8, 1);

  group('Phase 49 Step 1F customer confirmation boundary', () {
    test('boolean customerConfirmed alone cannot pass without token', () async {
      final gateway = _FakeTrustedConfirmationGateway();
      final result = await _boundary(gateway).verifyForTrustedBackend(
        request: _request(confirmed: true),
        callSessionId: 'call-session-1',
        requestedBy: 'trusted-call-session-1',
        tokenReferenceId: '',
        now: now,
      );

      expect(result.isBlocked, isTrue);
      expect(result.code, 'CUSTOMER_CONFIRMATION_TOKEN_REQUIRED');
      expect(gateway.calls, 0);
    });

    test('customerConfirmed false blocks before token gateway', () async {
      final gateway = _FakeTrustedConfirmationGateway();

      final result = await _boundary(gateway).verifyForTrustedBackend(
        request: _request(confirmed: false),
        callSessionId: 'call-session-1',
        requestedBy: 'trusted-call-session-1',
        tokenReferenceId: 'confirmation-token-ref-1',
        now: now,
      );

      expect(result.isBlocked, isTrue);
      expect(result.code, 'CUSTOMER_CONFIRMATION_REQUIRED');
      expect(gateway.calls, 0);
    });

    test(
      'exact trusted backend token + exact scope becomes Step1G ready',
      () async {
        final gateway = _FakeTrustedConfirmationGateway();

        final result = await _boundary(gateway).verifyForTrustedBackend(
          request: _request(),
          callSessionId: 'call-session-1',
          requestedBy: 'trusted-call-session-1',
          tokenReferenceId: 'confirmation-token-ref-1',
          now: now,
        );

        expect(result.isReadyForStep1G, isTrue);
        expect(result.verifiedScope, isNotNull);
        expect(result.code, 'CUSTOMER_CONFIRMATION_VERIFIED');
        expect(result.realRideWritePerformed, isFalse);
        expect(gateway.calls, 1);
      },
    );

    test('scope binds exact Call booking action', () {
      final scope =
          AgentCallRideBookingCustomerConfirmationScope.fromExecutionRequest(
            request: _request(),
            callSessionId: 'call-session-1',
            requestedBy: 'trusted-call-session-1',
          );

      expect(scope.actionId, AgentActionId.createCallRideBooking);
      expect(scope.callSessionId, 'call-session-1');
      expect(scope.executionId, 'execution-1');
      expect(scope.trustedCallerReferenceId, 'caller-ref-1');
      expect(scope.trustedContactReferenceId, 'contact-ref-1');
      expect(scope.idempotencyKey, 'call-session-1:booking-1');
      expect(scope.pickupReferenceId, 'pickup-ref-1');
      expect(scope.destinationReferenceId, 'destination-ref-1');
      expect(scope.vehicleId, 'vehicle-1');
      expect(scope.vehicleType, 'car');
      expect(scope.estimatedFare, 650);
    });

    test('caller mismatch fails closed', () async {
      final gateway = _FakeTrustedConfirmationGateway()
        ..mutateScope = (scope) =>
            scope.copyWith(trustedCallerReferenceId: 'other-caller');

      final result = await _boundary(gateway).verifyForTrustedBackend(
        request: _request(),
        callSessionId: 'call-session-1',
        requestedBy: 'trusted-call-session-1',
        tokenReferenceId: 'confirmation-token-ref-1',
        now: now,
      );

      expect(result.isBlocked, isTrue);
      expect(result.code, 'CUSTOMER_CONFIRMATION_TOKEN_MISMATCH');
    });

    test('contact mismatch fails closed', () async {
      final gateway = _FakeTrustedConfirmationGateway()
        ..mutateScope = (scope) =>
            scope.copyWith(trustedContactReferenceId: 'other-contact');

      final result = await _boundary(gateway).verifyForTrustedBackend(
        request: _request(),
        callSessionId: 'call-session-1',
        requestedBy: 'trusted-call-session-1',
        tokenReferenceId: 'confirmation-token-ref-1',
        now: now,
      );

      expect(result.isBlocked, isTrue);
    });

    test('call session mismatch fails closed', () async {
      final gateway = _FakeTrustedConfirmationGateway()
        ..mutateScope = (scope) =>
            scope.copyWith(callSessionId: 'other-session');

      final result = await _boundary(gateway).verifyForTrustedBackend(
        request: _request(),
        callSessionId: 'call-session-1',
        requestedBy: 'trusted-call-session-1',
        tokenReferenceId: 'confirmation-token-ref-1',
        now: now,
      );

      expect(result.isBlocked, isTrue);
    });

    test('idempotency mismatch fails closed', () async {
      final gateway = _FakeTrustedConfirmationGateway()
        ..mutateScope = (scope) => scope.copyWith(idempotencyKey: 'other-key');

      final result = await _boundary(gateway).verifyForTrustedBackend(
        request: _request(),
        callSessionId: 'call-session-1',
        requestedBy: 'trusted-call-session-1',
        tokenReferenceId: 'confirmation-token-ref-1',
        now: now,
      );

      expect(result.isBlocked, isTrue);
    });

    test('pickup/destination scope mismatch fails closed', () async {
      final gateway = _FakeTrustedConfirmationGateway()
        ..mutateScope = (scope) =>
            scope.copyWith(pickupReferenceId: 'other-pickup');

      final result = await _boundary(gateway).verifyForTrustedBackend(
        request: _request(),
        callSessionId: 'call-session-1',
        requestedBy: 'trusted-call-session-1',
        tokenReferenceId: 'confirmation-token-ref-1',
        now: now,
      );

      expect(result.isBlocked, isTrue);
    });

    test('vehicle scope mismatch fails closed', () async {
      final gateway = _FakeTrustedConfirmationGateway()
        ..mutateScope = (scope) => scope.copyWith(vehicleId: 'other-vehicle');

      final result = await _boundary(gateway).verifyForTrustedBackend(
        request: _request(),
        callSessionId: 'call-session-1',
        requestedBy: 'trusted-call-session-1',
        tokenReferenceId: 'confirmation-token-ref-1',
        now: now,
      );

      expect(result.isBlocked, isTrue);
    });

    test('fare amount mismatch fails closed', () async {
      final gateway = _FakeTrustedConfirmationGateway()
        ..mutateScope = (scope) =>
            scope.copyWith(estimatedFare: scope.estimatedFare + 1);

      final result = await _boundary(gateway).verifyForTrustedBackend(
        request: _request(),
        callSessionId: 'call-session-1',
        requestedBy: 'trusted-call-session-1',
        tokenReferenceId: 'confirmation-token-ref-1',
        now: now,
      );

      expect(result.isBlocked, isTrue);
    });

    test('untrusted source cannot verify confirmation', () async {
      final gateway = _FakeTrustedConfirmationGateway()
        ..source = 'VOICE_TRANSCRIPT';

      final result = await _boundary(gateway).verifyForTrustedBackend(
        request: _request(),
        callSessionId: 'call-session-1',
        requestedBy: 'trusted-call-session-1',
        tokenReferenceId: 'confirmation-token-ref-1',
        now: now,
      );

      expect(result.isBlocked, isTrue);
      expect(result.code, 'CUSTOMER_CONFIRMATION_VERIFICATION_INVALID');
    });

    test('token must be atomically consumed once', () async {
      final gateway = _FakeTrustedConfirmationGateway()
        ..oneTimeConsumed = false;

      final result = await _boundary(gateway).verifyForTrustedBackend(
        request: _request(),
        callSessionId: 'call-session-1',
        requestedBy: 'trusted-call-session-1',
        tokenReferenceId: 'confirmation-token-ref-1',
        now: now,
      );

      expect(result.isBlocked, isTrue);
      expect(result.code, 'CUSTOMER_CONFIRMATION_VERIFICATION_INVALID');
    });

    test('token lifetime above two minutes is rejected', () async {
      final gateway = _FakeTrustedConfirmationGateway()
        ..lifetime = const Duration(minutes: 3);

      final result = await _boundary(gateway).verifyForTrustedBackend(
        request: _request(
          fare: _fare(expiresAt: DateTime.utc(2026, 8, 18, 8, 10)),
        ),
        callSessionId: 'call-session-1',
        requestedBy: 'trusted-call-session-1',
        tokenReferenceId: 'confirmation-token-ref-1',
        now: now,
      );

      expect(result.isBlocked, isTrue);
      expect(result.code, 'CUSTOMER_CONFIRMATION_TOKEN_MISMATCH');
    });

    test('confirmation cannot outlive verified fare', () async {
      final gateway = _FakeTrustedConfirmationGateway()
        ..lifetime = const Duration(minutes: 2);

      final result = await _boundary(gateway).verifyForTrustedBackend(
        request: _request(
          fare: _fare(expiresAt: DateTime.utc(2026, 8, 18, 8, 2)),
        ),
        callSessionId: 'call-session-1',
        requestedBy: 'trusted-call-session-1',
        tokenReferenceId: 'confirmation-token-ref-1',
        now: now,
      );

      expect(result.isBlocked, isTrue);
    });

    test('expired fare blocks before confirmation gateway', () async {
      final gateway = _FakeTrustedConfirmationGateway();

      final result = await _boundary(gateway).verifyForTrustedBackend(
        request: _request(
          fare: _fare(expiresAt: DateTime.utc(2026, 8, 18, 8, 0, 30)),
        ),
        callSessionId: 'call-session-1',
        requestedBy: 'trusted-call-session-1',
        tokenReferenceId: 'confirmation-token-ref-1',
        now: now,
      );

      expect(result.isBlocked, isTrue);
      expect(result.code, 'CUSTOMER_CONFIRMATION_FARE_EXPIRED');
      expect(gateway.calls, 0);
    });

    test('gateway failure fails closed', () async {
      final gateway = _FakeTrustedConfirmationGateway()..throwError = true;

      final result = await _boundary(gateway).verifyForTrustedBackend(
        request: _request(),
        callSessionId: 'call-session-1',
        requestedBy: 'trusted-call-session-1',
        tokenReferenceId: 'confirmation-token-ref-1',
        now: now,
      );

      expect(result.isBlocked, isTrue);
      expect(result.code, 'CUSTOMER_CONFIRMATION_GATEWAY_FAILED');
    });

    test('security boundary exposes no token-mint or Ride authority', () {
      final boundary = _boundary(_FakeTrustedConfirmationGateway());

      expect(boundary.customerBooleanIsSufficientAuthority, isFalse);
      expect(boundary.tokenIsAuthenticationByItself, isFalse);
      expect(boundary.transcriptCanMintToken, isFalse);
      expect(boundary.voiceCanMintToken, isFalse);
      expect(boundary.aiCanMintToken, isFalse);
      expect(boundary.clientCanSignProductionToken, isFalse);
      expect(boundary.storesRawPhoneSecret, isFalse);
      expect(boundary.storesTranscriptConfirmationText, isFalse);

      expect(boundary.requiresTrustedBackendIssuer, isTrue);
      expect(boundary.requiresAtomicOneTimeConsumption, isTrue);
      expect(boundary.requiresExactCallerBinding, isTrue);
      expect(boundary.requiresExactContactBinding, isTrue);
      expect(boundary.requiresCallSessionBinding, isTrue);
      expect(boundary.requiresIdempotencyBinding, isTrue);
      expect(boundary.requiresExactVerifiedFareScope, isTrue);
      expect(boundary.requiresShortLivedConfirmation, isTrue);

      expect(boundary.writesRide, isFalse);
      expect(boundary.changesPayment, isFalse);
      expect(boundary.changesDriverState, isFalse);
      expect(boundary.sendsSms, isFalse);
      expect(boundary.invokesTelephonyProvider, isFalse);
      expect(boundary.invokesSpeechToTextProvider, isFalse);
      expect(boundary.invokesTextToSpeechProvider, isFalse);
    });

    test('Step1B adapter declares trusted confirmation token required', () {
      const adapter = AgentCallRideBookingAuthorizedAdapter();

      expect(
        adapter.requiresTrustedCustomerConfirmationTokenBeforeRealBackend,
        isTrue,
      );
      expect(adapter.writesRide, isFalse);
    });
  });
}
