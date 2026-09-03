import '../constants/agent_incident_response_human_constants.dart';

class AgentSecurityIncidentTimelineEvent {
  AgentSecurityIncidentTimelineEvent({
    required this.eventId,
    required this.incidentId,
    required this.eventType,
    required this.actorRef,
    required this.occurredAt,
    required List<String> evidenceReferenceCodes,
    this.containsRawPrompt = false,
    this.containsRawMessageHistory = false,
    this.containsRawSecret = false,
    this.containsPaymentCredential = false,
    this.containsAuthToken = false,
    this.containsPrivatePayload = false,
  }) : evidenceReferenceCodes = List<String>.unmodifiable(
         evidenceReferenceCodes,
       );

  final String eventId;
  final String incidentId;
  final String eventType;
  final String actorRef;
  final DateTime occurredAt;
  final List<String> evidenceReferenceCodes;

  final bool containsRawPrompt;
  final bool containsRawMessageHistory;
  final bool containsRawSecret;
  final bool containsPaymentCredential;
  final bool containsAuthToken;
  final bool containsPrivatePayload;

  bool get metadataOnly => true;
  bool get actorReferenceIsPseudonymous => true;
  bool get grantsAuthority => false;
  bool get invokesProvider => false;
  bool get writesBusinessData => false;
  bool get persistsTimelineEvent => false;

  void validateStructure() {
    final RegExp safeId = RegExp(r'^[A-Za-z0-9._:-]{1,160}$');

    if (!safeId.hasMatch(eventId) ||
        !safeId.hasMatch(incidentId) ||
        !safeId.hasMatch(actorRef)) {
      throw const AgentSecurityIncidentTimelineEventException(
        'Incident timeline identifiers are invalid.',
      );
    }

    if (!AgentSecurityIncidentTimelineEventType.values.contains(eventType)) {
      throw const AgentSecurityIncidentTimelineEventException(
        'Incident timeline event type is invalid.',
      );
    }

    if (evidenceReferenceCodes.length > 8) {
      throw const AgentSecurityIncidentTimelineEventException(
        'Incident timeline evidence references exceed the limit.',
      );
    }

    for (final String code in evidenceReferenceCodes) {
      if (!safeId.hasMatch(code)) {
        throw const AgentSecurityIncidentTimelineEventException(
          'Incident timeline evidence reference is invalid.',
        );
      }
    }

    if (containsRawPrompt ||
        containsRawMessageHistory ||
        containsRawSecret ||
        containsPaymentCredential ||
        containsAuthToken ||
        containsPrivatePayload) {
      throw const AgentSecurityIncidentTimelineEventException(
        'Incident timeline contains prohibited raw/private evidence.',
      );
    }
  }

  Map<String, dynamic> toSafeMap() {
    validateStructure();

    return Map<String, dynamic>.unmodifiable(<String, dynamic>{
      'eventId': eventId,
      'incidentId': incidentId,
      'eventType': eventType,
      'actorRef': actorRef,
      'occurredAt': occurredAt.toUtc().toIso8601String(),
      'evidenceReferenceCodes': List<String>.unmodifiable(
        evidenceReferenceCodes,
      ),
      'metadataOnly': true,
      'actorReferenceIsPseudonymous': true,
      'rawPromptIncluded': false,
      'rawMessageHistoryIncluded': false,
      'rawSecretIncluded': false,
      'paymentCredentialIncluded': false,
      'authTokenIncluded': false,
      'privatePayloadIncluded': false,
      'grantsAuthority': false,
      'invokesProvider': false,
      'writesBusinessData': false,
      'persistsTimelineEvent': false,
    });
  }
}

class AgentSecurityIncidentTimelineEventException implements Exception {
  const AgentSecurityIncidentTimelineEventException(this.message);

  final String message;

  @override
  String toString() => 'AgentSecurityIncidentTimelineEventException: $message';
}
