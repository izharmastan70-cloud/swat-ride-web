import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_incident_response_adversarial_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_incident_response_closure_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_incident_response_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_incident_response_human_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_incident_response_plan_constants.dart';
import 'package:swat_ride/ai_agent/services/agent_security_incident_adversarial_verification_service.dart';
import 'package:swat_ride/ai_agent/services/agent_security_incident_assignment_timeline_service.dart';
import 'package:swat_ride/ai_agent/services/agent_security_incident_closure_service.dart';
import 'package:swat_ride/ai_agent/services/agent_security_incident_response_plan_service.dart';
import 'package:swat_ride/ai_agent/services/agent_security_incident_triage_service.dart';

void main() {
  const AgentSecurityIncidentTriageService triageService =
      AgentSecurityIncidentTriageService();

  const AgentSecurityIncidentAssignmentTimelineService assignmentService =
      AgentSecurityIncidentAssignmentTimelineService();

  const AgentSecurityIncidentResponsePlanService responsePlanService =
      AgentSecurityIncidentResponsePlanService();

  const AgentSecurityIncidentClosureService closureService =
      AgentSecurityIncidentClosureService();

  const AgentSecurityIncidentAdversarialVerificationService adversarialService =
      AgentSecurityIncidentAdversarialVerificationService();

  group('Phase 54 Step 1G final incident-response readiness', () {
    test('incident lifecycle keeps CLOSED terminal', () {
      expect(
        triageService.canTransition(
          currentStatus: AgentSecurityIncidentStatus.resolved,
          nextStatus: AgentSecurityIncidentStatus.closed,
        ),
        isTrue,
      );

      expect(
        triageService.canTransition(
          currentStatus: AgentSecurityIncidentStatus.closed,
          nextStatus: AgentSecurityIncidentStatus.open,
        ),
        isFalse,
      );
    });

    test('human assignment remains explicit and non-automatic', () {
      expect(
        AgentSecurityIncidentAssignmentStatus.values,
        contains(
          AgentSecurityIncidentAssignmentStatus.assignedAwaitingAcknowledgement,
        ),
      );
      expect(
        AgentSecurityIncidentAssignmentStatus.values,
        contains(AgentSecurityIncidentAssignmentStatus.acknowledged),
      );
      expect(assignmentService.humanAssignmentAndTimelineOnly, isTrue);
      expect(assignmentService.autoAssignsResponder, isFalse);
      expect(assignmentService.sendsResponderNotification, isFalse);
    });

    test('human assignment service grants no authority', () {
      expect(assignmentService.grantsResponderAuthority, isFalse);
      expect(assignmentService.invokesPermissionEngine, isFalse);
      expect(assignmentService.invokesApprovalEngine, isFalse);
      expect(assignmentService.invokesRuntimeGate, isFalse);
      expect(assignmentService.invokesEmergencyStop, isFalse);
      expect(assignmentService.bypassesAuthoritativeControls, isFalse);
    });

    test('response planning is recommendation and handoff only', () {
      expect(responsePlanService.recommendationAndHandoffOnly, isTrue);
      expect(responsePlanService.executesContainment, isFalse);
      expect(responsePlanService.executesRemediation, isFalse);
      expect(responsePlanService.executesRecoveryAction, isFalse);
      expect(responsePlanService.invokesProvider, isFalse);
      expect(responsePlanService.writesBusinessData, isFalse);
    });

    test('response plan cannot complete authoritative controls', () {
      expect(responsePlanService.invokesPermissionEngine, isFalse);
      expect(responsePlanService.invokesApprovalEngine, isFalse);
      expect(responsePlanService.invokesRuntimeGate, isFalse);
      expect(responsePlanService.invokesEmergencyStop, isFalse);
      expect(responsePlanService.bypassesAuthoritativeControls, isFalse);
      expect(responsePlanService.consumesApproval, isFalse);
      expect(responsePlanService.grantsPermission, isFalse);
      expect(responsePlanService.marksRuntimeAllowed, isFalse);
    });

    test('closure remains recommendation-only with external authority', () {
      expect(closureService.closureAssessmentOnly, isTrue);
      expect(closureService.finalClosureAuthorityExternal, isTrue);
      expect(closureService.autoClosesIncident, isFalse);
      expect(closureService.marksIncidentResolved, isFalse);
      expect(closureService.marksIncidentClosed, isFalse);
    });

    test('closure cannot execute response or bypass gates', () {
      expect(closureService.invokesPermissionEngine, isFalse);
      expect(closureService.invokesApprovalEngine, isFalse);
      expect(closureService.invokesRuntimeGate, isFalse);
      expect(closureService.invokesEmergencyStop, isFalse);
      expect(closureService.bypassesAuthoritativeControls, isFalse);
      expect(closureService.executesContainment, isFalse);
      expect(closureService.executesRemediation, isFalse);
      expect(closureService.executesRecoveryAction, isFalse);
    });

    test('adversarial coverage remains locked to 14 scenarios', () {
      expect(AgentSecurityIncidentAdversarialScenario.values.length, 14);
      expect(
        AgentSecurityIncidentAdversarialVerificationService
            .lockedScenarioOutcomes
            .length,
        14,
      );
    });

    test('all locked adversarial scenarios pass expected outcomes', () {
      final results = adversarialService.verifyLockedCoverage(
        verifiedAt: DateTime.utc(2026, 8, 19, 13),
      );

      expect(results.length, 14);
      expect(results.every((result) => result.passed), isTrue);
    });

    test('idempotency and replay protections remain fail-safe', () {
      expect(adversarialService.duplicateExecutionAllowed, isFalse);
      expect(adversarialService.collisionFailsClosed, isTrue);
      expect(adversarialService.staleReplayAccepted, isFalse);
      expect(adversarialService.crossIncidentBindingAccepted, isFalse);
      expect(
        AgentSecurityIncidentAdversarialVerificationService.maxReplayAge,
        const Duration(minutes: 30),
      );
    });

    test('failure isolation protects core app and other channels', () {
      expect(adversarialService.observerFailureBreaksCoreApp, isFalse);
      expect(adversarialService.observerFailureBreaksOtherChannels, isFalse);
    });

    test('incident-response layer has no direct business authority', () {
      expect(assignmentService.writesBusinessData, isFalse);
      expect(responsePlanService.writesBusinessData, isFalse);
      expect(closureService.writesBusinessData, isFalse);
      expect(adversarialService.writesBusinessData, isFalse);

      expect(assignmentService.invokesProvider, isFalse);
      expect(responsePlanService.invokesProvider, isFalse);
      expect(closureService.invokesProvider, isFalse);
      expect(adversarialService.invokesProvider, isFalse);
    });

    test('incident-response layer performs no client persistence', () {
      expect(assignmentService.persistsAssignment, isFalse);
      expect(assignmentService.persistsTimeline, isFalse);
      expect(responsePlanService.persistsPlan, isFalse);
      expect(responsePlanService.persistsHandoff, isFalse);
      expect(closureService.persistsEvidence, isFalse);
      expect(closureService.persistsAssessment, isFalse);
      expect(adversarialService.persistsIdempotencyState, isFalse);
      expect(adversarialService.persistsAdversarialResults, isFalse);
    });

    test('Phase 63 privacy UI remains outside Phase 54', () {
      expect(assignmentService.implementsPhase63PrivacyUi, isFalse);
      expect(responsePlanService.implementsPhase63PrivacyUi, isFalse);
      expect(closureService.implementsPhase63PrivacyUi, isFalse);
      expect(adversarialService.implementsPhase63PrivacyUi, isFalse);
    });

    test('Phase 54 final readiness is foundation-only', () {
      expect(
        AgentSecurityIncidentClosureAssessmentStatus.values,
        contains(
          AgentSecurityIncidentClosureAssessmentStatus
              .readyForAuthoritativeClosureReview,
        ),
      );
      expect(
        AgentSecurityIncidentResponsePlanStatus.values,
        contains(
          AgentSecurityIncidentResponsePlanStatus.readyForAuthoritativeReview,
        ),
      );

      expect(responsePlanService.autoClosesIncident, isFalse);
      expect(closureService.autoClosesIncident, isFalse);
      expect(adversarialService.closesIncident, isFalse);
    });
  });
}
