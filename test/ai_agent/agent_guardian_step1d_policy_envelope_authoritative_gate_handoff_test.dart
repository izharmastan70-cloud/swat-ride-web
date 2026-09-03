import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_guardian_security_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_guardian_authoritative_gate_handoff.dart';
import 'package:swat_ride/ai_agent/models/agent_guardian_risk_aggregate.dart';
import 'package:swat_ride/ai_agent/models/agent_guardian_risk_decision.dart';
import 'package:swat_ride/ai_agent/models/agent_guardian_security_policy_envelope.dart';
import 'package:swat_ride/ai_agent/services/agent_guardian_policy_handoff_service.dart';

void main() {
  const AgentGuardianPolicyHandoffService service =
      AgentGuardianPolicyHandoffService();

  AgentGuardianRiskAggregate aggregate({
    String severity = AgentGuardianSeverity.medium,
    String confidence = AgentGuardianEvidenceConfidence.high,
    String disposition = AgentGuardianRecommendedDisposition.review,
    bool elevated = false,
    bool rejected = false,
    String status = AgentGuardianRiskAggregateStatus.ready,
  }) {
    return AgentGuardianRiskAggregate(
      status: status,
      correlationId: 'correlation_001',
      pseudonymousSubjectRef: 'subject_hash_001',
      severity: severity,
      evidenceConfidence: confidence,
      recommendedDisposition: disposition,
      acceptedDecisions: <AgentGuardianRiskDecision>[
        AgentGuardianRiskDecision(
          status: AgentGuardianRiskDecisionStatus.classified,
          eventId: 'event_001',
          category: AgentGuardianRiskCategory.promptInjectionAttempt,
          severity: severity,
          evidenceConfidence: confidence,
          recommendedDisposition: disposition,
          reasonCodes: const <String>[
            AgentGuardianRiskReason.baseCategorySeverity,
          ],
          existingAuthoritativeGateBlocked: false,
        ),
      ],
      rejectedReasonByEventId: rejected
          ? const <String, String>{'event_rejected': 'duplicate_event_id'}
          : const <String, String>{},
      reasonCodes: const <String>['highest_individual_severity'],
      duplicateEventCount: rejected ? 1 : 0,
      replayDuplicateSignalCount: 0,
      crossSubjectRejectedCount: 0,
      invalidSignalRejectedCount: 0,
      outsideWindowRejectedCount: 0,
      distinctCategoryCount: 1,
      distinctSourceComponentCount: 1,
      elevatedByCorrelation: elevated,
    );
  }

  AgentGuardianSecurityPolicyEnvelope envelope({
    AgentGuardianRiskAggregate? source,
  }) {
    return service.buildEnvelope(
      envelopeId: 'envelope_001',
      aggregate: source ?? aggregate(),
      generatedAt: DateTime.utc(2026, 8, 19, 9),
    );
  }

  group('Phase 53 Step 1D Guardian policy handoff', () {
    test('MEDIUM review does not invent high-risk authority requirements', () {
      final AgentGuardianSecurityPolicyEnvelope result = envelope();

      expect(result.ready, isTrue);
      expect(result.requiresPermissionEngine, isFalse);
      expect(result.requiresApprovalEngine, isFalse);
      expect(result.requiresRuntimeGate, isFalse);
      expect(result.requiresEmergencySecurityReview, isFalse);
      expect(result.actionMayProceedWithoutAuthoritativeChecks, isFalse);
    });

    test('HIGH risk requires Permission Engine and Runtime Gate', () {
      final AgentGuardianSecurityPolicyEnvelope result = envelope(
        source: aggregate(
          severity: AgentGuardianSeverity.high,
          disposition: AgentGuardianRecommendedDisposition.blockRecommended,
        ),
      );

      expect(result.requiresPermissionEngine, isTrue);
      expect(result.requiresRuntimeGate, isTrue);
      expect(result.failClosedRecommended, isTrue);
    });

    test('block recommendation requires Approval Engine handoff', () {
      final AgentGuardianSecurityPolicyEnvelope result = envelope(
        source: aggregate(
          severity: AgentGuardianSeverity.high,
          disposition: AgentGuardianRecommendedDisposition.blockRecommended,
        ),
      );

      expect(result.requiresApprovalEngine, isTrue);
    });

    test('CRITICAL risk requires all central reviews', () {
      final AgentGuardianSecurityPolicyEnvelope result = envelope(
        source: aggregate(
          severity: AgentGuardianSeverity.critical,
          disposition:
              AgentGuardianRecommendedDisposition.blockAndEscalateRecommended,
        ),
      );

      expect(result.requiresPermissionEngine, isTrue);
      expect(result.requiresApprovalEngine, isTrue);
      expect(result.requiresRuntimeGate, isTrue);
      expect(result.requiresEmergencySecurityReview, isTrue);
      expect(result.requiresHumanSecurityReview, isTrue);
      expect(result.failClosedRecommended, isTrue);
    });

    test('correlation elevation remains visible in policy reasons', () {
      final AgentGuardianSecurityPolicyEnvelope result = envelope(
        source: aggregate(
          severity: AgentGuardianSeverity.high,
          disposition: AgentGuardianRecommendedDisposition.reviewAndEscalate,
          elevated: true,
        ),
      );

      expect(
        result.policyReasonCodes,
        contains('multi_signal_correlation_elevation'),
      );
    });

    test('rejected correlation signals remain visible in policy reasons', () {
      final AgentGuardianSecurityPolicyEnvelope result = envelope(
        source: aggregate(rejected: true),
      );

      expect(
        result.policyReasonCodes,
        contains('correlation_had_rejected_signals'),
      );
    });

    test('blocked aggregate fails closed to authoritative checks', () {
      final AgentGuardianSecurityPolicyEnvelope result = envelope(
        source: aggregate(status: AgentGuardianRiskAggregateStatus.blocked),
      );

      expect(result.blocked, isTrue);
      expect(result.requiresPermissionEngine, isTrue);
      expect(result.requiresApprovalEngine, isTrue);
      expect(result.requiresRuntimeGate, isTrue);
      expect(result.requiresHumanSecurityReview, isTrue);
      expect(result.failClosedRecommended, isTrue);
    });

    test('envelope structurally rejects authoritative-check bypass', () {
      final AgentGuardianSecurityPolicyEnvelope invalid =
          AgentGuardianSecurityPolicyEnvelope(
            status: AgentGuardianPolicyEnvelopeStatus.ready,
            envelopeId: 'envelope_invalid',
            correlationId: 'correlation_001',
            pseudonymousSubjectRef: 'subject_hash_001',
            severity: AgentGuardianSeverity.medium,
            evidenceConfidence: AgentGuardianEvidenceConfidence.high,
            recommendedDisposition: AgentGuardianRecommendedDisposition.review,
            requiresPermissionEngine: false,
            requiresApprovalEngine: false,
            requiresRuntimeGate: false,
            requiresEmergencySecurityReview: false,
            requiresHumanSecurityReview: false,
            failClosedRecommended: false,
            actionMayProceedWithoutAuthoritativeChecks: true,
            policyReasonCodes: const <String>['unsafe_bypass_attempt'],
            generatedAt: DateTime.utc(2026, 8, 19, 9),
          );

      expect(
        () => invalid.validateStructure(),
        throwsA(isA<AgentGuardianSecurityPolicyEnvelopeException>()),
      );
    });

    test('HIGH envelope cannot remove Permission/Runtime checks', () {
      final AgentGuardianSecurityPolicyEnvelope invalid =
          AgentGuardianSecurityPolicyEnvelope(
            status: AgentGuardianPolicyEnvelopeStatus.ready,
            envelopeId: 'envelope_invalid_high',
            correlationId: 'correlation_001',
            pseudonymousSubjectRef: 'subject_hash_001',
            severity: AgentGuardianSeverity.high,
            evidenceConfidence: AgentGuardianEvidenceConfidence.high,
            recommendedDisposition:
                AgentGuardianRecommendedDisposition.blockRecommended,
            requiresPermissionEngine: false,
            requiresApprovalEngine: true,
            requiresRuntimeGate: false,
            requiresEmergencySecurityReview: false,
            requiresHumanSecurityReview: true,
            failClosedRecommended: true,
            actionMayProceedWithoutAuthoritativeChecks: false,
            policyReasonCodes: const <String>['invalid_removed_checks'],
            generatedAt: DateTime.utc(2026, 8, 19, 9),
          );

      expect(
        () => invalid.validateStructure(),
        throwsA(isA<AgentGuardianSecurityPolicyEnvelopeException>()),
      );
    });

    test('prepared handoff keeps authoritative checks pending', () {
      final AgentGuardianSecurityPolicyEnvelope policy = envelope(
        source: aggregate(
          severity: AgentGuardianSeverity.high,
          disposition: AgentGuardianRecommendedDisposition.blockRecommended,
        ),
      );

      final AgentGuardianAuthoritativeGateHandoff handoff = service
          .prepareHandoff(handoffId: 'handoff_001', envelope: policy);

      expect(handoff.prepared, isTrue);
      expect(handoff.permissionEngineRequired, isTrue);
      expect(handoff.approvalEngineRequired, isTrue);
      expect(handoff.runtimeGateRequired, isTrue);
      expect(handoff.authoritativeChecksStillPending, isTrue);
    });

    test('handoff never marks Permission/Approval/Runtime as completed', () {
      final AgentGuardianAuthoritativeGateHandoff handoff = service
          .prepareHandoff(
            handoffId: 'handoff_001',
            envelope: envelope(
              source: aggregate(
                severity: AgentGuardianSeverity.high,
                disposition:
                    AgentGuardianRecommendedDisposition.blockRecommended,
              ),
            ),
          );

      expect(handoff.marksPermissionApproved, isFalse);
      expect(handoff.marksApprovalConsumed, isFalse);
      expect(handoff.marksRuntimeAllowed, isFalse);
    });

    test('CRITICAL handoff requests emergency security review only', () {
      final AgentGuardianAuthoritativeGateHandoff handoff = service
          .prepareHandoff(
            handoffId: 'handoff_critical',
            envelope: envelope(
              source: aggregate(
                severity: AgentGuardianSeverity.critical,
                disposition: AgentGuardianRecommendedDisposition
                    .blockAndEscalateRecommended,
              ),
            ),
          );

      expect(handoff.emergencySecurityReviewRequired, isTrue);
      expect(handoff.invokesEmergencyStop, isFalse);
      expect(handoff.createsIncident, isFalse);
    });

    test('safe envelope metadata grants no authority', () {
      final Map<String, dynamic> map = envelope().toSafeMap();

      expect(map['recommendationOnly'], isTrue);
      expect(map['guardianIsFinalEnforcer'], isFalse);
      expect(map['grantsAuthority'], isFalse);
      expect(map['grantsPermission'], isFalse);
      expect(map['consumesApproval'], isFalse);
      expect(map['invokesPermissionEngine'], isFalse);
      expect(map['invokesApprovalEngine'], isFalse);
      expect(map['invokesRuntimeGate'], isFalse);
      expect(map['invokesEmergencyStop'], isFalse);
      expect(map['writesBusinessData'], isFalse);
    });

    test('safe handoff metadata remains evidence-only', () {
      final AgentGuardianAuthoritativeGateHandoff handoff = service
          .prepareHandoff(handoffId: 'handoff_001', envelope: envelope());

      final Map<String, dynamic> map = handoff.toSafeMap();

      expect(map['recommendationOnly'], isTrue);
      expect(map['guardianIsFinalEnforcer'], isFalse);
      expect(map['grantsAuthority'], isFalse);
      expect(map['marksPermissionApproved'], isFalse);
      expect(map['marksApprovalConsumed'], isFalse);
      expect(map['marksRuntimeAllowed'], isFalse);
      expect(map['invokesProvider'], isFalse);
      expect(map['writesBusinessData'], isFalse);
    });

    test('service cannot bypass or execute authoritative controls', () {
      expect(service.recommendationOnly, isTrue);
      expect(service.guardianIsFinalEnforcer, isFalse);
      expect(service.invokesPermissionEngine, isFalse);
      expect(service.invokesApprovalEngine, isFalse);
      expect(service.invokesRuntimeGate, isFalse);
      expect(service.invokesEmergencyStop, isFalse);
      expect(service.bypassesPermissionEngine, isFalse);
      expect(service.bypassesApprovalEngine, isFalse);
      expect(service.bypassesRuntimeGate, isFalse);
      expect(service.bypassesEmergencyStop, isFalse);
      expect(service.grantsPermission, isFalse);
      expect(service.consumesApproval, isFalse);
      expect(service.marksRuntimeAllowed, isFalse);
      expect(service.executesBlock, isFalse);
      expect(service.executesEscalation, isFalse);
      expect(service.createsIncident, isFalse);
      expect(service.implementsIncidentResponse, isFalse);
      expect(service.mutatesSecurityControls, isFalse);
      expect(service.invokesProvider, isFalse);
      expect(service.invokesTargetAgent, isFalse);
      expect(service.writesBusinessData, isFalse);
      expect(service.persistsEnvelopeOrHandoff, isFalse);
    });
  });
}
