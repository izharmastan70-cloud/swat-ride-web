import '../models/admin_intelligence_health_snapshot.dart';
import '../models/admin_intelligence_reasoning_policy.dart';
import '../models/admin_intelligence_report.dart';
import 'admin_intelligence_periodic_scheduler.dart';
import 'admin_intelligence_snapshot_report_bridge.dart';
import 'admin_intelligence_source_adapter.dart';
import 'admin_intelligence_source_registry.dart';

class AdminIntelligencePeriodicRunPlan {
  const AdminIntelligencePeriodicRunPlan({
    required this.shouldRun,
    required this.scheduleReason,
    required this.nextEligibleAt,
    required this.reasoningDecision,
    this.snapshot,
    this.report,
  });

  final bool shouldRun;
  final String scheduleReason;
  final DateTime nextEligibleAt;

  final AdminIntelligenceHealthSnapshot? snapshot;
  final AdminIntelligenceReport? report;

  /// Routing decision only. This orchestrator never calls a provider itself.
  final AdminIntelligenceReasoningDecision reasoningDecision;
}

/// Coordinates periodic read-only Admin Intelligence reporting.
///
/// Flow:
/// schedule policy
/// -> authorized read-only source batches
/// -> health snapshot
/// -> verified/candidate report
/// -> Free-first reasoning route decision
///
/// It does NOT:
/// - call Free/Local/Paid providers itself
/// - write Firestore
/// - perform Admin operational actions
/// - deploy production
class AdminIntelligencePeriodicReportOrchestrator {
  const AdminIntelligencePeriodicReportOrchestrator({
    this.scheduler = const AdminIntelligencePeriodicScheduler(),
    this.sourceRegistry = const AdminIntelligenceSourceRegistry(),
    this.reportBridge = const AdminIntelligenceSnapshotReportBridge(),
  });

  final AdminIntelligencePeriodicScheduler scheduler;
  final AdminIntelligenceSourceRegistry sourceRegistry;
  final AdminIntelligenceSnapshotReportBridge reportBridge;

  AdminIntelligencePeriodicRunPlan prepareRun({
    required DateTime now,
    required bool enabled,
    required String snapshotId,
    required DateTime windowStart,
    required DateTime windowEnd,
    required Iterable<AdminIntelligenceSourceBatch> batches,
    required AdminIntelligenceReasoningPolicy reasoningPolicy,
    required AdminIntelligenceReasoningState reasoningState,
    required AdminIntelligencePaidBudget paidBudget,
    DateTime? lastSuccessfulRunAt,
  }) {
    final scheduleDecision = scheduler.evaluate(
      now: now,
      lastSuccessfulRunAt: lastSuccessfulRunAt,
      enabled: enabled,
    );

    final reasoningDecision = reasoningPolicy.decideNext(
      state: reasoningState,
      paidBudget: paidBudget,
    );

    if (!scheduleDecision.shouldRun) {
      return AdminIntelligencePeriodicRunPlan(
        shouldRun: false,
        scheduleReason: scheduleDecision.reason,
        nextEligibleAt: scheduleDecision.nextEligibleAt,
        reasoningDecision: reasoningDecision,
      );
    }

    final snapshot = sourceRegistry.buildSnapshot(
      snapshotId: snapshotId,
      generatedAt: now,
      windowStart: windowStart,
      windowEnd: windowEnd,
      batches: batches,
    );

    final report = reportBridge.buildReportFromSnapshot(snapshot);

    return AdminIntelligencePeriodicRunPlan(
      shouldRun: true,
      scheduleReason: scheduleDecision.reason,
      nextEligibleAt: now.add(scheduler.interval),
      snapshot: snapshot,
      report: report,
      reasoningDecision: reasoningDecision,
    );
  }
}
