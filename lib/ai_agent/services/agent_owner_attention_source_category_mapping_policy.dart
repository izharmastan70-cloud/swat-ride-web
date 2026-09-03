import '../constants/agent_owner_attention_constants.dart';
import '../constants/agent_owner_attention_source_signal_constants.dart';
import '../models/agent_owner_attention_source_mapping_decision.dart';
import 'agent_owner_attention_priority_policy.dart';

class AgentOwnerAttentionSourceCategoryMappingPolicy {
  const AgentOwnerAttentionSourceCategoryMappingPolicy({
    this.priorityPolicy = const AgentOwnerAttentionPriorityPolicy(),
  });

  final AgentOwnerAttentionPriorityPolicy priorityPolicy;

  AgentOwnerAttentionSourceMappingDecision map({
    required String sourceType,
    required String sourceKind,
  }) {
    if (!AgentOwnerAttentionSourceType.values.contains(sourceType) ||
        !AgentOwnerAttentionSourceKind.values.contains(sourceKind)) {
      throw const FormatException('Unknown Owner Attention source mapping.');
    }

    final category = _categoryFor(
      sourceType: sourceType,
      sourceKind: sourceKind,
    );

    return AgentOwnerAttentionSourceMappingDecision(
      category: category,
      minimumPriority: priorityPolicy.minimumPriorityFor(category),
      reasonCode: 'source_mapped_to_unified_owner_attention',
    );
  }

  String _categoryFor({
    required String sourceType,
    required String sourceKind,
  }) {
    switch (sourceKind) {
      case AgentOwnerAttentionSourceKind.seriousComplaint:
        _requireSource(sourceType, <String>{
          AgentOwnerAttentionSourceType.feedback,
        });
        return AgentOwnerAttentionCategory.seriousComplaint;

      case AgentOwnerAttentionSourceKind.highValuePaymentDispute:
        _requireSource(sourceType, <String>{
          AgentOwnerAttentionSourceType.payment,
          AgentOwnerAttentionSourceType.call,
        });
        return AgentOwnerAttentionCategory.highValuePaymentDispute;

      case AgentOwnerAttentionSourceKind.unresolvedCall:
        _requireSource(sourceType, <String>{
          AgentOwnerAttentionSourceType.call,
        });
        return AgentOwnerAttentionCategory.unresolvedCall;

      case AgentOwnerAttentionSourceKind.securityAlert:
        _requireSource(sourceType, <String>{
          AgentOwnerAttentionSourceType.security,
        });
        return AgentOwnerAttentionCategory.securityAlert;

      case AgentOwnerAttentionSourceKind.agentConflict:
        _requireSource(sourceType, <String>{
          AgentOwnerAttentionSourceType.crossAgentSupervisor,
        });
        return AgentOwnerAttentionCategory.agentConflict;

      case AgentOwnerAttentionSourceKind.pendingSensitiveApproval:
        _requireSource(sourceType, <String>{
          AgentOwnerAttentionSourceType.approval,
        });
        return AgentOwnerAttentionCategory.pendingSensitiveApproval;

      case AgentOwnerAttentionSourceKind.criticalCrash:
        _requireSource(sourceType, <String>{
          AgentOwnerAttentionSourceType.crash,
        });
        return AgentOwnerAttentionCategory.criticalCrash;

      case AgentOwnerAttentionSourceKind.fraudFinding:
        _requireSource(sourceType, <String>{
          AgentOwnerAttentionSourceType.fraud,
        });
        return AgentOwnerAttentionCategory.fraudFinding;

      case AgentOwnerAttentionSourceKind.emergencyCase:
        _requireSource(sourceType, <String>{
          AgentOwnerAttentionSourceType.emergency,
        });
        return AgentOwnerAttentionCategory.emergencyCase;

      case AgentOwnerAttentionSourceKind.emailUnusualReview:
        _requireSource(sourceType, <String>{
          AgentOwnerAttentionSourceType.emailAttention,
        });
        return AgentOwnerAttentionCategory.pendingSensitiveApproval;

      default:
        throw const FormatException('Unknown Owner Attention source kind.');
    }
  }

  void _requireSource(String sourceType, Set<String> allowed) {
    if (!allowed.contains(sourceType)) {
      throw const FormatException('Owner Attention source type/kind mismatch.');
    }
  }

  bool get mappingOnly => true;
  bool get writesInbox => false;
  bool get consumesApproval => false;
  bool get grantsPermission => false;
  bool get executesBusinessAction => false;
}
