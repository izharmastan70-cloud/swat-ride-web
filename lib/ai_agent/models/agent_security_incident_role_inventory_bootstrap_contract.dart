import 'agent_security_incident_role_inventory_revision_design.dart';

abstract final class AgentSecurityIncidentRoleInventoryBootstrapContract {
  static const String authorityManifestDocument =
      'security_incident_role_inventory_authority_manifest';

  static const String migrationHoldDocument =
      'security_incident_role_inventory_migration_hold';

  static const String currentInventoryVersion = 'phase66_roles_v1_22';

  static const String proposedInventoryVersion =
      'phase66_roles_v2_23_security_incident';

  static const int currentRoleCount = 22;
  static const int proposedRoleCount = 23;

  static const String targetRoleId =
      AgentSecurityIncidentRoleInventoryRevisionDesign.dedicatedRoleId;

  static const String targetModule =
      AgentSecurityIncidentRoleInventoryRevisionDesign.dedicatedModule;

  static const String targetActionId =
      AgentSecurityIncidentRoleInventoryRevisionDesign.attachRuntimeActionId;

  static const String targetStoredMode =
      AgentSecurityIncidentRoleInventoryRevisionDesign.proposedStoredRoleMode;

  static const bool sourceMustBeFreshLiveFirestore = true;
  static const bool staticSeedMayAuthorize = false;
  static const bool trustedBackendOrAdminSdkRequired = true;
  static const bool ordinaryFlutterClientMayBootstrap = false;
  static const bool freshOwnerIdentityRequired = true;
  static const bool ownerApprovalBindingRequired = true;
  static const bool exactCurrentRoleIdsRequired = true;
  static const bool exactCurrentInventoryFingerprintRequired = true;
  static const bool exactProposedInventoryFingerprintRequired = true;
  static const bool currentRolloutMustRemainMonitorOnly = true;
  static const bool dedicatedRoleMustBeAbsentBeforeBootstrap = true;
  static const bool backendSingleMutationAuthorityRequired = true;
  static const bool sameBackendTransactionAuditRequired = true;

  static const bool oldGuardImmutable = true;
  static const bool oldArmingTokenImmutable = true;
  static const bool oldActivationReceiptImmutable = true;
  static const bool existingActivationTokenReuseAllowed = false;

  static const bool postBootstrapRoleDeltaExecuted = false;
  static const bool repositoryAttachAuthorized = false;
  static const bool repositoryArmAuthorized = false;
  static const bool firstIncidentWriteAuthorized = false;
  static const bool authorizesSuggestOnly = false;
  static const bool authorizesAuto = false;

  static const List<String> authorityManifestRequiredFields = <String>[
    'status',
    'inventoryVersion',
    'roleCount',
    'roleProjectionFingerprintSha256',
    'revision',
    'postMigrationRebindRequired',
    'updatedAt',
  ];

  static const List<String> migrationHoldRequiredFields = <String>[
    'status',
    'migrationIdSha256',
    'ownerApprovalId',
    'ownerApprovalBindingSha256',
    'currentInventoryFingerprintSha256',
    'proposedInventoryFingerprintSha256',
    'currentControlFingerprintSha256',
    'expectedRoleIds',
    'expectedRoleCount',
    'proposedRoleCount',
    'expectedGuardRevision',
    'targetRoleId',
    'targetActionId',
    'migrationHoldActive',
    'repositoryAttachAuthorized',
    'repositoryArmAuthorized',
    'firstIncidentWriteAuthorized',
    'authorizesSuggestOnly',
    'authorizesAuto',
    'updatedAt',
  ];

  static bool validExactCurrentRoleIds(List<String> roleIds) {
    if (roleIds.length != currentRoleCount) {
      return false;
    }

    final Set<String> unique = roleIds.map((String id) => id.trim()).toSet();

    return unique.length == currentRoleCount &&
        !unique.contains(targetRoleId) &&
        !unique.contains('');
  }

  static bool looksLikeSha256(String value) {
    final String normalized = value.trim().toLowerCase();

    return normalized.length == 64 &&
        RegExp(r'^[0-9a-f]{64}$').hasMatch(normalized);
  }
}
