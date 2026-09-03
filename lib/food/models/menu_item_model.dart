// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Digital Menu Item Model
//
// Used by:
// 1. Restaurant owner menu management
// 2. Customer restaurant menu
// 3. Cart and checkout
// 4. Food orders
// 5. Admin menu review
// 6. Menu photo-to-digital-menu workflow
// =============================================================

enum MenuItemAvailabilityStatus {
  available,
  outOfStock,
  hidden,
  pendingApproval,
  rejected,
}

extension MenuItemAvailabilityStatusX
    on MenuItemAvailabilityStatus {
  String get value {
    switch (this) {
      case MenuItemAvailabilityStatus.available:
        return 'available';
      case MenuItemAvailabilityStatus.outOfStock:
        return 'out_of_stock';
      case MenuItemAvailabilityStatus.hidden:
        return 'hidden';
      case MenuItemAvailabilityStatus.pendingApproval:
        return 'pending_approval';
      case MenuItemAvailabilityStatus.rejected:
        return 'rejected';
    }
  }

  String get displayName {
    switch (this) {
      case MenuItemAvailabilityStatus.available:
        return 'Available';
      case MenuItemAvailabilityStatus.outOfStock:
        return 'Out of stock';
      case MenuItemAvailabilityStatus.hidden:
        return 'Hidden';
      case MenuItemAvailabilityStatus.pendingApproval:
        return 'Pending approval';
      case MenuItemAvailabilityStatus.rejected:
        return 'Rejected';
    }
  }

  static MenuItemAvailabilityStatus fromValue(
    dynamic value,
  ) {
    final String normalized =
        value?.toString().trim().toLowerCase() ?? '';

    switch (normalized) {
      case 'available':
        return MenuItemAvailabilityStatus.available;
      case 'outofstock':
      case 'out_of_stock':
      case 'out of stock':
        return MenuItemAvailabilityStatus.outOfStock;
      case 'hidden':
        return MenuItemAvailabilityStatus.hidden;
      case 'pendingapproval':
      case 'pending_approval':
      case 'pending approval':
        return MenuItemAvailabilityStatus.pendingApproval;
      case 'rejected':
        return MenuItemAvailabilityStatus.rejected;
      default:
        return MenuItemAvailabilityStatus.available;
    }
  }
}

// =============================================================
// MENU ITEM VARIANT
//
// Examples:
// Regular, Large, Family
// Half, Full
// Small Pizza, Medium Pizza, Large Pizza
// =============================================================

class MenuItemVariantModel {
  final String id;
  final String name;

  // This is the complete price for this variant.
  final double price;

  final bool isDefault;
  final bool isAvailable;
  final int displayOrder;

  const MenuItemVariantModel({
    required this.id,
    required this.name,
    required this.price,
    required this.isDefault,
    required this.isAvailable,
    required this.displayOrder,
  });

  factory MenuItemVariantModel.empty() {
    return const MenuItemVariantModel(
      id: '',
      name: '',
      price: 0,
      isDefault: false,
      isAvailable: true,
      displayOrder: 0,
    );
  }

  MenuItemVariantModel copyWith({
    String? id,
    String? name,
    double? price,
    bool? isDefault,
    bool? isAvailable,
    int? displayOrder,
  }) {
    return MenuItemVariantModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      isDefault: isDefault ?? this.isDefault,
      isAvailable: isAvailable ?? this.isAvailable,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'price': price,
      'isDefault': isDefault,
      'isAvailable': isAvailable,
      'displayOrder': displayOrder,
    };
  }

  factory MenuItemVariantModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return MenuItemVariantModel(
      id: _ModelParser.stringValue(map['id']),
      name: _ModelParser.stringValue(map['name']),
      price: _ModelParser.doubleValue(map['price']),
      isDefault:
          _ModelParser.boolValue(map['isDefault']),
      isAvailable: _ModelParser.boolValue(
        map['isAvailable'],
        fallback: true,
      ),
      displayOrder:
          _ModelParser.intValue(map['displayOrder']),
    );
  }
}

// =============================================================
// MENU ITEM ADD-ON
//
// Examples:
// Extra cheese + Rs. 80
// Extra patty + Rs. 180
// Fries + Rs. 150
// Cold drink + Rs. 120
// =============================================================

class MenuItemAddOnModel {
  final String id;
  final String name;
  final double price;

