// lib/food/restaurant_partner/models/food_category_model.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Restaurant Partner Menu Category Model
//
// Important:
// This class is named RestaurantMenuCategoryModel so it does not
// conflict with the existing customer-side FoodCategoryModel.
//
// Used by:
// - Restaurant Partner menu management
// - Add/Edit category screens
// - Menu item filtering
// - Customer digital menu sections
// - Firestore category CRUD
// =============================================================

class RestaurantMenuCategoryModel {
  final String id;
  final String restaurantId;
  final String partnerId;

  final String name;
  final String description;

  // Firebase Storage is temporarily bypassed.
  // imageUrl will be used after Storage is enabled.
  // localImagePath can temporarily hold a local device path.
  final String imageUrl;
  final String localImagePath;

  final int sortOrder;

  final bool isActive;
  final bool isVisible;
  final bool isFeatured;

  final String createdBy;

  final int totalItems;

  final DateTime createdAt;
  final DateTime updatedAt;

  const RestaurantMenuCategoryModel({
    required this.id,
    required this.restaurantId,
    required this.partnerId,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.localImagePath,
    required this.sortOrder,
    required this.isActive,
    required this.isVisible,
    required this.isFeatured,
    required this.createdBy,
    required this.totalItems,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RestaurantMenuCategoryModel.empty({
    String restaurantId = '',
    String partnerId = '',
    String createdBy = '',
  }) {
    final DateTime now = DateTime.now();

    return RestaurantMenuCategoryModel(
      id: '',
      restaurantId: restaurantId,
      partnerId: partnerId,
      name: '',
      description: '',
      imageUrl: '',
      localImagePath: '',
      sortOrder: 0,
      isActive: true,
      isVisible: true,
      isFeatured: false,
      createdBy: createdBy,
      totalItems: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  bool get hasImage {
    return imageUrl.trim().isNotEmpty ||
        localImagePath.trim().isNotEmpty;
  }

  bool get canShowToCustomer {
    return isActive && isVisible;
  }

  String get itemCountText {
    if (totalItems == 1) {
      return '1 item';
    }

    return '$totalItems items';
  }

  RestaurantMenuCategoryModel copyWith({
    String? id,
    String? restaurantId,
    String? partnerId,
    String? name,
    String? description,
    String? imageUrl,
    String? localImagePath,
    int? sortOrder,
    bool? isActive,
    bool? isVisible,
    bool? isFeatured,
    String? createdBy,
    int? totalItems,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RestaurantMenuCategoryModel(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      partnerId: partnerId ?? this.partnerId,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      localImagePath:
          localImagePath ?? this.localImagePath,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      isVisible: isVisible ?? this.isVisible,
      isFeatured: isFeatured ?? this.isFeatured,
      createdBy: createdBy ?? this.createdBy,
      totalItems: totalItems ?? this.totalItems,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'restaurantId': restaurantId,
      'partnerId': partnerId,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'localImagePath': localImagePath,
      'sortOrder': sortOrder,
      'isActive': isActive,
      'isVisible': isVisible,
      'isFeatured': isFeatured,
      'createdBy': createdBy,
      'totalItems': totalItems,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory RestaurantMenuCategoryModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return RestaurantMenuCategoryModel(
      id: _CategoryParser.stringValue(map['id']),
      restaurantId:
          _CategoryParser.stringValue(map['restaurantId']),
      partnerId:
          _CategoryParser.stringValue(map['partnerId']),
      name: _CategoryParser.stringValue(map['name']),
      description:
          _CategoryParser.stringValue(map['description']),
      imageUrl:
          _CategoryParser.stringValue(map['imageUrl']),
      localImagePath:
          _CategoryParser.stringValue(
        map['localImagePath'],
      ),
      sortOrder:
          _CategoryParser.intValue(map['sortOrder']),
      isActive: _CategoryParser.boolValue(
        map['isActive'],
        fallback: true,
      ),
      isVisible: _CategoryParser.boolValue(
        map['isVisible'],
        fallback: true,
      ),
      isFeatured:
          _CategoryParser.boolValue(map['isFeatured']),
      createdBy:
          _CategoryParser.stringValue(map['createdBy']),
      totalItems:
          _CategoryParser.intValue(map['totalItems']),
      createdAt:
          _CategoryParser.dateTimeValue(map['createdAt']) ??
          DateTime.now(),
      updatedAt:
          _CategoryParser.dateTimeValue(map['updatedAt']) ??
          DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is RestaurantMenuCategoryModel &&
        other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'RestaurantMenuCategoryModel('
        'id: $id, '
        'restaurantId: $restaurantId, '
        'name: $name, '
        'totalItems: $totalItems'
        ')';
  }
}

class _CategoryParser {
  const _CategoryParser._();

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
      // Supports Firestore Timestamp without direct import.
    }

    return DateTime.tryParse(value.toString());
  }
}
