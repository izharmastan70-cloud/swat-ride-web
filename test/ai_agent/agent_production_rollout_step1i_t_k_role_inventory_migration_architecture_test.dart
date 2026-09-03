import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_role_inventory_migration_plan.dart';
import 'package:swat_ride/ai_agent/services/agent_security_incident_role_inventory_migration_coordinator.dart';

void main() {
  const String hashA =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  const String hashB =
      'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
  const String hashC =
      'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';
  const String hashD =
      'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd';

  AgentSecurityIncidentRoleInventoryMigrationPlan validPlan({
    bool freshOwnerVerified = true,
    bool migrationHoldActive = true,
    bool existingArmingTokenReuseAllowed = false,
    bool repositoryAttachAuthorized = false,
    bool repositoryArmAuthorized = false,
    bool firstIncidentWriteAuthorized = false,
    bool authorizesSuggestOnly = false,
    bool authorizesAuto = false,
  }) {
    return AgentSecurityIncidentRoleInventoryMigrationPlan(
      currentInventoryVersion: 'phase66_roles_v1_22',
      proposedInventoryVersion: 'phase66_roles_v2_23_security_incident',
      currentRoleCount: 22,
      proposedRoleCount: 23,
      currentInventoryFingerprintSha256: hashA,
      proposedInventoryFingerprintSha256: hashB,
      currentControlFingerprintSha256: hashC,
      freshOwnerVerified: freshOwnerVerified,
      ownerApprovalBindingSha256: hashD,
      currentRolloutStage: 'MONITOR_ONLY',
      dedicatedRoleId: 'security_incident_agent',
      dedicatedModule: 'security_incident',
      dedicatedActionId: 'security_incident.attach_runtime',
      currentGuardRevision: 2,
      proposedGuardRevision: 3,
      oldGuardImmutable: true,
      oldArmingTokenImmutable: true,
      oldActivationReceiptImmutable: true,
      existingArmingTokenReuseAllowed: existingArmingTokenReuseAllowed,
      migrationHoldRequired: true,
      migrationHoldActive: migrationHoldActive,
      newLiveSnapshotRequired: true,
      newGuardRequired: true,
      newOneTimeTokenRequired: true,
      newMigrationReceiptRequired: true,
      firstIncidentWriteAuthorized: firstIncidentWriteAuthorized,
      repositoryAttachAuthorized: repositoryAttachAuthorized,
      repositoryArmAuthorized: repositoryArmAuthorized,
      authorizesSuggestOnly: authorizesSuggestOnly,
      authorizesAuto: authorizesAuto,
    );
  }

  group('Phase66 Step1I-T-K migration architecture', () {
    const coordinator =
        AgentSecurityIncidentRoleInventoryMigrationCoordinator();

    test('valid offline 22 to 23 plan is architecture-ready only', () {
      final decision = coordinator.evaluateOffline(validPlan());

      expect(decision.readyForSeparateAtomicExecutorDesign, isTrue);
      expect(decision.writesFirestore, isFalse);
      expect(decision.createsRole, isFalse);
      expect(decision.consumesApproval, isFalse);
      expect(decision.attachesRuntime, isFalse);
      expect(decision.armsRepository, isFalse);
      expect(decision.writesIncident, isFalse);
    });

    test('fresh Owner verification is mandatory', () {
      final decision = coordinator.evaluateOffline(
        validPlan(freshOwnerVerified: false),
      );

      expect(decision.readyForSeparateAtomicExecutorDesign, isFalse);
      expect(decision.reasonCode, 'fresh_owner_verification_required');
    });

    test('migration hold is mandatory before role delta execution design', () {
      final decision = coordinator.evaluateOffline(
        validPlan(migrationHoldActive: false),
      );

      expect(decision.readyForSeparateAtomicExecutorDesign, isFalse);
      expect(decision.reasonCode, 'fail_closed_migration_hold_required');
    });

    test('old arming token can never be reused', () {
      final decision = coordinator.evaluateOffline(
        validPlan(existingArmingTokenReuseAllowed: true),
      );

      expect(decision.readyForSeparateAtomicExecutorDesign, isFalse);
      expect(
        decision.reasonCode,
        'old_activation_evidence_must_remain_immutable',
      );
    });

    test('migration cannot authorize repository attach', () {
      final decision = coordinator.evaluateOffline(
        validPlan(repositoryAttachAuthorized: true),
      );

      expect(decision.readyForSeparateAtomicExecutorDesign, isFalse);
      expect(
        decision.reasonCode,
        'migration_must_not_grant_runtime_or_rollout_authority',
      );
    });

    test('migration cannot authorize repository arm', () {
      final decision = coordinator.evaluateOffline(
        validPlan(repositoryArmAuthorized: true),
      );

      expect(decision.readyForSeparateAtomicExecutorDesign, isFalse);
    });

    test('migration cannot authorize first incident write', () {
      final decision = coordinator.evaluateOffline(
        validPlan(firstIncidentWriteAuthorized: true),
      );

      expect(decision.readyForSeparateAtomicExecutorDesign, isFalse);
    });

    test('migration cannot authorize SUGGEST_ONLY', () {
      final decision = coordinator.evaluateOffline(
        validPlan(authorizesSuggestOnly: true),
      );

      expect(decision.readyForSeparateAtomicExecutorDesign, isFalse);
    });

    test('migration cannot authorize AUTO', () {
      final decision = coordinator.evaluateOffline(
        validPlan(authorizesAuto: true),
      );

      expect(decision.readyForSeparateAtomicExecutorDesign, isFalse);
    });

    test('coordinator has no live executor or Firestore authority', () {
      expect(coordinator.executionArmed, isFalse);
      expect(coordinator.liveExecutorAttached, isFalse);
      expect(coordinator.writesFirestore, isFalse);
      expect(coordinator.createsRole, isFalse);
      expect(coordinator.updatesRole, isFalse);
      expect(coordinator.syncsRolePermissions, isFalse);
      expect(coordinator.createsOwnerApproval, isFalse);
      expect(coordinator.consumesOwnerApproval, isFalse);
    });

    test('old evidence remains immutable and fresh rebinding is separate', () {
      expect(coordinator.mutatesExistingGuard, isFalse);
      expect(coordinator.mutatesExistingArmingToken, isFalse);
      expect(coordinator.mutatesExistingActivationReceipt, isFalse);
      expect(coordinator.reusesExistingArmingToken, isFalse);
      expect(coordinator.createsNewGuard, isFalse);
      expect(coordinator.createsNewArmingToken, isFalse);
      expect(coordinator.createsMigrationReceipt, isFalse);
    });

    test('dedicated atomic executor remains required', () {
      expect(coordinator.requiresDedicatedAtomicExecutor, isTrue);
      expect(coordinator.requiresExactCurrentStatePrecondition, isTrue);
      expect(coordinator.requiresMigrationHold, isTrue);
      expect(coordinator.usesOrdinaryCreateRoleAsMigrationAuthority, isFalse);
    });
  });
}
