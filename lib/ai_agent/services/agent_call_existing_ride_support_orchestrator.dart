import '../constants/agent_call_constants.dart';
import '../models/agent_call_existing_ride_support_contract.dart';
import '../models/agent_call_existing_ride_support_orchestration.dart';
import '../models/agent_master_settings.dart';
import '../models/agent_role.dart';
import 'agent_call_escalation_router.dart';
import 'agent_call_existing_ride_read_authorization_service.dart';
import 'agent_call_existing_ride_read_support_service.dart';

/// Phase 49 Stage 2 orchestrator.
///
/// Security order for normal existing-Ride support:
/// 1. validate concern/request;
/// 2. central Permission Engine + Runtime Gate authorization;
/// 3. trusted existing-Ride gateway read;
/// 4. answer only from a privacy-minimized trusted snapshot.
///
/// High-risk/support concerns may be routed for escalation without exposing
/// Ride data. Escalation here is a recommendation/target only. No transfer
/// action is executed and no transfer permission is implied.
class AgentCallExistingRideSupportOrchestrator {
  const AgentCallExistingRideSupportOrchestrator({
    required this.readSupportService,
    this.authorizationService =
        const AgentCallExistingRideReadAuthorizationService(),
    this.escalationRouter = const AgentCallEscalationRouter(),
  });

  final AgentCallExistingRideReadSupportService readSupportService;
  final AgentCallExistingRideReadAuthorizationService authorizationService;
  final AgentCallEscalationRouter escalationRouter;

  Future<AgentCallExistingRideSupportOrchestrationResult> handle({
    required AgentMasterSettings settings,
    required AgentRole role,
    required AgentCallExistingRideSupportRequest request,
    required DateTime now,
    AgentCallExistingRideConcern concern = const AgentCallExistingRideConcern(),
  }) async {
    try {
      concern.validate();
    } catch (_) {
      return _blocked(code: 'INVALID_EXISTING_RIDE_SUPPORT_CONCERN', now: now);
    }

    // Safety/support triage can recommend escalation, but never grants Ride
    // read authority. We deliberately avoid touching Ride data in this branch.
    if (concern.needsImmediateEscalation) {
      final String target = escalationRouter.route(
        intent: concern.routerIntent,
        aiCanSolve: false,
        serious: concern.serious,
        critical: concern.critical,
      );

      return AgentCallExistingRideSupportOrchestrationResult(
        status: AgentCallExistingRideOrchestrationStatus.escalated,
        code: 'EXISTING_RIDE_CONCERN_ESCALATION_RECOMMENDED',
        authorizationAllowed: false,
        readAttempted: false,
        escalationLevel: target,
        escalationRecommended: target != AgentCallEscalationLevel.ai,
        createdAt: now.toUtc(),
      );
    }

    final authorization = authorizationService.authorize(
      settings: settings,
      role: role,
      request: request,
    );

    if (!authorization.isAllowed) {
      // Do not read an arbitrary Ride after a failed binding/security decision.
      // Human support may help the caller establish a valid trusted binding,
      // but this method still exposes no Ride snapshot.
      final String target = escalationRouter.route(
        intent: AgentCallIntent.rideStatus,
        aiCanSolve: false,
        serious: false,
        critical: false,
      );

      return AgentCallExistingRideSupportOrchestrationResult(
        status: AgentCallExistingRideOrchestrationStatus.escalated,
        code: 'EXISTING_RIDE_AUTHORIZATION_BLOCKED_ESCALATE',
        authorizationAllowed: false,
        readAttempted: false,
        escalationLevel: target,
        escalationRecommended: target != AgentCallEscalationLevel.ai,
        createdAt: now.toUtc(),
      );
    }

    final AgentCallExistingRideSupportResult readResult =
        await readSupportService.read(request: request, now: now);

    if (!readResult.isReady) {
      final String target = escalationRouter.route(
        intent: AgentCallIntent.rideStatus,
        aiCanSolve: false,
        serious: false,
        critical: false,
      );

      return AgentCallExistingRideSupportOrchestrationResult(
        status: AgentCallExistingRideOrchestrationStatus.escalated,
        code: 'EXISTING_RIDE_READ_UNAVAILABLE_ESCALATE',
        authorizationAllowed: true,
        readAttempted: true,
        escalationLevel: target,
        escalationRecommended: target != AgentCallEscalationLevel.ai,
        createdAt: now.toUtc(),
      );
    }

    return AgentCallExistingRideSupportOrchestrationResult(
      status: AgentCallExistingRideOrchestrationStatus.answered,
      code: 'EXISTING_RIDE_TRUSTED_ANSWER_READY',
      authorizationAllowed: true,
      readAttempted: true,
      escalationLevel: AgentCallEscalationLevel.ai,
      escalationRecommended: false,
      createdAt: now.toUtc(),
      supportResult: readResult,
    );
  }

  AgentCallExistingRideSupportOrchestrationResult _blocked({
    required String code,
    required DateTime now,
  }) {
    return AgentCallExistingRideSupportOrchestrationResult(
      status: AgentCallExistingRideOrchestrationStatus.blocked,
      code: code,
      authorizationAllowed: false,
      readAttempted: false,
      escalationLevel: AgentCallEscalationLevel.ai,
      escalationRecommended: false,
      createdAt: now.toUtc(),
    );
  }

  bool get escalationIsRecommendationOnly => true;
  bool get executesTransferAction => false;
  bool get requiresTransferPermissionForRecommendation => false;

  bool get concernCanGrantRideReadAuthority => false;
  bool get concernCanGrantRideWriteAuthority => false;
  bool get transcriptCanGrantAuthority => false;
  bool get voiceCanGrantAuthority => false;
  bool get rawPhoneCanGrantAuthority => false;

  bool get writesRide => false;
  bool get cancelsRide => false;
  bool get reassignsDriver => false;
  bool get changesPayment => false;
  bool get issuesRefund => false;
  bool get changesFare => false;

  bool get invokesFirestoreDirectly => false;
  bool get invokesFirebaseAuthDirectly => false;
  bool get invokesRideServiceDirectly => false;
  bool get invokesTelephonyProvider => false;
  bool get sendsSms => false;
}
