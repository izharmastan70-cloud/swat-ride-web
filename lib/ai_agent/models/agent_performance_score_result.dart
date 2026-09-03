import '../constants/agent_performance_scoring_constants.dart';
import 'agent_performance_metric_score_component.dart';

class AgentPerformanceScoreResult {
  AgentPerformanceScoreResult({
    required this.status,
    required this.agentId,
    required this.cohortKey,
    required this.windowId,
    required this.scoreContractVersion,
    required this.overallScore,
    required this.confidence,
    required this.comparisonEligible,
    required List<String> includedMetricIds,
    required List<AgentPerformanceMetricScoreComponent> components,
    required List<String> reasonCodes,
  }) : includedMetricIds = List<String>.unmodifiable(includedMetricIds),
       components = List<AgentPerformanceMetricScoreComponent>.unmodifiable(
         components,
       ),
       reasonCodes = List<String>.unmodifiable(reasonCodes);

  final String status;
  final String agentId;
  final String cohortKey;
  final String windowId;
  final String scoreContractVersion;
  final double? overallScore;
  final String confidence;
  final bool comparisonEligible;
  final List<String> includedMetricIds;
  final List<AgentPerformanceMetricScoreComponent> components;
  final List<String> reasonCodes;

  bool get hasScore => overallScore != null;

  bool get readOnlyVisibilityOnly => true;
  bool get statisticalSignificanceClaimed => false;
  bool get leaderboardRankAssigned => false;
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
  bool get mutatesProviderState => false;
  bool get mutatesBudget => false;
  bool get persistsResult => false;

  bool get securityAuthorityAlwaysAboveDashboard => true;

  void validateStructure() {
    if (!AgentPerformanceScoreStatus.values.contains(status) ||
        !AgentPerformanceScoreConfidence.values.contains(confidence) ||
        agentId.trim().isEmpty ||
        cohortKey.trim().isEmpty ||
        windowId.trim().isEmpty ||
        scoreContractVersion != AgentPerformanceScoreContract.version ||
        reasonCodes.isEmpty) {
      throw const FormatException('Invalid Agent Performance score result.');
    }

    if (overallScore != null &&
        (overallScore!.isNaN ||
            overallScore!.isInfinite ||
            overallScore! < 0 ||
            overallScore! > 100)) {
      throw const FormatException('Invalid Agent Performance overall score.');
    }

    if (comparisonEligible &&
        (overallScore == null ||
            confidence != AgentPerformanceScoreConfidence.high)) {
      throw const FormatException(
        'Only HIGH-confidence score can be comparison eligible.',
      );
    }

    for (final AgentPerformanceMetricScoreComponent component in components) {
      component.validateStructure();
    }
  }
}
