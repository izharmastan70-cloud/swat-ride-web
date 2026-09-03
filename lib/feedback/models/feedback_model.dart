import 'package:cloud_firestore/cloud_firestore.dart';

enum FeedbackServiceType {
  ride,
  food,
  hotel,
  tour,
  cargo,
  parcel,
  studentRide,
  other,
}

enum FeedbackTargetType {
  driver,
  foodRider,
  restaurant,
  hotel,
  tourGuide,
  tourismDriver,
  cargoDriver,
  parcelRider,
  studentRideDriver,
  service,
  other,
}

enum FeedbackStatus { published, pendingModeration, hidden, removed, flagged }

enum FeedbackVisibility { public, private, anonymous }

extension FeedbackServiceTypeX on FeedbackServiceType {
  String get value => name;

  String get displayName {
    switch (this) {
      case FeedbackServiceType.ride:
        return 'Ride';
      case FeedbackServiceType.food:
        return 'Food';
      case FeedbackServiceType.hotel:
        return 'Hotel';
      case FeedbackServiceType.tour:
        return 'Tour';
      case FeedbackServiceType.cargo:
        return 'Cargo';
      case FeedbackServiceType.parcel:
        return 'Parcel';
      case FeedbackServiceType.studentRide:
        return 'Student Ride';
      case FeedbackServiceType.other:
        return 'Other';
    }
  }

  static FeedbackServiceType fromValue(Object? value) {
    final normalized = value?.toString().trim().toLowerCase() ?? '';

    switch (normalized) {
      case 'ride':
        return FeedbackServiceType.ride;
      case 'food':
        return FeedbackServiceType.food;
      case 'hotel':
        return FeedbackServiceType.hotel;
      case 'tour':
      case 'tourism':
        return FeedbackServiceType.tour;
      case 'cargo':
        return FeedbackServiceType.cargo;
      case 'parcel':
        return FeedbackServiceType.parcel;
      case 'studentride':
      case 'student_ride':
      case 'student ride':
        return FeedbackServiceType.studentRide;
      default:
        return FeedbackServiceType.other;
    }
  }
}

extension FeedbackTargetTypeX on FeedbackTargetType {
  String get value => name;

  String get displayName {
    switch (this) {
      case FeedbackTargetType.driver:
        return 'Driver';
      case FeedbackTargetType.foodRider:
        return 'Food Rider';
      case FeedbackTargetType.restaurant:
        return 'Restaurant';
      case FeedbackTargetType.hotel:
        return 'Hotel';
      case FeedbackTargetType.tourGuide:
        return 'Tour Guide';
      case FeedbackTargetType.tourismDriver:
        return 'Tourism Driver';
      case FeedbackTargetType.cargoDriver:
        return 'Cargo Driver';
      case FeedbackTargetType.parcelRider:
        return 'Parcel Rider';
      case FeedbackTargetType.studentRideDriver:
        return 'Student Ride Driver';
      case FeedbackTargetType.service:
        return 'Service';
      case FeedbackTargetType.other:
        return 'Other';
    }
  }

  static FeedbackTargetType fromValue(Object? value) {
    final normalized = value?.toString().trim().toLowerCase() ?? '';

    switch (normalized) {
      case 'driver':
        return FeedbackTargetType.driver;
      case 'foodrider':
      case 'food_rider':
      case 'food rider':
        return FeedbackTargetType.foodRider;
      case 'restaurant':
        return FeedbackTargetType.restaurant;
      case 'hotel':
        return FeedbackTargetType.hotel;
      case 'tourguide':
      case 'tour_guide':
      case 'tour guide':
        return FeedbackTargetType.tourGuide;
      case 'tourismdriver':
      case 'tourism_driver':
      case 'tourism driver':
        return FeedbackTargetType.tourismDriver;
      case 'cargodriver':
      case 'cargo_driver':
      case 'cargo driver':
        return FeedbackTargetType.cargoDriver;
      case 'parcelrider':
      case 'parcel_rider':
      case 'parcel rider':
        return FeedbackTargetType.parcelRider;
      case 'studentridedriver':
      case 'student_ride_driver':
      case 'student ride driver':
        return FeedbackTargetType.studentRideDriver;
      case 'service':
        return FeedbackTargetType.service;
      default:
        return FeedbackTargetType.other;
    }
  }
}

extension FeedbackStatusX on FeedbackStatus {
  String get value => name;

