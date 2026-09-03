import 'agent_project_context.dart';

class AdminIntelligenceExecutionHandoff {
  const AdminIntelligenceExecutionHandoff({
    required this.handoffId,
    required this.taskId,
    required this.providerId,
    required this.routingLane,
    required this.requiredCapability,
    required this.createdAt,
    required this.expiresAt,
    required this.estimatedCostRs,
    required this.paidReasoning,
    required this.ownerApprovalSatisfied,
    required this.budgetAllowed,
    required this.providerCapacityAllowed,
    required this.routingPlanReady,
    required this.readOnlyPreparation,
    required this.blockedReason,
    this.projectContext,
  });

  final String handoffId;
  final String taskId;
  final String providerId;
  final String routingLane;
  final String requiredCapability;

  final DateTime createdAt;
  final DateTime expiresAt;

  final double estimatedCostRs;
  final bool paidReasoning;

  final bool ownerApprovalSatisfied;
  final bool budgetAllowed;
  final bool providerCapacityAllowed;
  final bool routingPlanReady;

  /// Preparation only. This model never performs provider execution.
  final bool readOnlyPreparation;

  final String? blockedReason;

  /// Optional for legacy handoffs. New capability preparation requires it.
  final AgentProjectContext? projectContext;

  bool get expired => DateTime.now().isAfter(expiresAt);

  bool get allPaidGuardsSatisfied =>
      ownerApprovalSatisfied && budgetAllowed && providerCapacityAllowed;

  bool get executionEligible =>
      readOnlyPreparation &&
      routingPlanReady &&
      (!paidReasoning || allPaidGuardsSatisfied) &&
      blockedReason == null;

  Map<String, dynamic> toAuditMap() {
    return <String, dynamic>{
      'handoffId': handoffId,
      'taskId': taskId,
      'providerId': providerId,
      'routingLane': routingLane,
      'requiredCapability': requiredCapability,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'estimatedCostRs': estimatedCostRs,
      'paidReasoning': paidReasoning,
      'ownerApprovalSatisfied': ownerApprovalSatisfied,
      'budgetAllowed': budgetAllowed,
      'providerCapacityAllowed': providerCapacityAllowed,
      'routingPlanReady': routingPlanReady,
      'readOnlyPreparation': readOnlyPreparation,
      'blockedReason': blockedReason,
      'projectContext': projectContext?.toAuthorizationScope(),
    };
  }
}
