import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_action_ids.dart';
import 'package:swat_ride/ai_agent/constants/agent_enums.dart';
import 'package:swat_ride/ai_agent/data/initial_agent_roles_seed.dart';
import 'package:swat_ride/ai_agent/models/agent_action_definition.dart';
import 'package:swat_ride/ai_agent/models/agent_call_ride_booking_idempotency_reservation.dart';
import 'package:swat_ride/ai_agent/models/agent_master_settings.dart';
import 'package:swat_ride/ai_agent/models/agent_role.dart';
import 'package:swat_ride/ai_agent/services/agent_action_registry.dart';
import 'package:swat_ride/ai_agent/services/agent_call_ride_booking_authorization_broker.dart';
import 'package:swat_ride/ai_agent/services/agent_call_ride_booking_central_authorization_gateway.dart';
import 'package:swat_ride/ai_agent/services/agent_call_ride_booking_idempotency_repository.dart';

class _MemoryReservationGateway
    implements AgentCallRideBookingIdempotencyReservationGateway {
  final Map<String, AgentCallRideBookingIdempotencyReservation> reservations =
      <String, AgentCallRideBookingIdempotencyReservation>{};

  int calls = 0;
  bool fail = false;
  bool returnBindingMismatch = false;

  @override
  Future<AgentCallRideBookingIdempotencyReservation> reserve({
    required String idempotencyKey,
    required String roleId,
    required String actionId,
    required String requestedBy,
    required String trustedCallerReferenceId,
    required String trustedContactReferenceId,
  }) async {
    calls += 1;

    if (fail) {
      throw const AgentCallRideBookingIdempotencyException(
        'test reservation failure',
      );
    }

    final AgentCallRideBookingIdempotencyReservation? existing =
        reservations[idempotencyKey];

    if (existing != null) {
      if (!existing.matchesBinding(
        roleId: roleId,
        actionId: actionId,
        requestedBy: requestedBy,
        trustedCallerReferenceId: trustedCallerReferenceId,
        trustedContactReferenceId: trustedContactReferenceId,
      )) {
        throw const AgentCallRideBookingIdempotencyException(
          'test binding conflict',
        );
      }

      return existing.copyWith(reusedExistingReservation: true);
    }

    final AgentCallRideBookingIdempotencyReservation created =
        AgentCallRideBookingIdempotencyReservation(
          reservationId: 'reservation-$idempotencyKey',
          idempotencyKey: idempotencyKey,
          roleId: returnBindingMismatch ? 'wrong-role' : roleId,
          actionId: actionId,
          requestedBy: requestedBy,
          trustedCallerReferenceId: trustedCallerReferenceId,
          trustedContactReferenceId: trustedContactReferenceId,
          status: AgentCallRideBookingIdempotencyReservationStatus.reserved,
          createdAt: DateTime.utc(2026, 8, 18, 8),
          reusedExistingReservation: false,
        );

    reservations[idempotencyKey] = created;
    return created;
  }
}

AgentMasterSettings _enabledSettings({
  bool master = true,
  bool emergencyReadOnly = false,
  bool freeAi = true,
  bool callAgent = true,
}) {
  return AgentMasterSettings.safeDefaults().copyWith(
    masterEnabled: master,
    emergencyReadOnly: emergencyReadOnly,
    freeAiEnabled: freeAi,
    callAgentEnabled: callAgent,
  );
}

AgentRole _seedCallRole() {
  return buildInitialAgentRoles().firstWhere(
    (AgentRole role) => role.roleId == 'call_agent',
  );
}