  static FeedbackStatus fromValue(Object? value) {
    final normalized = value?.toString().trim().toLowerCase() ?? '';

    switch (normalized) {
      case 'published':
        return FeedbackStatus.published;
      case 'pendingmoderation':
      case 'pending_moderation':
      case 'pending moderation':
        return FeedbackStatus.pendingModeration;
      case 'hidden':
        return FeedbackStatus.hidden;
      case 'removed':
      case 'deleted':
        return FeedbackStatus.removed;
      case 'flagged':
        return FeedbackStatus.flagged;
      default:
        return FeedbackStatus.pendingModeration;
    }
  }
}

extension FeedbackVisibilityX on FeedbackVisibility {
  String get value => name;

  static FeedbackVisibility fromValue(Object? value) {
    final normalized = value?.toString().trim().toLowerCase() ?? '';

    switch (normalized) {
      case 'public':
        return FeedbackVisibility.public;
      case 'private':
        return FeedbackVisibility.private;
      case 'anonymous':
        return FeedbackVisibility.anonymous;
      default:
        return FeedbackVisibility.public;
    }
  }
}

class FeedbackModel {
  static const int minimumRating = 1;
  static const int maximumRating = 5;
  static const int maximumCommentLength = 1000;
  static const int maximumTagCount = 10;

  final String id;
  final FeedbackServiceType serviceType;
  final FeedbackTargetType targetType;

  /// Completed ride/order/booking/subscription identifier.
  final String sourceId;

  /// Optional human-readable reference shown in UI.
  final String sourceReference;

  final String reviewerId;
  final String reviewerName;
  final String reviewerPhotoUrl;

  final String targetId;
  final String targetName;
  final String targetPhotoUrl;

  final int rating;
  final List<String> tags;
  final String comment;

  /// True only when the linked service has been verified as completed.
  final bool isVerified;

  final FeedbackVisibility visibility;
  final FeedbackStatus status;

  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? editDeadline;

  final String moderatedBy;
  final DateTime? moderatedAt;
  final String moderationReason;

  final DateTime? deletedAt;
  final String deletedBy;
  final String deletionReason;

  final bool hasPartnerReply;
  final int reportCount;
  final int helpfulCount;

  /// Future-safe values such as city, area, vehicle type or app version.
  final Map<String, dynamic> metadata;

  const FeedbackModel({
    required this.id,
    required this.serviceType,
    required this.targetType,
    required this.sourceId,
    this.sourceReference = '',
    required this.reviewerId,
    this.reviewerName = '',
    this.reviewerPhotoUrl = '',
    required this.targetId,
    this.targetName = '',
    this.targetPhotoUrl = '',
    required this.rating,
    this.tags = const <String>[],
    this.comment = '',
    this.isVerified = false,
    this.visibility = FeedbackVisibility.public,
    this.status = FeedbackStatus.pendingModeration,
    required this.createdAt,
    this.updatedAt,
    this.editDeadline,
    this.moderatedBy = '',
    this.moderatedAt,
    this.moderationReason = '',
    this.deletedAt,
    this.deletedBy = '',
    this.deletionReason = '',
    this.hasPartnerReply = false,
    this.reportCount = 0,
    this.helpfulCount = 0,
    this.metadata = const <String, dynamic>{},
  });

  bool get isAnonymous => visibility == FeedbackVisibility.anonymous;

  bool get isPublic =>
      visibility != FeedbackVisibility.private &&
      status == FeedbackStatus.published &&
      !isDeleted;

  bool get isDeleted => deletedAt != null || status == FeedbackStatus.removed;

  bool get isFlagged => status == FeedbackStatus.flagged || reportCount > 0;

  bool get canCurrentlyEdit {
    if (isDeleted) {
      return false;
    }

    final deadline = editDeadline;
    return deadline == null || DateTime.now().isBefore(deadline);
  }

  String get publicReviewerName {
    if (isAnonymous) {
      return 'Anonymous Customer';
    }

    final cleanName = reviewerName.trim();
    return cleanName.isEmpty ? 'SWAT RIDE Customer' : cleanName;
  }

  /// Legacy review key kept for stored-document compatibility.
  String get uniqueReviewKey {
    return '${serviceType.value}_${sourceId.trim()}_${reviewerId.trim()}';
  }

  /// Duplicate-protection key.
  ///
  /// Food supports separate Restaurant and Food Rider reviews for the same
  /// delivered order, so its duplicate key also includes the review target.
  /// Other modules retain the original one-review-per-completed-service key.
  String get duplicateReviewKey {
    if (serviceType != FeedbackServiceType.food) {
      return uniqueReviewKey;
    }

    return '${uniqueReviewKey}_${targetType.value}_${targetId.trim()}';
  }

