import 'agent_evaluation_result.dart';

/// Immutable evidence for one completed offline evaluation run.
///
/// Phase 42 run records are descriptive evidence only. They do not train a
/// model, mutate prompts, grant runtime authority, consume approvals, write
/// business data, call a provider, or deploy anything.
class AgentEvaluationRun {
  const AgentEvaluationRun({
    required this.runId,
    required this.catalogVersion,
    required this.evaluatorVersion,
    required this.policyVersion,
    required this.totalCount,
    required this.passedCount,
    required this.failedCount,
    required this.blockedCount,
    required this.passPercent,
    required this.weightedScorePercent,
    required this.criticalFailureCount,
    required this.highFailureCount,
    required this.safetyViolationCount,
    required this.thresholdPassed,
    required this.failClosed,
    required this.eligibleForHumanReview,
    required this.results,
    required this.startedAt,
    required this.completedAt,
  });

  final String runId;
  final String catalogVersion;
  final String evaluatorVersion;
  final String policyVersion;

  final int totalCount;
  final int passedCount;
  final int failedCount;
  final int blockedCount;

  final double passPercent;
  final double weightedScorePercent;

  final int criticalFailureCount;
  final int highFailureCount;
  final int safetyViolationCount;

  final bool thresholdPassed;
  final bool failClosed;
  final bool eligibleForHumanReview;

  final List<AgentEvaluationResult> results;

  final DateTime startedAt;
  final DateTime completedAt;

  bool get isReadOnlyEvidence => true;
  bool get mayChangePrompt => false;
  bool get mayTrainModel => false;
  bool get mayGrantPermission => false;
  bool get mayConsumeApproval => false;
  bool get mayWriteBusinessData => false;
  bool get mayCallProvider => false;
  bool get mayDeploy => false;

  void validate() {
    if (runId.trim().isEmpty ||
        catalogVersion.trim().isEmpty ||
        evaluatorVersion.trim().isEmpty ||
        policyVersion.trim().isEmpty) {
      throw const AgentEvaluationRunException(
        'Evaluation run identity/version fields cannot be empty.',
      );
    }

    if (totalCount <= 0 ||
        passedCount < 0 ||
        failedCount < 0 ||
        blockedCount < 0 ||
        criticalFailureCount < 0 ||
        highFailureCount < 0 ||
        safetyViolationCount < 0) {
      throw const AgentEvaluationRunException(
        'Evaluation run counts are invalid.',
      );
    }

    if (results.length != totalCount) {
      throw const AgentEvaluationRunException(
        'Evaluation run result count must equal totalCount.',
      );
    }

    if (passedCount + failedCount + blockedCount != totalCount) {
      throw const AgentEvaluationRunException(
        'Evaluation run status counts must equal totalCount.',
      );
    }

    if (passPercent < 0 ||
        passPercent > 100 ||
        weightedScorePercent < 0 ||
        weightedScorePercent > 100) {
      throw const AgentEvaluationRunException(
        'Evaluation run percentages are invalid.',
      );
    }

    if (completedAt.isBefore(startedAt)) {
      throw const AgentEvaluationRunException(
        'Evaluation run completedAt cannot be before startedAt.',
      );
    }

    if (eligibleForHumanReview &&
        (!thresholdPassed || failClosed || blockedCount > 0)) {
      throw const AgentEvaluationRunException(
        'Human review eligibility cannot bypass policy safety.',
      );
    }

    final Set<String> identities = <String>{};

    for (final AgentEvaluationResult result in results) {
      result.validate();

      final String identity = '${result.caseId}@${result.caseVersion}';

      if (!identities.add(identity)) {
        throw AgentEvaluationRunException(
          'Duplicate evaluation result identity "$identity".',
        );
      }
    }
  }

  Map<String, dynamic> toMap() {
    validate();

    return <String, dynamic>{
      'runId': runId.trim(),
      'catalogVersion': catalogVersion.trim(),
      'evaluatorVersion': evaluatorVersion.trim(),
      'policyVersion': policyVersion.trim(),
      'totalCount': totalCount,
      'passedCount': passedCount,
      'failedCount': failedCount,
      'blockedCount': blockedCount,
      'passPercent': passPercent,
      'weightedScorePercent': weightedScorePercent,
      'criticalFailureCount': criticalFailureCount,
      'highFailureCount': highFailureCount,
      'safetyViolationCount': safetyViolationCount,
      'thresholdPassed': thresholdPassed,
      'failClosed': failClosed,
      'eligibleForHumanReview': eligibleForHumanReview,
      'results': results
          .map((AgentEvaluationResult result) => result.toMap())
          .toList(growable: false),
      'startedAt': startedAt.toUtc().toIso8601String(),
      'completedAt': completedAt.toUtc().toIso8601String(),
      'isReadOnlyEvidence': true,
      'mayChangePrompt': false,
      'mayTrainModel': false,
      'mayGrantPermission': false,
      'mayConsumeApproval': false,
      'mayWriteBusinessData': false,
      'mayCallProvider': false,
      'mayDeploy': false,
    };
  }

  factory AgentEvaluationRun.fromMap(Map<String, dynamic> map) {
    final AgentEvaluationRun value = AgentEvaluationRun(
      runId: (map['runId'] ?? '').toString(),
      catalogVersion: (map['catalogVersion'] ?? '').toString(),
      evaluatorVersion: (map['evaluatorVersion'] ?? '').toString(),
      policyVersion: (map['policyVersion'] ?? '').toString(),
      totalCount: (map['totalCount'] as num?)?.toInt() ?? 0,
      passedCount: (map['passedCount'] as num?)?.toInt() ?? 0,
      failedCount: (map['failedCount'] as num?)?.toInt() ?? 0,
      blockedCount: (map['blockedCount'] as num?)?.toInt() ?? 0,
      passPercent: (map['passPercent'] as num?)?.toDouble() ?? 0,
      weightedScorePercent:
          (map['weightedScorePercent'] as num?)?.toDouble() ?? 0,
      criticalFailureCount: (map['criticalFailureCount'] as num?)?.toInt() ?? 0,
      highFailureCount: (map['highFailureCount'] as num?)?.toInt() ?? 0,
      safetyViolationCount: (map['safetyViolationCount'] as num?)?.toInt() ?? 0,
      thresholdPassed: map['thresholdPassed'] == true,
      failClosed: map['failClosed'] == true,
      eligibleForHumanReview: map['eligibleForHumanReview'] == true,
      results: (map['results'] as List? ?? const <dynamic>[])
          .map(
            (dynamic raw) => AgentEvaluationResult.fromMap(
              Map<String, dynamic>.from(raw as Map),
            ),
          )
          .toList(growable: false),
      startedAt:
          DateTime.tryParse((map['startedAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      completedAt:
          DateTime.tryParse((map['completedAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );

    value.validate();
    return value;
  }
}

class AgentEvaluationRunException implements Exception {
  const AgentEvaluationRunException(this.message);

  final String message;

  @override
  String toString() => 'AgentEvaluationRunException: $message';
}
