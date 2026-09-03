abstract final class AgentSecurityIncidentPersistenceOperation {
  static const String create = 'CREATE';
  static const String lifecycleUpdate = 'LIFECYCLE_UPDATE';

  static const Set<String> values = <String>{create, lifecycleUpdate};
}

abstract final class AgentSecurityIncidentPersistenceActorRole {
  static const String owner = 'OWNER';
  static const String superAdmin = 'SUPER_ADMIN';

  static const Set<String> values = <String>{owner, superAdmin};
}

class AgentSecurityIncidentPersistenceWriteAuthorization {
  AgentSecurityIncidentPersistenceWriteAuthorization({
    required this.operation,
    required this.incidentId,
    required this.actorRole,
    required this.actorRef,
    required this.idempotencyKey,
    required this.issuedAtUtc,
    required this.expiresAtUtc,
    required this.freshTrustedIdentityVerified,
    required this.permissionGranted,
    required this.sensitiveApprovalVerified,
    required this.runtimeGateAllowed,
    required this.immutableAuditReady,
  });

  final String operation;
  final String incidentId;
  final String actorRole;
  final String actorRef;
  final String idempotencyKey;
  final DateTime issuedAtUtc;
  final DateTime expiresAtUtc;

  final bool freshTrustedIdentityVerified;
  final bool permissionGranted;
  final bool sensitiveApprovalVerified;
  final bool runtimeGateAllowed;
  final bool immutableAuditReady;

  static final RegExp _safeId = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]{0,159}$');

  void validate({
    required String expectedOperation,
    required String expectedIncidentId,
    required DateTime nowUtc,
  }) {
    if (!AgentSecurityIncidentPersistenceOperation.values.contains(operation) ||
        operation != expectedOperation) {
      throw const AgentSecurityIncidentPersistenceAuthorizationException(
        'Incident persistence operation binding is invalid.',
      );
    }

    if (!_safeId.hasMatch(incidentId) ||
        incidentId != expectedIncidentId ||
        !_safeId.hasMatch(actorRef) ||
        !_safeId.hasMatch(idempotencyKey)) {
      throw const AgentSecurityIncidentPersistenceAuthorizationException(
        'Incident persistence identifier binding is invalid.',
      );
    }

    if (!AgentSecurityIncidentPersistenceActorRole.values.contains(actorRole)) {
      throw const AgentSecurityIncidentPersistenceAuthorizationException(
        'Incident persistence actor role is not trusted.',
      );
    }

    final DateTime issued = issuedAtUtc.toUtc();
    final DateTime expires = expiresAtUtc.toUtc();
    final DateTime now = nowUtc.toUtc();

    if (!expires.isAfter(issued) ||
        expires.difference(issued) > const Duration(minutes: 5) ||
        issued.isAfter(now.add(const Duration(minutes: 1))) ||
        !expires.isAfter(now)) {
      throw const AgentSecurityIncidentPersistenceAuthorizationException(
        'Incident persistence authorization is stale or invalid.',
      );
    }

    if (!freshTrustedIdentityVerified ||
        !permissionGranted ||
        !sensitiveApprovalVerified ||
        !runtimeGateAllowed ||
        !immutableAuditReady) {
      throw const AgentSecurityIncidentPersistenceAuthorizationException(
        'Incident persistence authority chain is incomplete.',
      );
    }
  }

  Map<String, Object> toSafeAuditMetadata() {
    return Map<String, Object>.unmodifiable(<String, Object>{
      'operation': operation,
      'incidentId': incidentId,
      'actorRole': actorRole,
      'actorRef': actorRef,
      'idempotencyKey': idempotencyKey,
      'issuedAtUtc': issuedAtUtc.toUtc().toIso8601String(),
      'expiresAtUtc': expiresAtUtc.toUtc().toIso8601String(),
      'freshTrustedIdentityVerified': freshTrustedIdentityVerified,
      'permissionGranted': permissionGranted,
      'sensitiveApprovalVerified': sensitiveApprovalVerified,
      'runtimeGateAllowed': runtimeGateAllowed,
      'immutableAuditReady': immutableAuditReady,
      'containsAuthToken': false,
      'containsSessionToken': false,
      'containsRawPrivatePayload': false,
    });
  }
}

class AgentSecurityIncidentPersistenceAuthorizationException
    implements Exception {
  const AgentSecurityIncidentPersistenceAuthorizationException(this.message);

  final String message;

  @override
  String toString() =>
      'AgentSecurityIncidentPersistenceAuthorizationException: $message';
}
