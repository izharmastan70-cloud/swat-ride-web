import '../constants/agent_performance_dashboard_constants.dart';
import '../constants/agent_performance_dashboard_privacy_constants.dart';
import '../models/agent_performance_dashboard_agent_summary.dart';
import '../models/agent_performance_dashboard_read_model.dart';
import '../models/agent_performance_dashboard_safe_projection.dart';
import 'agent_performance_dashboard_failure_isolation_boundary.dart';
import 'agent_performance_dashboard_freshness_policy.dart';
import 'agent_performance_dashboard_privacy_redaction_policy.dart';

class AgentPerformanceDashboardSafeProjectionService {
  const AgentPerformanceDashboardSafeProjectionService({
    this.privacyPolicy =
        const AgentPerformanceDashboardPrivacyRedactionPolicy(),
    this.freshnessPolicy = const AgentPerformanceDashboardFreshnessPolicy(),
    this.failureIsolationBoundary =
        const AgentPerformanceDashboardFailureIsolationBoundary(),
  });

  final AgentPerformanceDashboardPrivacyRedactionPolicy privacyPolicy;
  final AgentPerformanceDashboardFreshnessPolicy freshnessPolicy;
  final AgentPerformanceDashboardFailureIsolationBoundary
  failureIsolationBoundary;

