class AdminIntelligenceScheduleDecision {
  const AdminIntelligenceScheduleDecision({
    required this.shouldRun,
    required this.nextEligibleAt,
    required this.reason,
  });

  final bool shouldRun;
  final DateTime nextEligibleAt;
  final String reason;
}

/// Pure scheduling policy only.
///
/// It does NOT start a background worker by itself.
/// It does NOT call an AI provider.
/// It does NOT write Firestore.
/// A future authorized runtime/orchestrator may consult this contract.
class AdminIntelligencePeriodicScheduler {
  const AdminIntelligencePeriodicScheduler({
    this.interval = const Duration(hours: 24),
  });

  final Duration interval;

  AdminIntelligenceScheduleDecision evaluate({
    required DateTime now,
    DateTime? lastSuccessfulRunAt,
    bool enabled = true,
  }) {
    if (interval <= Duration.zero) {
      throw ArgumentError(
        'Admin Intelligence schedule interval must be positive.',
      );
    }

    if (!enabled) {
      return AdminIntelligenceScheduleDecision(
        shouldRun: false,
        nextEligibleAt: now.add(interval),
        reason: 'admin_intelligence_disabled',
      );
    }

    if (lastSuccessfulRunAt == null) {
      return AdminIntelligenceScheduleDecision(
        shouldRun: true,
        nextEligibleAt: now,
        reason: 'first_run_due',
      );
    }

    final nextEligible = lastSuccessfulRunAt.add(interval);

    if (!now.isBefore(nextEligible)) {
      return AdminIntelligenceScheduleDecision(
        shouldRun: true,
        nextEligibleAt: nextEligible,
        reason: 'periodic_run_due',
      );
    }

    return AdminIntelligenceScheduleDecision(
      shouldRun: false,
      nextEligibleAt: nextEligible,
      reason: 'interval_not_elapsed',
    );
  }
}
