import '../constants/agent_action_ids.dart';
import '../models/agent_call_food_order_status_authorization.dart';
import '../models/agent_call_food_order_status_contract.dart';
import '../models/agent_master_settings.dart';
import '../models/agent_permission_decision.dart';
import '../models/agent_role.dart';
import 'agent_permission_engine.dart';
import 'agent_runtime_gate.dart';

/// Phase 49 Stage 3 authorization boundary for Food order STATUS / READ.
///
/// Canonical order:
/// 1. Validate exact trusted Call/caller/contact/order binding.
/// 2. AgentPermissionEngine.evaluate.
/// 3. AgentRuntimeGate.apply.
///
/// This service authorizes only the dedicated CALL action
/// `call.read_food_order_status`.
///
/// It deliberately does NOT execute `food.read_order`, does not call the Food
/// connector and does not read/write any Food business data.
class AgentCallFoodOrderStatusAuthorizationService {
  const AgentCallFoodOrderStatusAuthorizationService({
    this.permissionEngine = const AgentPermissionEngine(),
    this.runtimeGate = const AgentRuntimeGate(),
  });

  static const String callRoleId = 'call_agent';
  static const String callModule = 'call';
  static const String actionId = AgentActionId.readCallFoodOrderStatus;
  static const String businessReadActionId = AgentActionId.readFoodOrder;

  final AgentPermissionEngine permissionEngine;
  final AgentRuntimeGate runtimeGate;

  AgentCallFoodOrderStatusAuthorization authorize({
    required AgentMasterSettings settings,
    required AgentRole role,
    required AgentCallFoodOrderStatusRequest request,
  }) {
    try {
      request.validate();
    } catch (_) {
      return _blocked('TRUSTED_FOOD_ORDER_BINDING_REQUIRED');
    }

    final bool exactRoleBound = role.roleId.trim() == callRoleId;
    final bool exactModuleBound = role.module.trim() == callModule;

    if (!exactRoleBound || !exactModuleBound) {
      return AgentCallFoodOrderStatusAuthorization(
        permissionAllowed: false,
        runtimeAllowed: false,
        trustedContextBound: true,
        exactRoleBound: exactRoleBound,
        exactModuleBound: exactModuleBound,
        exactActionBound: false,
        approvalFreeRead: false,
        reason: 'CALL_FOOD_STATUS_ROLE_MODULE_MISMATCH',
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
      reason = 'CALL_FOOD_STATUS_ACTION_BINDING_MISMATCH';
    } else if (!permissionAllowed) {
      reason = permissionDecision.reason.trim().isEmpty
          ? 'CALL_FOOD_STATUS_PERMISSION_BLOCKED'
          : permissionDecision.reason.trim();
    } else if (!runtimeAllowed) {
      reason = runtimeDecision.reason.trim().isEmpty
          ? 'CALL_FOOD_STATUS_RUNTIME_BLOCKED'
          : runtimeDecision.reason.trim();
    } else if (!approvalFreeRead) {
      reason = 'CALL_FOOD_STATUS_READ_MUST_NOT_REQUIRE_APPROVAL';
    }

    final AgentCallFoodOrderStatusAuthorization result =
        AgentCallFoodOrderStatusAuthorization(
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

  AgentCallFoodOrderStatusAuthorization _blocked(String reason) {
    return AgentCallFoodOrderStatusAuthorization(
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

  bool get genericFoodActionCanGrantCallPermission => false;
  bool get rawPhoneCanGrantPermission => false;
  bool get transcriptCanGrantPermission => false;
  bool get voiceCanGrantPermission => false;
  bool get currentFirebaseUserCanGrantPermission => false;
  bool get orderReferenceAloneCanGrantPermission => false;

  bool get executesFoodConnector => false;
  bool get readsFoodOrder => false;
  bool get writesFoodOrder => false;
  bool get createsFoodOrder => false;
  bool get cancelsFoodOrder => false;
  bool get refundsFoodOrder => false;
  bool get changesPayment => false;
  bool get assignsRider => false;

  bool get invokesFirestore => false;
  bool get invokesFirebaseAuth => false;
  bool get invokesFoodOrderService => false;
  bool get invokesHttp => false;
  bool get invokesCloudFunctions => false;
  bool get invokesTelephonyProvider => false;
}
