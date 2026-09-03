// lib/food/restaurant_partner/models/restaurant_partner_model.dart

enum RestaurantPartnerApplicationStatus {
  draft,
  pending,
  underReview,
  approved,
  rejected,
  suspended,
}

extension RestaurantPartnerApplicationStatusX
    on RestaurantPartnerApplicationStatus {
  String get value {
    switch (this) {
      case RestaurantPartnerApplicationStatus.draft:
        return 'draft';
      case RestaurantPartnerApplicationStatus.pending:
        return 'pending';
      case RestaurantPartnerApplicationStatus.underReview:
        return 'under_review';
      case RestaurantPartnerApplicationStatus.approved:
        return 'approved';
      case RestaurantPartnerApplicationStatus.rejected:
        return 'rejected';
      case RestaurantPartnerApplicationStatus.suspended:
        return 'suspended';
    }
  }

  String get displayName {
    switch (this) {
      case RestaurantPartnerApplicationStatus.draft:
        return 'Draft';
      case RestaurantPartnerApplicationStatus.pending:
        return 'Pending';
      case RestaurantPartnerApplicationStatus.underReview:
        return 'Under Review';
      case RestaurantPartnerApplicationStatus.approved:
        return 'Approved';
      case RestaurantPartnerApplicationStatus.rejected:
        return 'Rejected';
      case RestaurantPartnerApplicationStatus.suspended:
        return 'Suspended';
    }
  }

  static RestaurantPartnerApplicationStatus fromValue(dynamic value) {
    switch (value?.toString().trim().toLowerCase()) {
      case 'draft':
        return RestaurantPartnerApplicationStatus.draft;
      case 'under_review':
      case 'underreview':
      case 'under review':
        return RestaurantPartnerApplicationStatus.underReview;
      case 'approved':
        return RestaurantPartnerApplicationStatus.approved;
      case 'rejected':
        return RestaurantPartnerApplicationStatus.rejected;
      case 'suspended':
        return RestaurantPartnerApplicationStatus.suspended;
      default:
        return RestaurantPartnerApplicationStatus.pending;
    }
  }
}

class RestaurantPartnerModel {
  final String partnerId;
  final String userId;
  final String restaurantId;

  final String ownerName;
  final String email;
  final String phoneNumber;
  final String cnicNumber;

  final String restaurantName;
  final String restaurantType;
  final String description;
  final List<String> categories;
  final List<String> foodTypes;

  final String openingTime;
  final String closingTime;
  final List<int> openDays;

  final double deliveryRadiusKm;
  final double minimumOrderAmount;
  final double deliveryFee;

  final String country;
  final String province;
  final String city;
  final String area;
  final String address;
  final String landmark;
  final double latitude;
  final double longitude;

  final String cnicFrontPath;
  final String cnicBackPath;
  final String restaurantLicensePath;
  final String foodAuthorityCertificatePath;

  final String logoImagePath;
  final String coverImagePath;
  final List<String> galleryImagePaths;

  final String settlementMethod;
  final String accountTitle;
  final String accountNumber;
  final String bankName;

  final RestaurantPartnerApplicationStatus applicationStatus;
  final bool isApproved;
  final bool isRejected;
  final bool isBlocked;
  final bool isActive;
  final String rejectionReason;
  final String suspensionReason;
  final String adminNote;
  final String reviewedBy;
  final DateTime? reviewedAt;

  final double commissionPercentage;
  final bool acceptsCash;
  final bool acceptsWallet;
  final bool acceptsJazzCash;
  final bool acceptsEasypaisa;

  final double rating;
  final int totalReviews;
  final int totalOrders;
  final int completedOrders;
  final int cancelledOrders;
  final double totalEarnings;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? approvedAt;

  const RestaurantPartnerModel({
    required this.partnerId,
    required this.userId,
    required this.restaurantId,
    required this.ownerName,
    required this.email,
    required this.phoneNumber,
    required this.cnicNumber,
    required this.restaurantName,
    required this.restaurantType,
    required this.description,
    required this.categories,
    required this.foodTypes,
    required this.openingTime,
    required this.closingTime,
    required this.openDays,
    required this.deliveryRadiusKm,
    required this.minimumOrderAmount,
    required this.deliveryFee,
    required this.country,
    required this.province,
    required this.city,
    required this.area,
    required this.address,
    required this.landmark,
    required this.latitude,
    required this.longitude,
    required this.cnicFrontPath,
    required this.cnicBackPath,
    required this.restaurantLicensePath,
    required this.foodAuthorityCertificatePath,
    required this.logoImagePath,
    required this.coverImagePath,
    required this.galleryImagePaths,
    required this.settlementMethod,
    required this.accountTitle,
    required this.accountNumber,
    required this.bankName,
    required this.applicationStatus,
    required this.isApproved,
    required this.isRejected,
    required this.isBlocked,
    required this.isActive,
    required this.rejectionReason,
    required this.suspensionReason,
    required this.commissionPercentage,
    required this.acceptsCash,
    required this.acceptsWallet,
    required this.acceptsJazzCash,
    required this.acceptsEasypaisa,
    required this.rating,
    required this.totalReviews,
    required this.totalOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.totalEarnings,
    required this.createdAt,
    required this.updatedAt,
    required this.approvedAt,
    this.adminNote = '',
    this.reviewedBy = '',
    this.reviewedAt,
  });

