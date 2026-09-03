import '../constants/agent_incident_response_closure_constants.dart';

class AgentSecurityIncidentRecoveryEvidence {
  AgentSecurityIncidentRecoveryEvidence({
    required this.evidenceId,
    required this.incidentId,
    required this.source,
    required this.observedAt,
    required this.recoveryStable,
    required this.containmentVerified,
    required this.remediationVerified,
    required this.permissionReviewVerified,
    required this.approvalReviewVerified,
    required this.runtimeReviewVerified,
    required this.emergencyReviewVerified,
    required this.humanSecurityReviewVerified,
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

  final String evidenceId;
  final String incidentId;
  final String source;
  final DateTime observedAt;

  final bool recoveryStable;
  final bool containmentVerified;
  final bool remediationVerified;

  final bool permissionReviewVerified;
  final bool approvalReviewVerified;
  final bool runtimeReviewVerified;
  final bool emergencyReviewVerified;
  final bool humanSecurityReviewVerified;

  final List<String> evidenceReferenceCodes;

  final bool containsRawPrompt;
  final bool containsRawMessageHistory;
  final bool containsRawSecret;
  final bool containsPaymentCredential;
  final bool containsAuthToken;
  final bool containsPrivatePayload;

  bool get evidenceOnly => true;
  bool get authoritativeReceiptExecution => false;
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
  bool get closesIncident => false;
  bool get invokesProvider => false;
  bool get writesBusinessData => false;
  bool get persistsEvidence => false;

  void validateStructure() {
    final RegExp safeId = RegExp(r'^[A-Za-z0-9._:-]{1,160}$');

    if (!safeId.hasMatch(evidenceId) || !safeId.hasMatch(incidentId)) {
      throw const AgentSecurityIncidentRecoveryEvidenceException(
        'Incident recovery evidence identifiers are invalid.',
      );
    }

    if (!AgentSecurityIncidentRecoveryEvidenceSource.values.contains(source)) {
      throw const AgentSecurityIncidentRecoveryEvidenceException(
        'Incident recovery evidence source is invalid.',
      );
    }

    if (evidenceReferenceCodes.isEmpty || evidenceReferenceCodes.length > 8) {
      throw const AgentSecurityIncidentRecoveryEvidenceException(
        'Recovery evidence must contain 1 to 8 bounded references.',
      );
    }

    for (final String code in evidenceReferenceCodes) {
      if (!safeId.hasMatch(code)) {
        throw const AgentSecurityIncidentRecoveryEvidenceException(
          'Recovery evidence reference is invalid.',
        );
      }
    }

    if (containsRawPrompt ||
        containsRawMessageHistory ||
        containsRawSecret ||
        containsPaymentCredential ||
        containsAuthToken ||
        containsPrivatePayload) {
      throw const AgentSecurityIncidentRecoveryEvidenceException(
        'Recovery evidence contains prohibited raw/private data.',
      );
    }
  }

  Map<String, dynamic> toSafeMap() {
    validateStructure();

    return Map<String, dynamic>.unmodifiable(<String, dynamic>{
      'evidenceId': evidenceId,
      'incidentId': incidentId,
      'source': source,
      'observedAt': observedAt.toUtc().toIso8601String(),
      'recoveryStable': recoveryStable,
      'containmentVerified': containmentVerified,
      'remediationVerified': remediationVerified,
      'permissionReviewVerified': permissionReviewVerified,
      'approvalReviewVerified': approvalReviewVerified,
      'runtimeReviewVerified': runtimeReviewVerified,
      'emergencyReviewVerified': emergencyReviewVerified,
      'humanSecurityReviewVerified': humanSecurityReviewVerified,
      'evidenceReferenceCodes': List<String>.unmodifiable(
        evidenceReferenceCodes,
      ),
      'rawPromptIncluded': false,
      'rawMessageHistoryIncluded': false,
      'rawSecretIncluded': false,
      'paymentCredentialIncluded': false,
      'authTokenIncluded': false,
      'privatePayloadIncluded': false,
      'evidenceOnly': true,
      'authoritativeReceiptExecution': false,
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
      'closesIncident': false,
      'invokesProvider': false,
      'writesBusinessData': false,
      'persistsEvidence': false,
    });
  }
}

class AgentSecurityIncidentRecoveryEvidenceException implements Exception {
  const AgentSecurityIncidentRecoveryEvidenceException(this.message);

  final String message;

  @override
  String toString() =>
      'AgentSecurityIncidentRecoveryEvidenceException: $message';
}
