import '../constants/agent_owner_attention_constants.dart';
import 'agent_owner_attention_safe_payload.dart';
import 'agent_owner_attention_source_identity.dart';

class AgentOwnerAttentionEvent {
  AgentOwnerAttentionEvent({
    required this.attentionId,
    required this.category,
    required this.priority,
    required this.status,
    required this.source,
    required this.payload,
    required this.createdAtUtc,
  }) {
    validate();
  }

  final String attentionId;
  final String category;
  final String priority;
  final String status;

  final AgentOwnerAttentionSourceIdentity source;
  final AgentOwnerAttentionSafePayload payload;

  final DateTime createdAtUtc;

  bool get requiresHumanReview => true;
  bool get unifiedPhase64Contract => true;

  bool get mayExecuteBusinessAction => false;
  bool get mayConsumeApproval => false;
  bool get mayGrantPermission => false;
  bool get mayOverrideRuntimeGate => false;
  bool get mayCallProvider => false;
  bool get maySendMessage => false;
  bool get mayTransferMoney => false;
  bool get mayResolveSourceRecord => false;
  bool get mayDeleteSourceRecord => false;

  void validate() {
    final safeIdPattern = RegExp(r'^[A-Za-z0-9_.:-]+$');

    final validAttentionId =
        attentionId.isNotEmpty &&
        attentionId == attentionId.trim() &&
        attentionId.length <= AgentOwnerAttentionLimits.opaqueIdMaxLength &&
        safeIdPattern.hasMatch(attentionId);

    source.validate();
    payload.validate();

    if (!validAttentionId ||
        !AgentOwnerAttentionCategory.values.contains(category) ||
        !AgentOwnerAttentionPriority.values.contains(priority) ||
        !AgentOwnerAttentionStatus.values.contains(status) ||
        !createdAtUtc.isUtc) {
      throw const FormatException('Invalid unified Owner Attention event.');
    }
  }

  Map<String, Object?> toSafeMetadata() {
    validate();

    return <String, Object?>{
      'attentionId': attentionId,
      'category': category,
      'priority': priority,
      'status': status,
      'sourceType': source.sourceType,
      'sourceEventId': source.sourceEventId,
      'sourceReferenceSha256': source.sourceReferenceSha256,
      'sourceDedupeKey': source.dedupeKey,
      'payload': payload.toSafeMetadata(),
      'requiresHumanReview': true,
      'unifiedPhase64Contract': true,
      'mayExecuteBusinessAction': false,
      'mayConsumeApproval': false,
      'mayGrantPermission': false,
      'mayOverrideRuntimeGate': false,
      'createdAtUtc': createdAtUtc.toIso8601String(),
    };
  }
}
