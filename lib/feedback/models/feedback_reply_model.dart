import 'package:cloud_firestore/cloud_firestore.dart';

import 'feedback_model.dart';

enum FeedbackReplyType { public, privateSupport }

enum FeedbackReplyAuthorType {
  driver,
  foodRider,
  restaurantOwner,
  hotelOwner,
  tourGuide,
  tourismDriver,
  cargoDriver,
  parcelRider,
  studentRideDriver,
  admin,
  supportAgent,
  system,
  other,
}

enum FeedbackReplyStatus {
  published,
  pendingModeration,
  hidden,
  removed,
  flagged,
}

extension FeedbackReplyTypeX on FeedbackReplyType {
  String get value => name;

  String get displayName {
    switch (this) {
      case FeedbackReplyType.public:
        return 'Public Reply';
      case FeedbackReplyType.privateSupport:
        return 'Private Support Reply';
    }
  }

  static FeedbackReplyType fromValue(Object? value) {
    final normalized = value?.toString().trim().toLowerCase() ?? '';

    switch (normalized) {
      case 'privatesupport':
      case 'private_support':
      case 'private support':
      case 'private':
        return FeedbackReplyType.privateSupport;
      default:
        return FeedbackReplyType.public;
    }
  }
}

extension FeedbackReplyAuthorTypeX on FeedbackReplyAuthorType {
  String get value => name;

  String get displayName {
    switch (this) {
      case FeedbackReplyAuthorType.driver:
        return 'Driver';
      case FeedbackReplyAuthorType.foodRider:
        return 'Food Rider';
      case FeedbackReplyAuthorType.restaurantOwner:
        return 'Restaurant Owner';
      case FeedbackReplyAuthorType.hotelOwner:
        return 'Hotel Owner';
      case FeedbackReplyAuthorType.tourGuide:
        return 'Tour Guide';
      case FeedbackReplyAuthorType.tourismDriver:
        return 'Tourism Driver';
      case FeedbackReplyAuthorType.cargoDriver:
        return 'Cargo Driver';
      case FeedbackReplyAuthorType.parcelRider:
        return 'Parcel Rider';
      case FeedbackReplyAuthorType.studentRideDriver:
        return 'Student Ride Driver';
      case FeedbackReplyAuthorType.admin:
        return 'Admin';
      case FeedbackReplyAuthorType.supportAgent:
        return 'Support Agent';
      case FeedbackReplyAuthorType.system:
        return 'SWAT RIDE';
      case FeedbackReplyAuthorType.other:
        return 'Partner';
    }
  }

  bool get isAdminOrSupport {
    return this == FeedbackReplyAuthorType.admin ||
        this == FeedbackReplyAuthorType.supportAgent ||
        this == FeedbackReplyAuthorType.system;
  }

  static FeedbackReplyAuthorType fromValue(Object? value) {
    final normalized = value?.toString().trim().toLowerCase() ?? '';

    switch (normalized) {
      case 'driver':
        return FeedbackReplyAuthorType.driver;
      case 'foodrider':
      case 'food_rider':
      case 'food rider':
        return FeedbackReplyAuthorType.foodRider;
      case 'restaurantowner':
      case 'restaurant_owner':
      case 'restaurant owner':
        return FeedbackReplyAuthorType.restaurantOwner;
      case 'hotelowner':
      case 'hotel_owner':
      case 'hotel owner':
        return FeedbackReplyAuthorType.hotelOwner;
      case 'tourguide':
      case 'tour_guide':
      case 'tour guide':
        return FeedbackReplyAuthorType.tourGuide;
      case 'tourismdriver':
      case 'tourism_driver':
      case 'tourism driver':
        return FeedbackReplyAuthorType.tourismDriver;
      case 'cargodriver':
      case 'cargo_driver':
      case 'cargo driver':
        return FeedbackReplyAuthorType.cargoDriver;
      case 'parcelrider':
      case 'parcel_rider':
      case 'parcel rider':
        return FeedbackReplyAuthorType.parcelRider;
      case 'studentridedriver':
      case 'student_ride_driver':
      case 'student ride driver':
        return FeedbackReplyAuthorType.studentRideDriver;
      case 'admin':
        return FeedbackReplyAuthorType.admin;
      case 'supportagent':
      case 'support_agent':
      case 'support agent':
        return FeedbackReplyAuthorType.supportAgent;
      case 'system':
      case 'swatride':
      case 'swat_ride':
        return FeedbackReplyAuthorType.system;
      default:
        return FeedbackReplyAuthorType.other;
    }
  }
}

