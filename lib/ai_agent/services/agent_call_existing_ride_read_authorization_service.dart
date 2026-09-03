import '../constants/agent_action_ids.dart';
import '../models/agent_call_existing_ride_read_authorization.dart';
import '../models/agent_call_existing_ride_support_contract.dart';
import '../models/agent_master_settings.dart';
import '../models/agent_permission_decision.dart';
import '../models/agent_role.dart';
import 'agent_permission_engine.dart';
import 'agent_runtime_gate.dart';

/// Stage 2 authorization adapter over the existing central security engines.
///
/// Canonical order:
/// 1. Validate exact trusted Call/Ride binding.
/// 2. AgentPermissionEngine.evaluate.
/// 3. AgentRuntimeGate.apply.
///
/// This service does not read a Ride and never writes a Ride.
class AgentCallExistingRideReadAuthorizationService {
  const AgentCallExistingRideReadAuthorizationService({
    this.permissionEngine = const AgentPermissionEngine(),
    this.runtimeGate = const AgentRuntimeGate(),
  });

  static const String callRoleId = 'call_agent';
  static const String callModule = 'call';
  static const String actionId = AgentActionId.readCallExistingRide;

  final AgentPermissionEngine permissionEngine;
  final AgentRuntimeGate runtimeGate;

  AgentCallExistingRideReadAuthorization authorize({
    required AgentMasterSettings settings,
    required AgentRole role,
    required AgentCallExistingRideSupportRequest request,
  }) {
    try {
      request.validate();
    } catch (_) {
      return _blocked('TRUSTED_EXISTING_RIDE_BINDING_REQUIRED');
    }

    final bool exactRoleBound = role.roleId.trim() == callRoleId;
    final bool exactModuleBound = role.module.trim() == callModule;

    if (!exactRoleBound || !exactModuleBound) {
      return AgentCallExistingRideReadAuthorization(
        permissionAllowed: false,
        runtimeAllowed: false,
        trustedContextBound: true,
        exactRoleBound: exactRoleBound,
        exactModuleBound: exactModuleBound,
        exactActionBound: false,
        approvalFreeRead: false,
        reason: 'CALL_EXISTING_RIDE_ROLE_MODULE_MISMATCH',
      );
    }

    final AgentPermissionDecision permissionDecision = permissionEngine
        .evaluate(role: role, actionId: actionId);

    final AgentPermissionDecision runtimeDecision = runtimeGate.apply(
      settings: settings,
      role: role,
      permissionDecision: permissionDecision,
    );

    final bool exactActionBound =
        permissionDecision.actionId.trim() == actionId &&
        runtimeDecision.actionId.trim() == actionId;

    final bool permissionAllowed = permissionDecision.isAllowed;
    final bool runtimeAllowed = runtimeDecision.isAllowed;

    final bool approvalFreeRead =
        !permissionDecision.needsApproval && !runtimeDecision.needsApproval;

    String reason = '';

    if (!exactActionBound) {
      reason = 'CALL_EXISTING_RIDE_ACTION_BINDING_MISMATCH';
    } else if (!permissionAllowed) {
      reason = permissionDecision.reason.trim().isEmpty
          ? 'CALL_EXISTING_RIDE_PERMISSION_BLOCKED'
          : permissionDecision.reason.trim();
    } else if (!runtimeAllowed) {
      reason = runtimeDecision.reason.trim().isEmpty
          ? 'CALL_EXISTING_RIDE_RUNTIME_BLOCKED'
          : runtimeDecision.reason.trim();
    } else if (!approvalFreeRead) {
      reason = 'CALL_EXISTING_RIDE_READ_MUST_NOT_REQUIRE_APPROVAL';
    }

    final AgentCallExistingRideReadAuthorization result =
        AgentCallExistingRideReadAuthorization(
          permissionAllowed: permissionAllowed,
          runtimeAllowed: runtimeAllowed,
          trustedContextBound: true,
          exactRoleBound: true,
          exactModuleBound: true,
          exactActionBound: exactActionBound,
          approvalFreeRead: approvalFreeRead,
          reason: reason,
        );

    result.validate();
    return result;
  }

  AgentCallExistingRideReadAuthorization _blocked(String reason) {
    return AgentCallExistingRideReadAuthorization(
      permissionAllowed: false,
      runtimeAllowed: false,
      trustedContextBound: false,
      exactRoleBound: false,
      exactModuleBound: false,
      exactActionBound: false,
      approvalFreeRead: false,
      reason: reason,
    );
  }

  bool get usesAgentPermissionEngine => true;
  bool get usesAgentRuntimeGate => true;
  bool get duplicatesPermissionLogic => false;

  bool get queryCanGrantPermission => false;
  bool get rawPhoneCanGrantPermission => false;
  bool get transcriptCanGrantPermission => false;
  bool get voiceCanGrantPermission => false;
  bool get currentFirebaseUserCanGrantPermission => false;
  bool get rideReferenceAloneCanGrantPermission => false;

  bool get writesRide => false;
  bool get cancelsRide => false;
  bool get reassignsDriver => false;
  bool get changesPayment => false;
  bool get issuesRefund => false;
  bool get changesFare => false;

  bool get invokesFirestore => false;
  bool get invokesFirebaseAuth => false;
  bool get invokesRideService => false;
  bool get invokesTelephonyProvider => false;
}
