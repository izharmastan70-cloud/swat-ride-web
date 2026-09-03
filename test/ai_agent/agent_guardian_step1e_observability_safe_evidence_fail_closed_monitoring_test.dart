import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_guardian_observability_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_guardian_security_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_guardian_authoritative_gate_handoff.dart';
import 'package:swat_ride/ai_agent/models/agent_guardian_monitoring_assessment.dart';
import 'package:swat_ride/ai_agent/models/agent_guardian_risk_aggregate.dart';
import 'package:swat_ride/ai_agent/models/agent_guardian_risk_decision.dart';
import 'package:swat_ride/ai_agent/models/agent_guardian_security_observability_snapshot.dart';
import 'package:swat_ride/ai_agent/models/agent_guardian_security_policy_envelope.dart';
import 'package:swat_ride/ai_agent/services/agent_guardian_observability_service.dart';
import 'package:swat_ride/ai_agent/services/agent_guardian_policy_handoff_service.dart';

void main() {
  const AgentGuardianObservabilityService observability =
      AgentGuardianObservabilityService();

  const AgentGuardianPolicyHandoffService handoffService =
      AgentGuardianPolicyHandoffService();

  AgentGuardianRiskAggregate aggregate({
    String severity = AgentGuardianSeverity.medium,
    String confidence = AgentGuardianEvidenceConfidence.high,
    String disposition = AgentGuardianRecommendedDisposition.review,
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
      rejectedReasonByEventId: const <String, String>{},
      reasonCodes: const <String>['highest_individual_severity'],
      duplicateEventCount: 0,
      replayDuplicateSignalCount: 0,
      crossSubjectRejectedCount: 0,
      invalidSignalRejectedCount: 0,
      outsideWindowRejectedCount: 0,
      distinctCategoryCount: 1,
      distinctSourceComponentCount: 1,
      elevatedByCorrelation: false,
    );
  }

  AgentGuardianAuthoritativeGateHandoff handoff({
    AgentGuardianRiskAggregate? source,
  }) {
    final AgentGuardianSecurityPolicyEnvelope envelope = handoffService
        .buildEnvelope(
          envelopeId: 'envelope_001',
          aggregate: source ?? aggregate(),
          generatedAt: DateTime.utc(2026, 8, 19, 9),
        );

    return handoffService.prepareHandoff(
      handoffId: 'handoff_001',
      envelope: envelope,
    );
  }

  AgentGuardianSecurityObservabilitySnapshot snapshot({
    bool? permission = true,
    bool? approval = true,
    bool? runtime = true,
    bool? emergency = true,
    bool? human = true,
    Set<String> evidenceCodes = const <String>{'control_health_snapshot'},
    bool rawPrompt = false,
    bool rawHistory = false,
    bool rawSecret = false,
    bool payment = false,
    bool authToken = false,
    bool privatePayload = false,
  }) {
    return AgentGuardianSecurityObservabilitySnapshot(
      snapshotId: 'snapshot_001',
      sourceComponent: 'guardian_health_observer',
      capturedAt: DateTime.utc(2026, 8, 19, 9, 1),
      evidenceCodes: evidenceCodes,
      permissionEngineHealthy: permission,
      approvalEngineHealthy: approval,
      runtimeGateHealthy: runtime,
      emergencySecurityReviewHealthy: emergency,
      humanSecurityReviewAvailable: human,
      containsRawPrompt: rawPrompt,
      containsRawMessageHistory: rawHistory,
      containsRawSecret: rawSecret,
      containsPaymentCredential: payment,
      containsAuthToken: authToken,
      containsPrivatePayload: privatePayload,
    );
  }

  AgentGuardianMonitoringAssessment assess({
    AgentGuardianAuthoritativeGateHandoff? sourceHandoff,
    AgentGuardianSecurityObservabilitySnapshot? sourceSnapshot,
  }) {
    return observability.assess(
      assessmentId: 'assessment_001',
      handoff: sourceHandoff ?? handoff(),
      snapshot: sourceSnapshot ?? snapshot(),
      generatedAt: DateTime.utc(2026, 8, 19, 9, 2),
    );
  }

  group('Phase 53 Step 1E Guardian observability', () {
    test('safe metadata-only snapshot validates', () {
      final AgentGuardianSecurityObservabilitySnapshot safe = snapshot();

      expect(() => safe.validateStructure(), returnsNormally);
      expect(safe.safeEvidenceOnly, isTrue);
      expect(safe.persistsSnapshot, isFalse);
    });

    test('snapshot rejects raw/private payload classes', () {
      final List<AgentGuardianSecurityObservabilitySnapshot> prohibited =
          <AgentGuardianSecurityObservabilitySnapshot>[
            snapshot(rawPrompt: true),
            snapshot(rawHistory: true),
            snapshot(rawSecret: true),
            snapshot(payment: true),
            snapshot(authToken: true),
            snapshot(privatePayload: true),
          ];

      for (final AgentGuardianSecurityObservabilitySnapshot item
          in prohibited) {
        expect(
          () => item.validateStructure(),
          throwsA(isA<AgentGuardianSecurityObservabilitySnapshotException>()),
        );
      }
    });

    test('snapshot requires 1 to 8 evidence codes', () {
      expect(
        () => snapshot(evidenceCodes: const <String>{}).validateStructure(),
        throwsA(isA<AgentGuardianSecurityObservabilitySnapshotException>()),
      );

      expect(
        () => snapshot(
          evidenceCodes: const <String>{
            'a',
            'b',
            'c',
            'd',
            'e',
            'f',
            'g',
            'h',
            'i',
          },
        ).validateStructure(),
        throwsA(isA<AgentGuardianSecurityObservabilitySnapshotException>()),
      );
    });

    test('MEDIUM handoff with healthy supplied controls is healthy', () {
      final AgentGuardianMonitoringAssessment result = assess();

      expect(result.healthy, isTrue);
      expect(result.failClosedRecommended, isFalse);
      expect(result.authoritativeChecksStillPending, isTrue);
    });

    test(
      'required Permission Engine unhealthy => fail closed recommendation',
      () {
        final AgentGuardianMonitoringAssessment result = assess(
          sourceHandoff: handoff(
            source: aggregate(
              severity: AgentGuardianSeverity.high,
              disposition: AgentGuardianRecommendedDisposition.blockRecommended,
            ),
          ),
          sourceSnapshot: snapshot(permission: false),
        );

        expect(result.failClosed, isTrue);
        expect(result.failClosedRecommended, isTrue);
        expect(result.unhealthyRequiredControls, contains('permission_engine'));
        expect(
          result.reasonCodes,
          contains(
            AgentGuardianMonitoringReason.requiredPermissionEngineUnhealthy,
          ),
        );
      },
    );

    test(
      'required Permission Engine unknown => fail closed recommendation',
      () {
        final AgentGuardianMonitoringAssessment result = assess(
          sourceHandoff: handoff(
            source: aggregate(
              severity: AgentGuardianSeverity.high,
              disposition: AgentGuardianRecommendedDisposition.blockRecommended,
            ),
          ),
          sourceSnapshot: snapshot(permission: null),
        );

        expect(result.failClosed, isTrue);
        expect(result.unknownRequiredControls, contains('permission_engine'));
      },
    );

    test('required Runtime Gate unhealthy => fail closed recommendation', () {
      final AgentGuardianMonitoringAssessment result = assess(
        sourceHandoff: handoff(
          source: aggregate(
            severity: AgentGuardianSeverity.high,
            disposition: AgentGuardianRecommendedDisposition.blockRecommended,
          ),
        ),
        sourceSnapshot: snapshot(runtime: false),
      );

      expect(result.failClosed, isTrue);
      expect(result.unhealthyRequiredControls, contains('runtime_gate'));
    });

    test(
      'block-like HIGH requiring Approval Engine fails closed if unhealthy',
      () {
        final AgentGuardianMonitoringAssessment result = assess(
          sourceHandoff: handoff(
            source: aggregate(
              severity: AgentGuardianSeverity.high,
              disposition: AgentGuardianRecommendedDisposition.blockRecommended,
            ),
          ),
          sourceSnapshot: snapshot(approval: false),
        );

        expect(result.failClosed, isTrue);
        expect(result.unhealthyRequiredControls, contains('approval_engine'));
      },
    );

    test('CRITICAL emergency review unknown => fail closed recommendation', () {
      final AgentGuardianMonitoringAssessment result = assess(
        sourceHandoff: handoff(
          source: aggregate(
            severity: AgentGuardianSeverity.critical,
            disposition:
                AgentGuardianRecommendedDisposition.blockAndEscalateRecommended,
          ),
        ),
        sourceSnapshot: snapshot(emergency: null),
      );

      expect(result.failClosed, isTrue);
      expect(
        result.unknownRequiredControls,
        contains('emergency_security_review'),
      );
    });

    test('required human security review unavailable => fail closed', () {
      final AgentGuardianMonitoringAssessment result = assess(
        sourceHandoff: handoff(
          source: aggregate(
            severity: AgentGuardianSeverity.critical,
            disposition:
                AgentGuardianRecommendedDisposition.blockAndEscalateRecommended,
          ),
        ),
        sourceSnapshot: snapshot(human: false),
      );

      expect(result.failClosed, isTrue);
      expect(result.humanSecurityReviewRequired, isTrue);
      expect(
        result.unhealthyRequiredControls,
        contains('human_security_review'),
      );
    });

    test('non-required unhealthy control is degraded, not fail closed', () {
      final AgentGuardianMonitoringAssessment result = assess(
        sourceSnapshot: snapshot(approval: false),
      );

      expect(result.degraded, isTrue);
      expect(result.failClosedRecommended, isFalse);
      expect(
        result.reasonCodes,
        contains(AgentGuardianMonitoringReason.nonRequiredControlDegraded),
      );
    });

    test('invalid observability snapshot fails closed', () {
      final AgentGuardianMonitoringAssessment result = assess(
        sourceSnapshot: snapshot(rawSecret: true),
      );

      expect(result.failClosed, isTrue);
      expect(result.failClosedRecommended, isTrue);
      expect(
        result.reasonCodes,
        contains(AgentGuardianMonitoringReason.invalidObservabilitySnapshot),
      );
    });

    test('blocked Guardian handoff fails closed', () {
      final AgentGuardianAuthoritativeGateHandoff blocked = handoff(
        source: aggregate(status: AgentGuardianRiskAggregateStatus.blocked),
      );

      final AgentGuardianMonitoringAssessment result = assess(
        sourceHandoff: blocked,
      );

      expect(result.failClosed, isTrue);
      expect(result.humanSecurityReviewRequired, isTrue);
    });

    test('all required CRITICAL controls healthy does not auto-authorize', () {
      final AgentGuardianMonitoringAssessment result = assess(
        sourceHandoff: handoff(
          source: aggregate(
            severity: AgentGuardianSeverity.critical,
            disposition:
                AgentGuardianRecommendedDisposition.blockAndEscalateRecommended,
          ),
        ),
      );

      expect(result.healthy, isTrue);
      expect(result.failClosedRecommended, isFalse);
      expect(result.authoritativeChecksStillPending, isTrue);
      expect(result.grantsAuthority, isFalse);
      expect(result.marksPermissionApproved, isFalse);
      expect(result.marksApprovalConsumed, isFalse);
      expect(result.marksRuntimeAllowed, isFalse);
    });

    test('safe snapshot map exposes no prohibited payload', () {
      final Map<String, dynamic> map = snapshot().toSafeMap();

      expect(map['rawPromptIncluded'], isFalse);
      expect(map['rawMessageHistoryIncluded'], isFalse);
      expect(map['rawSecretIncluded'], isFalse);
      expect(map['paymentCredentialIncluded'], isFalse);
      expect(map['authTokenIncluded'], isFalse);
      expect(map['privatePayloadIncluded'], isFalse);
      expect(map['persistsSnapshot'], isFalse);
    });

    test('safe assessment map remains recommendation-only', () {
      final Map<String, dynamic> map = assess().toSafeMap();

      expect(map['rawEvidencePayloadIncluded'], isFalse);
      expect(map['recommendationOnly'], isTrue);
      expect(map['safeEvidenceOnly'], isTrue);
      expect(map['guardianIsFinalEnforcer'], isFalse);
      expect(map['grantsAuthority'], isFalse);
      expect(map['grantsPermission'], isFalse);
      expect(map['consumesApproval'], isFalse);
      expect(map['executesBlock'], isFalse);
      expect(map['executesEscalation'], isFalse);
      expect(map['createsIncident'], isFalse);
      expect(map['writesBusinessData'], isFalse);
      expect(map['persistsAssessment'], isFalse);
    });

    test('observability never invokes or bypasses authoritative controls', () {
      expect(observability.recommendationOnly, isTrue);
      expect(observability.safeEvidenceOnly, isTrue);
      expect(observability.guardianIsFinalEnforcer, isFalse);
      expect(observability.invokesPermissionEngine, isFalse);
      expect(observability.invokesApprovalEngine, isFalse);
      expect(observability.invokesRuntimeGate, isFalse);
      expect(observability.invokesEmergencyStop, isFalse);
      expect(observability.bypassesPermissionEngine, isFalse);
      expect(observability.bypassesApprovalEngine, isFalse);
      expect(observability.bypassesRuntimeGate, isFalse);
      expect(observability.bypassesEmergencyStop, isFalse);
      expect(observability.grantsPermission, isFalse);
      expect(observability.consumesApproval, isFalse);
      expect(observability.marksRuntimeAllowed, isFalse);
    });

    test('observability does not persist audit or implement Phase 54', () {
      expect(observability.executesBlock, isFalse);
      expect(observability.executesEscalation, isFalse);
      expect(observability.createsIncident, isFalse);
      expect(observability.implementsIncidentResponse, isFalse);
      expect(observability.writesAuditPersistence, isFalse);
      expect(observability.invokesSecurityAuditService, isFalse);
      expect(observability.mutatesSecurityControls, isFalse);
      expect(observability.invokesProvider, isFalse);
      expect(observability.invokesTargetAgent, isFalse);
      expect(observability.writesBusinessData, isFalse);
      expect(observability.persistsSnapshotOrAssessment, isFalse);
    });
  });
}