extension FeedbackReplyStatusX on FeedbackReplyStatus {
  String get value => name;

  static FeedbackReplyStatus fromValue(Object? value) {
    final normalized = value?.toString().trim().toLowerCase() ?? '';

    switch (normalized) {
      case 'published':
        return FeedbackReplyStatus.published;
      case 'pendingmoderation':
      case 'pending_moderation':
      case 'pending moderation':
        return FeedbackReplyStatus.pendingModeration;
      case 'hidden':
        return FeedbackReplyStatus.hidden;
      case 'removed':
      case 'deleted':
        return FeedbackReplyStatus.removed;
      case 'flagged':
        return FeedbackReplyStatus.flagged;
      default:
        return FeedbackReplyStatus.pendingModeration;
    }
  }
}

class FeedbackReplyModel {
  static const int maximumMessageLength = 1500;

  final String id;

  /// Connects this reply with FeedbackModel.id.
  final String feedbackId;

  final FeedbackServiceType serviceType;
  final String sourceId;
  final String targetId;

  final String authorId;
  final String authorName;
  final String authorPhotoUrl;
  final FeedbackReplyAuthorType authorType;

  final FeedbackReplyType replyType;
  final String message;
  final FeedbackReplyStatus status;

  final DateTime createdAt;
  final DateTime? updatedAt;

  final String moderatedBy;
  final DateTime? moderatedAt;
  final String moderationReason;

  final int reportCount;

  final DateTime? deletedAt;
  final String deletedBy;
  final String deletionReason;

  final Map<String, dynamic> metadata;

  const FeedbackReplyModel({
    required this.id,
    required this.feedbackId,
    required this.serviceType,
    required this.sourceId,
    required this.targetId,
    required this.authorId,
    this.authorName = '',
    this.authorPhotoUrl = '',
    required this.authorType,
    this.replyType = FeedbackReplyType.public,
    required this.message,
    this.status = FeedbackReplyStatus.pendingModeration,
    required this.createdAt,
    this.updatedAt,
    this.moderatedBy = '',
    this.moderatedAt,
    this.moderationReason = '',
    this.reportCount = 0,
    this.deletedAt,
    this.deletedBy = '',
    this.deletionReason = '',
    this.metadata = const <String, dynamic>{},
  });

  bool get isPublic =>
      replyType == FeedbackReplyType.public &&
      status == FeedbackReplyStatus.published &&
      !isDeleted;

  bool get isPrivateSupport => replyType == FeedbackReplyType.privateSupport;

  bool get isDeleted =>
      deletedAt != null || status == FeedbackReplyStatus.removed;

  bool get isFlagged =>
      status == FeedbackReplyStatus.flagged || reportCount > 0;

  bool get isAdminOrSupportReply => authorType.isAdminOrSupport;

  String get publicAuthorName {
    final cleanName = authorName.trim();

    if (cleanName.isNotEmpty) {
      return cleanName;
    }

    return authorType.displayName;
  }

  void validate() {
    if (feedbackId.trim().isEmpty) {
      throw const FormatException('Feedback ID is required.');
    }

    if (sourceId.trim().isEmpty) {
      throw const FormatException('Service source ID is required.');
    }

    if (targetId.trim().isEmpty) {
      throw const FormatException('Feedback target ID is required.');
    }

    if (authorId.trim().isEmpty) {
      throw const FormatException('Reply author ID is required.');
    }

    if (message.trim().isEmpty) {
      throw const FormatException('Reply message is required.');
    }

    if (message.trim().length > maximumMessageLength) {
      throw const FormatException(
        'Reply message cannot exceed 1500 characters.',
      );
    }

    if (reportCount < 0) {
      throw const FormatException('Report count cannot be negative.');
    }

    if (updatedAt != null && updatedAt!.isBefore(createdAt)) {
      throw const FormatException(
        'Updated date cannot be before created date.',
      );
    }

    if (moderatedAt != null && moderatedBy.trim().isEmpty) {
      throw const FormatException('Moderator ID is required after moderation.');
    }

    if (deletedAt != null && deletionReason.trim().isEmpty) {
      throw const FormatException(
        'Deletion reason is required for a deleted reply.',
      );
    }
  }

