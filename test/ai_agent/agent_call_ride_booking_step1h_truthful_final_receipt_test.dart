import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_action_ids.dart';
import 'package:swat_ride/ai_agent/models/agent_call_ride_booking_backend_handoff.dart';
import 'package:swat_ride/ai_agent/models/agent_call_ride_booking_final_receipt.dart';
import 'package:swat_ride/ai_agent/services/agent_call_ride_booking_authorized_adapter.dart';
import 'package:swat_ride/ai_agent/services/agent_call_ride_booking_exactly_once_completion_contract.dart';
import 'package:swat_ride/ai_agent/services/agent_call_ride_booking_trusted_backend_executor.dart';

class _FakeExactlyOnceGateway
    implements AgentCallRideBookingExactlyOnceCompletionGateway {
  _FakeExactlyOnceGateway({required this.receipt, this.throwError = false});

  AgentCallRideBookingBackendCompletionReceipt receipt;
  bool throwError;
  int calls = 0;

  @override
  Future<AgentCallRideBookingBackendCompletionReceipt> completeExactlyOnce({
    required AgentCallRideBookingBackendHandoffEnvelope envelope,
  }) async {
    calls += 1;

    if (throwError) {
      throw StateError('test backend failure');
    }

    return receipt;
  }
}

AgentCallRideBookingBackendHandoffEnvelope _envelope({
  DateTime? createdAt,
  DateTime? fareExpiresAt,
}) {
  final DateTime verifiedAt = DateTime.utc(2026, 8, 18, 8, 0);
  final DateTime handoffAt = createdAt ?? DateTime.utc(2026, 8, 18, 8, 1);

  return AgentCallRideBookingBackendHandoffEnvelope(
    envelopeId: 'envelope-1',
    actionId: AgentActionId.createCallRideBooking,
    roleId: 'call_agent',
    module: 'call',
    callSessionId: 'call-session-1',
    requestedBy: 'trusted-call-session-1',
    executionId: 'execution-1',
    idempotencyKey: 'call-session-1:booking-1',
    trustedCallerReferenceId: 'caller-ref-1',
    trustedContactReferenceId: 'contact-ref-1',
    confirmationTokenReferenceId: 'confirmation-token-ref-1',
    pickupReferenceId: 'pickup-ref-1',
    destinationReferenceId: 'destination-ref-1',
    vehicleId: 'vehicle-1',
    vehicleType: 'car',
    distanceKm: 12.5,
    estimatedMinutes: 25,
    baseFare: 150,
    estimatedFare: 650,
    adminCommissionAmount: 65,
    driverAvailable: true,
    rideServiceAvailable: true,
    usedTestingRouteBypass: false,
    fareVerifiedAt: verifiedAt,
    fareExpiresAt: fareExpiresAt ?? verifiedAt.add(const Duration(minutes: 5)),
    createdAt: handoffAt,
  );
}

AgentCallRideBookingBackendHandoffResult _readyHandoff({
  AgentCallRideBookingBackendHandoffEnvelope? envelope,
}) {
  return AgentCallRideBookingBackendHandoffResult(
    status: AgentCallRideBookingBackendHandoffStatus.ready,
    code: 'READY_FOR_TRUSTED_BACKEND_EXECUTOR',
    createdAt: DateTime.utc(2026, 8, 18, 8, 1),
    envelope: envelope ?? _envelope(),
  );
}

AgentCallRideBookingBackendCompletionReceipt _created({
  String rideId = 'ride-1',
  String idempotencyKey = 'call-session-1:booking-1',
  String completionSource =
      AgentCallRideBookingBackendCompletionReceipt.trustedBackendSource,
  bool persisted = true,
  String evidenceSource =
      AgentCallRideBookingBackendCompletionReceipt.trustedRideIdEvidenceSource,
  String backendExecutionReferenceId = 'backend-exec-1',
  String? previousRideId,
}) {
  return AgentCallRideBookingBackendCompletionReceipt(
    status: AgentCallRideBookingBackendCompletionReceipt.created,
    code: 'RIDE_CREATED',
    idempotencyKey: idempotencyKey,
    rideId: rideId,
    backendExecutionReferenceId: backendExecutionReferenceId,
    completionSource: completionSource,
    completedAt: DateTime.utc(2026, 8, 18, 8, 1, 10),
    reusedExistingCompletion: false,
    previousAcceptedRideIdBeforeCompletion: previousRideId,
    rideRecordPersisted: persisted,
    rideIdEvidenceSource: evidenceSource,
  );
}

AgentCallRideBookingBackendCompletionReceipt _replay({
  String rideId = 'ride-1',
  String previousRideId = 'ride-1',
}) {
  return AgentCallRideBookingBackendCompletionReceipt(
    status: AgentCallRideBookingBackendCompletionReceipt.alreadyCompleted,
    code: 'ALREADY_COMPLETED',
    idempotencyKey: 'call-session-1:booking-1',
    rideId: rideId,
    backendExecutionReferenceId: 'backend-exec-2',
    completionSource:
        AgentCallRideBookingBackendCompletionReceipt.trustedBackendSource,
    completedAt: DateTime.utc(2026, 8, 18, 8, 1, 20),
    reusedExistingCompletion: true,
    previousAcceptedRideIdBeforeCompletion: previousRideId,
    rideRecordPersisted: true,
    rideIdEvidenceSource: AgentCallRideBookingBackendCompletionReceipt
        .trustedRideIdEvidenceSource,
  );
}

