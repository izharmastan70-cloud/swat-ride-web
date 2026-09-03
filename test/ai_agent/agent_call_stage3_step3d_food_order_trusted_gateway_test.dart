import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/models/agent_call_food_order_status_contract.dart';
import 'package:swat_ride/ai_agent/models/agent_call_food_order_trusted_resolution.dart';
import 'package:swat_ride/ai_agent/services/agent_call_food_order_trusted_backend_read_gateway.dart';

class _FakeFoodResolver implements AgentCallFoodOrderTrustedBackendResolver {
  _FakeFoodResolver(this.receiptBuilder);

  final AgentCallFoodOrderTrustedResolutionReceipt Function(
    AgentCallFoodOrderTrustedResolutionRequest request,
    DateTime now,
  )
  receiptBuilder;

  int calls = 0;

  @override
  Future<AgentCallFoodOrderTrustedResolutionReceipt> resolveAndRead({
    required AgentCallFoodOrderTrustedResolutionRequest request,
    required DateTime now,
  }) async {
    calls++;
    return receiptBuilder(request, now);
  }
}

AgentCallFoodOrderStatusRequest _request({
  String session = 'call-session-food-1',
  String requestedBy = 'trusted-call-actor-1',
  String caller = 'caller-ref-1',
  String contact = 'contact-ref-1',
  String order = 'order-ref-1',
}) {
  return AgentCallFoodOrderStatusRequest(
    callSessionId: session,
    requestedBy: requestedBy,
    trustedCallerReferenceId: caller,
    trustedContactReferenceId: contact,
    trustedOrderReferenceId: order,
  );
}

AgentCallFoodOrderStatusSnapshot _snapshot(
  DateTime now, {
  String order = 'order-ref-1',
}) {
  return AgentCallFoodOrderStatusSnapshot(
    trustedOrderReferenceId: order,
    restaurantName: 'Safe Restaurant',
    orderStatus: 'preparing',
    paymentState: 'cash_due',
    hasAssignedRider: true,
    canTrackOrder: true,
    itemCount: 3,
    orderUpdatedAt: now.subtract(const Duration(seconds: 20)),
    observedAt: now.subtract(const Duration(seconds: 2)),
  );
}

AgentCallFoodOrderTrustedResolutionReceipt _authorizedReceipt(
  AgentCallFoodOrderTrustedResolutionRequest request,
  DateTime now, {
  String source =
      AgentCallFoodOrderTrustedResolutionReceipt.trustedBackendSource,
  String? session,
  String? order,
  bool accessVerified = true,
  DateTime? resolvedAt,
  AgentCallFoodOrderStatusSnapshot? snapshot,
}) {
  return AgentCallFoodOrderTrustedResolutionReceipt(
    status: AgentCallFoodOrderTrustedResolutionStatus.authorizedFoodOrder,
    source: source,
    callSessionId: session ?? request.callSessionId,
    requestedBy: request.requestedBy,
    trustedCallerReferenceId: request.trustedCallerReferenceId,
    trustedContactReferenceId: request.trustedContactReferenceId,
    presentedOrderReferenceId: order ?? request.presentedOrderReferenceId,
    backendAccessVerified: accessVerified,
    resolvedAt: resolvedAt ?? now,
    snapshot:
        snapshot ??
        _snapshot(now, order: order ?? request.presentedOrderReferenceId),
  );
}

AgentCallFoodOrderTrustedResolutionReceipt _unavailableReceipt(
  AgentCallFoodOrderTrustedResolutionRequest request,
  DateTime now, {
  String status =
      AgentCallFoodOrderTrustedResolutionStatus.foodOrderUnavailable,
}) {
  return AgentCallFoodOrderTrustedResolutionReceipt(
    status: status,
    source: AgentCallFoodOrderTrustedResolutionReceipt.trustedBackendSource,
    callSessionId: request.callSessionId,
    requestedBy: request.requestedBy,
    trustedCallerReferenceId: request.trustedCallerReferenceId,
    trustedContactReferenceId: request.trustedContactReferenceId,
    presentedOrderReferenceId: request.presentedOrderReferenceId,
    backendAccessVerified: false,
    resolvedAt: now,
  );
}

