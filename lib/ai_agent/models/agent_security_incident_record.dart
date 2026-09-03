import '../constants/agent_guardian_security_constants.dart';
import '../constants/agent_incident_response_constants.dart';

class AgentSecurityIncidentRecord {
  AgentSecurityIncidentRecord({
    required this.incidentId,
    required this.source,
    required this.sourceReferenceId,
    required this.pseudonymousSubjectRef,
    required this.status,
    required this.severity,
    required this.evidenceConfidence,
    required this.createdAt,
    required this.updatedAt,
    required List<String> evidenceReferenceCodes,
    this.assignedResponderRef,
    this.acknowledgedAt,
    this.triagedAt,
    this.resolvedAt,
    this.closedAt,
    this.containsRawPrompt = false,
    this.containsRawMessageHistory = false,
    this.containsRawSecret = false,
    this.containsPaymentCredential = false,
    this.containsAuthToken = false,
    this.containsPrivatePayload = false,
  }) : evidenceReferenceCodes = List<String>.unmodifiable(
         evidenceReferenceCodes,
       );

  final String incidentId;
  final String source;
  final String sourceReferenceId;
  final String pseudonymousSubjectRef;

  final String status;
  final String severity;
  final String evidenceConfidence;

  final DateTime createdAt;
  final DateTime updatedAt;

  final List<String> evidenceReferenceCodes;

  final String? assignedResponderRef;
  final DateTime? acknowledgedAt;
  final DateTime? triagedAt;
  final DateTime? resolvedAt;
  final DateTime? closedAt;

  final bool containsRawPrompt;
  final bool containsRawMessageHistory;
  final bool containsRawSecret;
  final bool containsPaymentCredential;
  final bool containsAuthToken;
  final bool containsPrivatePayload;

  bool get privacyMinimizedEvidenceOnly => true;
  bool get recommendationAndLifecycleOnly => true;
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
  bool get invokesTargetAgent => false;
  bool get writesBusinessData => false;
  bool get persistsRecord => false;

  bool get isClosed => status == AgentSecurityIncidentStatus.closed;

  bool get requiresHumanResponder =>
      severity == AgentGuardianSeverity.high ||
      severity == AgentGuardianSeverity.critical;

