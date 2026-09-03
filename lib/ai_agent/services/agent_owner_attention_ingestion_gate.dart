import '../constants/agent_owner_attention_source_signal_constants.dart';
import '../models/agent_owner_attention_event.dart';
import 'agent_owner_attention_contract_service.dart';

class AgentOwnerAttentionIngestionResult {
  const AgentOwnerAttentionIngestionResult({
    required this.status,
    required this.event,
    required this.reasonCode,
  });

  final String status;
  final AgentOwnerAttentionEvent? event;
  final String reasonCode;

  bool get accepted => status == AgentOwnerAttentionIngestionStatus.accepted;

  bool get persisted => false;
  bool get sourceMutated => false;
  bool get approvalConsumed => false;
  bool get businessActionExecuted => false;
}

class AgentOwnerAttentionIngestionGate {
  const AgentOwnerAttentionIngestionGate({
    this.contractService = const AgentOwnerAttentionContractService(),
  });

  final AgentOwnerAttentionContractService contractService;

  AgentOwnerAttentionIngestionResult evaluate({
    required Iterable<AgentOwnerAttentionEvent> existing,
    required AgentOwnerAttentionEvent candidate,
    required DateTime evaluatedAtUtc,
  }) {
    if (!contractService.validateForCentralInbox(
      candidate,
      evaluatedAtUtc: evaluatedAtUtc,
    )) {
      return const AgentOwnerAttentionIngestionResult(
        status: AgentOwnerAttentionIngestionStatus.blockedInvalid,
        event: null,
        reasonCode: 'unified_contract_validation_failed',
      );
    }

    if (contractService.hasDuplicateSourceIdentity(existing, candidate)) {
      return const AgentOwnerAttentionIngestionResult(
        status: AgentOwnerAttentionIngestionStatus.blockedDuplicate,
        event: null,
        reasonCode: 'duplicate_source_identity',
      );
    }

    return AgentOwnerAttentionIngestionResult(
      status: AgentOwnerAttentionIngestionStatus.accepted,
      event: candidate,
      reasonCode: 'accepted_for_later_repository_persistence',
    );
  }

  bool get gateOnly => true;
  bool get persistsInbox => false;
  bool get readsFirestore => false;
  bool get writesFirestore => false;
  bool get consumesApproval => false;
  bool get grantsPermission => false;
  bool get overridesRuntimeGate => false;
  bool get callsProvider => false;
  bool get mutatesSource => false;
  bool get executesBusinessAction => false;
}
