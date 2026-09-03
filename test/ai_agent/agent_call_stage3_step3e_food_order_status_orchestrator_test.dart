import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_call_constants.dart';
import 'package:swat_ride/ai_agent/data/initial_agent_roles_seed.dart';
import 'package:swat_ride/ai_agent/models/agent_call_food_order_status_contract.dart';
import 'package:swat_ride/ai_agent/models/agent_call_food_order_status_orchestration.dart';
import 'package:swat_ride/ai_agent/models/agent_call_food_order_trusted_resolution.dart';
import 'package:swat_ride/ai_agent/models/agent_master_settings.dart';
import 'package:swat_ride/ai_agent/models/agent_role.dart';
import 'package:swat_ride/ai_agent/services/agent_call_food_order_status_orchestrator.dart';
import 'package:swat_ride/ai_agent/services/agent_call_food_order_trusted_backend_read_gateway.dart';

class _FakeFoodStatusReadGateway
    implements AgentCallFoodOrderStatusReadGateway {
  _FakeFoodStatusReadGateway(this.builder);

  final AgentCallFoodOrderStatusReadEvidence Function(
    AgentCallFoodOrderStatusRequest request,
    DateTime now,
  )
  builder;

  int calls = 0;

  @override
  Future<AgentCallFoodOrderStatusReadEvidence> readAuthorizedFoodOrderStatus({
    required AgentCallFoodOrderStatusRequest request,
    required DateTime now,
  }) async {
    calls++;
    return builder(request, now);
  }
}

AgentRole _callRole() {
  return buildInitialAgentRoles().firstWhere(
    (AgentRole role) => role.roleId == 'call_agent',
  );
}

