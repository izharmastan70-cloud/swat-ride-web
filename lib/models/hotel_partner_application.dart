import 'package:cloud_firestore/cloud_firestore.dart';

class HotelPartnerApplication {
  const HotelPartnerApplication({
    required this.id,
    required this.applicantUserId,
    required this.ownerName,
    required this.ownerPhone,
    required this.ownerCnic,
    required this.ownerEmail,
    required this.hotelName,
    required this.hotelPhone,
    required this.location,
    required this.address,
    required this.category,
    required this.description,
    required this.facilities,
    required this.totalRooms,
    required this.minimumRoomPrice,
    required this.checkInTime,
    required this.checkOutTime,
    required this.applicationStatus,
    required this.isCustomerAccessEnabled,
    required this.createdAt,
    required this.updatedAt,
    this.hotelType = 'Hotel',
    this.hotelCategories = const <String>[],
    this.latitude,
    this.longitude,
    this.adminId = '',
    this.reviewedBy = '',
    this.reviewedAt,
    this.adminNote = '',
    this.rejectionReason = '',
    this.hotelId = '',
    this.imageUrls = const <String>[],
    this.documentUrls = const <String>[],
  });

  final String id;
  final String applicantUserId;
  final String ownerName;
  final String ownerPhone;
  final String ownerCnic;
  final String ownerEmail;
  final String hotelName;
  final String hotelPhone;
  final String location;
  final String address;
  final double? latitude;
  final double? longitude;

  final String hotelType;
  final List<String> hotelCategories;

  // Legacy field kept during migration.
  final String category;

  final String description;
  final List<String> facilities;
  final int totalRooms;
  final double minimumRoomPrice;
  final String checkInTime;
  final String checkOutTime;
  final String applicationStatus;
  final bool isCustomerAccessEnabled;
  final String adminId;
  final String reviewedBy;
  final DateTime? reviewedAt;
  final String adminNote;
  final String rejectionReason;
  final String hotelId;
  final List<String> imageUrls;
  final List<String> documentUrls;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isApproved => applicationStatus == 'approved';
  bool get needsChanges => applicationStatus == 'changes_requested';
  bool get isRejected => applicationStatus == 'rejected';

  bool get canOpenHotelDashboard {
    return isApproved && hotelId.trim().isNotEmpty;
  }

  factory HotelPartnerApplication.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    final String legacyCategory = _readString(
      map['category'],
      fallback: 'Standard',
    );

    final List<String> savedCategories =
        _readStringList(map['hotelCategories']);

