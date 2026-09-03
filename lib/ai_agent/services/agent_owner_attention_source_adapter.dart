import '../constants/agent_owner_attention_constants.dart';
import '../models/agent_owner_attention_event.dart';
import '../models/agent_owner_attention_safe_payload.dart';
import '../models/agent_owner_attention_source_identity.dart';
import '../models/agent_owner_attention_source_signal.dart';
import 'agent_owner_attention_source_category_mapping_policy.dart';

class AgentOwnerAttentionSourceAdapter {
  const AgentOwnerAttentionSourceAdapter({
    this.mappingPolicy = const AgentOwnerAttentionSourceCategoryMappingPolicy(),
  });

  final AgentOwnerAttentionSourceCategoryMappingPolicy mappingPolicy;

  AgentOwnerAttentionEvent adapt(AgentOwnerAttentionSourceSignal signal) {
    signal.validate();

    final mapping = mappingPolicy.map(
      sourceType: signal.sourceType,
      sourceKind: signal.sourceKind,
    );

    return AgentOwnerAttentionEvent(
      attentionId:
          'attention:${signal.sourceType.toLowerCase()}:${signal.sourceEventId}',
      category: mapping.category,
      priority: mapping.minimumPriority,
      status: AgentOwnerAttentionStatus.pendingReview,
      source: AgentOwnerAttentionSourceIdentity(
        sourceType: signal.sourceType,
        sourceEventId: signal.sourceEventId,
        sourceReferenceSha256: signal.sourceReferenceSha256,
      ),
      payload: AgentOwnerAttentionSafePayload(
        safeTitle: signal.safeTitle,
        safeSummary: signal.safeSummary,
        reasonCodes: List<String>.unmodifiable(signal.reasonCodes),
        redactionVerified: signal.redactionVerified,
        minimumNecessaryVerified: signal.minimumNecessaryVerified,
      ),
      createdAtUtc: signal.occurredAtUtc,
    );
  }

  bool get adapterOnly => true;
  bool get readsFirestore => false;
  bool get writesFirestore => false;
  bool get mutatesSource => false;
  bool get consumesApproval => false;
  bool get grantsPermission => false;
  bool get overridesRuntimeGate => false;
  bool get callsProvider => false;
  bool get executesBusinessAction => false;
}
