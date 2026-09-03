import '../constants/agent_incident_response_constants.dart';
import '../constants/agent_incident_response_human_constants.dart';
import '../models/agent_security_incident_human_assignment.dart';
import '../models/agent_security_incident_record.dart';
import '../models/agent_security_incident_timeline_event.dart';
import 'agent_security_incident_triage_service.dart';

class AgentSecurityIncidentAssignmentTimelineService {
  const AgentSecurityIncidentAssignmentTimelineService({
    this.triageService = const AgentSecurityIncidentTriageService(),
  });

  final AgentSecurityIncidentTriageService triageService;

  AgentSecurityIncidentHumanAssignment assignResponder({
    required String assignmentId,
    required AgentSecurityIncidentRecord incident,
    required String responderRef,
    required DateTime assignedAt,
  }) {
    incident.validateStructure();

    if (incident.status != AgentSecurityIncidentStatus.open &&
        incident.status != AgentSecurityIncidentStatus.triaged) {
      throw const AgentSecurityIncidentAssignmentTimelineServiceException(
        'Responder assignment requires OPEN or TRIAGED incident.',
      );
    }

    if (assignedAt.isBefore(incident.createdAt)) {
      throw const AgentSecurityIncidentAssignmentTimelineServiceException(
        'Responder assignment cannot predate incident creation.',
      );
    }

    final AgentSecurityIncidentHumanAssignment assignment =
        AgentSecurityIncidentHumanAssignment(
          assignmentId: assignmentId,
          incidentId: incident.incidentId,
          responderRef: responderRef,
          status: AgentSecurityIncidentAssignmentStatus
              .assignedAwaitingAcknowledgement,
          assignedAt: assignedAt,
          reasonCodes: const <String>[
            AgentSecurityIncidentHumanReason.humanAssignmentRequired,
            AgentSecurityIncidentHumanReason.responderReferencePseudonymous,
            AgentSecurityIncidentHumanReason.noAuthorityGranted,
          ],
        );

    assignment.validateStructure();
    return assignment;
  }

  AgentSecurityIncidentHumanAssignment acknowledgeAssignment({
    required AgentSecurityIncidentHumanAssignment assignment,
    required DateTime acknowledgedAt,
  }) {
    assignment.validateStructure();

    if (assignment.isAcknowledged) {
      throw const AgentSecurityIncidentAssignmentTimelineServiceException(
        'Incident assignment is already acknowledged.',
      );
    }

    final AgentSecurityIncidentHumanAssignment acknowledged =
        AgentSecurityIncidentHumanAssignment(
          assignmentId: assignment.assignmentId,
          incidentId: assignment.incidentId,
          responderRef: assignment.responderRef,
          status: AgentSecurityIncidentAssignmentStatus.acknowledged,
          assignedAt: assignment.assignedAt,
          acknowledgedAt: acknowledgedAt,
          reasonCodes: const <String>[
            AgentSecurityIncidentHumanReason.humanAssignmentRequired,
            AgentSecurityIncidentHumanReason.responderReferencePseudonymous,
            AgentSecurityIncidentHumanReason.acknowledgementExplicit,
            AgentSecurityIncidentHumanReason.noAuthorityGranted,
          ],
        );

    acknowledged.validateStructure();
    return acknowledged;
  }

  AgentSecurityIncidentRecord buildAcknowledgedIncidentRecord({
    required AgentSecurityIncidentRecord incident,
    required AgentSecurityIncidentHumanAssignment assignment,
  }) {
    incident.validateStructure();
    assignment.validateStructure();

    if (!assignment.isAcknowledged ||
        assignment.incidentId != incident.incidentId ||
        assignment.acknowledgedAt == null) {
      throw const AgentSecurityIncidentAssignmentTimelineServiceException(
        'Acknowledged assignment is not bound to the incident.',
      );
    }

    if (!triageService.canTransition(
      currentStatus: incident.status,
      nextStatus: AgentSecurityIncidentStatus.acknowledged,
    )) {
      throw const AgentSecurityIncidentAssignmentTimelineServiceException(
        'Incident lifecycle does not permit acknowledgement transition.',
      );
    }

    final AgentSecurityIncidentRecord updated = AgentSecurityIncidentRecord(
      incidentId: incident.incidentId,
      source: incident.source,
      sourceReferenceId: incident.sourceReferenceId,
      pseudonymousSubjectRef: incident.pseudonymousSubjectRef,
      status: AgentSecurityIncidentStatus.acknowledged,
      severity: incident.severity,
      evidenceConfidence: incident.evidenceConfidence,
      createdAt: incident.createdAt,
      updatedAt: assignment.acknowledgedAt!,
      evidenceReferenceCodes: incident.evidenceReferenceCodes,
      assignedResponderRef: assignment.responderRef,
      acknowledgedAt: assignment.acknowledgedAt,
    );

    updated.validateStructure();
    return updated;
  }