void main() {
  final DateTime now = DateTime.utc(2026, 8, 18, 8, 1, 30);

  group('Phase 49 Step 1H truthful final receipt', () {
    test('validated CREATED receipt is the only new-booking success', () async {
      final gateway = _FakeExactlyOnceGateway(receipt: _created());

      final executor = AgentCallRideBookingTrustedBackendExecutor(
        completionGateway: gateway,
      );

      final result = await executor.execute(
        handoffResult: _readyHandoff(),
        now: now,
      );

      expect(result.status, AgentCallRideBookingFinalStatus.booked);
      expect(result.canStateRideBooked, isTrue);
      expect(result.realRideIdProven, isTrue);
      expect(result.rideId, 'ride-1');
      expect(result.code, 'RIDE_BOOKED_CONFIRMED');
      expect(result.backendInvoked, isTrue);
      expect(result.validatedExactlyOnce, isTrue);
      expect(gateway.calls, 1);
    });

    test('retry ALREADY_COMPLETED same Ride is truthful BOOKED', () async {
      final gateway = _FakeExactlyOnceGateway(receipt: _replay());

      final executor = AgentCallRideBookingTrustedBackendExecutor(
        completionGateway: gateway,
      );

      final result = await executor.execute(
        handoffResult: _readyHandoff(),
        now: now,
      );

      expect(result.canStateRideBooked, isTrue);
      expect(result.rideId, 'ride-1');
      expect(result.code, 'RIDE_ALREADY_BOOKED_CONFIRMED');
      expect(result.reusedExistingCompletion, isTrue);
    });

    test(
      'handoff not ready never invokes backend and says NOT_BOOKED',
      () async {
        final gateway = _FakeExactlyOnceGateway(receipt: _created());

        final executor = AgentCallRideBookingTrustedBackendExecutor(
          completionGateway: gateway,
        );

        final result = await executor.execute(
          handoffResult: AgentCallRideBookingBackendHandoffResult(
            status: AgentCallRideBookingBackendHandoffStatus.blocked,
            code: 'BLOCKED',
            createdAt: now,
          ),
          now: now,
        );

        expect(result.status, AgentCallRideBookingFinalStatus.notBooked);
        expect(result.canStateRideBooked, isFalse);
        expect(result.rideId, isNull);
        expect(result.backendInvoked, isFalse);
        expect(gateway.calls, 0);
      },
    );

    test('expired handoff never invokes backend and says NOT_BOOKED', () async {
      final envelope = _envelope(
        fareExpiresAt: DateTime.utc(2026, 8, 18, 8, 1),
      );

      final gateway = _FakeExactlyOnceGateway(receipt: _created());

      final executor = AgentCallRideBookingTrustedBackendExecutor(
        completionGateway: gateway,
      );

      final result = await executor.execute(
        handoffResult: _readyHandoff(envelope: envelope),
        now: now,
      );

      expect(result.status, AgentCallRideBookingFinalStatus.notBooked);
      expect(result.canStateRideBooked, isFalse);
      expect(gateway.calls, 0);
    });

    test('backend exception becomes UNKNOWN, never fake success', () async {
      final gateway = _FakeExactlyOnceGateway(
        receipt: _created(),
        throwError: true,
      );

      final executor = AgentCallRideBookingTrustedBackendExecutor(
        completionGateway: gateway,
      );

      final result = await executor.execute(
        handoffResult: _readyHandoff(),
        now: now,
      );

      expect(
        result.status,
        AgentCallRideBookingFinalStatus.bookingStatusUnknown,
      );
      expect(result.canStateRideBooked, isFalse);
      expect(result.rideId, isNull);
      expect(result.backendInvoked, isTrue);
      expect(result.validatedExactlyOnce, isFalse);
    });

    test('empty Ride ID can never become BOOKED', () async {
      final gateway = _FakeExactlyOnceGateway(receipt: _created(rideId: ''));

      final executor = AgentCallRideBookingTrustedBackendExecutor(
        completionGateway: gateway,
      );

      final result = await executor.execute(
        handoffResult: _readyHandoff(),
        now: now,
      );

      expect(
        result.status,
        AgentCallRideBookingFinalStatus.bookingStatusUnknown,
      );
      expect(result.canStateRideBooked, isFalse);
    });

    test('untrusted completion source can never become BOOKED', () async {
      final gateway = _FakeExactlyOnceGateway(
        receipt: _created(completionSource: 'CLIENT'),
      );

      final result = await AgentCallRideBookingTrustedBackendExecutor(
        completionGateway: gateway,
      ).execute(handoffResult: _readyHandoff(), now: now);

      expect(result.canStateRideBooked, isFalse);
      expect(
        result.status,
        AgentCallRideBookingFinalStatus.bookingStatusUnknown,
      );
    });

    test(
      'non-persisted/local placeholder Ride ID cannot become BOOKED',
      () async {
        final gateway = _FakeExactlyOnceGateway(
          receipt: _created(
            rideId: 'local-placeholder-ride',
            persisted: false,
            evidenceSource: 'LOCAL_CLIENT',
          ),
        );

        final result = await AgentCallRideBookingTrustedBackendExecutor(
          completionGateway: gateway,
        ).execute(handoffResult: _readyHandoff(), now: now);

        expect(result.canStateRideBooked, isFalse);
        expect(result.rideId, isNull);
        expect(
          result.status,
          AgentCallRideBookingFinalStatus.bookingStatusUnknown,
        );
      },
    );

    test('idempotency mismatch becomes UNKNOWN, never BOOKED', () async {
      final gateway = _FakeExactlyOnceGateway(
        receipt: _created(idempotencyKey: 'other-key'),
      );

      final result = await AgentCallRideBookingTrustedBackendExecutor(
        completionGateway: gateway,
      ).execute(handoffResult: _readyHandoff(), now: now);

      expect(result.canStateRideBooked, isFalse);
      expect(
        result.status,
        AgentCallRideBookingFinalStatus.bookingStatusUnknown,
      );
    });

    test('CREATED receipt cannot claim a previous accepted Ride', () async {
      final gateway = _FakeExactlyOnceGateway(
        receipt: _created(previousRideId: 'ride-1'),
      );

      final result = await AgentCallRideBookingTrustedBackendExecutor(
        completionGateway: gateway,
      ).execute(handoffResult: _readyHandoff(), now: now);

      expect(result.canStateRideBooked, isFalse);
    });

    test('ALREADY_COMPLETED must prove exact same Ride ID', () async {
      final gateway = _FakeExactlyOnceGateway(
        receipt: _replay(rideId: 'ride-2', previousRideId: 'ride-1'),
      );

      final result = await AgentCallRideBookingTrustedBackendExecutor(
        completionGateway: gateway,
      ).execute(handoffResult: _readyHandoff(), now: now);

      expect(result.canStateRideBooked, isFalse);
      expect(
        result.status,
        AgentCallRideBookingFinalStatus.bookingStatusUnknown,
      );
    });

    test('missing backend execution reference cannot become BOOKED', () async {
      final gateway = _FakeExactlyOnceGateway(
        receipt: _created(backendExecutionReferenceId: ''),
      );

      final result = await AgentCallRideBookingTrustedBackendExecutor(
        completionGateway: gateway,
      ).execute(handoffResult: _readyHandoff(), now: now);

      expect(result.canStateRideBooked, isFalse);
    });

    test('customer-safe map exposes Ride ID only for proven BOOKED', () async {
      final gateway = _FakeExactlyOnceGateway(receipt: _created());

      final result = await AgentCallRideBookingTrustedBackendExecutor(
        completionGateway: gateway,
      ).execute(handoffResult: _readyHandoff(), now: now);

      final map = result.toCustomerSafeMap();

      expect(map['rideId'], 'ride-1');
      expect(map['rawPhoneIncluded'], isFalse);
      expect(map['transcriptIncluded'], isFalse);
      expect(map['providerSecretIncluded'], isFalse);
    });

    test('UNKNOWN receipt customer-safe map never exposes Ride ID', () async {
      final gateway = _FakeExactlyOnceGateway(receipt: _created(rideId: ''));

      final result = await AgentCallRideBookingTrustedBackendExecutor(
        completionGateway: gateway,
      ).execute(handoffResult: _readyHandoff(), now: now);

      expect(result.toCustomerSafeMap()['rideId'], isNull);
    });

    test('executor declares no default production backend/writes', () {
      final executor = AgentCallRideBookingTrustedBackendExecutor(
        completionGateway: _FakeExactlyOnceGateway(receipt: _created()),
      );

      expect(executor.reusesStep1GExactlyOnceGateway, isTrue);
      expect(executor.hasDefaultProductionGateway, isFalse);
      expect(executor.canClaimSuccessFromHandoffOnly, isFalse);
      expect(executor.canClaimSuccessFromPreflightOnly, isFalse);
      expect(executor.canClaimSuccessFromCustomerBooleanOnly, isFalse);
      expect(executor.acceptsPlaceholderRideIdAsSuccess, isFalse);
      expect(executor.clientGeneratesRideId, isFalse);
      expect(executor.usesCurrentFirebaseUserAsCaller, isFalse);

      expect(executor.directlyWritesRide, isFalse);
      expect(executor.directlyWritesFirestore, isFalse);
      expect(executor.invokesHttpTransport, isFalse);
      expect(executor.invokesFirebaseFunctions, isFalse);
      expect(executor.invokesTelephonyProvider, isFalse);
      expect(executor.sendsSms, isFalse);
    });

    test('Step1B adapter requires validated Step1H receipt before claim', () {
      const adapter = AgentCallRideBookingAuthorizedAdapter();

      expect(
        adapter.requiresStep1HValidatedFinalReceiptBeforeBookedClaim,
        isTrue,
      );
      expect(adapter.writesRide, isFalse);
    });
  });
}
