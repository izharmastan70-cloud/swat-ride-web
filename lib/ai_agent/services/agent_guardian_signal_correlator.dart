import '../constants/agent_guardian_security_constants.dart';
import '../models/agent_guardian_correlation_request.dart';
import '../models/agent_guardian_risk_aggregate.dart';
import '../models/agent_guardian_risk_decision.dart';
import '../models/agent_guardian_security_event.dart';
import 'agent_guardian_risk_classifier.dart';

class AgentGuardianSignalCorrelator {
  const AgentGuardianSignalCorrelator({
    this._classifier = const AgentGuardianRiskClassifier(),
  });

  final AgentGuardianRiskClassifier _classifier;

  AgentGuardianRiskAggregate correlate(
    AgentGuardianCorrelationRequest request,
  ) {
    try {
      request.validateStructure();
    } on AgentGuardianCorrelationRequestException {
      return _blocked(
        request: request,
        reasonCode: AgentGuardianCorrelationRejectReason.invalidRequest,
      );
    }

    final Set<String> seenEventIds = <String>{};
    final Set<String> seenSemanticFingerprints = <String>{};

    final List<AgentGuardianRiskDecision> accepted =
        <AgentGuardianRiskDecision>[];

    final Map<String, String> rejected = <String, String>{};

    final List<String> reasons = <String>[
      AgentGuardianCorrelationReason.highestIndividualSeverity,
    ];

    final Set<String> categories = <String>{};
    final Set<String> sourceComponents = <String>{};

    int duplicateEventCount = 0;
    int replayDuplicateSignalCount = 0;
    int crossSubjectRejectedCount = 0;
    int invalidSignalRejectedCount = 0;
    int outsideWindowRejectedCount = 0;

    final DateTime windowStart = request.windowStart.toUtc();
    final DateTime windowEnd = request.windowEnd.toUtc();

    for (final AgentGuardianSecurityEvent event in request.events) {
      if (!seenEventIds.add(event.eventId)) {
        duplicateEventCount += 1;
        rejected[event.eventId] =
            AgentGuardianCorrelationRejectReason.duplicateEventId;
        continue;
      }

      try {
        event.validateStructure();
      } on AgentGuardianSecurityEventException {
        invalidSignalRejectedCount += 1;
        rejected[event.eventId] =
            AgentGuardianCorrelationRejectReason.invalidEvent;
        continue;
      }

      final String? eventSubject = event.pseudonymousSubjectRef;

      if (eventSubject == null || eventSubject.trim().isEmpty) {
        crossSubjectRejectedCount += 1;
        rejected[event.eventId] =
            AgentGuardianCorrelationRejectReason.subjectUnbound;
        continue;
      }

      if (eventSubject != request.pseudonymousSubjectRef) {
        crossSubjectRejectedCount += 1;
        rejected[event.eventId] =
            AgentGuardianCorrelationRejectReason.subjectMismatch;
        continue;
      }

      final DateTime occurredAt = event.occurredAt.toUtc();

      if (occurredAt.isBefore(windowStart) || occurredAt.isAfter(windowEnd)) {
        outsideWindowRejectedCount += 1;
        rejected[event.eventId] =
            AgentGuardianCorrelationRejectReason.outsideWindow;
        continue;
      }

      final String fingerprint = _semanticFingerprint(event);

      if (!seenSemanticFingerprints.add(fingerprint)) {
        replayDuplicateSignalCount += 1;
        rejected[event.eventId] =
            AgentGuardianCorrelationRejectReason.replayDuplicateSignal;
        continue;
      }

      final AgentGuardianRiskDecision decision = _classifier.classify(event);

      if (!decision.classified) {
        invalidSignalRejectedCount += 1;
        rejected[event.eventId] =
            AgentGuardianCorrelationRejectReason.invalidEvent;
        continue;
      }

      accepted.add(decision);
      categories.add(event.category);
      sourceComponents.add(event.sourceComponent);
    }

    if (duplicateEventCount > 0 || replayDuplicateSignalCount > 0) {
      reasons.add(AgentGuardianCorrelationReason.duplicateReplaySuppressed);
    }

    if (crossSubjectRejectedCount > 0) {
      reasons.add(AgentGuardianCorrelationReason.crossSubjectSuppressed);
    }

    if (invalidSignalRejectedCount > 0) {
      reasons.add(AgentGuardianCorrelationReason.invalidSignalSuppressed);
    }

    if (accepted.isEmpty) {
      return AgentGuardianRiskAggregate(
        status: AgentGuardianRiskAggregateStatus.blocked,
        correlationId: request.correlationId,
        pseudonymousSubjectRef: request.pseudonymousSubjectRef,
        severity: AgentGuardianSeverity.high,
        evidenceConfidence: AgentGuardianEvidenceConfidence.low,
        recommendedDisposition:
            AgentGuardianRecommendedDisposition.reviewAndEscalate,
        acceptedDecisions: const <AgentGuardianRiskDecision>[],
        rejectedReasonByEventId: rejected,
        reasonCodes: <String>[
          ...reasons,
          AgentGuardianCorrelationRejectReason.noAcceptedSignals,
        ],
        duplicateEventCount: duplicateEventCount,
        replayDuplicateSignalCount: replayDuplicateSignalCount,
        crossSubjectRejectedCount: crossSubjectRejectedCount,
        invalidSignalRejectedCount: invalidSignalRejectedCount,
        outsideWindowRejectedCount: outsideWindowRejectedCount,
        distinctCategoryCount: 0,
        distinctSourceComponentCount: 0,
        elevatedByCorrelation: false,
      );
    }

    final String baseSeverity = _highestSeverity(
      accepted.map((AgentGuardianRiskDecision decision) => decision.severity),
    );

    String aggregateSeverity = baseSeverity;
    bool elevatedByCorrelation = false;

    final bool independentMultiSignal =
        accepted.length >= 2 &&
        categories.length >= 2 &&
        sourceComponents.length >= 2;

    if (independentMultiSignal &&
        aggregateSeverity == AgentGuardianSeverity.low) {
      aggregateSeverity = AgentGuardianSeverity.medium;
      elevatedByCorrelation = true;
      reasons.add(
        AgentGuardianCorrelationReason.independentMultiSignalElevation,
      );
    } else if (independentMultiSignal &&
        aggregateSeverity == AgentGuardianSeverity.medium) {
      aggregateSeverity = AgentGuardianSeverity.high;
      elevatedByCorrelation = true;
      reasons.add(
        AgentGuardianCorrelationReason.independentMultiSignalElevation,
      );
    }

    final bool independentCriticalPattern =
        accepted.length >= 3 &&
        categories.length >= 3 &&
        sourceComponents.length >= 2;

    if (independentCriticalPattern &&
        aggregateSeverity == AgentGuardianSeverity.high) {
      aggregateSeverity = AgentGuardianSeverity.critical;
      elevatedByCorrelation = true;
      reasons.add(
        AgentGuardianCorrelationReason.independentCriticalCorrelation,
      );
    }

    final String confidence = _highestConfidence(
      accepted.map(
        (AgentGuardianRiskDecision decision) => decision.evidenceConfidence,
      ),
    );

    final String disposition = _recommendedDisposition(
      severity: aggregateSeverity,
      evidenceConfidence: confidence,
    );

    return AgentGuardianRiskAggregate(
      status: rejected.isEmpty
          ? AgentGuardianRiskAggregateStatus.ready
          : AgentGuardianRiskAggregateStatus.readyWithRejections,
      correlationId: request.correlationId,
      pseudonymousSubjectRef: request.pseudonymousSubjectRef,
      severity: aggregateSeverity,
      evidenceConfidence: confidence,
      recommendedDisposition: disposition,
      acceptedDecisions: accepted,
      rejectedReasonByEventId: rejected,
      reasonCodes: reasons,
      duplicateEventCount: duplicateEventCount,
      replayDuplicateSignalCount: replayDuplicateSignalCount,
      crossSubjectRejectedCount: crossSubjectRejectedCount,
      invalidSignalRejectedCount: invalidSignalRejectedCount,
      outsideWindowRejectedCount: outsideWindowRejectedCount,
      distinctCategoryCount: categories.length,
      distinctSourceComponentCount: sourceComponents.length,
      elevatedByCorrelation: elevatedByCorrelation,
    );
  }

