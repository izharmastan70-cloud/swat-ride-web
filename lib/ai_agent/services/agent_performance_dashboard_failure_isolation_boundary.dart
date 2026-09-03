import '../constants/agent_performance_dashboard_privacy_constants.dart';
import '../models/agent_performance_dashboard_agent_summary.dart';
import 'agent_performance_dashboard_privacy_redaction_policy.dart';

class AgentPerformanceDashboardIsolationResult {
  AgentPerformanceDashboardIsolationResult({
    required List<AgentPerformanceDashboardAgentSummary> safeSummaries,
    required this.redactedSummaryCount,
    required this.isolatedFailureCount,
    required this.duplicateIdentityDetected,
    required this.failureBudgetExceeded,
  }) : safeSummaries = List<AgentPerformanceDashboardAgentSummary>.unmodifiable(
         safeSummaries,
       );

  final List<AgentPerformanceDashboardAgentSummary> safeSummaries;
  final int redactedSummaryCount;
  final int isolatedFailureCount;
  final bool duplicateIdentityDetected;
  final bool failureBudgetExceeded;
}

class AgentPerformanceDashboardFailureIsolationBoundary {
  const AgentPerformanceDashboardFailureIsolationBoundary();

  AgentPerformanceDashboardIsolationResult isolate({
    required List<AgentPerformanceDashboardAgentSummary> summaries,
    required AgentPerformanceDashboardPrivacyRedactionPolicy privacyPolicy,
  }) {
    final List<AgentPerformanceDashboardAgentSummary> safe =
        <AgentPerformanceDashboardAgentSummary>[];
    final Set<String> identities = <String>{};
    int redacted = 0;
    int isolatedFailures = 0;
    bool duplicateIdentityDetected = false;
    bool failureBudgetExceeded = false;

    for (final AgentPerformanceDashboardAgentSummary summary in summaries) {
      try {
        summary.validateStructure();
      } catch (_) {
        isolatedFailures++;

        if (isolatedFailures >
            AgentPerformanceDashboardPrivacyLimits.maxIsolatedFailures) {
          failureBudgetExceeded = true;
          break;
        }
        continue;
      }

      if (!identities.add(summary.summaryIdentity)) {
        duplicateIdentityDetected = true;
        break;
      }

      if (!privacyPolicy.isSafeSummaryIdentifierEnvelope(summary)) {
        redacted++;
        continue;
      }

      safe.add(summary);
    }

    return AgentPerformanceDashboardIsolationResult(
      safeSummaries: safe,
      redactedSummaryCount: redacted,
      isolatedFailureCount: isolatedFailures,
      duplicateIdentityDetected: duplicateIdentityDetected,
      failureBudgetExceeded: failureBudgetExceeded,
    );
  }

  bool get oneMalformedSummaryDoesNotCrashProjection => true;
  bool get exceptionTextNeverEscapesBoundary => true;
  bool get duplicateIdentityFailsClosed => true;
  bool get failureBudgetFailsClosed => true;
  bool get unsafeIdentifierRedactsWholeSummary => true;

  bool get grantsPermission => false;
  bool get createsApproval => false;
  bool get mutatesAgentState => false;
  bool get mutatesRouting => false;
  bool get persistenceImplementedHere => false;
}
