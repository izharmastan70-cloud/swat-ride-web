import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_post_rebind_enable_boundary.dart';
import 'package:swat_ride/ai_agent/services/agent_security_incident_post_rebind_enable_policy.dart';

void main() {
  const policy = AgentSecurityIncidentPostRebindEnablePolicy();

  AgentSecurityIncidentPostRebindEnableEvidence evidence({
    int roleCount = 23,
    bool roleEnabled = false,
    bool exactPayload = true,
    bool snapshot = true,
    bool manifest = true,
    bool receipt = true,
    bool hold = true,
    bool guard = true,
    bool freshToken = true,
    bool oldTokenReused = false,
    bool freshOwner = true,
    bool ownerApproval = true,
    bool separateApproval = true,
    bool exactApproval = true,
    bool attached = false,
    bool armed = false,
    bool incidentWritten = false,
  }) {
    return AgentSecurityIncidentPostRebindEnableEvidence(
      postMigrationRoleCount: roleCount,
      roleId: 'security_incident_agent',
      module: 'security_incident',
      roleEnabled: roleEnabled,
      exactDisabledRolePayloadVerified: exactPayload,
      postMigrationSnapshotVerified: snapshot,
      authorityManifestRebound: manifest,
      migrationReceiptVerified: receipt,
      migrationHoldPresent: hold,
      productionGuardReboundToPostMigrationInventory: guard,
      freshArmingTokenIssuedAfterRebind: freshToken,
      oldArmingTokenReused: oldTokenReused,
      freshOwnerIdentityVerified: freshOwner,
      freshOwnerApprovalPresent: ownerApproval,
      ownerApprovalSeparateFromMigrationApproval: separateApproval,
      ownerApprovalExactBindingVerified: exactApproval,
      repositoryRuntimeAttached: attached,
      repositoryExecutionArmed: armed,
      incidentWritePerformed: incidentWritten,
    );
  }

  group('Phase66 Step1I-T-T post-rebind enable boundary', () {
    test('clean evidence is eligible for separate implementation only', () {
      final result = policy.evaluate(evidence());

      expect(result.eligibleForSeparateEnableImplementation, isTrue);
      expect(
        result.status,
        AgentSecurityIncidentPostRebindEnableBoundaryStatus.eligible,
      );
      expect(result.roleEnablePerformed, isFalse);
      expect(result.migrationHoldReleased, isFalse);
      expect(result.writesFirestore, isFalse);
      expect(result.consumesApproval, isFalse);
    });

    test('exact post-migration role inventory must be 23', () {
      final result = policy.evaluate(evidence(roleCount: 22));

      expect(
        result.status,
        AgentSecurityIncidentPostRebindEnableBoundaryStatus
            .blockedRoleInventory,
      );
    });

    test('role must still be disabled with exact T-S payload', () {
      final enabled = policy.evaluate(evidence(roleEnabled: true));
      final wrongPayload = policy.evaluate(evidence(exactPayload: false));

      expect(
        enabled.status,
        AgentSecurityIncidentPostRebindEnableBoundaryStatus
            .blockedRoleAuthority,
      );
      expect(
        wrongPayload.status,
        AgentSecurityIncidentPostRebindEnableBoundaryStatus
            .blockedRoleAuthority,
      );
    });

    test('post-migration snapshot manifest and receipt are mandatory', () {
      expect(
        policy.evaluate(evidence(snapshot: false)).status,
        AgentSecurityIncidentPostRebindEnableBoundaryStatus
            .blockedRebindEvidence,
      );
      expect(
        policy.evaluate(evidence(manifest: false)).status,
        AgentSecurityIncidentPostRebindEnableBoundaryStatus
            .blockedRebindEvidence,
      );
      expect(
        policy.evaluate(evidence(receipt: false)).status,
        AgentSecurityIncidentPostRebindEnableBoundaryStatus
            .blockedRebindEvidence,
      );
    });

    test('migration hold remains until future atomic enable transaction', () {
      final result = policy.evaluate(evidence(hold: false));

      expect(
        result.status,
        AgentSecurityIncidentPostRebindEnableBoundaryStatus
            .blockedMigrationHold,
      );
    });

    test('fresh guard and fresh post-rebind token are mandatory', () {
      expect(
        policy.evaluate(evidence(guard: false)).status,
        AgentSecurityIncidentPostRebindEnableBoundaryStatus
            .blockedSecurityRebind,
      );
      expect(
        policy.evaluate(evidence(freshToken: false)).status,
        AgentSecurityIncidentPostRebindEnableBoundaryStatus
            .blockedSecurityRebind,
      );
      expect(
        policy.evaluate(evidence(oldTokenReused: true)).status,
        AgentSecurityIncidentPostRebindEnableBoundaryStatus
            .blockedSecurityRebind,
      );
      expect(policy.permitsOldArmingTokenReuse, isFalse);
    });

    test('fresh Owner identity and separate exact approval are mandatory', () {
      expect(
        policy.evaluate(evidence(freshOwner: false)).status,
        AgentSecurityIncidentPostRebindEnableBoundaryStatus
            .blockedOwnerIdentity,
      );
      expect(
        policy.evaluate(evidence(ownerApproval: false)).status,
        AgentSecurityIncidentPostRebindEnableBoundaryStatus
            .blockedOwnerApproval,
      );
      expect(
        policy.evaluate(evidence(separateApproval: false)).status,
        AgentSecurityIncidentPostRebindEnableBoundaryStatus
            .blockedOwnerApproval,
      );
      expect(
        policy.evaluate(evidence(exactApproval: false)).status,
        AgentSecurityIncidentPostRebindEnableBoundaryStatus
            .blockedOwnerApproval,
      );
    });

    test('runtime attach arm or incident write before enable is blocked', () {
      expect(
        policy.evaluate(evidence(attached: true)).status,
        AgentSecurityIncidentPostRebindEnableBoundaryStatus.blockedRuntimeState,
      );
      expect(
        policy.evaluate(evidence(armed: true)).status,
        AgentSecurityIncidentPostRebindEnableBoundaryStatus.blockedRuntimeState,
      );
      expect(
        policy.evaluate(evidence(incidentWritten: true)).status,
        AgentSecurityIncidentPostRebindEnableBoundaryStatus.blockedRuntimeState,
      );
    });

    test('offline policy has zero live authority', () {
      expect(policy.offlineDesignOnly, isTrue);
      expect(policy.requiresFreshOwnerDecisionAtExecution, isTrue);
      expect(policy.requiresSeparateOwnerApproval, isTrue);
      expect(policy.requiresAtomicRoleEnableAndHoldReleaseAtExecution, isTrue);
      expect(policy.roleEnablePerformed, isFalse);
      expect(policy.migrationHoldReleased, isFalse);
      expect(policy.writesFirestore, isFalse);
      expect(policy.readsLiveFirestore, isFalse);
      expect(policy.consumesApproval, isFalse);
      expect(policy.createsApproval, isFalse);
      expect(policy.invokesPermissionEngine, isFalse);
      expect(policy.invokesRuntimeGate, isFalse);
      expect(policy.grantsPermission, isFalse);
      expect(policy.repositoryAttached, isFalse);
      expect(policy.repositoryArmed, isFalse);
      expect(policy.incidentWritten, isFalse);
      expect(policy.authorizesSuggestOnly, isFalse);
      expect(policy.authorizesAuto, isFalse);
    });
  });
}
