import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_post_migration_rebind_execution_contract.dart';
import 'package:swat_ride/ai_agent/services/agent_security_incident_post_migration_rebind_executor_design.dart';

void main() {
  const AgentSecurityIncidentPostMigrationRebindExecutorDesign design =
      AgentSecurityIncidentPostMigrationRebindExecutorDesign();

  AgentSecurityIncidentPostMigrationRebindEvidence evidence({
    String snapshotSha = AgentSecurityIncidentPostMigrationRebindExecutorDesign
        .lockedPostMigrationSnapshotSha256,
    String roleSha = AgentSecurityIncidentPostMigrationRebindExecutorDesign
        .lockedRoleInventoryFingerprintSha256,
    int roleCount = 23,
    bool targetRoleExists = true,
    bool targetRoleEnabled = false,
    String targetRoleMode = 'ASK_FIRST',
    int manifestRevision = 2,
    int manifestRoleCount = 23,
    String manifestSha = AgentSecurityIncidentPostMigrationRebindExecutorDesign
        .lockedRoleInventoryFingerprintSha256,
    bool rebindRequired = true,
    String holdStatus = 'ROLE_DELTA_COMMITTED',
    bool holdActive = true,
    int guardRevision = 2,
    int guardRoleCount = 22,
    String rolloutStage = 'MONITOR_ONLY',
    int autoTraffic = 0,
    int businessTraffic = 0,
    bool externalChannels = false,
    bool oldTokenConsumed = true,
    bool oldReceiptApplied = true,
    bool oldTokenReuse = false,
    bool freshOwner = true,
    bool rebindApproval = true,
    bool separateApproval = true,
    bool exactApprovalBinding = true,
    bool securityBypass = false,
    bool duplicateAuthority = false,
    bool attached = false,
    bool armed = false,
    bool incidentWritten = false,
  }) {
    return AgentSecurityIncidentPostMigrationRebindEvidence(
      postMigrationSnapshotSha256: snapshotSha,
      roleInventoryFingerprintSha256: roleSha,
      roleCount: roleCount,
      targetRoleExists: targetRoleExists,
      targetRoleEnabled: targetRoleEnabled,
      targetRoleMode: targetRoleMode,
      authorityManifestRevision: manifestRevision,
      authorityManifestRoleCount: manifestRoleCount,
      authorityManifestFingerprintSha256: manifestSha,
      postMigrationRebindRequired: rebindRequired,
      migrationHoldStatus: holdStatus,
      migrationHoldActive: holdActive,
      currentGuardRevision: guardRevision,
      currentGuardRoleCount: guardRoleCount,
      currentRolloutStage: rolloutStage,
      currentAutoTrafficPercent: autoTraffic,
      currentBusinessWriteTrafficPercent: businessTraffic,
      externalChannelsEnabled: externalChannels,
      oldArmingTokenConsumed: oldTokenConsumed,
      oldActivationReceiptApplied: oldReceiptApplied,
      oldArmingTokenReuseRequested: oldTokenReuse,
      freshOwnerIdentityVerified: freshOwner,
      freshRebindOwnerApprovalPresent: rebindApproval,
      rebindApprovalSeparateFromMigrationApproval: separateApproval,
      rebindApprovalExactSnapshotBindingVerified: exactApprovalBinding,
      securityBypassDetected: securityBypass,
      duplicateAlternateAuthorityDetected: duplicateAuthority,
      repositoryRuntimeAttached: attached,
      repositoryExecutionArmed: armed,
      incidentWritePerformed: incidentWritten,
    );
  }

  group('Phase66 Step1I-T-AM-T post-migration rebind executor design', () {
    test('exact fail-closed evidence produces offline trusted-rebind plan', () {
      final decision = design.evaluate(evidence());

      expect(decision.eligibleForDedicatedTrustedImplementation, isTrue);
      expect(
        decision.status,
        AgentSecurityIncidentPostMigrationRebindStatus.eligible,
      );

      final plan = decision.plan!;

      expect(plan.targetGuardRevision, 3);
      expect(plan.targetRoleCount, 23);
      expect(plan.targetRolloutStage, 'MONITOR_ONLY');

      expect(plan.updateAuthorityManifest, isTrue);
      expect(plan.persistFreshGuard, isTrue);
      expect(plan.issueFreshOneTimeArmingToken, isTrue);
      expect(plan.createFreshRebindReceipt, isTrue);
      expect(plan.appendAuditInSameTrustedBoundary, isTrue);
      expect(plan.plannedAuthorityWriteSurfaces, 6);

      expect(plan.keepMigrationHoldActive, isTrue);
      expect(plan.enableSecurityIncidentRole, isFalse);
      expect(plan.releaseMigrationHold, isFalse);

      expect(plan.reuseOldArmingToken, isFalse);
      expect(plan.persistRawArmingToken, isFalse);

      expect(plan.attachRepositoryRuntime, isFalse);
      expect(plan.armRepositoryExecution, isFalse);
      expect(plan.writeIncident, isFalse);
      expect(plan.authorizeSuggestOnly, isFalse);
      expect(plan.authorizeAuto, isFalse);

      expect(decision.performsLiveRebind, isFalse);
      expect(decision.writesFirestore, isFalse);
      expect(decision.issuesArmingToken, isFalse);
      expect(decision.createsRebindReceipt, isFalse);
    });

    test('wrong post-migration snapshot fails closed', () {
      final decision = design.evaluate(
        evidence(
          snapshotSha:
              'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        ),
      );

      expect(decision.eligibleForDedicatedTrustedImplementation, isFalse);
      expect(
        decision.status,
        AgentSecurityIncidentPostMigrationRebindStatus.blockedSnapshot,
      );
    });

    test('role must remain disabled ASK_FIRST before rebind', () {
      expect(
        design.evaluate(evidence(targetRoleEnabled: true)).status,
        AgentSecurityIncidentPostMigrationRebindStatus.blockedRoleAuthority,
      );

      expect(
        design.evaluate(evidence(targetRoleMode: 'AUTO')).status,
        AgentSecurityIncidentPostMigrationRebindStatus.blockedRoleAuthority,
      );
    });

    test(
      'manifest revision2 exact 23-role rebind-required state is mandatory',
      () {
        expect(
          design.evaluate(evidence(manifestRevision: 3)).status,
          AgentSecurityIncidentPostMigrationRebindStatus.blockedManifest,
        );

        expect(
          design.evaluate(evidence(rebindRequired: false)).status,
          AgentSecurityIncidentPostMigrationRebindStatus.blockedManifest,
        );
      },
    );

    test('migration hold must remain ROLE_DELTA_COMMITTED and active', () {
      expect(
        design.evaluate(evidence(holdStatus: 'HELD')).status,
        AgentSecurityIncidentPostMigrationRebindStatus.blockedMigrationHold,
      );

      expect(
        design.evaluate(evidence(holdActive: false)).status,
        AgentSecurityIncidentPostMigrationRebindStatus.blockedMigrationHold,
      );
    });

    test(
      'old token/receipt are historical evidence and token cannot be reused',
      () {
        expect(
          design.evaluate(evidence(oldTokenConsumed: false)).status,
          AgentSecurityIncidentPostMigrationRebindStatus
              .blockedHistoricalEvidence,
        );

        expect(
          design.evaluate(evidence(oldReceiptApplied: false)).status,
          AgentSecurityIncidentPostMigrationRebindStatus
              .blockedHistoricalEvidence,
        );

        expect(
          design.evaluate(evidence(oldTokenReuse: true)).status,
          AgentSecurityIncidentPostMigrationRebindStatus
              .blockedHistoricalEvidence,
        );
      },
    );

    test('guard must be historical revision2 roleCount22 MONITOR_ONLY', () {
      expect(
        design.evaluate(evidence(guardRevision: 3)).status,
        AgentSecurityIncidentPostMigrationRebindStatus.blockedCurrentGuard,
      );

      expect(
        design.evaluate(evidence(guardRoleCount: 23)).status,
        AgentSecurityIncidentPostMigrationRebindStatus.blockedCurrentGuard,
      );

      expect(
        design.evaluate(evidence(autoTraffic: 1)).status,
        AgentSecurityIncidentPostMigrationRebindStatus.blockedCurrentGuard,
      );
    });

    test('fresh separate Owner-bound rebind approval is mandatory', () {
      expect(
        design.evaluate(evidence(freshOwner: false)).status,
        AgentSecurityIncidentPostMigrationRebindStatus.blockedOwner,
      );

      expect(
        design.evaluate(evidence(rebindApproval: false)).status,
        AgentSecurityIncidentPostMigrationRebindStatus.blockedOwner,
      );

      expect(
        design.evaluate(evidence(separateApproval: false)).status,
        AgentSecurityIncidentPostMigrationRebindStatus.blockedOwner,
      );

      expect(
        design.evaluate(evidence(exactApprovalBinding: false)).status,
        AgentSecurityIncidentPostMigrationRebindStatus.blockedOwner,
      );
    });

    test(
      'security bypass, duplicate authority, attach, arm, incident all block',
      () {
        expect(
          design.evaluate(evidence(securityBypass: true)).status,
          AgentSecurityIncidentPostMigrationRebindStatus.blockedSafety,
        );

        expect(
          design.evaluate(evidence(duplicateAuthority: true)).status,
          AgentSecurityIncidentPostMigrationRebindStatus.blockedSafety,
        );

        expect(
          design.evaluate(evidence(attached: true)).status,
          AgentSecurityIncidentPostMigrationRebindStatus.blockedSafety,
        );

        expect(
          design.evaluate(evidence(armed: true)).status,
          AgentSecurityIncidentPostMigrationRebindStatus.blockedSafety,
        );

        expect(
          design.evaluate(evidence(incidentWritten: true)).status,
          AgentSecurityIncidentPostMigrationRebindStatus.blockedSafety,
        );
      },
    );

    test('design itself exposes no live authority', () {
      expect(design.offlineDesignOnly, isTrue);
      expect(design.trustedBackendImplementationStillRequired, isTrue);

      expect(design.requiresFreshPostMigrationSnapshot, isTrue);
      expect(design.requiresExact23RoleInventory, isTrue);
      expect(design.requiresFreshSeparateOwnerRebindApproval, isTrue);
      expect(design.requiresGuardRevision2To3, isTrue);
      expect(design.requiresFreshOneTimeArmingToken, isTrue);
      expect(design.requiresNewRebindReceipt, isTrue);
      expect(design.requiresAuthorityManifestRebind, isTrue);
      expect(design.migrationHoldMustRemainActive, isTrue);

      expect(design.permitsOldArmingTokenReuse, isFalse);
      expect(design.permitsRoleEnableInsideRebind, isFalse);
      expect(design.permitsMigrationHoldReleaseInsideRebind, isFalse);
      expect(design.persistsRawArmingToken, isFalse);
      expect(design.securityBypassAllowed, isFalse);
      expect(design.duplicateAlternateAuthorityAllowed, isFalse);

      expect(design.performsLiveFirestoreWrite, isFalse);
      expect(design.invokesPermissionEngine, isFalse);
      expect(design.invokesRuntimeGate, isFalse);
      expect(design.attachesRepositoryRuntime, isFalse);
      expect(design.armsRepositoryExecution, isFalse);
      expect(design.writesIncident, isFalse);
      expect(design.authorizesSuggestOnly, isFalse);
      expect(design.authorizesAuto, isFalse);
    });
  });
}
