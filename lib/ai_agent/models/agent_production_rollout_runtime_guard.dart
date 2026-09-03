import '../constants/agent_production_rollout_runtime_guard_constants.dart';

class AgentProductionRolloutRuntimeGuard {
  AgentProductionRolloutRuntimeGuard({
    required this.enabled,
    required this.guardVersion,
    required this.revision,
    required this.targetStage,
    required this.runtimeMonitorOnlyOverlayEnforced,
    required this.noAutoBusinessWriteBoundaryEnforced,
    required this.appChatOnly,
    required this.autoTrafficPercent,
    required this.businessWriteTrafficPercent,
    required this.externalChannelsEnabled,
    required this.controlStateFingerprintSha256,
    required this.planFingerprintSha256,
    required this.roleCount,
    required this.ownerApprovalId,
    required this.actorReferenceSha256,
  }) {
    validate();
  }

  final bool enabled;
  final String guardVersion;
  final int revision;
  final String targetStage;

  final bool runtimeMonitorOnlyOverlayEnforced;
  final bool noAutoBusinessWriteBoundaryEnforced;
  final bool appChatOnly;

  final int autoTrafficPercent;
  final int businessWriteTrafficPercent;
  final bool externalChannelsEnabled;

  final String controlStateFingerprintSha256;
  final String planFingerprintSha256;
  final int roleCount;
  final String ownerApprovalId;
  final String actorReferenceSha256;

  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get activatesProduction => false;
  bool get enablesAuto => false;
  bool get enablesBusinessWrites => false;

  void validate() {
    final RegExp sha256 = RegExp(r'^[A-Fa-f0-9]{64}$');

    if (guardVersion !=
            AgentProductionRolloutRuntimeGuardVersion.monitorOnlyV1 ||
        revision < 1 ||
        targetStage != AgentProductionRolloutRuntimeGuardStatus.monitorOnly ||
        !runtimeMonitorOnlyOverlayEnforced ||
        !noAutoBusinessWriteBoundaryEnforced ||
        !appChatOnly ||
        autoTrafficPercent != 0 ||
        businessWriteTrafficPercent != 0 ||
        externalChannelsEnabled ||
        !sha256.hasMatch(controlStateFingerprintSha256) ||
        !sha256.hasMatch(planFingerprintSha256) ||
        roleCount <= 0 ||
        ownerApprovalId.trim().isEmpty ||
        !sha256.hasMatch(actorReferenceSha256)) {
      throw const FormatException(
        'Invalid Phase 66 MONITOR_ONLY production runtime guard.',
      );
    }
  }

  Map<String, dynamic> toMap() {
    validate();

    return <String, dynamic>{
      'enabled': enabled,
      'guardVersion': guardVersion,
      'revision': revision,
      'targetStage': targetStage,
      'runtimeMonitorOnlyOverlayEnforced': runtimeMonitorOnlyOverlayEnforced,
      'noAutoBusinessWriteBoundaryEnforced':
          noAutoBusinessWriteBoundaryEnforced,
      'appChatOnly': appChatOnly,
      'autoTrafficPercent': autoTrafficPercent,
      'businessWriteTrafficPercent': businessWriteTrafficPercent,
      'externalChannelsEnabled': externalChannelsEnabled,
      'controlStateFingerprintSha256': controlStateFingerprintSha256
          .toLowerCase(),
      'planFingerprintSha256': planFingerprintSha256.toLowerCase(),
      'roleCount': roleCount,
      'ownerApprovalId': ownerApprovalId.trim(),
      'actorReferenceSha256': actorReferenceSha256.toLowerCase(),
    };
  }

  factory AgentProductionRolloutRuntimeGuard.fromMap(Map<String, dynamic> map) {
    return AgentProductionRolloutRuntimeGuard(
      enabled: map['enabled'] == true,
      guardVersion: (map['guardVersion'] ?? '').toString().trim(),
      revision: (map['revision'] as num?)?.toInt() ?? 0,
      targetStage: (map['targetStage'] ?? '').toString().trim(),
      runtimeMonitorOnlyOverlayEnforced:
          map['runtimeMonitorOnlyOverlayEnforced'] == true,
      noAutoBusinessWriteBoundaryEnforced:
          map['noAutoBusinessWriteBoundaryEnforced'] == true,
      appChatOnly: map['appChatOnly'] == true,
      autoTrafficPercent: (map['autoTrafficPercent'] as num?)?.toInt() ?? -1,
      businessWriteTrafficPercent:
          (map['businessWriteTrafficPercent'] as num?)?.toInt() ?? -1,
      externalChannelsEnabled: map['externalChannelsEnabled'] == true,
      controlStateFingerprintSha256:
          (map['controlStateFingerprintSha256'] ?? '').toString().trim(),
      planFingerprintSha256: (map['planFingerprintSha256'] ?? '')
          .toString()
          .trim(),
      roleCount: (map['roleCount'] as num?)?.toInt() ?? 0,
      ownerApprovalId: (map['ownerApprovalId'] ?? '').toString().trim(),
      actorReferenceSha256: (map['actorReferenceSha256'] ?? '')
          .toString()
          .trim(),
    );
  }
}

class AgentProductionRolloutGuardPersistenceRequest {
  AgentProductionRolloutGuardPersistenceRequest({
    required this.guard,
    required this.expectedPreviousRevision,
    required this.requestedAtUtc,
  }) {
    validate();
  }

  final AgentProductionRolloutRuntimeGuard guard;
  final int expectedPreviousRevision;
  final DateTime requestedAtUtc;

  void validate() {
    guard.validate();

    if (expectedPreviousRevision < 0 ||
        guard.revision != expectedPreviousRevision + 1 ||
        !requestedAtUtc.isUtc) {
      throw const FormatException(
        'Invalid Phase 66 production guard persistence request.',
      );
    }
  }
}

class AgentProductionRolloutGuardPersistenceResult {
  const AgentProductionRolloutGuardPersistenceResult({
    required this.status,
    required this.reasonCode,
    required this.revision,
    required this.persisted,
    required this.idempotentReplay,
  });

  final String status;
  final String reasonCode;
  final int revision;
  final bool persisted;
  final bool idempotentReplay;

  bool get activatesProduction => false;
  bool get armsActivationRepository => false;
}
