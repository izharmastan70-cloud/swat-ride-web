import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/models/agent_call_ride_booking_backend_handoff.dart';
import 'package:swat_ride/ai_agent/models/agent_call_ride_booking_customer_confirmation.dart';
import 'package:swat_ride/ai_agent/models/agent_call_ride_booking_draft.dart';
import 'package:swat_ride/ai_agent/models/agent_call_ride_booking_execution_contract.dart';
import 'package:swat_ride/ai_agent/services/agent_call_ride_booking_authorized_adapter.dart';
import 'package:swat_ride/ai_agent/services/agent_call_ride_booking_backend_handoff_coordinator.dart';
import 'package:swat_ride/ai_agent/services/agent_call_ride_booking_exactly_once_completion_contract.dart';

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
  bool testingRoute = false,
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
    usedTestingRouteBypass: testingRoute,
    verifiedAt: verified,
    expiresAt: expiresAt ?? verified.add(const Duration(minutes: 5)),
  );
}

AgentCallRideBookingAuthorization _authorization({bool allowed = true}) {
  if (allowed) {
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

  return const AgentCallRideBookingAuthorization(
    callAgentMasterEnabled: false,
    runtimeAllowed: false,
    permissionAllowed: false,
    dedicatedBookingActionAllowed: false,
    trustedCallerBound: false,
    trustedContactBound: false,
    idempotencyKeyReserved: false,
    reason: 'blocked',
  );
}

AgentCallRideBookingExecutionRequest _request({
  bool confirmed = true,
  bool allowed = true,
  String mode = AgentCallRideBookingExecutionMode.production,
  AgentCallRideFareVerification? fare,
}) {
  return AgentCallRideBookingExecutionRequest(
    executionId: 'execution-1',
    idempotencyKey: 'call-session-1:booking-1',
    mode: mode,
    trustedCallerReferenceId: 'caller-ref-1',
    trustedContactReferenceId: 'contact-ref-1',
    draft: _draft(confirmed: confirmed),
    fareVerification: fare ?? _fare(),
    authorization: _authorization(allowed: allowed),
    createdAt: DateTime.utc(2026, 8, 18, 8, 0, 30),
  );
}

AgentCallRideBookingCustomerConfirmationScope _scope({
  AgentCallRideBookingExecutionRequest? request,
  String callSessionId = 'call-session-1',
  String requestedBy = 'trusted-call-session-1',
}) {
  return AgentCallRideBookingCustomerConfirmationScope.fromExecutionRequest(
    request: request ?? _request(),
    callSessionId: callSessionId,
    requestedBy: requestedBy,
  );
}

AgentCallRideBookingCustomerConfirmationBoundaryResult _confirmed({
  AgentCallRideBookingCustomerConfirmationScope? scope,
  String tokenRef = 'confirmation-token-ref-1',
}) {
  return AgentCallRideBookingCustomerConfirmationBoundaryResult(
    status: AgentCallRideBookingCustomerConfirmationBoundaryResult.ready,
    code: 'CUSTOMER_CONFIRMATION_VERIFIED',
    tokenReferenceId: tokenRef,
    createdAt: DateTime.utc(2026, 8, 18, 8, 1),
    verifiedScope: scope ?? _scope(),
  );
}

AgentCallRideBookingBackendCompletionReceipt _createdReceipt({
  String idempotencyKey = 'call-session-1:booking-1',
  String rideId = 'ride-1',
}) {
  return AgentCallRideBookingBackendCompletionReceipt(
    status: AgentCallRideBookingBackendCompletionReceipt.created,
    code: 'RIDE_CREATED',
    idempotencyKey: idempotencyKey,
    rideId: rideId,
    backendExecutionReferenceId: 'backend-exec-1',
    completionSource:
        AgentCallRideBookingBackendCompletionReceipt.trustedBackendSource,
    rideRecordPersisted: true,
    rideIdEvidenceSource: AgentCallRideBookingBackendCompletionReceipt
        .trustedRideIdEvidenceSource,
    completedAt: DateTime.utc(2026, 8, 18, 8, 1, 10),
    reusedExistingCompletion: false,
  );
}

AgentCallRideBookingBackendCompletionReceipt _replayReceipt({
  String idempotencyKey = 'call-session-1:booking-1',
  String rideId = 'ride-1',
}) {
  return AgentCallRideBookingBackendCompletionReceipt(
    status: AgentCallRideBookingBackendCompletionReceipt.alreadyCompleted,
    code: 'ALREADY_COMPLETED',
    idempotencyKey: idempotencyKey,
    rideId: rideId,
    backendExecutionReferenceId: 'backend-exec-2',
    previousAcceptedRideIdBeforeCompletion: rideId,
    completionSource:
        AgentCallRideBookingBackendCompletionReceipt.trustedBackendSource,
    rideRecordPersisted: true,
    rideIdEvidenceSource: AgentCallRideBookingBackendCompletionReceipt
        .trustedRideIdEvidenceSource,
    completedAt: DateTime.utc(2026, 8, 18, 8, 1, 20),
    reusedExistingCompletion: true,
  );
}

void main() {
  const coordinator = AgentCallRideBookingBackendHandoffCoordinator();

  const completion = AgentCallRideBookingExactlyOnceCompletionContract();

  final DateTime now = DateTime.utc(2026, 8, 18, 8, 1);

  group('Phase 49 Step 1G handoff envelope', () {
    test('exact Step1F verified scope produces ready envelope', () {
      final request = _request();

      final result = coordinator.prepare(
        request: request,
        confirmationResult: _confirmed(scope: _scope(request: request)),
        envelopeId: 'envelope-1',
        now: now,
      );

      expect(result.isReady, isTrue);
      expect(result.realRideWritePerformed, isFalse);
      expect(result.envelope, isNotNull);
      expect(result.envelope!.idempotencyKey, request.idempotencyKey);
      expect(result.envelope!.trustedCallerReferenceId, 'caller-ref-1');
      expect(result.envelope!.trustedContactReferenceId, 'contact-ref-1');
      expect(
        result.envelope!.confirmationTokenReferenceId,
        'confirmation-token-ref-1',
      );
      expect(result.envelope!.pickupReferenceId, 'pickup-ref-1');
      expect(result.envelope!.destinationReferenceId, 'destination-ref-1');
      expect(result.envelope!.vehicleId, 'vehicle-1');
      expect(result.envelope!.estimatedFare, 650);
    });

    test('missing Step1F verified result blocks handoff', () {
      final result = coordinator.prepare(
        request: _request(),
        confirmationResult:
            AgentCallRideBookingCustomerConfirmationBoundaryResult(
              status: AgentCallRideBookingCustomerConfirmationBoundaryResult
                  .blocked,
              code: 'BLOCKED',
              tokenReferenceId: '',
              createdAt: now,
            ),
        envelopeId: 'envelope-1',
        now: now,
      );

      expect(result.isBlocked, isTrue);
      expect(result.code, 'STEP1F_VERIFIED_CONFIRMATION_REQUIRED');
    });

    test('scope mismatch against execution fails closed', () {
      final request = _request();

      final result = coordinator.prepare(
        request: request,
        confirmationResult: _confirmed(
          scope: _scope(
            request: request,
          ).copyWith(trustedCallerReferenceId: 'other-caller'),
        ),
        envelopeId: 'envelope-1',
        now: now,
      );

      expect(result.isBlocked, isTrue);
      expect(result.code, 'STEP1F_SCOPE_EXECUTION_MISMATCH');
    });

    test('fare mismatch against execution fails closed', () {
      final request = _request();

      final result = coordinator.prepare(
        request: request,
        confirmationResult: _confirmed(
          scope: _scope(request: request).copyWith(estimatedFare: 651),
        ),
        envelopeId: 'envelope-1',
        now: now,
      );

      expect(result.isBlocked, isTrue);
    });

    test('test execution mode cannot produce production handoff', () {
      final request = _request(mode: AgentCallRideBookingExecutionMode.test);

      final result = coordinator.prepare(
        request: request,
        confirmationResult: _confirmed(scope: _scope(request: request)),
        envelopeId: 'envelope-1',
        now: now,
      );

      expect(result.isBlocked, isTrue);
      expect(result.code, 'PRODUCTION_HANDOFF_REQUIRED');
    });

    test('testing-route provenance cannot produce handoff', () {
      final request = _request(fare: _fare(testingRoute: true));

      final result = coordinator.prepare(
        request: request,
        confirmationResult: _confirmed(scope: _scope(request: request)),
        envelopeId: 'envelope-1',
        now: now,
      );

      expect(result.isBlocked, isTrue);
      expect(result.code, 'PRODUCTION_ROUTE_VERIFICATION_REQUIRED');
    });

    test('expired fare cannot produce handoff', () {
      final request = _request(
        fare: _fare(expiresAt: DateTime.utc(2026, 8, 18, 8, 0, 30)),
      );

      final result = coordinator.prepare(
        request: request,
        confirmationResult: _confirmed(scope: _scope(request: request)),
        envelopeId: 'envelope-1',
        now: now,
      );

      expect(result.isBlocked, isTrue);
      expect(result.code, 'FARE_VERIFICATION_EXPIRED');
    });

    test('sanitized envelope contains no raw phone/transcript/secrets', () {
      final request = _request();

      final result = coordinator.prepare(
        request: request,
        confirmationResult: _confirmed(scope: _scope(request: request)),
        envelopeId: 'envelope-1',
        now: now,
      );

      final map = result.envelope!.toSanitizedMap();

      expect(map['rawPhoneIncluded'], isFalse);
      expect(map['transcriptIncluded'], isFalse);
      expect(map['providerSecretIncluded'], isFalse);
      expect(map['clientSigningSecretIncluded'], isFalse);
      expect(map.containsKey('contactPhoneMasked'), isFalse);
      expect(map.containsKey('customerName'), isFalse);
    });

    test('handoff coordinator has no executor or Ride authority', () {
      expect(coordinator.envelopeIsAuthority, isFalse);
      expect(coordinator.trustsClientEnvelopeWithoutBackendChecks, isFalse);
      expect(coordinator.invokesTrustedBackend, isFalse);
      expect(coordinator.writesRide, isFalse);
      expect(coordinator.writesFirestore, isFalse);
      expect(coordinator.usesCurrentFirebaseUserAsCaller, isFalse);
      expect(coordinator.includesRawPhone, isFalse);
      expect(coordinator.includesTranscript, isFalse);
      expect(coordinator.includesProviderSecret, isFalse);
      expect(coordinator.includesClientSigningSecret, isFalse);
    });
  });

  group('Phase 49 Step 1G exactly-once completion contract', () {
    late AgentCallRideBookingBackendHandoffEnvelope envelope;

    setUp(() {
      final request = _request();

      envelope = coordinator
          .prepare(
            request: request,
            confirmationResult: _confirmed(scope: _scope(request: request)),
            envelopeId: 'envelope-1',
            now: now,
          )
          .envelope!;
    });

    test('first successful completion locks one Ride ID', () {
      final receipt = completion.validateReceipt(
        envelope: envelope,
        receipt: _createdReceipt(),
        previousAcceptedRideId: null,
      );

      expect(receipt.rideId, 'ride-1');
      expect(
        receipt.status,
        AgentCallRideBookingBackendCompletionReceipt.created,
      );
    });

    test('same Ride ID replay is allowed only as ALREADY_COMPLETED', () {
      final receipt = completion.validateReceipt(
        envelope: envelope,
        receipt: _replayReceipt(),
        previousAcceptedRideId: 'ride-1',
      );

      expect(receipt.rideId, 'ride-1');
      expect(receipt.reusedExistingCompletion, isTrue);
    });

    test('different Ride ID replay fails closed', () {
      expect(
        () => completion.validateReceipt(
          envelope: envelope,
          receipt: _replayReceipt(rideId: 'ride-2'),
          previousAcceptedRideId: 'ride-1',
        ),
        throwsA(isA<AgentCallRideBookingBackendHandoffException>()),
      );
    });

    test('different idempotency key fails closed', () {
      expect(
        () => completion.validateReceipt(
          envelope: envelope,
          receipt: _createdReceipt(idempotencyKey: 'other-key'),
          previousAcceptedRideId: null,
        ),
        throwsA(isA<AgentCallRideBookingBackendHandoffException>()),
      );
    });

    test('replay cannot pretend to be new CREATED', () {
      expect(
        () => completion.validateReceipt(
          envelope: envelope,
          receipt: _createdReceipt(),
          previousAcceptedRideId: 'ride-1',
        ),
        throwsA(isA<AgentCallRideBookingBackendHandoffException>()),
      );
    });

    test('first completion cannot be ALREADY_COMPLETED', () {
      expect(
        () => completion.validateReceipt(
          envelope: envelope,
          receipt: _replayReceipt(),
          previousAcceptedRideId: null,
        ),
        throwsA(isA<AgentCallRideBookingBackendHandoffException>()),
      );
    });

    test('untrusted completion source fails validation', () {
      final receipt = AgentCallRideBookingBackendCompletionReceipt(
        status: AgentCallRideBookingBackendCompletionReceipt.created,
        code: 'RIDE_CREATED',
        idempotencyKey: envelope.idempotencyKey,
        rideId: 'ride-1',
        backendExecutionReferenceId: 'backend-exec-1',
        completionSource: 'CLIENT',

        rideRecordPersisted: true,
        rideIdEvidenceSource: AgentCallRideBookingBackendCompletionReceipt
            .trustedRideIdEvidenceSource,
        completedAt: now,
        reusedExistingCompletion: false,
      );

      expect(
        () => completion.validateReceipt(
          envelope: envelope,
          receipt: receipt,
          previousAcceptedRideId: null,
        ),
        throwsA(isA<AgentCallRideBookingBackendHandoffException>()),
      );
    });

    test('completion contract itself does not persist or create Ride', () {
      expect(completion.requiresTrustedPersistentState, isTrue);
      expect(completion.firstCompletionLocksOneRideId, isTrue);
      expect(completion.sameRideReplayAllowed, isTrue);
      expect(completion.differentRideReplayAllowed, isFalse);
      expect(completion.clientMemoryIsTrustedCompletionState, isFalse);
      expect(completion.completionReceiptIsAuthentication, isFalse);
      expect(completion.writesRide, isFalse);
      expect(completion.writesFirestore, isFalse);
    });

    test('Step1B adapter declares Step1G envelope requirement', () {
      const adapter = AgentCallRideBookingAuthorizedAdapter();

      expect(adapter.requiresStep1GTrustedBackendHandoffEnvelope, isTrue);
      expect(adapter.writesRide, isFalse);
    });
  });
}
