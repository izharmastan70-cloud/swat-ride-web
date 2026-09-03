import 'package:cloud_firestore/cloud_firestore.dart';

import 'feedback_model.dart';

class FeedbackRatingBreakdown {
  final int oneStar;
  final int twoStar;
  final int threeStar;
  final int fourStar;
  final int fiveStar;

  const FeedbackRatingBreakdown({
    this.oneStar = 0,
    this.twoStar = 0,
    this.threeStar = 0,
    this.fourStar = 0,
    this.fiveStar = 0,
  });

  int get total => oneStar + twoStar + threeStar + fourStar + fiveStar;

  int get ratingSum =>
      oneStar +
      (twoStar * 2) +
      (threeStar * 3) +
      (fourStar * 4) +
      (fiveStar * 5);

  double get averageRating {
    if (total == 0) {
      return 0;
    }

    return ratingSum / total;
  }

  int countForRating(int rating) {
    switch (rating) {
      case 1:
        return oneStar;
      case 2:
        return twoStar;
      case 3:
        return threeStar;
      case 4:
        return fourStar;
      case 5:
        return fiveStar;
      default:
        return 0;
    }
  }

  double percentageForRating(int rating) {
    if (total == 0) {
      return 0;
    }

    return (countForRating(rating) / total) * 100;
  }

  FeedbackRatingBreakdown increment(int rating) {
    switch (rating) {
      case 1:
        return copyWith(oneStar: oneStar + 1);
      case 2:
        return copyWith(twoStar: twoStar + 1);
      case 3:
        return copyWith(threeStar: threeStar + 1);
      case 4:
        return copyWith(fourStar: fourStar + 1);
      case 5:
        return copyWith(fiveStar: fiveStar + 1);
      default:
        throw const FormatException('Rating must be between 1 and 5.');
    }
  }

  FeedbackRatingBreakdown decrement(int rating) {
    final currentCount = countForRating(rating);

    if (currentCount <= 0) {
      throw StateError(
        'Cannot decrease rating $rating because its count is already zero.',
      );
    }

    switch (rating) {
      case 1:
        return copyWith(oneStar: oneStar - 1);
      case 2:
        return copyWith(twoStar: twoStar - 1);
      case 3:
        return copyWith(threeStar: threeStar - 1);
      case 4:
        return copyWith(fourStar: fourStar - 1);
      case 5:
        return copyWith(fiveStar: fiveStar - 1);
      default:
        throw const FormatException('Rating must be between 1 and 5.');
    }
  }

  FeedbackRatingBreakdown replaceRating({
    required int oldRating,
    required int newRating,
  }) {
    if (oldRating == newRating) {
      return this;
    }

    return decrement(oldRating).increment(newRating);
  }

  void validate() {
    if (oneStar < 0 ||
        twoStar < 0 ||
        threeStar < 0 ||
        fourStar < 0 ||
        fiveStar < 0) {
      throw const FormatException(
        'Rating breakdown counts cannot be negative.',
      );
    }
  }

  Map<String, dynamic> toMap() {
    validate();

    return <String, dynamic>{
      '1': oneStar,
      '2': twoStar,
      '3': threeStar,
      '4': fourStar,
      '5': fiveStar,
    };
  }

  factory FeedbackRatingBreakdown.fromMap(Object? value) {
    if (value is! Map) {
      return const FeedbackRatingBreakdown();
    }

    return FeedbackRatingBreakdown(
      oneStar: _intValue(value['1'] ?? value[1] ?? value['oneStar']),
      twoStar: _intValue(value['2'] ?? value[2] ?? value['twoStar']),
      threeStar: _intValue(value['3'] ?? value[3] ?? value['threeStar']),
      fourStar: _intValue(value['4'] ?? value[4] ?? value['fourStar']),
      fiveStar: _intValue(value['5'] ?? value[5] ?? value['fiveStar']),
    );
  }

