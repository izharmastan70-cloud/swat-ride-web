import '../constants/agent_owner_attention_constants.dart';
import '../models/agent_owner_attention_event.dart';
import 'agent_owner_attention_priority_policy.dart';

class AgentOwnerAttentionContractService {
  const AgentOwnerAttentionContractService({
    this.priorityPolicy = const AgentOwnerAttentionPriorityPolicy(),
  });

  final AgentOwnerAttentionPriorityPolicy priorityPolicy;

  bool validateForCentralInbox(
    AgentOwnerAttentionEvent event, {
    required DateTime evaluatedAtUtc,
  }) {
    try {
      event.validate();
    } catch (_) {
      return false;
    }

    if (!evaluatedAtUtc.isUtc) {
      return false;
    }

    if (event.createdAtUtc.isAfter(
      evaluatedAtUtc.add(AgentOwnerAttentionLimits.maximumFutureClockSkew),
    )) {
      return false;
    }

    if (!event.requiresHumanReview ||
        !event.unifiedPhase64Contract ||
        !priorityPolicy.isPriorityAllowed(
          category: event.category,
          priority: event.priority,
        )) {
      return false;
    }

    return true;
  }

  bool hasDuplicateSourceIdentity(
    Iterable<AgentOwnerAttentionEvent> existing,
    AgentOwnerAttentionEvent candidate,
  ) {
    final key = candidate.source.dedupeKey;

    return existing.any((event) => event.source.dedupeKey == key);
  }

  bool canAcceptCandidate({
    required Iterable<AgentOwnerAttentionEvent> existing,
    required AgentOwnerAttentionEvent candidate,
    required DateTime evaluatedAtUtc,
  }) {
    return validateForCentralInbox(candidate, evaluatedAtUtc: evaluatedAtUtc) &&
        !hasDuplicateSourceIdentity(existing, candidate);
  }

  bool get contractValidationOnly => true;
  bool get writesInbox => false;
  bool get readsFirestore => false;
  bool get writesFirestore => false;
  bool get consumesApproval => false;
  bool get grantsPermission => false;
  bool get overridesRuntimeGate => false;
  bool get callsProvider => false;
  bool get executesBusinessAction => false;
  bool get mutatesSourceRecord => false;
  bool get deletesSourceRecord => false;
}