    return HotelPartnerApplication(
      id: documentId,
      applicantUserId: _readString(map['applicantUserId']),
      ownerName: _readString(map['ownerName']),
      ownerPhone: _readString(map['ownerPhone']),
      ownerCnic: _readString(map['ownerCnic']),
      ownerEmail: _readString(map['ownerEmail']),
      hotelName: _readString(map['hotelName']),
      hotelPhone: _readString(map['hotelPhone']),
      location: _readString(map['location']),
      address: _readString(map['address']),
      latitude: _readNullableDouble(map['latitude']),
      longitude: _readNullableDouble(map['longitude']),
      hotelType: _readString(
        map['hotelType'],
        fallback: _legacyTypeFromCategory(legacyCategory),
      ),
      hotelCategories: savedCategories.isNotEmpty
          ? savedCategories
          : _legacyCategoriesFromCategory(legacyCategory),
      category: legacyCategory,
      description: _readString(map['description']),
      facilities: _readStringList(map['facilities']),
      totalRooms: _readInt(map['totalRooms']),
      minimumRoomPrice: _readDouble(map['minimumRoomPrice']),
      checkInTime: _readString(
        map['checkInTime'],
        fallback: '02:00 PM',
      ),
      checkOutTime: _readString(
        map['checkOutTime'],
        fallback: '12:00 PM',
      ),
      applicationStatus: _readString(
        map['applicationStatus'],
        fallback: 'draft',
      ),
      isCustomerAccessEnabled:
          map['isCustomerAccessEnabled'] != false,
      adminId: _readString(map['adminId']),
      reviewedBy: _readString(map['reviewedBy']),
      reviewedAt: _readDateTime(map['reviewedAt']),
      adminNote: _readString(map['adminNote']),
      rejectionReason: _readString(map['rejectionReason']),
      hotelId: _readString(map['hotelId']),
      imageUrls: _readStringList(map['imageUrls']),
      documentUrls: _readStringList(map['documentUrls']),
      createdAt: _readDateTime(map['createdAt']),
      updatedAt: _readDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'applicantUserId': applicantUserId,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,
      'ownerCnic': ownerCnic,
      'ownerEmail': ownerEmail,
      'hotelName': hotelName,
      'hotelPhone': hotelPhone,
      'location': location,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'hotelType': hotelType,
      'hotelCategories': hotelCategories,
      'category': category,
      'description': description,
      'facilities': facilities,
      'totalRooms': totalRooms,
      'minimumRoomPrice': minimumRoomPrice,
      'checkInTime': checkInTime,
      'checkOutTime': checkOutTime,
      'applicationStatus': applicationStatus,
      'isCustomerAccessEnabled': isCustomerAccessEnabled,
      'adminId': adminId,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt == null
          ? null
          : Timestamp.fromDate(reviewedAt!),
      'adminNote': adminNote,
      'rejectionReason': rejectionReason,
      'hotelId': hotelId,
      'imageUrls': imageUrls,
      'documentUrls': documentUrls,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(updatedAt!),
    };
  }

  HotelPartnerApplication copyWith({
    String? id,
    String? applicantUserId,
    String? ownerName,
    String? ownerPhone,
    String? ownerCnic,
    String? ownerEmail,
    String? hotelName,
    String? hotelPhone,
    String? location,
    String? address,
    double? latitude,
    double? longitude,
    String? hotelType,
    List<String>? hotelCategories,
    String? category,
    String? description,
    List<String>? facilities,
    int? totalRooms,
    double? minimumRoomPrice,
    String? checkInTime,
    String? checkOutTime,
    String? applicationStatus,
    bool? isCustomerAccessEnabled,
    String? adminId,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? adminNote,
    String? rejectionReason,
    String? hotelId,
    List<String>? imageUrls,
    List<String>? documentUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HotelPartnerApplication(
      id: id ?? this.id,
      applicantUserId: applicantUserId ?? this.applicantUserId,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      ownerCnic: ownerCnic ?? this.ownerCnic,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      hotelName: hotelName ?? this.hotelName,
      hotelPhone: hotelPhone ?? this.hotelPhone,
      location: location ?? this.location,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      hotelType: hotelType ?? this.hotelType,
      hotelCategories: hotelCategories ?? this.hotelCategories,
      category: category ?? this.category,
      description: description ?? this.description,
      facilities: facilities ?? this.facilities,
      totalRooms: totalRooms ?? this.totalRooms,
      minimumRoomPrice: minimumRoomPrice ?? this.minimumRoomPrice,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      applicationStatus: applicationStatus ?? this.applicationStatus,
      isCustomerAccessEnabled:
          isCustomerAccessEnabled ?? this.isCustomerAccessEnabled,
      adminId: adminId ?? this.adminId,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      adminNote: adminNote ?? this.adminNote,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      hotelId: hotelId ?? this.hotelId,
      imageUrls: imageUrls ?? this.imageUrls,
      documentUrls: documentUrls ?? this.documentUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static String _legacyTypeFromCategory(String category) {
    switch (category) {
      case 'Resort':
        return 'Resort';
      case 'Guest House':
        return 'Guest House';
      default:
        return 'Hotel';
    }
  }

  static List<String> _legacyCategoriesFromCategory(
    String category,
  ) {
    switch (category) {
      case 'Family':
        return const <String>['Family Friendly'];
      case 'Luxury':
        return const <String>['Luxury'];
      case 'Budget':
        return const <String>['Budget'];
      case 'Standard':
        return const <String>['Standard'];
      default:
        return const <String>[];
    }
  }

  static String _readString(
    dynamic value, {
    String fallback = '',
  }) {
    final String text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _readNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static List<String> _readStringList(dynamic value) {
    if (value is! List) return <String>[];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
