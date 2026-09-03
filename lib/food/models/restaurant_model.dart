// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Restaurant Model
//
// This model is shared by:
// 1. Customer Food App
// 2. Restaurant Owner Dashboard
// 3. Food Delivery Rider
// 4. Admin Panel
// 5. Firestore Services
// =============================================================

class RestaurantModel {
  // ===========================================================
  // BASIC IDENTIFIERS
  // ===========================================================

  final String id;
  final String ownerId;

  // ===========================================================
  // RESTAURANT INFORMATION
  // ===========================================================

  final String name;
  final String description;
  final String phoneNumber;
  final String email;

  final String logoUrl;
  final String coverImageUrl;

  // Original restaurant menu photos.
  //
  // Restaurant owner can upload one or multiple real menu photos.
  // Customer will be able to view these photos as reference.
  final List<String> originalMenuImageUrls;

  // ===========================================================
  // LOCATION
  // ===========================================================

  final String address;
  final String city;
  final String area;
  final String landmark;

  final double latitude;
  final double longitude;

  // ===========================================================
  // RESTAURANT CATEGORIES
  // ===========================================================

  final List<String> categories;
  final List<String> foodTypes;

  // Examples:
  // Burger, Pizza, BBQ, Biryani, Fast Food
  //
  // foodTypes examples:
  // Halal, Pakistani, Chinese, Continental

  // ===========================================================
  // RATINGS
  // ===========================================================

  final double rating;
  final int totalReviews;
  final int totalOrders;

  // ===========================================================
  // DELIVERY DETAILS
  // ===========================================================

  final double deliveryFee;
  final double minimumOrderAmount;

  final int minimumDeliveryTimeMinutes;
  final int maximumDeliveryTimeMinutes;

  final double maximumDeliveryDistanceKm;

  final bool isFreeDeliveryAvailable;

  // ===========================================================
  // BUSINESS HOURS
  // ===========================================================

  final String openingTime;
  final String closingTime;

  // Example:
  // openingTime = "09:00"
  // closingTime = "23:00"

  final List<int> openDays;

  // Day values:
  // 1 = Monday
  // 2 = Tuesday
  // ...
  // 7 = Sunday

  // ===========================================================
  // BUSINESS STATUS
  // ===========================================================

  final bool isOpen;
  final bool isBusy;
  final bool isTemporarilyClosed;

  final String temporaryClosingReason;

  // ===========================================================
  // ADMIN APPROVAL STATUS
  // ===========================================================

  final RestaurantApprovalStatus approvalStatus;

  final bool isApproved;
  final bool isActive;
  final bool isSuspended;

  final String rejectionReason;
  final String suspensionReason;

  // ===========================================================
  // PROMOTION AND VISIBILITY
  // ===========================================================

  final bool isFeatured;
  final bool isPopular;
  final bool isSponsored;

  final double discountPercentage;
  final String discountTitle;

  // ===========================================================
  // COMMISSION
  // ===========================================================

  // Admin can configure commission independently
  // for every restaurant.
  final double commissionPercentage;

  // ===========================================================
  // ORDER SETTINGS
  // ===========================================================

  final bool acceptsCash;
  final bool acceptsWallet;
  final bool acceptsJazzCash;
  final bool acceptsEasypaisa;

  final bool autoAcceptOrders;
  final int defaultPreparationTimeMinutes;

  // ===========================================================
  // MENU SETTINGS
  // ===========================================================

  final bool hasOriginalMenuImages;
  final bool hasDigitalMenu;
  final bool menuVerifiedByOwner;
  final bool menuApprovedByAdmin;

  final DateTime? menuLastUpdatedAt;

  // ===========================================================
  // OWNER DOCUMENTS
  // ===========================================================

  final String ownerCnicFrontUrl;
  final String ownerCnicBackUrl;
  final String restaurantFrontImageUrl;
  final String restaurantLicenseUrl;

  // ===========================================================
  // TIMESTAMPS
  // ===========================================================

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? approvedAt;

