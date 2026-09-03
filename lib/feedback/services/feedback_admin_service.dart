import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/feedback_model.dart';
import '../models/feedback_reply_model.dart';
import 'feedback_rating_service.dart';
import 'feedback_service.dart';

class FeedbackAdminService {
  static const String reportsCollectionName = 'feedback_reports';
  static const String adminNotesCollectionName = 'feedback_admin_notes';
  static const String auditCollectionName = 'feedback_admin_audit_logs';
  static const String repliesCollectionName = 'feedback_replies';

  final FirebaseFirestore _firestore;
  final FeedbackRatingService _ratingService;

  FeedbackAdminService({
    FirebaseFirestore? firestore,
    FeedbackRatingService? ratingService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _ratingService =
           ratingService ??
           FeedbackRatingService(
             firestore: firestore ?? FirebaseFirestore.instance,
           );

  CollectionReference<Map<String, dynamic>> get _reviews =>
      _firestore.collection(FeedbackService.reviewsCollectionName);

  CollectionReference<Map<String, dynamic>> get _replies =>
      _firestore.collection(repliesCollectionName);

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection(reportsCollectionName);

  CollectionReference<Map<String, dynamic>> get _adminNotes =>
      _firestore.collection(adminNotesCollectionName);

  CollectionReference<Map<String, dynamic>> get _auditLogs =>
      _firestore.collection(auditCollectionName);

  DocumentReference<Map<String, dynamic>> get _settingsDocument => _firestore
      .collection(FeedbackService.settingsCollectionName)
      .doc(FeedbackService.settingsDocumentId);

  Future<void> updateGlobalSettings({
    required FeedbackRuntimeSettings settings,
    required String adminId,
    bool complaintModuleEnabled = true,
    String reason = '',
  }) async {
    final cleanAdminId = adminId.trim();

    if (cleanAdminId.isEmpty) {
      throw const FeedbackOperationException(
        'admin-required',
        'Admin ID is required to update feedback settings.',
      );
    }

    final now = DateTime.now();
    final previousSnapshot = await _settingsDocument.get();
    final previousData = previousSnapshot.data() ?? const <String, dynamic>{};

    final nextData = <String, dynamic>{
      ...settings.toMap(),
      'complaintModuleEnabled': complaintModuleEnabled,
      'updatedBy': cleanAdminId,
      'updatedAt': Timestamp.fromDate(now),
    };

    final batch = _firestore.batch();

    batch.set(_settingsDocument, nextData);

    final auditReference = _auditLogs.doc();

    batch.set(auditReference, <String, dynamic>{
      'id': auditReference.id,
      'entityType': 'settings',
      'entityId': FeedbackService.settingsDocumentId,
      'action': 'settings_updated',
      'adminId': cleanAdminId,
      'reason': reason.trim(),
      'before': previousData,
      'after': nextData,
      'createdAt': Timestamp.fromDate(now),
    });

    await batch.commit();
  }

  Future<void> setServiceRatingEnabled({
    required FeedbackServiceType serviceType,
    required bool enabled,
    required String adminId,
    String reason = '',
  }) async {
    final cleanAdminId = adminId.trim();

    if (cleanAdminId.isEmpty) {
      throw const FeedbackOperationException(
        'admin-required',
        'Admin ID is required.',
      );
    }

    final now = DateTime.now();
    final fieldPath = 'serviceRatingsEnabled.${serviceType.value}';

    final batch = _firestore.batch();

    batch.set(_settingsDocument, <String, dynamic>{
      fieldPath: enabled,
      'updatedBy': cleanAdminId,
      'updatedAt': Timestamp.fromDate(now),
    }, SetOptions(merge: true));

    final auditReference = _auditLogs.doc();

    batch.set(auditReference, <String, dynamic>{
      'id': auditReference.id,
      'entityType': 'settings',
      'entityId': FeedbackService.settingsDocumentId,
      'action': enabled ? 'service_rating_enabled' : 'service_rating_disabled',
      'adminId': cleanAdminId,
      'serviceType': serviceType.value,
      'reason': reason.trim(),
      'createdAt': Timestamp.fromDate(now),
    });

    await batch.commit();
  }

  Stream<List<FeedbackModel>> watchReviews({
    FeedbackServiceType? serviceType,
    FeedbackStatus? status,
    int? rating,
    String? targetId,
    int limit = 100,
  }) {
    Query<Map<String, dynamic>> query = _reviews;

    if (serviceType != null) {
      query = query.where('serviceType', isEqualTo: serviceType.value);
    }

    if (status != null) {
      query = query.where('status', isEqualTo: status.value);
    }

    if (rating != null) {
      if (rating < 1 || rating > 5) {
        throw const FeedbackOperationException(
          'invalid-rating',
          'Rating filter must be between 1 and 5.',
        );
      }

      query = query.where('rating', isEqualTo: rating);
    }

    final cleanTargetId = targetId?.trim() ?? '';

    if (cleanTargetId.isNotEmpty) {
      query = query.where('targetId', isEqualTo: cleanTargetId);
    }

    return query
        .orderBy('createdAt', descending: true)
        .limit(_safeLimit(limit))
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (document) => FeedbackModel.fromMap(
                  document.data(),
                  documentId: document.id,
                ),
              )
              .toList(growable: false);
        });
  }

  Stream<List<FeedbackModel>> watchLowRatingReviews({
    int maximumRating = 2,
    FeedbackServiceType? serviceType,
    int limit = 100,
  }) {
    if (maximumRating < 1 || maximumRating > 5) {
      throw const FeedbackOperationException(
        'invalid-rating-threshold',
        'Low-rating threshold must be between 1 and 5.',
      );
    }

    Query<Map<String, dynamic>> query = _reviews.where(
      'rating',
      isLessThanOrEqualTo: maximumRating,
    );

    if (serviceType != null) {
      query = query.where('serviceType', isEqualTo: serviceType.value);
    }

    return query
        .orderBy('rating')
        .orderBy('createdAt', descending: true)
        .limit(_safeLimit(limit))
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (document) => FeedbackModel.fromMap(
                  document.data(),
                  documentId: document.id,
                ),
              )
              .where((review) => !review.isDeleted)
              .toList(growable: false);
        });
  }

  Future<void> moderateReview({
    required String feedbackId,
    required FeedbackStatus nextStatus,
    required String adminId,
    required String reason,
  }) async {
    final cleanFeedbackId = feedbackId.trim();
    final cleanAdminId = adminId.trim();
    final cleanReason = reason.trim();

    if (cleanFeedbackId.isEmpty ||
        cleanAdminId.isEmpty ||
        cleanReason.isEmpty) {
      throw const FeedbackOperationException(
        'invalid-moderation',
        'Feedback ID, admin ID and moderation reason are required.',
      );
    }

    if (nextStatus == FeedbackStatus.pendingModeration) {
      throw const FeedbackOperationException(
        'invalid-status',
        'Admin moderation cannot return a review to pending status.',
      );
    }

    final reference = _reviews.doc(cleanFeedbackId);
    late FeedbackModel current;
    final now = DateTime.now();

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      final data = snapshot.data();

      if (!snapshot.exists || data == null) {
        throw const FeedbackOperationException(
          'review-not-found',
          'Feedback was not found.',
        );
      }

      current = FeedbackModel.fromMap(
        data,
        documentId: snapshot.id,
      ).normalized();

      final updates = <String, dynamic>{
        'status': nextStatus.value,
        'moderatedBy': cleanAdminId,
        'moderatedAt': Timestamp.fromDate(now),
        'moderationReason': cleanReason,
        'updatedAt': Timestamp.fromDate(now),
      };

      if (nextStatus == FeedbackStatus.removed) {
        updates.addAll(<String, dynamic>{
          'deletedAt': Timestamp.fromDate(now),
          'deletedBy': cleanAdminId,
          'deletionReason': cleanReason,
        });
      } else if (current.isDeleted) {
        updates.addAll(<String, dynamic>{
          'deletedAt': null,
          'deletedBy': '',
          'deletionReason': '',
        });
      }

      transaction.update(reference, updates);

      _writeAudit(
        transaction: transaction,
        entityType: 'review',
        entityId: cleanFeedbackId,
        action: 'review_moderated',
        adminId: cleanAdminId,
        reason: cleanReason,
        beforeStatus: current.status.value,
        afterStatus: nextStatus.value,
        time: now,
      );
    });

    await _ratingService.synchronizeModerationChange(
      feedbackId: cleanFeedbackId,
    );
  }

  Future<String> reportReview({
    required String feedbackId,
    required String reporterId,
    required String category,
    required String reason,
  }) async {
    final cleanFeedbackId = feedbackId.trim();
    final cleanReporterId = reporterId.trim();
    final cleanCategory = category.trim();
    final cleanReason = reason.trim();

    if (cleanFeedbackId.isEmpty ||
        cleanReporterId.isEmpty ||
        cleanCategory.isEmpty ||
        cleanReason.isEmpty) {
      throw const FeedbackOperationException(
        'invalid-report',
        'Feedback, reporter, category and reason are required.',
      );
    }

    final reviewReference = _reviews.doc(cleanFeedbackId);
    final reportReference = _reports.doc();
    final now = DateTime.now();

    await _firestore.runTransaction((transaction) async {
      final reviewSnapshot = await transaction.get(reviewReference);
      final reviewData = reviewSnapshot.data();

      if (!reviewSnapshot.exists || reviewData == null) {
        throw const FeedbackOperationException(
          'review-not-found',
          'Feedback was not found.',
        );
      }

      final review = FeedbackModel.fromMap(
        reviewData,
        documentId: reviewSnapshot.id,
      );

      if (review.isDeleted) {
        throw const FeedbackOperationException(
          'review-deleted',
          'A deleted review cannot be reported.',
        );
      }

      transaction.set(reportReference, <String, dynamic>{
        'id': reportReference.id,
        'entityType': 'review',
        'entityId': cleanFeedbackId,
        'serviceType': review.serviceType.value,
        'reporterId': cleanReporterId,
        'category': cleanCategory,
        'reason': cleanReason,
        'status': 'open',
        'assignedAdminId': '',
        'resolution': '',
        'createdAt': Timestamp.fromDate(now),
        'resolvedAt': null,
      });

      transaction.update(reviewReference, <String, dynamic>{
        'reportCount': FieldValue.increment(1),
        'updatedAt': Timestamp.fromDate(now),
      });
    });

    await _ratingService.synchronizeModerationChange(
      feedbackId: cleanFeedbackId,
    );

    return reportReference.id;
  }

  Stream<List<Map<String, dynamic>>> watchOpenReports({
    String? entityType,
    FeedbackServiceType? serviceType,
    int limit = 100,
  }) {
    Query<Map<String, dynamic>> query = _reports.where(
      'status',
      isEqualTo: 'open',
    );

    final cleanEntityType = entityType?.trim() ?? '';

    if (cleanEntityType.isNotEmpty) {
      query = query.where('entityType', isEqualTo: cleanEntityType);
    }

    return query.orderBy('createdAt').limit(_safeLimit(limit)).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map(
            (document) => <String, dynamic>{
              ...document.data(),
              'id': document.id,
            },
          )
          .where((report) {
            if (serviceType == null) return true;
            return (report['serviceType']?.toString().trim() ?? '') ==
                serviceType.value;
          })
          .toList(growable: false);
    });
  }

  Future<void> resolveReport({
    required String reportId,
    required String adminId,
    required String resolution,
    bool dismiss = false,
  }) async {
    final cleanReportId = reportId.trim();
    final cleanAdminId = adminId.trim();
    final cleanResolution = resolution.trim();

    if (cleanReportId.isEmpty ||
        cleanAdminId.isEmpty ||
        cleanResolution.isEmpty) {
      throw const FeedbackOperationException(
        'invalid-resolution',
        'Report ID, admin ID and resolution are required.',
      );
    }

    final reference = _reports.doc(cleanReportId);
    final now = DateTime.now();

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      final data = snapshot.data();

      if (!snapshot.exists || data == null) {
        throw const FeedbackOperationException(
          'report-not-found',
          'Report was not found.',
        );
      }

      if (data['status'] != 'open') {
        throw const FeedbackOperationException(
          'report-final',
          'This report has already been resolved.',
        );
      }

      transaction.update(reference, <String, dynamic>{
        'status': dismiss ? 'dismissed' : 'resolved',
        'assignedAdminId': cleanAdminId,
        'resolution': cleanResolution,
        'resolvedAt': Timestamp.fromDate(now),
      });

      _writeAudit(
        transaction: transaction,
        entityType: 'report',
        entityId: cleanReportId,
        action: dismiss ? 'report_dismissed' : 'report_resolved',
        adminId: cleanAdminId,
        reason: cleanResolution,
        beforeStatus: 'open',
        afterStatus: dismiss ? 'dismissed' : 'resolved',
        time: now,
      );
    });
  }

  Future<String> addAdminNote({
    required String entityType,
    required String entityId,
    required String adminId,
    required String note,
    bool privateNote = true,
  }) async {
    final cleanEntityType = entityType.trim();
    final cleanEntityId = entityId.trim();
    final cleanAdminId = adminId.trim();
    final cleanNote = note.trim();

    if (cleanEntityType.isEmpty ||
        cleanEntityId.isEmpty ||
        cleanAdminId.isEmpty ||
        cleanNote.isEmpty) {
      throw const FeedbackOperationException(
        'invalid-note',
        'Entity, admin and note values are required.',
      );
    }

    final reference = _adminNotes.doc();
    final now = DateTime.now();

    await reference.set(<String, dynamic>{
      'id': reference.id,
      'entityType': cleanEntityType,
      'entityId': cleanEntityId,
      'adminId': cleanAdminId,
      'note': cleanNote,
      'private': privateNote,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });

    return reference.id;
  }

  Stream<List<Map<String, dynamic>>> watchAdminNotes({
    required String entityType,
    required String entityId,
  }) {
    final cleanEntityType = entityType.trim();
    final cleanEntityId = entityId.trim();

    if (cleanEntityType.isEmpty || cleanEntityId.isEmpty) {
      return Stream<List<Map<String, dynamic>>>.value(
        const <Map<String, dynamic>>[],
      );
    }

    return _adminNotes
        .where('entityType', isEqualTo: cleanEntityType)
        .where('entityId', isEqualTo: cleanEntityId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (document) => <String, dynamic>{
                  ...document.data(),
                  'id': document.id,
                },
              )
              .toList(growable: false);
        });
  }

  Future<void> moderateReply({
    required String replyId,
    required FeedbackReplyStatus nextStatus,
    required String adminId,
    required String reason,
  }) async {
    final cleanReplyId = replyId.trim();
    final cleanAdminId = adminId.trim();
    final cleanReason = reason.trim();

    if (cleanReplyId.isEmpty || cleanAdminId.isEmpty || cleanReason.isEmpty) {
      throw const FeedbackOperationException(
        'invalid-reply-moderation',
        'Reply ID, admin ID and reason are required.',
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
          'Feedback reply was not found.',
        );
      }

      final current = FeedbackReplyModel.fromMap(data, documentId: snapshot.id);

      final updates = <String, dynamic>{
        'status': nextStatus.value,
        'moderatedBy': cleanAdminId,
        'moderatedAt': Timestamp.fromDate(now),
        'moderationReason': cleanReason,
        'updatedAt': Timestamp.fromDate(now),
      };

      if (nextStatus == FeedbackReplyStatus.removed) {
        updates.addAll(<String, dynamic>{
          'deletedAt': Timestamp.fromDate(now),
          'deletedBy': cleanAdminId,
          'deletionReason': cleanReason,
        });
      }

      transaction.update(reference, updates);

      _writeAudit(
        transaction: transaction,
        entityType: 'reply',
        entityId: cleanReplyId,
        action: 'reply_moderated',
        adminId: cleanAdminId,
        reason: cleanReason,
        beforeStatus: current.status.value,
        afterStatus: nextStatus.value,
        time: now,
      );
    });
  }

  Stream<List<Map<String, dynamic>>> watchAuditLogs({
    String? entityType,
    String? entityId,
    int limit = 100,
  }) {
    Query<Map<String, dynamic>> query = _auditLogs;

    final cleanEntityType = entityType?.trim() ?? '';
    final cleanEntityId = entityId?.trim() ?? '';

    if (cleanEntityType.isNotEmpty) {
      query = query.where('entityType', isEqualTo: cleanEntityType);
    }

    if (cleanEntityId.isNotEmpty) {
      query = query.where('entityId', isEqualTo: cleanEntityId);
    }

    return query
        .orderBy('createdAt', descending: true)
        .limit(_safeLimit(limit))
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (document) => <String, dynamic>{
                  ...document.data(),
                  'id': document.id,
                },
              )
              .toList(growable: false);
        });
  }

  void _writeAudit({
    required Transaction transaction,
    required String entityType,
    required String entityId,
    required String action,
    required String adminId,
    required String reason,
    required String beforeStatus,
    required String afterStatus,
    required DateTime time,
  }) {
    final reference = _auditLogs.doc();

    transaction.set(reference, <String, dynamic>{
      'id': reference.id,
      'entityType': entityType,
      'entityId': entityId,
      'action': action,
      'adminId': adminId,
      'reason': reason,
      'beforeStatus': beforeStatus,
      'afterStatus': afterStatus,
      'createdAt': Timestamp.fromDate(time),
    });
  }

  int _safeLimit(int value) {
    return value.clamp(1, 100);
  }
}
