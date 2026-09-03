import '../models/agent_git_connected_vercel_provider_config.dart';
import '../models/agent_website_deployment_plan.dart';
import 'agent_website_deployment_adapter.dart';

/// Phase 34 Step 3D-E3C2.
///
/// Git-connected Vercel provider boundary.
///
/// IMPORTANT:
/// This adapter validates provider configuration and production plan,
/// but it intentionally performs NO Git push and NO Vercel deployment.
///
/// A later phase may add a separate explicitly-authorized execution
/// mechanism behind this boundary.
///
/// No token, secret, Process.run, Process.start, HTTP deployment API,
/// DNS mutation, or unrestricted filesystem access exists here.
class AgentGitConnectedVercelDeploymentAdapter
    implements AgentWebsiteDeploymentAdapter {
  final AgentGitConnectedVercelProviderConfig config;

  const AgentGitConnectedVercelDeploymentAdapter({required this.config});

  bool get providerRelationshipReady => config.providerRelationshipReady;

  @override
  Future<AgentWebsiteDeploymentExecutionResult> deploy(
    AgentWebsiteDeploymentPlan plan,
  ) async {
    plan.validate();
    config.validate();

    if (plan.target != AgentWebsiteDeploymentTarget.production) {
      return AgentWebsiteDeploymentExecutionResult.blocked(
        deploymentId: plan.deploymentId,
        reason:
            'Git-connected Vercel adapter accepts production deployment plans only.',
      );
    }

    if (!plan.canDeployToProduction) {
      return AgentWebsiteDeploymentExecutionResult.blocked(
        deploymentId: plan.deploymentId,
        reason: 'Production plan is not authorized for deployment.',
      );
    }

    if (!config.gitProviderConnected) {
      return AgentWebsiteDeploymentExecutionResult.blocked(
        deploymentId: plan.deploymentId,
        reason: 'Git provider relationship is not confirmed.',
      );
    }

    if (!config.vercelProjectConnected) {
      return AgentWebsiteDeploymentExecutionResult.blocked(
        deploymentId: plan.deploymentId,
        reason:
            'Vercel project is not confirmed as connected to the Git repository.',
      );
    }

    if (!config.liveExecutionAllowed) {
      return AgentWebsiteDeploymentExecutionResult.blocked(
        deploymentId: plan.deploymentId,
        reason:
            'Git-connected Vercel provider contract is ready, '
            'but live Git push and deployment authority remain disabled.',
      );
    }

    // Phase 34 E3C2 must fail closed.
    //
    // Even if a future configuration model is accidentally changed,
    // this contract-only adapter cannot execute production deployment.
    return AgentWebsiteDeploymentExecutionResult.blocked(
      deploymentId: plan.deploymentId,
      reason:
          'Live Git-connected deployment executor is not implemented in Phase 34 E3C2.',
    );
  }
}
