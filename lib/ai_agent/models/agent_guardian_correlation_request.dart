import 'agent_guardian_security_event.dart';

class AgentGuardianCorrelationRequest {
  AgentGuardianCorrelationRequest({
    required this.correlationId,
    required this.pseudonymousSubjectRef,
    required this.windowStart,
    required this.windowEnd,
    required List<AgentGuardianSecurityEvent> events,
    this.maxEvents = 20,
  }) : events = List<AgentGuardianSecurityEvent>.unmodifiable(events);

  final String correlationId;
  final String pseudonymousSubjectRef;
  final DateTime windowStart;
  final DateTime windowEnd;
  final List<AgentGuardianSecurityEvent> events;
  final int maxEvents;

  bool get grantsAuthority => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get executesBlock => false;
  bool get createsIncident => false;
  bool get persistsRequest => false;
  bool get loadsCrossSubjectHistory => false;
  bool get loadsFullConversationHistory => false;

  void validateStructure() {
    final RegExp safeIdPattern = RegExp(r'^[A-Za-z0-9._:-]{1,120}$');

    if (!safeIdPattern.hasMatch(correlationId) ||
        !safeIdPattern.hasMatch(pseudonymousSubjectRef)) {
      throw const AgentGuardianCorrelationRequestException(
        'Guardian correlation identifiers are invalid.',
      );
    }

    if (maxEvents < 1 || maxEvents > 20) {
      throw const AgentGuardianCorrelationRequestException(
        'Guardian correlation maxEvents is outside safe bounds.',
      );
    }

    if (events.isEmpty || events.length > maxEvents) {
      throw const AgentGuardianCorrelationRequestException(
        'Guardian correlation requires 1 to maxEvents signals.',
      );
    }

    final DateTime start = windowStart.toUtc();
    final DateTime end = windowEnd.toUtc();

    if (!end.isAfter(start)) {
      throw const AgentGuardianCorrelationRequestException(
        'Guardian correlation window is invalid.',
      );
    }

    if (end.difference(start) > const Duration(minutes: 30)) {
      throw const AgentGuardianCorrelationRequestException(
        'Guardian correlation window exceeds 30 minutes.',
      );
    }
  }

  Map<String, dynamic> toSafeMap() {
    validateStructure();

    return Map<String, dynamic>.unmodifiable(<String, dynamic>{
      'correlationId': correlationId,
      'pseudonymousSubjectRef': pseudonymousSubjectRef,
      'windowStart': windowStart.toUtc().toIso8601String(),
      'windowEnd': windowEnd.toUtc().toIso8601String(),
      'eventCount': events.length,
      'maxEvents': maxEvents,
      'eventPayloadIncluded': false,
      'grantsAuthority': false,
      'grantsPermission': false,
      'consumesApproval': false,
      'executesBlock': false,
      'createsIncident': false,
      'persistsRequest': false,
      'loadsCrossSubjectHistory': false,
      'loadsFullConversationHistory': false,
    });
  }
}

class AgentGuardianCorrelationRequestException implements Exception {
  const AgentGuardianCorrelationRequestException(this.message);

  final String message;

  @override
  String toString() => 'AgentGuardianCorrelationRequestException: $message';
}
