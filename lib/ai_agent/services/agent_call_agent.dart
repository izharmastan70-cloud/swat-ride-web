import '../constants/agent_call_constants.dart';
import '../models/agent_call_escalation_summary.dart';
import '../models/agent_call_ride_booking_draft.dart';
import '../models/agent_call_session.dart';
import 'agent_call_escalation_router.dart';
import 'agent_call_privacy_service.dart';
import 'agent_call_session_service.dart';

// =========================================================
// AI AGENT — CALL AGENT
// =========================================================
//
// Phase 17 = TEST MODE FOUNDATION.
//
// No real phone number.
// No SIP/PSTN/WebRTC telephony provider.
// No real Ride/Food/Hotel/Tour write.
// No call recording.
//
// The purpose is to make conversation state, ride-booking draft,
// privacy, confirmation and escalation rules ready before integration.

class AgentCallAgent {
  final AgentCallPrivacyService privacy;
  final AgentCallEscalationRouter escalationRouter;
  final AgentCallSessionService sessionService;

  AgentCallAgent({
    AgentCallPrivacyService? privacy,
    AgentCallEscalationRouter? escalationRouter,
    AgentCallSessionService? sessionService,
  })  : privacy = privacy ?? const AgentCallPrivacyService(),
        escalationRouter =
            escalationRouter ?? const AgentCallEscalationRouter(),
        sessionService = sessionService ?? AgentCallSessionService();

  Future<AgentCallSession> startTestSession({
    required String callerName,
    required String callerPhone,
    String intent = AgentCallIntent.unknown,
  }) async {
    final DateTime now = DateTime.now();

    final AgentCallSession session = AgentCallSession(
      sessionId: 'call_${now.microsecondsSinceEpoch}',
      mode: AgentCallMode.test,
      callerName: callerName.trim(),
      callerPhoneMasked: privacy.maskPhone(callerPhone),
      intent: intent,
      module: 'call',
      referenceId: '',
      status: AgentCallSessionStatus.active,
      escalationLevel: AgentCallEscalationLevel.ai,
      recordingEnabled: false,
      createdAt: now,
      updatedAt: now,
    );

    await sessionService.save(session);
    return session;
  }

  AgentCallRideBookingDraft buildRideDraft({
    required String customerName,
    required String phone,
    required String pickup,
    required String destination,
    required String vehicleType,
    required bool customerConfirmed,
  }) {
    final String combined = '$customerName $pickup $destination $vehicleType';

    if (privacy.containsForbiddenSecret(combined)) {
      throw StateError(
        'Call input appears to contain forbidden secret data.',
      );
    }

    return AgentCallRideBookingDraft(
      customerName: customerName.trim(),
      contactPhoneMasked: privacy.maskPhone(phone),
      pickup: pickup.trim(),
      destination: destination.trim(),
      vehicleType: vehicleType.trim(),
      customerConfirmed: customerConfirmed,
    );
  }

  Future<String> escalate({
    required AgentCallSession session,
    required String problem,
    required String alreadyChecked,
    required bool aiCanSolve,
    required bool serious,
    required bool critical,
  }) async {
    final String target = escalationRouter.route(
      intent: session.intent,
      aiCanSolve: aiCanSolve,
      serious: serious,
      critical: critical,
    );

    if (target == AgentCallEscalationLevel.ai) {
      return target;
    }

    final AgentCallEscalationSummary summary =
        AgentCallEscalationSummary(
      callerName: session.callerName,
      callerPhoneMasked: session.callerPhoneMasked,
      module: session.module,
      referenceId: session.referenceId,
      problem: problem,
      alreadyChecked: alreadyChecked,
      escalationReason:
          'AI cannot safely/fully resolve this call at current authority.',
      targetLevel: target,
    );

    await sessionService.markEscalated(
      sessionId: session.sessionId,
      level: target,
      summary: summary.toMap(),
    );

    return target;
  }
}