void main() {
  const AgentCallRideBookingExistingSecurityGateway centralGateway =
      AgentCallRideBookingExistingSecurityGateway();

  group('Phase 49 Step 1E exact security gateway', () {
    test(
      'call booking action is medium-risk non-read-only and no owner approval',
      () {
        final definition = AgentActionRegistry.get(
          AgentActionId.createCallRideBooking,
        );

        expect(definition, isNotNull);
        expect(definition!.module, 'call');
        expect(definition.risk, AgentActionRisk.medium);
        expect(definition.readOnly, isFalse);
        expect(definition.alwaysRequiresApproval, isFalse);
      },
    );

    test('seed call role is AUTO but remains least privilege', () {
      final AgentRole role = _seedCallRole();

      expect(role.mode, AgentMode.auto);
      expect(role.allowedActions, <String>[
        AgentActionId.createCallRideBooking,
        AgentActionId.readCallExistingRide,
        AgentActionId.readCallFoodOrderStatus,
        AgentActionId.readCallTourBookingStatus,
      ]);
      expect(
        role.allowedActions,
        isNot(contains(AgentActionId.transferCallToHuman)),
      );
      expect(
        role.allowedActions,
        isNot(contains(AgentActionId.transferCallToManager)),
      );
      expect(
        role.allowedActions,
        isNot(contains(AgentActionId.transferCallToOwner)),
      );
    });

    test(
      'real Permission Engine + Runtime Gate allow exact enabled booking role',
      () async {
        final AgentRole role = _seedCallRole();

        final decision = await centralGateway.evaluate(
          settings: _enabledSettings(),
          role: role,
          actionId: AgentActionId.createCallRideBooking,
          module: 'call',
          requestedBy: 'trusted-call-session-1',
          actionScope: const <String, dynamic>{
            'trustedCallerReferenceId': 'caller-ref-1',
            'trustedContactReferenceId': 'contact-ref-1',
            'idempotencyKey': 'session-1:booking-1',
          },
        );

        expect(decision.permissionAllowed, isTrue);
        expect(decision.runtimeAllowed, isTrue);
        expect(decision.isAllowed, isTrue);
        expect(decision.permissionDecisionSource, 'AgentPermissionEngine');
        expect(decision.runtimeDecisionSource, 'AgentRuntimeGate');
      },
    );

    test('master OFF fails in real Runtime Gate', () async {
      final decision = await centralGateway.evaluate(
        settings: _enabledSettings(master: false),
        role: _seedCallRole(),
        actionId: AgentActionId.createCallRideBooking,
        module: 'call',
        requestedBy: 'session',
        actionScope: const <String, dynamic>{
          'trustedCallerReferenceId': 'caller',
          'trustedContactReferenceId': 'contact',
          'idempotencyKey': 'key-master-off',
        },
      );

      expect(decision.isAllowed, isFalse);
      expect(decision.runtimeAllowed, isFalse);
      expect(decision.reason, contains('Master Control is OFF'));
    });

    test('Emergency Read-Only blocks Call booking write', () async {
      final decision = await centralGateway.evaluate(
        settings: _enabledSettings(emergencyReadOnly: true),
        role: _seedCallRole(),
        actionId: AgentActionId.createCallRideBooking,
        module: 'call',
        requestedBy: 'session',
        actionScope: const <String, dynamic>{
          'trustedCallerReferenceId': 'caller',
          'trustedContactReferenceId': 'contact',
          'idempotencyKey': 'key-emergency',
        },
      );

      expect(decision.isAllowed, isFalse);
      expect(decision.runtimeAllowed, isFalse);
    });

    test('Free AI OFF blocks Call Agent runtime', () async {
      final decision = await centralGateway.evaluate(
        settings: _enabledSettings(freeAi: false),
        role: _seedCallRole(),
        actionId: AgentActionId.createCallRideBooking,
        module: 'call',
        requestedBy: 'session',
        actionScope: const <String, dynamic>{
          'trustedCallerReferenceId': 'caller',
          'trustedContactReferenceId': 'contact',
          'idempotencyKey': 'key-free-off',
        },
      );

      expect(decision.isAllowed, isFalse);
      expect(decision.runtimeAllowed, isFalse);
    });

    test(
      'trusted scope is mandatory even if Permission/Runtime otherwise allow',
      () async {
        final decision = await centralGateway.evaluate(
          settings: _enabledSettings(),
          role: _seedCallRole(),
          actionId: AgentActionId.createCallRideBooking,
          module: 'call',
          requestedBy: 'session',
          actionScope: const <String, dynamic>{
            'trustedCallerReferenceId': '',
            'trustedContactReferenceId': 'contact',
            'idempotencyKey': 'key-missing-caller',
          },
        );

        expect(decision.isAllowed, isFalse);
        expect(decision.reason, 'TRUSTED_CALL_AUTHORITY_CONTEXT_REQUIRED');
      },
    );
  });

  group('Phase 49 Step 1E broker + idempotency', () {
    test('broker reserves idempotency only after central allow', () async {
      final _MemoryReservationGateway reservation = _MemoryReservationGateway();

      final broker = AgentCallRideBookingAuthorizationBroker(
        centralAuthorizationGateway: centralGateway,
        idempotencyReservationGateway: reservation,
      );

      final result = await broker.authorize(
        settings: _enabledSettings(),
        role: _seedCallRole(),
        requestedBy: 'trusted-session',
        trustedCallerReferenceId: 'caller-ref',
        trustedContactReferenceId: 'contact-ref',
        idempotencyKey: 'booking-key-1',
      );

      expect(result.baseAuthorityAllowed, isTrue);
      expect(result.idempotencyKeyReserved, isTrue);
      expect(reservation.calls, 1);
    });

    test('central deny does not reserve idempotency', () async {
      final _MemoryReservationGateway reservation = _MemoryReservationGateway();

      final broker = AgentCallRideBookingAuthorizationBroker(
        centralAuthorizationGateway: centralGateway,
        idempotencyReservationGateway: reservation,
      );

      final result = await broker.authorize(
        settings: _enabledSettings(master: false),
        role: _seedCallRole(),
        requestedBy: 'trusted-session',
        trustedCallerReferenceId: 'caller-ref',
        trustedContactReferenceId: 'contact-ref',
        idempotencyKey: 'booking-key-denied',
      );

      expect(result.baseAuthorityAllowed, isFalse);
      expect(reservation.calls, 0);
    });

    test(
      'same idempotency key + same binding reuses one reservation',
      () async {
        final _MemoryReservationGateway reservation =
            _MemoryReservationGateway();

        final broker = AgentCallRideBookingAuthorizationBroker(
          centralAuthorizationGateway: centralGateway,
          idempotencyReservationGateway: reservation,
        );

        final first = await broker.authorize(
          settings: _enabledSettings(),
          role: _seedCallRole(),
          requestedBy: 'trusted-session',
          trustedCallerReferenceId: 'caller-ref',
          trustedContactReferenceId: 'contact-ref',
          idempotencyKey: 'booking-key-reuse',
        );

        final second = await broker.authorize(
          settings: _enabledSettings(),
          role: _seedCallRole(),
          requestedBy: 'trusted-session',
          trustedCallerReferenceId: 'caller-ref',
          trustedContactReferenceId: 'contact-ref',
          idempotencyKey: 'booking-key-reuse',
        );

        expect(first.baseAuthorityAllowed, isTrue);
        expect(second.baseAuthorityAllowed, isTrue);
        expect(reservation.reservations.length, 1);
        expect(reservation.calls, 2);
      },
    );

    test('same key cannot silently bind to a different caller', () async {
      final _MemoryReservationGateway reservation = _MemoryReservationGateway();

      final broker = AgentCallRideBookingAuthorizationBroker(
        centralAuthorizationGateway: centralGateway,
        idempotencyReservationGateway: reservation,
      );

      final first = await broker.authorize(
        settings: _enabledSettings(),
        role: _seedCallRole(),
        requestedBy: 'trusted-session',
        trustedCallerReferenceId: 'caller-a',
        trustedContactReferenceId: 'contact-ref',
        idempotencyKey: 'booking-key-conflict',
      );

      final conflict = await broker.authorize(
        settings: _enabledSettings(),
        role: _seedCallRole(),
        requestedBy: 'trusted-session',
        trustedCallerReferenceId: 'caller-b',
        trustedContactReferenceId: 'contact-ref',
        idempotencyKey: 'booking-key-conflict',
      );

      expect(first.baseAuthorityAllowed, isTrue);
      expect(conflict.baseAuthorityAllowed, isFalse);
      expect(conflict.reason, 'IDEMPOTENCY_RESERVATION_FAILED');
    });

    test('invalid reservation binding fails closed', () async {
      final _MemoryReservationGateway reservation = _MemoryReservationGateway()
        ..returnBindingMismatch = true;

      final broker = AgentCallRideBookingAuthorizationBroker(
        centralAuthorizationGateway: centralGateway,
        idempotencyReservationGateway: reservation,
      );

      final result = await broker.authorize(
        settings: _enabledSettings(),
        role: _seedCallRole(),
        requestedBy: 'trusted-session',
        trustedCallerReferenceId: 'caller-ref',
        trustedContactReferenceId: 'contact-ref',
        idempotencyKey: 'booking-key-mismatch',
      );

      expect(result.baseAuthorityAllowed, isFalse);
      expect(result.reason, 'IDEMPOTENCY_RESERVATION_BINDING_MISMATCH');
    });

    test('reservation backend failure fails closed', () async {
      final _MemoryReservationGateway reservation = _MemoryReservationGateway()
        ..fail = true;

      final broker = AgentCallRideBookingAuthorizationBroker(
        centralAuthorizationGateway: centralGateway,
        idempotencyReservationGateway: reservation,
      );

      final result = await broker.authorize(
        settings: _enabledSettings(),
        role: _seedCallRole(),
        requestedBy: 'trusted-session',
        trustedCallerReferenceId: 'caller-ref',
        trustedContactReferenceId: 'contact-ref',
        idempotencyKey: 'booking-key-failure',
      );

      expect(result.baseAuthorityAllowed, isFalse);
      expect(result.reason, 'IDEMPOTENCY_RESERVATION_FAILED');
    });

    test(
      'deterministic Firestore reservation document ID is stable and slash-safe',
      () {
        final String first =
            AgentCallRideBookingIdempotencyRepository.encodeIdempotencyKey(
              'call/session/123:booking:1',
            );

        final String second =
            AgentCallRideBookingIdempotencyRepository.encodeIdempotencyKey(
              'call/session/123:booking:1',
            );

        expect(first, second);
        expect(first, isNot(contains('/')));
        expect(first, isNotEmpty);
      },
    );

    test('idempotency is not authorization and no Ride write is exposed', () {
      final broker = AgentCallRideBookingAuthorizationBroker(
        centralAuthorizationGateway: centralGateway,
        idempotencyReservationGateway: _MemoryReservationGateway(),
      );

      expect(broker.idempotencyIsAuthorization, isFalse);
      expect(broker.writesRide, isFalse);
      expect(broker.createsApproval, isFalse);
      expect(broker.consumesApproval, isFalse);
      expect(broker.sendsSms, isFalse);
      expect(broker.invokesTelephonyProvider, isFalse);
    });
  });
}