  final bool isAvailable;
  final bool isRequired;
  final int maximumQuantity;
  final int displayOrder;

  const MenuItemAddOnModel({
    required this.id,
    required this.name,
    required this.price,
    required this.isAvailable,
    required this.isRequired,
    required this.maximumQuantity,
    required this.displayOrder,
  });

  factory MenuItemAddOnModel.empty() {
    return const MenuItemAddOnModel(
      id: '',
      name: '',
      price: 0,
      isAvailable: true,
      isRequired: false,
      maximumQuantity: 1,
      displayOrder: 0,
    );
  }

  MenuItemAddOnModel copyWith({
    String? id,
    String? name,
    double? price,
    bool? isAvailable,
    bool? isRequired,
    int? maximumQuantity,
    int? displayOrder,
  }) {
    return MenuItemAddOnModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      isAvailable: isAvailable ?? this.isAvailable,
      isRequired: isRequired ?? this.isRequired,
      maximumQuantity:
          maximumQuantity ?? this.maximumQuantity,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'price': price,
      'isAvailable': isAvailable,
      'isRequired': isRequired,
      'maximumQuantity': maximumQuantity,
      'displayOrder': displayOrder,
    };
  }

  factory MenuItemAddOnModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return MenuItemAddOnModel(
      id: _ModelParser.stringValue(map['id']),
      name: _ModelParser.stringValue(map['name']),
      price: _ModelParser.doubleValue(map['price']),
      isAvailable: _ModelParser.boolValue(
        map['isAvailable'],
        fallback: true,
      ),
      isRequired:
          _ModelParser.boolValue(map['isRequired']),
      maximumQuantity: _ModelParser.intValue(
        map['maximumQuantity'],
        fallback: 1,
      ),
      displayOrder:
          _ModelParser.intValue(map['displayOrder']),
    );
  }
}

// =============================================================
// MAIN MENU ITEM MODEL
// =============================================================

class MenuItemModel {
  // ===========================================================
  // IDENTIFIERS
  // ===========================================================

  final String id;
  final String restaurantId;
  final String categoryId;

  // ===========================================================
  // BASIC DETAILS
  // ===========================================================

  final String name;
  final String description;

  final String imageUrl;

  // Temporary local path while Firebase Storage is bypassed.
  //
  // This should not be treated as a permanent cloud URL.
  // It allows owner-side preview on the same device.
  final String localImagePath;

  // ===========================================================
  // PRICING
  // ===========================================================

  final double basePrice;
  final double discountedPrice;

  final bool hasDiscount;
  final double discountPercentage;

  // ===========================================================
  // OPTIONS
  // ===========================================================

  final List<MenuItemVariantModel> variants;
  final List<MenuItemAddOnModel> addOns;

  // ===========================================================
  // FOOD INFORMATION
  // ===========================================================

  final bool isVegetarian;
  final bool isSpicy;
  final bool isPopular;
  final bool isFeatured;

  final String spicyLevel;
  final List<String> ingredients;
  final List<String> allergens;

  // ===========================================================
  // AVAILABILITY
  // ===========================================================

  final MenuItemAvailabilityStatus availabilityStatus;

  final bool isAvailable;
  final bool isVisible;

  final int preparationTimeMinutes;
  final int dailyStockQuantity;

  // -1 means unlimited/not manually tracked.
  final int remainingStockQuantity;

  final int displayOrder;

  // ===========================================================
  // MENU PHOTO EXTRACTION
  // ===========================================================

  // True when item was initially created from an uploaded
  // restaurant menu photo.
  final bool createdFromMenuImage;

  // Text detected from the original menu image.
  final String extractedRawText;

  // Owner must verify OCR/extracted data before publishing.
  final bool verifiedByOwner;

  final bool approvedByAdmin;
  final String rejectionReason;

  // ===========================================================
  // STATISTICS
  // ===========================================================

  final double rating;
  final int totalReviews;
  final int totalOrders;

  // ===========================================================
  // TIMESTAMPS
  // ===========================================================

  final DateTime createdAt;
  final DateTime updatedAt;

  // ===========================================================
  // CONSTRUCTOR
  // ===========================================================

