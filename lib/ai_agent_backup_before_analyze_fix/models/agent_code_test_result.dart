import '../constants/agent_code_change_constants.dart';

// =========================================================
// AI AGENT — CODE TEST RESULT
// =========================================================

class AgentCodeTestResult {
  final String analyzeStatus;
  final String unitTestStatus;
  final String buildStatus;
  final String outputSummary;
  final DateTime completedAt;

  const AgentCodeTestResult({
    required this.analyzeStatus,
    required this.unitTestStatus,
    required this.buildStatus,
    required this.outputSummary,
    required this.completedAt,
  });

  bool get allPassed =>
      analyzeStatus == AgentCodeTestStatus.passed &&
      (unitTestStatus == AgentCodeTestStatus.passed ||
          unitTestStatus == AgentCodeTestStatus.unavailable) &&
      (buildStatus == AgentCodeTestStatus.passed ||
          buildStatus == AgentCodeTestStatus.unavailable);
}
