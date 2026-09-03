class AgentGuardianAdversarialVerificationResult {
  AgentGuardianAdversarialVerificationResult({
    required this.status,
    required this.scenarioId,
    required this.actualSeverity,
    required this.actualDisposition,
    required this.monitoringStatus,
    required this.expectedOutcomeMet,
    required this.replaySuppressed,
    required this.crossSubjectSuppressed,
    required this.failClosedRecommended,
    required this.coreAppAvailable,
    required this.otherChannelsAvailable,
    required this.authoritativeControlsRemainIndependent,
    required this.guardianFailureIsolated,
    required List<String> evidenceCodes,
  }) : evidenceCodes = List<String>.unmodifiable(evidenceCodes);

  final String status;
  final String scenarioId;
  final String actualSeverity;
  final String actualDisposition;
  final String monitoringStatus;

  final bool expectedOutcomeMet;
  final bool replaySuppressed;
  final bool crossSubjectSuppressed;
  final bool failClosedRecommended;

  final bool coreAppAvailable;
  final bool otherChannelsAvailable;
  final bool authoritativeControlsRemainIndependent;
  final bool guardianFailureIsolated;

  final List<String> evidenceCodes;

  bool get passed => status == 'PASSED';
  bool get failed => status == 'FAILED';

  bool get recommendationOnly => true;
  bool get guardianIsFinalEnforcer => false;
  bool get invokesPermissionEngine => false;
  bool get invokesApprovalEngine => false;
  bool get invokesRuntimeGate => false;
  bool get invokesEmergencyStop => false;
  bool get executesBlock => false;
  bool get executesEscalation => false;
  bool get createsIncident => false;
  bool get invokesProvider => false;
  bool get invokesTargetAgent => false;
  bool get writesBusinessData => false;
  bool get persistsResult => false;

  Map<String, dynamic> toSafeMap() {
    return Map<String, dynamic>.unmodifiable(<String, dynamic>{
      'status': status,
      'scenarioId': scenarioId,
      'actualSeverity': actualSeverity,
      'actualDisposition': actualDisposition,
      'monitoringStatus': monitoringStatus,
      'expectedOutcomeMet': expectedOutcomeMet,
      'replaySuppressed': replaySuppressed,
      'crossSubjectSuppressed': crossSubjectSuppressed,
      'failClosedRecommended': failClosedRecommended,
      'coreAppAvailable': coreAppAvailable,
      'otherChannelsAvailable': otherChannelsAvailable,
      'authoritativeControlsRemainIndependent':
          authoritativeControlsRemainIndependent,
      'guardianFailureIsolated': guardianFailureIsolated,
      'evidenceCodes': List<String>.unmodifiable(evidenceCodes),
      'rawEvidencePayloadIncluded': false,
      'recommendationOnly': true,
      'guardianIsFinalEnforcer': false,
      'invokesPermissionEngine': false,
      'invokesApprovalEngine': false,
      'invokesRuntimeGate': false,
      'invokesEmergencyStop': false,
      'executesBlock': false,
      'executesEscalation': false,
      'createsIncident': false,
      'invokesProvider': false,
      'invokesTargetAgent': false,
      'writesBusinessData': false,
      'persistsResult': false,
    });
  }
}