  void validateStructure() {
    final RegExp safeId = RegExp(r'^[A-Za-z0-9._:-]{1,160}$');

    if (!safeId.hasMatch(incidentId) ||
        !safeId.hasMatch(sourceReferenceId) ||
        !safeId.hasMatch(pseudonymousSubjectRef)) {
      throw const AgentSecurityIncidentRecordException(
        'Incident identifiers are invalid.',
      );
    }

    if (!AgentSecurityIncidentSource.values.contains(source)) {
      throw const AgentSecurityIncidentRecordException(
        'Incident source is invalid.',
      );
    }

    if (!AgentSecurityIncidentStatus.values.contains(status)) {
      throw const AgentSecurityIncidentRecordException(
        'Incident lifecycle status is invalid.',
      );
    }

    if (!AgentGuardianSeverity.values.contains(severity)) {
      throw const AgentSecurityIncidentRecordException(
        'Incident severity is invalid.',
      );
    }

    if (!AgentGuardianEvidenceConfidence.values.contains(evidenceConfidence)) {
      throw const AgentSecurityIncidentRecordException(
        'Incident evidence confidence is invalid.',
      );
    }

    if (updatedAt.isBefore(createdAt)) {
      throw const AgentSecurityIncidentRecordException(
        'Incident update time cannot be before creation time.',
      );
    }

    if (evidenceReferenceCodes.isEmpty || evidenceReferenceCodes.length > 12) {
      throw const AgentSecurityIncidentRecordException(
        'Incident must contain 1 to 12 bounded evidence references.',
      );
    }

    for (final String code in evidenceReferenceCodes) {
      if (!safeId.hasMatch(code)) {
        throw const AgentSecurityIncidentRecordException(
          'Incident evidence reference is invalid.',
        );
      }
    }

    if (assignedResponderRef != null &&
        !safeId.hasMatch(assignedResponderRef!)) {
      throw const AgentSecurityIncidentRecordException(
        'Assigned responder reference is invalid.',
      );
    }

    if (acknowledgedAt != null && acknowledgedAt!.isBefore(createdAt)) {
      throw const AgentSecurityIncidentRecordException(
        'Incident acknowledgement cannot predate creation.',
      );
    }

    if (triagedAt != null && triagedAt!.isBefore(createdAt)) {
      throw const AgentSecurityIncidentRecordException(
        'Incident triage cannot predate creation.',
      );
    }

    if (resolvedAt != null && resolvedAt!.isBefore(createdAt)) {
      throw const AgentSecurityIncidentRecordException(
        'Incident resolution cannot predate creation.',
      );
    }

    if (closedAt != null && closedAt!.isBefore(createdAt)) {
      throw const AgentSecurityIncidentRecordException(
        'Incident closure cannot predate creation.',
      );
    }

    if (status == AgentSecurityIncidentStatus.acknowledged &&
        (assignedResponderRef == null || acknowledgedAt == null)) {
      throw const AgentSecurityIncidentRecordException(
        'Acknowledged incident requires responder and acknowledgement time.',
      );
    }

    if (status == AgentSecurityIncidentStatus.triaged && triagedAt == null) {
      throw const AgentSecurityIncidentRecordException(
        'Triaged incident requires triage time.',
      );
    }

    if (status == AgentSecurityIncidentStatus.resolved && resolvedAt == null) {
      throw const AgentSecurityIncidentRecordException(
        'Resolved incident requires resolution time.',
      );
    }

    if (status == AgentSecurityIncidentStatus.closed &&
        (resolvedAt == null || closedAt == null)) {
      throw const AgentSecurityIncidentRecordException(
        'Closed incident requires resolution and closure times.',
      );
    }

    if (containsRawPrompt ||
        containsRawMessageHistory ||
        containsRawSecret ||
        containsPaymentCredential ||
        containsAuthToken ||
        containsPrivatePayload) {
      throw const AgentSecurityIncidentRecordException(
        'Incident record contains prohibited raw/private evidence.',
      );
    }
  }

  Map<String, dynamic> toSafeMap() {
    validateStructure();

    return Map<String, dynamic>.unmodifiable(<String, dynamic>{
      'incidentId': incidentId,
      'source': source,
      'sourceReferenceId': sourceReferenceId,
      'pseudonymousSubjectRef': pseudonymousSubjectRef,
      'status': status,
      'severity': severity,
      'evidenceConfidence': evidenceConfidence,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'evidenceReferenceCodes': List<String>.unmodifiable(
        evidenceReferenceCodes,
      ),
      'assignedResponderRef': assignedResponderRef,
      'acknowledgedAt': acknowledgedAt?.toUtc().toIso8601String(),
      'triagedAt': triagedAt?.toUtc().toIso8601String(),
      'resolvedAt': resolvedAt?.toUtc().toIso8601String(),
      'closedAt': closedAt?.toUtc().toIso8601String(),
      'rawPromptIncluded': false,
      'rawMessageHistoryIncluded': false,
      'rawSecretIncluded': false,
      'paymentCredentialIncluded': false,
      'authTokenIncluded': false,
      'privatePayloadIncluded': false,
      'privacyMinimizedEvidenceOnly': true,
      'recommendationAndLifecycleOnly': true,
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
      'invokesTargetAgent': false,
      'writesBusinessData': false,
      'persistsRecord': false,
    });
  }
}

class AgentSecurityIncidentRecordException implements Exception {
  const AgentSecurityIncidentRecordException(this.message);

  final String message;

  @override
  String toString() => 'AgentSecurityIncidentRecordException: $message';
}