  AgentSecurityIncidentTimelineEvent buildAssignmentTimelineEvent({
    required String eventId,
    required AgentSecurityIncidentHumanAssignment assignment,
  }) {
    assignment.validateStructure();

    final AgentSecurityIncidentTimelineEvent event =
        AgentSecurityIncidentTimelineEvent(
          eventId: eventId,
          incidentId: assignment.incidentId,
          eventType: AgentSecurityIncidentTimelineEventType.responderAssigned,
          actorRef: assignment.responderRef,
          occurredAt: assignment.assignedAt,
          evidenceReferenceCodes: <String>[assignment.assignmentId],
        );

    event.validateStructure();
    return event;
  }

  AgentSecurityIncidentTimelineEvent buildAcknowledgementTimelineEvent({
    required String eventId,
    required AgentSecurityIncidentHumanAssignment assignment,
  }) {
    assignment.validateStructure();

    if (!assignment.isAcknowledged || assignment.acknowledgedAt == null) {
      throw const AgentSecurityIncidentAssignmentTimelineServiceException(
        'Acknowledgement timeline requires acknowledged assignment.',
      );
    }

    final AgentSecurityIncidentTimelineEvent event =
        AgentSecurityIncidentTimelineEvent(
          eventId: eventId,
          incidentId: assignment.incidentId,
          eventType:
              AgentSecurityIncidentTimelineEventType.responderAcknowledged,
          actorRef: assignment.responderRef,
          occurredAt: assignment.acknowledgedAt!,
          evidenceReferenceCodes: <String>[assignment.assignmentId],
        );

    event.validateStructure();
    return event;
  }

  AgentSecurityIncidentTimelineEvent buildEvidenceReferenceEvent({
    required String eventId,
    required String incidentId,
    required String actorRef,
    required DateTime occurredAt,
    required List<String> evidenceReferenceCodes,
  }) {
    final AgentSecurityIncidentTimelineEvent event =
        AgentSecurityIncidentTimelineEvent(
          eventId: eventId,
          incidentId: incidentId,
          eventType: AgentSecurityIncidentTimelineEventType.evidenceReferenced,
          actorRef: actorRef,
          occurredAt: occurredAt,
          evidenceReferenceCodes: evidenceReferenceCodes,
        );

    event.validateStructure();
    return event;
  }

  bool get humanAssignmentAndTimelineOnly => true;
  bool get grantsResponderAuthority => false;
  bool get autoAssignsResponder => false;
  bool get sendsResponderNotification => false;
  bool get invokesPermissionEngine => false;
  bool get invokesApprovalEngine => false;
  bool get invokesRuntimeGate => false;
  bool get invokesEmergencyStop => false;
  bool get bypassesAuthoritativeControls => false;
  bool get executesContainment => false;
  bool get executesRemediation => false;
  bool get executesRecoveryAction => false;
  bool get invokesProvider => false;
  bool get invokesTargetAgent => false;
  bool get writesBusinessData => false;
  bool get persistsAssignment => false;
  bool get persistsTimeline => false;
  bool get implementsPhase63PrivacyUi => false;
}

class AgentSecurityIncidentAssignmentTimelineServiceException
    implements Exception {
  const AgentSecurityIncidentAssignmentTimelineServiceException(this.message);

  final String message;

  @override
  String toString() =>
      'AgentSecurityIncidentAssignmentTimelineServiceException: $message';
}
