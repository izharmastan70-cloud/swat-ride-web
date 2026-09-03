import '../models/agent_call_ride_booking_authorization.dart';
import '../models/agent_master_settings.dart';
import '../models/agent_permission_decision.dart';
import '../models/agent_role.dart';
import 'agent_call_ride_booking_authorization_broker.dart';
import 'agent_permission_engine.dart';
import 'agent_runtime_gate.dart';

/// Exact Phase 49 adapter over the existing security engines.
///
/// Canonical order:
/// 1. AgentPermissionEngine.evaluate
/// 2. AgentRuntimeGate.apply
///
/// No duplicate permission logic is introduced here.
class AgentCallRideBookingExistingSecurityGateway
    implements AgentCallRideBookingCentralAuthorizationGateway {
  const AgentCallRideBookingExistingSecurityGateway({
    this.permissionEngine = const AgentPermissionEngine(),
    this.runtimeGate = const AgentRuntimeGate(),
  });

  final AgentPermissionEngine permissionEngine;
  final AgentRuntimeGate runtimeGate;

  @override
  Future<AgentCallRideBookingCentralAuthorizationDecision> evaluate({
    required AgentMasterSettings settings,
    required AgentRole role,
    required String actionId,
    required String module,
    required String requestedBy,
    required Map<String, dynamic> actionScope,
  }) async {
    final String caller = (actionScope['trustedCallerReferenceId'] ?? '')
        .toString()
        .trim();
    final String contact = (actionScope['trustedContactReferenceId'] ?? '')
        .toString()
        .trim();
    final String idempotency = (actionScope['idempotencyKey'] ?? '')
        .toString()
        .trim();

    final bool trustedContextBound =
        requestedBy.trim().isNotEmpty &&
        caller.isNotEmpty &&
        contact.isNotEmpty &&
        idempotency.isNotEmpty;

    final AgentPermissionDecision permissionDecision = permissionEngine
        .evaluate(role: role, actionId: actionId);

    final AgentPermissionDecision runtimeDecision = runtimeGate.apply(
      settings: settings,
      role: role,
      permissionDecision: permissionDecision,
    );

    final bool permissionAllowed = permissionDecision.isAllowed;
    final bool runtimeAllowed = runtimeDecision.isAllowed;

    String reason = '';

    if (!trustedContextBound) {
      reason = 'TRUSTED_CALL_AUTHORITY_CONTEXT_REQUIRED';
    } else if (!permissionAllowed) {
      reason = permissionDecision.reason;
    } else if (!runtimeAllowed) {
      reason = runtimeDecision.reason;
    }

    final AgentCallRideBookingCentralAuthorizationDecision decision =
        AgentCallRideBookingCentralAuthorizationDecision(
          roleId: role.roleId,
          actionId: actionId.trim(),
          module: module.trim(),
          requestedBy: requestedBy.trim(),
          permissionAllowed: permissionAllowed,
          runtimeAllowed: runtimeAllowed,
          trustedAuthorityContextBound: trustedContextBound,
          permissionDecisionSource: 'AgentPermissionEngine',
          runtimeDecisionSource: 'AgentRuntimeGate',
          reason: reason,
        );

    decision.validate();
    return decision;
  }

  bool get duplicatesPermissionLogic => false;
  bool get writesRide => false;
  bool get writesFirestore => false;
  bool get createsApproval => false;
  bool get consumesApproval => false;
}
