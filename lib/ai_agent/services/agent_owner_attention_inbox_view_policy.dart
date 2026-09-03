import '../constants/agent_owner_attention_constants.dart';
import '../models/agent_owner_attention_inbox_badges.dart';
import '../models/agent_owner_attention_inbox_record.dart';

class AgentOwnerAttentionInboxViewPolicy {
  const AgentOwnerAttentionInboxViewPolicy();

  List<AgentOwnerAttentionInboxRecord> filter({
    required Iterable<AgentOwnerAttentionInboxRecord> records,
    String? category,
    String? priority,
    String? status,
  }) {
    return records
        .where((record) {
          final categoryOk =
              category == null || record.event.category == category;

          final priorityOk =
              priority == null || record.event.priority == priority;

          final statusOk = status == null || record.event.status == status;

          return categoryOk && priorityOk && statusOk;
        })
        .toList(growable: false);
  }

  AgentOwnerAttentionInboxBadges buildBadges(
    Iterable<AgentOwnerAttentionInboxRecord> records,
  ) {
    var pending = 0;
    var urgent = 0;
    var inReview = 0;
    var open = 0;

    for (final record in records) {
      final status = record.event.status;
      final priority = record.event.priority;

      if (status == AgentOwnerAttentionStatus.pendingReview) {
        pending++;
      }

      if (status == AgentOwnerAttentionStatus.inReview) {
        inReview++;
      }

      if (status != AgentOwnerAttentionStatus.resolved &&
          status != AgentOwnerAttentionStatus.dismissed) {
        open++;

        if (priority == AgentOwnerAttentionPriority.critical ||
            priority == AgentOwnerAttentionPriority.emergency) {
          urgent++;
        }
      }
    }

    final badges = AgentOwnerAttentionInboxBadges(
      pendingReview: pending,
      criticalOrEmergency: urgent,
      inReview: inReview,
      totalOpen: open,
    );

    badges.validate();
    return badges;
  }

  List<String> allowedNextStatuses(AgentOwnerAttentionInboxRecord record) {
    switch (record.event.status) {
      case AgentOwnerAttentionStatus.pendingReview:
        return const <String>[AgentOwnerAttentionStatus.acknowledged];

      case AgentOwnerAttentionStatus.acknowledged:
        return const <String>[
          AgentOwnerAttentionStatus.inReview,
          AgentOwnerAttentionStatus.dismissed,
        ];

      case AgentOwnerAttentionStatus.inReview:
        return const <String>[
          AgentOwnerAttentionStatus.resolved,
          AgentOwnerAttentionStatus.dismissed,
        ];

      case AgentOwnerAttentionStatus.resolved:
      case AgentOwnerAttentionStatus.dismissed:
        return const <String>[];

      default:
        return const <String>[];
    }
  }

  bool get viewCoordinationOnly => true;
  bool get sourceActionExecutionAllowed => false;
  bool get approvalConsumptionAllowed => false;
  bool get permissionGrantAllowed => false;
  bool get providerExecutionAllowed => false;
  bool get businessWriteAllowed => false;
}
