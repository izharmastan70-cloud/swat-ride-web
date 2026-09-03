import '../models/agent_security_incident_role_inventory_bootstrap_contract.dart';
import '../models/agent_security_incident_role_inventory_bootstrap_readiness.dart';

class AgentSecurityIncidentRoleInventoryBootstrapPolicy {
  const AgentSecurityIncidentRoleInventoryBootstrapPolicy();

  AgentSecurityIncidentRoleInventoryBootstrapDecision evaluate(
    AgentSecurityIncidentRoleInventoryBootstrapReadiness evidence,
  ) {
    if (!evidence.trustedBackendImplemented) {
      return const AgentSecurityIncidentRoleInventoryBootstrapDecision(
        status: AgentSecurityIncidentRoleInventoryBootstrapStatus
            .blockedBackendMissing,
        reasonCode: 'trusted_backend_or_admin_sdk_not_implemented',
      );
    }

    if (!evidence.backendSingleMutationAuthority) {
      return const AgentSecurityIncidentRoleInventoryBootstrapDecision(
        status: AgentSecurityIncidentRoleInventoryBootstrapStatus
            .blockedBackendAuthority,
        reasonCode: 'backend_is_not_single_role_inventory_mutation_authority',
      );
    }

    if (!evidence.clientRoleWritesDenied ||
        !evidence.clientManifestWritesDenied ||
        !evidence.clientMigrationHoldWritesDenied) {
      return const AgentSecurityIncidentRoleInventoryBootstrapDecision(
        status: AgentSecurityIncidentRoleInventoryBootstrapStatus
            .blockedRulesBoundary,
        reasonCode: 'client_write_denial_boundary_not_proven',
      );
    }

    if (!evidence.freshTrustedLiveInventoryRead ||
        !AgentSecurityIncidentRoleInventoryBootstrapContract.validExactCurrentRoleIds(
          evidence.exactCurrentRoleIds,
        )) {
      return const AgentSecurityIncidentRoleInventoryBootstrapDecision(
        status: AgentSecurityIncidentRoleInventoryBootstrapStatus
            .blockedLiveInventory,
        reasonCode: 'fresh_exact_live_22_role_inventory_not_proven',
      );
    }

    if (!AgentSecurityIncidentRoleInventoryBootstrapContract.looksLikeSha256(
          evidence.currentInventoryFingerprintSha256,
        ) ||
        !AgentSecurityIncidentRoleInventoryBootstrapContract.looksLikeSha256(
          evidence.proposedInventoryFingerprintSha256,
        ) ||
        !AgentSecurityIncidentRoleInventoryBootstrapContract.looksLikeSha256(
          evidence.currentControlFingerprintSha256,
        )) {
      return const AgentSecurityIncidentRoleInventoryBootstrapDecision(
        status: AgentSecurityIncidentRoleInventoryBootstrapStatus
            .blockedFingerprint,
        reasonCode: 'inventory_or_control_fingerprint_invalid',
      );
    }

    if (!evidence.freshOwnerVerified || !evidence.ownerApprovalBound) {
      return const AgentSecurityIncidentRoleInventoryBootstrapDecision(
        status: AgentSecurityIncidentRoleInventoryBootstrapStatus.blockedOwner,
        reasonCode: 'fresh_owner_and_exact_approval_binding_required',
      );
    }

    if (!evidence.currentRolloutMonitorOnly || !evidence.dedicatedRoleAbsent) {
      return const AgentSecurityIncidentRoleInventoryBootstrapDecision(
        status:
            AgentSecurityIncidentRoleInventoryBootstrapStatus.blockedRollout,
        reasonCode: 'monitor_only_or_role_absence_precondition_failed',
      );
    }

    if (!evidence.oldGuardImmutable ||
        !evidence.oldArmingTokenImmutable ||
        !evidence.oldActivationReceiptImmutable) {
      return const AgentSecurityIncidentRoleInventoryBootstrapDecision(
        status:
            AgentSecurityIncidentRoleInventoryBootstrapStatus.blockedEvidence,
        reasonCode: 'historical_activation_evidence_must_remain_immutable',
      );
    }

    if (!evidence.sameTransactionAuditReady) {
      return const AgentSecurityIncidentRoleInventoryBootstrapDecision(
        status: AgentSecurityIncidentRoleInventoryBootstrapStatus.blockedAudit,
        reasonCode: 'same_transaction_bootstrap_audit_not_ready',
      );
    }

    return const AgentSecurityIncidentRoleInventoryBootstrapDecision(
      status: AgentSecurityIncidentRoleInventoryBootstrapStatus
          .readyForSeparateTrustedBootstrapExecution,
      reasonCode:
          'trusted_bootstrap_contract_ready_for_separate_execution_boundary',
    );
  }

  bool get executesBootstrap => false;
  bool get writesFirestore => false;
  bool get consumesApproval => false;
  bool get createsRole => false;
  bool get changesRolloutStage => false;
  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;
}
