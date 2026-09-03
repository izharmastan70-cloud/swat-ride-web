import '../models/agent_crash_assessment.dart';
import '../models/agent_crash_event.dart';
import 'agent_crash_classifier.dart';
import 'agent_crash_event_service.dart';

// =========================================================
// AI AGENT — CRASH MONITOR AGENT
// =========================================================
//
// FREE_AI monitoring only.
//
// It classifies and decides whether a technical issue should be handed
// to Code Agent. It NEVER invokes Paid Code AI directly in Phase 14.

class AgentCrashMonitorAgent {
  final AgentCrashClassifier classifier;
  final AgentCrashEventService crashService;

  AgentCrashMonitorAgent({
    AgentCrashClassifier? classifier,
    AgentCrashEventService? crashService,
  })  : classifier = classifier ?? const AgentCrashClassifier(),
        crashService = crashService ?? AgentCrashEventService();

  Future<AgentCrashAssessment> classify(
    AgentCrashEvent event,
  ) async {
    final AgentCrashAssessment assessment =
        classifier.assess(event);

    await crashService.markClassification(
      crashId: event.crashId,
      severity: assessment.severity,
      category: assessment.category,
    );

    return assessment;
  }

  Future<void> markHandoffPrepared(
    AgentCrashEvent event,
  ) async {
    // This only marks that the handoff is prepared.
    // Phase 15 Paid Code AI connection will require owner-controlled
    // approval before any paid request is made.
    await crashService.markHandedToCodeAgent(event.crashId);
  }
}
