import '../constants/agent_action_ids.dart';
import '../models/agent_call_ride_booking_authorization.dart';
import '../models/agent_call_ride_booking_execution_contract.dart';
import '../models/agent_call_ride_booking_idempotency_reservation.dart';
import '../models/agent_master_settings.dart';
import '../models/agent_role.dart';

abstract class AgentCallRideBookingCentralAuthorizationGateway {
  Future<AgentCallRideBookingCentralAuthorizationDecision> evaluate({
    required AgentMasterSettings settings,
    required AgentRole role,
    required String actionId,
    required String module,
    required String requestedBy,
    required Map<String, dynamic> actionScope,
  });
}

abstract class AgentCallRideBookingIdempotencyReservationGateway {
  Future<AgentCallRideBookingIdempotencyReservation> reserve({
    required String idempotencyKey,
    required String roleId,
    required String actionId,
    required String requestedBy,
    required String trustedCallerReferenceId,
    required String trustedContactReferenceId,
  });
}

/// Phase 49 Call Ride Booking authorization broker.
///
/// Security order:
/// 1. exact Call role/module + master feature switch;
/// 2. trusted caller/contact/idempotency context exists;
/// 3. central Permission Engine + Runtime Gate allow;
/// 4. persistent idempotency key is reserved with the exact same binding;
/// 5. only then Step 1B receives baseAuthorityAllowed.
///
/// Voice/text/transcript never grants authority.
/// Idempotency is duplicate prevention, never an authorization source.
/// No real Ride write occurs here.
class AgentCallRideBookingAuthorizationBroker {
  const AgentCallRideBookingAuthorizationBroker({
    required this.centralAuthorizationGateway,
    required this.idempotencyReservationGateway,
  });

  static const String callRoleId = 'call_agent';
  static const String callModule = 'call';

  final AgentCallRideBookingCentralAuthorizationGateway
  centralAuthorizationGateway;

  final AgentCallRideBookingIdempotencyReservationGateway
  idempotencyReservationGateway;

  Future<AgentCallRideBookingAuthorization> authorize({
    required AgentMasterSettings settings,
    required AgentRole role,
    required String requestedBy,
    required String trustedCallerReferenceId,
    required String trustedContactReferenceId,
    required String idempotencyKey,
  }) async {
    final String actor = requestedBy.trim();
    final String callerRef = trustedCallerReferenceId.trim();
    final String contactRef = trustedContactReferenceId.trim();
    final String idempotency = idempotencyKey.trim();

    if (role.roleId.trim() != callRoleId || role.module.trim() != callModule) {
      return _blocked('CALL_BOOKING_EXACT_CALL_ROLE_REQUIRED');
    }

    if (!settings.callAgentEnabled) {
      return _blocked('CALL_AGENT_MASTER_DISABLED');
    }

    if (!role.enabled || role.isFailClosed) {
      return _blocked('CALL_AGENT_ROLE_DISABLED_OR_FAIL_CLOSED');
    }

    if (actor.isEmpty ||
        callerRef.isEmpty ||
        contactRef.isEmpty ||
        idempotency.isEmpty) {
      return _blocked('TRUSTED_CALL_AUTHORITY_CONTEXT_REQUIRED');
    }

    if (!role.allowedActions.contains(AgentActionId.createCallRideBooking)) {
      return _blocked('CALL_BOOKING_ACTION_NOT_ALLOWED_FOR_ROLE');
    }

    final AgentCallRideBookingCentralAuthorizationDecision decision =
        await centralAuthorizationGateway.evaluate(
          settings: settings,
          role: role,
          actionId: AgentActionId.createCallRideBooking,
          module: callModule,
          requestedBy: actor,
          actionScope: <String, dynamic>{
            'trustedCallerReferenceId': callerRef,
            'trustedContactReferenceId': contactRef,
            'idempotencyKey': idempotency,
          },
        );

    decision.validate();

    if (decision.roleId.trim() != callRoleId ||
        decision.actionId.trim() != AgentActionId.createCallRideBooking ||
        decision.module.trim() != callModule ||
        decision.requestedBy.trim() != actor) {
      return _blocked('CENTRAL_AUTHORIZATION_BINDING_MISMATCH');
    }

    if (!decision.isAllowed) {
      return _blocked(
        decision.reason.trim().isEmpty
            ? 'CENTRAL_AUTHORIZATION_BLOCKED'
            : decision.reason.trim(),
      );
    }

    AgentCallRideBookingIdempotencyReservation reservation;

    try {
      reservation = await idempotencyReservationGateway.reserve(
        idempotencyKey: idempotency,
        roleId: callRoleId,
        actionId: AgentActionId.createCallRideBooking,
        requestedBy: actor,
        trustedCallerReferenceId: callerRef,
        trustedContactReferenceId: contactRef,
      );
    } catch (_) {
      return _blocked('IDEMPOTENCY_RESERVATION_FAILED');
    }

    try {
      reservation.validate();
    } catch (_) {
      return _blocked('IDEMPOTENCY_RESERVATION_INVALID');
    }

    if (!reservation.isReserved ||
        reservation.idempotencyKey != idempotency ||
        !reservation.matchesBinding(
          roleId: callRoleId,
          actionId: AgentActionId.createCallRideBooking,
          requestedBy: actor,
          trustedCallerReferenceId: callerRef,
          trustedContactReferenceId: contactRef,
        )) {
      return _blocked('IDEMPOTENCY_RESERVATION_BINDING_MISMATCH');
    }

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

  AgentCallRideBookingAuthorization _blocked(String reason) {
    return AgentCallRideBookingAuthorization(
      callAgentMasterEnabled: false,
      runtimeAllowed: false,
      permissionAllowed: false,
      dedicatedBookingActionAllowed: false,
      trustedCallerBound: false,
      trustedContactBound: false,
      idempotencyKeyReserved: false,
      reason: reason,
    );
  }

  bool get queryCanGrantPermission => false;
  bool get voiceCanGrantPermission => false;
  bool get transcriptCanGrantRuntime => false;
  bool get aiCanSelectPrivilegedAction => false;
  bool get idempotencyIsAuthorization => false;
  bool get writesRide => false;
  bool get createsApproval => false;
  bool get consumesApproval => false;
  bool get changesPricing => false;
  bool get changesCommission => false;
  bool get changesPayment => false;
  bool get changesDriverState => false;
  bool get sendsSms => false;
  bool get invokesTelephonyProvider => false;
  bool get invokesSpeechToTextProvider => false;
  bool get invokesTextToSpeechProvider => false;
  bool get storesRawAudio => false;
  bool get deploys => false;

  bool get requiresCentralPermissionDecision => true;
  bool get requiresCentralRuntimeDecision => true;
  bool get requiresDedicatedAction => true;
  bool get requiresTrustedCallerBinding => true;
  bool get requiresTrustedContactBinding => true;
  bool get requiresIdempotencyReservation => true;
}