  String _semanticFingerprint(AgentGuardianSecurityEvent event) {
    final List<String> evidenceCodes = event.evidenceCodes.toList()..sort();

    return <String>[
      event.pseudonymousSubjectRef ?? 'UNBOUND',
      event.category,
      event.evidenceTrust,
      event.sourceComponent,
      event.sourceChannel ?? 'NO_CHANNEL',
      event.agentRoleId ?? 'NO_ROLE',
      event.targetActionId ?? 'NO_ACTION',
      event.occurredAt.toUtc().toIso8601String(),
      evidenceCodes.join(','),
      event.highImpactActionTargeted.toString(),
      event.repeatedWithinWindow.toString(),
      event.activeExploitEvidence.toString(),
      event.existingAuthoritativeGateBlocked.toString(),
    ].join('|');
  }

  String _highestSeverity(Iterable<String> severities) {
    int bestRank = -1;
    String best = AgentGuardianSeverity.low;

    for (final String severity in severities) {
      final int rank = _severityRank(severity);
      if (rank > bestRank) {
        bestRank = rank;
        best = severity;
      }
    }

    return best;
  }

  int _severityRank(String severity) {
    switch (severity) {
      case AgentGuardianSeverity.low:
        return 0;
      case AgentGuardianSeverity.medium:
        return 1;
      case AgentGuardianSeverity.high:
        return 2;
      case AgentGuardianSeverity.critical:
        return 3;
      default:
        return 2;
    }
  }