  void validate() {
    if (sourceId.trim().isEmpty) {
      throw const FormatException('Completed service source ID is required.');
    }

    if (reviewerId.trim().isEmpty) {
      throw const FormatException('Reviewer ID is required.');
    }

    if (targetId.trim().isEmpty) {
      throw const FormatException('Feedback target ID is required.');
    }

    if (rating < minimumRating || rating > maximumRating) {
      throw const FormatException('Rating must be between 1 and 5.');
    }

    if (comment.trim().length > maximumCommentLength) {
      throw const FormatException(
        'Feedback comment cannot exceed 1000 characters.',
      );
    }

    if (tags.length > maximumTagCount) {
      throw const FormatException('A maximum of 10 feedback tags is allowed.');
    }

    final normalizedTags = tags
        .map((tag) => tag.trim().toLowerCase())
        .where((tag) => tag.isNotEmpty)
        .toList();

    if (normalizedTags.length != normalizedTags.toSet().length) {
      throw const FormatException('Duplicate feedback tags are not allowed.');
    }

    if (reportCount < 0) {
      throw const FormatException('Report count cannot be negative.');
    }

    if (helpfulCount < 0) {
      throw const FormatException('Helpful count cannot be negative.');
    }

    if (updatedAt != null && updatedAt!.isBefore(createdAt)) {
      throw const FormatException(
        'Updated date cannot be before created date.',
      );
    }

    if (editDeadline != null && editDeadline!.isBefore(createdAt)) {
      throw const FormatException(
        'Edit deadline cannot be before created date.',
      );
    }

    if (deletedAt != null && deletionReason.trim().isEmpty) {
      throw const FormatException(
        'A deletion reason is required for deleted feedback.',
      );
    }
  }

  FeedbackModel normalized() {
    final cleanTags = tags
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .take(maximumTagCount)
        .toList(growable: false);

    final model = copyWith(
      id: id.trim(),
      sourceId: sourceId.trim(),
      sourceReference: sourceReference.trim(),
      reviewerId: reviewerId.trim(),
      reviewerName: reviewerName.trim(),
      reviewerPhotoUrl: reviewerPhotoUrl.trim(),
      targetId: targetId.trim(),
      targetName: targetName.trim(),
      targetPhotoUrl: targetPhotoUrl.trim(),
      tags: cleanTags,
      comment: comment.trim(),
      moderatedBy: moderatedBy.trim(),
      moderationReason: moderationReason.trim(),
      deletedBy: deletedBy.trim(),
      deletionReason: deletionReason.trim(),
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
      'sourceId': model.sourceId,
      'sourceReference': model.sourceReference,
      'reviewerId': model.reviewerId,
      'reviewerName': model.reviewerName,
      'reviewerPhotoUrl': model.reviewerPhotoUrl,
      'targetId': model.targetId,
      'targetName': model.targetName,
      'targetPhotoUrl': model.targetPhotoUrl,
      'rating': model.rating,
      'tags': model.tags,
      'comment': model.comment,
      'isVerified': model.isVerified,
      'visibility': model.visibility.value,
      'isAnonymous': model.isAnonymous,
      'status': model.status.value,
      'createdAt': Timestamp.fromDate(model.createdAt),
      'updatedAt': model.updatedAt == null
          ? null
          : Timestamp.fromDate(model.updatedAt!),
      'editDeadline': model.editDeadline == null
          ? null
          : Timestamp.fromDate(model.editDeadline!),
      'moderatedBy': model.moderatedBy,
      'moderatedAt': model.moderatedAt == null
          ? null
          : Timestamp.fromDate(model.moderatedAt!),
      'moderationReason': model.moderationReason,
      'deletedAt': model.deletedAt == null
          ? null
          : Timestamp.fromDate(model.deletedAt!),
      'deletedBy': model.deletedBy,
      'deletionReason': model.deletionReason,
      'hasPartnerReply': model.hasPartnerReply,
      'reportCount': model.reportCount,
      'helpfulCount': model.helpfulCount,
      'uniqueReviewKey': model.uniqueReviewKey,
      'metadata': model.metadata,
    };
  }

