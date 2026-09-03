import '../models/agent_monetization_assessment.dart';
import '../models/agent_monetization_opportunity.dart';
import 'agent_monetization_policy.dart';

class AgentMonetizationIntelligenceService {
  final AgentMonetizationPolicy policy;

  const AgentMonetizationIntelligenceService({
    this.policy = const AgentMonetizationPolicy(),
  });

  AgentMonetizationOpportunity assessOpportunity({
    required String type,
    required String module,
    required String title,
    required String reason,
    required String recommendation,
    required double revenuePotentialScore,
    required double userBenefitScore,
    required double confidenceScore,
    required double implementationRiskScore,
  }) {
    final bool sensitiveFinancialArea =
        type == AgentMonetizationOpportunityType.commissionOptimization ||
        type == AgentMonetizationOpportunityType.promotion ||
        type == AgentMonetizationOpportunityType.referralCampaign;

    final opportunity = AgentMonetizationOpportunity(
      type: type,
      module: module,
      title: title,
      reason: reason,
      recommendation: recommendation,
      revenuePotentialScore: revenuePotentialScore,
      userBenefitScore: userBenefitScore,
      confidenceScore: confidenceScore,
      implementationRiskScore: implementationRiskScore,
      requiresAdminReview: true,
      requiresSuperAdminReview: sensitiveFinancialArea,
      createdAt: DateTime.now(),
    );

    opportunity.validate();

    return opportunity;
  }

  List<AgentMonetizationOpportunity> rankOpportunities(
    Iterable<AgentMonetizationOpportunity> opportunities,
  ) {
    final result = opportunities
        .where((item) => item.isSuitableForRecommendation)
        .toList();

    result.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));

    return List<AgentMonetizationOpportunity>.unmodifiable(result);
  }

  AgentMonetizationAssessment buildProposalAssessment({
    required AgentMonetizationOpportunity opportunity,
  }) {
    opportunity.validate();

    return policy.buildAssessment(
      module: opportunity.module,
      subject: opportunity.title,
      summary: opportunity.reason,
      recommendation: opportunity.recommendation,

      // Recommendation becomes a proposal only.
      // It does NOT directly execute a financial mutation.
      action: AgentMonetizationAction.proposeChange,
    );
  }
}
