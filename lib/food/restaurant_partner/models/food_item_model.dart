// lib/food/restaurant_partner/models/food_item_model.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Restaurant Partner Food Item Model
//
// Important:
// This class is named RestaurantFoodItemModel so it does not
// conflict with the existing customer-side MenuItemModel.
//
// Used by:
// - Restaurant Partner menu management
// - Add/Edit food item screens
// - Food item Firestore service
// - Menu preview
// - Customer menu synchronization
// =============================================================

enum RestaurantFoodItemStatus {
  draft,
  pendingApproval,
  active,
  outOfStock,
  hidden,
  rejected,
}

extension RestaurantFoodItemStatusX
    on RestaurantFoodItemStatus {
  String get value {
    switch (this) {
      case RestaurantFoodItemStatus.draft:
        return 'draft';
      case RestaurantFoodItemStatus.pendingApproval:
        return 'pending_approval';
      case RestaurantFoodItemStatus.active:
        return 'active';
      case RestaurantFoodItemStatus.outOfStock:
        return 'out_of_stock';
      case RestaurantFoodItemStatus.hidden:
        return 'hidden';
      case RestaurantFoodItemStatus.rejected:
        return 'rejected';
    }
  }

  static RestaurantFoodItemStatus fromValue(
    dynamic value,
  ) {
    final String normalized =
        value?.toString().trim().toLowerCase() ?? '';

    switch (normalized) {
      case 'draft':
        return RestaurantFoodItemStatus.draft;
      case 'pendingapproval':
      case 'pending_approval':
      case 'pending approval':
        return RestaurantFoodItemStatus.pendingApproval;
      case 'active':
        return RestaurantFoodItemStatus.active;
      case 'outofstock':
      case 'out_of_stock':
      case 'out of stock':
        return RestaurantFoodItemStatus.outOfStock;
      case 'hidden':
        return RestaurantFoodItemStatus.hidden;
      case 'rejected':
        return RestaurantFoodItemStatus.rejected;
      default:
        return RestaurantFoodItemStatus.draft;
    }
  }
}

enum RestaurantFoodType {
  vegetarian,
  nonVegetarian,
  vegan,
  egg,
  other,
}

extension RestaurantFoodTypeX on RestaurantFoodType {
  String get value {
    switch (this) {
      case RestaurantFoodType.vegetarian:
        return 'vegetarian';
      case RestaurantFoodType.nonVegetarian:
        return 'non_vegetarian';
      case RestaurantFoodType.vegan:
        return 'vegan';
      case RestaurantFoodType.egg:
        return 'egg';
      case RestaurantFoodType.other:
        return 'other';
    }
  }

  static RestaurantFoodType fromValue(dynamic value) {
    final String normalized =
        value?.toString().trim().toLowerCase() ?? '';

    switch (normalized) {
      case 'vegetarian':
      case 'veg':
        return RestaurantFoodType.vegetarian;
      case 'nonvegetarian':
      case 'non_vegetarian':
      case 'non-vegetarian':
      case 'non veg':
        return RestaurantFoodType.nonVegetarian;
      case 'vegan':
        return RestaurantFoodType.vegan;
      case 'egg':
        return RestaurantFoodType.egg;
      default:
        return RestaurantFoodType.other;
    }
  }
}

class RestaurantFoodVariantModel {
  final String id;
  final String name;
  final double price;
  final bool isDefault;
  final bool isAvailable;
  final int sortOrder;

  const RestaurantFoodVariantModel({
    required this.id,
    required this.name,
    required this.price,
    required this.isDefault,
    required this.isAvailable,
    required this.sortOrder,
  });

  factory RestaurantFoodVariantModel.empty() {
    return const RestaurantFoodVariantModel(
      id: '',
      name: '',
      price: 0,
      isDefault: false,
      isAvailable: true,
      sortOrder: 0,
    );
  }

