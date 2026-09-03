import '../constants/agent_production_rollout_activation_constants.dart';
import '../constants/agent_production_rollout_snapshot_constants.dart';
import 'agent_production_rollout_snapshot.dart';

class AgentProductionRolloutTrustedOwnerContext {
  AgentProductionRolloutTrustedOwnerContext({
    required this.actorRole,
    required this.actorReferenceSha256,
    required this.sessionReferenceSha256,
    required this.authorityVerified,
    required this.freshReauthenticationVerified,
    required this.issuedAtUtc,
  }) {
    validate();
  }

  final String actorRole;
  final String actorReferenceSha256;
  final String sessionReferenceSha256;
  final bool authorityVerified;
  final bool freshReauthenticationVerified;
  final DateTime issuedAtUtc;

  bool get storesRawUserId => false;
  bool get storesRawSessionToken => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;

  void validate() {
    final RegExp sha256 = RegExp(r'^[A-Fa-f0-9]{64}$');

    if (!AgentProductionRolloutTrustedActorRole.allowed.contains(actorRole) ||
        !sha256.hasMatch(actorReferenceSha256) ||
        !sha256.hasMatch(sessionReferenceSha256) ||
        !issuedAtUtc.isUtc) {
      throw const FormatException(
        'Invalid trusted Owner/Super Admin production-rollout context.',
      );
    }
  }
}

class AgentProductionRolloutTrustedCapture {
  AgentProductionRolloutTrustedCapture({
    required this.snapshot,
    required this.controlStateFingerprintSha256,
    required this.actorReferenceSha256,
    required this.capturedAtUtc,
  }) {
    validate();
  }

  final AgentProductionRolloutSnapshot snapshot;
  final String controlStateFingerprintSha256;
  final String actorReferenceSha256;
  final DateTime capturedAtUtc;

  bool get metadataOnly => true;
  bool get activatesRollout => false;
  bool get changesMasterSettings => false;
  bool get changesAgentMode => false;

  void validate() {
    final RegExp sha256 = RegExp(r'^[A-Fa-f0-9]{64}$');

    snapshot.validate();

    if (!sha256.hasMatch(controlStateFingerprintSha256) ||
        !sha256.hasMatch(actorReferenceSha256) ||
        !capturedAtUtc.isUtc ||
        capturedAtUtc != snapshot.capturedAtUtc) {
      throw const FormatException(
        'Invalid trusted production rollout capture.',
      );
    }
  }
}

class AgentProductionRolloutAtomicPrecondition {
  AgentProductionRolloutAtomicPrecondition({
    required this.expectedSnapshotFingerprintSha256,
    required this.expectedControlStateFingerprintSha256,
    required this.expectedRoleCount,
    required this.expectedMasterEnabled,
    required this.expectedEmergencyReadOnly,
    required this.expectedNoEnabledAutoRole,
    required this.targetStage,
    required this.createdAtUtc,
    required this.expiresAtUtc,
  }) {
    validate();
  }

  final String expectedSnapshotFingerprintSha256;
  final String expectedControlStateFingerprintSha256;
  final int expectedRoleCount;

  final bool expectedMasterEnabled;
  final bool expectedEmergencyReadOnly;
  final bool expectedNoEnabledAutoRole;

  final String targetStage;
  final DateTime createdAtUtc;
  final DateTime expiresAtUtc;

  bool get requiresTransactionalReread => true;
  bool get requiresExactControlStateMatch => true;
  bool get requiresAtomicAudit => true;
  bool get authorizesWriteByItself => false;

  void validate() {
    final RegExp sha256 = RegExp(r'^[A-Fa-f0-9]{64}$');

    if (!sha256.hasMatch(expectedSnapshotFingerprintSha256) ||
        !sha256.hasMatch(expectedControlStateFingerprintSha256) ||
        expectedRoleCount <= 0 ||
        expectedMasterEnabled ||
        !expectedEmergencyReadOnly ||
        !expectedNoEnabledAutoRole ||
        targetStage != AgentProductionRolloutStage.monitorOnly ||
        !createdAtUtc.isUtc ||
        !expiresAtUtc.isUtc ||
        !expiresAtUtc.isAfter(createdAtUtc) ||
        expiresAtUtc.difference(createdAtUtc) >
            AgentProductionRolloutActivationLimits
                .atomicPreconditionMaxValidity) {
      throw const FormatException(
        'Invalid MONITOR_ONLY atomic activation precondition.',
      );
    }
  }
}

