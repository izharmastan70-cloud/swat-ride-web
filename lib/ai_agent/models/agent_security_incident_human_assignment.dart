import '../constants/agent_incident_response_human_constants.dart';

class AgentSecurityIncidentHumanAssignment {
  AgentSecurityIncidentHumanAssignment({
    required this.assignmentId,
    required this.incidentId,
    required this.responderRef,
    required this.status,
    required this.assignedAt,
    required List<String> reasonCodes,
    this.acknowledgedAt,
  }) : reasonCodes = List<String>.unmodifiable(reasonCodes);

  final String assignmentId;
  final String incidentId;
  final String responderRef;
  final String status;
  final DateTime assignedAt;
  final DateTime? acknowledgedAt;
  final List<String> reasonCodes;

  bool get humanControlled => true;
  bool get responderReferenceIsPseudonymous => true;
  bool get grantsAuthority => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get marksRuntimeAllowed => false;
  bool get invokesPermissionEngine => false;
  bool get invokesApprovalEngine => false;
  bool get invokesRuntimeGate => false;
  bool get invokesEmergencyStop => false;
  bool get executesContainment => false;
  bool get executesRemediation => false;
  bool get executesRecoveryAction => false;
  bool get invokesProvider => false;
  bool get writesBusinessData => false;
  bool get persistsAssignment => false;

  bool get isAcknowledged =>
      status == AgentSecurityIncidentAssignmentStatus.acknowledged;

  void validateStructure() {
    final RegExp safeId = RegExp(r'^[A-Za-z0-9._:-]{1,160}$');

    if (!safeId.hasMatch(assignmentId) ||
        !safeId.hasMatch(incidentId) ||
        !safeId.hasMatch(responderRef)) {
      throw const AgentSecurityIncidentHumanAssignmentException(
        'Incident human assignment identifiers are invalid.',
      );
    }

    if (!AgentSecurityIncidentAssignmentStatus.values.contains(status)) {
      throw const AgentSecurityIncidentHumanAssignmentException(
        'Incident assignment status is invalid.',
      );
    }

    if (reasonCodes.isEmpty || reasonCodes.length > 8) {
      throw const AgentSecurityIncidentHumanAssignmentException(
        'Incident assignment requires 1 to 8 bounded reason codes.',
      );
    }

    for (final String reason in reasonCodes) {
      if (!safeId.hasMatch(reason) ||
          !AgentSecurityIncidentHumanReason.values.contains(reason)) {
        throw const AgentSecurityIncidentHumanAssignmentException(
          'Incident assignment reason code is invalid.',
        );
      }
    }

    if (acknowledgedAt != null && acknowledgedAt!.isBefore(assignedAt)) {
      throw const AgentSecurityIncidentHumanAssignmentException(
        'Incident acknowledgement cannot predate assignment.',
      );
    }

    if (status == AgentSecurityIncidentAssignmentStatus.acknowledged &&
        acknowledgedAt == null) {
      throw const AgentSecurityIncidentHumanAssignmentException(
        'Acknowledged assignment requires acknowledgement time.',
      );
    }

    if (status ==
            AgentSecurityIncidentAssignmentStatus
                .assignedAwaitingAcknowledgement &&
        acknowledgedAt != null) {
      throw const AgentSecurityIncidentHumanAssignmentException(
        'Awaiting acknowledgement assignment cannot have acknowledgement time.',
      );
    }
  }

  Map<String, dynamic> toSafeMap() {
    validateStructure();

    return Map<String, dynamic>.unmodifiable(<String, dynamic>{
      'assignmentId': assignmentId,
      'incidentId': incidentId,
      'responderRef': responderRef,
      'status': status,
      'assignedAt': assignedAt.toUtc().toIso8601String(),
      'acknowledgedAt': acknowledgedAt?.toUtc().toIso8601String(),
      'reasonCodes': List<String>.unmodifiable(reasonCodes),
      'humanControlled': true,
      'responderReferenceIsPseudonymous': true,
      'rawResponderIdentityIncluded': false,
      'grantsAuthority': false,
      'grantsPermission': false,
      'consumesApproval': false,
      'marksRuntimeAllowed': false,
      'invokesPermissionEngine': false,
      'invokesApprovalEngine': false,
      'invokesRuntimeGate': false,
      'invokesEmergencyStop': false,
      'executesContainment': false,
      'executesRemediation': false,
      'executesRecoveryAction': false,
      'invokesProvider': false,
      'writesBusinessData': false,
      'persistsAssignment': false,
    });
  }
}

class AgentSecurityIncidentHumanAssignmentException implements Exception {
  const AgentSecurityIncidentHumanAssignmentException(this.message);

  final String message;

  @override
  String toString() =>
      'AgentSecurityIncidentHumanAssignmentException: $message';
}
