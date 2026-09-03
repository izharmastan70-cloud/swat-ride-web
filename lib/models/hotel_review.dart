import 'package:cloud_firestore/cloud_firestore.dart';

class HotelReview {
  const HotelReview({
    required this.id,
    required this.hotelId,
    required this.bookingId,
    required this.userId,
    required this.customerName,
    required this.rating,
    required this.reviewText,
    required this.ownerReply,
    required this.reviewStatus,
    required this.isVerifiedStay,
    required this.isHiddenByAdmin,
    required this.createdAt,
    required this.updatedAt,
    this.ownerRepliedAt,
    this.hiddenReason = '',
    this.reviewPhotoLocalPaths = const <String>[],
    this.storageUploadUsed = false,
  });

  final String id;
  final String hotelId;
  final String bookingId;
  final String userId;
  final String customerName;
  final double rating;
  final String reviewText;
  final String ownerReply;
  final String reviewStatus;
  final bool isVerifiedStay;
  final bool isHiddenByAdmin;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? ownerRepliedAt;
  final String hiddenReason;
  final List<String> reviewPhotoLocalPaths;
  final bool storageUploadUsed;

  bool get isPublished =>
      reviewStatus == 'published' && !isHiddenByAdmin;

  bool get hasOwnerReply =>
      ownerReply.trim().isNotEmpty;

  bool get ratingIsValid =>
      rating >= 1 && rating <= 5;

  factory HotelReview.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return HotelReview(
      id: documentId,
      hotelId: map['hotelId']?.toString() ?? '',
      bookingId: map['bookingId']?.toString() ?? '',
      userId: map['userId']?.toString() ??
          map['customerId']?.toString() ??
          '',
      customerName:
          map['customerName']?.toString() ??
              map['guestName']?.toString() ??
              'Guest',
      rating: _readDouble(map['rating']),
      reviewText:
          map['reviewText']?.toString() ??
              map['review']?.toString() ??
              '',
      ownerReply:
          map['ownerReply']?.toString() ?? '',
      reviewStatus:
          map['reviewStatus']?.toString() ??
              'pending',
      isVerifiedStay:
          map['isVerifiedStay'] == true,
      isHiddenByAdmin:
          map['isHiddenByAdmin'] == true,
      createdAt:
          _readDateTime(map['createdAt']),
      updatedAt: _readDateTime(
        map['updatedAt'] ?? map['createdAt'],
      ),
      ownerRepliedAt:
          _readNullableDateTime(
        map['ownerRepliedAt'],
      ),
      hiddenReason:
          map['hiddenReason']?.toString() ?? '',
      reviewPhotoLocalPaths:
          _readStringList(
        map['reviewPhotoLocalPaths'],
      ),
      storageUploadUsed:
          map['storageUploadUsed'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'hotelId': hotelId,
      'bookingId': bookingId,
      'userId': userId,
      'customerId': userId,
      'customerName': customerName,
      'rating': rating,
      'reviewText': reviewText,
      'ownerReply': ownerReply,
      'reviewStatus': reviewStatus,
      'isVerifiedStay': isVerifiedStay,
      'isHiddenByAdmin': isHiddenByAdmin,
      'hiddenReason': hiddenReason,
      'reviewPhotoLocalPaths':
          reviewPhotoLocalPaths,
      'storageUploadUsed': storageUploadUsed,
      'createdAt':
          Timestamp.fromDate(createdAt),
      'updatedAt':
          Timestamp.fromDate(updatedAt),
      'ownerRepliedAt':
          ownerRepliedAt == null
              ? null
              : Timestamp.fromDate(
                  ownerRepliedAt!,
                ),
    };
  }

  HotelReview copyWith({
    String? id,
    String? hotelId,
    String? bookingId,
    String? userId,
    String? customerName,
    double? rating,
    String? reviewText,
    String? ownerReply,
    String? reviewStatus,
    bool? isVerifiedStay,
    bool? isHiddenByAdmin,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? ownerRepliedAt,
    bool clearOwnerRepliedAt = false,
    String? hiddenReason,
    List<String>? reviewPhotoLocalPaths,
    bool? storageUploadUsed,
  }) {
    return HotelReview(
      id: id ?? this.id,
      hotelId: hotelId ?? this.hotelId,
      bookingId: bookingId ?? this.bookingId,
      userId: userId ?? this.userId,
      customerName:
          customerName ?? this.customerName,
      rating: rating ?? this.rating,
      reviewText: reviewText ?? this.reviewText,
      ownerReply: ownerReply ?? this.ownerReply,
      reviewStatus:
          reviewStatus ?? this.reviewStatus,
      isVerifiedStay:
          isVerifiedStay ?? this.isVerifiedStay,
      isHiddenByAdmin:
          isHiddenByAdmin ?? this.isHiddenByAdmin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ownerRepliedAt: clearOwnerRepliedAt
          ? null
          : ownerRepliedAt ??
              this.ownerRepliedAt,
      hiddenReason:
          hiddenReason ?? this.hiddenReason,
      reviewPhotoLocalPaths:
          reviewPhotoLocalPaths ??
              this.reviewPhotoLocalPaths,
      storageUploadUsed:
          storageUploadUsed ??
              this.storageUploadUsed,
    );
  }

  static double _readDouble(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  static DateTime _readDateTime(
    dynamic value,
  ) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value) ??
          DateTime.now();
    }

    return DateTime.now();
  }

  static DateTime? _readNullableDateTime(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  static List<String> _readStringList(
    dynamic value,
  ) {
    if (value is! List) {
      return const <String>[];
    }

    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}
