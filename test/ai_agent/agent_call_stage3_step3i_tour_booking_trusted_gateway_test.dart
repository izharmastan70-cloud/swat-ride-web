import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/models/agent_call_tour_booking_status_contract.dart';
import 'package:swat_ride/ai_agent/models/agent_call_tour_booking_trusted_resolution.dart';
import 'package:swat_ride/ai_agent/services/agent_call_tour_booking_trusted_backend_read_gateway.dart';

class _FakeTrustedTourResolver
    extends AgentCallTourBookingTrustedBackendResolver {
  _FakeTrustedTourResolver(this.builder);

  final AgentCallTourBookingTrustedResolutionReceipt Function(
    AgentCallTourBookingTrustedResolutionRequest request,
    DateTime now,
  )
  builder;

  int calls = 0;

  @override
  Future<AgentCallTourBookingTrustedResolutionReceipt> resolveAndRead({
    required AgentCallTourBookingTrustedResolutionRequest request,
    required DateTime now,
  }) async {
    calls++;
    return builder(request, now);
  }
}

AgentCallTourBookingStatusRequest _request({
  String session = 'call-session-tour-1',
  String requestedBy = 'trusted-call-actor-1',
  String caller = 'caller-ref-1',
  String contact = 'contact-ref-1',
  String booking = 'tour-booking-ref-1',
}) {
  return AgentCallTourBookingStatusRequest(
    callSessionId: session,
    requestedBy: requestedBy,
    trustedCallerReferenceId: caller,
    trustedContactReferenceId: contact,
    trustedTourBookingReferenceId: booking,
  );
}

AgentCallTourBookingStatusSnapshot _snapshot(DateTime now) {
  return AgentCallTourBookingStatusSnapshot(
    trustedTourBookingReferenceId: 'tour-booking-ref-1',
    tourType: 'private_tour',
    bookingStatus: 'confirmed',
    paymentStatus: 'advance_paid',
    assignmentStatus: 'driver_assigned',
    startDate: DateTime.utc(2026, 8, 20),
    endDate: DateTime.utc(2026, 8, 22),
    hasDriver: true,
    hasGuide: false,
    hasVehicle: true,
    hasHotel: false,
    observedAt: now.subtract(const Duration(seconds: 2)),
  );
}

AgentCallTourBookingTrustedResolutionReceipt _authorizedReceipt(
  AgentCallTourBookingTrustedResolutionRequest request,
  DateTime now, {
  AgentCallTourBookingStatusSnapshot? snapshot,
  String source =
      AgentCallTourBookingTrustedResolutionReceipt.trustedBackendSource,
  bool backendAccessVerified = true,
  DateTime? resolvedAt,
}) {
  return AgentCallTourBookingTrustedResolutionReceipt(
    status: AgentCallTourBookingTrustedResolutionStatus.authorizedTourBooking,
    source: source,
    callSessionId: request.callSessionId,
    requestedBy: request.requestedBy,
    trustedCallerReferenceId: request.trustedCallerReferenceId,
    trustedContactReferenceId: request.trustedContactReferenceId,
    presentedTourBookingReferenceId: request.presentedTourBookingReferenceId,
    backendAccessVerified: backendAccessVerified,
    resolvedAt: resolvedAt ?? now,
    snapshot: snapshot ?? _snapshot(now),
  );
}

AgentCallTourBookingTrustedResolutionReceipt _unavailableReceipt(
  AgentCallTourBookingTrustedResolutionRequest request,
  DateTime now, {
  String status =
      AgentCallTourBookingTrustedResolutionStatus.tourBookingUnavailable,
}) {
  return AgentCallTourBookingTrustedResolutionReceipt(
    status: status,
    source: AgentCallTourBookingTrustedResolutionReceipt.trustedBackendSource,
    callSessionId: request.callSessionId,
    requestedBy: request.requestedBy,
    trustedCallerReferenceId: request.trustedCallerReferenceId,
    trustedContactReferenceId: request.trustedContactReferenceId,
    presentedTourBookingReferenceId: request.presentedTourBookingReferenceId,
    backendAccessVerified: false,
    resolvedAt: now,
  );
}

