import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/feedback_model.dart';
import '../models/feedback_summary_model.dart';
import 'feedback_service.dart';

class FeedbackRatingService {
  final FirebaseFirestore _firestore;

  FeedbackRatingService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _reviews =>
      _firestore.collection(FeedbackService.reviewsCollectionName);

  CollectionReference<Map<String, dynamic>> get _summaries =>
      _firestore.collection(FeedbackService.summariesCollectionName);

  Future<FeedbackSummaryModel?> getSummary({
    required FeedbackServiceType serviceType,
    required FeedbackTargetType targetType,
    required String targetId,
  }) async {
    final cleanTargetId = targetId.trim();

    if (cleanTargetId.isEmpty) {
      return null;
    }

    final summaryId = FeedbackSummaryModel.buildSummaryId(
      serviceType: serviceType,
      targetType: targetType,
      targetId: cleanTargetId,
    );

    final snapshot = await _summaries.doc(summaryId).get();
    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      return null;
    }

    return FeedbackSummaryModel.fromMap(data, documentId: snapshot.id);
  }

  Stream<FeedbackSummaryModel?> watchSummary({
    required FeedbackServiceType serviceType,
    required FeedbackTargetType targetType,
    required String targetId,
  }) {
    final cleanTargetId = targetId.trim();

    if (cleanTargetId.isEmpty) {
      return Stream<FeedbackSummaryModel?>.value(null);
    }

    final summaryId = FeedbackSummaryModel.buildSummaryId(
      serviceType: serviceType,
      targetType: targetType,
      targetId: cleanTargetId,
    );

    return _summaries.doc(summaryId).snapshots().map((snapshot) {
      final data = snapshot.data();

      if (!snapshot.exists || data == null) {
        return null;
      }

      return FeedbackSummaryModel.fromMap(data, documentId: snapshot.id);
    });
  }

  Future<FeedbackSummaryModel> rebuildTargetSummary({
    required FeedbackServiceType serviceType,
    required FeedbackTargetType targetType,
    required String targetId,
    String targetName = '',
    int lowRatingThreshold = 2,
  }) async {
    final cleanTargetId = targetId.trim();

    if (cleanTargetId.isEmpty) {
      throw const FeedbackOperationException(
        'invalid-target',
        'Rating summary target ID is required.',
      );
    }

    _validateThreshold(lowRatingThreshold);

    final snapshot = await _reviews
        .where('serviceType', isEqualTo: serviceType.value)
        .where('targetType', isEqualTo: targetType.value)
        .where('targetId', isEqualTo: cleanTargetId)
        .get();

    final reviews = snapshot.docs
        .map(
          (document) =>
              FeedbackModel.fromMap(document.data(), documentId: document.id),
        )
        .where(_isSummaryEligible)
        .toList(growable: false);

    final resolvedTargetName = targetName.trim().isNotEmpty
        ? targetName.trim()
        : _firstAvailableTargetName(reviews);

    final summary = buildSummaryFromReviews(
      reviews: reviews,
      serviceType: serviceType,
      targetType: targetType,
      targetId: cleanTargetId,
      targetName: resolvedTargetName,
      lowRatingThreshold: lowRatingThreshold,
      updateTime: DateTime.now(),
    );

    await _summaries.doc(summary.id).set(summary.toMap());

    await _projectFoodSummary(summary);

    return summary;
  }

  Future<int> rebuildServiceSummaries({
    required FeedbackServiceType serviceType,
    int lowRatingThreshold = 2,
  }) async {
    _validateThreshold(lowRatingThreshold);

    final snapshot = await _reviews
        .where('serviceType', isEqualTo: serviceType.value)
        .get();

    final eligibleReviews = snapshot.docs
        .map(
          (document) =>
              FeedbackModel.fromMap(document.data(), documentId: document.id),
        )
        .where(_isSummaryEligible)
        .toList(growable: false);

    final groups = <String, List<FeedbackModel>>{};

    for (final review in eligibleReviews) {
      final key = FeedbackSummaryModel.buildSummaryId(
        serviceType: review.serviceType,
        targetType: review.targetType,
        targetId: review.targetId,
      );

      groups.putIfAbsent(key, () => <FeedbackModel>[]).add(review);
    }

    if (groups.isEmpty) {
      return 0;
    }

    final now = DateTime.now();
    var batch = _firestore.batch();
    var operationCount = 0;
    var totalUpdated = 0;

    final List<FeedbackSummaryModel> rebuiltSummaries =
        <FeedbackSummaryModel>[];

    for (final entry in groups.entries) {
      final reviews = entry.value;
      final first = reviews.first;

      final summary = buildSummaryFromReviews(
        reviews: reviews,
        serviceType: first.serviceType,
        targetType: first.targetType,
        targetId: first.targetId,
        targetName: _firstAvailableTargetName(reviews),
        lowRatingThreshold: lowRatingThreshold,
        updateTime: now,
      );

      batch.set(_summaries.doc(summary.id), summary.toMap());

      rebuiltSummaries.add(summary);

      operationCount++;
      totalUpdated++;

      if (operationCount == 400) {
        await batch.commit();
        batch = _firestore.batch();
        operationCount = 0;
      }
    }

    if (operationCount > 0) {
      await batch.commit();
    }

    for (final FeedbackSummaryModel summary in rebuiltSummaries) {
      await _projectFoodSummary(summary);
    }

    return totalUpdated;
  }

  Future<void> synchronizeReplyState({
    required String feedbackId,
    required bool hasPartnerReply,
    int lowRatingThreshold = 2,
  }) async {
    final cleanFeedbackId = feedbackId.trim();

    if (cleanFeedbackId.isEmpty) {
      throw const FeedbackOperationException(
        'invalid-feedback-id',
        'Feedback ID is required.',
      );
    }

    _validateThreshold(lowRatingThreshold);

    final reference = _reviews.doc(cleanFeedbackId);
    final snapshot = await reference.get();
    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      throw const FeedbackOperationException(
        'feedback-not-found',
        'Feedback was not found.',
      );
    }

    final current = FeedbackModel.fromMap(
      data,
      documentId: snapshot.id,
    ).normalized();

    if (current.isDeleted) {
      throw const FeedbackOperationException(
        'feedback-deleted',
        'A deleted review cannot receive a reply.',
      );
    }

    if (current.hasPartnerReply != hasPartnerReply) {
      await reference.update(<String, dynamic>{
        'hasPartnerReply': hasPartnerReply,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await rebuildTargetSummary(
      serviceType: current.serviceType,
      targetType: current.targetType,
      targetId: current.targetId,
      targetName: current.targetName,
      lowRatingThreshold: lowRatingThreshold,
    );
  }

  Future<void> synchronizeModerationChange({
    required String feedbackId,
    int lowRatingThreshold = 2,
  }) async {
    final cleanFeedbackId = feedbackId.trim();

    if (cleanFeedbackId.isEmpty) {
      throw const FeedbackOperationException(
        'invalid-feedback-id',
        'Feedback ID is required.',
      );
    }

    _validateThreshold(lowRatingThreshold);

    final snapshot = await _reviews.doc(cleanFeedbackId).get();
    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      throw const FeedbackOperationException(
        'feedback-not-found',
        'Feedback was not found.',
      );
    }

    final feedback = FeedbackModel.fromMap(data, documentId: snapshot.id);

    await rebuildTargetSummary(
      serviceType: feedback.serviceType,
      targetType: feedback.targetType,
      targetId: feedback.targetId,
      targetName: feedback.targetName,
      lowRatingThreshold: lowRatingThreshold,
    );
  }

  Future<bool> verifyStoredSummary({
    required FeedbackServiceType serviceType,
    required FeedbackTargetType targetType,
    required String targetId,
    int lowRatingThreshold = 2,
  }) async {
    final stored = await getSummary(
      serviceType: serviceType,
      targetType: targetType,
      targetId: targetId,
    );

    final rebuilt = await _calculateTargetSummaryWithoutSaving(
      serviceType: serviceType,
      targetType: targetType,
      targetId: targetId,
      lowRatingThreshold: lowRatingThreshold,
    );

    if (stored == null) {
      return rebuilt.totalReviews == 0;
    }

    return stored.totalReviews == rebuilt.totalReviews &&
        stored.totalRatingPoints == rebuilt.totalRatingPoints &&
        stored.verifiedReviewCount == rebuilt.verifiedReviewCount &&
        stored.publicReviewCount == rebuilt.publicReviewCount &&
        stored.repliedReviewCount == rebuilt.repliedReviewCount &&
        stored.lowRatingCount == rebuilt.lowRatingCount &&
        stored.flaggedReviewCount == rebuilt.flaggedReviewCount &&
        stored.ratingBreakdown.oneStar == rebuilt.ratingBreakdown.oneStar &&
        stored.ratingBreakdown.twoStar == rebuilt.ratingBreakdown.twoStar &&
        stored.ratingBreakdown.threeStar == rebuilt.ratingBreakdown.threeStar &&
        stored.ratingBreakdown.fourStar == rebuilt.ratingBreakdown.fourStar &&
        stored.ratingBreakdown.fiveStar == rebuilt.ratingBreakdown.fiveStar;
  }

  Future<FeedbackSummaryModel> repairSummaryIfNeeded({
    required FeedbackServiceType serviceType,
    required FeedbackTargetType targetType,
    required String targetId,
    int lowRatingThreshold = 2,
  }) async {
    final isValid = await verifyStoredSummary(
      serviceType: serviceType,
      targetType: targetType,
      targetId: targetId,
      lowRatingThreshold: lowRatingThreshold,
    );

    if (isValid) {
      final existing = await getSummary(
        serviceType: serviceType,
        targetType: targetType,
        targetId: targetId,
      );

      if (existing != null) {
        await _projectFoodSummary(existing);
        return existing;
      }
    }

    return rebuildTargetSummary(
      serviceType: serviceType,
      targetType: targetType,
      targetId: targetId,
      lowRatingThreshold: lowRatingThreshold,
    );
  }

  Future<FeedbackSummaryModel> _calculateTargetSummaryWithoutSaving({
    required FeedbackServiceType serviceType,
    required FeedbackTargetType targetType,
    required String targetId,
    required int lowRatingThreshold,
  }) async {
    final cleanTargetId = targetId.trim();

    if (cleanTargetId.isEmpty) {
      throw const FeedbackOperationException(
        'invalid-target',
        'Rating summary target ID is required.',
      );
    }

    _validateThreshold(lowRatingThreshold);

    final snapshot = await _reviews
        .where('serviceType', isEqualTo: serviceType.value)
        .where('targetType', isEqualTo: targetType.value)
        .where('targetId', isEqualTo: cleanTargetId)
        .get();

    final reviews = snapshot.docs
        .map(
          (document) =>
              FeedbackModel.fromMap(document.data(), documentId: document.id),
        )
        .where(_isSummaryEligible)
        .toList(growable: false);

    return buildSummaryFromReviews(
      reviews: reviews,
      serviceType: serviceType,
      targetType: targetType,
      targetId: cleanTargetId,
      targetName: _firstAvailableTargetName(reviews),
      lowRatingThreshold: lowRatingThreshold,
      updateTime: DateTime.now(),
    );
  }

  Future<void> _projectFoodSummary(FeedbackSummaryModel summary) async {
    if (summary.serviceType != FeedbackServiceType.food) {
      return;
    }

    final String targetId = summary.targetId.trim();

    if (targetId.isEmpty) {
      return;
    }

    final WriteBatch batch = _firestore.batch();
    var writeCount = 0;

    switch (summary.targetType) {
      case FeedbackTargetType.restaurant:
        final Map<String, dynamic> restaurantFields = <String, dynamic>{
          'rating': summary.averageRating,
          'totalReviews': summary.totalReviews,
        };

        final DocumentReference<Map<String, dynamic>> restaurantReference =
            _firestore.collection('food_restaurants').doc(targetId);

        final DocumentSnapshot<Map<String, dynamic>> restaurantSnapshot =
            await restaurantReference.get();

        if (restaurantSnapshot.exists) {
          batch.set(
            restaurantReference,
            restaurantFields,
            SetOptions(merge: true),
          );
          writeCount++;
        }

        final QuerySnapshot<Map<String, dynamic>> partnerSnapshot =
            await _firestore
                .collection('food_restaurant_partners')
                .where('restaurantId', isEqualTo: targetId)
                .get();

        for (final QueryDocumentSnapshot<Map<String, dynamic>> partnerDocument
            in partnerSnapshot.docs) {
          batch.set(
            partnerDocument.reference,
            restaurantFields,
            SetOptions(merge: true),
          );
          writeCount++;
        }

        break;

      case FeedbackTargetType.foodRider:
        final DocumentReference<Map<String, dynamic>> riderReference =
            _firestore.collection('food_delivery_riders').doc(targetId);

        final DocumentSnapshot<Map<String, dynamic>> riderSnapshot =
            await riderReference.get();

        if (riderSnapshot.exists) {
          batch.set(riderReference, <String, dynamic>{
            'rating': summary.averageRating,
            'totalRatings': summary.totalReviews,
          }, SetOptions(merge: true));
          writeCount++;
        }

        break;

      default:
        return;
    }

    if (writeCount > 0) {
      await batch.commit();
    }
  }

  static FeedbackSummaryModel buildSummaryFromReviews({
    required Iterable<FeedbackModel> reviews,
    required FeedbackServiceType serviceType,
    required FeedbackTargetType targetType,
    required String targetId,
    String targetName = '',
    int lowRatingThreshold = 2,
    DateTime? updateTime,
  }) {
    _validateThreshold(lowRatingThreshold);

    final cleanTargetId = targetId.trim();

    if (cleanTargetId.isEmpty) {
      throw const FeedbackOperationException(
        'invalid-target',
        'Rating summary target ID is required.',
      );
    }

    var breakdown = const FeedbackRatingBreakdown();
    var verifiedCount = 0;
    var publicCount = 0;
    var repliedCount = 0;
    var lowRatingCount = 0;
    var flaggedCount = 0;
    DateTime? firstReviewAt;
    DateTime? lastReviewAt;

    for (final review in reviews) {
      if (!_isSummaryEligible(review)) {
        continue;
      }

      if (review.serviceType != serviceType ||
          review.targetType != targetType ||
          review.targetId.trim() != cleanTargetId) {
        continue;
      }

      breakdown = breakdown.increment(review.rating);

      if (review.isVerified) {
        verifiedCount++;
      }

      if (review.isPublic) {
        publicCount++;
      }

      if (review.hasPartnerReply) {
        repliedCount++;
      }

      if (review.rating <= lowRatingThreshold) {
        lowRatingCount++;
      }

      if (review.isFlagged) {
        flaggedCount++;
      }

      if (firstReviewAt == null || review.createdAt.isBefore(firstReviewAt)) {
        firstReviewAt = review.createdAt;
      }

      if (lastReviewAt == null || review.createdAt.isAfter(lastReviewAt)) {
        lastReviewAt = review.createdAt;
      }
    }

    final totalReviews = breakdown.total;
    final totalPoints = breakdown.ratingSum;

    return FeedbackSummaryModel(
      id: FeedbackSummaryModel.buildSummaryId(
        serviceType: serviceType,
        targetType: targetType,
        targetId: cleanTargetId,
      ),
      serviceType: serviceType,
      targetType: targetType,
      targetId: cleanTargetId,
      targetName: targetName.trim(),
      totalReviews: totalReviews,
      totalRatingPoints: totalPoints,
      averageRating: totalReviews == 0 ? 0 : totalPoints / totalReviews,
      ratingBreakdown: breakdown,
      verifiedReviewCount: verifiedCount,
      publicReviewCount: publicCount,
      repliedReviewCount: repliedCount,
      lowRatingCount: lowRatingCount,
      flaggedReviewCount: flaggedCount,
      firstReviewAt: firstReviewAt,
      lastReviewAt: lastReviewAt,
      updatedAt: updateTime ?? DateTime.now(),
    ).normalized();
  }

  static bool _isSummaryEligible(FeedbackModel feedback) {
    if (feedback.isDeleted) {
      return false;
    }

    return feedback.status == FeedbackStatus.published ||
        feedback.status == FeedbackStatus.flagged;
  }

  static String _firstAvailableTargetName(Iterable<FeedbackModel> reviews) {
    for (final review in reviews) {
      final name = review.targetName.trim();

      if (name.isNotEmpty) {
        return name;
      }
    }

    return '';
  }

  static void _validateThreshold(int threshold) {
    if (threshold < 1 || threshold > 5) {
      throw const FeedbackOperationException(
        'invalid-threshold',
        'Low-rating threshold must be between 1 and 5.',
      );
    }
  }
}
