import '../models/agent_fraud_case.dart';
import '../models/agent_fraud_review_package.dart';

// =========================================================
// AI AGENT - FRAUD CASE SERVICE
// =========================================================
//
// Phase 32 Step 7B.
//
// PURE WORKFLOW SERVICE.
//
// It creates updated case objects.
// It does NOT persist them.
// It does NOT punish anyone.
//
// Persistence/audit integration remains behind existing
// Permission/Approval/Audit architecture.

class AgentFraudCaseService {
  const AgentFraudCaseService();

  AgentFraudCase openCase({
    required String caseId,
    required String subjectId,
    required String subjectType,
    required String module,
    required AgentFraudReviewPackage
        reviewPackage,
    required String actorRole,
    required String actorId,
    DateTime? now,
  }) {
    reviewPackage.validate();

    final DateTime timestamp =
        now ?? DateTime.now();

    final AgentFraudCaseTimelineEvent event =
        AgentFraudCaseTimelineEvent(
      eventId:
          '${caseId.trim()}_opened',
      eventType:
          'CASE_OPENED',
      actorRole:
          actorRole.trim(),
      actorId:
          actorId.trim(),
      note:
          'Fraud/risk case opened for human review. No guilt determination or enforcement was applied.',
      createdAt:
          timestamp,
    );

    final AgentFraudCase result =
        AgentFraudCase(
      caseId:
          caseId.trim(),
      subjectId:
          subjectId.trim(),
      subjectType:
          subjectType.trim(),
      module:
          module.trim(),
      reviewPackage:
          reviewPackage,
      status:
          AgentFraudCaseStatus.open,
      timeline:
          <AgentFraudCaseTimelineEvent>[
        event,
      ],
      createdAt:
          timestamp,
      updatedAt:
          timestamp,
    );

    result.validate();

    return result;
  }

  AgentFraudCase assignReviewer({
    required AgentFraudCase fraudCase,
    required String reviewerId,
    required String reviewerRole,
    required String actorRole,
    required String actorId,
    DateTime? now,
  }) {
    fraudCase.validate();

    if (fraudCase.isClosed) {
      throw const AgentFraudCaseException(
        'Closed fraud case cannot be reassigned.',
      );
    }

    final String cleanReviewerId =
        reviewerId.trim();

    final String cleanReviewerRole =
        reviewerRole.trim();

    if (cleanReviewerId.isEmpty ||
        cleanReviewerRole.isEmpty) {
      throw const AgentFraudCaseException(
        'reviewerId and reviewerRole are required.',
      );
    }

    final DateTime timestamp =
        now ?? DateTime.now();

    return _copyWithEvent(
      fraudCase,
      status:
          AgentFraudCaseStatus.underReview,
      reviewerId:
          cleanReviewerId,
      reviewerRole:
          cleanReviewerRole,
      event:
          AgentFraudCaseTimelineEvent(
        eventId:
            '${fraudCase.caseId}_${timestamp.microsecondsSinceEpoch}',
        eventType:
            'REVIEWER_ASSIGNED',
        actorRole:
            actorRole.trim(),
        actorId:
            actorId.trim(),
        note:
            'Case assigned for human review.',
        createdAt:
            timestamp,
      ),
      updatedAt:
          timestamp,
    );
  }

  AgentFraudCase openDispute({
    required AgentFraudCase fraudCase,
    required String actorRole,
    required String actorId,
    required String reason,
    DateTime? now,
  }) {
    fraudCase.validate();

    if (fraudCase.isClosed) {
      throw const AgentFraudCaseException(
        'Closed fraud case cannot open a dispute.',
      );
    }

    if (reason.trim().isEmpty) {
      throw const AgentFraudCaseException(
        'Dispute reason is required.',
      );
    }

    final DateTime timestamp =
        now ?? DateTime.now();

    return _copyWithEvent(
      fraudCase,
      status:
          AgentFraudCaseStatus.disputed,
      disputeOpen:
          true,
      appealOpen:
          false,
      event:
          AgentFraudCaseTimelineEvent(
        eventId:
            '${fraudCase.caseId}_${timestamp.microsecondsSinceEpoch}',
        eventType:
            'DISPUTE_OPENED',
        actorRole:
            actorRole.trim(),
        actorId:
            actorId.trim(),
        note:
            reason.trim(),
        createdAt:
            timestamp,
      ),
      updatedAt:
          timestamp,
    );
  }