  AgentPerformanceDashboardSafeProjection build({
    required AgentPerformanceDashboardReadModel source,
    required DateTime snapshotGeneratedAtUtc,
    required DateTime evaluatedAtUtc,
    Duration maxAge =
        AgentPerformanceDashboardPrivacyLimits.defaultMaxSnapshotAge,
  }) {
    final String safeQueryId = privacyPolicy.safeQueryIdOrRedacted(
      source.queryId,
    );

    if (!_sourceEnvelopeValid(source)) {
      return _blocked(
        status: AgentPerformanceDashboardSafeProjectionStatus.blockedSource,
        sourceStatus: source.status,
        queryId: safeQueryId,
        sourceTotalMatchedBeforeLimit: 0,
        sourceTruncated: false,
        redactedSummaryCount: 0,
        isolatedFailureCount: 0,
        snapshotGeneratedAtUtc: _utcOrEpoch(snapshotGeneratedAtUtc),
        evaluatedAtUtc: _utcOrEpoch(evaluatedAtUtc),
        freshnessState:
            AgentPerformanceDashboardFreshnessState.invalidTimestamp,
        reason: AgentPerformanceDashboardSafeReasonCode.invalidSourceEnvelope,
      );
    }

    if (!privacyPolicy.isSafeOpaqueIdentifier(source.queryId)) {
      return _blocked(
        status: AgentPerformanceDashboardSafeProjectionStatus.blockedPrivacy,
        sourceStatus: source.status,
        queryId: safeQueryId,
        sourceTotalMatchedBeforeLimit: source.totalMatchedBeforeLimit,
        sourceTruncated: source.truncated,
        redactedSummaryCount: 0,
        isolatedFailureCount: 0,
        snapshotGeneratedAtUtc: _utcOrEpoch(snapshotGeneratedAtUtc),
        evaluatedAtUtc: _utcOrEpoch(evaluatedAtUtc),
        freshnessState: snapshotGeneratedAtUtc.isUtc && evaluatedAtUtc.isUtc
            ? AgentPerformanceDashboardFreshnessState.fresh
            : AgentPerformanceDashboardFreshnessState.invalidTimestamp,
        reason: AgentPerformanceDashboardSafeReasonCode.unsafeQueryId,
      );
    }

    if (source.status != AgentPerformanceDashboardStatus.ready &&
        source.status != AgentPerformanceDashboardStatus.empty) {
      return _blocked(
        status: AgentPerformanceDashboardSafeProjectionStatus.blockedSource,
        sourceStatus: source.status,
        queryId: safeQueryId,
        sourceTotalMatchedBeforeLimit: source.totalMatchedBeforeLimit,
        sourceTruncated: source.truncated,
        redactedSummaryCount: 0,
        isolatedFailureCount: 0,
        snapshotGeneratedAtUtc: _utcOrEpoch(snapshotGeneratedAtUtc),
        evaluatedAtUtc: _utcOrEpoch(evaluatedAtUtc),
        freshnessState: snapshotGeneratedAtUtc.isUtc && evaluatedAtUtc.isUtc
            ? AgentPerformanceDashboardFreshnessState.fresh
            : AgentPerformanceDashboardFreshnessState.invalidTimestamp,
        reason: AgentPerformanceDashboardSafeReasonCode.sourceBlocked,
      );
    }

    final AgentPerformanceDashboardFreshnessDecision freshness = freshnessPolicy
        .evaluate(
          snapshotGeneratedAtUtc: snapshotGeneratedAtUtc,
          evaluatedAtUtc: evaluatedAtUtc,
          maxAge: maxAge,
        );

    if (freshness.invalidTimestamp || freshness.futureClockSkew) {
      return _blocked(
        status: AgentPerformanceDashboardSafeProjectionStatus.blockedClockSkew,
        sourceStatus: source.status,
        queryId: safeQueryId,
        sourceTotalMatchedBeforeLimit: source.totalMatchedBeforeLimit,
        sourceTruncated: source.truncated,
        redactedSummaryCount: 0,
        isolatedFailureCount: 0,
        snapshotGeneratedAtUtc: _utcOrEpoch(snapshotGeneratedAtUtc),
        evaluatedAtUtc: _utcOrEpoch(evaluatedAtUtc),
        freshnessState: freshness.state,
        reason: AgentPerformanceDashboardSafeReasonCode.clockSkew,
      );
    }

    if (freshness.stale) {
      return _blocked(
        status: AgentPerformanceDashboardSafeProjectionStatus.blockedStaleData,
        sourceStatus: source.status,
        queryId: safeQueryId,
        sourceTotalMatchedBeforeLimit: source.totalMatchedBeforeLimit,
        sourceTruncated: source.truncated,
        redactedSummaryCount: 0,
        isolatedFailureCount: 0,
        snapshotGeneratedAtUtc: snapshotGeneratedAtUtc,
        evaluatedAtUtc: evaluatedAtUtc,
        freshnessState: freshness.state,
        reason: AgentPerformanceDashboardSafeReasonCode.staleSnapshot,
      );
    }

    if (source.status == AgentPerformanceDashboardStatus.empty) {
      return _projection(
        status: AgentPerformanceDashboardSafeProjectionStatus.empty,
        sourceStatus: source.status,
        queryId: safeQueryId,
        summaries: const <AgentPerformanceDashboardAgentSummary>[],
        sourceTotalMatchedBeforeLimit: source.totalMatchedBeforeLimit,
        sourceTruncated: source.truncated,
        redactedSummaryCount: 0,
        isolatedFailureCount: 0,
        snapshotGeneratedAtUtc: snapshotGeneratedAtUtc,
        evaluatedAtUtc: evaluatedAtUtc,
        freshnessState: freshness.state,
        reason: AgentPerformanceDashboardSafeReasonCode.sourceEmpty,
      );
    }

    final AgentPerformanceDashboardIsolationResult isolated =
        failureIsolationBoundary.isolate(
          summaries: source.summaries,
          privacyPolicy: privacyPolicy,
        );

    if (isolated.duplicateIdentityDetected) {
      return _blocked(
        status: AgentPerformanceDashboardSafeProjectionStatus.blockedSource,
        sourceStatus: source.status,
        queryId: safeQueryId,
        sourceTotalMatchedBeforeLimit: source.totalMatchedBeforeLimit,
        sourceTruncated: source.truncated,
        redactedSummaryCount: isolated.redactedSummaryCount,
        isolatedFailureCount: isolated.isolatedFailureCount,
        snapshotGeneratedAtUtc: snapshotGeneratedAtUtc,
        evaluatedAtUtc: evaluatedAtUtc,
        freshnessState: freshness.state,
        reason: AgentPerformanceDashboardSafeReasonCode.duplicateSummary,
      );
    }

    if (isolated.failureBudgetExceeded) {
      return _blocked(
        status: AgentPerformanceDashboardSafeProjectionStatus.blockedSource,
        sourceStatus: source.status,
        queryId: safeQueryId,
        sourceTotalMatchedBeforeLimit: source.totalMatchedBeforeLimit,
        sourceTruncated: source.truncated,
        redactedSummaryCount: isolated.redactedSummaryCount,
        isolatedFailureCount: isolated.isolatedFailureCount,
        snapshotGeneratedAtUtc: snapshotGeneratedAtUtc,
        evaluatedAtUtc: evaluatedAtUtc,
        freshnessState: freshness.state,
        reason: AgentPerformanceDashboardSafeReasonCode.isolationBudgetExceeded,
      );
    }

    if (isolated.safeSummaries.isEmpty) {
      if (isolated.redactedSummaryCount > 0) {
        return _blocked(
          status: AgentPerformanceDashboardSafeProjectionStatus.blockedPrivacy,
          sourceStatus: source.status,
          queryId: safeQueryId,
          sourceTotalMatchedBeforeLimit: source.totalMatchedBeforeLimit,
          sourceTruncated: source.truncated,
          redactedSummaryCount: isolated.redactedSummaryCount,
          isolatedFailureCount: isolated.isolatedFailureCount,
          snapshotGeneratedAtUtc: snapshotGeneratedAtUtc,
          evaluatedAtUtc: evaluatedAtUtc,
          freshnessState: freshness.state,
          reason: AgentPerformanceDashboardSafeReasonCode.allSummariesRedacted,
        );
      }

      return _blocked(
        status: AgentPerformanceDashboardSafeProjectionStatus.blockedSource,
        sourceStatus: source.status,
        queryId: safeQueryId,
        sourceTotalMatchedBeforeLimit: source.totalMatchedBeforeLimit,
        sourceTruncated: source.truncated,
        redactedSummaryCount: isolated.redactedSummaryCount,
        isolatedFailureCount: isolated.isolatedFailureCount,
        snapshotGeneratedAtUtc: snapshotGeneratedAtUtc,
        evaluatedAtUtc: evaluatedAtUtc,
        freshnessState: freshness.state,
        reason: AgentPerformanceDashboardSafeReasonCode.allSummariesFailed,
      );
    }

    final bool degraded =
        isolated.redactedSummaryCount > 0 || isolated.isolatedFailureCount > 0;

    return _projection(
      status: degraded
          ? AgentPerformanceDashboardSafeProjectionStatus.degraded
          : AgentPerformanceDashboardSafeProjectionStatus.ready,
      sourceStatus: source.status,
      queryId: safeQueryId,
      summaries: isolated.safeSummaries,
      sourceTotalMatchedBeforeLimit: source.totalMatchedBeforeLimit,
      sourceTruncated: source.truncated,
      redactedSummaryCount: isolated.redactedSummaryCount,
      isolatedFailureCount: isolated.isolatedFailureCount,
      snapshotGeneratedAtUtc: snapshotGeneratedAtUtc,
      evaluatedAtUtc: evaluatedAtUtc,
      freshnessState: freshness.state,
      reason: degraded
          ? AgentPerformanceDashboardSafeReasonCode.degraded
          : AgentPerformanceDashboardSafeReasonCode.ready,
    );
  }

