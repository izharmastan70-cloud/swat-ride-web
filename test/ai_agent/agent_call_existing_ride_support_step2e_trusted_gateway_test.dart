import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/models/agent_call_existing_ride_support_contract.dart';
import 'package:swat_ride/ai_agent/models/agent_call_existing_ride_trusted_resolution.dart';
import 'package:swat_ride/ai_agent/services/agent_call_existing_ride_trusted_backend_read_gateway.dart';

class _FakeTrustedResolver
    implements AgentCallExistingRideTrustedBackendResolver {
  _FakeTrustedResolver({
    this.status = AgentCallExistingRideTrustedResolutionStatus.authorized,
    this.source = AgentCallExistingRideTrustedResolutionReceipt.trustedSource,
    this.accessVerified = true,
    this.throwOnResolve = false,
    this.overrideSessionId,
    this.overrideRequestedBy,
    this.overrideCallerRef,
    this.overrideContactRef,
    this.overridePresentedRideRef,
    this.verifiedOffset = Duration.zero,
    this.lifetime = const Duration(minutes: 1),
    this.includeSnapshot = true,
  });

  final String status;
  final String source;
  final bool accessVerified;
  final bool throwOnResolve;
  final String? overrideSessionId;
  final String? overrideRequestedBy;
  final String? overrideCallerRef;
  final String? overrideContactRef;
  final String? overridePresentedRideRef;
  final Duration verifiedOffset;
  final Duration lifetime;
  final bool includeSnapshot;

  int calls = 0;

  @override
  Future<AgentCallExistingRideTrustedResolutionReceipt> resolveAndRead({
    required AgentCallExistingRideTrustedResolutionRequest request,
    required DateTime now,
  }) async {
    calls += 1;

    if (throwOnResolve) {
      throw StateError('test resolver failure');
    }

    final DateTime verifiedAt = now.toUtc().add(verifiedOffset);
    final bool authorized =
        status == AgentCallExistingRideTrustedResolutionStatus.authorized;
    final String resolvedRideRef = request.presentedRideReferenceId;

    return AgentCallExistingRideTrustedResolutionReceipt(
      status: status,
      code: authorized ? 'TEST_AUTHORIZED' : 'TEST_UNAVAILABLE',
      source: source,
      callSessionId: overrideSessionId ?? request.callSessionId,
      requestedBy: overrideRequestedBy ?? request.requestedBy,
      trustedCallerReferenceId:
          overrideCallerRef ?? request.trustedCallerReferenceId,
      trustedContactReferenceId:
          overrideContactRef ?? request.trustedContactReferenceId,
      presentedRideReferenceId:
          overridePresentedRideRef ?? request.presentedRideReferenceId,
      resolvedRideReferenceId: authorized ? resolvedRideRef : '',
      ownershipOrAccessVerified: authorized ? accessVerified : false,
      verifiedAt: verifiedAt,
      expiresAt: verifiedAt.add(lifetime),
      snapshot: authorized && includeSnapshot
          ? AgentCallExistingRideSupportSnapshot(
              trustedRideReferenceId: resolvedRideRef,
              rideStatus: 'driver_arriving',
              vehicleName: 'Car',
              driverAssigned: true,
              driverDisplayName: 'Driver A',
              driverVehicleType: 'Sedan',
              driverVehicleNumber: 'SWAT-123',
              estimatedFare: 650,
              paymentStatus: 'pending',
              observedAt: verifiedAt,
            )
          : null,
    );
  }
}

AgentCallExistingRideSupportRequest _request({
  String rideReferenceId = 'ride-ref-1',
}) {
  return AgentCallExistingRideSupportRequest(
    callSessionId: 'call-session-1',
    requestedBy: 'trusted-call-actor-1',
    trustedCallerReferenceId: 'caller-ref-1',
    trustedContactReferenceId: 'contact-ref-1',
    trustedRideReferenceId: rideReferenceId,
    intent: AgentCallExistingRideSupportIntent.status,
  );
}

