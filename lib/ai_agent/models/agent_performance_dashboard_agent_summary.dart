import '../constants/agent_performance_metric_constants.dart';
import '../constants/agent_performance_scoring_constants.dart';

class AgentPerformanceDashboardAgentSummary {
  AgentPerformanceDashboardAgentSummary({
    required this.agentId,
    required this.cohortKey,
    required this.windowId,
    required this.scoreContractVersion,
    required this.scoreStatus,
    required this.overallScore,
    required this.confidence,
    required this.comparisonEligible,
    required List<String> includedScorableMetricIds,
    required Map<String, double> contextMetricValues,
    required Set<String> insufficientContextMetricIds,
  }) : includedScorableMetricIds = List<String>.unmodifiable(
         includedScorableMetricIds,
       ),
       contextMetricValues = Map<String, double>.unmodifiable(
         contextMetricValues,
       ),
       insufficientContextMetricIds = Set<String>.unmodifiable(
         insufficientContextMetricIds,
       );

  final String agentId;
  final String cohortKey;
  final String windowId;
  final String scoreContractVersion;
  final String scoreStatus;
  final double? overallScore;
  final String confidence;
  final bool comparisonEligible;
  final List<String> includedScorableMetricIds;
  final Map<String, double> contextMetricValues;
  final Set<String> insufficientContextMetricIds;

  bool get hasScore => overallScore != null;
  String get summaryIdentity => '$agentId|$cohortKey|$windowId';

  bool get readOnlyVisibilityOnly => true;
  bool get presentationOrderIsNotRank => true;
  bool get globalLeaderboardEntry => false;
  bool get permanentRankAssigned => false;
  bool get disciplinaryDecisionMade => false;
  bool get routingDecisionMade => false;
  bool get payDecisionMade => false;
  bool get accessDecisionMade => false;

  bool get containsRawPrompt => false;
  bool get containsRawConversation => false;
  bool get containsPrivatePayload => false;
  bool get containsSecret => false;
  bool get containsApprovalToken => false;
  bool get containsPermissionToken => false;

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
  bool get persistsSummary => false;
  bool get securityAuthorityAlwaysAboveDashboard => true;

  void validateStructure() {
    if (agentId.trim().isEmpty ||
        cohortKey.trim().isEmpty ||
        windowId.trim().isEmpty ||
        scoreContractVersion != AgentPerformanceScoreContract.version ||
        !AgentPerformanceScoreStatus.values.contains(scoreStatus) ||
        !AgentPerformanceScoreConfidence.values.contains(confidence)) {
      throw const FormatException('Invalid dashboard summary.');
    }

    if (overallScore != null &&
        (overallScore!.isNaN ||
            overallScore!.isInfinite ||
            overallScore! < 0 ||
            overallScore! > 100)) {
      throw const FormatException('Invalid dashboard score.');
    }

    if (comparisonEligible &&
        (overallScore == null ||
            confidence != AgentPerformanceScoreConfidence.high)) {
      throw const FormatException(
        'Comparison eligibility requires HIGH-confidence score.',
      );
    }

    for (final String id in includedScorableMetricIds) {
      if (!AgentPerformanceScoreContract.scorableMetricIds.contains(id)) {
        throw const FormatException('Invalid scorable metric in summary.');
      }
    }

    for (final MapEntry<String, double> entry in contextMetricValues.entries) {
      if (!AgentPerformanceScoreContract.contextOnlyMetricIds.contains(
            entry.key,
          ) ||
          entry.value.isNaN ||
          entry.value.isInfinite ||
          entry.value < 0) {
        throw const FormatException('Invalid dashboard context metric.');
      }
    }

    for (final String id in insufficientContextMetricIds) {
      if (!AgentPerformanceScoreContract.contextOnlyMetricIds.contains(id)) {
        throw const FormatException('Invalid insufficient context metric.');
      }
    }

    if (contextMetricValues.keys
        .toSet()
        .intersection(insufficientContextMetricIds)
        .isNotEmpty) {
      throw const FormatException(
        'Context metric cannot be sufficient and insufficient.',
      );
    }

    if (AgentPerformanceMetricId.values.length != 14) {
      throw const FormatException('Unexpected metric contract.');
    }
  }
}
