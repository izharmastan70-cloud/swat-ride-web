import '../constants/agent_performance_dashboard_constants.dart';
import '../models/agent_performance_dashboard_agent_summary.dart';
import '../models/agent_performance_dashboard_query.dart';
import '../models/agent_performance_dashboard_read_model.dart';
import 'agent_performance_dashboard_filter_sort_policy.dart';

class AgentPerformanceDashboardReadModelService {
  const AgentPerformanceDashboardReadModelService({
    this.filterSortPolicy = const AgentPerformanceDashboardFilterSortPolicy(),
  });

  final AgentPerformanceDashboardFilterSortPolicy filterSortPolicy;

  AgentPerformanceDashboardReadModel build({
    required AgentPerformanceDashboardQuery query,
    required List<AgentPerformanceDashboardAgentSummary> summaries,
  }) {
    try {
      query.validateStructure();

      if (summaries.length >
          AgentPerformanceDashboardLimits.maxInputSummaries) {
        return _blocked(
          status: AgentPerformanceDashboardStatus.blockedInvalidInput,
          queryId: query.queryId,
          reason: 'too_many_dashboard_summaries',
        );
      }

      final Set<String> identities = <String>{};

      for (final AgentPerformanceDashboardAgentSummary summary in summaries) {
        summary.validateStructure();

        if (!identities.add(summary.summaryIdentity)) {
          return _blocked(
            status: AgentPerformanceDashboardStatus.blockedDuplicateSummary,
            queryId: query.queryId,
            reason: 'duplicate_agent_cohort_window_summary',
          );
        }
      }
    } catch (_) {
      return _blocked(
        status: AgentPerformanceDashboardStatus.blockedInvalidInput,
        queryId: query.queryId,
        reason: 'invalid_dashboard_input',
      );
    }

    if (!query.fairScoreSortPreconditionsSatisfied) {
      return _blocked(
        status: AgentPerformanceDashboardStatus.blockedUnfairScoreSort,
        queryId: query.queryId,
        reason: 'score_sort_requires_fair_comparison_boundary',
      );
    }

    final List<AgentPerformanceDashboardAgentSummary> ordered = filterSortPolicy
        .filterAndSort(query: query, summaries: summaries);

    if (ordered.isEmpty) {
      return _model(
        status: AgentPerformanceDashboardStatus.empty,
        queryId: query.queryId,
        summaries: const <AgentPerformanceDashboardAgentSummary>[],
        totalMatchedBeforeLimit: 0,
        truncated: false,
        reason: 'no_matching_summaries',
      );
    }

    final int total = ordered.length;
    final bool truncated = total > query.limit;
    final List<AgentPerformanceDashboardAgentSummary> visible = ordered
        .take(query.limit)
        .toList(growable: false);

    return _model(
      status: AgentPerformanceDashboardStatus.ready,
      queryId: query.queryId,
      summaries: visible,
      totalMatchedBeforeLimit: total,
      truncated: truncated,
      reason: 'read_only_dashboard_projection_ready',
    );
  }

  AgentPerformanceDashboardReadModel _blocked({
    required String status,
    required String queryId,
    required String reason,
  }) {
    return _model(
      status: status,
      queryId: queryId.trim().isEmpty ? 'invalid:query' : queryId,
      summaries: const <AgentPerformanceDashboardAgentSummary>[],
      totalMatchedBeforeLimit: 0,
      truncated: false,
      reason: reason,
    );
  }

  AgentPerformanceDashboardReadModel _model({
    required String status,
    required String queryId,
    required List<AgentPerformanceDashboardAgentSummary> summaries,
    required int totalMatchedBeforeLimit,
    required bool truncated,
    required String reason,
  }) {
    final AgentPerformanceDashboardReadModel model =
        AgentPerformanceDashboardReadModel(
          status: status,
          queryId: queryId,
          summaries: summaries,
          totalMatchedBeforeLimit: totalMatchedBeforeLimit,
          truncated: truncated,
          reasonCode: reason,
        );

    model.validateStructure();
    return model;
  }

  bool get readOnlyProjectionOnly => true;
  bool get filterSortVisibilityOnly => true;
  bool get duplicateSummaryFailsClosed => true;
  bool get unfairScoreSortFailsClosed => true;
  bool get presentationOrderNeverPermanentRank => true;

  bool get dashboardCanGrantPermission => false;
  bool get dashboardCanCreateApproval => false;
  bool get dashboardCanExpandScope => false;
  bool get dashboardCanAssignRole => false;
  bool get dashboardCanGrantOwnerAuthority => false;
  bool get dashboardCanExecuteBusinessAction => false;
  bool get dashboardCanModifySecurityEngine => false;

  bool get firestoreWriteImplementedHere => false;
  bool get providerInvocationImplementedHere => false;
  bool get routingMutationImplementedHere => false;
  bool get agentStateMutationImplementedHere => false;
  bool get payMutationImplementedHere => false;
  bool get accessMutationImplementedHere => false;
  bool get budgetMutationImplementedHere => false;
  bool get persistenceImplementedHere => false;

  bool get securityAuthorityAlwaysAboveDashboard => true;
  bool get step1FPrivacyFailureIsolationSeparate => true;
  bool get step1GFinalCloseoutSeparate => true;
}
