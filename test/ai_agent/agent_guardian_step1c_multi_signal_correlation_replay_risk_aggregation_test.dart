import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_guardian_security_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_omnichannel_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_guardian_correlation_request.dart';
import 'package:swat_ride/ai_agent/models/agent_guardian_risk_aggregate.dart';
import 'package:swat_ride/ai_agent/models/agent_guardian_security_event.dart';
import 'package:swat_ride/ai_agent/services/agent_guardian_signal_correlator.dart';

void main() {
  const AgentGuardianSignalCorrelator correlator =
      AgentGuardianSignalCorrelator();

  AgentGuardianSecurityEvent event({
    required String eventId,
    String subjectRef = 'subject_hash_001',
    String category = AgentGuardianRiskCategory.promptInjectionAttempt,
    String evidenceTrust = AgentGuardianEvidenceTrust.verifiedSystem,
    String sourceComponent = 'gateway_a',
    DateTime? occurredAt,
    Set<String> evidenceCodes = const <String>{'pattern_match'},
    String channel = AgentOmnichannelChannel.appChat,
    String targetActionId = 'status.read',
    bool highImpact = false,
    bool repeated = false,
    bool activeExploit = false,
    bool rawSecret = false,
  }) {
    final DateTime occurred = occurredAt ?? DateTime.utc(2026, 8, 19, 8, 5);

    return AgentGuardianSecurityEvent(
      eventId: eventId,
      category: category,
      evidenceTrust: evidenceTrust,
      sourceComponent: sourceComponent,
      occurredAt: occurred,
      observedAt: occurred.add(const Duration(minutes: 1)),
      evidenceCodes: evidenceCodes,
      pseudonymousSubjectRef: subjectRef,
      sourceChannel: channel,
      agentRoleId: 'support_agent',
      targetActionId: targetActionId,
      highImpactActionTargeted: highImpact,
      repeatedWithinWindow: repeated,
      activeExploitEvidence: activeExploit,
      existingAuthoritativeGateBlocked: false,
      containsRawPrompt: false,
      containsRawMessageHistory: false,
      containsRawSecret: rawSecret,
      containsPaymentCredential: false,
      containsAuthToken: false,
      containsOwnerPrivatePayload: false,
      containsCustomerPrivatePayload: false,
    );
  }

  AgentGuardianCorrelationRequest request({
    List<AgentGuardianSecurityEvent>? events,
    String subjectRef = 'subject_hash_001',
    DateTime? windowStart,
    DateTime? windowEnd,
    int maxEvents = 20,
  }) {
    return AgentGuardianCorrelationRequest(
      correlationId: 'correlation_001',
      pseudonymousSubjectRef: subjectRef,
      windowStart: windowStart ?? DateTime.utc(2026, 8, 19, 8),
      windowEnd: windowEnd ?? DateTime.utc(2026, 8, 19, 8, 30),
      events:
          events ?? <AgentGuardianSecurityEvent>[event(eventId: 'event_001')],
      maxEvents: maxEvents,
    );
  }

  group('Phase 53 Step 1C multi-signal correlation', () {
    test('bounded correlation request validates', () {
      final AgentGuardianCorrelationRequest safeRequest = request();

      expect(() => safeRequest.validateStructure(), returnsNormally);

      expect(safeRequest.loadsCrossSubjectHistory, isFalse);
      expect(safeRequest.loadsFullConversationHistory, isFalse);
    });

    test('window over 30 minutes is rejected', () {
      expect(
        () => request(
          windowStart: DateTime.utc(2026, 8, 19, 8),
          windowEnd: DateTime.utc(2026, 8, 19, 8, 31),
        ).validateStructure(),
        throwsA(isA<AgentGuardianCorrelationRequestException>()),
      );
    });

    test('max 20 events enforced', () {
      final List<AgentGuardianSecurityEvent> events =
          List<AgentGuardianSecurityEvent>.generate(
            21,
            (int index) => event(eventId: 'event_$index'),
          );

      expect(
        () => request(events: events).validateStructure(),
        throwsA(isA<AgentGuardianCorrelationRequestException>()),
      );
    });

    test('single valid signal correlates without elevation', () {
      final AgentGuardianRiskAggregate aggregate = correlator.correlate(
        request(),
      );

      expect(aggregate.ready, isTrue);
      expect(aggregate.acceptedDecisions.length, 1);
      expect(aggregate.severity, AgentGuardianSeverity.medium);
      expect(aggregate.elevatedByCorrelation, isFalse);
    });

    test('duplicate event id is suppressed', () {
      final AgentGuardianSecurityEvent first = event(eventId: 'same_event');

      final AgentGuardianSecurityEvent duplicate = event(
        eventId: 'same_event',
        category: AgentGuardianRiskCategory.permissionBypassAttempt,
        sourceComponent: 'gateway_b',
      );

      final AgentGuardianRiskAggregate aggregate = correlator.correlate(
        request(events: <AgentGuardianSecurityEvent>[first, duplicate]),
      );

      expect(aggregate.acceptedDecisions.length, 1);
      expect(aggregate.duplicateEventCount, 1);
      expect(
        aggregate.rejectedReasonByEventId['same_event'],
        AgentGuardianCorrelationRejectReason.duplicateEventId,
      );
    });

    test('semantic replay with new event id is suppressed', () {
      final AgentGuardianSecurityEvent first = event(eventId: 'event_a');

      final AgentGuardianSecurityEvent replay = event(eventId: 'event_b');

      final AgentGuardianRiskAggregate aggregate = correlator.correlate(
        request(events: <AgentGuardianSecurityEvent>[first, replay]),
      );

      expect(aggregate.acceptedDecisions.length, 1);
      expect(aggregate.replayDuplicateSignalCount, 1);
      expect(
        aggregate.rejectedReasonByEventId['event_b'],
        AgentGuardianCorrelationRejectReason.replayDuplicateSignal,
      );
    });

    test('cross-subject signal is rejected and never correlated', () {
      final AgentGuardianRiskAggregate aggregate = correlator.correlate(
        request(
          events: <AgentGuardianSecurityEvent>[
            event(eventId: 'event_good'),
            event(
              eventId: 'event_other',
              subjectRef: 'subject_hash_other',
              sourceComponent: 'gateway_b',
            ),
          ],
        ),
      );

      expect(aggregate.acceptedDecisions.length, 1);
      expect(aggregate.crossSubjectRejectedCount, 1);
      expect(
        aggregate.rejectedReasonByEventId['event_other'],
        AgentGuardianCorrelationRejectReason.subjectMismatch,
      );
    });

    test('unbound subject signal is rejected', () {
      final AgentGuardianSecurityEvent unbound = AgentGuardianSecurityEvent(
        eventId: 'event_unbound',
        category: AgentGuardianRiskCategory.promptInjectionAttempt,
        evidenceTrust: AgentGuardianEvidenceTrust.verifiedSystem,
        sourceComponent: 'gateway_b',
        occurredAt: DateTime.utc(2026, 8, 19, 8, 5),
        observedAt: DateTime.utc(2026, 8, 19, 8, 6),
        evidenceCodes: const <String>{'pattern_match'},
        pseudonymousSubjectRef: null,
        sourceChannel: AgentOmnichannelChannel.appChat,
        agentRoleId: 'support_agent',
        targetActionId: 'status.read',
      );

      final AgentGuardianRiskAggregate aggregate = correlator.correlate(
        request(
          events: <AgentGuardianSecurityEvent>[
            event(eventId: 'event_good'),
            unbound,
          ],
        ),
      );

      expect(aggregate.acceptedDecisions.length, 1);
      expect(aggregate.crossSubjectRejectedCount, 1);
      expect(
        aggregate.rejectedReasonByEventId['event_unbound'],
        AgentGuardianCorrelationRejectReason.subjectUnbound,
      );
    });

    test('out-of-window signal is rejected', () {
      final AgentGuardianRiskAggregate aggregate = correlator.correlate(
        request(
          events: <AgentGuardianSecurityEvent>[
            event(eventId: 'event_good'),
            event(
              eventId: 'event_old',
              occurredAt: DateTime.utc(2026, 8, 19, 7, 30),
              sourceComponent: 'gateway_b',
            ),
          ],
        ),
      );

      expect(aggregate.acceptedDecisions.length, 1);
      expect(aggregate.outsideWindowRejectedCount, 1);
    });

    test('invalid raw-secret event is rejected, not aggregated', () {
      final AgentGuardianRiskAggregate aggregate = correlator.correlate(
        request(
          events: <AgentGuardianSecurityEvent>[
            event(eventId: 'event_good'),
            event(
              eventId: 'event_invalid',
              rawSecret: true,
              sourceComponent: 'gateway_b',
            ),
          ],
        ),
      );

      expect(aggregate.acceptedDecisions.length, 1);
      expect(aggregate.invalidSignalRejectedCount, 1);
      expect(
        aggregate.rejectedReasonByEventId['event_invalid'],
        AgentGuardianCorrelationRejectReason.invalidEvent,
      );
    });

    test('two independent MEDIUM signals elevate aggregate to HIGH', () {
      final AgentGuardianRiskAggregate aggregate = correlator.correlate(
        request(
          events: <AgentGuardianSecurityEvent>[
            event(
              eventId: 'event_injection',
              category: AgentGuardianRiskCategory.promptInjectionAttempt,
              sourceComponent: 'gateway_a',
            ),
            event(
              eventId: 'event_identity',
              category: AgentGuardianRiskCategory.identityMismatch,
              sourceComponent: 'identity_gate',
              occurredAt: DateTime.utc(2026, 8, 19, 8, 6),
              evidenceCodes: const <String>{'binding_mismatch'},
            ),
          ],
        ),
      );

      expect(aggregate.severity, AgentGuardianSeverity.high);
      expect(aggregate.elevatedByCorrelation, isTrue);
      expect(aggregate.distinctCategoryCount, 2);
      expect(aggregate.distinctSourceComponentCount, 2);
    });

    test('three independent HIGH categories can elevate to CRITICAL', () {
      final AgentGuardianRiskAggregate aggregate = correlator.correlate(
        request(
          events: <AgentGuardianSecurityEvent>[
            event(
              eventId: 'event_perm',
              category: AgentGuardianRiskCategory.permissionBypassAttempt,
              sourceComponent: 'permission_boundary',
              occurredAt: DateTime.utc(2026, 8, 19, 8, 5),
              evidenceCodes: const <String>{'permission_denied'},
            ),
            event(
              eventId: 'event_runtime',
              category: AgentGuardianRiskCategory.runtimeGateBypassAttempt,
              sourceComponent: 'runtime_boundary',
              occurredAt: DateTime.utc(2026, 8, 19, 8, 6),
              evidenceCodes: const <String>{'runtime_denied'},
            ),
            event(
              eventId: 'event_context',
              category: AgentGuardianRiskCategory.crossSubjectContextAttempt,
              sourceComponent: 'context_boundary',
              occurredAt: DateTime.utc(2026, 8, 19, 8, 7),
              evidenceCodes: const <String>{'subject_mismatch'},
            ),
          ],
        ),
      );

      expect(aggregate.severity, AgentGuardianSeverity.critical);
      expect(aggregate.elevatedByCorrelation, isTrue);
      expect(
        aggregate.reasonCodes,
        contains(AgentGuardianCorrelationReason.independentCriticalCorrelation),
      );
    });

    test('replayed duplicates cannot create correlation elevation', () {
      final AgentGuardianSecurityEvent original = event(
        eventId: 'event_original',
        category: AgentGuardianRiskCategory.promptInjectionAttempt,
      );

      final List<AgentGuardianSecurityEvent> events =
          <AgentGuardianSecurityEvent>[
            original,
            event(
              eventId: 'event_replay_1',
              category: AgentGuardianRiskCategory.promptInjectionAttempt,
            ),
            event(
              eventId: 'event_replay_2',
              category: AgentGuardianRiskCategory.promptInjectionAttempt,
            ),
          ];

      final AgentGuardianRiskAggregate aggregate = correlator.correlate(
        request(events: events),
      );

      expect(aggregate.acceptedDecisions.length, 1);
      expect(aggregate.replayDuplicateSignalCount, 2);
      expect(aggregate.elevatedByCorrelation, isFalse);
      expect(aggregate.severity, AgentGuardianSeverity.medium);
    });

    test(
      'same source with different categories does not qualify as independent',
      () {
        final AgentGuardianRiskAggregate aggregate = correlator.correlate(
          request(
            events: <AgentGuardianSecurityEvent>[
              event(
                eventId: 'event_a',
                category: AgentGuardianRiskCategory.promptInjectionAttempt,
                sourceComponent: 'same_gateway',
              ),
              event(
                eventId: 'event_b',
                category: AgentGuardianRiskCategory.identityMismatch,
                sourceComponent: 'same_gateway',
                occurredAt: DateTime.utc(2026, 8, 19, 8, 6),
                evidenceCodes: const <String>{'identity_signal'},
              ),
            ],
          ),
        );

        expect(aggregate.distinctCategoryCount, 2);
        expect(aggregate.distinctSourceComponentCount, 1);
        expect(aggregate.elevatedByCorrelation, isFalse);
        expect(aggregate.severity, AgentGuardianSeverity.medium);
      },
    );

    test(
      'verified critical aggregate may recommend block and escalate only',
      () {
        final AgentGuardianRiskAggregate aggregate = correlator.correlate(
          request(
            events: <AgentGuardianSecurityEvent>[
              event(
                eventId: 'event_tamper',
                category:
                    AgentGuardianRiskCategory.securityControlTamperAttempt,
                evidenceTrust:
                    AgentGuardianEvidenceTrust.verifiedSecurityControl,
                sourceComponent: 'security_control',
                evidenceCodes: const <String>{'tamper_proof'},
              ),
            ],
          ),
        );

        expect(
          aggregate.recommendedDisposition,
          AgentGuardianRecommendedDisposition.blockAndEscalateRecommended,
        );
        expect(aggregate.executesBlock, isFalse);
        expect(aggregate.executesEscalation, isFalse);
      },
    );

    test('low-confidence critical aggregate never auto-blocks', () {
      final AgentGuardianRiskAggregate aggregate = correlator.correlate(
        request(
          events: <AgentGuardianSecurityEvent>[
            event(
              eventId: 'event_reported',
              category: AgentGuardianRiskCategory.securityControlTamperAttempt,
              evidenceTrust: AgentGuardianEvidenceTrust.userReported,
              sourceComponent: 'support_report',
            ),
          ],
        ),
      );

      expect(aggregate.evidenceConfidence, AgentGuardianEvidenceConfidence.low);
      expect(
        aggregate.recommendedDisposition,
        AgentGuardianRecommendedDisposition.reviewAndEscalate,
      );
      expect(aggregate.executesBlock, isFalse);
    });

    test('all rejected signals fail closed', () {
      final AgentGuardianRiskAggregate aggregate = correlator.correlate(
        request(
          events: <AgentGuardianSecurityEvent>[
            event(eventId: 'event_other', subjectRef: 'other_subject'),
          ],
        ),
      );

      expect(aggregate.blocked, isTrue);
      expect(aggregate.acceptedDecisions, isEmpty);
      expect(
        aggregate.recommendedDisposition,
        AgentGuardianRecommendedDisposition.reviewAndEscalate,
      );
    });

    test('safe aggregate metadata contains no raw events', () {
      final AgentGuardianRiskAggregate aggregate = correlator.correlate(
        request(),
      );

      final Map<String, dynamic> map = aggregate.toSafeMap();

      expect(map['rawGuardianEventsIncluded'], isFalse);
      expect(map.containsKey('events'), isFalse);
      expect(map['recommendationOnly'], isTrue);
      expect(map['guardianIsFinalEnforcer'], isFalse);
      expect(map['createsIncident'], isFalse);
      expect(map['writesBusinessData'], isFalse);
    });

    test('aggregate remains recommendation-only', () {
      final AgentGuardianRiskAggregate aggregate = correlator.correlate(
        request(),
      );

      expect(aggregate.recommendationOnly, isTrue);
      expect(aggregate.guardianIsFinalEnforcer, isFalse);
      expect(aggregate.grantsAuthority, isFalse);
      expect(aggregate.grantsPermission, isFalse);
      expect(aggregate.consumesApproval, isFalse);
      expect(aggregate.executesBlock, isFalse);
      expect(aggregate.executesEscalation, isFalse);
      expect(aggregate.createsIncident, isFalse);
      expect(aggregate.mutatesSecurityControls, isFalse);
      expect(aggregate.persistsAggregate, isFalse);
    });

    test('correlator never becomes enforcement or incident response', () {
      expect(correlator.recommendationOnly, isTrue);
      expect(correlator.guardianIsFinalEnforcer, isFalse);
      expect(correlator.invokesPermissionEngine, isFalse);
      expect(correlator.invokesApprovalEngine, isFalse);
      expect(correlator.invokesRuntimeGate, isFalse);
      expect(correlator.invokesEmergencyStop, isFalse);
      expect(correlator.executesBlock, isFalse);
      expect(correlator.executesEscalation, isFalse);
      expect(correlator.createsIncident, isFalse);
      expect(correlator.implementsIncidentResponse, isFalse);
      expect(correlator.mutatesSecurityControls, isFalse);
      expect(correlator.invokesProvider, isFalse);
      expect(correlator.invokesTargetAgent, isFalse);
      expect(correlator.writesBusinessData, isFalse);
      expect(correlator.persistsSignalsOrAggregate, isFalse);
      expect(correlator.loadsCrossSubjectHistory, isFalse);
      expect(correlator.loadsFullConversationHistory, isFalse);
    });
  });
}
