import '../constants/agent_guardian_security_constants.dart';

class AgentGuardianPolicyEnvelopeStatus {
  AgentGuardianPolicyEnvelopeStatus._();

  static const String ready = 'READY';
  static const String blocked = 'BLOCKED';
}

class AgentGuardianSecurityPolicyEnvelope {
  AgentGuardianSecurityPolicyEnvelope({
    required this.status,
    required this.envelopeId,
    required this.correlationId,
    required this.pseudonymousSubjectRef,
    required this.severity,
    required this.evidenceConfidence,
    required this.recommendedDisposition,
    required this.requiresPermissionEngine,
    required this.requiresApprovalEngine,
    required this.requiresRuntimeGate,
    required this.requiresEmergencySecurityReview,
    required this.requiresHumanSecurityReview,
    required this.failClosedRecommended,
    required this.actionMayProceedWithoutAuthoritativeChecks,
    required List<String> policyReasonCodes,
    required this.generatedAt,
  }) : policyReasonCodes = List<String>.unmodifiable(policyReasonCodes);

  final String status;
  final String envelopeId;
  final String correlationId;
  final String pseudonymousSubjectRef;
  final String severity;
  final String evidenceConfidence;
  final String recommendedDisposition;

  final bool requiresPermissionEngine;
  final bool requiresApprovalEngine;
  final bool requiresRuntimeGate;
  final bool requiresEmergencySecurityReview;
  final bool requiresHumanSecurityReview;
  final bool failClosedRecommended;
  final bool actionMayProceedWithoutAuthoritativeChecks;

  final List<String> policyReasonCodes;
  final DateTime generatedAt;

  bool get ready => status == AgentGuardianPolicyEnvelopeStatus.ready;

  bool get blocked => status == AgentGuardianPolicyEnvelopeStatus.blocked;

  bool get recommendationOnly => true;
  bool get guardianIsFinalEnforcer => false;
  bool get grantsAuthority => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get invokesPermissionEngine => false;
  bool get invokesApprovalEngine => false;
  bool get invokesRuntimeGate => false;
  bool get invokesEmergencyStop => false;
  bool get executesBlock => false;
  bool get executesEscalation => false;
  bool get createsIncident => false;
  bool get mutatesSecurityControls => false;
  bool get invokesProvider => false;
  bool get invokesTargetAgent => false;
  bool get writesBusinessData => false;
  bool get persistsEnvelope => false;

  void validateStructure() {
    final RegExp safeIdPattern = RegExp(r'^[A-Za-z0-9._:-]{1,120}$');

    if (!safeIdPattern.hasMatch(envelopeId) ||
        !safeIdPattern.hasMatch(correlationId) ||
        !safeIdPattern.hasMatch(pseudonymousSubjectRef)) {
      throw const AgentGuardianSecurityPolicyEnvelopeException(
        'Guardian policy envelope identifiers are invalid.',
      );
    }

    if (!AgentGuardianSeverity.values.contains(severity) ||
        !AgentGuardianEvidenceConfidence.values.contains(evidenceConfidence) ||
        !AgentGuardianRecommendedDisposition.values.contains(
          recommendedDisposition,
        )) {
      throw const AgentGuardianSecurityPolicyEnvelopeException(
        'Guardian policy envelope classification is invalid.',
      );
    }

    if (policyReasonCodes.isEmpty || policyReasonCodes.length > 12) {
      throw const AgentGuardianSecurityPolicyEnvelopeException(
        'Guardian policy envelope reason codes are outside safe bounds.',
      );
    }

    if (actionMayProceedWithoutAuthoritativeChecks) {
      throw const AgentGuardianSecurityPolicyEnvelopeException(
        'Guardian policy cannot authorize bypass of authoritative checks.',
      );
    }

    if ((severity == AgentGuardianSeverity.high ||
            severity == AgentGuardianSeverity.critical) &&
        (!requiresPermissionEngine || !requiresRuntimeGate)) {
      throw const AgentGuardianSecurityPolicyEnvelopeException(
        'High/Critical Guardian policy must retain permission/runtime checks.',
      );
    }
  }

  Map<String, dynamic> toSafeMap() {
    validateStructure();

    return Map<String, dynamic>.unmodifiable(<String, dynamic>{
      'status': status,
      'envelopeId': envelopeId,
      'correlationId': correlationId,
      'pseudonymousSubjectRef': pseudonymousSubjectRef,
      'severity': severity,
      'evidenceConfidence': evidenceConfidence,
      'recommendedDisposition': recommendedDisposition,
      'requiresPermissionEngine': requiresPermissionEngine,
      'requiresApprovalEngine': requiresApprovalEngine,
      'requiresRuntimeGate': requiresRuntimeGate,
      'requiresEmergencySecurityReview': requiresEmergencySecurityReview,
      'requiresHumanSecurityReview': requiresHumanSecurityReview,
      'failClosedRecommended': failClosedRecommended,
      'actionMayProceedWithoutAuthoritativeChecks': false,
      'policyReasonCodes': List<String>.unmodifiable(policyReasonCodes),
      'generatedAt': generatedAt.toUtc().toIso8601String(),
      'recommendationOnly': true,
      'guardianIsFinalEnforcer': false,
      'grantsAuthority': false,
      'grantsPermission': false,
      'consumesApproval': false,
      'invokesPermissionEngine': false,
      'invokesApprovalEngine': false,
      'invokesRuntimeGate': false,
      'invokesEmergencyStop': false,
      'executesBlock': false,
      'executesEscalation': false,
      'createsIncident': false,
      'mutatesSecurityControls': false,
      'invokesProvider': false,
      'invokesTargetAgent': false,
      'writesBusinessData': false,
      'persistsEnvelope': false,
    });
  }
}

class AgentGuardianSecurityPolicyEnvelopeException implements Exception {
  const AgentGuardianSecurityPolicyEnvelopeException(this.message);

  final String message;

  @override
  String toString() => 'AgentGuardianSecurityPolicyEnvelopeException: $message';
}
