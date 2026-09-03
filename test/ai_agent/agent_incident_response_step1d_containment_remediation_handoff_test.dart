import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_guardian_security_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_incident_response_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_incident_response_human_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_incident_response_plan_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_authoritative_handoff.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_human_assignment.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_record.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_response_plan.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_triage_decision.dart';
import 'package:swat_ride/ai_agent/services/agent_security_incident_response_plan_service.dart';

void main() {
  const AgentSecurityIncidentResponsePlanService service =
      AgentSecurityIncidentResponsePlanService();

  AgentSecurityIncidentRecord incident({
    String severity = AgentGuardianSeverity.medium,
  }) {
    return AgentSecurityIncidentRecord(
      incidentId: 'incident_step1d_001',
      source: AgentSecurityIncidentSource.guardian,
      sourceReferenceId: 'guardian_corr_step1d_001',
      pseudonymousSubjectRef: 'subject_hash_step1d_001',
      status: AgentSecurityIncidentStatus.open,
      severity: severity,
      evidenceConfidence: AgentGuardianEvidenceConfidence.high,
      createdAt: DateTime.utc(2026, 8, 19, 11),
      updatedAt: DateTime.utc(2026, 8, 19, 11),
      evidenceReferenceCodes: const <String>['guardian_corr_step1d_001'],
    );
  }

  AgentSecurityIncidentTriageDecision triage({
    String severity = AgentGuardianSeverity.medium,
    bool humanReviewRequired = false,
    bool failClosedRecommended = false,
  }) {
    return AgentSecurityIncidentTriageDecision(
      status: humanReviewRequired
          ? AgentSecurityIncidentTriageStatus.humanReviewRequired
          : AgentSecurityIncidentTriageStatus.readyForResponsePlanning,
      incidentId: 'incident_step1d_001',
      sourceReferenceId: 'guardian_corr_step1d_001',
      inheritedGuardianSeverity: severity,
      incidentSeverity: severity,
      evidenceConfidence: AgentGuardianEvidenceConfidence.high,
      humanReviewRequired: humanReviewRequired,
      responderAssignmentRequired: humanReviewRequired,
      failClosedRecommended: failClosedRecommended,
      authoritativeChecksStillRequired: true,
      responsePlanningAllowed: true,
      generatedAt: DateTime.utc(2026, 8, 19, 11, 1),
      reasonCodes: const <String>[
        AgentSecurityIncidentReason.guardianSeverityInherited,
        AgentSecurityIncidentReason.authoritativeChecksStillRequired,
        AgentSecurityIncidentReason.responsePlanningOnly,
      ],
    );
  }

  AgentSecurityIncidentHumanAssignment acknowledgedAssignment() {
    return AgentSecurityIncidentHumanAssignment(
      assignmentId: 'assignment_step1d_001',
      incidentId: 'incident_step1d_001',
      responderRef: 'responder_hash_step1d_001',
      status: AgentSecurityIncidentAssignmentStatus.acknowledged,
      assignedAt: DateTime.utc(2026, 8, 19, 11, 2),
      acknowledgedAt: DateTime.utc(2026, 8, 19, 11, 3),
      reasonCodes: const <String>[
        AgentSecurityIncidentHumanReason.humanAssignmentRequired,
        AgentSecurityIncidentHumanReason.responderReferencePseudonymous,
        AgentSecurityIncidentHumanReason.acknowledgementExplicit,
        AgentSecurityIncidentHumanReason.noAuthorityGranted,
      ],
    );
  }

  group('Phase 54 Step 1D response recommendation + handoff', () {
    test('MEDIUM incident builds recommendation-only plan', () {
      final AgentSecurityIncidentResponsePlan plan = service.buildPlan(
        planId: 'plan_medium_001',
        incident: incident(),
        triage: triage(),
        generatedAt: DateTime.utc(2026, 8, 19, 11, 4),
      );

      expect(
        plan.status,
        AgentSecurityIncidentResponsePlanStatus.readyForAuthoritativeReview,
      );
      expect(plan.recommendationOnly, isTrue);
      expect(plan.authoritativeChecksStillRequired, isTrue);
      expect(plan.executesContainment, isFalse);
    });

    test('HIGH incident without human acknowledgement is blocked', () {
      final AgentSecurityIncidentResponsePlan plan = service.buildPlan(
        planId: 'plan_high_blocked',
        incident: incident(severity: AgentGuardianSeverity.high),
        triage: triage(
          severity: AgentGuardianSeverity.high,
          humanReviewRequired: true,
        ),
        generatedAt: DateTime.utc(2026, 8, 19, 11, 4),
      );

      expect(plan.blocked, isTrue);
      expect(plan.failClosedRecommended, isTrue);
      expect(plan.humanReviewVerified, isFalse);
    });

    test('HIGH incident with acknowledged responder can prepare plan', () {
      final AgentSecurityIncidentResponsePlan plan = service.buildPlan(
        planId: 'plan_high_ready',
        incident: incident(severity: AgentGuardianSeverity.high),
        triage: triage(
          severity: AgentGuardianSeverity.high,
          humanReviewRequired: true,
        ),
        humanAssignment: acknowledgedAssignment(),
        generatedAt: DateTime.utc(2026, 8, 19, 11, 4),
      );

      expect(plan.blocked, isFalse);
      expect(plan.humanReviewVerified, isTrue);
      expect(
        plan.recommendationTypes,
        contains(
          AgentSecurityIncidentRecommendationType.requireHumanSecurityReview,
        ),
      );
    });

    test('CRITICAL plan requests emergency security review', () {
      final AgentSecurityIncidentResponsePlan plan = service.buildPlan(
        planId: 'plan_critical',
        incident: incident(severity: AgentGuardianSeverity.critical),
        triage: triage(
          severity: AgentGuardianSeverity.critical,
          humanReviewRequired: true,
          failClosedRecommended: true,
        ),
        humanAssignment: acknowledgedAssignment(),
        generatedAt: DateTime.utc(2026, 8, 19, 11, 4),
      );

      expect(plan.failClosedRecommended, isTrue);
      expect(
        plan.recommendationTypes,
        contains(
          AgentSecurityIncidentRecommendationType
              .requireEmergencySecurityReview,
        ),
      );
    });

    test('plan rejects incident/triage binding mismatch', () {
      final AgentSecurityIncidentTriageDecision mismatched =
          AgentSecurityIncidentTriageDecision(
            status: AgentSecurityIncidentTriageStatus.readyForResponsePlanning,
            incidentId: 'incident_other',
            sourceReferenceId: 'guardian_corr_other',
            inheritedGuardianSeverity: AgentGuardianSeverity.medium,
            incidentSeverity: AgentGuardianSeverity.medium,
            evidenceConfidence: AgentGuardianEvidenceConfidence.high,
            humanReviewRequired: false,
            responderAssignmentRequired: false,
            failClosedRecommended: false,
            authoritativeChecksStillRequired: true,
            responsePlanningAllowed: true,
            generatedAt: DateTime.utc(2026, 8, 19, 11, 1),
            reasonCodes: const <String>[
              AgentSecurityIncidentReason.guardianSeverityInherited,
              AgentSecurityIncidentReason.authoritativeChecksStillRequired,
              AgentSecurityIncidentReason.responsePlanningOnly,
            ],
          );

      expect(
        () => service.buildPlan(
          planId: 'plan_mismatch',
          incident: incident(),
          triage: mismatched,
          generatedAt: DateTime.utc(2026, 8, 19, 11, 4),
        ),
        throwsA(isA<AgentSecurityIncidentResponsePlanServiceException>()),
      );
    });

    test('prepared MEDIUM handoff requires Permission + Runtime', () {
      final AgentSecurityIncidentResponsePlan plan = service.buildPlan(
        planId: 'plan_handoff_medium',
        incident: incident(),
        triage: triage(),
        generatedAt: DateTime.utc(2026, 8, 19, 11, 4),
      );

      final AgentSecurityIncidentAuthoritativeHandoff handoff = service
          .prepareHandoff(
            handoffId: 'handoff_medium_001',
            plan: plan,
            preparedAt: DateTime.utc(2026, 8, 19, 11, 5),
          );

      expect(
        handoff.status,
        AgentSecurityIncidentAuthoritativeHandoffStatus.prepared,
      );
      expect(handoff.permissionEngineRequired, isTrue);
      expect(handoff.runtimeGateRequired, isTrue);
      expect(handoff.authoritativeChecksStillPending, isTrue);
    });

    test('HIGH handoff requires Approval + Human review', () {
      final AgentSecurityIncidentResponsePlan plan = service.buildPlan(
        planId: 'plan_handoff_high',
        incident: incident(severity: AgentGuardianSeverity.high),
        triage: triage(
          severity: AgentGuardianSeverity.high,
          humanReviewRequired: true,
        ),
        humanAssignment: acknowledgedAssignment(),
        generatedAt: DateTime.utc(2026, 8, 19, 11, 4),
      );

      final AgentSecurityIncidentAuthoritativeHandoff handoff = service
          .prepareHandoff(
            handoffId: 'handoff_high_001',
            plan: plan,
            preparedAt: DateTime.utc(2026, 8, 19, 11, 5),
          );

      expect(handoff.approvalEngineRequired, isTrue);
      expect(handoff.humanSecurityReviewRequired, isTrue);
      expect(handoff.emergencySecurityReviewRequired, isFalse);
    });

    test('CRITICAL handoff requests emergency review but invokes nothing', () {
      final AgentSecurityIncidentResponsePlan plan = service.buildPlan(
        planId: 'plan_handoff_critical',
        incident: incident(severity: AgentGuardianSeverity.critical),
        triage: triage(
          severity: AgentGuardianSeverity.critical,
          humanReviewRequired: true,
          failClosedRecommended: true,
        ),
        humanAssignment: acknowledgedAssignment(),
        generatedAt: DateTime.utc(2026, 8, 19, 11, 4),
      );

      final AgentSecurityIncidentAuthoritativeHandoff handoff = service
          .prepareHandoff(
            handoffId: 'handoff_critical_001',
            plan: plan,
            preparedAt: DateTime.utc(2026, 8, 19, 11, 5),
          );

      expect(handoff.emergencySecurityReviewRequired, isTrue);
      expect(handoff.invokesEmergencyStop, isFalse);
      expect(handoff.executesContainment, isFalse);
    });

    test('blocked plan produces BLOCKED handoff with checks pending', () {
      final AgentSecurityIncidentResponsePlan plan = service.buildPlan(
        planId: 'plan_blocked_handoff',
        incident: incident(severity: AgentGuardianSeverity.high),
        triage: triage(
          severity: AgentGuardianSeverity.high,
          humanReviewRequired: true,
        ),
        generatedAt: DateTime.utc(2026, 8, 19, 11, 4),
      );

      final AgentSecurityIncidentAuthoritativeHandoff handoff = service
          .prepareHandoff(
            handoffId: 'handoff_blocked_001',
            plan: plan,
            preparedAt: DateTime.utc(2026, 8, 19, 11, 5),
          );

      expect(
        handoff.status,
        AgentSecurityIncidentAuthoritativeHandoffStatus.blocked,
      );
      expect(handoff.authoritativeChecksStillPending, isTrue);
      expect(handoff.failClosedRecommended, isTrue);
    });

    test('plan safe map contains recommendation only / no execution', () {
      final Map<String, dynamic> map = service
          .buildPlan(
            planId: 'plan_safe_map',
            incident: incident(),
            triage: triage(),
            generatedAt: DateTime.utc(2026, 8, 19, 11, 4),
          )
          .toSafeMap();

      expect(map['recommendationOnly'], isTrue);
      expect(map['grantsAuthority'], isFalse);
      expect(map['grantsPermission'], isFalse);
      expect(map['executesContainment'], isFalse);
      expect(map['executesRemediation'], isFalse);
      expect(map['executesRecoveryAction'], isFalse);
      expect(map['persistsPlan'], isFalse);
      expect(map['rawSensitiveEvidenceIncluded'], isFalse);
    });

    test('handoff never marks Permission/Approval/Runtime complete', () {
      final AgentSecurityIncidentResponsePlan plan = service.buildPlan(
        planId: 'plan_pending_checks',
        incident: incident(),
        triage: triage(),
        generatedAt: DateTime.utc(2026, 8, 19, 11, 4),
      );

      final AgentSecurityIncidentAuthoritativeHandoff handoff = service
          .prepareHandoff(
            handoffId: 'handoff_pending_checks',
            plan: plan,
            preparedAt: DateTime.utc(2026, 8, 19, 11, 5),
          );

      expect(handoff.marksPermissionApproved, isFalse);
      expect(handoff.marksApprovalConsumed, isFalse);
      expect(handoff.marksRuntimeAllowed, isFalse);
      expect(handoff.authoritativeChecksStillPending, isTrue);
    });

    test('service cannot execute response or bypass authority', () {
      expect(service.recommendationAndHandoffOnly, isTrue);
      expect(service.executesContainment, isFalse);
      expect(service.executesRemediation, isFalse);
      expect(service.executesRecoveryAction, isFalse);
      expect(service.invokesPermissionEngine, isFalse);
      expect(service.invokesApprovalEngine, isFalse);
      expect(service.invokesRuntimeGate, isFalse);
      expect(service.invokesEmergencyStop, isFalse);
      expect(service.bypassesAuthoritativeControls, isFalse);
      expect(service.consumesApproval, isFalse);
      expect(service.grantsPermission, isFalse);
      expect(service.marksRuntimeAllowed, isFalse);
      expect(service.invokesProvider, isFalse);
      expect(service.invokesTargetAgent, isFalse);
      expect(service.writesBusinessData, isFalse);
      expect(service.persistsPlan, isFalse);
      expect(service.persistsHandoff, isFalse);
      expect(service.autoClosesIncident, isFalse);
      expect(service.implementsPhase63PrivacyUi, isFalse);
    });
  });
}