  factory RestaurantPartnerModel.empty({String userId = ''}) {
    final now = DateTime.now();

    return RestaurantPartnerModel(
      partnerId: '',
      userId: userId,
      restaurantId: '',
      ownerName: '',
      email: '',
      phoneNumber: '',
      cnicNumber: '',
      restaurantName: '',
      restaurantType: '',
      description: '',
      categories: const [],
      foodTypes: const [],
      openingTime: '09:00',
      closingTime: '23:00',
      openDays: const [1, 2, 3, 4, 5, 6, 7],
      deliveryRadiusKm: 10,
      minimumOrderAmount: 0,
      deliveryFee: 0,
      country: 'Pakistan',
      province: 'Khyber Pakhtunkhwa',
      city: 'Swat',
      area: '',
      address: '',
      landmark: '',
      latitude: 0,
      longitude: 0,
      cnicFrontPath: '',
      cnicBackPath: '',
      restaurantLicensePath: '',
      foodAuthorityCertificatePath: '',
      logoImagePath: '',
      coverImagePath: '',
      galleryImagePaths: const [],
      settlementMethod: 'cash',
      accountTitle: '',
      accountNumber: '',
      bankName: '',
      applicationStatus: RestaurantPartnerApplicationStatus.draft,
      isApproved: false,
      isRejected: false,
      isBlocked: false,
      isActive: false,
      rejectionReason: '',
      suspensionReason: '',
      commissionPercentage: 0,
      acceptsCash: true,
      acceptsWallet: true,
      acceptsJazzCash: false,
      acceptsEasypaisa: false,
      rating: 0,
      totalReviews: 0,
      totalOrders: 0,
      completedOrders: 0,
      cancelledOrders: 0,
      totalEarnings: 0,
      createdAt: now,
      updatedAt: now,
      approvedAt: null,
    );
  }

  bool get canAccessPartnerDashboard =>
      isApproved &&
      isActive &&
      !isBlocked &&
      applicationStatus == RestaurantPartnerApplicationStatus.approved;