  factory FeedbackModel.fromMap(
    Map<String, dynamic> map, {
    String documentId = '',
  }) {
    final legacyAnonymous = map['isAnonymous'] == true;

    return FeedbackModel(
      id: _stringValue(map['id'], fallback: documentId),
      serviceType: FeedbackServiceTypeX.fromValue(map['serviceType']),
      targetType: FeedbackTargetTypeX.fromValue(map['targetType']),
      sourceId: _stringValue(
        map['sourceId'] ?? map['rideId'] ?? map['orderId'] ?? map['bookingId'],
      ),
      sourceReference: _stringValue(map['sourceReference']),
      reviewerId: _stringValue(map['reviewerId'] ?? map['userId']),
      reviewerName: _stringValue(map['reviewerName'] ?? map['userName']),
      reviewerPhotoUrl: _stringValue(
        map['reviewerPhotoUrl'] ?? map['userPhotoUrl'],
      ),
      targetId: _stringValue(
        map['targetId'] ??
            map['driverId'] ??
            map['restaurantId'] ??
            map['hotelId'],
      ),
      targetName: _stringValue(map['targetName']),
      targetPhotoUrl: _stringValue(map['targetPhotoUrl']),
      rating: _intValue(map['rating']),
      tags: _stringList(map['tags']),
      comment: _stringValue(map['comment'] ?? map['review']),
      isVerified: map['isVerified'] == true,
      visibility: legacyAnonymous
          ? FeedbackVisibility.anonymous
          : FeedbackVisibilityX.fromValue(map['visibility']),
      status: FeedbackStatusX.fromValue(map['status']),
      createdAt: _dateTimeValue(map['createdAt']) ?? DateTime.now(),
      updatedAt: _dateTimeValue(map['updatedAt']),
      editDeadline: _dateTimeValue(map['editDeadline']),
      moderatedBy: _stringValue(map['moderatedBy']),
      moderatedAt: _dateTimeValue(map['moderatedAt']),
      moderationReason: _stringValue(map['moderationReason']),
      deletedAt: _dateTimeValue(map['deletedAt']),
      deletedBy: _stringValue(map['deletedBy']),
      deletionReason: _stringValue(map['deletionReason']),
      hasPartnerReply: map['hasPartnerReply'] == true,
      reportCount: _intValue(map['reportCount']),
      helpfulCount: _intValue(map['helpfulCount']),
      metadata: _dynamicMap(map['metadata']),
    );
  }

  factory FeedbackModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return FeedbackModel.fromMap(
      document.data() ?? const <String, dynamic>{},
      documentId: document.id,
    );
  }

  FeedbackModel copyWith({
    String? id,
    FeedbackServiceType? serviceType,
    FeedbackTargetType? targetType,
    String? sourceId,
    String? sourceReference,
    String? reviewerId,
    String? reviewerName,
    String? reviewerPhotoUrl,
    String? targetId,
    String? targetName,
    String? targetPhotoUrl,
    int? rating,
    List<String>? tags,
    String? comment,
    bool? isVerified,
    FeedbackVisibility? visibility,
    FeedbackStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? editDeadline,
    String? moderatedBy,
    DateTime? moderatedAt,
    String? moderationReason,
    DateTime? deletedAt,
    String? deletedBy,
    String? deletionReason,
    bool? hasPartnerReply,
    int? reportCount,
    int? helpfulCount,
    Map<String, dynamic>? metadata,
  }) {
    return FeedbackModel(
      id: id ?? this.id,
      serviceType: serviceType ?? this.serviceType,
      targetType: targetType ?? this.targetType,
      sourceId: sourceId ?? this.sourceId,
      sourceReference: sourceReference ?? this.sourceReference,
      reviewerId: reviewerId ?? this.reviewerId,
      reviewerName: reviewerName ?? this.reviewerName,
      reviewerPhotoUrl: reviewerPhotoUrl ?? this.reviewerPhotoUrl,
      targetId: targetId ?? this.targetId,
      targetName: targetName ?? this.targetName,
      targetPhotoUrl: targetPhotoUrl ?? this.targetPhotoUrl,
      rating: rating ?? this.rating,
      tags: tags ?? this.tags,
      comment: comment ?? this.comment,
      isVerified: isVerified ?? this.isVerified,
      visibility: visibility ?? this.visibility,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      editDeadline: editDeadline ?? this.editDeadline,
      moderatedBy: moderatedBy ?? this.moderatedBy,
      moderatedAt: moderatedAt ?? this.moderatedAt,
      moderationReason: moderationReason ?? this.moderationReason,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
      deletionReason: deletionReason ?? this.deletionReason,
      hasPartnerReply: hasPartnerReply ?? this.hasPartnerReply,
      reportCount: reportCount ?? this.reportCount,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      metadata: metadata ?? this.metadata,
    );
  }

  static String _stringValue(Object? value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }

    final result = value.toString().trim();
    return result.isEmpty ? fallback : result;
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

  static List<String> _stringList(Object? value) {
    if (value is! Iterable) {
      return const <String>[];
    }

    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
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
        other is FeedbackModel &&
            runtimeType == other.runtimeType &&
            id == other.id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'FeedbackModel('
        'id: $id, '
        'serviceType: ${serviceType.value}, '
        'sourceId: $sourceId, '
        'targetId: $targetId, '
        'rating: $rating, '
        'status: ${status.value}'
        ')';
  }
}
