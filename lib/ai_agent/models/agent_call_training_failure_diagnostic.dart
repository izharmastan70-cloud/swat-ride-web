import 'agent_call_training_evaluation.dart';

class AgentCallTrainingAdversarialFamily {
  AgentCallTrainingAdversarialFamily._();

  static const String wrongAction = 'WRONG_ACTION';
  static const String missingTrustedBinding = 'MISSING_TRUSTED_BINDING';
  static const String missingFreshVerification = 'MISSING_FRESH_VERIFICATION';
  static const String missingConfirmation = 'MISSING_CONFIRMATION';
  static const String privacyLeak = 'PRIVACY_LEAK';
  static const String permissionGrant = 'PERMISSION_GRANT';
  static const String transcriptAuthority = 'TRANSCRIPT_AUTHORITY';
  static const String liveProvider = 'LIVE_PROVIDER';
  static const String businessWrite = 'BUSINESS_WRITE';
  static const String ownerEscalationMiss = 'OWNER_ESCALATION_MISS';

  static const Set<String> values = <String>{
    wrongAction,
    missingTrustedBinding,
    missingFreshVerification,
    missingConfirmation,
    privacyLeak,
    permissionGrant,
    transcriptAuthority,
    liveProvider,
    businessWrite,
    ownerEscalationMiss,
  };
}

class AgentCallTrainingAdversarialCase {
  const AgentCallTrainingAdversarialCase({
    required this.caseId,
    required this.sourceScenarioId,
    required this.family,
    required this.expectedFailClosed,
    required this.expectedDiagnosticCodes,
    required this.observation,
  });

  final String caseId;
  final String sourceScenarioId;
  final String family;
  final bool expectedFailClosed;
  final List<String> expectedDiagnosticCodes;
  final AgentCallTrainingObservation observation;

  bool get syntheticOnly => true;
  bool get mayGrantPermission => false;
  bool get mayWriteBusinessData => false;
  bool get mayTrainModel => false;
  bool get mayDeploy => false;

  void validate() {
    if (caseId.trim().isEmpty || sourceScenarioId.trim().isEmpty) {
      throw const AgentCallTrainingFailureDiagnosticException(
        'Adversarial case identity cannot be empty.',
      );
    }

    if (!AgentCallTrainingAdversarialFamily.values.contains(family)) {
      throw AgentCallTrainingFailureDiagnosticException(
        'Unsupported adversarial family: $family',
      );
    }

    if (expectedDiagnosticCodes.isEmpty ||
        expectedDiagnosticCodes.any((String value) => value.trim().isEmpty)) {
      throw const AgentCallTrainingFailureDiagnosticException(
        'Adversarial case must declare expected diagnostics.',
      );
    }

    observation.validate();
  }
}

class AgentCallTrainingFailureDiagnosticReport {
  const AgentCallTrainingFailureDiagnosticReport({
    required this.adversarialCaseId,
    required this.sourceScenarioId,
    required this.family,
    required this.evaluationResult,
    required this.diagnosticCodes,
    required this.failClosed,
    required this.detectedFailure,
  });

  final String adversarialCaseId;
  final String sourceScenarioId;
  final String family;
  final AgentCallTrainingEvaluationResult evaluationResult;
  final List<String> diagnosticCodes;
  final bool failClosed;
  final bool detectedFailure;

  bool get mayGrantPermission => false;
  bool get mayWriteBusinessData => false;
  bool get mayTrainModel => false;
  bool get mayDeploy => false;

  void validate() {
    if (adversarialCaseId.trim().isEmpty ||
        sourceScenarioId.trim().isEmpty ||
        !AgentCallTrainingAdversarialFamily.values.contains(family)) {
      throw const AgentCallTrainingFailureDiagnosticException(
        'Failure diagnostic identity/family is invalid.',
      );
    }

    evaluationResult.validate();

    if (!detectedFailure) {
      throw const AgentCallTrainingFailureDiagnosticException(
        'Adversarial diagnostic report cannot mark failure undetected.',
      );
    }

    if (diagnosticCodes.isEmpty) {
      throw const AgentCallTrainingFailureDiagnosticException(
        'Detected adversarial failure must expose diagnostic codes.',
      );
    }

    if (failClosed != evaluationResult.failClosed) {
      throw const AgentCallTrainingFailureDiagnosticException(
        'Diagnostic fail-closed flag must match evaluation result.',
      );
    }
  }

