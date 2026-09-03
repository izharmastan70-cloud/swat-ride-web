import '../models/agent_website_deployment_plan.dart';

/// Controlled website deployment adapter boundary.
///
/// Phase 34 Step 3D.
///
/// Implementations may be connected in a later phase only after
/// explicit production authorization and secret-management design.
///
/// This interface itself:
/// - has no Vercel token;
/// - has no GitHub token;
/// - runs no shell command;
/// - performs no DNS/domain mutation.
abstract interface class AgentWebsiteDeploymentAdapter {
  Future<AgentWebsiteDeploymentExecutionResult> deploy(
    AgentWebsiteDeploymentPlan plan,
  );
}

/// Fail-closed adapter used until a real deployment provider is
/// explicitly connected.
class AgentDisabledWebsiteDeploymentAdapter
    implements AgentWebsiteDeploymentAdapter {
  const AgentDisabledWebsiteDeploymentAdapter();

  @override
  Future<AgentWebsiteDeploymentExecutionResult> deploy(
    AgentWebsiteDeploymentPlan plan,
  ) async {
    plan.validate();

    return AgentWebsiteDeploymentExecutionResult.blocked(
      deploymentId: plan.deploymentId,
      reason:
          'Production deployment adapter is not connected. '
          'Approval alone does not authorize or perform deployment.',
    );
  }
}

class AgentWebsiteDeploymentExecutionResult {
  final String deploymentId;

  final bool attempted;
  final bool succeeded;

  final String reason;

  final Uri? deploymentUri;

  final DateTime createdAt;

  const AgentWebsiteDeploymentExecutionResult._({
    required this.deploymentId,
    required this.attempted,
    required this.succeeded,
    required this.reason,
    required this.deploymentUri,
    required this.createdAt,
  });

  factory AgentWebsiteDeploymentExecutionResult.blocked({
    required String deploymentId,
    required String reason,
  }) {
    return AgentWebsiteDeploymentExecutionResult._(
      deploymentId: deploymentId,
      attempted: false,
      succeeded: false,
      reason: reason,
      deploymentUri: null,
      createdAt: DateTime.now(),
    );
  }

  factory AgentWebsiteDeploymentExecutionResult.completed({
    required String deploymentId,
    required Uri deploymentUri,
  }) {
    return AgentWebsiteDeploymentExecutionResult._(
      deploymentId: deploymentId,
      attempted: true,
      succeeded: true,
      reason: 'Deployment completed by connected controlled adapter.',
      deploymentUri: deploymentUri,
      createdAt: DateTime.now(),
    );
  }

  factory AgentWebsiteDeploymentExecutionResult.failed({
    required String deploymentId,
    required String reason,
  }) {
    return AgentWebsiteDeploymentExecutionResult._(
      deploymentId: deploymentId,
      attempted: true,
      succeeded: false,
      reason: reason,
      deploymentUri: null,
      createdAt: DateTime.now(),
    );
  }
}