  // ===========================================================
  // CONSTRUCTOR
  // ===========================================================

  const RestaurantModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.phoneNumber,
    required this.email,
    required this.logoUrl,
    required this.coverImageUrl,
    required this.originalMenuImageUrls,
    required this.address,
    required this.city,
    required this.area,
    required this.landmark,
    required this.latitude,
    required this.longitude,
    required this.categories,
    required this.foodTypes,
    required this.rating,
    required this.totalReviews,
    required this.totalOrders,
    required this.deliveryFee,
    required this.minimumOrderAmount,
    required this.minimumDeliveryTimeMinutes,
    required this.maximumDeliveryTimeMinutes,
    required this.maximumDeliveryDistanceKm,
    required this.isFreeDeliveryAvailable,
    required this.openingTime,
    required this.closingTime,
    required this.openDays,
    required this.isOpen,
    required this.isBusy,
    required this.isTemporarilyClosed,
    required this.temporaryClosingReason,
    required this.approvalStatus,
    required this.isApproved,
    required this.isActive,
    required this.isSuspended,
    required this.rejectionReason,
    required this.suspensionReason,
    required this.isFeatured,
    required this.isPopular,
    required this.isSponsored,
    required this.discountPercentage,
    required this.discountTitle,
    required this.commissionPercentage,
    required this.acceptsCash,
    required this.acceptsWallet,
    required this.acceptsJazzCash,
    required this.acceptsEasypaisa,
    required this.autoAcceptOrders,
    required this.defaultPreparationTimeMinutes,
    required this.hasOriginalMenuImages,
    required this.hasDigitalMenu,
    required this.menuVerifiedByOwner,
    required this.menuApprovedByAdmin,
    required this.menuLastUpdatedAt,
    required this.ownerCnicFrontUrl,
    required this.ownerCnicBackUrl,
    required this.restaurantFrontImageUrl,
    required this.restaurantLicenseUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.approvedAt,
  });

  // ===========================================================
  // EMPTY MODEL
  // ===========================================================

  factory RestaurantModel.empty() {
    final DateTime now = DateTime.now();

    return RestaurantModel(
      id: '',
      ownerId: '',
      name: '',
      description: '',
      phoneNumber: '',
      email: '',
      logoUrl: '',
      coverImageUrl: '',
      originalMenuImageUrls: const <String>[],
      address: '',
      city: 'Swat',
      area: '',
      landmark: '',
      latitude: 0.0,
      longitude: 0.0,
      categories: const <String>[],
      foodTypes: const <String>[],
      rating: 0.0,
      totalReviews: 0,
      totalOrders: 0,
      deliveryFee: 0.0,
      minimumOrderAmount: 0.0,
      minimumDeliveryTimeMinutes: 20,
      maximumDeliveryTimeMinutes: 40,
      maximumDeliveryDistanceKm: 10.0,
      isFreeDeliveryAvailable: false,
      openingTime: '09:00',
      closingTime: '23:00',
      openDays: const <int>[1, 2, 3, 4, 5, 6, 7],
      isOpen: false,
      isBusy: false,
      isTemporarilyClosed: false,
      temporaryClosingReason: '',
      approvalStatus: RestaurantApprovalStatus.pending,
      isApproved: false,
      isActive: false,
      isSuspended: false,
      rejectionReason: '',
      suspensionReason: '',
      isFeatured: false,
      isPopular: false,
      isSponsored: false,
      discountPercentage: 0.0,
      discountTitle: '',
      commissionPercentage: 0.0,
      acceptsCash: true,
      acceptsWallet: true,
      acceptsJazzCash: false,
      acceptsEasypaisa: false,
      autoAcceptOrders: false,
      defaultPreparationTimeMinutes: 25,
      hasOriginalMenuImages: false,
      hasDigitalMenu: false,
      menuVerifiedByOwner: false,
      menuApprovedByAdmin: false,
      menuLastUpdatedAt: null,
      ownerCnicFrontUrl: '',
      ownerCnicBackUrl: '',
      restaurantFrontImageUrl: '',
      restaurantLicenseUrl: '',
      createdAt: now,
      updatedAt: now,
      approvedAt: null,
    );
  }

  // ===========================================================
  // DISPLAY HELPERS
  // ===========================================================

  String get deliveryTimeText {
    return '$minimumDeliveryTimeMinutes-'
        '$maximumDeliveryTimeMinutes min';
  }

  String get deliveryFeeText {
    if (isFreeDeliveryAvailable || deliveryFee <= 0) {
      return 'Free delivery';
    }

    return 'Rs. ${deliveryFee.toStringAsFixed(0)} delivery';
  }

  String get minimumOrderText {
    if (minimumOrderAmount <= 0) {
      return 'No minimum order';
    }

    return 'Minimum Rs. '
        '${minimumOrderAmount.toStringAsFixed(0)}';
  }

  String get discountText {
    if (discountPercentage <= 0) {
      return '';
    }

    return '${discountPercentage.toStringAsFixed(0)}% OFF';
  }

  String get categoriesText {
    if (categories.isEmpty) {
      return 'Restaurant';
    }

    return categories.join(' • ');
  }

  String get ratingText {
    if (totalReviews <= 0) {
      return 'New';
    }

    return rating.toStringAsFixed(1);
  }

  String get openStatusText {
    if (isSuspended) {
      return 'Suspended';
    }

    if (!isApproved) {
      return 'Awaiting approval';
    }

    if (!isActive) {
      return 'Inactive';
    }

    if (isTemporarilyClosed) {
      return 'Temporarily closed';
    }

    if (isBusy) {
      return 'Busy';
    }

    if (isOpen) {
      return 'Open';
    }

    return 'Closed';
  }

  bool get canReceiveOrders {
    return isApproved &&
        isActive &&
        !isSuspended &&
        !isTemporarilyClosed &&
        isOpen;
  }

  bool get hasDiscount {
    return discountPercentage > 0;
  }

  bool get hasValidLocation {
    return latitude != 0.0 && longitude != 0.0;
  }

  // ===========================================================
  // COPY WITH
  // ===========================================================

  RestaurantModel copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? description,
    String? phoneNumber,
    String? email,
    String? logoUrl,
    String? coverImageUrl,
    List<String>? originalMenuImageUrls,
    String? address,
    String? city,
    String? area,
    String? landmark,
    double? latitude,
    double? longitude,
    List<String>? categories,
    List<String>? foodTypes,
    double? rating,
    int? totalReviews,
    int? totalOrders,
    double? deliveryFee,
    double? minimumOrderAmount,
    int? minimumDeliveryTimeMinutes,
    int? maximumDeliveryTimeMinutes,
    double? maximumDeliveryDistanceKm,
    bool? isFreeDeliveryAvailable,
    String? openingTime,
    String? closingTime,
    List<int>? openDays,
    bool? isOpen,
    bool? isBusy,
    bool? isTemporarilyClosed,
    String? temporaryClosingReason,
    RestaurantApprovalStatus? approvalStatus,
    bool? isApproved,
    bool? isActive,
    bool? isSuspended,
    String? rejectionReason,
    String? suspensionReason,
    bool? isFeatured,
    bool? isPopular,
    bool? isSponsored,
    double? discountPercentage,
    String? discountTitle,
    double? commissionPercentage,
    bool? acceptsCash,
    bool? acceptsWallet,
    bool? acceptsJazzCash,
    bool? acceptsEasypaisa,
    bool? autoAcceptOrders,
    int? defaultPreparationTimeMinutes,
    bool? hasOriginalMenuImages,
    bool? hasDigitalMenu,
    bool? menuVerifiedByOwner,
    bool? menuApprovedByAdmin,
    DateTime? menuLastUpdatedAt,
    bool clearMenuLastUpdatedAt = false,
    String? ownerCnicFrontUrl,
    String? ownerCnicBackUrl,
    String? restaurantFrontImageUrl,
    String? restaurantLicenseUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? approvedAt,
    bool clearApprovedAt = false,
  }) {
    return RestaurantModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      logoUrl: logoUrl ?? this.logoUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      originalMenuImageUrls:
          originalMenuImageUrls ?? this.originalMenuImageUrls,
      address: address ?? this.address,
      city: city ?? this.city,
      area: area ?? this.area,
      landmark: landmark ?? this.landmark,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      categories: categories ?? this.categories,
      foodTypes: foodTypes ?? this.foodTypes,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      totalOrders: totalOrders ?? this.totalOrders,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      minimumOrderAmount:
          minimumOrderAmount ?? this.minimumOrderAmount,
      minimumDeliveryTimeMinutes:
          minimumDeliveryTimeMinutes ??
          this.minimumDeliveryTimeMinutes,
      maximumDeliveryTimeMinutes:
          maximumDeliveryTimeMinutes ??
          this.maximumDeliveryTimeMinutes,
      maximumDeliveryDistanceKm:
          maximumDeliveryDistanceKm ??
          this.maximumDeliveryDistanceKm,
      isFreeDeliveryAvailable:
          isFreeDeliveryAvailable ??
          this.isFreeDeliveryAvailable,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      openDays: openDays ?? this.openDays,
      isOpen: isOpen ?? this.isOpen,
      isBusy: isBusy ?? this.isBusy,
      isTemporarilyClosed:
          isTemporarilyClosed ??
          this.isTemporarilyClosed,
      temporaryClosingReason:
          temporaryClosingReason ??
          this.temporaryClosingReason,
      approvalStatus:
          approvalStatus ?? this.approvalStatus,
      isApproved: isApproved ?? this.isApproved,
      isActive: isActive ?? this.isActive,
      isSuspended: isSuspended ?? this.isSuspended,
      rejectionReason:
          rejectionReason ?? this.rejectionReason,
      suspensionReason:
          suspensionReason ?? this.suspensionReason,
      isFeatured: isFeatured ?? this.isFeatured,
      isPopular: isPopular ?? this.isPopular,
      isSponsored: isSponsored ?? this.isSponsored,
      discountPercentage:
          discountPercentage ?? this.discountPercentage,
      discountTitle:
          discountTitle ?? this.discountTitle,
      commissionPercentage:
          commissionPercentage ?? this.commissionPercentage,
      acceptsCash: acceptsCash ?? this.acceptsCash,
      acceptsWallet: acceptsWallet ?? this.acceptsWallet,
      acceptsJazzCash:
          acceptsJazzCash ?? this.acceptsJazzCash,
      acceptsEasypaisa:
          acceptsEasypaisa ?? this.acceptsEasypaisa,
      autoAcceptOrders:
          autoAcceptOrders ?? this.autoAcceptOrders,
      defaultPreparationTimeMinutes:
          defaultPreparationTimeMinutes ??
          this.defaultPreparationTimeMinutes,
      hasOriginalMenuImages:
          hasOriginalMenuImages ??
          this.hasOriginalMenuImages,
      hasDigitalMenu:
          hasDigitalMenu ?? this.hasDigitalMenu,
      menuVerifiedByOwner:
          menuVerifiedByOwner ??
          this.menuVerifiedByOwner,
      menuApprovedByAdmin:
          menuApprovedByAdmin ??
          this.menuApprovedByAdmin,
      menuLastUpdatedAt: clearMenuLastUpdatedAt
          ? null
          : menuLastUpdatedAt ?? this.menuLastUpdatedAt,
      ownerCnicFrontUrl:
          ownerCnicFrontUrl ?? this.ownerCnicFrontUrl,
      ownerCnicBackUrl:
          ownerCnicBackUrl ?? this.ownerCnicBackUrl,
      restaurantFrontImageUrl:
          restaurantFrontImageUrl ??
          this.restaurantFrontImageUrl,
      restaurantLicenseUrl:
          restaurantLicenseUrl ??
          this.restaurantLicenseUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      approvedAt: clearApprovedAt
          ? null
          : approvedAt ?? this.approvedAt,
    );
  }

  // ===========================================================
  // MAP CONVERSION
  // ===========================================================

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'ownerId': ownerId,
      'name': name,
      'description': description,
      'phoneNumber': phoneNumber,
      'email': email,
      'logoUrl': logoUrl,
      'coverImageUrl': coverImageUrl,
      'originalMenuImageUrls': originalMenuImageUrls,
      'address': address,
      'city': city,
      'area': area,
      'landmark': landmark,
      'latitude': latitude,
      'longitude': longitude,
      'categories': categories,
      'foodTypes': foodTypes,
      'rating': rating,
      'totalReviews': totalReviews,
      'totalOrders': totalOrders,
      'deliveryFee': deliveryFee,
      'minimumOrderAmount': minimumOrderAmount,
      'minimumDeliveryTimeMinutes':
          minimumDeliveryTimeMinutes,
      'maximumDeliveryTimeMinutes':
          maximumDeliveryTimeMinutes,
      'maximumDeliveryDistanceKm':
          maximumDeliveryDistanceKm,
      'isFreeDeliveryAvailable':
          isFreeDeliveryAvailable,
      'openingTime': openingTime,
      'closingTime': closingTime,
      'openDays': openDays,
      'isOpen': isOpen,
      'isBusy': isBusy,
      'isTemporarilyClosed': isTemporarilyClosed,
      'temporaryClosingReason': temporaryClosingReason,
      'approvalStatus': approvalStatus.name,
      'isApproved': isApproved,
      'isActive': isActive,
      'isSuspended': isSuspended,
      'rejectionReason': rejectionReason,
      'suspensionReason': suspensionReason,
      'isFeatured': isFeatured,
      'isPopular': isPopular,
      'isSponsored': isSponsored,
      'discountPercentage': discountPercentage,
      'discountTitle': discountTitle,
      'commissionPercentage': commissionPercentage,
      'acceptsCash': acceptsCash,
      'acceptsWallet': acceptsWallet,
      'acceptsJazzCash': acceptsJazzCash,
      'acceptsEasypaisa': acceptsEasypaisa,
      'autoAcceptOrders': autoAcceptOrders,
      'defaultPreparationTimeMinutes':
          defaultPreparationTimeMinutes,
      'hasOriginalMenuImages': hasOriginalMenuImages,
      'hasDigitalMenu': hasDigitalMenu,
      'menuVerifiedByOwner': menuVerifiedByOwner,
      'menuApprovedByAdmin': menuApprovedByAdmin,
      'menuLastUpdatedAt':
          menuLastUpdatedAt?.toIso8601String(),
      'ownerCnicFrontUrl': ownerCnicFrontUrl,
      'ownerCnicBackUrl': ownerCnicBackUrl,
      'restaurantFrontImageUrl':
          restaurantFrontImageUrl,
      'restaurantLicenseUrl': restaurantLicenseUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
    };
  }

  factory RestaurantModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return RestaurantModel(
      id: _stringValue(map['id']),
      ownerId: _stringValue(map['ownerId']),
      name: _stringValue(map['name']),
      description: _stringValue(map['description']),
      phoneNumber: _stringValue(map['phoneNumber']),
      email: _stringValue(map['email']),
      logoUrl: _stringValue(map['logoUrl']),
      coverImageUrl: _stringValue(map['coverImageUrl']),
      originalMenuImageUrls:
          _stringListValue(map['originalMenuImageUrls']),
      address: _stringValue(map['address']),
      city: _stringValue(
        map['city'],
        fallback: 'Swat',
      ),
      area: _stringValue(map['area']),
      landmark: _stringValue(map['landmark']),
      latitude: _doubleValue(map['latitude']),
      longitude: _doubleValue(map['longitude']),
      categories: _stringListValue(map['categories']),
      foodTypes: _stringListValue(map['foodTypes']),
      rating: _doubleValue(map['rating']),
      totalReviews: _intValue(map['totalReviews']),
      totalOrders: _intValue(map['totalOrders']),
      deliveryFee: _doubleValue(map['deliveryFee']),
      minimumOrderAmount:
          _doubleValue(map['minimumOrderAmount']),
      minimumDeliveryTimeMinutes: _intValue(
        map['minimumDeliveryTimeMinutes'],
        fallback: 20,
      ),
      maximumDeliveryTimeMinutes: _intValue(
        map['maximumDeliveryTimeMinutes'],
        fallback: 40,
      ),
      maximumDeliveryDistanceKm: _doubleValue(
        map['maximumDeliveryDistanceKm'],
        fallback: 10.0,
      ),
      isFreeDeliveryAvailable:
          _boolValue(map['isFreeDeliveryAvailable']),
      openingTime: _stringValue(
        map['openingTime'],
        fallback: '09:00',
      ),
      closingTime: _stringValue(
        map['closingTime'],
        fallback: '23:00',
      ),
      openDays: _intListValue(
        map['openDays'],
        fallback: const <int>[1, 2, 3, 4, 5, 6, 7],
      ),
      isOpen: _boolValue(map['isOpen']),
      isBusy: _boolValue(map['isBusy']),
      isTemporarilyClosed:
          _boolValue(map['isTemporarilyClosed']),
      temporaryClosingReason:
          _stringValue(map['temporaryClosingReason']),
      approvalStatus:
          RestaurantApprovalStatusX.fromValue(
        map['approvalStatus'],
      ),
      isApproved: _boolValue(map['isApproved']),
      isActive: _boolValue(map['isActive']),
      isSuspended: _boolValue(map['isSuspended']),
      rejectionReason:
          _stringValue(map['rejectionReason']),
      suspensionReason:
          _stringValue(map['suspensionReason']),
      isFeatured: _boolValue(map['isFeatured']),
      isPopular: _boolValue(map['isPopular']),
      isSponsored: _boolValue(map['isSponsored']),
      discountPercentage:
          _doubleValue(map['discountPercentage']),
      discountTitle:
          _stringValue(map['discountTitle']),
      commissionPercentage:
          _doubleValue(map['commissionPercentage']),
      acceptsCash: _boolValue(
        map['acceptsCash'],
        fallback: true,
      ),
      acceptsWallet: _boolValue(
        map['acceptsWallet'],
        fallback: true,
      ),
      acceptsJazzCash:
          _boolValue(map['acceptsJazzCash']),
      acceptsEasypaisa:
          _boolValue(map['acceptsEasypaisa']),
      autoAcceptOrders:
          _boolValue(map['autoAcceptOrders']),
      defaultPreparationTimeMinutes: _intValue(
        map['defaultPreparationTimeMinutes'],
        fallback: 25,
      ),
      hasOriginalMenuImages:
          _boolValue(map['hasOriginalMenuImages']),
      hasDigitalMenu:
          _boolValue(map['hasDigitalMenu']),
      menuVerifiedByOwner:
          _boolValue(map['menuVerifiedByOwner']),
      menuApprovedByAdmin:
          _boolValue(map['menuApprovedByAdmin']),
      menuLastUpdatedAt:
          _dateTimeValue(map['menuLastUpdatedAt']),
      ownerCnicFrontUrl:
          _stringValue(map['ownerCnicFrontUrl']),
      ownerCnicBackUrl:
          _stringValue(map['ownerCnicBackUrl']),
      restaurantFrontImageUrl:
          _stringValue(map['restaurantFrontImageUrl']),
      restaurantLicenseUrl:
          _stringValue(map['restaurantLicenseUrl']),
      createdAt:
          _dateTimeValue(map['createdAt']) ??
          DateTime.now(),
      updatedAt:
          _dateTimeValue(map['updatedAt']) ??
          DateTime.now(),
      approvedAt: _dateTimeValue(map['approvedAt']),
    );
  }

  // ===========================================================
  // SAFE PARSING HELPERS
  // ===========================================================

  static String _stringValue(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) {
      return fallback;
    }

    final String parsed = value.toString().trim();

    if (parsed.isEmpty) {
      return fallback;
    }

    return parsed;
  }

  static double _doubleValue(
    dynamic value, {
    double fallback = 0.0,
  }) {
    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        fallback;
  }

  static int _intValue(
    dynamic value, {
    int fallback = 0,
  }) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        fallback;
  }

  static bool _boolValue(
    dynamic value, {
    bool fallback = false,
  }) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final String parsed =
        value?.toString().trim().toLowerCase() ?? '';

    if (parsed == 'true' ||
        parsed == '1' ||
        parsed == 'yes') {
      return true;
    }

    if (parsed == 'false' ||
        parsed == '0' ||
        parsed == 'no') {
      return false;
    }

    return fallback;
  }

  static List<String> _stringListValue(
    dynamic value,
  ) {
    if (value is! List) {
      return const <String>[];
    }

    return value
        .map((dynamic item) => item.toString().trim())
        .where((String item) => item.isNotEmpty)
        .toList();
  }

  static List<int> _intListValue(
    dynamic value, {
    List<int> fallback = const <int>[],
  }) {
    if (value is! List) {
      return fallback;
    }

    final List<int> result = value
        .map((dynamic item) {
          if (item is int) {
            return item;
          }

          if (item is num) {
            return item.toInt();
          }

          return int.tryParse(item.toString());
        })
        .whereType<int>()
        .where((int item) => item >= 1 && item <= 7)
        .toSet()
        .toList();

    result.sort();

    return result.isEmpty ? fallback : result;
  }

  static DateTime? _dateTimeValue(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    // Supports Firebase Timestamp without importing
    // cloud_firestore directly into this model.
    try {
      final dynamic converted = value.toDate();

      if (converted is DateTime) {
        return converted;
      }
    } catch (_) {
      // Ignore and continue with string parsing.
    }

    return DateTime.tryParse(value.toString());
  }

  // ===========================================================
  // OBJECT COMPARISON
  // ===========================================================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is RestaurantModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'RestaurantModel('
        'id: $id, '
        'name: $name, '
        'approvalStatus: ${approvalStatus.name}, '
        'isOpen: $isOpen'
        ')';
  }
}

