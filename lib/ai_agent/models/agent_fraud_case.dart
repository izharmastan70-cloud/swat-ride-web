import 'agent_fraud_review_package.dart';

// =========================================================
// AI AGENT - FRAUD CASE
// =========================================================
//
// Phase 32 Step 7B.
//
// A Fraud Case is a HUMAN-REVIEW workflow container.
//
// IMPORTANT:
//
// Case opened != fraud proven.
//
// This model stores:
// - review package
// - reviewer state
// - dispute/appeal state
// - timeline metadata
//
// It has NO enforcement authority.

class AgentFraudCaseStatus {
  AgentFraudCaseStatus._();

  static const String open = 'OPEN';
  static const String underReview =
      'UNDER_REVIEW';
  static const String awaitingEvidence =
      'AWAITING_EVIDENCE';
  static const String disputed =
      'DISPUTED';
  static const String appealed =
      'APPEALED';
  static const String resolvedNoAction =
      'RESOLVED_NO_ACTION';
  static const String resolvedActionRecommended =
      'RESOLVED_ACTION_RECOMMENDED';
  static const String closed = 'CLOSED';

  static const Set<String> values =
      <String>{
    open,
    underReview,
    awaitingEvidence,
    disputed,
    appealed,
    resolvedNoAction,
    resolvedActionRecommended,
    closed,
  };

  static bool isValid(String value) =>
      values.contains(value);
}

class AgentFraudCaseTimelineEvent {
  final String eventId;
  final String eventType;
  final String actorRole;
  final String actorId;
  final String note;
  final DateTime createdAt;

  const AgentFraudCaseTimelineEvent({
    required this.eventId,
    required this.eventType,
    required this.actorRole,
    required this.actorId,
    required this.note,
    required this.createdAt,
  });

  void validate() {
    if (eventId.trim().isEmpty ||
        eventType.trim().isEmpty ||
        actorRole.trim().isEmpty ||
        note.trim().isEmpty) {
      throw const AgentFraudCaseException(
        'Fraud case timeline event fields cannot be empty.',
      );
    }
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'eventId': eventId,
      'eventType': eventType,
      'actorRole': actorRole,
      'actorId': actorId,
      'note': note,
      'createdAt':
          createdAt.toIso8601String(),
    };
  }
}

class AgentFraudCase {
  final String caseId;

  final String subjectId;
  final String subjectType;
  final String module;

  final AgentFraudReviewPackage
      reviewPackage;

  final String status;

  final String reviewerId;
  final String reviewerRole;

  final bool disputeOpen;
  final bool appealOpen;

  final String resolutionNote;

  final List<AgentFraudCaseTimelineEvent>
      timeline;

  final DateTime createdAt;
  final DateTime updatedAt;

  const AgentFraudCase({
    required this.caseId,
    required this.subjectId,
    required this.subjectType,
    required this.module,
    required this.reviewPackage,
    required this.status,
    this.reviewerId = '',
    this.reviewerRole = '',
    this.disputeOpen = false,
    this.appealOpen = false,
    this.resolutionNote = '',
    this.timeline =
        const <AgentFraudCaseTimelineEvent>[],
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isClosed =>
      status == AgentFraudCaseStatus.closed;

  bool get requiresHumanReview =>
      reviewPackage.requiresAdminReview ||
      reviewPackage
          .requiresSuperAdminReview ||
      disputeOpen ||
      appealOpen;

  void validate() {
    if (caseId.trim().isEmpty) {
      throw const AgentFraudCaseException(
        'caseId cannot be empty.',
      );
    }

    if (subjectId.trim().isEmpty ||
        subjectType.trim().isEmpty ||
        module.trim().isEmpty) {
      throw const AgentFraudCaseException(
        'Fraud case subject/module cannot be empty.',
      );
    }

    reviewPackage.validate();

    if (!AgentFraudCaseStatus.isValid(
      status,
    )) {
      throw AgentFraudCaseException(
        'Invalid fraud case status "$status".',
      );
    }

    if (disputeOpen &&
        status !=
            AgentFraudCaseStatus.disputed) {
      throw const AgentFraudCaseException(
        'Open dispute requires DISPUTED status.',
      );
    }

    if (appealOpen &&
        status !=
            AgentFraudCaseStatus.appealed) {
      throw const AgentFraudCaseException(
        'Open appeal requires APPEALED status.',
      );
    }

    if (status ==
            AgentFraudCaseStatus
                .resolvedActionRecommended &&
        resolutionNote.trim().isEmpty) {
      throw const AgentFraudCaseException(
        'Recommended action resolution requires a note.',
      );
    }

    for (final AgentFraudCaseTimelineEvent
        event in timeline) {
      event.validate();
    }
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'caseId': caseId,
      'subjectId': subjectId,
      'subjectType': subjectType,
      'module': module,
      'reviewPackage':
          reviewPackage.toMap(),
      'status': status,
      'reviewerId': reviewerId,
      'reviewerRole': reviewerRole,
      'disputeOpen': disputeOpen,
      'appealOpen': appealOpen,
      'resolutionNote':
          resolutionNote,
      'timeline':
          timeline
              .map(
                (
                  AgentFraudCaseTimelineEvent
                      event,
                ) =>
                    event.toMap(),
              )
              .toList(growable: false),
      'createdAt':
          createdAt.toIso8601String(),
      'updatedAt':
          updatedAt.toIso8601String(),
    };
  }
}

class AgentFraudCaseException
    implements Exception {
  final String message;

  const AgentFraudCaseException(
    this.message,
  );

  @override
  String toString() =>
      'AgentFraudCaseException: $message';
}