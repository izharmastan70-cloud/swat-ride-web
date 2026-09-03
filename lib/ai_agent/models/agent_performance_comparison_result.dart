import '../constants/agent_performance_scoring_constants.dart';

class AgentPerformanceComparisonResult {
  const AgentPerformanceComparisonResult({
    required this.status,
    required this.relation,
    required this.firstAgentId,
    required this.secondAgentId,
    required this.absoluteDifferencePoints,
    required this.reasonCode,
  });

  final String status;
  final String relation;
  final String firstAgentId;
  final String secondAgentId;
  final double? absoluteDifferencePoints;
  final String reasonCode;

  bool get comparable => status == AgentPerformanceComparisonStatus.comparable;

  bool get readOnlyVisibilityOnly => true;
  bool get statisticalSignificanceClaimed => false;
  bool get globalLeaderboardCreated => false;
  bool get permanentRankAssigned => false;
  bool get disciplinaryDecisionMade => false;
  bool get routingDecisionMade => false;
  bool get payDecisionMade => false;
  bool get accessDecisionMade => false;

  bool get grantsPermission => false;
  bool get createsApproval => false;
  bool get authorizesBusinessExecution => false;
  bool get executesBusinessAction => false;

  bool get mutatesAgentState => false;
  bool get mutatesRouting => false;
  bool get mutatesBudget => false;
  bool get persistsComparison => false;

  bool get securityAuthorityAlwaysAboveDashboard => true;

  void validateStructure() {
    if (!AgentPerformanceComparisonStatus.values.contains(status) ||
        !AgentPerformanceComparisonRelation.values.contains(relation) ||
        firstAgentId.trim().isEmpty ||
        secondAgentId.trim().isEmpty ||
        reasonCode.trim().isEmpty) {
      throw const FormatException(
        'Invalid Agent Performance comparison result.',
      );
    }

    if (comparable !=
        (relation != AgentPerformanceComparisonRelation.notComparable)) {
      throw const FormatException('Comparison status/relation mismatch.');
    }

    if (absoluteDifferencePoints != null &&
        (absoluteDifferencePoints!.isNaN ||
            absoluteDifferencePoints!.isInfinite ||
            absoluteDifferencePoints! < 0 ||
            absoluteDifferencePoints! > 100)) {
      throw const FormatException(
        'Invalid Agent Performance comparison difference.',
      );
    }
  }
}
