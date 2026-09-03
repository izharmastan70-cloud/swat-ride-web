class AgentSecurityIncidentAssignmentStatus {
  AgentSecurityIncidentAssignmentStatus._();

  static const String assignedAwaitingAcknowledgement =
      'ASSIGNED_AWAITING_ACKNOWLEDGEMENT';

  static const String acknowledged = 'ACKNOWLEDGED';

  static const Set<String> values = <String>{
    assignedAwaitingAcknowledgement,
    acknowledged,
  };
}

class AgentSecurityIncidentTimelineEventType {
  AgentSecurityIncidentTimelineEventType._();

  static const String incidentOpened = 'INCIDENT_OPENED';
  static const String responderAssigned = 'RESPONDER_ASSIGNED';
  static const String responderAcknowledged = 'RESPONDER_ACKNOWLEDGED';
  static const String triageRecorded = 'TRIAGE_RECORDED';
  static const String evidenceReferenced = 'EVIDENCE_REFERENCED';

  static const Set<String> values = <String>{
    incidentOpened,
    responderAssigned,
    responderAcknowledged,
    triageRecorded,
    evidenceReferenced,
  };
}

class AgentSecurityIncidentHumanReason {
  AgentSecurityIncidentHumanReason._();

  static const String humanAssignmentRequired = 'human_assignment_required';

  static const String responderReferencePseudonymous =
      'responder_reference_pseudonymous';

  static const String acknowledgementExplicit = 'acknowledgement_explicit';

  static const String timelineMetadataOnly = 'timeline_metadata_only';

  static const String noAuthorityGranted = 'no_authority_granted';

  static const Set<String> values = <String>{
    humanAssignmentRequired,
    responderReferencePseudonymous,
    acknowledgementExplicit,
    timelineMetadataOnly,
    noAuthorityGranted,
  };
}
