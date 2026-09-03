import '../constants/agent_call_constants.dart';
import '../models/agent_call_tour_booking_status_contract.dart';
import '../models/agent_call_tour_booking_status_orchestration.dart';
import '../models/agent_call_tour_booking_trusted_resolution.dart';
import '../models/agent_master_settings.dart';
import '../models/agent_role.dart';
import 'agent_call_escalation_router.dart';
import 'agent_call_tour_booking_status_authorization_service.dart';
import 'agent_call_tour_booking_trusted_backend_read_gateway.dart';

/// Phase 49 Stage 3 Step 3J.
///
/// Safe Tour booking STATUS sequence:
/// 1. Route serious/critical/high-risk concerns BEFORE Tour read.
/// 2. Step 3H dedicated `call.read_tour_booking_status` authorization.
/// 3. Step 3I trusted backend Tour booking status read gateway.
/// 4. Return only the Step 3I privacy-minimized snapshot.
///
/// Failed authorization or trusted-read unavailable becomes a Human Support
/// recommendation. Serious/payment/emergency becomes Manager/Admin.
/// Critical/legal/fraud becomes Owner.
///
/// This class never performs the transfer and never mutates Tour data.
class AgentCallTourBookingStatusOrchestrator {
  const AgentCallTourBookingStatusOrchestrator({
    required this.readGateway,
    this.authorizationService =
        const AgentCallTourBookingStatusAuthorizationService(),
    this.escalationRouter = const AgentCallEscalationRouter(),
  });

  final AgentCallTourBookingStatusReadGateway readGateway;
  final AgentCallTourBookingStatusAuthorizationService authorizationService;
  final AgentCallEscalationRouter escalationRouter;

  Future<AgentCallTourBookingStatusOrchestrationResult> orchestrate({
    required AgentMasterSettings settings,
    required AgentRole role,
    required AgentCallTourBookingStatusRequest request,
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
        reason: 'HIGH_RISK_CONCERN_ROUTED_BEFORE_TOUR_READ',
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
        reason: 'TOUR_STATUS_AUTHORIZATION_BLOCKED',
        now: normalizedNow,
      );
    }

    final AgentCallTourBookingStatusReadEvidence evidence = await readGateway
        .readAuthorizedTourBookingStatus(request: request, now: normalizedNow);

    if (!evidence.isAuthorized || evidence.snapshot == null) {
      return _unresolved(
        reason: 'TRUSTED_TOUR_STATUS_UNAVAILABLE',
        now: normalizedNow,
      );
    }

    final AgentCallTourBookingStatusSnapshot snapshot = evidence.snapshot!;

    snapshot.validate();

    final result = AgentCallTourBookingStatusOrchestrationResult(
      status: AgentCallTourBookingStatusOrchestrationStatus.answerReady,
      escalationLevel: AgentCallEscalationLevel.ai,
      reason: 'AUTHORIZED_TRUSTED_TOUR_STATUS_READY',
      processedAt: normalizedNow,
      snapshot: snapshot,
    );

    result.validate();
    return result;
  }

  AgentCallTourBookingStatusOrchestrationResult _unresolved({
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

  AgentCallTourBookingStatusOrchestrationResult _escalation({
    required String level,
    required String reason,
    required DateTime now,
  }) {
    final result = AgentCallTourBookingStatusOrchestrationResult(
      status:
          AgentCallTourBookingStatusOrchestrationStatus.escalationRecommended,
      escalationLevel: level,
      reason: reason,
      processedAt: now,
    );

    result.validate();
    return result;
  }

  bool get highRiskRoutedBeforeTourRead => true;
  bool get authorizationBeforeRead => true;
  bool get trustedGatewayOnly => true;
  bool get privacyMinimizedSnapshotOnly => true;
  bool get escalationRecommendationOnly => true;

  bool get executesActualTransfer => false;
  bool get invokesGenericTourConnectorDirectly => false;
  bool get invokesTourBookingService => false;
  bool get invokesFirestore => false;
  bool get invokesFirebaseAuth => false;
  bool get invokesHttp => false;
  bool get invokesCloudFunctions => false;
  bool get invokesTelephonyProvider => false;
  bool get sendsSms => false;

  bool get createsTourBooking => false;
  bool get writesTourBooking => false;
  bool get cancelsTourBooking => false;
  bool get changesTourPrice => false;
  bool get changesTourPayment => false;
  bool get changesTourAssignment => false;
}