  String _highestConfidence(Iterable<String> confidences) {
    if (confidences.contains(AgentGuardianEvidenceConfidence.high)) {
      return AgentGuardianEvidenceConfidence.high;
    }

    if (confidences.contains(AgentGuardianEvidenceConfidence.medium)) {
      return AgentGuardianEvidenceConfidence.medium;
    }

    return AgentGuardianEvidenceConfidence.low;
  }

  String _recommendedDisposition({
    required String severity,
    required String evidenceConfidence,
  }) {
    if (severity == AgentGuardianSeverity.critical) {
      if (evidenceConfidence == AgentGuardianEvidenceConfidence.high) {
        return AgentGuardianRecommendedDisposition.blockAndEscalateRecommended;
      }

      return AgentGuardianRecommendedDisposition.reviewAndEscalate;
    }

    if (severity == AgentGuardianSeverity.high) {
      if (evidenceConfidence == AgentGuardianEvidenceConfidence.high) {
        return AgentGuardianRecommendedDisposition.blockRecommended;
      }

      return AgentGuardianRecommendedDisposition.reviewAndEscalate;
    }

    if (severity == AgentGuardianSeverity.medium) {
      return AgentGuardianRecommendedDisposition.review;
    }

    return AgentGuardianRecommendedDisposition.observe;
  }

  AgentGuardianRiskAggregate _blocked({
    required AgentGuardianCorrelationRequest request,
    required String reasonCode,
  }) {
    return AgentGuardianRiskAggregate(
      status: AgentGuardianRiskAggregateStatus.blocked,
      correlationId: request.correlationId,
      pseudonymousSubjectRef: request.pseudonymousSubjectRef,
      severity: AgentGuardianSeverity.high,
      evidenceConfidence: AgentGuardianEvidenceConfidence.low,
      recommendedDisposition:
          AgentGuardianRecommendedDisposition.reviewAndEscalate,
      acceptedDecisions: const <AgentGuardianRiskDecision>[],
      rejectedReasonByEventId: const <String, String>{},
      reasonCodes: <String>[reasonCode],
      duplicateEventCount: 0,
      replayDuplicateSignalCount: 0,
      crossSubjectRejectedCount: 0,
      invalidSignalRejectedCount: 0,
      outsideWindowRejectedCount: 0,
      distinctCategoryCount: 0,
      distinctSourceComponentCount: 0,
      elevatedByCorrelation: false,
    );
  }

  bool get recommendationOnly => true;
  bool get guardianIsFinalEnforcer => false;
  bool get invokesPermissionEngine => false;
  bool get invokesApprovalEngine => false;
  bool get invokesRuntimeGate => false;
  bool get invokesEmergencyStop => false;
  bool get executesBlock => false;
  bool get executesEscalation => false;
  bool get createsIncident => false;
  bool get implementsIncidentResponse => false;
  bool get mutatesSecurityControls => false;
  bool get invokesProvider => false;
  bool get invokesTargetAgent => false;
  bool get writesBusinessData => false;
  bool get persistsSignalsOrAggregate => false;
  bool get loadsCrossSubjectHistory => false;
  bool get loadsFullConversationHistory => false;
}