  RestaurantFoodVariantModel copyWith({
    String? id,
    String? name,
    double? price,
    bool? isDefault,
    bool? isAvailable,
    int? sortOrder,
  }) {
    return RestaurantFoodVariantModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      isDefault: isDefault ?? this.isDefault,
      isAvailable: isAvailable ?? this.isAvailable,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'price': price,
      'isDefault': isDefault,
      'isAvailable': isAvailable,
      'sortOrder': sortOrder,
    };
  }

  factory RestaurantFoodVariantModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return RestaurantFoodVariantModel(
      id: _FoodItemParser.stringValue(map['id']),
      name: _FoodItemParser.stringValue(map['name']),
      price: _FoodItemParser.doubleValue(map['price']),
      isDefault:
          _FoodItemParser.boolValue(map['isDefault']),
      isAvailable: _FoodItemParser.boolValue(
        map['isAvailable'],
        fallback: true,
      ),
      sortOrder:
          _FoodItemParser.intValue(map['sortOrder']),
    );
  }
}

class RestaurantFoodAddOnModel {
  final String id;
  final String name;
  final double price;
  final bool isRequired;
  final bool isAvailable;
  final int maximumQuantity;
  final int sortOrder;

  const RestaurantFoodAddOnModel({
    required this.id,
    required this.name,
    required this.price,
    required this.isRequired,
    required this.isAvailable,
    required this.maximumQuantity,
    required this.sortOrder,
  });

  factory RestaurantFoodAddOnModel.empty() {
    return const RestaurantFoodAddOnModel(
      id: '',
      name: '',
      price: 0,
      isRequired: false,
      isAvailable: true,
      maximumQuantity: 1,
      sortOrder: 0,
    );
  }

  RestaurantFoodAddOnModel copyWith({
    String? id,
    String? name,
    double? price,
    bool? isRequired,
    bool? isAvailable,
    int? maximumQuantity,
    int? sortOrder,
  }) {
    return RestaurantFoodAddOnModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      isRequired: isRequired ?? this.isRequired,
      isAvailable: isAvailable ?? this.isAvailable,
      maximumQuantity:
          maximumQuantity ?? this.maximumQuantity,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'price': price,
      'isRequired': isRequired,
      'isAvailable': isAvailable,
      'maximumQuantity': maximumQuantity,
      'sortOrder': sortOrder,
    };
  }

  factory RestaurantFoodAddOnModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return RestaurantFoodAddOnModel(
      id: _FoodItemParser.stringValue(map['id']),
      name: _FoodItemParser.stringValue(map['name']),
      price: _FoodItemParser.doubleValue(map['price']),
      isRequired:
          _FoodItemParser.boolValue(map['isRequired']),
      isAvailable: _FoodItemParser.boolValue(
        map['isAvailable'],
        fallback: true,
      ),
      maximumQuantity: _FoodItemParser.intValue(
        map['maximumQuantity'],
        fallback: 1,
      ),
      sortOrder:
          _FoodItemParser.intValue(map['sortOrder']),
    );
  }
}

class RestaurantFoodItemModel {
  // ===========================================================
  // IDENTIFIERS
  // ===========================================================

  final String id;
  final String restaurantId;
  final String partnerId;
  final String categoryId;

  // ===========================================================
  // BASIC INFORMATION
  // ===========================================================

  final String name;
  final String description;
  final String shortDescription;

  final RestaurantFoodType foodType;
  final String spiceLevel;

  final List<String> ingredients;
  final List<String> allergens;
  final List<String> tags;

  // ===========================================================
  // IMAGES
  // ===========================================================

  final String mainImageUrl;
  final String mainLocalImagePath;
  final List<String> imageUrls;
  final List<String> localImagePaths;

  // ===========================================================
  // PRICING
  // ===========================================================

  final double originalPrice;
  final double discountedPrice;
  final double discountPercentage;
  final bool hasDiscount;

  // ===========================================================
  // VARIANTS AND ADD-ONS
  // ===========================================================

  final List<RestaurantFoodVariantModel> variants;
  final List<RestaurantFoodAddOnModel> addOns;

  // ===========================================================
  // SERVING INFORMATION
  // ===========================================================

  final String servingSize;
  final String weightText;
  final int preparationTimeMinutes;

  // ===========================================================
  // STOCK
  // ===========================================================

  final bool trackStock;
  final int dailyStockQuantity;
  final int remainingStockQuantity;

  // ===========================================================
  // STATUS AND VISIBILITY
  // ===========================================================

  final RestaurantFoodItemStatus status;

  final bool isAvailable;
  final bool isVisible;
  final bool isFeatured;
  final bool isPopular;
  final bool isRecommended;

  final bool approvedByAdmin;
  final String rejectionReason;

