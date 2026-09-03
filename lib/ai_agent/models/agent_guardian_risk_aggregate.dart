import 'agent_guardian_risk_decision.dart';

class AgentGuardianRiskAggregateStatus {
  AgentGuardianRiskAggregateStatus._();

  static const String ready = 'READY';
  static const String readyWithRejections = 'READY_WITH_REJECTIONS';
  static const String blocked = 'BLOCKED';
}

class AgentGuardianCorrelationRejectReason {
  AgentGuardianCorrelationRejectReason._();

  static const String invalidRequest = 'invalid_correlation_request';
  static const String invalidEvent = 'invalid_guardian_event';
  static const String subjectUnbound = 'subject_unbound';
  static const String subjectMismatch = 'cross_subject_signal_rejected';
  static const String outsideWindow = 'signal_outside_window';
  static const String duplicateEventId = 'duplicate_event_id';
  static const String replayDuplicateSignal = 'replay_duplicate_signal';
  static const String noAcceptedSignals = 'no_accepted_signals';
}

class AgentGuardianCorrelationReason {
  AgentGuardianCorrelationReason._();

  static const String highestIndividualSeverity = 'highest_individual_severity';

  static const String independentMultiSignalElevation =
      'independent_multi_signal_elevation';

  static const String independentCriticalCorrelation =
      'independent_critical_correlation';

  static const String duplicateReplaySuppressed = 'duplicate_replay_suppressed';

  static const String crossSubjectSuppressed = 'cross_subject_suppressed';

  static const String invalidSignalSuppressed = 'invalid_signal_suppressed';
}

class AgentGuardianRiskAggregate {
  AgentGuardianRiskAggregate({
    required this.status,
    required this.correlationId,
    required this.pseudonymousSubjectRef,
    required this.severity,
    required this.evidenceConfidence,
    required this.recommendedDisposition,
    required List<AgentGuardianRiskDecision> acceptedDecisions,
    required Map<String, String> rejectedReasonByEventId,
    required List<String> reasonCodes,
    required this.duplicateEventCount,
    required this.replayDuplicateSignalCount,
    required this.crossSubjectRejectedCount,
    required this.invalidSignalRejectedCount,
    required this.outsideWindowRejectedCount,
    required this.distinctCategoryCount,
    required this.distinctSourceComponentCount,
    required this.elevatedByCorrelation,
  }) : acceptedDecisions = List<AgentGuardianRiskDecision>.unmodifiable(
         acceptedDecisions,
       ),
       rejectedReasonByEventId = Map<String, String>.unmodifiable(
         rejectedReasonByEventId,
       ),
       reasonCodes = List<String>.unmodifiable(reasonCodes);

  final String status;
  final String correlationId;
  final String pseudonymousSubjectRef;
  final String severity;
  final String evidenceConfidence;
  final String recommendedDisposition;

  /// Decisions only; raw Guardian events are intentionally not retained here.
  final List<AgentGuardianRiskDecision> acceptedDecisions;
  final Map<String, String> rejectedReasonByEventId;
  final List<String> reasonCodes;

  final int duplicateEventCount;
  final int replayDuplicateSignalCount;
  final int crossSubjectRejectedCount;
  final int invalidSignalRejectedCount;
  final int outsideWindowRejectedCount;
  final int distinctCategoryCount;
  final int distinctSourceComponentCount;
  final bool elevatedByCorrelation;

  bool get ready =>
      status == AgentGuardianRiskAggregateStatus.ready ||
      status == AgentGuardianRiskAggregateStatus.readyWithRejections;

  bool get blocked => status == AgentGuardianRiskAggregateStatus.blocked;

  bool get hasRejections => rejectedReasonByEventId.isNotEmpty;

  bool get recommendationOnly => true;
  bool get guardianIsFinalEnforcer => false;
  bool get grantsAuthority => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get executesBlock => false;
  bool get executesEscalation => false;
  bool get createsIncident => false;
  bool get invokesProvider => false;
  bool get invokesTargetAgent => false;
  bool get invokesRuntimeGate => false;
  bool get mutatesSecurityControls => false;
  bool get writesBusinessData => false;
  bool get persistsAggregate => false;
  bool get containsRawGuardianEvents => false;

  Map<String, dynamic> toSafeMap() {
    return Map<String, dynamic>.unmodifiable(<String, dynamic>{
      'status': status,
      'correlationId': correlationId,
      'pseudonymousSubjectRef': pseudonymousSubjectRef,
      'severity': severity,
      'evidenceConfidence': evidenceConfidence,
      'recommendedDisposition': recommendedDisposition,
      'acceptedEventIds': List<String>.unmodifiable(
        acceptedDecisions
            .map((AgentGuardianRiskDecision decision) => decision.eventId)
            .toList(),
      ),
      'acceptedSignalCount': acceptedDecisions.length,
      'rejectedReasonByEventId': Map<String, String>.unmodifiable(
        rejectedReasonByEventId,
      ),
      'reasonCodes': List<String>.unmodifiable(reasonCodes),
      'duplicateEventCount': duplicateEventCount,
      'replayDuplicateSignalCount': replayDuplicateSignalCount,
      'crossSubjectRejectedCount': crossSubjectRejectedCount,
      'invalidSignalRejectedCount': invalidSignalRejectedCount,
      'outsideWindowRejectedCount': outsideWindowRejectedCount,
      'distinctCategoryCount': distinctCategoryCount,
      'distinctSourceComponentCount': distinctSourceComponentCount,
      'elevatedByCorrelation': elevatedByCorrelation,
      'rawGuardianEventsIncluded': false,
      'recommendationOnly': true,
      'guardianIsFinalEnforcer': false,
      'grantsAuthority': false,
      'grantsPermission': false,
      'consumesApproval': false,
      'executesBlock': false,
      'executesEscalation': false,
      'createsIncident': false,
      'invokesProvider': false,
      'invokesTargetAgent': false,
      'invokesRuntimeGate': false,
      'mutatesSecurityControls': false,
      'writesBusinessData': false,
      'persistsAggregate': false,
    });
  }
}