void main() {
  group('Phase 49 Stage 3 Step 3I trusted Tour gateway', () {
    final DateTime now = DateTime.utc(2026, 8, 18, 11, 50);

    test(
      'valid trusted backend receipt returns minimum Tour snapshot',
      () async {
        final resolver = _FakeTrustedTourResolver(
          (request, time) => _authorizedReceipt(request, time),
        );

        final gateway = AgentCallTourBookingTrustedBackendReadGateway(
          resolver: resolver,
        );

        final evidence = await gateway.readAuthorizedTourBookingStatus(
          request: _request(),
          now: now,
        );

        expect(evidence.isAuthorized, isTrue);
        expect(evidence.snapshot, isNotNull);
        expect(evidence.snapshot!.bookingStatus, 'confirmed');
        expect(evidence.snapshot!.hasDriver, isTrue);
        expect(resolver.calls, 1);
      },
    );

    test('safe snapshot exposes exactly operational minimum fields', () {
      final Map<String, dynamic> map = _snapshot(now).toSafeMap();

      expect(map.keys.toSet(), <String>{
        'trustedTourBookingReferenceId',
        'tourType',
        'bookingStatus',
        'paymentStatus',
        'assignmentStatus',
        'startDate',
        'endDate',
        'hasDriver',
        'hasGuide',
        'hasVehicle',
        'hasHotel',
        'observedAt',
      });
    });

    test(
      'snapshot excludes identity location request amounts and private IDs',
      () {
        final Map<String, dynamic> map = _snapshot(now).toSafeMap();

        for (final String key in <String>[
          'userId',
          'phone',
          'email',
          'cnic',
          'pickupLatitude',
          'pickupLongitude',
          'specialRequest',
          'totalAmount',
          'advanceAmount',
          'remainingAmount',
          'driverId',
          'guideId',
          'vehicleId',
          'hotelId',
        ]) {
          expect(map.containsKey(key), isFalse);
        }
      },
    );

    test('not-found/unavailable collapses to generic unavailable', () async {
      final resolver = _FakeTrustedTourResolver(
        (request, time) => _unavailableReceipt(request, time),
      );

      final gateway = AgentCallTourBookingTrustedBackendReadGateway(
        resolver: resolver,
      );

      final evidence = await gateway.readAuthorizedTourBookingStatus(
        request: _request(),
        now: now,
      );

      expect(evidence.isAuthorized, isFalse);
      expect(evidence.snapshot, isNull);
      expect(
        evidence.status,
        AgentCallTourBookingStatusReadStatus.tourBookingStatusUnavailable,
      );
    });

    test('backend-blocked is indistinguishable from unavailable', () async {
      final resolver = _FakeTrustedTourResolver(
        (request, time) => _unavailableReceipt(
          request,
          time,
          status: AgentCallTourBookingTrustedResolutionStatus
              .tourBookingResolutionBlocked,
        ),
      );

      final gateway = AgentCallTourBookingTrustedBackendReadGateway(
        resolver: resolver,
      );

      final evidence = await gateway.readAuthorizedTourBookingStatus(
        request: _request(),
        now: now,
      );

      expect(evidence.isAuthorized, isFalse);
      expect(evidence.snapshot, isNull);
      expect(
        evidence.status,
        AgentCallTourBookingStatusReadStatus.tourBookingStatusUnavailable,
      );
    });

    test('session binding mismatch fails closed', () async {
      final resolver = _FakeTrustedTourResolver(
        (request, time) => AgentCallTourBookingTrustedResolutionReceipt(
          status:
              AgentCallTourBookingTrustedResolutionStatus.authorizedTourBooking,
          source:
              AgentCallTourBookingTrustedResolutionReceipt.trustedBackendSource,
          callSessionId: 'wrong-session',
          requestedBy: request.requestedBy,
          trustedCallerReferenceId: request.trustedCallerReferenceId,
          trustedContactReferenceId: request.trustedContactReferenceId,
          presentedTourBookingReferenceId:
              request.presentedTourBookingReferenceId,
          backendAccessVerified: true,
          resolvedAt: time,
          snapshot: _snapshot(time),
        ),
      );

      final gateway = AgentCallTourBookingTrustedBackendReadGateway(
        resolver: resolver,
      );

      final evidence = await gateway.readAuthorizedTourBookingStatus(
        request: _request(),
        now: now,
      );

      expect(evidence.isAuthorized, isFalse);
      expect(evidence.snapshot, isNull);
    });

    test('snapshot booking reference mismatch fails closed', () async {
      final resolver = _FakeTrustedTourResolver(
        (request, time) => _authorizedReceipt(
          request,
          time,
          snapshot: AgentCallTourBookingStatusSnapshot(
            trustedTourBookingReferenceId: 'different-booking-ref',
            tourType: 'private_tour',
            bookingStatus: 'confirmed',
            paymentStatus: 'advance_paid',
            assignmentStatus: 'driver_assigned',
            startDate: DateTime.utc(2026, 8, 20),
            endDate: DateTime.utc(2026, 8, 22),
            hasDriver: true,
            hasGuide: false,
            hasVehicle: true,
            hasHotel: false,
            observedAt: time,
          ),
        ),
      );

      final gateway = AgentCallTourBookingTrustedBackendReadGateway(
        resolver: resolver,
      );

      final evidence = await gateway.readAuthorizedTourBookingStatus(
        request: _request(),
        now: now,
      );

      expect(evidence.isAuthorized, isFalse);
      expect(evidence.snapshot, isNull);
    });

    test('untrusted resolver source fails closed', () async {
      final resolver = _FakeTrustedTourResolver(
        (request, time) => _authorizedReceipt(
          request,
          time,
          source: 'UNTRUSTED_CLIENT_SOURCE',
        ),
      );

      final gateway = AgentCallTourBookingTrustedBackendReadGateway(
        resolver: resolver,
      );

      final evidence = await gateway.readAuthorizedTourBookingStatus(
        request: _request(),
        now: now,
      );

      expect(evidence.isAuthorized, isFalse);
      expect(evidence.snapshot, isNull);
    });

    test('stale trusted resolution fails closed', () async {
      final resolver = _FakeTrustedTourResolver(
        (request, time) => _authorizedReceipt(
          request,
          time,
          resolvedAt: time.subtract(const Duration(minutes: 3)),
        ),
      );

      final gateway = AgentCallTourBookingTrustedBackendReadGateway(
        resolver: resolver,
      );

      final evidence = await gateway.readAuthorizedTourBookingStatus(
        request: _request(),
        now: now,
      );

      expect(evidence.isAuthorized, isFalse);
      expect(evidence.snapshot, isNull);
    });

    test(
      'authorized receipt without backend access verification fails closed',
      () async {
        final resolver = _FakeTrustedTourResolver(
          (request, time) =>
              _authorizedReceipt(request, time, backendAccessVerified: false),
        );

        final gateway = AgentCallTourBookingTrustedBackendReadGateway(
          resolver: resolver,
        );

        final evidence = await gateway.readAuthorizedTourBookingStatus(
          request: _request(),
          now: now,
        );

        expect(evidence.isAuthorized, isFalse);
        expect(evidence.snapshot, isNull);
      },
    );

    test('invalid request fails before trusted resolver invocation', () async {
      final resolver = _FakeTrustedTourResolver(
        (request, time) => _authorizedReceipt(request, time),
      );

      final gateway = AgentCallTourBookingTrustedBackendReadGateway(
        resolver: resolver,
      );

      final evidence = await gateway.readAuthorizedTourBookingStatus(
        request: _request(booking: ''),
        now: now,
      );

      expect(evidence.isAuthorized, isFalse);
      expect(evidence.snapshot, isNull);
      expect(resolver.calls, 0);
    });

    test('gateway exposes no client provider or Tour write authority', () {
      final resolver = _FakeTrustedTourResolver(
        (request, time) => _authorizedReceipt(request, time),
      );

      final gateway = AgentCallTourBookingTrustedBackendReadGateway(
        resolver: resolver,
      );

      expect(gateway.requiresTrustedBackendResolver, isTrue);
      expect(gateway.defaultFlutterProductionResolverConnected, isFalse);
      expect(gateway.backendCallerContactAccessVerificationRequired, isTrue);
      expect(gateway.exactSessionBindingRequired, isTrue);
      expect(gateway.exactRequestedByBindingRequired, isTrue);
      expect(gateway.exactCallerBindingRequired, isTrue);
      expect(gateway.exactContactBindingRequired, isTrue);
      expect(gateway.exactTourBookingBindingRequired, isTrue);
      expect(gateway.hidesUnauthorizedTourBookingExistence, isTrue);

      expect(gateway.rawPhoneIsAuthority, isFalse);
      expect(gateway.transcriptIsAuthority, isFalse);
      expect(gateway.voiceIsAuthority, isFalse);
      expect(gateway.firebaseCurrentUserIsAuthority, isFalse);
      expect(gateway.bookingReferenceAloneIsAuthority, isFalse);

      expect(gateway.invokesGenericTourConnectorDirectly, isFalse);
      expect(gateway.invokesTourBookingService, isFalse);
      expect(gateway.invokesFirestore, isFalse);
      expect(gateway.invokesFirebaseAuth, isFalse);
      expect(gateway.invokesHttp, isFalse);
      expect(gateway.invokesCloudFunctions, isFalse);
      expect(gateway.invokesTelephonyProvider, isFalse);

      expect(gateway.createsTourBooking, isFalse);
      expect(gateway.writesTourBooking, isFalse);
      expect(gateway.cancelsTourBooking, isFalse);
      expect(gateway.changesTourPrice, isFalse);
      expect(gateway.changesTourPayment, isFalse);
      expect(gateway.changesTourAssignment, isFalse);
    });

    test('generic unavailable evidence leaks no sensitive Tour fields', () {
      final Map<String, dynamic> map =
          AgentCallTourBookingStatusReadEvidence.unavailable(
            observedAt: now,
          ).toSafeMap();

      expect(map['tourBookingExistenceDisclosedWhenUnavailable'], isFalse);
      expect(map['userIdIncluded'], isFalse);
      expect(map['phoneIncluded'], isFalse);
      expect(map['emailIncluded'], isFalse);
      expect(map['cnicIncluded'], isFalse);
      expect(map['pickupCoordinatesIncluded'], isFalse);
      expect(map['specialRequestIncluded'], isFalse);
      expect(map['financialAmountsIncluded'], isFalse);
      expect(map['privateAssignmentIdsIncluded'], isFalse);
      expect(map['writeAuthority'], isFalse);
      expect(map['cancelAuthority'], isFalse);
      expect(map['paymentMutationAuthority'], isFalse);
      expect(map['assignmentMutationAuthority'], isFalse);
    });
  });
}
