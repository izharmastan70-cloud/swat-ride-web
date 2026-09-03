import 'agent_security_incident_role_inventory_bootstrap_contract.dart';

/// This contract intentionally separates two authorities:
///
/// 1. Firestore client rules:
///    - may allow trusted Owner/Super Admin READ visibility;
///    - must deny ordinary client CREATE/UPDATE/DELETE of agent_roles;
///    - must deny client bootstrap/mutation of the authority manifest and hold.
///
/// 2. Trusted backend/Admin SDK:
///    - owns exact live inventory capture;
///    - owns manifest + hold bootstrap;
///    - later owns the atomic role delta and same-transaction audit.
///
/// This avoids treating a Flutter Super Admin client as migration authority.
abstract final class AgentSecurityIncidentRoleInventoryRulesBoundaryContract {
  static const bool superAdminClientMayReadRoles = true;

  static const bool ordinaryClientMayCreateRole = false;
  static const bool ordinaryClientMayUpdateRole = false;
  static const bool ordinaryClientMayDeleteRole = false;

  static const bool superAdminClientMayReadAuthorityManifest = true;
  static const bool superAdminClientMayReadMigrationHold = true;

  static const bool ordinaryClientMayCreateAuthorityManifest = false;
  static const bool ordinaryClientMayUpdateAuthorityManifest = false;
  static const bool ordinaryClientMayDeleteAuthorityManifest = false;

  static const bool ordinaryClientMayCreateMigrationHold = false;
  static const bool ordinaryClientMayUpdateMigrationHold = false;
  static const bool ordinaryClientMayDeleteMigrationHold = false;

  static const bool trustedBackendOwnsRoleMutation = true;
  static const bool trustedBackendOwnsManifestBootstrap = true;
  static const bool trustedBackendOwnsMigrationHoldBootstrap = true;
  static const bool trustedBackendOwnsAtomicAudit = true;

  static const bool currentBroadSuperAdminRoleWriteRuleIsAcceptable = false;
  static const bool clientManifestCouplingIsMigrationAuthority = false;
  static const bool backendManifestAndHoldCouplingRequired = true;

  static const String authorityManifestDocument =
      AgentSecurityIncidentRoleInventoryBootstrapContract
          .authorityManifestDocument;

  static const String migrationHoldDocument =
      AgentSecurityIncidentRoleInventoryBootstrapContract.migrationHoldDocument;

  static const bool rulesDeployAuthorizesRoleMigration = false;
  static const bool bootstrapAuthorizesRoleMigration = false;
  static const bool roleDeltaRequiresSeparateExecutionBoundary = true;
}
