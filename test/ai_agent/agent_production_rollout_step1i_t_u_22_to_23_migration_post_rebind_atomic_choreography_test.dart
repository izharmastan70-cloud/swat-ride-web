import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/models/agent_security_incident_role_migration_rebind_execution_boundary.dart';
import 'package:swat_ride/ai_agent/services/agent_security_incident_role_migration_rebind_execution_policy.dart';

void main() {
  const policy = AgentSecurityIncidentRoleMigrationRebindExecutionPolicy();

  AgentSecurityIncidentRoleMigrationRebindEvidence evidence({
    int currentRoleCount = 22,
    int targetRoleCount = 23,
    bool roleEnabledAtMigrationCommit = false,
    bool exactTSPayloadVerified = true,
    bool dedicatedMigrationRepositoryReady = true,
    bool migrationRulesManifestCouplingVerified = true,
    bool trustedBackendExecutionEnvironmentReady = true,
    bool freshOwnerIdentityVerified = true,
    bool freshOwnerMigrationApprovalPresent = true,
    bool ownerMigrationApprovalExactBindingVerified = true,
    bool roleCreateSameTransactionRequired = true,
    bool authorityManifestUpdateSameTransactionRequired = true,
    bool migrationHoldSameTransactionRequired = true,
    bool migrationAuditSameTransactionRequired = true,
    bool postMigrationSnapshotRequired = true,
    bool postMigrationAuthorityManifestRebindRequired = true,
    bool postMigrationGuardRebindRequired = true,
    bool postMigrationFreshArmingTokenRequired = true,
    bool postMigrationMigrationReceiptRequired = true,
    bool separatePostRebindEnableApprovalRequired = true,
    bool roleEnableIncludedInMigrationTransaction = false,
    bool oldArmingTokenReuseAllowed = false,
    bool repositoryRuntimeAttached = false,
    bool repositoryExecutionArmed = false,
    bool incidentWritePerformed = false,
  }) {
    return AgentSecurityIncidentRoleMigrationRebindEvidence(
      currentRoleCount: currentRoleCount,
      targetRoleCount: targetRoleCount,
      roleId: 'security_incident_agent',
      module: 'security_incident',
      roleEnabledAtMigrationCommit: roleEnabledAtMigrationCommit,
      exactTSPayloadVerified: exactTSPayloadVerified,
      dedicatedMigrationRepositoryReady: dedicatedMigrationRepositoryReady,
      migrationRulesManifestCouplingVerified:
          migrationRulesManifestCouplingVerified,
      trustedBackendExecutionEnvironmentReady:
          trustedBackendExecutionEnvironmentReady,
      freshOwnerIdentityVerified: freshOwnerIdentityVerified,
      freshOwnerMigrationApprovalPresent: freshOwnerMigrationApprovalPresent,
      ownerMigrationApprovalExactBindingVerified:
          ownerMigrationApprovalExactBindingVerified,
      roleCreateSameTransactionRequired: roleCreateSameTransactionRequired,
      authorityManifestUpdateSameTransactionRequired:
          authorityManifestUpdateSameTransactionRequired,
      migrationHoldSameTransactionRequired:
          migrationHoldSameTransactionRequired,
      migrationAuditSameTransactionRequired:
          migrationAuditSameTransactionRequired,
      postMigrationSnapshotRequired: postMigrationSnapshotRequired,
      postMigrationAuthorityManifestRebindRequired:
          postMigrationAuthorityManifestRebindRequired,
      postMigrationGuardRebindRequired: postMigrationGuardRebindRequired,
      postMigrationFreshArmingTokenRequired:
          postMigrationFreshArmingTokenRequired,
      postMigrationMigrationReceiptRequired:
          postMigrationMigrationReceiptRequired,
      separatePostRebindEnableApprovalRequired:
          separatePostRebindEnableApprovalRequired,
      roleEnableIncludedInMigrationTransaction:
          roleEnableIncludedInMigrationTransaction,
      oldArmingTokenReuseAllowed: oldArmingTokenReuseAllowed,
      repositoryRuntimeAttached: repositoryRuntimeAttached,
      repositoryExecutionArmed: repositoryExecutionArmed,
      incidentWritePerformed: incidentWritePerformed,
    );
  }

  group('Phase66 Step1I-T-U migration/rebind choreography', () {
    test(
      'clean evidence is eligible for separate migration implementation only',
      () {
        final result = policy.evaluate(evidence());

        expect(
          result.eligibleForSeparateMigrationExecutionImplementation,
          isTrue,
        );
        expect(
          result.status,
          AgentSecurityIncidentRoleMigrationRebindStatus.eligible,
        );
        expect(result.liveMigrationPerformed, isFalse);
        expect(result.roleCreated, isFalse);
        expect(result.roleEnabled, isFalse);
        expect(result.writesFirestore, isFalse);
      },
    );

    test('role inventory must be exact 22 to 23', () {
      expect(
        policy.evaluate(evidence(currentRoleCount: 21)).status,
        AgentSecurityIncidentRoleMigrationRebindStatus.blockedCurrentInventory,
      );

      expect(
        policy.evaluate(evidence(targetRoleCount: 24)).status,
        AgentSecurityIncidentRoleMigrationRebindStatus.blockedCurrentInventory,
      );
    });

    test('role must commit disabled with exact T-S payload', () {
      expect(
        policy.evaluate(evidence(roleEnabledAtMigrationCommit: true)).status,
        AgentSecurityIncidentRoleMigrationRebindStatus.blockedRolePayload,
      );

      expect(
        policy.evaluate(evidence(exactTSPayloadVerified: false)).status,
        AgentSecurityIncidentRoleMigrationRebindStatus.blockedRolePayload,
      );
    });

    test('trusted migration authority is mandatory', () {
      expect(
        policy
            .evaluate(evidence(dedicatedMigrationRepositoryReady: false))
            .status,
        AgentSecurityIncidentRoleMigrationRebindStatus
            .blockedMigrationAuthority,
      );

      expect(
        policy
            .evaluate(evidence(migrationRulesManifestCouplingVerified: false))
            .status,
        AgentSecurityIncidentRoleMigrationRebindStatus
            .blockedMigrationAuthority,
      );

      expect(
        policy
            .evaluate(evidence(trustedBackendExecutionEnvironmentReady: false))
            .status,
        AgentSecurityIncidentRoleMigrationRebindStatus
            .blockedMigrationAuthority,
      );
    });

    test('fresh exact Owner migration approval is mandatory', () {
      expect(
        policy.evaluate(evidence(freshOwnerIdentityVerified: false)).status,
        AgentSecurityIncidentRoleMigrationRebindStatus
            .blockedOwnerMigrationApproval,
      );

      expect(
        policy
            .evaluate(evidence(freshOwnerMigrationApprovalPresent: false))
            .status,
        AgentSecurityIncidentRoleMigrationRebindStatus
            .blockedOwnerMigrationApproval,
      );

      expect(
        policy
            .evaluate(
              evidence(ownerMigrationApprovalExactBindingVerified: false),
            )
            .status,
        AgentSecurityIncidentRoleMigrationRebindStatus
            .blockedOwnerMigrationApproval,
      );
    });

    test('role manifest hold and audit must share migration transaction', () {
      expect(
        policy
            .evaluate(evidence(roleCreateSameTransactionRequired: false))
            .status,
        AgentSecurityIncidentRoleMigrationRebindStatus.blockedAtomicMigration,
      );

      expect(
        policy
            .evaluate(
              evidence(authorityManifestUpdateSameTransactionRequired: false),
            )
            .status,
        AgentSecurityIncidentRoleMigrationRebindStatus.blockedAtomicMigration,
      );

      expect(
        policy
            .evaluate(evidence(migrationHoldSameTransactionRequired: false))
            .status,
        AgentSecurityIncidentRoleMigrationRebindStatus.blockedAtomicMigration,
      );

      expect(
        policy
            .evaluate(evidence(migrationAuditSameTransactionRequired: false))
            .status,
        AgentSecurityIncidentRoleMigrationRebindStatus.blockedAtomicMigration,
      );
    });

    test('complete post-migration rebind chain is mandatory', () {
      expect(
        policy.evaluate(evidence(postMigrationSnapshotRequired: false)).status,
        AgentSecurityIncidentRoleMigrationRebindStatus.blockedPostMigrationPlan,
      );

      expect(
        policy
            .evaluate(
              evidence(postMigrationAuthorityManifestRebindRequired: false),
            )
            .status,
        AgentSecurityIncidentRoleMigrationRebindStatus.blockedPostMigrationPlan,
      );

      expect(
        policy
            .evaluate(evidence(postMigrationGuardRebindRequired: false))
            .status,
        AgentSecurityIncidentRoleMigrationRebindStatus.blockedPostMigrationPlan,
      );

      expect(
        policy
            .evaluate(evidence(postMigrationFreshArmingTokenRequired: false))
            .status,
        AgentSecurityIncidentRoleMigrationRebindStatus.blockedPostMigrationPlan,
      );

      expect(
        policy
            .evaluate(evidence(postMigrationMigrationReceiptRequired: false))
            .status,
        AgentSecurityIncidentRoleMigrationRebindStatus.blockedPostMigrationPlan,
      );
    });

    test('migration cannot smuggle role enable or old token reuse', () {
      expect(
        policy
            .evaluate(evidence(separatePostRebindEnableApprovalRequired: false))
            .status,
        AgentSecurityIncidentRoleMigrationRebindStatus.blockedEnableSeparation,
      );

      expect(
        policy
            .evaluate(evidence(roleEnableIncludedInMigrationTransaction: true))
            .status,
        AgentSecurityIncidentRoleMigrationRebindStatus.blockedEnableSeparation,
      );

      expect(
        policy.evaluate(evidence(oldArmingTokenReuseAllowed: true)).status,
        AgentSecurityIncidentRoleMigrationRebindStatus.blockedEnableSeparation,
      );

      expect(policy.permitsRoleEnableInsideMigrationTransaction, isFalse);
      expect(policy.permitsOldArmingTokenReuse, isFalse);
    });

    test('incident runtime remains inactive through migration boundary', () {
      expect(
        policy.evaluate(evidence(repositoryRuntimeAttached: true)).status,
        AgentSecurityIncidentRoleMigrationRebindStatus.blockedEnableSeparation,
      );

      expect(
        policy.evaluate(evidence(repositoryExecutionArmed: true)).status,
        AgentSecurityIncidentRoleMigrationRebindStatus.blockedEnableSeparation,
      );

      expect(
        policy.evaluate(evidence(incidentWritePerformed: true)).status,
        AgentSecurityIncidentRoleMigrationRebindStatus.blockedEnableSeparation,
      );
    });

    test('policy has zero live production authority', () {
      expect(policy.performsLiveMigration, isFalse);
      expect(policy.writesFirestore, isFalse);
      expect(policy.readsLiveFirestore, isFalse);
      expect(policy.invokesApprovalEngine, isFalse);
      expect(policy.consumesApproval, isFalse);
      expect(policy.invokesPermissionEngine, isFalse);
      expect(policy.invokesRuntimeGate, isFalse);
      expect(policy.repositoryAttached, isFalse);
      expect(policy.repositoryArmed, isFalse);
      expect(policy.incidentWritten, isFalse);
      expect(policy.authorizesSuggestOnly, isFalse);
      expect(policy.authorizesAuto, isFalse);
    });
  });
}
