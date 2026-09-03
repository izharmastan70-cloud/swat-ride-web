import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_post_rebind_enable_execution_contract.dart';
import 'package:swat_ride/ai_agent/services/agent_security_incident_post_rebind_enable_execution_policy.dart';

void main() {
  const policy = AgentSecurityIncidentPostRebindEnableExecutionPolicy();

  AgentSecurityIncidentPostRebindTokenRecoveryEvidence tokenRecoveryEvidence({
    int manifestRevision = 3,
    int guardRevision = 3,
    int roleCount = 23,
    bool roleEnabled = false,
    String roleMode = 'ASK_FIRST',
    bool holdActive = true,
    String holdStatus = 'ROLE_DELTA_COMMITTED',
    String rolloutStage = 'MONITOR_ONLY',
    bool receipt = true,
    bool historicalExists = true,
    bool historicalReady = true,
    bool historicalExpired = true,
    bool historicalConsumed = false,
    bool rawReuseAttempted = false,
    bool freshOwner = true,
    bool attached = false,
    bool armed = false,
    bool incident = false,
  }) {
    return AgentSecurityIncidentPostRebindTokenRecoveryEvidence(
      authorityManifestRevision: manifestRevision,
      guardRevision: guardRevision,
      roleCount: roleCount,
      roleEnabled: roleEnabled,
      roleMode: roleMode,
      migrationHoldActive: holdActive,
      migrationHoldStatus: holdStatus,
      rolloutStage: rolloutStage,
      rebindReceiptVerified: receipt,
      historicalTokenExists: historicalExists,
      historicalTokenReady: historicalReady,
      historicalTokenExpired: historicalExpired,
      historicalTokenConsumed: historicalConsumed,
      rawHistoricalTokenReuseAttempted: rawReuseAttempted,
      freshOwnerIdentityVerified: freshOwner,
      repositoryRuntimeAttached: attached,
      repositoryExecutionArmed: armed,
      incidentWritePerformed: incident,
    );
  }

  AgentSecurityIncidentPostRebindEnableExecutionEvidence enableEvidence({
    int manifestRevision = 3,
    int guardRevision = 3,
    int roleCount = 23,
    String roleId = 'security_incident_agent',
    String module = 'security_incident',
    bool roleEnabled = false,
    String roleMode = 'ASK_FIRST',
    bool holdActive = true,
    String holdStatus = 'ROLE_DELTA_COMMITTED',
    String rolloutStage = 'MONITOR_ONLY',
    bool receipt = true,
    bool freshToken = true,
    bool tokenReady = true,
    bool tokenUnexpired = true,
    bool tokenExact = true,
    bool oldReuse = false,
    bool freshOwner = true,
    bool ownerApproval = true,
    bool approved = true,
    bool unconsumed = true,
    bool approvalExact = true,
    bool oldApprovalReuse = false,
    bool attached = false,
    bool armed = false,
    bool incident = false,
  }) {
    return AgentSecurityIncidentPostRebindEnableExecutionEvidence(
      authorityManifestRevision: manifestRevision,
      guardRevision: guardRevision,
      roleCount: roleCount,
      roleId: roleId,
      module: module,
      roleEnabled: roleEnabled,
      roleMode: roleMode,
      migrationHoldActive: holdActive,
      migrationHoldStatus: holdStatus,
      rolloutStage: rolloutStage,
      rebindReceiptVerified: receipt,
      freshReplacementTokenPresent: freshToken,
      freshReplacementTokenReady: tokenReady,
      freshReplacementTokenUnexpired: tokenUnexpired,
      freshReplacementTokenExactBindingVerified: tokenExact,
      oldTokenReuseAttempted: oldReuse,
      freshOwnerIdentityVerified: freshOwner,
      separateOwnerEnableApprovalPresent: ownerApproval,
      ownerEnableApprovalApproved: approved,
      ownerEnableApprovalUnconsumed: unconsumed,
      ownerEnableApprovalExactBindingVerified: approvalExact,
      migrationOrRebindApprovalReuseAttempted: oldApprovalReuse,
      repositoryRuntimeAttached: attached,
      repositoryExecutionArmed: armed,
      incidentWritePerformed: incident,
    );
  }

  group('post-rebind replacement token recovery', () {
    test('exact expired historical token state is eligible', () {
      final result = policy.evaluateTokenRecovery(tokenRecoveryEvidence());

      expect(result.eligibleForReplacementTokenIssuance, isTrue);
      expect(
        result.status,
        AgentSecurityIncidentPostRebindTokenRecoveryStatus.eligible,
      );
      expect(result.replacementTokenIssued, isFalse);
      expect(result.historicalTokenMutated, isFalse);
      expect(result.rawHistoricalTokenReused, isFalse);
      expect(result.writesFirestore, isFalse);
    });

    test('historical raw-token reuse is blocked', () {
      final result = policy.evaluateTokenRecovery(
        tokenRecoveryEvidence(rawReuseAttempted: true),
      );

      expect(
        result.status,
        AgentSecurityIncidentPostRebindTokenRecoveryStatus
            .blockedHistoricalToken,
      );
    });

    test('non-expired historical token is not recovery state', () {
      final result = policy.evaluateTokenRecovery(
        tokenRecoveryEvidence(historicalExpired: false),
      );

      expect(
        result.status,
        AgentSecurityIncidentPostRebindTokenRecoveryStatus
            .blockedHistoricalToken,
      );
    });

    test('wrong guard or role count blocks recovery', () {
      expect(
        policy
            .evaluateTokenRecovery(tokenRecoveryEvidence(guardRevision: 2))
            .status,
        AgentSecurityIncidentPostRebindTokenRecoveryStatus.blockedCheckpoint,
      );

      expect(
        policy
            .evaluateTokenRecovery(tokenRecoveryEvidence(roleCount: 22))
            .status,
        AgentSecurityIncidentPostRebindTokenRecoveryStatus.blockedCheckpoint,
      );
    });

    test('fresh Owner identity is mandatory for recovery', () {
      final result = policy.evaluateTokenRecovery(
        tokenRecoveryEvidence(freshOwner: false),
      );

      expect(
        result.status,
        AgentSecurityIncidentPostRebindTokenRecoveryStatus.blockedOwnerIdentity,
      );
    });
  });

  group('atomic role-enable / hold-release boundary', () {
    test('clean evidence is eligible but not executed', () {
      final result = policy.evaluateAtomicEnable(enableEvidence());

      expect(result.eligibleForAtomicEnableAndHoldRelease, isTrue);
      expect(
        result.status,
        AgentSecurityIncidentPostRebindEnableExecutionStatus.eligible,
      );

      expect(result.plannedAtomicWriteOrder, <String>[
        'OWNER_ENABLE_APPROVAL_CONSUME',
        'REPLACEMENT_TOKEN_CONSUME',
        'SECURITY_INCIDENT_ROLE_ENABLE',
        'MIGRATION_HOLD_RELEASE',
        'ENABLE_AUDIT_CREATE',
      ]);

      expect(result.executionPerformed, isFalse);
      expect(result.approvalConsumed, isFalse);
      expect(result.replacementTokenConsumed, isFalse);
      expect(result.roleEnablePerformed, isFalse);
      expect(result.migrationHoldReleased, isFalse);
      expect(result.repositoryAttached, isFalse);
      expect(result.repositoryArmed, isFalse);
      expect(result.incidentWritten, isFalse);
      expect(result.authorizesSuggestOnly, isFalse);
      expect(result.authorizesAuto, isFalse);
      expect(result.writesFirestore, isFalse);
    });

    test('fresh exact unexpired replacement token is mandatory', () {
      expect(
        policy
            .evaluateAtomicEnable(enableEvidence(tokenUnexpired: false))
            .status,
        AgentSecurityIncidentPostRebindEnableExecutionStatus
            .blockedReplacementToken,
      );

      expect(
        policy.evaluateAtomicEnable(enableEvidence(tokenExact: false)).status,
        AgentSecurityIncidentPostRebindEnableExecutionStatus
            .blockedReplacementToken,
      );

      expect(
        policy.evaluateAtomicEnable(enableEvidence(oldReuse: true)).status,
        AgentSecurityIncidentPostRebindEnableExecutionStatus
            .blockedReplacementToken,
      );
    });

    test(
      'separate approved unconsumed exact Owner enable approval required',
      () {
        expect(
          policy
              .evaluateAtomicEnable(enableEvidence(ownerApproval: false))
              .status,
          AgentSecurityIncidentPostRebindEnableExecutionStatus
              .blockedOwnerApproval,
        );

        expect(
          policy.evaluateAtomicEnable(enableEvidence(unconsumed: false)).status,
          AgentSecurityIncidentPostRebindEnableExecutionStatus
              .blockedOwnerApproval,
        );

        expect(
          policy
              .evaluateAtomicEnable(enableEvidence(oldApprovalReuse: true))
              .status,
          AgentSecurityIncidentPostRebindEnableExecutionStatus
              .blockedOwnerApproval,
        );
      },
    );

    test('role must still be disabled and hold active', () {
      expect(
        policy.evaluateAtomicEnable(enableEvidence(roleEnabled: true)).status,
        AgentSecurityIncidentPostRebindEnableExecutionStatus.blockedCheckpoint,
      );

      expect(
        policy.evaluateAtomicEnable(enableEvidence(holdActive: false)).status,
        AgentSecurityIncidentPostRebindEnableExecutionStatus.blockedCheckpoint,
      );
    });

    test('attach arm or incident before enable is blocked', () {
      expect(
        policy.evaluateAtomicEnable(enableEvidence(attached: true)).status,
        AgentSecurityIncidentPostRebindEnableExecutionStatus
            .blockedRuntimeState,
      );

      expect(
        policy.evaluateAtomicEnable(enableEvidence(armed: true)).status,
        AgentSecurityIncidentPostRebindEnableExecutionStatus
            .blockedRuntimeState,
      );

      expect(
        policy.evaluateAtomicEnable(enableEvidence(incident: true)).status,
        AgentSecurityIncidentPostRebindEnableExecutionStatus
            .blockedRuntimeState,
      );
    });

    test('contract keeps token recovery separate from atomic enable', () {
      expect(
        AgentSecurityIncidentPostRebindEnableExecutionContract
            .replacementTokenWriteOrder,
        <String>[
          'FRESH_REPLACEMENT_TOKEN_CREATE',
          'REPLACEMENT_TOKEN_AUDIT_CREATE',
        ],
      );

      expect(
        AgentSecurityIncidentPostRebindEnableExecutionContract
            .oldTokenReuseAllowed,
        isFalse,
      );

      expect(
        AgentSecurityIncidentPostRebindEnableExecutionContract
            .replacementTokenMutatesHistoricalToken,
        isFalse,
      );

      expect(
        AgentSecurityIncidentPostRebindEnableExecutionContract
            .replacementTokenMustBeConsumedAtomically,
        isTrue,
      );

      expect(
        AgentSecurityIncidentPostRebindEnableExecutionContract
            .enableAndHoldReleaseMustBeAtomic,
        isTrue,
      );

      expect(
        AgentSecurityIncidentPostRebindEnableExecutionContract
            .repositoryAttachIncluded,
        isFalse,
      );

      expect(
        AgentSecurityIncidentPostRebindEnableExecutionContract
            .repositoryArmIncluded,
        isFalse,
      );

      expect(
        AgentSecurityIncidentPostRebindEnableExecutionContract
            .incidentWriteIncluded,
        isFalse,
      );

      expect(
        AgentSecurityIncidentPostRebindEnableExecutionContract
            .suggestOnlyAuthorized,
        isFalse,
      );

      expect(
        AgentSecurityIncidentPostRebindEnableExecutionContract.autoAuthorized,
        isFalse,
      );
    });

    test('policy itself has zero live authority', () {
      expect(policy.offlineOnly, isTrue);
      expect(policy.performsFirestoreRead, isFalse);
      expect(policy.performsFirestoreWrite, isFalse);
      expect(policy.createsApproval, isFalse);
      expect(policy.consumesApproval, isFalse);
      expect(policy.issuesReplacementToken, isFalse);
      expect(policy.enablesRole, isFalse);
      expect(policy.releasesMigrationHold, isFalse);
      expect(policy.attachesRepository, isFalse);
      expect(policy.armsRepository, isFalse);
      expect(policy.writesIncident, isFalse);
      expect(policy.authorizesSuggestOnly, isFalse);
      expect(policy.authorizesAuto, isFalse);

      expect(policy.requiresFreshReplacementToken, isTrue);
      expect(policy.permitsHistoricalTokenReuse, isFalse);
      expect(policy.requiresAtomicReplacementTokenConsumption, isTrue);
      expect(policy.requiresFreshOwnerIdentity, isTrue);
      expect(policy.requiresSeparateOwnerEnableApproval, isTrue);
      expect(policy.requiresAtomicRoleEnableAndHoldRelease, isTrue);
    });
  });
}