  FeedbackRatingBreakdown copyWith({
    int? oneStar,
    int? twoStar,
    int? threeStar,
    int? fourStar,
    int? fiveStar,
  }) {
    return FeedbackRatingBreakdown(
      oneStar: oneStar ?? this.oneStar,
      twoStar: twoStar ?? this.twoStar,
      threeStar: threeStar ?? this.threeStar,
      fourStar: fourStar ?? this.fourStar,
      fiveStar: fiveStar ?? this.fiveStar,
    );
  }

  static int _intValue(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class FeedbackSummaryModel {
  final String id;
  final FeedbackServiceType serviceType;
  final FeedbackTargetType targetType;
  final String targetId;
  final String targetName;

  final int totalReviews;
  final int totalRatingPoints;
  final double averageRating;
  final FeedbackRatingBreakdown ratingBreakdown;

  final int verifiedReviewCount;
  final int publicReviewCount;
  final int repliedReviewCount;
  final int lowRatingCount;
  final int flaggedReviewCount;

  final DateTime? firstReviewAt;
  final DateTime? lastReviewAt;
  final DateTime updatedAt;

  final Map<String, dynamic> metadata;

  const FeedbackSummaryModel({
    required this.id,
    required this.serviceType,
    required this.targetType,
    required this.targetId,
    this.targetName = '',
    this.totalReviews = 0,
    this.totalRatingPoints = 0,
    this.averageRating = 0,
    this.ratingBreakdown = const FeedbackRatingBreakdown(),
    this.verifiedReviewCount = 0,
    this.publicReviewCount = 0,
    this.repliedReviewCount = 0,
    this.lowRatingCount = 0,
    this.flaggedReviewCount = 0,
    this.firstReviewAt,
    this.lastReviewAt,
    required this.updatedAt,
    this.metadata = const <String, dynamic>{},
  });

  factory FeedbackSummaryModel.empty({
    required FeedbackServiceType serviceType,
    required FeedbackTargetType targetType,
    required String targetId,
    String targetName = '',
    DateTime? updatedAt,
  }) {
    final cleanTargetId = targetId.trim();

    if (cleanTargetId.isEmpty) {
      throw const FormatException('Summary target ID is required.');
    }

    return FeedbackSummaryModel(
      id: buildSummaryId(
        serviceType: serviceType,
        targetType: targetType,
        targetId: cleanTargetId,
      ),
      serviceType: serviceType,
      targetType: targetType,
      targetId: cleanTargetId,
      targetName: targetName.trim(),
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  static String buildSummaryId({
    required FeedbackServiceType serviceType,
    required FeedbackTargetType targetType,
    required String targetId,
  }) {
    final cleanTargetId = targetId.trim();

    if (cleanTargetId.isEmpty) {
      throw const FormatException('Summary target ID is required.');
    }

    return '${serviceType.value}_${targetType.value}_$cleanTargetId';
  }

  double get fiveStarPercentage => ratingBreakdown.percentageForRating(5);

  double get fourStarPercentage => ratingBreakdown.percentageForRating(4);

  double get threeStarPercentage => ratingBreakdown.percentageForRating(3);

  double get twoStarPercentage => ratingBreakdown.percentageForRating(2);

  double get oneStarPercentage => ratingBreakdown.percentageForRating(1);

  double get responsePercentage {
    if (totalReviews == 0) {
      return 0;
    }

    return (repliedReviewCount / totalReviews) * 100;
  }

  double get verifiedPercentage {
    if (totalReviews == 0) {
      return 0;
    }

    return (verifiedReviewCount / totalReviews) * 100;
  }

  double get lowRatingPercentage {
    if (totalReviews == 0) {
      return 0;
    }

    return (lowRatingCount / totalReviews) * 100;
  }

  bool isBelowAlertThreshold(double threshold) {
    if (totalReviews == 0) {
      return false;
    }

    return averageRating < threshold;
  }

  FeedbackSummaryModel addReview({
    required int rating,
    required bool isVerified,
    required bool isPublic,
    required bool hasReply,
    required bool isFlagged,
    int lowRatingThreshold = 2,
    DateTime? reviewCreatedAt,
    DateTime? updateTime,
  }) {
    _validateRating(rating);
    _validateLowRatingThreshold(lowRatingThreshold);

    final nextTotal = totalReviews + 1;
    final nextPoints = totalRatingPoints + rating;
    final reviewTime = reviewCreatedAt ?? DateTime.now();

    return copyWith(
      totalReviews: nextTotal,
      totalRatingPoints: nextPoints,
      averageRating: nextPoints / nextTotal,
      ratingBreakdown: ratingBreakdown.increment(rating),
      verifiedReviewCount: verifiedReviewCount + (isVerified ? 1 : 0),
      publicReviewCount: publicReviewCount + (isPublic ? 1 : 0),
      repliedReviewCount: repliedReviewCount + (hasReply ? 1 : 0),
      lowRatingCount: lowRatingCount + (rating <= lowRatingThreshold ? 1 : 0),
      flaggedReviewCount: flaggedReviewCount + (isFlagged ? 1 : 0),
      firstReviewAt: firstReviewAt ?? reviewTime,
      lastReviewAt: reviewTime,
      updatedAt: updateTime ?? DateTime.now(),
    ).normalized();
  }

  FeedbackSummaryModel removeReview({
    required int rating,
    required bool isVerified,
    required bool isPublic,
    required bool hasReply,
    required bool isFlagged,
    int lowRatingThreshold = 2,
    DateTime? updateTime,
  }) {
    _validateRating(rating);
    _validateLowRatingThreshold(lowRatingThreshold);

    if (totalReviews <= 0) {
      throw StateError('Cannot remove a review from an empty summary.');
    }

    final nextTotal = totalReviews - 1;
    final nextPoints = totalRatingPoints - rating;

    return copyWith(
      totalReviews: nextTotal,
      totalRatingPoints: nextPoints,
      averageRating: nextTotal == 0 ? 0 : nextPoints / nextTotal,
      ratingBreakdown: ratingBreakdown.decrement(rating),
      verifiedReviewCount: verifiedReviewCount - (isVerified ? 1 : 0),
      publicReviewCount: publicReviewCount - (isPublic ? 1 : 0),
      repliedReviewCount: repliedReviewCount - (hasReply ? 1 : 0),
      lowRatingCount: lowRatingCount - (rating <= lowRatingThreshold ? 1 : 0),
      flaggedReviewCount: flaggedReviewCount - (isFlagged ? 1 : 0),
      firstReviewAt: nextTotal == 0 ? null : firstReviewAt,
      lastReviewAt: nextTotal == 0 ? null : lastReviewAt,
      updatedAt: updateTime ?? DateTime.now(),
    ).normalized();
  }

  FeedbackSummaryModel changeRating({
    required int oldRating,
    required int newRating,
    int lowRatingThreshold = 2,
    DateTime? updateTime,
  }) {
    _validateRating(oldRating);
    _validateRating(newRating);
    _validateLowRatingThreshold(lowRatingThreshold);

    if (totalReviews <= 0) {
      throw StateError('Cannot change a rating in an empty summary.');
    }

    if (oldRating == newRating) {
      return copyWith(updatedAt: updateTime ?? DateTime.now());
    }

    final nextPoints = totalRatingPoints - oldRating + newRating;
    final wasLow = oldRating <= lowRatingThreshold;
    final isLow = newRating <= lowRatingThreshold;

    var nextLowCount = lowRatingCount;

    if (wasLow && !isLow) {
      nextLowCount--;
    } else if (!wasLow && isLow) {
      nextLowCount++;
    }

    return copyWith(
      totalRatingPoints: nextPoints,
      averageRating: nextPoints / totalReviews,
      ratingBreakdown: ratingBreakdown.replaceRating(
        oldRating: oldRating,
        newRating: newRating,
      ),
      lowRatingCount: nextLowCount,
      updatedAt: updateTime ?? DateTime.now(),
    ).normalized();
  }

  void validate() {
    if (targetId.trim().isEmpty) {
      throw const FormatException('Summary target ID is required.');
    }

    if (totalReviews < 0 ||
        totalRatingPoints < 0 ||
        verifiedReviewCount < 0 ||
        publicReviewCount < 0 ||
        repliedReviewCount < 0 ||
        lowRatingCount < 0 ||
        flaggedReviewCount < 0) {
      throw const FormatException('Summary counts cannot be negative.');
    }

    ratingBreakdown.validate();

    if (ratingBreakdown.total != totalReviews) {
      throw const FormatException(
        'Rating breakdown total must equal total reviews.',
      );
    }

    if (ratingBreakdown.ratingSum != totalRatingPoints) {
      throw const FormatException(
        'Rating breakdown points must equal total rating points.',
      );
    }

    if (verifiedReviewCount > totalReviews ||
        publicReviewCount > totalReviews ||
        repliedReviewCount > totalReviews ||
        lowRatingCount > totalReviews ||
        flaggedReviewCount > totalReviews) {
      throw const FormatException(
        'A summary category count cannot exceed total reviews.',
      );
    }

    if (averageRating < 0 || averageRating > 5) {
      throw const FormatException('Average rating must be between 0 and 5.');
    }

    final calculatedAverage = totalReviews == 0
        ? 0.0
        : totalRatingPoints / totalReviews;

    if ((calculatedAverage - averageRating).abs() > 0.001) {
      throw const FormatException(
        'Average rating does not match rating totals.',
      );
    }

    if (firstReviewAt != null &&
        lastReviewAt != null &&
        lastReviewAt!.isBefore(firstReviewAt!)) {
      throw const FormatException(
        'Last review date cannot be before first review date.',
      );
    }
  }

  FeedbackSummaryModel normalized() {
    final cleanTargetId = targetId.trim();
    final calculatedAverage = totalReviews == 0
        ? 0.0
        : totalRatingPoints / totalReviews;

    final model = copyWith(
      id: id.trim().isEmpty
          ? buildSummaryId(
              serviceType: serviceType,
              targetType: targetType,
              targetId: cleanTargetId,
            )
          : id.trim(),
      targetId: cleanTargetId,
      targetName: targetName.trim(),
      averageRating: calculatedAverage,
      metadata: Map<String, dynamic>.unmodifiable(metadata),
    );

    model.validate();
    return model;
  }

  Map<String, dynamic> toMap() {
    final model = normalized();

    return <String, dynamic>{
      'id': model.id,
      'serviceType': model.serviceType.value,
      'targetType': model.targetType.value,
      'targetId': model.targetId,
      'targetName': model.targetName,
      'totalReviews': model.totalReviews,
      'totalRatingPoints': model.totalRatingPoints,
      'averageRating': model.averageRating,
      'ratingBreakdown': model.ratingBreakdown.toMap(),
      'verifiedReviewCount': model.verifiedReviewCount,
      'publicReviewCount': model.publicReviewCount,
      'repliedReviewCount': model.repliedReviewCount,
      'lowRatingCount': model.lowRatingCount,
      'flaggedReviewCount': model.flaggedReviewCount,
      'firstReviewAt': model.firstReviewAt == null
          ? null
          : Timestamp.fromDate(model.firstReviewAt!),
      'lastReviewAt': model.lastReviewAt == null
          ? null
          : Timestamp.fromDate(model.lastReviewAt!),
      'updatedAt': Timestamp.fromDate(model.updatedAt),
      'metadata': model.metadata,
    };
  }

  factory FeedbackSummaryModel.fromMap(
    Map<String, dynamic> map, {
    String documentId = '',
  }) {
    final breakdown = FeedbackRatingBreakdown.fromMap(map['ratingBreakdown']);

    final totalReviews = _intValue(
      map['totalReviews'],
      fallback: breakdown.total,
    );

    final totalPoints = _intValue(
      map['totalRatingPoints'],
      fallback: breakdown.ratingSum,
    );

    final calculatedAverage = totalReviews == 0
        ? 0.0
        : totalPoints / totalReviews;

    return FeedbackSummaryModel(
      id: _stringValue(map['id'], fallback: documentId),
      serviceType: FeedbackServiceTypeX.fromValue(map['serviceType']),
      targetType: FeedbackTargetTypeX.fromValue(map['targetType']),
      targetId: _stringValue(map['targetId']),
      targetName: _stringValue(map['targetName']),
      totalReviews: totalReviews,
      totalRatingPoints: totalPoints,
      averageRating: _doubleValue(
        map['averageRating'],
        fallback: calculatedAverage,
      ),
      ratingBreakdown: breakdown,
      verifiedReviewCount: _intValue(map['verifiedReviewCount']),
      publicReviewCount: _intValue(map['publicReviewCount']),
      repliedReviewCount: _intValue(map['repliedReviewCount']),
      lowRatingCount: _intValue(map['lowRatingCount']),
      flaggedReviewCount: _intValue(map['flaggedReviewCount']),
      firstReviewAt: _dateTimeValue(map['firstReviewAt']),
      lastReviewAt: _dateTimeValue(map['lastReviewAt']),
      updatedAt: _dateTimeValue(map['updatedAt']) ?? DateTime.now(),
      metadata: _dynamicMap(map['metadata']),
    );
  }

  factory FeedbackSummaryModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return FeedbackSummaryModel.fromMap(
      document.data() ?? const <String, dynamic>{},
      documentId: document.id,
    );
  }

  FeedbackSummaryModel copyWith({
    String? id,
    FeedbackServiceType? serviceType,
    FeedbackTargetType? targetType,
    String? targetId,
    String? targetName,
    int? totalReviews,
    int? totalRatingPoints,
    double? averageRating,
    FeedbackRatingBreakdown? ratingBreakdown,
    int? verifiedReviewCount,
    int? publicReviewCount,
    int? repliedReviewCount,
    int? lowRatingCount,
    int? flaggedReviewCount,
    DateTime? firstReviewAt,
    DateTime? lastReviewAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return FeedbackSummaryModel(
      id: id ?? this.id,
      serviceType: serviceType ?? this.serviceType,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      targetName: targetName ?? this.targetName,
      totalReviews: totalReviews ?? this.totalReviews,
      totalRatingPoints: totalRatingPoints ?? this.totalRatingPoints,
      averageRating: averageRating ?? this.averageRating,
      ratingBreakdown: ratingBreakdown ?? this.ratingBreakdown,
      verifiedReviewCount: verifiedReviewCount ?? this.verifiedReviewCount,
      publicReviewCount: publicReviewCount ?? this.publicReviewCount,
      repliedReviewCount: repliedReviewCount ?? this.repliedReviewCount,
      lowRatingCount: lowRatingCount ?? this.lowRatingCount,
      flaggedReviewCount: flaggedReviewCount ?? this.flaggedReviewCount,
      firstReviewAt: firstReviewAt ?? this.firstReviewAt,
      lastReviewAt: lastReviewAt ?? this.lastReviewAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  static void _validateRating(int rating) {
    if (rating < 1 || rating > 5) {
      throw const FormatException('Rating must be between 1 and 5.');
    }
  }

  static void _validateLowRatingThreshold(int threshold) {
    if (threshold < 1 || threshold > 5) {
      throw const FormatException(
        'Low-rating threshold must be between 1 and 5.',
      );
    }
  }

  static String _stringValue(Object? value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }

    final result = value.toString().trim();
    return result.isEmpty ? fallback : result;
  }

  static int _intValue(Object? value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static double _doubleValue(Object? value, {double fallback = 0}) {
    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static Map<String, dynamic> _dynamicMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(value);
    }

    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }

    return const <String, dynamic>{};
  }

  static DateTime? _dateTimeValue(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    return DateTime.tryParse(value.toString());
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FeedbackSummaryModel &&
            runtimeType == other.runtimeType &&
            id == other.id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'FeedbackSummaryModel('
        'id: $id, '
        'targetId: $targetId, '
        'averageRating: $averageRating, '
        'totalReviews: $totalReviews'
        ')';
  }
}