  AgentFraudCase openAppeal({
    required AgentFraudCase fraudCase,
    required String actorRole,
    required String actorId,
    required String reason,
    DateTime? now,
  }) {
    fraudCase.validate();

    if (fraudCase.isClosed) {
      throw const AgentFraudCaseException(
        'Closed fraud case cannot open an appeal.',
      );
    }

    if (reason.trim().isEmpty) {
      throw const AgentFraudCaseException(
        'Appeal reason is required.',
      );
    }

    final DateTime timestamp =
        now ?? DateTime.now();

    return _copyWithEvent(
      fraudCase,
      status:
          AgentFraudCaseStatus.appealed,
      disputeOpen:
          false,
      appealOpen:
          true,
      event:
          AgentFraudCaseTimelineEvent(
        eventId:
            '${fraudCase.caseId}_${timestamp.microsecondsSinceEpoch}',
        eventType:
            'APPEAL_OPENED',
        actorRole:
            actorRole.trim(),
        actorId:
            actorId.trim(),
        note:
            reason.trim(),
        createdAt:
            timestamp,
      ),
      updatedAt:
          timestamp,
    );
  }

  AgentFraudCase resolveNoAction({
    required AgentFraudCase fraudCase,
    required String reviewerId,
    required String reviewerRole,
    required String reason,
    DateTime? now,
  }) {
    fraudCase.validate();

    if (reason.trim().isEmpty) {
      throw const AgentFraudCaseException(
        'Resolution reason is required.',
      );
    }

    final DateTime timestamp =
        now ?? DateTime.now();

    return _copyWithEvent(
      fraudCase,
      status:
          AgentFraudCaseStatus
              .resolvedNoAction,
      reviewerId:
          reviewerId.trim(),
      reviewerRole:
          reviewerRole.trim(),
      disputeOpen:
          false,
      appealOpen:
          false,
      resolutionNote:
          reason.trim(),
      event:
          AgentFraudCaseTimelineEvent(
        eventId:
            '${fraudCase.caseId}_${timestamp.microsecondsSinceEpoch}',
        eventType:
            'RESOLVED_NO_ACTION',
        actorRole:
            reviewerRole.trim(),
        actorId:
            reviewerId.trim(),
        note:
            reason.trim(),
        createdAt:
            timestamp,
      ),
      updatedAt:
          timestamp,
    );
  }

  AgentFraudCase recommendAction({
    required AgentFraudCase fraudCase,
    required String reviewerId,
    required String reviewerRole,
    required String recommendation,
    DateTime? now,
  }) {
    fraudCase.validate();

    if (recommendation.trim().isEmpty) {
      throw const AgentFraudCaseException(
        'Recommendation cannot be empty.',
      );
    }

    final DateTime timestamp =
        now ?? DateTime.now();

    return _copyWithEvent(
      fraudCase,
      status:
          AgentFraudCaseStatus
              .resolvedActionRecommended,
      reviewerId:
          reviewerId.trim(),
      reviewerRole:
          reviewerRole.trim(),
      disputeOpen:
          false,
      appealOpen:
          false,
      resolutionNote:
          recommendation.trim(),
      event:
          AgentFraudCaseTimelineEvent(
        eventId:
            '${fraudCase.caseId}_${timestamp.microsecondsSinceEpoch}',
        eventType:
            'ACTION_RECOMMENDED',
        actorRole:
            reviewerRole.trim(),
        actorId:
            reviewerId.trim(),
        note:
            'Recommendation only: ${recommendation.trim()}',
        createdAt:
            timestamp,
      ),
      updatedAt:
          timestamp,
    );
  }

  AgentFraudCase _copyWithEvent(
    AgentFraudCase source, {
    required String status,
    String? reviewerId,
    String? reviewerRole,
    bool? disputeOpen,
    bool? appealOpen,
    String? resolutionNote,
    required AgentFraudCaseTimelineEvent event,
    required DateTime updatedAt,
  }) {
    final AgentFraudCase result =
        AgentFraudCase(
      caseId:
          source.caseId,
      subjectId:
          source.subjectId,
      subjectType:
          source.subjectType,
      module:
          source.module,
      reviewPackage:
          source.reviewPackage,
      status:
          status,
      reviewerId:
          reviewerId ??
          source.reviewerId,
      reviewerRole:
          reviewerRole ??
          source.reviewerRole,
      disputeOpen:
          disputeOpen ??
          source.disputeOpen,
      appealOpen:
          appealOpen ??
          source.appealOpen,
      resolutionNote:
          resolutionNote ??
          source.resolutionNote,
      timeline:
          <AgentFraudCaseTimelineEvent>[
        ...source.timeline,
        event,
      ],
      createdAt:
          source.createdAt,
      updatedAt:
          updatedAt,
    );

    result.validate();

    return result;
  }
}