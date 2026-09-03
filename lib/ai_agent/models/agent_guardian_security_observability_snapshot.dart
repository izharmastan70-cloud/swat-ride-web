class AgentGuardianSecurityObservabilitySnapshot {
  AgentGuardianSecurityObservabilitySnapshot({
    required this.snapshotId,
    required this.sourceComponent,
    required this.capturedAt,
    Set<String> evidenceCodes = const <String>{},
    this.permissionEngineHealthy,
    this.approvalEngineHealthy,
    this.runtimeGateHealthy,
    this.emergencySecurityReviewHealthy,
    this.humanSecurityReviewAvailable,
    this.containsRawPrompt = false,
    this.containsRawMessageHistory = false,
    this.containsRawSecret = false,
    this.containsPaymentCredential = false,
    this.containsAuthToken = false,
    this.containsPrivatePayload = false,
  }) : evidenceCodes = Set<String>.unmodifiable(evidenceCodes);

  final String snapshotId;
  final String sourceComponent;
  final DateTime capturedAt;
  final Set<String> evidenceCodes;

  /// Nullable means monitoring state is unknown/not supplied.
  final bool? permissionEngineHealthy;
  final bool? approvalEngineHealthy;
  final bool? runtimeGateHealthy;
  final bool? emergencySecurityReviewHealthy;
  final bool? humanSecurityReviewAvailable;

  final bool containsRawPrompt;
  final bool containsRawMessageHistory;
  final bool containsRawSecret;
  final bool containsPaymentCredential;
  final bool containsAuthToken;
  final bool containsPrivatePayload;

  bool get safeEvidenceOnly => true;
  bool get invokesPermissionEngine => false;
  bool get invokesApprovalEngine => false;
  bool get invokesRuntimeGate => false;
  bool get invokesEmergencyStop => false;
  bool get executesBlock => false;
  bool get executesEscalation => false;
  bool get createsIncident => false;
  bool get writesBusinessData => false;
  bool get persistsSnapshot => false;

  void validateStructure() {
    final RegExp safeIdPattern = RegExp(r'^[A-Za-z0-9._:-]{1,120}$');

    if (!safeIdPattern.hasMatch(snapshotId) ||
        !safeIdPattern.hasMatch(sourceComponent)) {
      throw const AgentGuardianSecurityObservabilitySnapshotException(
        'Guardian observability snapshot identifiers are invalid.',
      );
    }

    if (evidenceCodes.isEmpty || evidenceCodes.length > 8) {
      throw const AgentGuardianSecurityObservabilitySnapshotException(
        'Guardian observability snapshot requires 1 to 8 evidence codes.',
      );
    }

    for (final String code in evidenceCodes) {
      if (!safeIdPattern.hasMatch(code)) {
        throw const AgentGuardianSecurityObservabilitySnapshotException(
          'Guardian observability evidence code is invalid.',
        );
      }
    }

    if (containsRawPrompt ||
        containsRawMessageHistory ||
        containsRawSecret ||
        containsPaymentCredential ||
        containsAuthToken ||
        containsPrivatePayload) {
      throw const AgentGuardianSecurityObservabilitySnapshotException(
        'Guardian observability snapshot contains prohibited raw/private payload.',
      );
    }
  }

  Map<String, dynamic> toSafeMap() {
    validateStructure();

    return Map<String, dynamic>.unmodifiable(<String, dynamic>{
      'snapshotId': snapshotId,
      'sourceComponent': sourceComponent,
      'capturedAt': capturedAt.toUtc().toIso8601String(),
      'evidenceCodes': List<String>.unmodifiable(
        evidenceCodes.toList()..sort(),
      ),
      'permissionEngineHealthy': permissionEngineHealthy,
      'approvalEngineHealthy': approvalEngineHealthy,
      'runtimeGateHealthy': runtimeGateHealthy,
      'emergencySecurityReviewHealthy': emergencySecurityReviewHealthy,
      'humanSecurityReviewAvailable': humanSecurityReviewAvailable,
      'rawPromptIncluded': false,
      'rawMessageHistoryIncluded': false,
      'rawSecretIncluded': false,
      'paymentCredentialIncluded': false,
      'authTokenIncluded': false,
      'privatePayloadIncluded': false,
      'safeEvidenceOnly': true,
      'invokesPermissionEngine': false,
      'invokesApprovalEngine': false,
      'invokesRuntimeGate': false,
      'invokesEmergencyStop': false,
      'executesBlock': false,
      'executesEscalation': false,
      'createsIncident': false,
      'writesBusinessData': false,
      'persistsSnapshot': false,
    });
  }
}

class AgentGuardianSecurityObservabilitySnapshotException implements Exception {
  const AgentGuardianSecurityObservabilitySnapshotException(this.message);

  final String message;

  @override
  String toString() =>
      'AgentGuardianSecurityObservabilitySnapshotException: $message';
}
