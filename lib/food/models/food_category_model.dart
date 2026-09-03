// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Food Category Model
//
// This model is used for:
// 1. Food home screen categories
// 2. Restaurant category filters
// 3. Search filters
// 4. Admin category management
// 5. Restaurant menu grouping
// =============================================================

class FoodCategoryModel {
  // ===========================================================
  // BASIC INFORMATION
  // ===========================================================

  final String id;
  final String name;
  final String description;

  // Category image or icon URL.
  //
  // Example:
  // Burger category image
  // Pizza category image
  // BBQ category image
  final String imageUrl;

  // Optional Material icon code point.
  //
  // This allows us to show a local icon when no image is uploaded.
  final int iconCodePoint;

  // ===========================================================
  // DISPLAY SETTINGS
  // ===========================================================

  final int displayOrder;

  final bool isActive;
  final bool isFeatured;
  final bool isPopular;

  // ===========================================================
  // RESTAURANT AND MENU USAGE
  // ===========================================================

  // This category can be used for restaurant classification.
  //
  // Example:
  // Fast Food, Pakistani, Chinese
  final bool usableForRestaurant;

  // This category can be used inside restaurant menus.
  //
  // Example:
  // Burgers, Pizza, Drinks, Desserts
  final bool usableForMenu;

  // ===========================================================
  // PROMOTION
  // ===========================================================

  final bool hasDiscount;
  final double discountPercentage;

  // ===========================================================
  // TIMESTAMPS
  // ===========================================================

  final DateTime createdAt;
  final DateTime updatedAt;

  // ===========================================================
  // CONSTRUCTOR
  // ===========================================================

  const FoodCategoryModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.iconCodePoint,
    required this.displayOrder,
    required this.isActive,
    required this.isFeatured,
    required this.isPopular,
    required this.usableForRestaurant,
    required this.usableForMenu,
    required this.hasDiscount,
    required this.discountPercentage,
    required this.createdAt,
    required this.updatedAt,
  });

  // ===========================================================
  // EMPTY MODEL
  // ===========================================================

  factory FoodCategoryModel.empty() {
    final DateTime now = DateTime.now();

    return FoodCategoryModel(
      id: '',
      name: '',
      description: '',
      imageUrl: '',
      iconCodePoint: 0,
      displayOrder: 0,
      isActive: true,
      isFeatured: false,
      isPopular: false,
      usableForRestaurant: true,
      usableForMenu: true,
      hasDiscount: false,
      discountPercentage: 0.0,
      createdAt: now,
      updatedAt: now,
    );
  }

  // ===========================================================
  // DISPLAY HELPERS
  // ===========================================================

  bool get hasImage {
    return imageUrl.trim().isNotEmpty;
  }

  bool get hasIcon {
    return iconCodePoint > 0;
  }

  bool get hasValidDiscount {
    return hasDiscount && discountPercentage > 0;
  }

  String get discountText {
    if (!hasValidDiscount) {
      return '';
    }

    return '${discountPercentage.toStringAsFixed(0)}% OFF';
  }

  // ===========================================================
  // COPY WITH
  // ===========================================================

  FoodCategoryModel copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    int? iconCodePoint,
    int? displayOrder,
    bool? isActive,
    bool? isFeatured,
    bool? isPopular,
    bool? usableForRestaurant,
    bool? usableForMenu,
    bool? hasDiscount,
    double? discountPercentage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FoodCategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      isPopular: isPopular ?? this.isPopular,
      usableForRestaurant:
          usableForRestaurant ?? this.usableForRestaurant,
      usableForMenu: usableForMenu ?? this.usableForMenu,
      hasDiscount: hasDiscount ?? this.hasDiscount,
      discountPercentage:
          discountPercentage ?? this.discountPercentage,
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
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'iconCodePoint': iconCodePoint,
      'displayOrder': displayOrder,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'isPopular': isPopular,
      'usableForRestaurant': usableForRestaurant,
      'usableForMenu': usableForMenu,
      'hasDiscount': hasDiscount,
      'discountPercentage': discountPercentage,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory FoodCategoryModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return FoodCategoryModel(
      id: _stringValue(map['id']),
      name: _stringValue(map['name']),
      description: _stringValue(map['description']),
      imageUrl: _stringValue(map['imageUrl']),
      iconCodePoint: _intValue(map['iconCodePoint']),
      displayOrder: _intValue(map['displayOrder']),
      isActive: _boolValue(
        map['isActive'],
        fallback: true,
      ),
      isFeatured: _boolValue(map['isFeatured']),
      isPopular: _boolValue(map['isPopular']),
      usableForRestaurant: _boolValue(
        map['usableForRestaurant'],
        fallback: true,
      ),
      usableForMenu: _boolValue(
        map['usableForMenu'],
        fallback: true,
      ),
      hasDiscount: _boolValue(map['hasDiscount']),
      discountPercentage:
          _doubleValue(map['discountPercentage']),
      createdAt:
          _dateTimeValue(map['createdAt']) ??
          DateTime.now(),
      updatedAt:
          _dateTimeValue(map['updatedAt']) ??
          DateTime.now(),
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

  static DateTime? _dateTimeValue(
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
      // Firebase Timestamp support without direct import.
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

    return other is FoodCategoryModel &&
        other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'FoodCategoryModel('
        'id: $id, '
        'name: $name, '
        'isActive: $isActive'
        ')';
  }
}