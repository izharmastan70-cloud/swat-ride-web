import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/feedback_model.dart';
import '../models/feedback_reply_model.dart';
import '../models/feedback_summary_model.dart';
import 'feedback_admin_service.dart';
import 'feedback_service.dart';

class FeedbackReplyService {
  static const String reportsCollectionName = 'feedback_reports';
  static const String auditCollectionName = 'feedback_reply_audit_logs';

  final FirebaseFirestore _firestore;
  final FeedbackService _feedbackService;

  FeedbackReplyService({
    FirebaseFirestore? firestore,
    FeedbackService? feedbackService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _feedbackService =
           feedbackService ??
           FeedbackService(firestore: firestore ?? FirebaseFirestore.instance);

  CollectionReference<Map<String, dynamic>> get _reviews =>
      _firestore.collection(FeedbackService.reviewsCollectionName);

  CollectionReference<Map<String, dynamic>> get _replies =>
      _firestore.collection(FeedbackAdminService.repliesCollectionName);

  CollectionReference<Map<String, dynamic>> get _summaries =>
      _firestore.collection(FeedbackService.summariesCollectionName);

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection(reportsCollectionName);

  CollectionReference<Map<String, dynamic>> get _auditLogs =>
      _firestore.collection(auditCollectionName);

  Future<String> createReply({
    required String feedbackId,
    required String authorId,
    required String authorName,
    required FeedbackReplyAuthorType authorType,
    required FeedbackReplyType replyType,
    required String message,
    String authorPhotoUrl = '',
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) async {
    final cleanFeedbackId = feedbackId.trim();
    final cleanAuthorId = authorId.trim();
    final cleanMessage = message.trim();

    if (cleanFeedbackId.isEmpty ||
        cleanAuthorId.isEmpty ||
        cleanMessage.isEmpty) {
      throw const FeedbackOperationException(
        'invalid-reply',
        'Review ID, reply author and message are required.',
      );
    }

    if (cleanMessage.length > FeedbackReplyModel.maximumMessageLength) {
      throw const FeedbackOperationException(
        'reply-too-long',
        'Reply cannot exceed 1500 characters.',
      );
    }

    if (authorType == FeedbackReplyAuthorType.system) {
      throw const FeedbackOperationException(
        'invalid-author',
        'A system reply cannot be submitted from the partner interface.',
      );
    }

    if (replyType == FeedbackReplyType.privateSupport &&
        !authorType.isAdminOrSupport) {
      throw const FeedbackOperationException(
        'private-reply-restricted',
        'Only SWAT RIDE admin or support can send a private support reply.',
      );
    }

    final settings = await _feedbackService.getSettings();

    if (!settings.feedbackEnabled || !settings.partnerRepliesEnabled) {
      throw const FeedbackOperationException(
        'partner-replies-disabled',
        'Partner replies are currently disabled by admin.',
      );
    }

    final reviewReference = _reviews.doc(cleanFeedbackId);
    final replyReference = _replies.doc(
      _buildReplyDocumentId(
        feedbackId: cleanFeedbackId,
        authorId: cleanAuthorId,
      ),
    );

    final now = DateTime.now();

    await _firestore.runTransaction((transaction) async {
      final reviewSnapshot = await transaction.get(reviewReference);
      final reviewData = reviewSnapshot.data();

      if (!reviewSnapshot.exists || reviewData == null) {
        throw const FeedbackOperationException(
          'review-not-found',
          'The review was not found.',
        );
      }

      final review = FeedbackModel.fromMap(
        reviewData,
        documentId: reviewSnapshot.id,
      ).normalized();

      if (review.isDeleted) {
        throw const FeedbackOperationException(
          'review-removed',
          'A removed review cannot receive a reply.',
        );
      }

      if (review.targetId != cleanAuthorId && !authorType.isAdminOrSupport) {
        throw const FeedbackOperationException(
          'permission-denied',
          'Only the reviewed partner can reply to this review.',
        );
      }

      if (!_authorMatchesTarget(
        authorType: authorType,
        targetType: review.targetType,
      )) {
        throw const FeedbackOperationException(
          'author-type-mismatch',
          'This partner role does not match the reviewed service role.',
        );
      }

      final existingReplySnapshot = await transaction.get(replyReference);
      final existingData = existingReplySnapshot.data();

      if (existingReplySnapshot.exists && existingData != null) {
        final existing = FeedbackReplyModel.fromMap(
          existingData,
          documentId: existingReplySnapshot.id,
        );

        if (!existing.isDeleted) {
          throw const FeedbackOperationException(
            'duplicate-reply',
            'You have already replied to this review.',
          );
        }
      }

      final status = settings.requireModeration
          ? FeedbackReplyStatus.pendingModeration
          : FeedbackReplyStatus.published;

      final reply = FeedbackReplyModel(
        id: replyReference.id,
        feedbackId: review.id,
        serviceType: review.serviceType,
        sourceId: review.sourceId,
        targetId: review.targetId,
        authorId: cleanAuthorId,
        authorName: authorName.trim(),
        authorPhotoUrl: authorPhotoUrl.trim(),
        authorType: authorType,
        replyType: replyType,
        message: cleanMessage,
        status: status,
        createdAt: now,
        metadata: Map<String, dynamic>.from(metadata),
      ).normalized();

      transaction.set(replyReference, reply.toMap());

      if (!review.hasPartnerReply) {
        final updatedReview = review.copyWith(
          hasPartnerReply: true,
          updatedAt: now,
        );

        transaction.set(reviewReference, updatedReview.toMap());

        final summaryReference = _summaries.doc(
          FeedbackSummaryModel.buildSummaryId(
            serviceType: review.serviceType,
            targetType: review.targetType,
            targetId: review.targetId,
          ),
        );

        final summarySnapshot = await transaction.get(summaryReference);
        final summaryData = summarySnapshot.data();

        if (summarySnapshot.exists && summaryData != null) {
          final summary = FeedbackSummaryModel.fromMap(
            summaryData,
            documentId: summarySnapshot.id,
          ).normalized();

          final nextReplyCount =
              summary.repliedReviewCount < summary.totalReviews
              ? summary.repliedReviewCount + 1
              : summary.repliedReviewCount;

          transaction.set(
            summaryReference,
            summary
                .copyWith(repliedReviewCount: nextReplyCount, updatedAt: now)
                .toMap(),
          );
        }
      }

      final auditReference = _auditLogs.doc();

      transaction.set(auditReference, <String, dynamic>{
        'id': auditReference.id,
        'entityType': 'reply',
        'entityId': replyReference.id,
        'feedbackId': review.id,
        'serviceType': review.serviceType.value,
        'targetId': review.targetId,
        'action': 'reply_created',
        'actorId': cleanAuthorId,
        'actorType': authorType.value,
        'replyType': replyType.value,
        'status': status.value,
        'createdAt': Timestamp.fromDate(now),
      });
    });

    return replyReference.id;
  }

  Future<FeedbackReplyModel?> getReplyById(String replyId) async {
    final cleanReplyId = replyId.trim();

    if (cleanReplyId.isEmpty) {
      return null;
    }

    final snapshot = await _replies.doc(cleanReplyId).get();
    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      return null;
    }

    return FeedbackReplyModel.fromMap(data, documentId: snapshot.id);
  }

  Stream<FeedbackReplyModel?> watchReplyById(String replyId) {
    final cleanReplyId = replyId.trim();

    if (cleanReplyId.isEmpty) {
      return Stream<FeedbackReplyModel?>.value(null);
    }

    return _replies.doc(cleanReplyId).snapshots().map((snapshot) {
      final data = snapshot.data();

      if (!snapshot.exists || data == null) {
        return null;
      }

      return FeedbackReplyModel.fromMap(data, documentId: snapshot.id);
    });
  }

  Stream<List<FeedbackReplyModel>> watchRepliesForReview({
    required String feedbackId,
    bool includePrivateSupport = false,
    bool includeModerated = false,
    int limit = 50,
  }) {
    final cleanFeedbackId = feedbackId.trim();

    if (cleanFeedbackId.isEmpty) {
      return Stream<List<FeedbackReplyModel>>.value(
        const <FeedbackReplyModel>[],
      );
    }

    Query<Map<String, dynamic>> query = _replies.where(
      'feedbackId',
      isEqualTo: cleanFeedbackId,
    );

    if (!includePrivateSupport) {
      query = query.where(
        'replyType',
        isEqualTo: FeedbackReplyType.public.value,
      );
    }

    if (!includeModerated) {
      query = query.where(
        'status',
        isEqualTo: FeedbackReplyStatus.published.value,
      );
    }

    return query
        .orderBy('createdAt')
        .limit(_safeLimit(limit))
        .snapshots()
        .map(_replyListFromSnapshot);
  }

  Stream<List<FeedbackReplyModel>> watchRepliesByAuthor({
    required String authorId,
    FeedbackServiceType? serviceType,
    bool includeRemoved = false,
    int limit = 100,
  }) {
    final cleanAuthorId = authorId.trim();

    if (cleanAuthorId.isEmpty) {
      return Stream<List<FeedbackReplyModel>>.value(
        const <FeedbackReplyModel>[],
      );
    }

    Query<Map<String, dynamic>> query = _replies.where(
      'authorId',
      isEqualTo: cleanAuthorId,
    );

    if (serviceType != null) {
      query = query.where('serviceType', isEqualTo: serviceType.value);
    }

    return query
        .orderBy('createdAt', descending: true)
        .limit(_safeLimit(limit))
        .snapshots()
        .map((snapshot) {
          final replies = snapshot.docs
              .map(
                (document) => FeedbackReplyModel.fromMap(
                  document.data(),
                  documentId: document.id,
                ),
              )
              .where((reply) => includeRemoved || !reply.isDeleted)
              .toList(growable: false);

          return replies;
        });
  }

  Future<void> editReply({
    required String replyId,
    required String authorId,
    required String message,
  }) async {
    final cleanReplyId = replyId.trim();
    final cleanAuthorId = authorId.trim();
    final cleanMessage = message.trim();

    if (cleanReplyId.isEmpty || cleanAuthorId.isEmpty || cleanMessage.isEmpty) {
      throw const FeedbackOperationException(
        'invalid-reply-edit',
        'Reply ID, author ID and message are required.',
      );
    }

    if (cleanMessage.length > FeedbackReplyModel.maximumMessageLength) {
      throw const FeedbackOperationException(
        'reply-too-long',
        'Reply cannot exceed 1500 characters.',
      );
    }

    final settings = await _feedbackService.getSettings();

    if (!settings.feedbackEnabled || !settings.partnerRepliesEnabled) {
      throw const FeedbackOperationException(
        'partner-replies-disabled',
        'Partner replies are currently disabled by admin.',
      );
    }

    final reference = _replies.doc(cleanReplyId);
    final now = DateTime.now();

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      final data = snapshot.data();

      if (!snapshot.exists || data == null) {
        throw const FeedbackOperationException(
          'reply-not-found',
          'The feedback reply was not found.',
        );
      }

      final current = FeedbackReplyModel.fromMap(
        data,
        documentId: snapshot.id,
      ).normalized();

      if (current.authorId != cleanAuthorId) {
        throw const FeedbackOperationException(
          'permission-denied',
          'Only the reply author can edit this response.',
        );
      }

      if (current.isDeleted) {
        throw const FeedbackOperationException(
          'reply-removed',
          'A removed reply cannot be edited.',
        );
      }

      final updated = current
          .copyWith(
            message: cleanMessage,
            status: settings.requireModeration
                ? FeedbackReplyStatus.pendingModeration
                : FeedbackReplyStatus.published,
            updatedAt: now,
          )
          .normalized();

      transaction.set(reference, updated.toMap());

      final auditReference = _auditLogs.doc();

      transaction.set(auditReference, <String, dynamic>{
        'id': auditReference.id,
        'entityType': 'reply',
        'entityId': current.id,
        'feedbackId': current.feedbackId,
        'action': 'reply_edited',
        'actorId': cleanAuthorId,
        'status': updated.status.value,
        'createdAt': Timestamp.fromDate(now),
      });
    });
  }