// =============================================================
// RESTAURANT APPROVAL STATUS
// =============================================================

enum RestaurantApprovalStatus {
  draft,
  pending,
  underReview,
  approved,
  rejected,
  suspended,
}

// =============================================================
// RESTAURANT APPROVAL STATUS HELPERS
// =============================================================

extension RestaurantApprovalStatusX
    on RestaurantApprovalStatus {
  String get displayName {
    switch (this) {
      case RestaurantApprovalStatus.draft:
        return 'Draft';

      case RestaurantApprovalStatus.pending:
        return 'Pending Approval';

      case RestaurantApprovalStatus.underReview:
        return 'Under Review';

      case RestaurantApprovalStatus.approved:
        return 'Approved';

      case RestaurantApprovalStatus.rejected:
        return 'Rejected';

      case RestaurantApprovalStatus.suspended:
        return 'Suspended';
    }
  }

  static RestaurantApprovalStatus fromValue(
    dynamic value,
  ) {
    final String normalized =
        value?.toString().trim().toLowerCase() ?? '';

    switch (normalized) {
      case 'draft':
        return RestaurantApprovalStatus.draft;

      case 'underreview':
      case 'under_review':
      case 'under review':
        return RestaurantApprovalStatus.underReview;

      case 'approved':
        return RestaurantApprovalStatus.approved;

      case 'rejected':
        return RestaurantApprovalStatus.rejected;

      case 'suspended':
        return RestaurantApprovalStatus.suspended;

      case 'pending':
      default:
        return RestaurantApprovalStatus.pending;
    }
  }
}