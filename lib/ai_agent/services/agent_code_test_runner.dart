import '../constants/agent_code_change_constants.dart';
import '../models/agent_code_test_result.dart';

// =========================================================
// AI AGENT — CODE TEST RUNNER CONTRACT
// =========================================================
//
// Real `flutter analyze`, tests and build execution are intentionally not
// connected in Phase 16.

abstract class AgentCodeTestRunner {
  Future<AgentCodeTestResult> run();
}

class AgentPlaceholderCodeTestRunner implements AgentCodeTestRunner {
  const AgentPlaceholderCodeTestRunner();

  @override
  Future<AgentCodeTestResult> run() async {
    return AgentCodeTestResult(
      analyzeStatus: AgentCodeTestStatus.unavailable,
      unitTestStatus: AgentCodeTestStatus.unavailable,
      buildStatus: AgentCodeTestStatus.unavailable,
      outputSummary:
          'Real Flutter analyze/test/build runner is not connected yet.',
      completedAt: DateTime.now(),
    );
  }
}
