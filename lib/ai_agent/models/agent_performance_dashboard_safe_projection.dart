import '../constants/agent_performance_dashboard_constants.dart';
import '../constants/agent_performance_dashboard_privacy_constants.dart';
import 'agent_performance_dashboard_agent_summary.dart';

class AgentPerformanceDashboardSafeProjection {
  AgentPerformanceDashboardSafeProjection({
    required this.status,
    required this.sourceStatus,
    required this.queryId,
    required List<AgentPerformanceDashboardAgentSummary> summaries,
    required this.sourceTotalMatchedBeforeLimit,
    required this.sourceTruncated,
    required this.redactedSummaryCount,
    required this.isolatedFailureCount,
    required this.snapshotGeneratedAtUtc,
    required this.evaluatedAtUtc,
    required this.freshnessState,
    required this.reasonCode,
  }) : summaries = List<AgentPerformanceDashboardAgentSummary>.unmodifiable(
         summaries,
       );

  final String status;
  final String sourceStatus;
  final String queryId;
  final List<AgentPerformanceDashboardAgentSummary> summaries;
  final int sourceTotalMatchedBeforeLimit;
  final bool sourceTruncated;
  final int redactedSummaryCount;
  final int isolatedFailureCount;
  final DateTime snapshotGeneratedAtUtc;
  final DateTime evaluatedAtUtc;
  final String freshnessState;
  final String reasonCode;

  bool get ready =>
      status == AgentPerformanceDashboardSafeProjectionStatus.ready;
  bool get degraded =>
      status == AgentPerformanceDashboardSafeProjectionStatus.degraded;
  bool get empty =>
      status == AgentPerformanceDashboardSafeProjectionStatus.empty;
  bool get blocked => status.startsWith('BLOCKED_');
  bool get staleBlocked =>
      status == AgentPerformanceDashboardSafeProjectionStatus.blockedStaleData;
  bool get clockSkewBlocked =>
      status == AgentPerformanceDashboardSafeProjectionStatus.blockedClockSkew;

  bool get readOnlyVisibilityOnly => true;
  bool get safeProjectionOnly => true;
  bool get rawExceptionTextExposed => false;
  bool get rawPromptExposed => false;
  bool get rawConversationExposed => false;
  bool get privatePayloadExposed => false;
  bool get secretExposed => false;
  bool get authTokenExposed => false;
  bool get approvalTokenExposed => false;
  bool get permissionTokenExposed => false;

  bool get exposesRankNumber => false;
  bool get globalLeaderboardCreated => false;
  bool get permanentRankAssigned => false;
  bool get disciplinaryDecisionMade => false;
  bool get routingDecisionMade => false;
  bool get payDecisionMade => false;
  bool get accessDecisionMade => false;

  bool get grantsPermission => false;
  bool get createsApproval => false;
  bool get expandsScope => false;
  bool get assignsRole => false;
  bool get grantsOwnerAuthority => false;
  bool get authorizesBusinessExecution => false;
  bool get executesBusinessAction => false;

  bool get mutatesAgentState => false;
  bool get mutatesRouting => false;
  bool get mutatesBudget => false;
  bool get persistsProjection => false;
  bool get securityAuthorityAlwaysAboveDashboard => true;

  void validateStructure() {
    if (!AgentPerformanceDashboardSafeProjectionStatus.values.contains(
          status,
        ) ||
        !AgentPerformanceDashboardStatus.values.contains(sourceStatus) ||
        queryId.trim().isEmpty ||
        queryId.length >
            AgentPerformanceDashboardPrivacyLimits.opaqueIdMaxLength ||
        sourceTotalMatchedBeforeLimit < 0 ||
        redactedSummaryCount < 0 ||
        isolatedFailureCount < 0 ||
        !snapshotGeneratedAtUtc.isUtc ||
        !evaluatedAtUtc.isUtc ||
        !AgentPerformanceDashboardFreshnessState.values.contains(
          freshnessState,
        ) ||
        reasonCode.trim().isEmpty) {
      throw const FormatException('Invalid safe dashboard projection.');
    }

    for (final AgentPerformanceDashboardAgentSummary summary in summaries) {
      summary.validateStructure();
    }

    if ((ready || degraded) && summaries.isEmpty) {
      throw const FormatException(
        'Visible safe dashboard state requires summaries.',
      );
    }

    if ((empty || blocked) && summaries.isNotEmpty) {
      throw const FormatException(
        'Empty/blocked safe dashboard must contain zero summaries.',
      );
    }

    if (ready && (redactedSummaryCount != 0 || isolatedFailureCount != 0)) {
      throw const FormatException(
        'READY safe dashboard cannot contain isolated failures.',
      );
    }

    if (degraded && redactedSummaryCount == 0 && isolatedFailureCount == 0) {
      throw const FormatException(
        'DEGRADED safe dashboard requires isolated/redacted entries.',
      );
    }

    if (staleBlocked &&
        freshnessState != AgentPerformanceDashboardFreshnessState.stale) {
      throw const FormatException('Stale block requires STALE state.');
    }

    if (clockSkewBlocked &&
        freshnessState !=
            AgentPerformanceDashboardFreshnessState.futureClockSkew &&
        freshnessState !=
            AgentPerformanceDashboardFreshnessState.invalidTimestamp) {
      throw const FormatException(
        'Clock-skew block requires unsafe timestamp state.',
      );
    }
  }
}