  RestaurantPartnerModel copyWith({
    String? partnerId,
    String? userId,
    String? restaurantId,
    String? ownerName,
    String? email,
    String? phoneNumber,
    String? cnicNumber,
    String? restaurantName,
    String? restaurantType,
    String? description,
    List<String>? categories,
    List<String>? foodTypes,
    String? openingTime,
    String? closingTime,
    List<int>? openDays,
    double? deliveryRadiusKm,
    double? minimumOrderAmount,
    double? deliveryFee,
    String? country,
    String? province,
    String? city,
    String? area,
    String? address,
    String? landmark,
    double? latitude,
    double? longitude,
    String? cnicFrontPath,
    String? cnicBackPath,
    String? restaurantLicensePath,
    String? foodAuthorityCertificatePath,
    String? logoImagePath,
    String? coverImagePath,
    List<String>? galleryImagePaths,
    String? settlementMethod,
    String? accountTitle,
    String? accountNumber,
    String? bankName,
    RestaurantPartnerApplicationStatus? applicationStatus,
    bool? isApproved,
    bool? isRejected,
    bool? isBlocked,
    bool? isActive,
    String? rejectionReason,
    String? suspensionReason,
    String? adminNote,
    String? reviewedBy,
    DateTime? reviewedAt,
    bool clearReviewedAt = false,
    double? commissionPercentage,
    bool? acceptsCash,
    bool? acceptsWallet,
    bool? acceptsJazzCash,
    bool? acceptsEasypaisa,
    double? rating,
    int? totalReviews,
    int? totalOrders,
    int? completedOrders,
    int? cancelledOrders,
    double? totalEarnings,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? approvedAt,
    bool clearApprovedAt = false,
  }) {
    return RestaurantPartnerModel(
      partnerId: partnerId ?? this.partnerId,
      userId: userId ?? this.userId,
      restaurantId: restaurantId ?? this.restaurantId,
      ownerName: ownerName ?? this.ownerName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      cnicNumber: cnicNumber ?? this.cnicNumber,
      restaurantName: restaurantName ?? this.restaurantName,
      restaurantType: restaurantType ?? this.restaurantType,
      description: description ?? this.description,
      categories: categories ?? this.categories,
      foodTypes: foodTypes ?? this.foodTypes,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      openDays: openDays ?? this.openDays,
      deliveryRadiusKm: deliveryRadiusKm ?? this.deliveryRadiusKm,
      minimumOrderAmount: minimumOrderAmount ?? this.minimumOrderAmount,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      country: country ?? this.country,
      province: province ?? this.province,
      city: city ?? this.city,
      area: area ?? this.area,
      address: address ?? this.address,
      landmark: landmark ?? this.landmark,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      cnicFrontPath: cnicFrontPath ?? this.cnicFrontPath,
      cnicBackPath: cnicBackPath ?? this.cnicBackPath,
      restaurantLicensePath:
          restaurantLicensePath ?? this.restaurantLicensePath,
      foodAuthorityCertificatePath:
          foodAuthorityCertificatePath ?? this.foodAuthorityCertificatePath,
      logoImagePath: logoImagePath ?? this.logoImagePath,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      galleryImagePaths: galleryImagePaths ?? this.galleryImagePaths,
      settlementMethod: settlementMethod ?? this.settlementMethod,
      accountTitle: accountTitle ?? this.accountTitle,
      accountNumber: accountNumber ?? this.accountNumber,
      bankName: bankName ?? this.bankName,
      applicationStatus: applicationStatus ?? this.applicationStatus,
      isApproved: isApproved ?? this.isApproved,
      isRejected: isRejected ?? this.isRejected,
      isBlocked: isBlocked ?? this.isBlocked,
      isActive: isActive ?? this.isActive,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      suspensionReason: suspensionReason ?? this.suspensionReason,
      adminNote: adminNote ?? this.adminNote,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt:
          clearReviewedAt ? null : reviewedAt ?? this.reviewedAt,
      commissionPercentage:
          commissionPercentage ?? this.commissionPercentage,
      acceptsCash: acceptsCash ?? this.acceptsCash,
      acceptsWallet: acceptsWallet ?? this.acceptsWallet,
      acceptsJazzCash: acceptsJazzCash ?? this.acceptsJazzCash,
      acceptsEasypaisa: acceptsEasypaisa ?? this.acceptsEasypaisa,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      totalOrders: totalOrders ?? this.totalOrders,
      completedOrders: completedOrders ?? this.completedOrders,
      cancelledOrders: cancelledOrders ?? this.cancelledOrders,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      approvedAt:
          clearApprovedAt ? null : approvedAt ?? this.approvedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'partnerId': partnerId,
      'userId': userId,
      'restaurantId': restaurantId,
      'ownerName': ownerName,
      'email': email,
      'phoneNumber': phoneNumber,
      'cnicNumber': cnicNumber,
      'restaurantName': restaurantName,
      'restaurantType': restaurantType,
      'description': description,
      'categories': categories,
      'foodTypes': foodTypes,
      'openingTime': openingTime,
      'closingTime': closingTime,
      'openDays': openDays,
      'deliveryRadiusKm': deliveryRadiusKm,
      'minimumOrderAmount': minimumOrderAmount,
      'deliveryFee': deliveryFee,
      'country': country,
      'province': province,
      'city': city,
      'area': area,
      'address': address,
      'landmark': landmark,
      'latitude': latitude,
      'longitude': longitude,
      'cnicFrontPath': cnicFrontPath,
      'cnicBackPath': cnicBackPath,
      'restaurantLicensePath': restaurantLicensePath,
      'foodAuthorityCertificatePath': foodAuthorityCertificatePath,
      'logoImagePath': logoImagePath,
      'coverImagePath': coverImagePath,
      'galleryImagePaths': galleryImagePaths,
      'settlementMethod': settlementMethod,
      'accountTitle': accountTitle,
      'accountNumber': accountNumber,
      'bankName': bankName,
      'applicationStatus': applicationStatus.value,
      'isApproved': isApproved,
      'isRejected': isRejected,
      'isBlocked': isBlocked,
      'isActive': isActive,
      'rejectionReason': rejectionReason,
      'suspensionReason': suspensionReason,
      'adminNote': adminNote.trim(),
      'reviewedBy': reviewedBy.trim(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'commissionPercentage': commissionPercentage,
      'acceptsCash': acceptsCash,
      'acceptsWallet': acceptsWallet,
      'acceptsJazzCash': acceptsJazzCash,
      'acceptsEasypaisa': acceptsEasypaisa,
      'rating': rating,
      'totalReviews': totalReviews,
      'totalOrders': totalOrders,
      'completedOrders': completedOrders,
      'cancelledOrders': cancelledOrders,
      'totalEarnings': totalEarnings,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
    };
  }

  factory RestaurantPartnerModel.fromMap(Map<String, dynamic> map) {
    return RestaurantPartnerModel(
      partnerId: _string(map['partnerId']),
      userId: _string(map['userId']),
      restaurantId: _string(map['restaurantId']),
      ownerName: _string(map['ownerName']),
      email: _string(map['email']),
      phoneNumber: _string(map['phoneNumber']),
      cnicNumber: _string(map['cnicNumber']),
      restaurantName: _string(map['restaurantName']),
      restaurantType: _string(map['restaurantType']),
      description: _string(map['description']),
      categories: _stringList(map['categories']),
      foodTypes: _stringList(map['foodTypes']),
      openingTime: _string(map['openingTime'], '09:00'),
      closingTime: _string(map['closingTime'], '23:00'),
      openDays: _intList(map['openDays'], const [1, 2, 3, 4, 5, 6, 7]),
      deliveryRadiusKm: _double(map['deliveryRadiusKm'], 10),
      minimumOrderAmount: _double(map['minimumOrderAmount']),
      deliveryFee: _double(map['deliveryFee']),
      country: _string(map['country'], 'Pakistan'),
      province: _string(map['province'], 'Khyber Pakhtunkhwa'),
      city: _string(map['city'], 'Swat'),
      area: _string(map['area']),
      address: _string(map['address']),
      landmark: _string(map['landmark']),
      latitude: _double(map['latitude']),
      longitude: _double(map['longitude']),
      cnicFrontPath: _string(map['cnicFrontPath']),
      cnicBackPath: _string(map['cnicBackPath']),
      restaurantLicensePath: _string(map['restaurantLicensePath']),
      foodAuthorityCertificatePath:
          _string(map['foodAuthorityCertificatePath']),
      logoImagePath: _string(map['logoImagePath']),
      coverImagePath: _string(map['coverImagePath']),
      galleryImagePaths: _stringList(map['galleryImagePaths']),
      settlementMethod: _string(map['settlementMethod'], 'cash'),
      accountTitle: _string(map['accountTitle']),
      accountNumber: _string(map['accountNumber']),
      bankName: _string(map['bankName']),
      applicationStatus:
          RestaurantPartnerApplicationStatusX.fromValue(
        map['applicationStatus'],
      ),
      isApproved: _bool(map['isApproved']),
      isRejected: _bool(map['isRejected']),
      isBlocked: _bool(map['isBlocked']),
      isActive: _bool(map['isActive']),
      rejectionReason: _string(map['rejectionReason']),
      suspensionReason: _string(map['suspensionReason']),
      adminNote: _string(map['adminNote']),
      reviewedBy: _string(map['reviewedBy']),
      reviewedAt: _date(map['reviewedAt']),
      commissionPercentage: _double(map['commissionPercentage']),
      acceptsCash: _bool(map['acceptsCash'], true),
      acceptsWallet: _bool(map['acceptsWallet'], true),
      acceptsJazzCash: _bool(map['acceptsJazzCash']),
      acceptsEasypaisa: _bool(map['acceptsEasypaisa']),
      rating: _double(map['rating']),
      totalReviews: _int(map['totalReviews']),
      totalOrders: _int(map['totalOrders']),
      completedOrders: _int(map['completedOrders']),
      cancelledOrders: _int(map['cancelledOrders']),
      totalEarnings: _double(map['totalEarnings']),
      createdAt: _date(map['createdAt']) ?? DateTime.now(),
      updatedAt: _date(map['updatedAt']) ?? DateTime.now(),
      approvedAt: _date(map['approvedAt']),
    );
  }

  static String _string(dynamic value, [String fallback = '']) {
    final parsed = value?.toString().trim() ?? '';
    return parsed.isEmpty ? fallback : parsed;
  }

  static int _int(dynamic value, [int fallback = 0]) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static double _double(dynamic value, [double fallback = 0]) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static bool _bool(dynamic value, [bool fallback = false]) {
    if (value is bool) return value;
    if (value is num) return value != 0;

    switch (value?.toString().trim().toLowerCase()) {
      case 'true':
      case '1':
      case 'yes':
        return true;
      case 'false':
      case '0':
      case 'no':
        return false;
      default:
        return fallback;
    }
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static List<int> _intList(dynamic value, List<int> fallback) {
    if (value is! List) return fallback;

    final result = value
        .map((item) => item is num
            ? item.toInt()
            : int.tryParse(item.toString()))
        .whereType<int>()
        .toSet()
        .toList()
      ..sort();

    return result.isEmpty ? fallback : result;
  }

  static DateTime? _date(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;

    try {
      final converted = value.toDate();
      if (converted is DateTime) return converted;
    } catch (_) {}

    return DateTime.tryParse(value.toString());
  }
}
