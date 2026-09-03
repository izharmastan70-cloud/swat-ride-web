import 'package:cloud_firestore/cloud_firestore.dart';

class HotelFavorite {
  const HotelFavorite({
    required this.id,
    required this.userId,
    required this.hotelId,
    required this.hotelName,
    required this.hotelLocation,
    required this.createdAt,
    required this.updatedAt,
    this.coverImageUrl = '',
    this.localCoverImagePath = '',
    this.averageRating = 0,
    this.reviewCount = 0,
    this.startingPrice = 0,
    this.isActive = true,
    this.storageUploadUsed = false,
  });

  final String id;
  final String userId;
  final String hotelId;
  final String hotelName;
  final String hotelLocation;

  /// Real image URL remains optional because Firebase Storage
  /// is intentionally bypassed for now.
  final String coverImageUrl;

  /// Testing/local preview path only.
  final String localCoverImagePath;

  final double averageRating;
  final int reviewCount;
  final double startingPrice;
  final bool isActive;
  final bool storageUploadUsed;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory HotelFavorite.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return HotelFavorite(
      id: documentId,
      userId: map['userId']?.toString() ?? '',
      hotelId: map['hotelId']?.toString() ?? '',
      hotelName:
          map['hotelName']?.toString() ??
              map['name']?.toString() ??
              'Hotel',
      hotelLocation:
          map['hotelLocation']?.toString() ??
              map['location']?.toString() ??
              map['address']?.toString() ??
              '',
      coverImageUrl:
          map['coverImageUrl']?.toString() ??
              map['imageUrl']?.toString() ??
              '',
      localCoverImagePath:
          map['localCoverImagePath']?.toString() ??
              '',
      averageRating:
          _readDouble(map['averageRating']),
      reviewCount:
          _readInt(map['reviewCount']),
      startingPrice:
          _readDouble(
        map['startingPrice'] ??
            map['pricePerNight'],
      ),
      isActive: map['isActive'] != false,
      storageUploadUsed:
          map['storageUploadUsed'] == true,
      createdAt:
          _readDateTime(map['createdAt']),
      updatedAt: _readDateTime(
        map['updatedAt'] ?? map['createdAt'],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'userId': userId,
      'hotelId': hotelId,
      'hotelName': hotelName,
      'hotelLocation': hotelLocation,
      'coverImageUrl': coverImageUrl,
      'localCoverImagePath':
          localCoverImagePath,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'startingPrice': startingPrice,
      'isActive': isActive,
      'storageUploadUsed': storageUploadUsed,
      'createdAt':
          Timestamp.fromDate(createdAt),
      'updatedAt':
          Timestamp.fromDate(updatedAt),
    };
  }

  HotelFavorite copyWith({
    String? id,
    String? userId,
    String? hotelId,
    String? hotelName,
    String? hotelLocation,
    String? coverImageUrl,
    String? localCoverImagePath,
    double? averageRating,
    int? reviewCount,
    double? startingPrice,
    bool? isActive,
    bool? storageUploadUsed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HotelFavorite(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      hotelId: hotelId ?? this.hotelId,
      hotelName: hotelName ?? this.hotelName,
      hotelLocation:
          hotelLocation ?? this.hotelLocation,
      coverImageUrl:
          coverImageUrl ?? this.coverImageUrl,
      localCoverImagePath:
          localCoverImagePath ??
              this.localCoverImagePath,
      averageRating:
          averageRating ?? this.averageRating,
      reviewCount:
          reviewCount ?? this.reviewCount,
      startingPrice:
          startingPrice ?? this.startingPrice,
      isActive: isActive ?? this.isActive,
      storageUploadUsed:
          storageUploadUsed ??
              this.storageUploadUsed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static int _readInt(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
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
}
