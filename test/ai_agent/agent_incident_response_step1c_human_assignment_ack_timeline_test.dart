import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_guardian_security_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_incident_response_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_incident_response_human_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_human_assignment.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_record.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_timeline_event.dart';
import 'package:swat_ride/ai_agent/services/agent_security_incident_assignment_timeline_service.dart';

void main() {
  const AgentSecurityIncidentAssignmentTimelineService service =
      AgentSecurityIncidentAssignmentTimelineService();

  AgentSecurityIncidentRecord openIncident() {
    return AgentSecurityIncidentRecord(
      incidentId: 'incident_step1c_001',
      source: AgentSecurityIncidentSource.guardian,
      sourceReferenceId: 'guardian_corr_step1c_001',
      pseudonymousSubjectRef: 'subject_hash_step1c_001',
      status: AgentSecurityIncidentStatus.open,
      severity: AgentGuardianSeverity.high,
      evidenceConfidence: AgentGuardianEvidenceConfidence.high,
      createdAt: DateTime.utc(2026, 8, 19, 10, 30),
      updatedAt: DateTime.utc(2026, 8, 19, 10, 30),
      evidenceReferenceCodes: const <String>['guardian_corr_step1c_001'],
    );
  }

  AgentSecurityIncidentHumanAssignment assigned() {
    return service.assignResponder(
      assignmentId: 'assignment_step1c_001',
      incident: openIncident(),
      responderRef: 'responder_hash_step1c_001',
      assignedAt: DateTime.utc(2026, 8, 19, 10, 31),
    );
  }

  group('Phase 54 Step 1C human assignment + timeline', () {
    test('OPEN incident can receive pseudonymous human assignment', () {
      final AgentSecurityIncidentHumanAssignment assignment = assigned();

      expect(
        assignment.status,
        AgentSecurityIncidentAssignmentStatus.assignedAwaitingAcknowledgement,
      );
      expect(assignment.humanControlled, isTrue);
      expect(assignment.responderReferenceIsPseudonymous, isTrue);
      expect(assignment.grantsAuthority, isFalse);
    });

    test('assignment cannot predate incident creation', () {
      expect(
        () => service.assignResponder(
          assignmentId: 'assignment_early',
          incident: openIncident(),
          responderRef: 'responder_hash_early',
          assignedAt: DateTime.utc(2026, 8, 19, 10, 29),
        ),
        throwsA(isA<AgentSecurityIncidentAssignmentTimelineServiceException>()),
      );
    });

    test('assignment rejects unsupported lifecycle status', () {
      final AgentSecurityIncidentRecord closed = AgentSecurityIncidentRecord(
        incidentId: 'incident_closed',
        source: AgentSecurityIncidentSource.guardian,
        sourceReferenceId: 'guardian_corr_closed',
        pseudonymousSubjectRef: 'subject_hash_closed',
        status: AgentSecurityIncidentStatus.closed,
        severity: AgentGuardianSeverity.high,
        evidenceConfidence: AgentGuardianEvidenceConfidence.high,
        createdAt: DateTime.utc(2026, 8, 19, 10),
        updatedAt: DateTime.utc(2026, 8, 19, 10, 20),
        evidenceReferenceCodes: const <String>['safe_ref_closed'],
        resolvedAt: DateTime.utc(2026, 8, 19, 10, 15),
        closedAt: DateTime.utc(2026, 8, 19, 10, 20),
      );

      expect(
        () => service.assignResponder(
          assignmentId: 'assignment_closed',
          incident: closed,
          responderRef: 'responder_hash_closed',
          assignedAt: DateTime.utc(2026, 8, 19, 10, 21),
        ),
        throwsA(isA<AgentSecurityIncidentAssignmentTimelineServiceException>()),
      );
    });

    test('human acknowledgement must be explicit and after assignment', () {
      final AgentSecurityIncidentHumanAssignment acknowledged = service
          .acknowledgeAssignment(
            assignment: assigned(),
            acknowledgedAt: DateTime.utc(2026, 8, 19, 10, 32),
          );

      expect(acknowledged.isAcknowledged, isTrue);
      expect(acknowledged.acknowledgedAt, DateTime.utc(2026, 8, 19, 10, 32));
    });

    test('acknowledgement cannot predate assignment', () {
      expect(
        () => service.acknowledgeAssignment(
          assignment: assigned(),
          acknowledgedAt: DateTime.utc(2026, 8, 19, 10, 30),
        ),
        throwsA(isA<AgentSecurityIncidentHumanAssignmentException>()),
      );
    });

    test('already acknowledged assignment cannot be acknowledged twice', () {
      final AgentSecurityIncidentHumanAssignment acknowledged = service
          .acknowledgeAssignment(
            assignment: assigned(),
            acknowledgedAt: DateTime.utc(2026, 8, 19, 10, 32),
          );

      expect(
        () => service.acknowledgeAssignment(
          assignment: acknowledged,
          acknowledgedAt: DateTime.utc(2026, 8, 19, 10, 33),
        ),
        throwsA(isA<AgentSecurityIncidentAssignmentTimelineServiceException>()),
      );
    });

    test('acknowledged assignment can build ACKNOWLEDGED incident record', () {
      final AgentSecurityIncidentHumanAssignment acknowledged = service
          .acknowledgeAssignment(
            assignment: assigned(),
            acknowledgedAt: DateTime.utc(2026, 8, 19, 10, 32),
          );

      final AgentSecurityIncidentRecord record = service
          .buildAcknowledgedIncidentRecord(
            incident: openIncident(),
            assignment: acknowledged,
          );

      expect(record.status, AgentSecurityIncidentStatus.acknowledged);
      expect(record.assignedResponderRef, 'responder_hash_step1c_001');
      expect(record.acknowledgedAt, DateTime.utc(2026, 8, 19, 10, 32));
      expect(record.persistsRecord, isFalse);
    });

    test('unacknowledged assignment cannot create ACKNOWLEDGED record', () {
      expect(
        () => service.buildAcknowledgedIncidentRecord(
          incident: openIncident(),
          assignment: assigned(),
        ),
        throwsA(isA<AgentSecurityIncidentAssignmentTimelineServiceException>()),
      );
    });

    test('assignment timeline event contains metadata-only evidence', () {
      final AgentSecurityIncidentTimelineEvent event = service
          .buildAssignmentTimelineEvent(
            eventId: 'timeline_assignment_001',
            assignment: assigned(),
          );

      expect(
        event.eventType,
        AgentSecurityIncidentTimelineEventType.responderAssigned,
      );
      expect(event.metadataOnly, isTrue);
      expect(event.persistsTimelineEvent, isFalse);
      expect(event.evidenceReferenceCodes.length, 1);
    });

    test('acknowledgement timeline requires acknowledged assignment', () {
      expect(
        () => service.buildAcknowledgementTimelineEvent(
          eventId: 'timeline_ack_invalid',
          assignment: assigned(),
        ),
        throwsA(isA<AgentSecurityIncidentAssignmentTimelineServiceException>()),
      );
    });

    test('acknowledgement timeline event is metadata-only', () {
      final AgentSecurityIncidentHumanAssignment acknowledged = service
          .acknowledgeAssignment(
            assignment: assigned(),
            acknowledgedAt: DateTime.utc(2026, 8, 19, 10, 32),
          );

      final AgentSecurityIncidentTimelineEvent event = service
          .buildAcknowledgementTimelineEvent(
            eventId: 'timeline_ack_001',
            assignment: acknowledged,
          );

      expect(
        event.eventType,
        AgentSecurityIncidentTimelineEventType.responderAcknowledged,
      );
      expect(event.metadataOnly, isTrue);
      expect(event.actorReferenceIsPseudonymous, isTrue);
    });

    test('timeline evidence references are bounded to 8', () {
      final List<String> refs = List<String>.generate(
        9,
        (int index) => 'safe_ref_$index',
      );

      expect(
        () => service.buildEvidenceReferenceEvent(
          eventId: 'timeline_evidence_overflow',
          incidentId: 'incident_step1c_001',
          actorRef: 'responder_hash_step1c_001',
          occurredAt: DateTime.utc(2026, 8, 19, 10, 35),
          evidenceReferenceCodes: refs,
        ),
        throwsA(isA<AgentSecurityIncidentTimelineEventException>()),
      );
    });

    test('timeline rejects raw/private evidence flags', () {
      final AgentSecurityIncidentTimelineEvent unsafe =
          AgentSecurityIncidentTimelineEvent(
            eventId: 'timeline_unsafe',
            incidentId: 'incident_step1c_001',
            eventType:
                AgentSecurityIncidentTimelineEventType.evidenceReferenced,
            actorRef: 'responder_hash_step1c_001',
            occurredAt: DateTime.utc(2026, 8, 19, 10, 35),
            evidenceReferenceCodes: const <String>['safe_ref_001'],
            containsRawSecret: true,
          );

      expect(
        () => unsafe.validateStructure(),
        throwsA(isA<AgentSecurityIncidentTimelineEventException>()),
      );
    });

    test('assignment safe map exposes no raw responder identity/authority', () {
      final Map<String, dynamic> map = assigned().toSafeMap();

      expect(map['rawResponderIdentityIncluded'], isFalse);
      expect(map['humanControlled'], isTrue);
      expect(map['grantsAuthority'], isFalse);
      expect(map['grantsPermission'], isFalse);
      expect(map['executesContainment'], isFalse);
      expect(map['persistsAssignment'], isFalse);
    });

    test('timeline safe map exposes no raw/private payload', () {
      final Map<String, dynamic> map = service
          .buildAssignmentTimelineEvent(
            eventId: 'timeline_safe_map',
            assignment: assigned(),
          )
          .toSafeMap();

      expect(map['rawPromptIncluded'], isFalse);
      expect(map['rawMessageHistoryIncluded'], isFalse);
      expect(map['rawSecretIncluded'], isFalse);
      expect(map['paymentCredentialIncluded'], isFalse);
      expect(map['authTokenIncluded'], isFalse);
      expect(map['privatePayloadIncluded'], isFalse);
      expect(map['persistsTimelineEvent'], isFalse);
    });

    test('service cannot grant authority or execute response actions', () {
      expect(service.humanAssignmentAndTimelineOnly, isTrue);
      expect(service.grantsResponderAuthority, isFalse);
      expect(service.autoAssignsResponder, isFalse);
      expect(service.sendsResponderNotification, isFalse);
      expect(service.invokesPermissionEngine, isFalse);
      expect(service.invokesApprovalEngine, isFalse);
      expect(service.invokesRuntimeGate, isFalse);
      expect(service.invokesEmergencyStop, isFalse);
      expect(service.bypassesAuthoritativeControls, isFalse);
      expect(service.executesContainment, isFalse);
      expect(service.executesRemediation, isFalse);
      expect(service.executesRecoveryAction, isFalse);
      expect(service.invokesProvider, isFalse);
      expect(service.invokesTargetAgent, isFalse);
      expect(service.writesBusinessData, isFalse);
      expect(service.persistsAssignment, isFalse);
      expect(service.persistsTimeline, isFalse);
      expect(service.implementsPhase63PrivacyUi, isFalse);
    });
  });
}
