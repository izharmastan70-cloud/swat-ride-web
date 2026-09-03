import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../constants/agent_production_rollout_repository_constants.dart';
import '../models/agent_production_rollout_activation_models.dart';

class AgentProductionRolloutMonitorPlanBindingService {
  const AgentProductionRolloutMonitorPlanBindingService();

  String fingerprint(AgentProductionRolloutMonitorActivationPlan plan) {
    plan.validate();

    return _sha256(<String, dynamic>{
      'algorithm': AgentProductionRolloutMonitorPlanBinding.algorithm,
      'planId': plan.planId,
      'ownerApprovalId': plan.ownerApprovalId,
      'actorReferenceSha256': plan.actorReferenceSha256.toLowerCase(),
      'sourceSnapshotFingerprintSha256': plan.sourceSnapshotFingerprintSha256
          .toLowerCase(),
      'sourceControlStateFingerprintSha256': plan
          .sourceControlStateFingerprintSha256
          .toLowerCase(),
      'targetStage': plan.targetStage,
      'targetMasterEnabled': plan.targetMasterEnabled,
      'targetEmergencyReadOnly': plan.targetEmergencyReadOnly,
      'targetFreeAiEnabled': plan.targetFreeAiEnabled,
      'targetLocalAiEnabled': plan.targetLocalAiEnabled,
      'targetPaidCodeAiEnabled': plan.targetPaidCodeAiEnabled,
      'targetPaidReasoningEnabled': plan.targetPaidReasoningEnabled,
      'targetCallAgentEnabled': plan.targetCallAgentEnabled,
      'autoTrafficPercent': plan.autoTrafficPercent,
      'businessWriteTrafficPercent': plan.businessWriteTrafficPercent,
      'channelsRemainDisabledExceptAppChat':
          plan.channelsRemainDisabledExceptAppChat,
      'precondition': <String, dynamic>{
        'expectedSnapshotFingerprintSha256': plan
            .precondition
            .expectedSnapshotFingerprintSha256
            .toLowerCase(),
        'expectedControlStateFingerprintSha256': plan
            .precondition
            .expectedControlStateFingerprintSha256
            .toLowerCase(),
        'expectedRoleCount': plan.precondition.expectedRoleCount,
        'expectedMasterEnabled': plan.precondition.expectedMasterEnabled,
        'expectedEmergencyReadOnly':
            plan.precondition.expectedEmergencyReadOnly,
        'expectedNoEnabledAutoRole':
            plan.precondition.expectedNoEnabledAutoRole,
        'targetStage': plan.precondition.targetStage,
        'createdAtUtc': plan.precondition.createdAtUtc.toIso8601String(),
        'expiresAtUtc': plan.precondition.expiresAtUtc.toIso8601String(),
      },
      'plannedAtUtc': plan.plannedAtUtc.toIso8601String(),
    });
  }

  String idempotencyKey(AgentProductionRolloutMonitorActivationPlan plan) {
    final String planFingerprint = fingerprint(plan);

    return _sha256(<String, dynamic>{
      'algorithm':
          AgentProductionRolloutMonitorPlanBinding.idempotencyAlgorithm,
      'planId': plan.planId,
      'ownerApprovalId': plan.ownerApprovalId,
      'sourceControlStateFingerprintSha256': plan
          .sourceControlStateFingerprintSha256
          .toLowerCase(),
      'planFingerprintSha256': planFingerprint,
    });
  }

  String _sha256(Map<String, dynamic> payload) {
    return sha256
        .convert(utf8.encode(jsonEncode(_canonicalize(payload))))
        .toString();
  }

  dynamic _canonicalize(dynamic value) {
    if (value == null || value is String || value is bool || value is num) {
      return value;
    }

    if (value is List) {
      return value.map<dynamic>(_canonicalize).toList(growable: false);
    }

    if (value is Map) {
      final List<String> keys =
          value.keys
              .map((dynamic key) => key.toString())
              .toList(growable: false)
            ..sort();

      final Map<String, dynamic> sorted = <String, dynamic>{};
      for (final String key in keys) {
        sorted[key] = _canonicalize(value[key]);
      }
      return sorted;
    }

    return value.toString();
  }

  bool get writesFirestore => false;
  bool get grantsAuthority => false;
}
