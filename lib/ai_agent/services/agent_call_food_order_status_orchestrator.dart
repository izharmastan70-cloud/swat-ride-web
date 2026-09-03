import '../constants/agent_call_constants.dart';
import '../models/agent_call_food_order_status_contract.dart';
import '../models/agent_call_food_order_status_orchestration.dart';
import '../models/agent_call_food_order_trusted_resolution.dart';
import '../models/agent_master_settings.dart';
import '../models/agent_role.dart';
import 'agent_call_escalation_router.dart';
import 'agent_call_food_order_status_authorization_service.dart';
import 'agent_call_food_order_trusted_backend_read_gateway.dart';

/// Phase 49 Stage 3 Step 3E.
///
/// Safe sequence for normal Food order STATUS support:
/// 1. Route high-risk concerns before any Food read.
/// 2. Step 3C dedicated Call authorization.
/// 3. Step 3D trusted backend Food status read gateway.
/// 4. Return only the privacy-minimized snapshot.
///
/// Failed authorization or unavailable trusted read becomes a Human Support
/// recommendation. Serious/payment/emergency becomes Manager/Admin.
/// Critical/legal/fraud becomes Owner.
///
/// This orchestrator NEVER executes the transfer itself.
class AgentCallFoodOrderStatusOrchestrator {
  const AgentCallFoodOrderStatusOrchestrator({
    required this.readGateway,
    this.authorizationService =
        const AgentCallFoodOrderStatusAuthorizationService(),
    this.escalationRouter = const AgentCallEscalationRouter(),
  });

  final AgentCallFoodOrderStatusReadGateway readGateway;
  final AgentCallFoodOrderStatusAuthorizationService authorizationService;
  final AgentCallEscalationRouter escalationRouter;

  Future<AgentCallFoodOrderStatusOrchestrationResult> orchestrate({
    required AgentMasterSettings settings,
    required AgentRole role,
    required AgentCallFoodOrderStatusRequest request,
    required String intent,
    required bool serious,
    required bool critical,
    required DateTime now,
  }) async {
    final DateTime normalizedNow = now.toUtc();

    final String preReadTarget = escalationRouter.route(
      intent: intent,
      aiCanSolve: true,
      serious: serious,
      critical: critical,
    );

    if (preReadTarget != AgentCallEscalationLevel.ai) {
      return _escalation(
        level: preReadTarget,
        reason: 'HIGH_RISK_CONCERN_ROUTED_BEFORE_FOOD_READ',
        now: normalizedNow,
      );
    }

    final authorization = authorizationService.authorize(
      settings: settings,
      role: role,
      request: request,
    );

    if (!authorization.isAllowed) {
      return _unresolved(
        reason: 'FOOD_STATUS_AUTHORIZATION_BLOCKED',
        now: normalizedNow,
      );
    }

    final AgentCallFoodOrderStatusReadEvidence evidence = await readGateway
        .readAuthorizedFoodOrderStatus(request: request, now: normalizedNow);

    if (!evidence.isAuthorized || evidence.snapshot == null) {
      return _unresolved(
        reason: 'TRUSTED_FOOD_STATUS_UNAVAILABLE',
        now: normalizedNow,
      );
    }

    final AgentCallFoodOrderStatusSnapshot snapshot = evidence.snapshot!;

    snapshot.validate();

    final result = AgentCallFoodOrderStatusOrchestrationResult(
      status: AgentCallFoodOrderStatusOrchestrationStatus.answerReady,
      escalationLevel: AgentCallEscalationLevel.ai,
      reason: 'AUTHORIZED_TRUSTED_FOOD_STATUS_READY',
      processedAt: normalizedNow,
      snapshot: snapshot,
    );

    result.validate();
    return result;
  }

  AgentCallFoodOrderStatusOrchestrationResult _unresolved({
    required String reason,
    required DateTime now,
  }) {
    final String target = escalationRouter.route(
      intent: AgentCallIntent.unknown,
      aiCanSolve: false,
      serious: false,
      critical: false,
    );

    return _escalation(level: target, reason: reason, now: now);
  }

  AgentCallFoodOrderStatusOrchestrationResult _escalation({
    required String level,
    required String reason,
    required DateTime now,
  }) {
    final result = AgentCallFoodOrderStatusOrchestrationResult(
      status: AgentCallFoodOrderStatusOrchestrationStatus.escalationRecommended,
      escalationLevel: level,
      reason: reason,
      processedAt: now,
    );

    result.validate();
    return result;
  }

  bool get highRiskRoutedBeforeFoodRead => true;
  bool get authorizationBeforeRead => true;
  bool get trustedGatewayOnly => true;
  bool get privacyMinimizedSnapshotOnly => true;
  bool get escalationRecommendationOnly => true;

  bool get executesActualTransfer => false;
  bool get invokesGenericFoodConnectorDirectly => false;
  bool get invokesFoodOrderService => false;
  bool get invokesFirestore => false;
  bool get invokesFirebaseAuth => false;
  bool get invokesHttp => false;
  bool get invokesCloudFunctions => false;
  bool get invokesTelephonyProvider => false;
  bool get sendsSms => false;

  bool get createsFoodOrder => false;
  bool get writesFoodOrder => false;
  bool get cancelsFoodOrder => false;
  bool get refundsFoodOrder => false;
  bool get changesPayment => false;
  bool get assignsRider => false;
}