void main() {
  group('Phase 49 Stage 3 Step 3D trusted Food read gateway', () {
    final DateTime now = DateTime.utc(2026, 8, 18, 10, 30);

    test(
      'valid trusted backend receipt returns minimum Food status snapshot',
      () async {
        final _FakeFoodResolver resolver = _FakeFoodResolver(
          (request, time) => _authorizedReceipt(request, time),
        );

        final AgentCallFoodOrderTrustedBackendReadGateway gateway =
            AgentCallFoodOrderTrustedBackendReadGateway(resolver: resolver);

        final AgentCallFoodOrderStatusReadEvidence result = await gateway
            .readAuthorizedFoodOrderStatus(request: _request(), now: now);

        expect(result.isAuthorized, isTrue);
        expect(resolver.calls, 1);
        expect(result.snapshot, isNotNull);
        expect(result.snapshot!.trustedOrderReferenceId, 'order-ref-1');
        expect(result.snapshot!.restaurantName, 'Safe Restaurant');
        expect(result.snapshot!.orderStatus, 'preparing');
        expect(result.snapshot!.paymentState, 'cash_due');
        expect(result.snapshot!.itemCount, 3);
      },
    );

    test('Call snapshot safe map exposes only minimum operational fields', () {
      final Map<String, dynamic> safe = _snapshot(now).toSafeMap();

      expect(safe.keys.toSet(), <String>{
        'trustedOrderReferenceId',
        'restaurantName',
        'orderStatus',
        'paymentState',
        'hasAssignedRider',
        'canTrackOrder',
        'itemCount',
        'orderUpdatedAt',
        'observedAt',
      });

      expect(safe.containsKey('customerId'), isFalse);
      expect(safe.containsKey('customerPhone'), isFalse);
      expect(safe.containsKey('deliveryAddress'), isFalse);
      expect(safe.containsKey('deliveryOtp'), isFalse);
      expect(safe.containsKey('riderId'), isFalse);
      expect(safe.containsKey('latitude'), isFalse);
      expect(safe.containsKey('longitude'), isFalse);
      expect(safe.containsKey('items'), isFalse);
      expect(safe.containsKey('grandTotal'), isFalse);
      expect(safe.containsKey('paymentMethod'), isFalse);
    });

    test('not-found/unavailable is collapsed to generic unavailable', () async {
      final _FakeFoodResolver resolver = _FakeFoodResolver(
        (request, time) => _unavailableReceipt(request, time),
      );

      final gateway = AgentCallFoodOrderTrustedBackendReadGateway(
        resolver: resolver,
      );

      final result = await gateway.readAuthorizedFoodOrderStatus(
        request: _request(),
        now: now,
      );

      expect(result.isAuthorized, isFalse);
      expect(
        result.status,
        AgentCallFoodOrderStatusReadStatus.foodOrderStatusUnavailable,
      );
      expect(result.snapshot, isNull);
      expect(
        result.toSafeMap()['foodOrderExistenceDisclosedWhenUnavailable'],
        isFalse,
      );
    });

    test('backend-blocked is indistinguishable from unavailable', () async {
      final _FakeFoodResolver resolver = _FakeFoodResolver(
        (request, time) => _unavailableReceipt(
          request,
          time,
          status: AgentCallFoodOrderTrustedResolutionStatus
              .foodOrderResolutionBlocked,
        ),
      );

      final gateway = AgentCallFoodOrderTrustedBackendReadGateway(
        resolver: resolver,
      );

      final result = await gateway.readAuthorizedFoodOrderStatus(
        request: _request(),
        now: now,
      );

      expect(
        result.status,
        AgentCallFoodOrderStatusReadStatus.foodOrderStatusUnavailable,
      );
      expect(result.snapshot, isNull);
    });

    test('exact session binding mismatch fails closed', () async {
      final _FakeFoodResolver resolver = _FakeFoodResolver(
        (request, time) =>
            _authorizedReceipt(request, time, session: 'wrong-session'),
      );

      final gateway = AgentCallFoodOrderTrustedBackendReadGateway(
        resolver: resolver,
      );

      final result = await gateway.readAuthorizedFoodOrderStatus(
        request: _request(),
        now: now,
      );

      expect(result.isAuthorized, isFalse);
      expect(result.snapshot, isNull);
    });

    test('snapshot/order reference mismatch fails closed', () async {
      final _FakeFoodResolver resolver = _FakeFoodResolver(
        (request, time) => _authorizedReceipt(
          request,
          time,
          snapshot: _snapshot(time, order: 'other-order-ref'),
        ),
      );

      final gateway = AgentCallFoodOrderTrustedBackendReadGateway(
        resolver: resolver,
      );

      final result = await gateway.readAuthorizedFoodOrderStatus(
        request: _request(),
        now: now,
      );

      expect(result.isAuthorized, isFalse);
      expect(result.snapshot, isNull);
    });

    test('untrusted resolver source fails closed', () async {
      final _FakeFoodResolver resolver = _FakeFoodResolver(
        (request, time) =>
            _authorizedReceipt(request, time, source: 'CLIENT_LOCAL_FAKE'),
      );

      final gateway = AgentCallFoodOrderTrustedBackendReadGateway(
        resolver: resolver,
      );

      final result = await gateway.readAuthorizedFoodOrderStatus(
        request: _request(),
        now: now,
      );

      expect(result.isAuthorized, isFalse);
      expect(result.snapshot, isNull);
    });

    test('stale trusted resolution fails closed', () async {
      final _FakeFoodResolver resolver = _FakeFoodResolver(
        (request, time) => _authorizedReceipt(
          request,
          time,
          resolvedAt: time.subtract(const Duration(minutes: 3)),
        ),
      );

      final gateway = AgentCallFoodOrderTrustedBackendReadGateway(
        resolver: resolver,
      );

      final result = await gateway.readAuthorizedFoodOrderStatus(
        request: _request(),
        now: now,
      );

      expect(result.isAuthorized, isFalse);
      expect(result.snapshot, isNull);
    });

    test(
      'authorized status without backend access verification fails closed',
      () async {
        final _FakeFoodResolver resolver = _FakeFoodResolver(
          (request, time) =>
              _authorizedReceipt(request, time, accessVerified: false),
        );

        final gateway = AgentCallFoodOrderTrustedBackendReadGateway(
          resolver: resolver,
        );

        final result = await gateway.readAuthorizedFoodOrderStatus(
          request: _request(),
          now: now,
        );

        expect(result.isAuthorized, isFalse);
        expect(result.snapshot, isNull);
      },
    );

    test('invalid trusted request fails before resolver execution', () async {
      final _FakeFoodResolver resolver = _FakeFoodResolver(
        (request, time) => _authorizedReceipt(request, time),
      );

      final gateway = AgentCallFoodOrderTrustedBackendReadGateway(
        resolver: resolver,
      );

      final result = await gateway.readAuthorizedFoodOrderStatus(
        request: _request(caller: ''),
        now: now,
      );

      expect(result.isAuthorized, isFalse);
      expect(result.snapshot, isNull);
      expect(resolver.calls, 0);
    });

    test('gateway is contract-only and has no client/provider authority', () {
      final _FakeFoodResolver resolver = _FakeFoodResolver(
        (request, time) => _authorizedReceipt(request, time),
      );

      final gateway = AgentCallFoodOrderTrustedBackendReadGateway(
        resolver: resolver,
      );

      expect(gateway.requiresTrustedBackendResolver, isTrue);
      expect(gateway.defaultFlutterProductionResolverConnected, isFalse);
      expect(gateway.requiresBackendOrderAccessVerification, isTrue);
      expect(gateway.hidesUnauthorizedOrderExistence, isTrue);
      expect(gateway.requiresExactSessionBinding, isTrue);
      expect(gateway.requiresExactRequestedByBinding, isTrue);
      expect(gateway.requiresExactCallerBinding, isTrue);
      expect(gateway.requiresExactContactBinding, isTrue);
      expect(gateway.requiresExactOrderBinding, isTrue);
      expect(gateway.requiresFreshResolution, isTrue);

      expect(gateway.rawPhoneCanAuthorize, isFalse);
      expect(gateway.transcriptCanAuthorize, isFalse);
      expect(gateway.voiceCanAuthorize, isFalse);
      expect(gateway.currentFirebaseUserCanAuthorize, isFalse);
      expect(gateway.orderReferenceAloneCanAuthorize, isFalse);

      expect(gateway.invokesGenericFoodConnector, isFalse);
      expect(gateway.invokesFoodOrderService, isFalse);
      expect(gateway.invokesFirestore, isFalse);
      expect(gateway.invokesFirebaseAuth, isFalse);
      expect(gateway.invokesHttp, isFalse);
      expect(gateway.invokesCloudFunctions, isFalse);
      expect(gateway.invokesTelephonyProvider, isFalse);

      expect(gateway.writesFoodOrder, isFalse);
      expect(gateway.createsFoodOrder, isFalse);
      expect(gateway.cancelsFoodOrder, isFalse);
      expect(gateway.refundsFoodOrder, isFalse);
      expect(gateway.changesPayment, isFalse);
      expect(gateway.assignsRider, isFalse);
    });

    test('unavailable evidence safe map carries no sensitive Food fields', () {
      final evidence = AgentCallFoodOrderStatusReadEvidence.unavailable(
        observedAt: now,
      );

      final Map<String, dynamic> map = evidence.toSafeMap();

      expect(map['snapshot'], isNull);
      expect(map['rawPhoneIncluded'], isFalse);
      expect(map['customerIdentityIncluded'], isFalse);
      expect(map['deliveryAddressIncluded'], isFalse);
      expect(map['deliveryOtpIncluded'], isFalse);
      expect(map['riderIdentityIncluded'], isFalse);
      expect(map['gpsIncluded'], isFalse);
      expect(map['itemDetailsIncluded'], isFalse);
      expect(map['orderTotalsIncluded'], isFalse);
      expect(map['paymentCredentialsIncluded'], isFalse);
      expect(map['foodWriteAuthority'], isFalse);
    });
  });
}