  Map<String, dynamic> toSafeMap() {
    validate();

    return <String, dynamic>{
      'adversarialCaseId': adversarialCaseId.trim(),
      'sourceScenarioId': sourceScenarioId.trim(),
      'family': family,
      'diagnosticCodes': List<String>.unmodifiable(diagnosticCodes),
      'failClosed': failClosed,
      'detectedFailure': detectedFailure,
      'overallScorePercent': evaluationResult.overallScorePercent,
      'mayGrantPermission': false,
      'mayWriteBusinessData': false,
      'mayTrainModel': false,
      'mayDeploy': false,
    };
  }
}

class AgentCallTrainingCoverageGateReport {
  const AgentCallTrainingCoverageGateReport({
    required this.requiredFamilies,
    required this.coveredFamilies,
    required this.adversarialReports,
    required this.canonicalBaselinePassed,
    required this.coverageComplete,
    required this.allAdversarialFailuresDetected,
    required this.noUnexpectedAdversarialPasses,
    required this.gatePassed,
    required this.evaluatedAt,
  });

  final Set<String> requiredFamilies;
  final Set<String> coveredFamilies;
  final List<AgentCallTrainingFailureDiagnosticReport> adversarialReports;

  final bool canonicalBaselinePassed;
  final bool coverageComplete;
  final bool allAdversarialFailuresDetected;
  final bool noUnexpectedAdversarialPasses;
  final bool gatePassed;
  final DateTime evaluatedAt;

  bool get mayGrantPermission => false;
  bool get mayWriteBusinessData => false;
  bool get mayTrainModel => false;
  bool get mayChangePrompt => false;
  bool get mayDeploy => false;

  void validate() {
    if (requiredFamilies.isEmpty || adversarialReports.isEmpty) {
      throw const AgentCallTrainingFailureDiagnosticException(
        'Coverage gate requires families and adversarial reports.',
      );
    }

    if (!requiredFamilies.every(
      AgentCallTrainingAdversarialFamily.values.contains,
    )) {
      throw const AgentCallTrainingFailureDiagnosticException(
        'Coverage gate contains unsupported required family.',
      );
    }

    for (final AgentCallTrainingFailureDiagnosticReport report
        in adversarialReports) {
      report.validate();
    }

    final bool computedCoverage = coveredFamilies.containsAll(requiredFamilies);

    if (coverageComplete != computedCoverage) {
      throw const AgentCallTrainingFailureDiagnosticException(
        'Coverage-complete flag does not match required families.',
      );
    }

    final bool expectedGate =
        canonicalBaselinePassed &&
        coverageComplete &&
        allAdversarialFailuresDetected &&
        noUnexpectedAdversarialPasses;

    if (gatePassed != expectedGate) {
      throw const AgentCallTrainingFailureDiagnosticException(
        'Coverage gate result is inconsistent.',
      );
    }
  }

  Map<String, dynamic> toSafeMap() {
    validate();

    return <String, dynamic>{
      'requiredFamilies': requiredFamilies.toList()..sort(),
      'coveredFamilies': coveredFamilies.toList()..sort(),
      'adversarialCount': adversarialReports.length,
      'canonicalBaselinePassed': canonicalBaselinePassed,
      'coverageComplete': coverageComplete,
      'allAdversarialFailuresDetected': allAdversarialFailuresDetected,
      'noUnexpectedAdversarialPasses': noUnexpectedAdversarialPasses,
      'gatePassed': gatePassed,
      'evaluatedAt': evaluatedAt.toUtc().toIso8601String(),
      'mayGrantPermission': false,
      'mayWriteBusinessData': false,
      'mayTrainModel': false,
      'mayChangePrompt': false,
      'mayDeploy': false,
    };
  }
}

class AgentCallTrainingFailureDiagnosticException implements Exception {
  const AgentCallTrainingFailureDiagnosticException(this.message);

  final String message;

  @override
  String toString() => 'AgentCallTrainingFailureDiagnosticException: $message';
}
