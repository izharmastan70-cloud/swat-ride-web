import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_action_ids.dart';
import 'package:swat_ride/ai_agent/constants/agent_call_constants.dart';
import 'package:swat_ride/ai_agent/data/initial_agent_roles_seed.dart';
import 'package:swat_ride/ai_agent/models/agent_call_tour_booking_status_contract.dart';
import 'package:swat_ride/ai_agent/models/agent_call_tour_booking_status_orchestration.dart';
import 'package:swat_ride/ai_agent/models/agent_call_tour_booking_trusted_resolution.dart';
import 'package:swat_ride/ai_agent/models/agent_master_settings.dart';
import 'package:swat_ride/ai_agent/models/agent_role.dart';
import 'package:swat_ride/ai_agent/services/agent_call_tour_booking_status_orchestrator.dart';
import 'package:swat_ride/ai_agent/services/agent_call_tour_booking_trusted_backend_read_gateway.dart';

class _FakeTourStatusReadGateway
    implements AgentCallTourBookingStatusReadGateway {
  _FakeTourStatusReadGateway(this.builder);

  final AgentCallTourBookingStatusReadEvidence Function(
    AgentCallTourBookingStatusRequest request,
    DateTime now,
  )
  builder;

  int calls = 0;

  @override
  Future<AgentCallTourBookingStatusReadEvidence>
  readAuthorizedTourBookingStatus({
    required AgentCallTourBookingStatusRequest request,
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
  final DateTime now = DateTime.utc(2026, 8, 18, 12);

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

AgentCallTourBookingStatusReadEvidence _authorized(DateTime now) {
  return AgentCallTourBookingStatusReadEvidence.authorized(
    snapshot: _snapshot(now),
    observedAt: now,
  );
}

AgentCallTourBookingStatusReadEvidence _unavailable(DateTime now) {
  return AgentCallTourBookingStatusReadEvidence.unavailable(observedAt: now);
}

void main() {
  group('Phase 49 Stage 3 Step 3J Tour status orchestrator', () {
    final DateTime now = DateTime.utc(2026, 8, 18, 12, 10);

    test('normal trusted Tour status returns privacy-safe AI answer', () async {
      final gateway = _FakeTourStatusReadGateway(
        (request, time) => _authorized(time),
      );

      final orchestrator = AgentCallTourBookingStatusOrchestrator(
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
      expect(result.escalationRecommended, isFalse);
      expect(result.escalationLevel, AgentCallEscalationLevel.ai);
      expect(result.reason, 'AUTHORIZED_TRUSTED_TOUR_STATUS_READY');
      expect(result.snapshot, isNotNull);
      expect(result.snapshot!.bookingStatus, 'confirmed');
      expect(gateway.calls, 1);
    });

    test('disabled Call Agent recommends Human Support without read', () async {
      final gateway = _FakeTourStatusReadGateway(
        (request, time) => _authorized(time),
      );

      final orchestrator = AgentCallTourBookingStatusOrchestrator(
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

      expect(result.answerReady, isFalse);
      expect(result.escalationRecommended, isTrue);
      expect(result.escalationLevel, AgentCallEscalationLevel.humanSupport);
      expect(result.reason, 'TOUR_STATUS_AUTHORIZATION_BLOCKED');
      expect(result.snapshot, isNull);
      expect(gateway.calls, 0);
    });

    test(
      'invalid trusted Tour binding recommends Human Support without read',
      () async {
        final gateway = _FakeTourStatusReadGateway(
          (request, time) => _authorized(time),
        );

        final orchestrator = AgentCallTourBookingStatusOrchestrator(
          readGateway: gateway,
        );

        final result = await orchestrator.orchestrate(
          settings: _settings(),
          role: _callRole(),
          request: _request(booking: ''),
          intent: AgentCallIntent.unknown,
          serious: false,
          critical: false,
          now: now,
        );

        expect(result.escalationLevel, AgentCallEscalationLevel.humanSupport);
        expect(result.snapshot, isNull);
        expect(gateway.calls, 0);
      },
    );

    test('trusted Tour read unavailable recommends Human Support', () async {
      final gateway = _FakeTourStatusReadGateway(
        (request, time) => _unavailable(time),
      );

      final orchestrator = AgentCallTourBookingStatusOrchestrator(
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

      expect(result.escalationLevel, AgentCallEscalationLevel.humanSupport);
      expect(result.reason, 'TRUSTED_TOUR_STATUS_UNAVAILABLE');
      expect(result.snapshot, isNull);
      expect(gateway.calls, 1);
    });

    test('serious concern routes Manager/Admin before Tour read', () async {
      final gateway = _FakeTourStatusReadGateway(
        (request, time) => _authorized(time),
      );

      final result =
          await AgentCallTourBookingStatusOrchestrator(
            readGateway: gateway,
          ).orchestrate(
            settings: _settings(),
            role: _callRole(),
            request: _request(),
            intent: AgentCallIntent.unknown,
            serious: true,
            critical: false,
            now: now,
          );

      expect(result.escalationLevel, AgentCallEscalationLevel.managerAdmin);
      expect(gateway.calls, 0);
      expect(result.snapshot, isNull);
    });

    test('payment dispute routes Manager/Admin before Tour read', () async {
      final gateway = _FakeTourStatusReadGateway(
        (request, time) => _authorized(time),
      );

      final result =
          await AgentCallTourBookingStatusOrchestrator(
            readGateway: gateway,
          ).orchestrate(
            settings: _settings(),
            role: _callRole(),
            request: _request(),
            intent: AgentCallIntent.paymentDispute,
            serious: false,
            critical: false,
            now: now,
          );

      expect(result.escalationLevel, AgentCallEscalationLevel.managerAdmin);
      expect(gateway.calls, 0);
    });

    test('emergency routes Manager/Admin before Tour read', () async {
      final gateway = _FakeTourStatusReadGateway(
        (request, time) => _authorized(time),
      );

      final result =
          await AgentCallTourBookingStatusOrchestrator(
            readGateway: gateway,
          ).orchestrate(
            settings: _settings(),
            role: _callRole(),
            request: _request(),
            intent: AgentCallIntent.emergency,
            serious: false,
            critical: false,
            now: now,
          );

      expect(result.escalationLevel, AgentCallEscalationLevel.managerAdmin);
      expect(gateway.calls, 0);
    });

    test('critical concern routes Owner before Tour read', () async {
      final gateway = _FakeTourStatusReadGateway(
        (request, time) => _authorized(time),
      );

      final result =
          await AgentCallTourBookingStatusOrchestrator(
            readGateway: gateway,
          ).orchestrate(
            settings: _settings(),
            role: _callRole(),
            request: _request(),
            intent: AgentCallIntent.unknown,
            serious: false,
            critical: true,
            now: now,
          );

      expect(result.escalationLevel, AgentCallEscalationLevel.owner);
      expect(gateway.calls, 0);
    });

    test('legal concern routes Owner before Tour read', () async {
      final gateway = _FakeTourStatusReadGateway(
        (request, time) => _authorized(time),
      );

      final result =
          await AgentCallTourBookingStatusOrchestrator(
            readGateway: gateway,
          ).orchestrate(
            settings: _settings(),
            role: _callRole(),
            request: _request(),
            intent: AgentCallIntent.legal,
            serious: false,
            critical: false,
            now: now,
          );

      expect(result.escalationLevel, AgentCallEscalationLevel.owner);
      expect(gateway.calls, 0);
    });

    test('fraud concern routes Owner before Tour read', () async {
      final gateway = _FakeTourStatusReadGateway(
        (request, time) => _authorized(time),
      );

      final result =
          await AgentCallTourBookingStatusOrchestrator(
            readGateway: gateway,
          ).orchestrate(
            settings: _settings(),
            role: _callRole(),
            request: _request(),
            intent: AgentCallIntent.fraud,
            serious: false,
            critical: false,
            now: now,
          );

      expect(result.escalationLevel, AgentCallEscalationLevel.owner);
      expect(gateway.calls, 0);
    });

    test('safe result map is recommendation-only and mutation-free', () {
      final result = AgentCallTourBookingStatusOrchestrationResult(
        status:
            AgentCallTourBookingStatusOrchestrationStatus.escalationRecommended,
        escalationLevel: AgentCallEscalationLevel.humanSupport,
        reason: 'SAFE_TEST',
        processedAt: now,
      );

      final Map<String, dynamic> map = result.toSafeMap();

      expect(map['recommendationOnly'], isTrue);
      expect(map['actualTransferExecuted'], isFalse);
      expect(map['tourWriteExecuted'], isFalse);
      expect(map['tourCreateExecuted'], isFalse);
      expect(map['tourCancelExecuted'], isFalse);
      expect(map['tourPriceChanged'], isFalse);
      expect(map['tourPaymentChanged'], isFalse);
      expect(map['tourAssignmentChanged'], isFalse);
      expect(map['providerInvoked'], isFalse);
      expect(map['snapshot'], isNull);
    });

    test('orchestrator exposes no direct Tour side-effect authority', () {
      final gateway = _FakeTourStatusReadGateway(
        (request, time) => _authorized(time),
      );

      final orchestrator = AgentCallTourBookingStatusOrchestrator(
        readGateway: gateway,
      );

      expect(orchestrator.highRiskRoutedBeforeTourRead, isTrue);
      expect(orchestrator.authorizationBeforeRead, isTrue);
      expect(orchestrator.trustedGatewayOnly, isTrue);
      expect(orchestrator.privacyMinimizedSnapshotOnly, isTrue);
      expect(orchestrator.escalationRecommendationOnly, isTrue);

      expect(orchestrator.executesActualTransfer, isFalse);
      expect(orchestrator.invokesGenericTourConnectorDirectly, isFalse);
      expect(orchestrator.invokesTourBookingService, isFalse);
      expect(orchestrator.invokesFirestore, isFalse);
      expect(orchestrator.invokesFirebaseAuth, isFalse);
      expect(orchestrator.invokesHttp, isFalse);
      expect(orchestrator.invokesCloudFunctions, isFalse);
      expect(orchestrator.invokesTelephonyProvider, isFalse);
      expect(orchestrator.sendsSms, isFalse);

      expect(orchestrator.createsTourBooking, isFalse);
      expect(orchestrator.writesTourBooking, isFalse);
      expect(orchestrator.cancelsTourBooking, isFalse);
      expect(orchestrator.changesTourPrice, isFalse);
      expect(orchestrator.changesTourPayment, isFalse);
      expect(orchestrator.changesTourAssignment, isFalse);
    });

    test('Stage 3 final Call least privilege remains exactly four actions', () {
      final AgentRole role = _callRole();

      expect(role.allowedActions, <String>[
        AgentActionId.createCallRideBooking,
        AgentActionId.readCallExistingRide,
        AgentActionId.readCallFoodOrderStatus,
        AgentActionId.readCallTourBookingStatus,
      ]);

      expect(role.allowedActions, isNot(contains(AgentActionId.readFoodOrder)));
      expect(
        role.allowedActions,
        isNot(contains(AgentActionId.readTourBooking)),
      );
      expect(
        role.allowedActions,
        isNot(contains(AgentActionId.cancelTourBooking)),
      );
      expect(
        role.allowedActions,
        isNot(contains(AgentActionId.changeTourPrice)),
      );
    });

    test('Stage 3 final Tour snapshot remains privacy-minimized', () {
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

      for (final String forbiddenKey in <String>[
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
        expect(map.containsKey(forbiddenKey), isFalse);
      }
    });
  });
}
