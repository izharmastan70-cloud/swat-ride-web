import '../constants/agent_incident_response_adversarial_constants.dart';

class AgentSecurityIncidentIdempotencyObservation {
  AgentSecurityIncidentIdempotencyObservation({
    required this.operationId,
    required this.incidentId,
    required this.idempotencyKey,
    required this.payloadFingerprint,
    required this.observedAt,
  });

  final String operationId;
  final String incidentId;
  final String idempotencyKey;
  final String payloadFingerprint;
  final DateTime observedAt;

  bool get metadataOnly => true;
  bool get containsRawPayload => false;
  bool get grantsAuthority => false;
  bool get invokesProvider => false;
  bool get writesBusinessData => false;
  bool get persistsObservation => false;

  void validateStructure() {
    final RegExp safeId = RegExp(r'^[A-Za-z0-9._:-]{1,180}$');

    if (!safeId.hasMatch(operationId) ||
        !safeId.hasMatch(incidentId) ||
        !safeId.hasMatch(idempotencyKey) ||
        !safeId.hasMatch(payloadFingerprint)) {
      throw const AgentSecurityIncidentIdempotencyObservationException(
        'Incident idempotency observation identifiers are invalid.',
      );
    }
  }

  Map<String, dynamic> toSafeMap() {
    validateStructure();

    return Map<String, dynamic>.unmodifiable(<String, dynamic>{
      'operationId': operationId,
      'incidentId': incidentId,
      'idempotencyKey': idempotencyKey,
      'payloadFingerprint': payloadFingerprint,
      'observedAt': observedAt.toUtc().toIso8601String(),
      'metadataOnly': true,
      'containsRawPayload': false,
      'grantsAuthority': false,
      'invokesProvider': false,
      'writesBusinessData': false,
      'persistsObservation': false,
    });
  }
}

class AgentSecurityIncidentIdempotencyEvaluation {
  AgentSecurityIncidentIdempotencyEvaluation({
    required this.decision,
    required this.idempotencyKey,
    required this.failClosedRecommended,
    required this.reasonCode,
  });

  final String decision;
  final String idempotencyKey;
  final bool failClosedRecommended;
  final String reasonCode;

  bool get grantsAuthority => false;
  bool get executesOperation => false;
  bool get persistsDecision => false;

  void validateStructure() {
    final RegExp safeId = RegExp(r'^[A-Za-z0-9._:-]{1,180}$');

    if (!AgentSecurityIncidentIdempotencyDecision.values.contains(decision) ||
        !safeId.hasMatch(idempotencyKey) ||
        !safeId.hasMatch(reasonCode)) {
      throw const AgentSecurityIncidentIdempotencyObservationException(
        'Incident idempotency evaluation is invalid.',
      );
    }
  }
}

class AgentSecurityIncidentIdempotencyObservationException
    implements Exception {
  const AgentSecurityIncidentIdempotencyObservationException(this.message);

  final String message;

  @override
  String toString() =>
      'AgentSecurityIncidentIdempotencyObservationException: $message';
}
