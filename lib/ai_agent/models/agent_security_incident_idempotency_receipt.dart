import 'agent_security_incident_persistence_write_authorization.dart';

class AgentSecurityIncidentIdempotencyReceipt {
  AgentSecurityIncidentIdempotencyReceipt({
    required this.idempotencyKey,
    required this.incidentId,
    required this.operation,
    required this.actorRole,
    required this.actorRef,
    required this.requestBinding,
    required this.authorizationIssuedAtUtc,
    required this.committedStatus,
  }) {
    validate();
  }

  static const String committed = 'COMMITTED';

  static final RegExp _safeId = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]{0,159}$');

  final String idempotencyKey;
  final String incidentId;
  final String operation;
  final String actorRole;
  final String actorRef;
  final String requestBinding;
  final DateTime authorizationIssuedAtUtc;
  final String committedStatus;

  void validate() {
    if (!_safeId.hasMatch(idempotencyKey) ||
        !_safeId.hasMatch(incidentId) ||
        !_safeId.hasMatch(actorRef) ||
        operation.trim().isEmpty ||
        actorRole.trim().isEmpty ||
        requestBinding.trim().isEmpty ||
        requestBinding.length > 8192 ||
        committedStatus != committed) {
      throw const AgentSecurityIncidentIdempotencyReceiptException(
        'Security incident idempotency receipt is invalid.',
      );
    }
  }

  bool matches({
    required AgentSecurityIncidentPersistenceWriteAuthorization authorization,
    required String expectedIncidentId,
    required String expectedRequestBinding,
  }) {
    return idempotencyKey == authorization.idempotencyKey &&
        incidentId == expectedIncidentId &&
        operation == authorization.operation &&
        actorRole == authorization.actorRole &&
        actorRef == authorization.actorRef &&
        requestBinding == expectedRequestBinding &&
        committedStatus == committed;
  }

  Map<String, dynamic> toMap() {
    validate();

    return <String, dynamic>{
      'idempotencyKey': idempotencyKey,
      'incidentId': incidentId,
      'operation': operation,
      'actorRole': actorRole,
      'actorRef': actorRef,
      'requestBinding': requestBinding,
      'authorizationIssuedAtUtc': authorizationIssuedAtUtc
          .toUtc()
          .toIso8601String(),
      'committedStatus': committedStatus,
    };
  }

  static AgentSecurityIncidentIdempotencyReceipt fromMap(
    Map<String, dynamic> data,
  ) {
    final DateTime? issuedAt = DateTime.tryParse(
      (data['authorizationIssuedAtUtc'] ?? '').toString(),
    );

    if (issuedAt == null) {
      throw const AgentSecurityIncidentIdempotencyReceiptException(
        'Security incident idempotency receipt timestamp is invalid.',
      );
    }

    return AgentSecurityIncidentIdempotencyReceipt(
      idempotencyKey: (data['idempotencyKey'] ?? '').toString(),
      incidentId: (data['incidentId'] ?? '').toString(),
      operation: (data['operation'] ?? '').toString(),
      actorRole: (data['actorRole'] ?? '').toString(),
      actorRef: (data['actorRef'] ?? '').toString(),
      requestBinding: (data['requestBinding'] ?? '').toString(),
      authorizationIssuedAtUtc: issuedAt.toUtc(),
      committedStatus: (data['committedStatus'] ?? '').toString(),
    );
  }
}

class AgentSecurityIncidentIdempotencyReceiptException implements Exception {
  const AgentSecurityIncidentIdempotencyReceiptException(this.message);

  final String message;

  @override
  String toString() =>
      'AgentSecurityIncidentIdempotencyReceiptException: $message';
}