  FeedbackReplyModel normalized() {
    final model = copyWith(
      id: id.trim(),
      feedbackId: feedbackId.trim(),
      sourceId: sourceId.trim(),
      targetId: targetId.trim(),
      authorId: authorId.trim(),
      authorName: authorName.trim(),
      authorPhotoUrl: authorPhotoUrl.trim(),
      message: message.trim(),
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
      'feedbackId': model.feedbackId,
      'serviceType': model.serviceType.value,
      'sourceId': model.sourceId,
      'targetId': model.targetId,
      'authorId': model.authorId,
      'authorName': model.authorName,
      'authorPhotoUrl': model.authorPhotoUrl,
      'authorType': model.authorType.value,
      'replyType': model.replyType.value,
      'message': model.message,
      'status': model.status.value,
      'createdAt': Timestamp.fromDate(model.createdAt),
      'updatedAt': model.updatedAt == null
          ? null
          : Timestamp.fromDate(model.updatedAt!),
      'moderatedBy': model.moderatedBy,
      'moderatedAt': model.moderatedAt == null
          ? null
          : Timestamp.fromDate(model.moderatedAt!),
      'moderationReason': model.moderationReason,
      'reportCount': model.reportCount,
      'deletedAt': model.deletedAt == null
          ? null
          : Timestamp.fromDate(model.deletedAt!),
      'deletedBy': model.deletedBy,
      'deletionReason': model.deletionReason,
      'metadata': model.metadata,
    };
  }

  factory FeedbackReplyModel.fromMap(
    Map<String, dynamic> map, {
    String documentId = '',
  }) {
    return FeedbackReplyModel(
      id: _stringValue(map['id'], fallback: documentId),
      feedbackId: _stringValue(map['feedbackId']),
      serviceType: FeedbackServiceTypeX.fromValue(map['serviceType']),
      sourceId: _stringValue(map['sourceId']),
      targetId: _stringValue(map['targetId']),
      authorId: _stringValue(map['authorId']),
      authorName: _stringValue(map['authorName']),
      authorPhotoUrl: _stringValue(map['authorPhotoUrl']),
      authorType: FeedbackReplyAuthorTypeX.fromValue(map['authorType']),
      replyType: FeedbackReplyTypeX.fromValue(map['replyType']),
      message: _stringValue(map['message']),
      status: FeedbackReplyStatusX.fromValue(map['status']),
      createdAt: _dateTimeValue(map['createdAt']) ?? DateTime.now(),
      updatedAt: _dateTimeValue(map['updatedAt']),
      moderatedBy: _stringValue(map['moderatedBy']),
      moderatedAt: _dateTimeValue(map['moderatedAt']),
      moderationReason: _stringValue(map['moderationReason']),
      reportCount: _intValue(map['reportCount']),
      deletedAt: _dateTimeValue(map['deletedAt']),
      deletedBy: _stringValue(map['deletedBy']),
      deletionReason: _stringValue(map['deletionReason']),
      metadata: _dynamicMap(map['metadata']),
    );
  }

  factory FeedbackReplyModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return FeedbackReplyModel.fromMap(
      document.data() ?? const <String, dynamic>{},
      documentId: document.id,
    );
  }

  FeedbackReplyModel copyWith({
    String? id,
    String? feedbackId,
    FeedbackServiceType? serviceType,
    String? sourceId,
    String? targetId,
    String? authorId,
    String? authorName,
    String? authorPhotoUrl,
    FeedbackReplyAuthorType? authorType,
    FeedbackReplyType? replyType,
    String? message,
    FeedbackReplyStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? moderatedBy,
    DateTime? moderatedAt,
    String? moderationReason,
    int? reportCount,
    DateTime? deletedAt,
    String? deletedBy,
    String? deletionReason,
    Map<String, dynamic>? metadata,
  }) {
    return FeedbackReplyModel(
      id: id ?? this.id,
      feedbackId: feedbackId ?? this.feedbackId,
      serviceType: serviceType ?? this.serviceType,
      sourceId: sourceId ?? this.sourceId,
      targetId: targetId ?? this.targetId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorPhotoUrl: authorPhotoUrl ?? this.authorPhotoUrl,
      authorType: authorType ?? this.authorType,
      replyType: replyType ?? this.replyType,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      moderatedBy: moderatedBy ?? this.moderatedBy,
      moderatedAt: moderatedAt ?? this.moderatedAt,
      moderationReason: moderationReason ?? this.moderationReason,
      reportCount: reportCount ?? this.reportCount,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
      deletionReason: deletionReason ?? this.deletionReason,
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
        other is FeedbackReplyModel &&
            runtimeType == other.runtimeType &&
            id == other.id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'FeedbackReplyModel('
        'id: $id, '
        'feedbackId: $feedbackId, '
        'authorType: ${authorType.value}, '
        'replyType: ${replyType.value}, '
        'status: ${status.value}'
        ')';
  }
}