AgentMasterSettings _settings({
  bool masterEnabled = true,
  bool emergencyReadOnly = false,
  bool freeAiEnabled = true,
  bool callAgentEnabled = true,
}) {
  final DateTime now = DateTime.utc(2026, 8, 18, 10);

  return AgentMasterSettings(
    masterEnabled: masterEnabled,
    emergencyReadOnly: emergencyReadOnly,
    freeAiEnabled: freeAiEnabled,
    localAiEnabled: false,
    paidCodeAiEnabled: false,
    callAgentEnabled: callAgentEnabled,
    approvalEngineEnabled: true,
    auditLoggingEnabled: true,
    monthlyPaidCodeBudgetRs: 0,
    paidCodeBudgetUsedRs: 0,
    emergencyActivatedAt: emergencyReadOnly ? now : null,
    emergencyActivatedBy: emergencyReadOnly ? 'test' : '',
    emergencyReason: emergencyReadOnly ? 'test emergency' : '',
    createdAt: now,
    updatedAt: null,
  );
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

AgentCallFoodOrderStatusSnapshot _snapshot(DateTime now) {
  return AgentCallFoodOrderStatusSnapshot(
    trustedOrderReferenceId: 'order-ref-1',
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

AgentCallFoodOrderStatusReadEvidence _authorized(DateTime now) {
  return AgentCallFoodOrderStatusReadEvidence.authorized(
    snapshot: _snapshot(now),
    observedAt: now,
  );
}

AgentCallFoodOrderStatusReadEvidence _unavailable(DateTime now) {
  return AgentCallFoodOrderStatusReadEvidence.unavailable(observedAt: now);
}

void main() {
  group('Phase 49 Stage 3 Step 3E Food status orchestrator', () {
    final DateTime now = DateTime.utc(2026, 8, 18, 10, 40);

    test('normal trusted Food status request returns safe AI answer', () async {
      final gateway = _FakeFoodStatusReadGateway(
        (request, time) => _authorized(time),
      );

      final orchestrator = AgentCallFoodOrderStatusOrchestrator(
        readGateway: gateway,
      );

      final result = await orchestrator.orchestrate(
        settings: _settings(),
        role: _callRole(),
        request: _request(),
        intent: AgentCallIntent.unknown,
        serious: false,
        critical: false,
        now: now,
      );

      expect(result.answerReady, isTrue);
      expect(result.escalationLevel, AgentCallEscalationLevel.ai);
      expect(result.snapshot, isNotNull);
      expect(result.snapshot!.orderStatus, 'preparing');
      expect(gateway.calls, 1);
    });

    test(
      'authorization failure recommends Human Support without read',
      () async {
        final gateway = _FakeFoodStatusReadGateway(
          (request, time) => _authorized(time),
        );

        final orchestrator = AgentCallFoodOrderStatusOrchestrator(
          readGateway: gateway,
        );

        final result = await orchestrator.orchestrate(
          settings: _settings(callAgentEnabled: false),
          role: _callRole(),
          request: _request(),
          intent: AgentCallIntent.unknown,
          serious: false,
          critical: false,
          now: now,
        );

        expect(result.escalationRecommended, isTrue);
        expect(result.escalationLevel, AgentCallEscalationLevel.humanSupport);
        expect(result.snapshot, isNull);
        expect(gateway.calls, 0);
      },
    );

    test(
      'invalid trusted request recommends Human Support without read',
      () async {
        final gateway = _FakeFoodStatusReadGateway(
          (request, time) => _authorized(time),
        );

        final orchestrator = AgentCallFoodOrderStatusOrchestrator(
          readGateway: gateway,
        );

        final result = await orchestrator.orchestrate(
          settings: _settings(),
          role: _callRole(),
          request: _request(order: ''),
          intent: AgentCallIntent.unknown,
          serious: false,
          critical: false,
          now: now,
        );

        expect(result.escalationRecommended, isTrue);
        expect(result.escalationLevel, AgentCallEscalationLevel.humanSupport);
        expect(result.snapshot, isNull);
        expect(gateway.calls, 0);
      },
    );

    test('trusted Food read unavailable recommends Human Support', () async {
      final gateway = _FakeFoodStatusReadGateway(
        (request, time) => _unavailable(time),
      );

      final orchestrator = AgentCallFoodOrderStatusOrchestrator(
        readGateway: gateway,
      );

      final result = await orchestrator.orchestrate(
        settings: _settings(),
        role: _callRole(),
        request: _request(),
        intent: AgentCallIntent.unknown,
        serious: false,
        critical: false,
        now: now,
      );

      expect(result.escalationRecommended, isTrue);
      expect(result.escalationLevel, AgentCallEscalationLevel.humanSupport);
      expect(result.snapshot, isNull);
      expect(gateway.calls, 1);
    });

    test('serious concern routes Manager/Admin before Food read', () async {
      final gateway = _FakeFoodStatusReadGateway(
        (request, time) => _authorized(time),
      );

      final orchestrator = AgentCallFoodOrderStatusOrchestrator(
        readGateway: gateway,
      );

      final result = await orchestrator.orchestrate(
        settings: _settings(),
        role: _callRole(),
        request: _request(),
        intent: AgentCallIntent.unknown,
        serious: true,
        critical: false,
        now: now,
      );

      expect(result.escalationLevel, AgentCallEscalationLevel.managerAdmin);
      expect(result.snapshot, isNull);
      expect(gateway.calls, 0);
    });

    test('payment dispute routes Manager/Admin before Food read', () async {
      final gateway = _FakeFoodStatusReadGateway(
        (request, time) => _authorized(time),
      );

      final orchestrator = AgentCallFoodOrderStatusOrchestrator(
        readGateway: gateway,
      );

      final result = await orchestrator.orchestrate(
        settings: _settings(),
        role: _callRole(),
        request: _request(),
        intent: AgentCallIntent.paymentDispute,
        serious: false,
        critical: false,
        now: now,
      );

      expect(result.escalationLevel, AgentCallEscalationLevel.managerAdmin);
      expect(result.snapshot, isNull);
      expect(gateway.calls, 0);
    });

    test('emergency routes Manager/Admin before Food read', () async {
      final gateway = _FakeFoodStatusReadGateway(
        (request, time) => _authorized(time),
      );

      final orchestrator = AgentCallFoodOrderStatusOrchestrator(
        readGateway: gateway,
      );

      final result = await orchestrator.orchestrate(
        settings: _settings(),
        role: _callRole(),
        request: _request(),
        intent: AgentCallIntent.emergency,
        serious: false,
        critical: false,
        now: now,
      );

      expect(result.escalationLevel, AgentCallEscalationLevel.managerAdmin);
      expect(result.snapshot, isNull);
      expect(gateway.calls, 0);
    });

    test('critical concern routes Owner before Food read', () async {
      final gateway = _FakeFoodStatusReadGateway(
        (request, time) => _authorized(time),
      );

      final orchestrator = AgentCallFoodOrderStatusOrchestrator(
        readGateway: gateway,
      );

      final result = await orchestrator.orchestrate(
        settings: _settings(),
        role: _callRole(),
        request: _request(),
        intent: AgentCallIntent.unknown,
        serious: false,
        critical: true,
        now: now,
      );

      expect(result.escalationLevel, AgentCallEscalationLevel.owner);
      expect(result.snapshot, isNull);
      expect(gateway.calls, 0);
    });

    test('legal concern routes Owner before Food read', () async {
      final gateway = _FakeFoodStatusReadGateway(
        (request, time) => _authorized(time),
      );

      final orchestrator = AgentCallFoodOrderStatusOrchestrator(
        readGateway: gateway,
      );

      final result = await orchestrator.orchestrate(
        settings: _settings(),
        role: _callRole(),
        request: _request(),
        intent: AgentCallIntent.legal,
        serious: false,
        critical: false,
        now: now,
      );

      expect(result.escalationLevel, AgentCallEscalationLevel.owner);
      expect(result.snapshot, isNull);
      expect(gateway.calls, 0);
    });

    test('fraud concern routes Owner before Food read', () async {
      final gateway = _FakeFoodStatusReadGateway(
        (request, time) => _authorized(time),
      );

      final orchestrator = AgentCallFoodOrderStatusOrchestrator(
        readGateway: gateway,
      );

      final result = await orchestrator.orchestrate(
        settings: _settings(),
        role: _callRole(),
        request: _request(),
        intent: AgentCallIntent.fraud,
        serious: false,
        critical: false,
        now: now,
      );

      expect(result.escalationLevel, AgentCallEscalationLevel.owner);
      expect(result.snapshot, isNull);
      expect(gateway.calls, 0);
    });

    test('orchestration result is recommendation-only and write-free', () {
      final result = AgentCallFoodOrderStatusOrchestrationResult(
        status:
            AgentCallFoodOrderStatusOrchestrationStatus.escalationRecommended,
        escalationLevel: AgentCallEscalationLevel.humanSupport,
        reason: 'TEST',
        processedAt: now,
      );

      final Map<String, dynamic> map = result.toSafeMap();

      expect(map['recommendationOnly'], isTrue);
      expect(map['actualTransferExecuted'], isFalse);
      expect(map['foodWriteExecuted'], isFalse);
      expect(map['refundExecuted'], isFalse);
      expect(map['cancelExecuted'], isFalse);
      expect(map['paymentChanged'], isFalse);
      expect(map['riderAssignmentChanged'], isFalse);
      expect(map['providerInvoked'], isFalse);
    });

    test('orchestrator exposes no direct side-effect authority', () {
      final gateway = _FakeFoodStatusReadGateway(
        (request, time) => _authorized(time),
      );

      final orchestrator = AgentCallFoodOrderStatusOrchestrator(
        readGateway: gateway,
      );

      expect(orchestrator.highRiskRoutedBeforeFoodRead, isTrue);
      expect(orchestrator.authorizationBeforeRead, isTrue);
      expect(orchestrator.trustedGatewayOnly, isTrue);
      expect(orchestrator.privacyMinimizedSnapshotOnly, isTrue);
      expect(orchestrator.escalationRecommendationOnly, isTrue);

      expect(orchestrator.executesActualTransfer, isFalse);
      expect(orchestrator.invokesGenericFoodConnectorDirectly, isFalse);
      expect(orchestrator.invokesFoodOrderService, isFalse);
      expect(orchestrator.invokesFirestore, isFalse);
      expect(orchestrator.invokesFirebaseAuth, isFalse);
      expect(orchestrator.invokesHttp, isFalse);
      expect(orchestrator.invokesCloudFunctions, isFalse);
      expect(orchestrator.invokesTelephonyProvider, isFalse);
      expect(orchestrator.sendsSms, isFalse);

      expect(orchestrator.createsFoodOrder, isFalse);
      expect(orchestrator.writesFoodOrder, isFalse);
      expect(orchestrator.cancelsFoodOrder, isFalse);
      expect(orchestrator.refundsFoodOrder, isFalse);
      expect(orchestrator.changesPayment, isFalse);
      expect(orchestrator.assignsRider, isFalse);
    });
  });
}
