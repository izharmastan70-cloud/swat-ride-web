import '../constants/agent_owner_attention_constants.dart';
import '../constants/agent_owner_attention_review_constants.dart';
import 'agent_owner_attention_event.dart';
import 'agent_owner_attention_safe_payload.dart';
import 'agent_owner_attention_source_identity.dart';

class AgentOwnerAttentionInboxRecord {
  AgentOwnerAttentionInboxRecord({
    required this.event,
    required this.reviewVersion,
    required this.reviewedByRole,
    required this.reviewerRef,
    required this.reviewUpdatedAtUtc,
  }) {
    validate();
  }

  factory AgentOwnerAttentionInboxRecord.initial(
    AgentOwnerAttentionEvent event,
  ) {
    if (event.status != AgentOwnerAttentionStatus.pendingReview) {
      throw const FormatException(
        'Initial Owner Attention ingestion must be PENDING_REVIEW.',
      );
    }

    return AgentOwnerAttentionInboxRecord(
      event: event,
      reviewVersion: 0,
      reviewedByRole: null,
      reviewerRef: null,
      reviewUpdatedAtUtc: null,
    );
  }

  factory AgentOwnerAttentionInboxRecord.fromMap(Map<String, dynamic> map) {
    final payloadMap = Map<String, dynamic>.from(map['payload'] as Map);

    final event = AgentOwnerAttentionEvent(
      attentionId: (map['attentionId'] ?? '').toString(),
      category: (map['category'] ?? '').toString(),
      priority: (map['priority'] ?? '').toString(),
      status: (map['status'] ?? '').toString(),
      source: AgentOwnerAttentionSourceIdentity(
        sourceType: (map['sourceType'] ?? '').toString(),
        sourceEventId: (map['sourceEventId'] ?? '').toString(),
        sourceReferenceSha256: (map['sourceReferenceSha256'] ?? '').toString(),
      ),
      payload: AgentOwnerAttentionSafePayload(
        safeTitle: (payloadMap['safeTitle'] ?? '').toString(),
        safeSummary: (payloadMap['safeSummary'] ?? '').toString(),
        reasonCodes:
            (payloadMap['reasonCodes'] as List<dynamic>? ?? const <dynamic>[])
                .map((value) => value.toString())
                .toList(growable: false),
        redactionVerified: payloadMap['redactionVerified'] == true,
        minimumNecessaryVerified:
            payloadMap['minimumNecessaryVerified'] == true,
      ),
      createdAtUtc: DateTime.parse(
        (map['createdAtUtc'] ?? '').toString(),
      ).toUtc(),
    );

    final reviewUpdatedRaw = map['reviewUpdatedAtUtc'];

    return AgentOwnerAttentionInboxRecord(
      event: event,
      reviewVersion: (map['reviewVersion'] as num?)?.toInt() ?? 0,
      reviewedByRole: map['reviewedByRole']?.toString(),
      reviewerRef: map['reviewerRef']?.toString(),
      reviewUpdatedAtUtc: reviewUpdatedRaw == null
          ? null
          : DateTime.parse(reviewUpdatedRaw.toString()).toUtc(),
    );
  }

  final AgentOwnerAttentionEvent event;
  final int reviewVersion;
  final String? reviewedByRole;
  final String? reviewerRef;
  final DateTime? reviewUpdatedAtUtc;

  bool get immutableSourcePayload => true;
  bool get sourceRecordMutated => false;
  bool get approvalConsumed => false;
  bool get businessActionExecuted => false;

  void validate() {
    event.validate();

    if (reviewVersion < 0) {
      throw const FormatException(
        'Owner Attention reviewVersion cannot be negative.',
      );
    }

    if (reviewVersion == 0) {
      if (event.status != AgentOwnerAttentionStatus.pendingReview ||
          reviewedByRole != null ||
          reviewerRef != null ||
          reviewUpdatedAtUtc != null) {
        throw const FormatException(
          'Initial Owner Attention review metadata is invalid.',
        );
      }
      return;
    }

    final role = reviewedByRole?.trim() ?? '';
    final reviewer = reviewerRef?.trim() ?? '';

    if (!AgentOwnerAttentionReviewRole.values.contains(role) ||
        reviewer.isEmpty ||
        reviewer.length >
            AgentOwnerAttentionRepositoryLimits.reviewerRefMaxLength ||
        reviewUpdatedAtUtc == null ||
        !reviewUpdatedAtUtc!.isUtc) {
      throw const FormatException(
        'Reviewed Owner Attention metadata is invalid.',
      );
    }
  }

  Map<String, dynamic> toMap() {
    validate();

    return <String, dynamic>{
      ...event.toSafeMetadata(),
      'reviewVersion': reviewVersion,
      'reviewedByRole': reviewedByRole,
      'reviewerRef': reviewerRef,
      'reviewUpdatedAtUtc': reviewUpdatedAtUtc?.toIso8601String(),
      'immutableSourcePayload': true,
      'sourceRecordMutated': false,
      'approvalConsumed': false,
      'permissionGranted': false,
      'runtimeGateOverridden': false,
      'providerCalled': false,
      'businessActionExecuted': false,
    };
  }
}