  bool _sourceEnvelopeValid(AgentPerformanceDashboardReadModel source) {
    if (!AgentPerformanceDashboardStatus.values.contains(source.status) ||
        source.queryId.trim().isEmpty ||
        source.queryId.length >
            AgentPerformanceDashboardPrivacyLimits.opaqueIdMaxLength ||
        source.totalMatchedBeforeLimit < 0 ||
        source.reasonCode.trim().isEmpty ||
        source.summaries.length >
            AgentPerformanceDashboardLimits.maxQueryLimit) {
      return false;
    }

    if (source.status == AgentPerformanceDashboardStatus.ready &&
        source.summaries.isEmpty) {
      return false;
    }

    if (source.status == AgentPerformanceDashboardStatus.empty &&
        source.summaries.isNotEmpty) {
      return false;
    }

    if (source.status != AgentPerformanceDashboardStatus.ready &&
        source.status != AgentPerformanceDashboardStatus.empty &&
        source.summaries.isNotEmpty) {
      return false;
    }

    return true;
  }

  String _safeSourceStatus(String value) {
    if (AgentPerformanceDashboardStatus.values.contains(value)) {
      return value;
    }
    return AgentPerformanceDashboardStatus.blockedInvalidInput;
  }

  DateTime _utcOrEpoch(DateTime value) {
    if (value.isUtc) return value;
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  AgentPerformanceDashboardSafeProjection _blocked({
    required String status,
    required String sourceStatus,
    required String queryId,
    required int sourceTotalMatchedBeforeLimit,
    required bool sourceTruncated,
    required int redactedSummaryCount,
    required int isolatedFailureCount,
    required DateTime snapshotGeneratedAtUtc,
    required DateTime evaluatedAtUtc,
    required String freshnessState,
    required String reason,
  }) {
    return _projection(
      status: status,
      sourceStatus: _safeSourceStatus(sourceStatus),
      queryId: queryId,
      summaries: const <AgentPerformanceDashboardAgentSummary>[],
      sourceTotalMatchedBeforeLimit: sourceTotalMatchedBeforeLimit,
      sourceTruncated: sourceTruncated,
      redactedSummaryCount: redactedSummaryCount,
      isolatedFailureCount: isolatedFailureCount,
      snapshotGeneratedAtUtc: snapshotGeneratedAtUtc,
      evaluatedAtUtc: evaluatedAtUtc,
      freshnessState: freshnessState,
      reason: reason,
    );
  }

  AgentPerformanceDashboardSafeProjection _projection({
    required String status,
    required String sourceStatus,
    required String queryId,
    required List<AgentPerformanceDashboardAgentSummary> summaries,
    required int sourceTotalMatchedBeforeLimit,
    required bool sourceTruncated,
    required int redactedSummaryCount,
    required int isolatedFailureCount,
    required DateTime snapshotGeneratedAtUtc,
    required DateTime evaluatedAtUtc,
    required String freshnessState,
    required String reason,
  }) {
    final AgentPerformanceDashboardSafeProjection projection =
        AgentPerformanceDashboardSafeProjection(
          status: status,
          sourceStatus: sourceStatus,
          queryId: queryId,
          summaries: summaries,
          sourceTotalMatchedBeforeLimit: sourceTotalMatchedBeforeLimit,
          sourceTruncated: sourceTruncated,
          redactedSummaryCount: redactedSummaryCount,
          isolatedFailureCount: isolatedFailureCount,
          snapshotGeneratedAtUtc: snapshotGeneratedAtUtc,
          evaluatedAtUtc: evaluatedAtUtc,
          freshnessState: freshnessState,
          reasonCode: reason,
        );

    projection.validateStructure();
    return projection;
  }

  bool get consumesStep1EReadModelOnly => true;
  bool get privacyRedactionBeforeVisibility => true;
  bool get malformedSummaryFailureIsolated => true;
  bool get staleDataFailsClosed => true;
  bool get futureClockSkewFailsClosed => true;
  bool get rawExceptionTextNeverExposed => true;
  bool get blockedProjectionContainsNoSummaries => true;

  bool get createsLeaderboard => false;
  bool get assignsPermanentRank => false;
  bool get disciplinesAgent => false;
  bool get changesRouting => false;
  bool get changesPay => false;
  bool get changesAccess => false;

  bool get grantsPermission => false;
  bool get createsApproval => false;
  bool get expandsScope => false;
  bool get assignsRole => false;
  bool get grantsOwnerAuthority => false;
  bool get executesBusinessAction => false;
  bool get modifiesSecurityEngine => false;

  bool get firestoreWriteImplementedHere => false;
  bool get providerInvocationImplementedHere => false;
  bool get routingMutationImplementedHere => false;
  bool get agentStateMutationImplementedHere => false;
  bool get budgetMutationImplementedHere => false;
  bool get persistenceImplementedHere => false;

  bool get securityAuthorityAlwaysAboveDashboard => true;
  bool get step1GFinalCloseoutSeparate => true;
}
