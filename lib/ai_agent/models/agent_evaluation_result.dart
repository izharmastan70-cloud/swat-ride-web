import '../constants/agent_evaluation_constants.dart';

/// Immutable result for one evaluation case.
///
/// A result is evidence only. It cannot modify a prompt/model, grant runtime
/// permission, consume approval, write business data, or deploy anything.
class AgentEvaluationResult {
  const AgentEvaluationResult({
    required this.caseId,
    required this.caseVersion,
    required this.status,
    required this.actualDecision,
    required this.actualBehaviorSummary,
    required this.passedChecks,
    required this.failedChecks,
    required this.safetyViolations,
    required this.evaluatorVersion,
    required this.evaluatedAt,
  });

  final String caseId;
  final int caseVersion;
  final String status;
  final String actualDecision;
  final String actualBehaviorSummary;
  final List<String> passedChecks;
  final List<String> failedChecks;
  final List<String> safetyViolations;
  final String evaluatorVersion;
  final DateTime evaluatedAt;

  bool get passed =>
      status == AgentEvaluationResultStatus.passed &&
      failedChecks.isEmpty &&
      safetyViolations.isEmpty;

  bool get mayChangePrompt => false;
  bool get mayTrainModel => false;
  bool get mayGrantPermission => false;
  bool get mayConsumeApproval => false;
  bool get mayWriteBusinessData => false;
  bool get mayDeploy => false;

  void validate() {
    if (caseId.trim().isEmpty || evaluatorVersion.trim().isEmpty) {
      throw const AgentEvaluationResultException(
        'Evaluation result case/evaluator identity cannot be empty.',
      );
    }

    if (caseVersion < 1) {
      throw const AgentEvaluationResultException(
        'Evaluation result caseVersion must be >= 1.',
      );
    }

    if (!AgentEvaluationResultStatus.values.contains(status)) {
      throw AgentEvaluationResultException(
        'Invalid evaluation result status "$status".',
      );
    }

    if (status != AgentEvaluationResultStatus.notRun &&
        actualBehaviorSummary.trim().isEmpty) {
      throw const AgentEvaluationResultException(
        'Executed evaluation result requires an actual behavior summary.',
      );
    }

    if (status == AgentEvaluationResultStatus.passed &&
        (failedChecks.isNotEmpty || safetyViolations.isNotEmpty)) {
      throw const AgentEvaluationResultException(
        'PASSED result cannot contain failed checks or safety violations.',
      );
    }

    _validateList(passedChecks, 'passedChecks');
    _validateList(failedChecks, 'failedChecks');
    _validateList(safetyViolations, 'safetyViolations');
  }

  void _validateList(List<String> values, String fieldName) {
    final List<String> normalized = values
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .toList(growable: false);

    if (normalized.length != values.length) {
      throw AgentEvaluationResultException(
        '$fieldName cannot contain empty values.',
      );
    }

    if (normalized.toSet().length != normalized.length) {
      throw AgentEvaluationResultException(
        '$fieldName cannot contain duplicate values.',
      );
    }
  }

  Map<String, dynamic> toMap() {
    validate();

    return <String, dynamic>{
      'caseId': caseId.trim(),
      'caseVersion': caseVersion,
      'status': status,
      'actualDecision': actualDecision.trim(),
      'actualBehaviorSummary': actualBehaviorSummary.trim(),
      'passedChecks': passedChecks.map((String value) => value.trim()).toList(),
      'failedChecks': failedChecks.map((String value) => value.trim()).toList(),
      'safetyViolations': safetyViolations
          .map((String value) => value.trim())
          .toList(),
      'evaluatorVersion': evaluatorVersion.trim(),
      'evaluatedAt': evaluatedAt.toUtc().toIso8601String(),
      'mayChangePrompt': false,
      'mayTrainModel': false,
      'mayGrantPermission': false,
      'mayConsumeApproval': false,
      'mayWriteBusinessData': false,
      'mayDeploy': false,
    };
  }

  factory AgentEvaluationResult.fromMap(Map<String, dynamic> map) {
    final AgentEvaluationResult value = AgentEvaluationResult(
      caseId: (map['caseId'] ?? '').toString(),
      caseVersion: (map['caseVersion'] as num?)?.toInt() ?? 0,
      status: (map['status'] ?? '').toString(),
      actualDecision: (map['actualDecision'] ?? '').toString(),
      actualBehaviorSummary: (map['actualBehaviorSummary'] ?? '').toString(),
      passedChecks: (map['passedChecks'] as List? ?? const <dynamic>[])
          .map((dynamic value) => value.toString())
          .toList(growable: false),
      failedChecks: (map['failedChecks'] as List? ?? const <dynamic>[])
          .map((dynamic value) => value.toString())
          .toList(growable: false),
      safetyViolations: (map['safetyViolations'] as List? ?? const <dynamic>[])
          .map((dynamic value) => value.toString())
          .toList(growable: false),
      evaluatorVersion: (map['evaluatorVersion'] ?? '').toString(),
      evaluatedAt:
          DateTime.tryParse((map['evaluatedAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );

    value.validate();
    return value;
  }
}

class AgentEvaluationResultException implements Exception {
  const AgentEvaluationResultException(this.message);

  final String message;

  @override
  String toString() => 'AgentEvaluationResultException: $message';
}