  // ===========================================================
  // PROMOTION
  // ===========================================================

  final bool promoEligible;
  final List<String> promoCodeIds;

  // ===========================================================
  // STATISTICS
  // ===========================================================

  final double rating;
  final int totalReviews;
  final int totalLikes;
  final int totalOrders;

  // ===========================================================
  // SORTING AND AUDIT
  // ===========================================================

  final int sortOrder;
  final String createdBy;

  final DateTime createdAt;
  final DateTime updatedAt;

  const RestaurantFoodItemModel({
    required this.id,
    required this.restaurantId,
    required this.partnerId,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.shortDescription,
    required this.foodType,
    required this.spiceLevel,
    required this.ingredients,
    required this.allergens,
    required this.tags,
    required this.mainImageUrl,
    required this.mainLocalImagePath,
    required this.imageUrls,
    required this.localImagePaths,
    required this.originalPrice,
    required this.discountedPrice,
    required this.discountPercentage,
    required this.hasDiscount,
    required this.variants,
    required this.addOns,
    required this.servingSize,
    required this.weightText,
    required this.preparationTimeMinutes,
    required this.trackStock,
    required this.dailyStockQuantity,
    required this.remainingStockQuantity,
    required this.status,
    required this.isAvailable,
    required this.isVisible,
    required this.isFeatured,
    required this.isPopular,
    required this.isRecommended,
    required this.approvedByAdmin,
    required this.rejectionReason,
    required this.promoEligible,
    required this.promoCodeIds,
    required this.rating,
    required this.totalReviews,
    required this.totalLikes,
    required this.totalOrders,
    required this.sortOrder,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RestaurantFoodItemModel.empty({
    String restaurantId = '',
    String partnerId = '',
    String categoryId = '',
    String createdBy = '',
  }) {
    final DateTime now = DateTime.now();

    return RestaurantFoodItemModel(
      id: '',
      restaurantId: restaurantId,
      partnerId: partnerId,
      categoryId: categoryId,
      name: '',
      description: '',
      shortDescription: '',
      foodType: RestaurantFoodType.other,
      spiceLevel: 'none',
      ingredients: const <String>[],
      allergens: const <String>[],
      tags: const <String>[],
      mainImageUrl: '',
      mainLocalImagePath: '',
      imageUrls: const <String>[],
      localImagePaths: const <String>[],
      originalPrice: 0,
      discountedPrice: 0,
      discountPercentage: 0,
      hasDiscount: false,
      variants: const <RestaurantFoodVariantModel>[],
      addOns: const <RestaurantFoodAddOnModel>[],
      servingSize: '',
      weightText: '',
      preparationTimeMinutes: 20,
      trackStock: false,
      dailyStockQuantity: -1,
      remainingStockQuantity: -1,
      status: RestaurantFoodItemStatus.draft,
      isAvailable: true,
      isVisible: true,
      isFeatured: false,
      isPopular: false,
      isRecommended: false,
      approvedByAdmin: false,
      rejectionReason: '',
      promoEligible: true,
      promoCodeIds: const <String>[],
      rating: 0,
      totalReviews: 0,
      totalLikes: 0,
      totalOrders: 0,
      sortOrder: 0,
      createdBy: createdBy,
      createdAt: now,
      updatedAt: now,
    );
  }

  // ===========================================================
  // BUSINESS HELPERS
  // ===========================================================

  double get effectivePrice {
    if (hasDiscount &&
        discountedPrice > 0 &&
        discountedPrice < originalPrice) {
      return discountedPrice;
    }

    return originalPrice;
  }

  bool get hasImages {
    return mainImageUrl.trim().isNotEmpty ||
        mainLocalImagePath.trim().isNotEmpty ||
        imageUrls.isNotEmpty ||
        localImagePaths.isNotEmpty;
  }

  bool get hasVariants => variants.isNotEmpty;

  bool get hasAddOns => addOns.isNotEmpty;

  bool get hasLimitedStock {
    return trackStock && remainingStockQuantity >= 0;
  }

  bool get isOutOfStock {
    return status == RestaurantFoodItemStatus.outOfStock ||
        (hasLimitedStock && remainingStockQuantity <= 0);
  }

  bool get canShowToCustomer {
    return isVisible &&
        isAvailable &&
        approvedByAdmin &&
        !isOutOfStock &&
        status == RestaurantFoodItemStatus.active;
  }

  String get priceText {
    return 'Rs. ${effectivePrice.toStringAsFixed(0)}';
  }

  String get originalPriceText {
    return 'Rs. ${originalPrice.toStringAsFixed(0)}';
  }

  String get discountText {
    if (!hasDiscount || discountPercentage <= 0) {
      return '';
    }

    return '${discountPercentage.toStringAsFixed(0)}% OFF';
  }

  String get stockText {
    if (!trackStock) {
      return 'Stock not tracked';
    }

    if (remainingStockQuantity <= 0) {
      return 'Out of stock';
    }

    return '$remainingStockQuantity remaining';
  }

  RestaurantFoodVariantModel? get defaultVariant {
    for (final RestaurantFoodVariantModel variant
        in variants) {
      if (variant.isDefault && variant.isAvailable) {
        return variant;
      }
    }

    for (final RestaurantFoodVariantModel variant
        in variants) {
      if (variant.isAvailable) {
        return variant;
      }
    }

    return null;
  }

  // ===========================================================
  // COPY WITH
  // ===========================================================

  RestaurantFoodItemModel copyWith({
    String? id,
    String? restaurantId,
    String? partnerId,
    String? categoryId,
    String? name,
    String? description,
    String? shortDescription,
    RestaurantFoodType? foodType,
    String? spiceLevel,
    List<String>? ingredients,
    List<String>? allergens,
    List<String>? tags,
    String? mainImageUrl,
    String? mainLocalImagePath,
    List<String>? imageUrls,
    List<String>? localImagePaths,
    double? originalPrice,
    double? discountedPrice,
    double? discountPercentage,
    bool? hasDiscount,
    List<RestaurantFoodVariantModel>? variants,
    List<RestaurantFoodAddOnModel>? addOns,
    String? servingSize,
    String? weightText,
    int? preparationTimeMinutes,
    bool? trackStock,
    int? dailyStockQuantity,
    int? remainingStockQuantity,
    RestaurantFoodItemStatus? status,
    bool? isAvailable,
    bool? isVisible,
    bool? isFeatured,
    bool? isPopular,
    bool? isRecommended,
    bool? approvedByAdmin,
    String? rejectionReason,
    bool? promoEligible,
    List<String>? promoCodeIds,
    double? rating,
    int? totalReviews,
    int? totalLikes,
    int? totalOrders,
    int? sortOrder,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RestaurantFoodItemModel(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      partnerId: partnerId ?? this.partnerId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      shortDescription:
          shortDescription ?? this.shortDescription,
      foodType: foodType ?? this.foodType,
      spiceLevel: spiceLevel ?? this.spiceLevel,
      ingredients: ingredients ?? this.ingredients,
      allergens: allergens ?? this.allergens,
      tags: tags ?? this.tags,
      mainImageUrl: mainImageUrl ?? this.mainImageUrl,
      mainLocalImagePath:
          mainLocalImagePath ?? this.mainLocalImagePath,
      imageUrls: imageUrls ?? this.imageUrls,
      localImagePaths:
          localImagePaths ?? this.localImagePaths,
      originalPrice: originalPrice ?? this.originalPrice,
      discountedPrice:
          discountedPrice ?? this.discountedPrice,
      discountPercentage:
          discountPercentage ?? this.discountPercentage,
      hasDiscount: hasDiscount ?? this.hasDiscount,
      variants: variants ?? this.variants,
      addOns: addOns ?? this.addOns,
      servingSize: servingSize ?? this.servingSize,
      weightText: weightText ?? this.weightText,
      preparationTimeMinutes:
          preparationTimeMinutes ??
              this.preparationTimeMinutes,
      trackStock: trackStock ?? this.trackStock,
      dailyStockQuantity:
          dailyStockQuantity ?? this.dailyStockQuantity,
      remainingStockQuantity:
          remainingStockQuantity ??
              this.remainingStockQuantity,
      status: status ?? this.status,
      isAvailable: isAvailable ?? this.isAvailable,
      isVisible: isVisible ?? this.isVisible,
      isFeatured: isFeatured ?? this.isFeatured,
      isPopular: isPopular ?? this.isPopular,
      isRecommended:
          isRecommended ?? this.isRecommended,
      approvedByAdmin:
          approvedByAdmin ?? this.approvedByAdmin,
      rejectionReason:
          rejectionReason ?? this.rejectionReason,
      promoEligible:
          promoEligible ?? this.promoEligible,
      promoCodeIds: promoCodeIds ?? this.promoCodeIds,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      totalLikes: totalLikes ?? this.totalLikes,
      totalOrders: totalOrders ?? this.totalOrders,
      sortOrder: sortOrder ?? this.sortOrder,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ===========================================================
  // FIRESTORE CONVERSION
  // ===========================================================

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'restaurantId': restaurantId,
      'partnerId': partnerId,
      'categoryId': categoryId,
      'name': name,
      'description': description,
      'shortDescription': shortDescription,
      'foodType': foodType.value,
      'spiceLevel': spiceLevel,
      'ingredients': ingredients,
      'allergens': allergens,
      'tags': tags,
      'mainImageUrl': mainImageUrl,
      'mainLocalImagePath': mainLocalImagePath,
      'imageUrls': imageUrls,
      'localImagePaths': localImagePaths,
      'originalPrice': originalPrice,
      'discountedPrice': discountedPrice,
      'discountPercentage': discountPercentage,
      'hasDiscount': hasDiscount,
      'variants': variants
          .map(
            (RestaurantFoodVariantModel variant) =>
                variant.toMap(),
          )
          .toList(),
      'addOns': addOns
          .map(
            (RestaurantFoodAddOnModel addOn) =>
                addOn.toMap(),
          )
          .toList(),
      'servingSize': servingSize,
      'weightText': weightText,
      'preparationTimeMinutes':
          preparationTimeMinutes,
      'trackStock': trackStock,
      'dailyStockQuantity': dailyStockQuantity,
      'remainingStockQuantity':
          remainingStockQuantity,
      'status': status.value,
      'isAvailable': isAvailable,
      'isVisible': isVisible,
      'isFeatured': isFeatured,
      'isPopular': isPopular,
      'isRecommended': isRecommended,
      'approvedByAdmin': approvedByAdmin,
      'rejectionReason': rejectionReason,
      'promoEligible': promoEligible,
      'promoCodeIds': promoCodeIds,
      'rating': rating,
      'totalReviews': totalReviews,
      'totalLikes': totalLikes,
      'totalOrders': totalOrders,
      'sortOrder': sortOrder,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory RestaurantFoodItemModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return RestaurantFoodItemModel(
      id: _FoodItemParser.stringValue(map['id']),
      restaurantId:
          _FoodItemParser.stringValue(map['restaurantId']),
      partnerId:
          _FoodItemParser.stringValue(map['partnerId']),
      categoryId:
          _FoodItemParser.stringValue(map['categoryId']),
      name: _FoodItemParser.stringValue(map['name']),
      description:
          _FoodItemParser.stringValue(map['description']),
      shortDescription: _FoodItemParser.stringValue(
        map['shortDescription'],
      ),
      foodType:
          RestaurantFoodTypeX.fromValue(map['foodType']),
      spiceLevel: _FoodItemParser.stringValue(
        map['spiceLevel'],
        fallback: 'none',
      ),
      ingredients:
          _FoodItemParser.stringList(map['ingredients']),
      allergens:
          _FoodItemParser.stringList(map['allergens']),
      tags: _FoodItemParser.stringList(map['tags']),
      mainImageUrl:
          _FoodItemParser.stringValue(map['mainImageUrl']),
      mainLocalImagePath: _FoodItemParser.stringValue(
        map['mainLocalImagePath'],
      ),
      imageUrls:
          _FoodItemParser.stringList(map['imageUrls']),
      localImagePaths:
          _FoodItemParser.stringList(
        map['localImagePaths'],
      ),
      originalPrice:
          _FoodItemParser.doubleValue(map['originalPrice']),
      discountedPrice: _FoodItemParser.doubleValue(
        map['discountedPrice'],
      ),
      discountPercentage: _FoodItemParser.doubleValue(
        map['discountPercentage'],
      ),
      hasDiscount:
          _FoodItemParser.boolValue(map['hasDiscount']),
      variants: _FoodItemParser.mapList(map['variants'])
          .map(RestaurantFoodVariantModel.fromMap)
          .toList(),
      addOns: _FoodItemParser.mapList(map['addOns'])
          .map(RestaurantFoodAddOnModel.fromMap)
          .toList(),
      servingSize:
          _FoodItemParser.stringValue(map['servingSize']),
      weightText:
          _FoodItemParser.stringValue(map['weightText']),
      preparationTimeMinutes:
          _FoodItemParser.intValue(
        map['preparationTimeMinutes'],
        fallback: 20,
      ),
      trackStock:
          _FoodItemParser.boolValue(map['trackStock']),
      dailyStockQuantity:
          _FoodItemParser.intValue(
        map['dailyStockQuantity'],
        fallback: -1,
      ),
      remainingStockQuantity:
          _FoodItemParser.intValue(
        map['remainingStockQuantity'],
        fallback: -1,
      ),
      status: RestaurantFoodItemStatusX.fromValue(
        map['status'],
      ),
      isAvailable: _FoodItemParser.boolValue(
        map['isAvailable'],
        fallback: true,
      ),
      isVisible: _FoodItemParser.boolValue(
        map['isVisible'],
        fallback: true,
      ),
      isFeatured:
          _FoodItemParser.boolValue(map['isFeatured']),
      isPopular:
          _FoodItemParser.boolValue(map['isPopular']),
      isRecommended:
          _FoodItemParser.boolValue(
        map['isRecommended'],
      ),
      approvedByAdmin:
          _FoodItemParser.boolValue(
        map['approvedByAdmin'],
      ),
      rejectionReason:
          _FoodItemParser.stringValue(
        map['rejectionReason'],
      ),
      promoEligible: _FoodItemParser.boolValue(
        map['promoEligible'],
        fallback: true,
      ),
      promoCodeIds:
          _FoodItemParser.stringList(
        map['promoCodeIds'],
      ),
      rating:
          _FoodItemParser.doubleValue(map['rating']),
      totalReviews:
          _FoodItemParser.intValue(map['totalReviews']),
      totalLikes:
          _FoodItemParser.intValue(map['totalLikes']),
      totalOrders:
          _FoodItemParser.intValue(map['totalOrders']),
      sortOrder:
          _FoodItemParser.intValue(map['sortOrder']),
      createdBy:
          _FoodItemParser.stringValue(map['createdBy']),
      createdAt:
          _FoodItemParser.dateTimeValue(map['createdAt']) ??
          DateTime.now(),
      updatedAt:
          _FoodItemParser.dateTimeValue(map['updatedAt']) ??
          DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is RestaurantFoodItemModel &&
        other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'RestaurantFoodItemModel('
        'id: $id, '
        'restaurantId: $restaurantId, '
        'name: $name, '
        'price: $effectivePrice, '
        'status: ${status.value}'
        ')';
  }
}

class _FoodItemParser {
  const _FoodItemParser._();

  static String stringValue(
    dynamic value, {
    String fallback = '',
  }) {
    final String parsed =
        value?.toString().trim() ?? '';

    return parsed.isEmpty ? fallback : parsed;
  }

  static int intValue(
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

  static double doubleValue(
    dynamic value, {
    double fallback = 0,
  }) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        fallback;
  }

  static bool boolValue(
    dynamic value, {
    bool fallback = false,
  }) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final String normalized =
        value?.toString().trim().toLowerCase() ?? '';

    if (normalized == 'true' ||
        normalized == '1' ||
        normalized == 'yes') {
      return true;
    }

    if (normalized == 'false' ||
        normalized == '0' ||
        normalized == 'no') {
      return false;
    }

    return fallback;
  }

  static List<String> stringList(dynamic value) {
    if (value is! List) {
      return const <String>[];
    }

    return value
        .map((dynamic item) => item.toString().trim())
        .where((String item) => item.isNotEmpty)
        .toList();
  }

  static List<Map<String, dynamic>> mapList(
    dynamic value,
  ) {
    if (value is! List) {
      return const <Map<String, dynamic>>[];
    }

    return value
        .whereType<Map>()
        .map(
          (Map item) =>
              Map<String, dynamic>.from(item),
        )
        .toList();
  }

  static DateTime? dateTimeValue(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    try {
      final dynamic converted = value.toDate();

      if (converted is DateTime) {
        return converted;
      }
    } catch (_) {
      // Supports Firestore Timestamp without importing it.
    }

    return DateTime.tryParse(value.toString());
  }
}
