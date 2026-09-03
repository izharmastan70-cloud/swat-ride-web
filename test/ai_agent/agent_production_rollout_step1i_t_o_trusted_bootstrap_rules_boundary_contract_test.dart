import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_role_inventory_bootstrap_contract.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_role_inventory_bootstrap_readiness.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_role_inventory_rules_boundary_contract.dart';
import 'package:swat_ride/ai_agent/services/agent_security_incident_role_inventory_bootstrap_policy.dart';

void main() {
  const String hashA =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  const String hashB =
      'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
  const String hashC =
      'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';

  List<String> exact22RoleIds() {
    return List<String>.generate(
      22,
      (int index) => 'existing_role_${index + 1}',
      growable: false,
    );
  }

  AgentSecurityIncidentRoleInventoryBootstrapReadiness readyEvidence() {
    return AgentSecurityIncidentRoleInventoryBootstrapReadiness(
      trustedBackendImplemented: true,
      backendSingleMutationAuthority: true,
      clientRoleWritesDenied: true,
      clientManifestWritesDenied: true,
      clientMigrationHoldWritesDenied: true,
      freshTrustedLiveInventoryRead: true,
      exactCurrentRoleIds: exact22RoleIds(),
      currentInventoryFingerprintSha256: hashA,
      proposedInventoryFingerprintSha256: hashB,
      currentControlFingerprintSha256: hashC,
      freshOwnerVerified: true,
      ownerApprovalBound: true,
      currentRolloutMonitorOnly: true,
      dedicatedRoleAbsent: true,
      oldGuardImmutable: true,
      oldArmingTokenImmutable: true,
      oldActivationReceiptImmutable: true,
      sameTransactionAuditReady: true,
    );
  }

  group('Phase66 Step1I-T-O trusted bootstrap contract', () {
    test('seed is never production role inventory authority', () {
      expect(
        AgentSecurityIncidentRoleInventoryBootstrapContract
            .sourceMustBeFreshLiveFirestore,
        isTrue,
      );
      expect(
        AgentSecurityIncidentRoleInventoryBootstrapContract
            .staticSeedMayAuthorize,
        isFalse,
      );
    });

    test('trusted backend or Admin SDK owns bootstrap', () {
      expect(
        AgentSecurityIncidentRoleInventoryBootstrapContract
            .trustedBackendOrAdminSdkRequired,
        isTrue,
      );
      expect(
        AgentSecurityIncidentRoleInventoryBootstrapContract
            .ordinaryFlutterClientMayBootstrap,
        isFalse,
      );
      expect(
        AgentSecurityIncidentRoleInventoryBootstrapContract
            .backendSingleMutationAuthorityRequired,
        isTrue,
      );
    });

    test('exact 22 role ids are mandatory', () {
      expect(
        AgentSecurityIncidentRoleInventoryBootstrapContract.validExactCurrentRoleIds(
          exact22RoleIds(),
        ),
        isTrue,
      );

      expect(
        AgentSecurityIncidentRoleInventoryBootstrapContract.validExactCurrentRoleIds(
          <String>['only_one'],
        ),
        isFalse,
      );

      final List<String> collision = exact22RoleIds();
      collision[0] =
          AgentSecurityIncidentRoleInventoryBootstrapContract.targetRoleId;

      expect(
        AgentSecurityIncidentRoleInventoryBootstrapContract.validExactCurrentRoleIds(
          collision,
        ),
        isFalse,
      );
    });

    test(
      'ordinary client role mutation is denied by target rules contract',
      () {
        expect(
          AgentSecurityIncidentRoleInventoryRulesBoundaryContract
              .ordinaryClientMayCreateRole,
          isFalse,
        );
        expect(
          AgentSecurityIncidentRoleInventoryRulesBoundaryContract
              .ordinaryClientMayUpdateRole,
          isFalse,
        );
        expect(
          AgentSecurityIncidentRoleInventoryRulesBoundaryContract
              .ordinaryClientMayDeleteRole,
          isFalse,
        );
        expect(
          AgentSecurityIncidentRoleInventoryRulesBoundaryContract
              .trustedBackendOwnsRoleMutation,
          isTrue,
        );
      },
    );

    test('client cannot bootstrap manifest or migration hold', () {
      expect(
        AgentSecurityIncidentRoleInventoryRulesBoundaryContract
            .ordinaryClientMayCreateAuthorityManifest,
        isFalse,
      );
      expect(
        AgentSecurityIncidentRoleInventoryRulesBoundaryContract
            .ordinaryClientMayUpdateAuthorityManifest,
        isFalse,
      );
      expect(
        AgentSecurityIncidentRoleInventoryRulesBoundaryContract
            .ordinaryClientMayCreateMigrationHold,
        isFalse,
      );
      expect(
        AgentSecurityIncidentRoleInventoryRulesBoundaryContract
            .ordinaryClientMayUpdateMigrationHold,
        isFalse,
      );
    });

    test('missing backend fails closed before any bootstrap readiness', () {
      const AgentSecurityIncidentRoleInventoryBootstrapPolicy policy =
          AgentSecurityIncidentRoleInventoryBootstrapPolicy();

      final evidence = readyEvidence();

      final decision = policy.evaluate(
        AgentSecurityIncidentRoleInventoryBootstrapReadiness(
          trustedBackendImplemented: false,
          backendSingleMutationAuthority:
              evidence.backendSingleMutationAuthority,
          clientRoleWritesDenied: evidence.clientRoleWritesDenied,
          clientManifestWritesDenied: evidence.clientManifestWritesDenied,
          clientMigrationHoldWritesDenied:
              evidence.clientMigrationHoldWritesDenied,
          freshTrustedLiveInventoryRead: evidence.freshTrustedLiveInventoryRead,
          exactCurrentRoleIds: evidence.exactCurrentRoleIds,
          currentInventoryFingerprintSha256:
              evidence.currentInventoryFingerprintSha256,
          proposedInventoryFingerprintSha256:
              evidence.proposedInventoryFingerprintSha256,
          currentControlFingerprintSha256:
              evidence.currentControlFingerprintSha256,
          freshOwnerVerified: evidence.freshOwnerVerified,
          ownerApprovalBound: evidence.ownerApprovalBound,
          currentRolloutMonitorOnly: evidence.currentRolloutMonitorOnly,
          dedicatedRoleAbsent: evidence.dedicatedRoleAbsent,
          oldGuardImmutable: evidence.oldGuardImmutable,
          oldArmingTokenImmutable: evidence.oldArmingTokenImmutable,
          oldActivationReceiptImmutable: evidence.oldActivationReceiptImmutable,
          sameTransactionAuditReady: evidence.sameTransactionAuditReady,
        ),
      );

      expect(
        decision.status,
        AgentSecurityIncidentRoleInventoryBootstrapStatus.blockedBackendMissing,
      );
      expect(decision.readyForSeparateTrustedBootstrapExecution, isFalse);
    });

    test('broad client write boundary fails closed', () {
      const AgentSecurityIncidentRoleInventoryBootstrapPolicy policy =
          AgentSecurityIncidentRoleInventoryBootstrapPolicy();

      final evidence = readyEvidence();

      final decision = policy.evaluate(
        AgentSecurityIncidentRoleInventoryBootstrapReadiness(
          trustedBackendImplemented: evidence.trustedBackendImplemented,
          backendSingleMutationAuthority:
              evidence.backendSingleMutationAuthority,
          clientRoleWritesDenied: false,
          clientManifestWritesDenied: evidence.clientManifestWritesDenied,
          clientMigrationHoldWritesDenied:
              evidence.clientMigrationHoldWritesDenied,
          freshTrustedLiveInventoryRead: evidence.freshTrustedLiveInventoryRead,
          exactCurrentRoleIds: evidence.exactCurrentRoleIds,
          currentInventoryFingerprintSha256:
              evidence.currentInventoryFingerprintSha256,
          proposedInventoryFingerprintSha256:
              evidence.proposedInventoryFingerprintSha256,
          currentControlFingerprintSha256:
              evidence.currentControlFingerprintSha256,
          freshOwnerVerified: evidence.freshOwnerVerified,
          ownerApprovalBound: evidence.ownerApprovalBound,
          currentRolloutMonitorOnly: evidence.currentRolloutMonitorOnly,
          dedicatedRoleAbsent: evidence.dedicatedRoleAbsent,
          oldGuardImmutable: evidence.oldGuardImmutable,
          oldArmingTokenImmutable: evidence.oldArmingTokenImmutable,
          oldActivationReceiptImmutable: evidence.oldActivationReceiptImmutable,
          sameTransactionAuditReady: evidence.sameTransactionAuditReady,
        ),
      );

      expect(
        decision.status,
        AgentSecurityIncidentRoleInventoryBootstrapStatus.blockedRulesBoundary,
      );
    });

    test('full evidence only reaches a separate execution readiness state', () {
      const AgentSecurityIncidentRoleInventoryBootstrapPolicy policy =
          AgentSecurityIncidentRoleInventoryBootstrapPolicy();

      final decision = policy.evaluate(readyEvidence());

      expect(decision.readyForSeparateTrustedBootstrapExecution, isTrue);
      expect(decision.executesBootstrap, isFalse);
      expect(decision.writesFirestore, isFalse);
      expect(decision.consumesApproval, isFalse);
      expect(decision.createsRole, isFalse);
      expect(decision.changesGuard, isFalse);
      expect(decision.reusesActivationToken, isFalse);
      expect(decision.attachesRepository, isFalse);
      expect(decision.armsRepository, isFalse);
      expect(decision.writesIncident, isFalse);
      expect(decision.authorizesSuggestOnly, isFalse);
      expect(decision.authorizesAuto, isFalse);
    });

    test('rules deployment or bootstrap alone never authorizes role delta', () {
      expect(
        AgentSecurityIncidentRoleInventoryRulesBoundaryContract
            .rulesDeployAuthorizesRoleMigration,
        isFalse,
      );
      expect(
        AgentSecurityIncidentRoleInventoryRulesBoundaryContract
            .bootstrapAuthorizesRoleMigration,
        isFalse,
      );
      expect(
        AgentSecurityIncidentRoleInventoryRulesBoundaryContract
            .roleDeltaRequiresSeparateExecutionBoundary,
        isTrue,
      );
    });

    test('old activation evidence and rollout stay locked', () {
      expect(
        AgentSecurityIncidentRoleInventoryBootstrapContract.oldGuardImmutable,
        isTrue,
      );
      expect(
        AgentSecurityIncidentRoleInventoryBootstrapContract
            .oldArmingTokenImmutable,
        isTrue,
      );
      expect(
        AgentSecurityIncidentRoleInventoryBootstrapContract
            .oldActivationReceiptImmutable,
        isTrue,
      );
      expect(
        AgentSecurityIncidentRoleInventoryBootstrapContract
            .existingActivationTokenReuseAllowed,
        isFalse,
      );
      expect(
        AgentSecurityIncidentRoleInventoryBootstrapContract
            .authorizesSuggestOnly,
        isFalse,
      );
      expect(
        AgentSecurityIncidentRoleInventoryBootstrapContract.authorizesAuto,
        isFalse,
      );
    });
  });
}
