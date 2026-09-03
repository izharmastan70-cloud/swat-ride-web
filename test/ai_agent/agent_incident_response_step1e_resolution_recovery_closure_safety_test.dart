import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_guardian_security_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_incident_response_closure_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_incident_response_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_incident_response_plan_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_authoritative_handoff.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_closure_assessment.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_record.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_recovery_evidence.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_response_plan.dart';
import 'package:swat_ride/ai_agent/services/agent_security_incident_closure_service.dart';

void main() {
  const AgentSecurityIncidentClosureService service =
      AgentSecurityIncidentClosureService();

  AgentSecurityIncidentRecord resolvedIncident({
    String status = AgentSecurityIncidentStatus.resolved,
    String severity = AgentGuardianSeverity.medium,
  }) {
    return AgentSecurityIncidentRecord(
      incidentId: 'incident_step1e_001',
      source: AgentSecurityIncidentSource.guardian,
      sourceReferenceId: 'guardian_corr_step1e_001',
      pseudonymousSubjectRef: 'subject_hash_step1e_001',
      status: status,
      severity: severity,
      evidenceConfidence: AgentGuardianEvidenceConfidence.high,
      createdAt: DateTime.utc(2026, 8, 19, 11, 30),
      updatedAt: DateTime.utc(2026, 8, 19, 11, 50),
      evidenceReferenceCodes: const <String>['guardian_corr_step1e_001'],
      resolvedAt: status == AgentSecurityIncidentStatus.resolved
          ? DateTime.utc(2026, 8, 19, 11, 50)
          : null,
    );
  }

  AgentSecurityIncidentResponsePlan plan({
    String severity = AgentGuardianSeverity.medium,
  }) {
    return AgentSecurityIncidentResponsePlan(
      status:
          AgentSecurityIncidentResponsePlanStatus.readyForAuthoritativeReview,
      planId: 'plan_step1e_001',
      incidentId: 'incident_step1e_001',
      severity: severity,
      failClosedRecommended: severity == AgentGuardianSeverity.critical,
      humanReviewVerified:
          severity == AgentGuardianSeverity.high ||
          severity == AgentGuardianSeverity.critical,
      authoritativeChecksStillRequired: true,
      generatedAt: DateTime.utc(2026, 8, 19, 11, 40),
      recommendationTypes: const <String>[
        AgentSecurityIncidentRecommendationType.preserveSafeEvidence,
        AgentSecurityIncidentRecommendationType.requirePermissionRecheck,
        AgentSecurityIncidentRecommendationType.requireRuntimeGateRecheck,
        AgentSecurityIncidentRecommendationType.monitorRecoveryBeforeClosure,
      ],
      reasonCodes: const <String>[
        AgentSecurityIncidentResponseReason.incidentTriageBound,
        AgentSecurityIncidentResponseReason.authoritativeChecksRequired,
        AgentSecurityIncidentResponseReason.recommendationOnly,
        AgentSecurityIncidentResponseReason.noExecutionAuthority,
      ],
    );
  }

  AgentSecurityIncidentAuthoritativeHandoff handoff({
    required AgentSecurityIncidentResponsePlan responsePlan,
    bool approvalRequired = false,
    bool emergencyRequired = false,
    bool humanRequired = false,
    String status = AgentSecurityIncidentAuthoritativeHandoffStatus.prepared,
  }) {
    return AgentSecurityIncidentAuthoritativeHandoff(
      status: status,
      handoffId: 'handoff_step1e_001',
      plan: responsePlan,
      permissionEngineRequired: true,
      approvalEngineRequired: approvalRequired,
      runtimeGateRequired: true,
      emergencySecurityReviewRequired: emergencyRequired,
      humanSecurityReviewRequired: humanRequired,
      failClosedRecommended: responsePlan.failClosedRecommended,
      authoritativeChecksStillPending: true,
      preparedAt: DateTime.utc(2026, 8, 19, 11, 41),
    );
  }

  AgentSecurityIncidentRecoveryEvidence evidence({
    bool recoveryStable = true,
    bool containmentVerified = true,
    bool remediationVerified = true,
    bool permissionVerified = true,
    bool approvalVerified = true,
    bool runtimeVerified = true,
    bool emergencyVerified = true,
    bool humanVerified = true,
  }) {
    return AgentSecurityIncidentRecoveryEvidence(
      evidenceId: 'recovery_step1e_001',
      incidentId: 'incident_step1e_001',
      source: AgentSecurityIncidentRecoveryEvidenceSource.trustedSystem,
      observedAt: DateTime.utc(2026, 8, 19, 11, 55),
      recoveryStable: recoveryStable,
      containmentVerified: containmentVerified,
      remediationVerified: remediationVerified,
      permissionReviewVerified: permissionVerified,
      approvalReviewVerified: approvalVerified,
      runtimeReviewVerified: runtimeVerified,
      emergencyReviewVerified: emergencyVerified,
      humanSecurityReviewVerified: humanVerified,
      evidenceReferenceCodes: const <String>[
        'recovery_ref_step1e_001',
        'verification_ref_step1e_001',
      ],
    );
  }

  AgentSecurityIncidentClosureAssessment assessMedium({
    AgentSecurityIncidentRecord? incident,
    AgentSecurityIncidentRecoveryEvidence? recoveryEvidence,
  }) {
    final AgentSecurityIncidentResponsePlan responsePlan = plan();

    return service.assessClosure(
      assessmentId: 'assessment_step1e_001',
      incident: incident ?? resolvedIncident(),
      plan: responsePlan,
      handoff: handoff(responsePlan: responsePlan),
      evidence: recoveryEvidence ?? evidence(),
      assessedAt: DateTime.utc(2026, 8, 19, 12),
    );
  }

  group('Phase 54 Step 1E recovery evidence + closure safety', () {
    test('safe recovery evidence is evidence-only', () {
      final AgentSecurityIncidentRecoveryEvidence item = evidence();

      expect(() => item.validateStructure(), returnsNormally);
      expect(item.evidenceOnly, isTrue);
      expect(item.closesIncident, isFalse);
      expect(item.persistsEvidence, isFalse);
    });

    test('recovery evidence rejects raw/private payload flags', () {
      final AgentSecurityIncidentRecoveryEvidence unsafe =
          AgentSecurityIncidentRecoveryEvidence(
            evidenceId: 'recovery_unsafe',
            incidentId: 'incident_step1e_001',
            source: AgentSecurityIncidentRecoveryEvidenceSource.trustedSystem,
            observedAt: DateTime.utc(2026, 8, 19, 11, 55),
            recoveryStable: true,
            containmentVerified: true,
            remediationVerified: true,
            permissionReviewVerified: true,
            approvalReviewVerified: true,
            runtimeReviewVerified: true,
            emergencyReviewVerified: true,
            humanSecurityReviewVerified: true,
            evidenceReferenceCodes: const <String>['safe_ref_001'],
            containsRawSecret: true,
          );

      expect(
        () => unsafe.validateStructure(),
        throwsA(isA<AgentSecurityIncidentRecoveryEvidenceException>()),
      );
    });

    test('recovery evidence references are bounded to 8', () {
      final List<String> refs = List<String>.generate(
        9,
        (int index) => 'recovery_ref_$index',
      );

      final AgentSecurityIncidentRecoveryEvidence overflow =
          AgentSecurityIncidentRecoveryEvidence(
            evidenceId: 'recovery_overflow',
            incidentId: 'incident_step1e_001',
            source: AgentSecurityIncidentRecoveryEvidenceSource.trustedSystem,
            observedAt: DateTime.utc(2026, 8, 19, 11, 55),
            recoveryStable: true,
            containmentVerified: true,
            remediationVerified: true,
            permissionReviewVerified: true,
            approvalReviewVerified: true,
            runtimeReviewVerified: true,
            emergencyReviewVerified: true,
            humanSecurityReviewVerified: true,
            evidenceReferenceCodes: refs,
          );

      expect(
        () => overflow.validateStructure(),
        throwsA(isA<AgentSecurityIncidentRecoveryEvidenceException>()),
      );
    });

    test('non-resolved incident cannot reach closure review readiness', () {
      final AgentSecurityIncidentClosureAssessment assessment = assessMedium(
        incident: resolvedIncident(status: AgentSecurityIncidentStatus.open),
      );

      expect(
        assessment.status,
        AgentSecurityIncidentClosureAssessmentStatus.blockedIncidentNotResolved,
      );
      expect(service.canRecommendClosure(assessment), isFalse);
    });

    test('unstable recovery requires continued monitoring', () {
      final AgentSecurityIncidentClosureAssessment assessment = assessMedium(
        recoveryEvidence: evidence(recoveryStable: false),
      );

      expect(
        assessment.status,
        AgentSecurityIncidentClosureAssessmentStatus.recoveryMonitoringRequired,
      );
      expect(service.canRecommendClosure(assessment), isFalse);
    });

    test('missing Permission verification blocks closure recommendation', () {
      final AgentSecurityIncidentClosureAssessment assessment = assessMedium(
        recoveryEvidence: evidence(permissionVerified: false),
      );

      expect(
        assessment.status,
        AgentSecurityIncidentClosureAssessmentStatus
            .blockedMissingRequiredVerification,
      );
      expect(assessment.requiredVerificationComplete, isFalse);
    });

    test('missing Runtime verification blocks closure recommendation', () {
      final AgentSecurityIncidentClosureAssessment assessment = assessMedium(
        recoveryEvidence: evidence(runtimeVerified: false),
      );

      expect(
        assessment.status,
        AgentSecurityIncidentClosureAssessmentStatus
            .blockedMissingRequiredVerification,
      );
    });

    test('MEDIUM resolved stable verified incident is review-ready only', () {
      final AgentSecurityIncidentClosureAssessment assessment = assessMedium();

      expect(
        assessment.status,
        AgentSecurityIncidentClosureAssessmentStatus
            .readyForAuthoritativeClosureReview,
      );
      expect(assessment.closureEligibleForAuthoritativeReview, isTrue);
      expect(assessment.finalClosureAuthorityStillRequired, isTrue);
      expect(assessment.marksIncidentClosed, isFalse);
    });

    test('HIGH incident requires containment/remediation verification', () {
      final AgentSecurityIncidentResponsePlan responsePlan = plan(
        severity: AgentGuardianSeverity.high,
      );

      final AgentSecurityIncidentClosureAssessment assessment = service
          .assessClosure(
            assessmentId: 'assessment_high_missing_response',
            incident: resolvedIncident(severity: AgentGuardianSeverity.high),
            plan: responsePlan,
            handoff: handoff(
              responsePlan: responsePlan,
              approvalRequired: true,
              humanRequired: true,
            ),
            evidence: evidence(
              containmentVerified: false,
              remediationVerified: true,
            ),
            assessedAt: DateTime.utc(2026, 8, 19, 12),
          );

      expect(
        assessment.status,
        AgentSecurityIncidentClosureAssessmentStatus
            .blockedMissingRequiredVerification,
      );
    });

    test('HIGH incident requires Approval and Human review verification', () {
      final AgentSecurityIncidentResponsePlan responsePlan = plan(
        severity: AgentGuardianSeverity.high,
      );

      final AgentSecurityIncidentClosureAssessment assessment = service
          .assessClosure(
            assessmentId: 'assessment_high_missing_reviews',
            incident: resolvedIncident(severity: AgentGuardianSeverity.high),
            plan: responsePlan,
            handoff: handoff(
              responsePlan: responsePlan,
              approvalRequired: true,
              humanRequired: true,
            ),
            evidence: evidence(approvalVerified: false, humanVerified: false),
            assessedAt: DateTime.utc(2026, 8, 19, 12),
          );

      expect(
        assessment.status,
        AgentSecurityIncidentClosureAssessmentStatus
            .blockedMissingRequiredVerification,
      );
    });

    test('CRITICAL incident requires Emergency review verification', () {
      final AgentSecurityIncidentResponsePlan responsePlan = plan(
        severity: AgentGuardianSeverity.critical,
      );

      final AgentSecurityIncidentClosureAssessment assessment = service
          .assessClosure(
            assessmentId: 'assessment_critical_missing_emergency',
            incident: resolvedIncident(
              severity: AgentGuardianSeverity.critical,
            ),
            plan: responsePlan,
            handoff: handoff(
              responsePlan: responsePlan,
              approvalRequired: true,
              emergencyRequired: true,
              humanRequired: true,
            ),
            evidence: evidence(emergencyVerified: false),
            assessedAt: DateTime.utc(2026, 8, 19, 12),
          );

      expect(
        assessment.status,
        AgentSecurityIncidentClosureAssessmentStatus
            .blockedMissingRequiredVerification,
      );
    });

    test('blocked upstream handoff cannot reach closure readiness', () {
      final AgentSecurityIncidentResponsePlan responsePlan = plan();

      final AgentSecurityIncidentClosureAssessment assessment = service
          .assessClosure(
            assessmentId: 'assessment_blocked_handoff',
            incident: resolvedIncident(),
            plan: responsePlan,
            handoff: handoff(
              responsePlan: responsePlan,
              status: AgentSecurityIncidentAuthoritativeHandoffStatus.blocked,
            ),
            evidence: evidence(),
            assessedAt: DateTime.utc(2026, 8, 19, 12),
          );

      expect(
        assessment.status,
        AgentSecurityIncidentClosureAssessmentStatus
            .blockedResponsePlanOrHandoff,
      );
    });

    test('closure input binding mismatch is rejected', () {
      final AgentSecurityIncidentResponsePlan responsePlan = plan();

      final AgentSecurityIncidentRecoveryEvidence mismatch =
          AgentSecurityIncidentRecoveryEvidence(
            evidenceId: 'recovery_mismatch',
            incidentId: 'different_incident',
            source: AgentSecurityIncidentRecoveryEvidenceSource.trustedSystem,
            observedAt: DateTime.utc(2026, 8, 19, 11, 55),
            recoveryStable: true,
            containmentVerified: true,
            remediationVerified: true,
            permissionReviewVerified: true,
            approvalReviewVerified: true,
            runtimeReviewVerified: true,
            emergencyReviewVerified: true,
            humanSecurityReviewVerified: true,
            evidenceReferenceCodes: const <String>['safe_ref_001'],
          );

      expect(
        () => service.assessClosure(
          assessmentId: 'assessment_mismatch',
          incident: resolvedIncident(),
          plan: responsePlan,
          handoff: handoff(responsePlan: responsePlan),
          evidence: mismatch,
          assessedAt: DateTime.utc(2026, 8, 19, 12),
        ),
        throwsA(isA<AgentSecurityIncidentClosureServiceException>()),
      );
    });

    test('closure safe map never claims final closure authority', () {
      final Map<String, dynamic> map = assessMedium().toSafeMap();

      expect(map['closureRecommendationOnly'], isTrue);
      expect(map['finalClosureAuthorityStillRequired'], isTrue);
      expect(map['marksIncidentResolved'], isFalse);
      expect(map['marksIncidentClosed'], isFalse);
      expect(map['grantsPermission'], isFalse);
      expect(map['persistsAssessment'], isFalse);
    });

    test('service cannot auto-close or execute response actions', () {
      expect(service.closureAssessmentOnly, isTrue);
      expect(service.finalClosureAuthorityExternal, isTrue);
      expect(service.autoClosesIncident, isFalse);
      expect(service.marksIncidentResolved, isFalse);
      expect(service.marksIncidentClosed, isFalse);
      expect(service.invokesPermissionEngine, isFalse);
      expect(service.invokesApprovalEngine, isFalse);
      expect(service.invokesRuntimeGate, isFalse);
      expect(service.invokesEmergencyStop, isFalse);
      expect(service.bypassesAuthoritativeControls, isFalse);
      expect(service.consumesApproval, isFalse);
      expect(service.grantsPermission, isFalse);
      expect(service.marksRuntimeAllowed, isFalse);
      expect(service.executesContainment, isFalse);
      expect(service.executesRemediation, isFalse);
      expect(service.executesRecoveryAction, isFalse);
      expect(service.invokesProvider, isFalse);
      expect(service.invokesTargetAgent, isFalse);
      expect(service.writesBusinessData, isFalse);
      expect(service.persistsEvidence, isFalse);
      expect(service.persistsAssessment, isFalse);
      expect(service.implementsPhase63PrivacyUi, isFalse);
    });
  });
}