void main() {
  group('Phase 49 Stage 2 Step 2E trusted Ride resolver boundary', () {
    final DateTime now = DateTime.utc(2026, 8, 18, 9, 40);

    test(
      'valid trusted backend resolution becomes Stage 2B read evidence',
      () async {
        final _FakeTrustedResolver resolver = _FakeTrustedResolver();
        final gateway = AgentCallExistingRideTrustedBackendReadGateway(
          resolver: resolver,
        );

        final evidence = await gateway.readAuthorizedExistingRide(
          request: _request(),
          now: now,
        );

        expect(evidence.isFound, isTrue);
        expect(
          evidence.verificationSource,
          AgentCallExistingRideReadEvidence.trustedVerificationSource,
        );
        expect(evidence.trustedRideReferenceId, 'ride-ref-1');
        expect(evidence.snapshot?.rideStatus, 'driver_arriving');
        expect(resolver.calls, 1);
      },
    );

    test('support request maps exact opaque scope into resolver request', () {
      final supportRequest = _request();
      final resolutionRequest =
          AgentCallExistingRideTrustedResolutionRequest.fromSupportRequest(
            supportRequest,
          );

      expect(
        resolutionRequest.exactlyMatchesSupportRequest(supportRequest),
        isTrue,
      );

      final map = resolutionRequest.toSafeMap();
      expect(map['rawPhoneIncluded'], isFalse);
      expect(map['transcriptIncluded'], isFalse);
      expect(map['voiceIncluded'], isFalse);
      expect(map['firebaseUidIncluded'], isFalse);
    });

    test('resolver exception fails closed', () async {
      final gateway = AgentCallExistingRideTrustedBackendReadGateway(
        resolver: _FakeTrustedResolver(throwOnResolve: true),
      );

      final evidence = await gateway.readAuthorizedExistingRide(
        request: _request(),
        now: now,
      );

      expect(evidence.isBlocked, isTrue);
      expect(evidence.snapshot, isNull);
    });

    test('untrusted source cannot produce authorized Ride evidence', () async {
      final gateway = AgentCallExistingRideTrustedBackendReadGateway(
        resolver: _FakeTrustedResolver(source: 'CLIENT_ASSERTION'),
      );

      final evidence = await gateway.readAuthorizedExistingRide(
        request: _request(),
        now: now,
      );

      expect(evidence.isBlocked, isTrue);
      expect(evidence.snapshot, isNull);
    });

    test('ownership/access verification is mandatory', () async {
      final gateway = AgentCallExistingRideTrustedBackendReadGateway(
        resolver: _FakeTrustedResolver(accessVerified: false),
      );

      final evidence = await gateway.readAuthorizedExistingRide(
        request: _request(),
        now: now,
      );

      expect(evidence.isBlocked, isTrue);
      expect(evidence.snapshot, isNull);
    });

    test('missing authorized snapshot fails closed', () async {
      final gateway = AgentCallExistingRideTrustedBackendReadGateway(
        resolver: _FakeTrustedResolver(includeSnapshot: false),
      );

      final evidence = await gateway.readAuthorizedExistingRide(
        request: _request(),
        now: now,
      );

      expect(evidence.isBlocked, isTrue);
      expect(evidence.snapshot, isNull);
    });

    test('call-session mismatch fails closed', () async {
      final gateway = AgentCallExistingRideTrustedBackendReadGateway(
        resolver: _FakeTrustedResolver(overrideSessionId: 'other-session'),
      );

      final evidence = await gateway.readAuthorizedExistingRide(
        request: _request(),
        now: now,
      );

      expect(evidence.isBlocked, isTrue);
    });

    test('requestedBy mismatch fails closed', () async {
      final gateway = AgentCallExistingRideTrustedBackendReadGateway(
        resolver: _FakeTrustedResolver(overrideRequestedBy: 'other-actor'),
      );

      final evidence = await gateway.readAuthorizedExistingRide(
        request: _request(),
        now: now,
      );

      expect(evidence.isBlocked, isTrue);
    });

    test('caller binding mismatch fails closed', () async {
      final gateway = AgentCallExistingRideTrustedBackendReadGateway(
        resolver: _FakeTrustedResolver(overrideCallerRef: 'other-caller'),
      );

      final evidence = await gateway.readAuthorizedExistingRide(
        request: _request(),
        now: now,
      );

      expect(evidence.isBlocked, isTrue);
    });

    test('contact binding mismatch fails closed', () async {
      final gateway = AgentCallExistingRideTrustedBackendReadGateway(
        resolver: _FakeTrustedResolver(overrideContactRef: 'other-contact'),
      );

      final evidence = await gateway.readAuthorizedExistingRide(
        request: _request(),
        now: now,
      );

      expect(evidence.isBlocked, isTrue);
    });

    test('presented Ride reference mismatch fails closed', () async {
      final gateway = AgentCallExistingRideTrustedBackendReadGateway(
        resolver: _FakeTrustedResolver(
          overridePresentedRideRef: 'other-presented-ride',
        ),
      );

      final evidence = await gateway.readAuthorizedExistingRide(
        request: _request(),
        now: now,
      );

      expect(evidence.isBlocked, isTrue);
    });

    test('expired resolution fails closed', () async {
      final gateway = AgentCallExistingRideTrustedBackendReadGateway(
        resolver: _FakeTrustedResolver(
          verifiedOffset: const Duration(minutes: -2),
          lifetime: const Duration(minutes: 1),
        ),
      );

      final evidence = await gateway.readAuthorizedExistingRide(
        request: _request(),
        now: now,
      );

      expect(evidence.isBlocked, isTrue);
    });

    test('resolution lifetime over two minutes is invalid', () async {
      final gateway = AgentCallExistingRideTrustedBackendReadGateway(
        resolver: _FakeTrustedResolver(lifetime: const Duration(minutes: 3)),
      );

      final evidence = await gateway.readAuthorizedExistingRide(
        request: _request(),
        now: now,
      );

      expect(evidence.isBlocked, isTrue);
    });

    test('unavailable and blocked resolution hide Ride existence', () async {
      for (final String status in <String>[
        AgentCallExistingRideTrustedResolutionStatus.unavailable,
        AgentCallExistingRideTrustedResolutionStatus.blocked,
      ]) {
        final gateway = AgentCallExistingRideTrustedBackendReadGateway(
          resolver: _FakeTrustedResolver(status: status),
        );

        final evidence = await gateway.readAuthorizedExistingRide(
          request: _request(),
          now: now,
        );

        expect(evidence.isBlocked, isTrue);
        expect(evidence.snapshot, isNull);
        expect(evidence.code, 'AUTHORIZED_EXISTING_RIDE_UNAVAILABLE');
      }
    });

    test('receipt safe map exposes resolved Ride only after authorization', () {
      final receipt = AgentCallExistingRideTrustedResolutionReceipt(
        status: AgentCallExistingRideTrustedResolutionStatus.authorized,
        code: 'TEST_AUTHORIZED',
        source: AgentCallExistingRideTrustedResolutionReceipt.trustedSource,
        callSessionId: 'call-session-1',
        requestedBy: 'actor-1',
        trustedCallerReferenceId: 'caller-ref-1',
        trustedContactReferenceId: 'contact-ref-1',
        presentedRideReferenceId: 'ride-ref-1',
        resolvedRideReferenceId: 'ride-ref-1',
        ownershipOrAccessVerified: true,
        verifiedAt: now,
        expiresAt: now.add(const Duration(minutes: 1)),
        snapshot: AgentCallExistingRideSupportSnapshot(
          trustedRideReferenceId: 'ride-ref-1',
          rideStatus: 'driver_assigned',
          vehicleName: 'Car',
          driverAssigned: true,
          estimatedFare: 500,
          paymentStatus: 'pending',
          observedAt: now,
        ),
      );

      receipt.validate();

      final map = receipt.toSafeMap();

      expect(map['resolvedRideReferenceId'], 'ride-ref-1');
      expect(map['ownershipOrAccessVerified'], isTrue);
      expect(map['rawPhoneIncluded'], isFalse);
      expect(map['firebaseUidIncluded'], isFalse);
      expect(map['rideWriteAuthority'], isFalse);
    });

    test('gateway production boundary is server-only and read-only', () {
      final gateway = AgentCallExistingRideTrustedBackendReadGateway(
        resolver: _FakeTrustedResolver(),
      );

      expect(gateway.hasDefaultProductionResolver, isFalse);
      expect(gateway.requiresTrustedBackendResolver, isTrue);
      expect(gateway.backendMustVerifyRideAccess, isTrue);
      expect(gateway.backendMustUseTrustedServerState, isTrue);
      expect(gateway.clientRideLookupAllowed, isFalse);
      expect(gateway.arbitraryRideReferenceAllowed, isFalse);

      expect(gateway.rawPhoneCanAuthorize, isFalse);
      expect(gateway.transcriptCanAuthorize, isFalse);
      expect(gateway.voiceCanAuthorize, isFalse);
      expect(gateway.currentFirebaseUserCanAuthorize, isFalse);
      expect(gateway.rideReferenceAloneCanAuthorize, isFalse);

      expect(gateway.exposesRawPhone, isFalse);
      expect(gateway.exposesFirebaseUid, isFalse);
      expect(gateway.exposesLiveDriverGps, isFalse);
      expect(gateway.exposesRideStartPin, isFalse);

      expect(gateway.writesRide, isFalse);
      expect(gateway.cancelsRide, isFalse);
      expect(gateway.reassignsDriver, isFalse);
      expect(gateway.changesPayment, isFalse);
      expect(gateway.issuesRefund, isFalse);
      expect(gateway.changesFare, isFalse);

      expect(gateway.invokesFirestoreDirectly, isFalse);
      expect(gateway.invokesFirebaseAuthDirectly, isFalse);
      expect(gateway.invokesRideServiceDirectly, isFalse);
      expect(gateway.invokesHttpDirectly, isFalse);
      expect(gateway.invokesCloudFunctionsDirectly, isFalse);
      expect(gateway.invokesTelephonyProvider, isFalse);
    });
  });
}