class AgentProductionRolloutMonitorActivationPlan {
  AgentProductionRolloutMonitorActivationPlan({
    required this.planId,
    required this.ownerApprovalId,
    required this.actorReferenceSha256,
    required this.sourceSnapshotFingerprintSha256,
    required this.sourceControlStateFingerprintSha256,
    required this.targetStage,
    required this.targetMasterEnabled,
    required this.targetEmergencyReadOnly,
    required this.targetFreeAiEnabled,
    required this.targetLocalAiEnabled,
    required this.targetPaidCodeAiEnabled,
    required this.targetPaidReasoningEnabled,
    required this.targetCallAgentEnabled,
    required this.autoTrafficPercent,
    required this.businessWriteTrafficPercent,
    required this.channelsRemainDisabledExceptAppChat,
    required this.precondition,
    required this.plannedAtUtc,
  }) {
    validate();
  }

  final String planId;
  final String ownerApprovalId;
  final String actorReferenceSha256;

  final String sourceSnapshotFingerprintSha256;
  final String sourceControlStateFingerprintSha256;

  final String targetStage;

  final bool targetMasterEnabled;
  final bool targetEmergencyReadOnly;
  final bool targetFreeAiEnabled;
  final bool targetLocalAiEnabled;
  final bool targetPaidCodeAiEnabled;
  final bool targetPaidReasoningEnabled;
  final bool targetCallAgentEnabled;

  final int autoTrafficPercent;
  final int businessWriteTrafficPercent;
  final bool channelsRemainDisabledExceptAppChat;

  final AgentProductionRolloutAtomicPrecondition precondition;
  final DateTime plannedAtUtc;

  bool get planOnly => true;
  bool get performsWrite => false;
  bool get consumesApproval => false;
  bool get grantsPermission => false;
  bool get routesAutoTraffic => false;
  bool get executesBusinessAction => false;

  void validate() {
    final RegExp sha256 = RegExp(r'^[A-Fa-f0-9]{64}$');

    precondition.validate();

    if (planId.trim().isEmpty ||
        ownerApprovalId.trim().isEmpty ||
        !sha256.hasMatch(actorReferenceSha256) ||
        !sha256.hasMatch(sourceSnapshotFingerprintSha256) ||
        !sha256.hasMatch(sourceControlStateFingerprintSha256) ||
        targetStage != AgentProductionRolloutStage.monitorOnly ||
        !targetMasterEnabled ||
        targetEmergencyReadOnly ||
        !targetFreeAiEnabled ||
        targetLocalAiEnabled ||
        targetPaidCodeAiEnabled ||
        targetPaidReasoningEnabled ||
        targetCallAgentEnabled ||
        autoTrafficPercent !=
            AgentProductionRolloutActivationLimits.autoTrafficPercent ||
        businessWriteTrafficPercent !=
            AgentProductionRolloutActivationLimits
                .businessWriteTrafficPercent ||
        !channelsRemainDisabledExceptAppChat ||
        !plannedAtUtc.isUtc ||
        precondition.expectedSnapshotFingerprintSha256 !=
            sourceSnapshotFingerprintSha256 ||
        precondition.expectedControlStateFingerprintSha256 !=
            sourceControlStateFingerprintSha256) {
      throw const FormatException(
        'Invalid initial MONITOR_ONLY production rollout activation plan.',
      );
    }
  }
}

class AgentProductionRolloutMonitorPlanDecision {
  const AgentProductionRolloutMonitorPlanDecision({
    required this.status,
    required this.reasonCode,
    required this.plan,
  });

  final String status;
  final String reasonCode;
  final AgentProductionRolloutMonitorActivationPlan? plan;

  bool get eligible => plan != null;
  bool get executesWrite => false;
  bool get activatesProduction => false;
}