  Future<void> deleteReply({
    required String replyId,
    required String authorId,
    required String reason,
  }) async {
    final cleanReplyId = replyId.trim();
    final cleanAuthorId = authorId.trim();
    final cleanReason = reason.trim();

    if (cleanReplyId.isEmpty || cleanAuthorId.isEmpty || cleanReason.isEmpty) {
      throw const FeedbackOperationException(
        'invalid-reply-delete',
        'Reply ID, author ID and deletion reason are required.',
      );
    }

    final replySnapshot = await _replies.doc(cleanReplyId).get();
    final replyData = replySnapshot.data();

    if (!replySnapshot.exists || replyData == null) {
      throw const FeedbackOperationException(
        'reply-not-found',
        'The feedback reply was not found.',
      );
    }

    final replyBeforeDelete = FeedbackReplyModel.fromMap(
      replyData,
      documentId: replySnapshot.id,
    );

    final otherReplySnapshot = await _replies
        .where('feedbackId', isEqualTo: replyBeforeDelete.feedbackId)
        .limit(10)
        .get();

    final otherActiveReplies = otherReplySnapshot.docs
        .map(
          (document) => FeedbackReplyModel.fromMap(
            document.data(),
            documentId: document.id,
          ),
        )
        .where((reply) => reply.id != cleanReplyId && !reply.isDeleted)
        .toList(growable: false);

    final reference = _replies.doc(cleanReplyId);
    final reviewReference = _reviews.doc(replyBeforeDelete.feedbackId);
    final now = DateTime.now();

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      final data = snapshot.data();

      if (!snapshot.exists || data == null) {
        throw const FeedbackOperationException(
          'reply-not-found',
          'The feedback reply was not found.',
        );
      }

      final current = FeedbackReplyModel.fromMap(
        data,
        documentId: snapshot.id,
      ).normalized();

      if (current.authorId != cleanAuthorId) {
        throw const FeedbackOperationException(
          'permission-denied',
          'Only the reply author can delete this response.',
        );
      }

      if (current.isDeleted) {
        return;
      }

      final deleted = current
          .copyWith(
            status: FeedbackReplyStatus.removed,
            deletedAt: now,
            deletedBy: cleanAuthorId,
            deletionReason: cleanReason,
            updatedAt: now,
          )
          .normalized();

      transaction.set(reference, deleted.toMap());

      if (otherActiveReplies.isEmpty) {
        final reviewSnapshot = await transaction.get(reviewReference);
        final reviewData = reviewSnapshot.data();

        if (reviewSnapshot.exists && reviewData != null) {
          final review = FeedbackModel.fromMap(
            reviewData,
            documentId: reviewSnapshot.id,
          ).normalized();

          if (review.hasPartnerReply) {
            transaction.set(
              reviewReference,
              review.copyWith(hasPartnerReply: false, updatedAt: now).toMap(),
            );

            final summaryReference = _summaries.doc(
              FeedbackSummaryModel.buildSummaryId(
                serviceType: review.serviceType,
                targetType: review.targetType,
                targetId: review.targetId,
              ),
            );

            final summarySnapshot = await transaction.get(summaryReference);
            final summaryData = summarySnapshot.data();

            if (summarySnapshot.exists && summaryData != null) {
              final summary = FeedbackSummaryModel.fromMap(
                summaryData,
                documentId: summarySnapshot.id,
              ).normalized();

              final nextReplyCount = summary.repliedReviewCount > 0
                  ? summary.repliedReviewCount - 1
                  : 0;

              transaction.set(
                summaryReference,
                summary
                    .copyWith(
                      repliedReviewCount: nextReplyCount,
                      updatedAt: now,
                    )
                    .toMap(),
              );
            }
          }
        }
      }

      final auditReference = _auditLogs.doc();

      transaction.set(auditReference, <String, dynamic>{
        'id': auditReference.id,
        'entityType': 'reply',
        'entityId': current.id,
        'feedbackId': current.feedbackId,
        'action': 'reply_deleted',
        'actorId': cleanAuthorId,
        'reason': cleanReason,
        'createdAt': Timestamp.fromDate(now),
      });
    });
  }

  Future<String> reportReply({
    required String replyId,
    required String reporterId,
    required String category,
    required String reason,
  }) async {
    final cleanReplyId = replyId.trim();
    final cleanReporterId = reporterId.trim();
    final cleanCategory = category.trim();
    final cleanReason = reason.trim();

    if (cleanReplyId.isEmpty ||
        cleanReporterId.isEmpty ||
        cleanCategory.isEmpty ||
        cleanReason.isEmpty) {
      throw const FeedbackOperationException(
        'invalid-report',
        'Reply, reporter, category and reason are required.',
      );
    }

    final replyReference = _replies.doc(cleanReplyId);
    final reportReference = _reports.doc();
    final now = DateTime.now();

    await _firestore.runTransaction((transaction) async {
      final replySnapshot = await transaction.get(replyReference);
      final data = replySnapshot.data();

      if (!replySnapshot.exists || data == null) {
        throw const FeedbackOperationException(
          'reply-not-found',
          'The feedback reply was not found.',
        );
      }

      final reply = FeedbackReplyModel.fromMap(
        data,
        documentId: replySnapshot.id,
      ).normalized();

      if (reply.isDeleted) {
        throw const FeedbackOperationException(
          'reply-removed',
          'A removed reply cannot be reported.',
        );
      }

      transaction.set(reportReference, <String, dynamic>{
        'id': reportReference.id,
        'entityType': 'reply',
        'entityId': reply.id,
        'feedbackId': reply.feedbackId,
        'serviceType': reply.serviceType.value,
        'targetId': reply.targetId,
        'reporterId': cleanReporterId,
        'category': cleanCategory,
        'reason': cleanReason,
        'status': 'open',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });

      transaction.update(replyReference, <String, dynamic>{
        'reportCount': FieldValue.increment(1),
        'updatedAt': Timestamp.fromDate(now),
      });

      final auditReference = _auditLogs.doc();

      transaction.set(auditReference, <String, dynamic>{
        'id': auditReference.id,
        'entityType': 'reply',
        'entityId': reply.id,
        'feedbackId': reply.feedbackId,
        'action': 'reply_reported',
        'actorId': cleanReporterId,
        'reason': cleanReason,
        'createdAt': Timestamp.fromDate(now),
      });
    });

    return reportReference.id;
  }

  List<FeedbackReplyModel> _replyListFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map(
          (document) => FeedbackReplyModel.fromMap(
            document.data(),
            documentId: document.id,
          ),
        )
        .where((reply) => !reply.isDeleted)
        .toList(growable: false);
  }

  bool _authorMatchesTarget({
    required FeedbackReplyAuthorType authorType,
    required FeedbackTargetType targetType,
  }) {
    if (authorType.isAdminOrSupport) {
      return true;
    }

    switch (targetType) {
      case FeedbackTargetType.driver:
        return authorType == FeedbackReplyAuthorType.driver;
      case FeedbackTargetType.foodRider:
        return authorType == FeedbackReplyAuthorType.foodRider;
      case FeedbackTargetType.restaurant:
        return authorType == FeedbackReplyAuthorType.restaurantOwner;
      case FeedbackTargetType.hotel:
        return authorType == FeedbackReplyAuthorType.hotelOwner;
      case FeedbackTargetType.tourGuide:
        return authorType == FeedbackReplyAuthorType.tourGuide;
      case FeedbackTargetType.tourismDriver:
        return authorType == FeedbackReplyAuthorType.tourismDriver;
      case FeedbackTargetType.cargoDriver:
        return authorType == FeedbackReplyAuthorType.cargoDriver;
      case FeedbackTargetType.parcelRider:
        return authorType == FeedbackReplyAuthorType.parcelRider;
      case FeedbackTargetType.studentRideDriver:
        return authorType == FeedbackReplyAuthorType.studentRideDriver;
      case FeedbackTargetType.service:
      case FeedbackTargetType.other:
        return authorType == FeedbackReplyAuthorType.other;
    }
  }

  String _buildReplyDocumentId({
    required String feedbackId,
    required String authorId,
  }) {
    final rawValue = '${feedbackId.trim()}_${authorId.trim()}';

    return base64Url.encode(utf8.encode(rawValue)).replaceAll('=', '');
  }

  int _safeLimit(int value) {
    return value.clamp(1, 100);
  }
}
