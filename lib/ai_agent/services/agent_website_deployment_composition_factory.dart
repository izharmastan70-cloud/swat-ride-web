import '../models/agent_git_connected_vercel_provider_config.dart';
import 'agent_audit_recorder.dart';
import 'agent_audit_service.dart';
import 'agent_website_deployment_adapter.dart';
import 'agent_website_deployment_execution_coordinator.dart';
import 'agent_website_deployment_history_repository.dart';
import 'agent_website_deployment_lifecycle_service.dart';
import 'agent_website_deployment_provider_selector.dart';

/// Phase 34 Step 3D-E3C4B.
///
/// Dedicated composition root for the controlled website deployment
/// subsystem.
///
/// Responsibilities:
/// - select the explicitly requested deployment provider;
/// - compose deployment-history persistence;
/// - compose append-only deployment audit recording;
/// - compose deployment lifecycle service;
/// - inject the selected adapter into the execution coordinator.
///
/// This factory does NOT:
/// - execute a deployment;
/// - perform Git push;
/// - call Vercel APIs;
/// - access Vercel/GitHub secrets;
/// - execute shell/process commands;
/// - mutate DNS/domain configuration.
///
/// Provider behavior remains governed by the selected adapter.
/// In Phase 34 E3C4B the Git-connected Vercel adapter remains fail-closed.
class AgentWebsiteDeploymentCompositionFactory {
  AgentWebsiteDeploymentCompositionFactory._();

  static AgentWebsiteDeploymentExecutionCoordinator compose({
    required String providerId,
    AgentGitConnectedVercelProviderConfig? gitConnectedVercelConfig,
    AgentWebsiteDeploymentProviderSelector selector =
        const AgentWebsiteDeploymentProviderSelector(),
    AgentWebsiteDeploymentHistoryRepository? historyRepository,
    AgentAuditService? auditService,
  }) {
    final AgentWebsiteDeploymentAdapter adapter = selector.select(
      providerId: providerId,
      gitConnectedVercelConfig: gitConnectedVercelConfig,
    );

    final AgentWebsiteDeploymentHistoryRepository repository =
        historyRepository ?? AgentWebsiteDeploymentHistoryRepository();

    final AgentAuditRecorder auditRecorder = AgentAuditRecorder(
      auditService: auditService ?? AgentAuditService(),
    );

    final AgentWebsiteDeploymentLifecycleService lifecycleService =
        AgentWebsiteDeploymentLifecycleService(
          repository: repository,
          auditRecorder: auditRecorder,
        );

    return AgentWebsiteDeploymentExecutionCoordinator(
      adapter: adapter,
      lifecycleService: lifecycleService,
    );
  }

  /// Safe convenience composition.
  ///
  /// This always selects the existing disabled provider and therefore
  /// cannot initiate real production deployment.
  static AgentWebsiteDeploymentExecutionCoordinator composeDisabled({
    AgentWebsiteDeploymentHistoryRepository? historyRepository,
    AgentAuditService? auditService,
  }) {
    return compose(
      providerId: AgentWebsiteDeploymentProviderId.disabled,
      historyRepository: historyRepository,
      auditService: auditService,
    );
  }
}