  const MenuItemModel({
    required this.id,
    required this.restaurantId,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.localImagePath,
    required this.basePrice,
    required this.discountedPrice,
    required this.hasDiscount,
    required this.discountPercentage,
    required this.variants,
    required this.addOns,
    required this.isVegetarian,
    required this.isSpicy,
    required this.isPopular,
    required this.isFeatured,
    required this.spicyLevel,
    required this.ingredients,
    required this.allergens,
    required this.availabilityStatus,
    required this.isAvailable,
    required this.isVisible,
    required this.preparationTimeMinutes,
    required this.dailyStockQuantity,
    required this.remainingStockQuantity,
    required this.displayOrder,
    required this.createdFromMenuImage,
    required this.extractedRawText,
    required this.verifiedByOwner,
    required this.approvedByAdmin,
    required this.rejectionReason,
    required this.rating,
    required this.totalReviews,
    required this.totalOrders,
    required this.createdAt,
    required this.updatedAt,
  });

  // ===========================================================
  // EMPTY MODEL
  // ===========================================================

  factory MenuItemModel.empty({
    String restaurantId = '',
    String categoryId = '',
  }) {
    final DateTime now = DateTime.now();

    return MenuItemModel(
      id: '',
      restaurantId: restaurantId,
      categoryId: categoryId,
      name: '',
      description: '',
      imageUrl: '',
      localImagePath: '',
      basePrice: 0,
      discountedPrice: 0,
      hasDiscount: false,
      discountPercentage: 0,
      variants: const <MenuItemVariantModel>[],
      addOns: const <MenuItemAddOnModel>[],
      isVegetarian: false,
      isSpicy: false,
      isPopular: false,
      isFeatured: false,
      spicyLevel: 'none',
      ingredients: const <String>[],
      allergens: const <String>[],
      availabilityStatus:
          MenuItemAvailabilityStatus.available,
      isAvailable: true,
      isVisible: true,
      preparationTimeMinutes: 20,
      dailyStockQuantity: -1,
      remainingStockQuantity: -1,
      displayOrder: 0,
      createdFromMenuImage: false,
      extractedRawText: '',
      verifiedByOwner: false,
      approvedByAdmin: false,
      rejectionReason: '',
      rating: 0,
      totalReviews: 0,
      totalOrders: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  // ===========================================================
  // DISPLAY AND BUSINESS HELPERS
  // ===========================================================

  double get effectivePrice {
    if (hasDiscount &&
        discountedPrice > 0 &&
        discountedPrice < basePrice) {
      return discountedPrice;
    }

    return basePrice;
  }

  bool get hasVariants => variants.isNotEmpty;

  bool get hasAddOns => addOns.isNotEmpty;

  bool get hasImage {
    return imageUrl.trim().isNotEmpty ||
        localImagePath.trim().isNotEmpty;
  }

  bool get hasLimitedStock {
    return remainingStockQuantity >= 0;
  }

  bool get isOutOfStock {
    if (availabilityStatus ==
        MenuItemAvailabilityStatus.outOfStock) {
      return true;
    }

    return hasLimitedStock && remainingStockQuantity <= 0;
  }

  bool get canBeOrdered {
    return isAvailable &&
        isVisible &&
        !isOutOfStock &&
        availabilityStatus ==
            MenuItemAvailabilityStatus.available &&
        verifiedByOwner;
  }

  String get priceText {
    return 'Rs. ${effectivePrice.toStringAsFixed(0)}';
  }

  String get originalPriceText {
    return 'Rs. ${basePrice.toStringAsFixed(0)}';
  }

  String get discountText {
    if (!hasDiscount || discountPercentage <= 0) {
      return '';
    }

    return '${discountPercentage.toStringAsFixed(0)}% OFF';
  }

  String get stockText {
    if (!hasLimitedStock) {
      return 'Available';
    }

    if (remainingStockQuantity <= 0) {
      return 'Out of stock';
    }

    return '$remainingStockQuantity remaining';
  }

  MenuItemVariantModel? get defaultVariant {
    for (final MenuItemVariantModel variant
        in variants) {
      if (variant.isDefault && variant.isAvailable) {
        return variant;
      }
    }

    for (final MenuItemVariantModel variant
        in variants) {
      if (variant.isAvailable) {
        return variant;
      }
    }

    return null;
  }

  double priceForVariant(
    MenuItemVariantModel? selectedVariant,
  ) {
    return selectedVariant?.price ?? effectivePrice;
  }

  // ===========================================================
  // COPY WITH
  // ===========================================================

  MenuItemModel copyWith({
    String? id,
    String? restaurantId,
    String? categoryId,
    String? name,
    String? description,
    String? imageUrl,
    String? localImagePath,
    double? basePrice,
    double? discountedPrice,
    bool? hasDiscount,
    double? discountPercentage,
    List<MenuItemVariantModel>? variants,
    List<MenuItemAddOnModel>? addOns,
    bool? isVegetarian,
    bool? isSpicy,
    bool? isPopular,
    bool? isFeatured,
    String? spicyLevel,
    List<String>? ingredients,
    List<String>? allergens,
    MenuItemAvailabilityStatus? availabilityStatus,
    bool? isAvailable,
    bool? isVisible,
    int? preparationTimeMinutes,
    int? dailyStockQuantity,
    int? remainingStockQuantity,
    int? displayOrder,
    bool? createdFromMenuImage,
    String? extractedRawText,
    bool? verifiedByOwner,
    bool? approvedByAdmin,
    String? rejectionReason,
    double? rating,
    int? totalReviews,
    int? totalOrders,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MenuItemModel(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      localImagePath:
          localImagePath ?? this.localImagePath,
      basePrice: basePrice ?? this.basePrice,
      discountedPrice:
          discountedPrice ?? this.discountedPrice,
      hasDiscount: hasDiscount ?? this.hasDiscount,
      discountPercentage:
          discountPercentage ?? this.discountPercentage,
      variants: variants ?? this.variants,
      addOns: addOns ?? this.addOns,
      isVegetarian:
          isVegetarian ?? this.isVegetarian,
      isSpicy: isSpicy ?? this.isSpicy,
      isPopular: isPopular ?? this.isPopular,
      isFeatured: isFeatured ?? this.isFeatured,
      spicyLevel: spicyLevel ?? this.spicyLevel,
      ingredients: ingredients ?? this.ingredients,
      allergens: allergens ?? this.allergens,
      availabilityStatus:
          availabilityStatus ?? this.availabilityStatus,
      isAvailable: isAvailable ?? this.isAvailable,
      isVisible: isVisible ?? this.isVisible,
      preparationTimeMinutes:
          preparationTimeMinutes ??
          this.preparationTimeMinutes,
      dailyStockQuantity:
          dailyStockQuantity ?? this.dailyStockQuantity,
      remainingStockQuantity:
          remainingStockQuantity ??
          this.remainingStockQuantity,
      displayOrder: displayOrder ?? this.displayOrder,
      createdFromMenuImage:
          createdFromMenuImage ??
          this.createdFromMenuImage,
      extractedRawText:
          extractedRawText ?? this.extractedRawText,
      verifiedByOwner:
          verifiedByOwner ?? this.verifiedByOwner,
      approvedByAdmin:
          approvedByAdmin ?? this.approvedByAdmin,
      rejectionReason:
          rejectionReason ?? this.rejectionReason,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      totalOrders: totalOrders ?? this.totalOrders,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ===========================================================
  // MAP CONVERSION
  // ===========================================================

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'restaurantId': restaurantId,
      'categoryId': categoryId,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'localImagePath': localImagePath,
      'basePrice': basePrice,
      'discountedPrice': discountedPrice,
      'hasDiscount': hasDiscount,
      'discountPercentage': discountPercentage,
      'variants': variants
          .map(
            (MenuItemVariantModel item) =>
                item.toMap(),
          )
          .toList(),
      'addOns': addOns
          .map(
            (MenuItemAddOnModel item) =>
                item.toMap(),
          )
          .toList(),
      'isVegetarian': isVegetarian,
      'isSpicy': isSpicy,
      'isPopular': isPopular,
      'isFeatured': isFeatured,
      'spicyLevel': spicyLevel,
      'ingredients': ingredients,
      'allergens': allergens,
      'availabilityStatus': availabilityStatus.value,
      'isAvailable': isAvailable,
      'isVisible': isVisible,
      'preparationTimeMinutes':
          preparationTimeMinutes,
      'dailyStockQuantity': dailyStockQuantity,
      'remainingStockQuantity':
          remainingStockQuantity,
      'displayOrder': displayOrder,
      'createdFromMenuImage':
          createdFromMenuImage,
      'extractedRawText': extractedRawText,
      'verifiedByOwner': verifiedByOwner,
      'approvedByAdmin': approvedByAdmin,
      'rejectionReason': rejectionReason,
      'rating': rating,
      'totalReviews': totalReviews,
      'totalOrders': totalOrders,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MenuItemModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return MenuItemModel(
      id: _ModelParser.stringValue(map['id']),
      restaurantId:
          _ModelParser.stringValue(map['restaurantId']),
      categoryId:
          _ModelParser.stringValue(map['categoryId']),
      name: _ModelParser.stringValue(map['name']),
      description:
          _ModelParser.stringValue(map['description']),
      imageUrl:
          _ModelParser.stringValue(map['imageUrl']),
      localImagePath:
          _ModelParser.stringValue(map['localImagePath']),
      basePrice:
          _ModelParser.doubleValue(map['basePrice']),
      discountedPrice:
          _ModelParser.doubleValue(map['discountedPrice']),
      hasDiscount:
          _ModelParser.boolValue(map['hasDiscount']),
      discountPercentage:
          _ModelParser.doubleValue(
        map['discountPercentage'],
      ),
      variants: _ModelParser.mapList(
        map['variants'],
      )
          .map(MenuItemVariantModel.fromMap)
          .toList(),
      addOns: _ModelParser.mapList(
        map['addOns'],
      )
          .map(MenuItemAddOnModel.fromMap)
          .toList(),
      isVegetarian:
          _ModelParser.boolValue(map['isVegetarian']),
      isSpicy:
          _ModelParser.boolValue(map['isSpicy']),
      isPopular:
          _ModelParser.boolValue(map['isPopular']),
      isFeatured:
          _ModelParser.boolValue(map['isFeatured']),
      spicyLevel: _ModelParser.stringValue(
        map['spicyLevel'],
        fallback: 'none',
      ),
      ingredients:
          _ModelParser.stringList(map['ingredients']),
      allergens:
          _ModelParser.stringList(map['allergens']),
      availabilityStatus:
          MenuItemAvailabilityStatusX.fromValue(
        map['availabilityStatus'],
      ),
      isAvailable: _ModelParser.boolValue(
        map['isAvailable'],
        fallback: true,
      ),
      isVisible: _ModelParser.boolValue(
        map['isVisible'],
        fallback: true,
      ),
      preparationTimeMinutes:
          _ModelParser.intValue(
        map['preparationTimeMinutes'],
        fallback: 20,
      ),
      dailyStockQuantity:
          _ModelParser.intValue(
        map['dailyStockQuantity'],
        fallback: -1,
      ),
      remainingStockQuantity:
          _ModelParser.intValue(
        map['remainingStockQuantity'],
        fallback: -1,
      ),
      displayOrder:
          _ModelParser.intValue(map['displayOrder']),
      createdFromMenuImage:
          _ModelParser.boolValue(
        map['createdFromMenuImage'],
      ),
      extractedRawText:
          _ModelParser.stringValue(
        map['extractedRawText'],
      ),
      verifiedByOwner:
          _ModelParser.boolValue(
        map['verifiedByOwner'],
      ),
      approvedByAdmin:
          _ModelParser.boolValue(
        map['approvedByAdmin'],
      ),
      rejectionReason:
          _ModelParser.stringValue(
        map['rejectionReason'],
      ),
      rating: _ModelParser.doubleValue(map['rating']),
      totalReviews:
          _ModelParser.intValue(map['totalReviews']),
      totalOrders:
          _ModelParser.intValue(map['totalOrders']),
      createdAt:
          _ModelParser.dateTimeValue(map['createdAt']) ??
          DateTime.now(),
      updatedAt:
          _ModelParser.dateTimeValue(map['updatedAt']) ??
          DateTime.now(),
    );
  }

  // ===========================================================
  // OBJECT COMPARISON
  // ===========================================================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is MenuItemModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'MenuItemModel('
        'id: $id, '
        'restaurantId: $restaurantId, '
        'name: $name, '
        'price: $effectivePrice'
        ')';
  }
}

// =============================================================
// INTERNAL SAFE MODEL PARSER
// =============================================================

class _ModelParser {
  const _ModelParser._();

  static String stringValue(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) {
      return fallback;
    }

    final String parsed = value.toString().trim();

    return parsed.isEmpty ? fallback : parsed;
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
          (Map item) => Map<String, dynamic>.from(item),
        )
        .toList();
  }

  static DateTime? dateTimeValue(dynamic value) {
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