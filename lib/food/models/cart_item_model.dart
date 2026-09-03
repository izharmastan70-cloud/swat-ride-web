import 'menu_item_model.dart';

// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Cart Item Model
//
// Connected with:
// menu_item_model.dart
//
// Used by:
// 1. Customer food cart
// 2. Checkout
// 3. Order creation
// 4. Price calculation
// 5. Firestore order snapshots
// =============================================================

// =============================================================
// SELECTED ADD-ON
// =============================================================

class SelectedAddOnModel {
  final String id;
  final String name;
  final double unitPrice;
  final int quantity;

  const SelectedAddOnModel({
    required this.id,
    required this.name,
    required this.unitPrice,
    required this.quantity,
  });

  factory SelectedAddOnModel.fromMenuAddOn({
    required MenuItemAddOnModel addOn,
    int quantity = 1,
  }) {
    return SelectedAddOnModel(
      id: addOn.id,
      name: addOn.name,
      unitPrice: addOn.price,
      quantity: quantity < 1 ? 1 : quantity,
    );
  }

  double get totalPrice {
    return unitPrice * quantity;
  }

  SelectedAddOnModel copyWith({
    String? id,
    String? name,
    double? unitPrice,
    int? quantity,
  }) {
    return SelectedAddOnModel(
      id: id ?? this.id,
      name: name ?? this.name,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'totalPrice': totalPrice,
    };
  }

  factory SelectedAddOnModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return SelectedAddOnModel(
      id: _CartParser.stringValue(map['id']),
      name: _CartParser.stringValue(map['name']),
      unitPrice:
          _CartParser.doubleValue(map['unitPrice']),
      quantity: _CartParser.intValue(
        map['quantity'],
        fallback: 1,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is SelectedAddOnModel &&
        other.id == id &&
        other.quantity == quantity;
  }

  @override
  int get hashCode => Object.hash(id, quantity);
}

// =============================================================
// CART ITEM
// =============================================================

class CartItemModel {
  // Unique cart-row ID.
  //
  // The same menu item can appear more than once when the
  // selected variant, add-ons, or instructions are different.
  final String cartItemId;

  final String restaurantId;
  final String restaurantName;

  final String menuItemId;
  final String menuItemName;
  final String menuItemImageUrl;
  final String menuItemLocalImagePath;

  // Snapshot price saved when item is added to cart.
  final double baseUnitPrice;

  // ===========================================================
  // SELECTED VARIANT
  // ===========================================================

  final String selectedVariantId;
  final String selectedVariantName;
  final double selectedVariantPrice;

  // ===========================================================
  // SELECTED ADD-ONS
  // ===========================================================

  final List<SelectedAddOnModel> selectedAddOns;

  // ===========================================================
  // ORDER PREFERENCES
  // ===========================================================

  final int quantity;
  final String specialInstructions;

  final bool isAvailable;
  final int maximumAllowedQuantity;

  final DateTime addedAt;
  final DateTime updatedAt;

  const CartItemModel({
    required this.cartItemId,
    required this.restaurantId,
    required this.restaurantName,
    required this.menuItemId,
    required this.menuItemName,
    required this.menuItemImageUrl,
    required this.menuItemLocalImagePath,
    required this.baseUnitPrice,
    required this.selectedVariantId,
    required this.selectedVariantName,
    required this.selectedVariantPrice,
    required this.selectedAddOns,
    required this.quantity,
    required this.specialInstructions,
    required this.isAvailable,
    required this.maximumAllowedQuantity,
    required this.addedAt,
    required this.updatedAt,
  });

  // ===========================================================
  // CREATE FROM MENU ITEM
  // ===========================================================

  factory CartItemModel.fromMenuItem({
    required MenuItemModel menuItem,
    required String restaurantName,
    MenuItemVariantModel? selectedVariant,
    List<SelectedAddOnModel> selectedAddOns =
        const <SelectedAddOnModel>[],
    int quantity = 1,
    String specialInstructions = '',
  }) {
    final DateTime now = DateTime.now();

    final MenuItemVariantModel? effectiveVariant =
        selectedVariant ?? menuItem.defaultVariant;

    final double effectiveBasePrice =
        menuItem.priceForVariant(effectiveVariant);

    final int safeQuantity = quantity < 1 ? 1 : quantity;

    final int maximumAllowedQuantity =
        _calculateMaximumAllowedQuantity(menuItem);

    return CartItemModel(
      cartItemId: _buildCartItemId(
        menuItemId: menuItem.id,
        variantId: effectiveVariant?.id ?? '',
        addOns: selectedAddOns,
        instructions: specialInstructions,
      ),
      restaurantId: menuItem.restaurantId,
      restaurantName: restaurantName,
      menuItemId: menuItem.id,
      menuItemName: menuItem.name,
      menuItemImageUrl: menuItem.imageUrl,
      menuItemLocalImagePath: menuItem.localImagePath,
      baseUnitPrice: effectiveBasePrice,
      selectedVariantId: effectiveVariant?.id ?? '',
      selectedVariantName: effectiveVariant?.name ?? '',
      selectedVariantPrice:
          effectiveVariant?.price ?? effectiveBasePrice,
      selectedAddOns: List<SelectedAddOnModel>.unmodifiable(
        selectedAddOns,
      ),
      quantity: safeQuantity > maximumAllowedQuantity
          ? maximumAllowedQuantity
          : safeQuantity,
      specialInstructions: specialInstructions.trim(),
      isAvailable: menuItem.canBeOrdered,
      maximumAllowedQuantity: maximumAllowedQuantity,
      addedAt: now,
      updatedAt: now,
    );
  }

  // ===========================================================
  // PRICE CALCULATION
  // ===========================================================

  double get unitBasePrice {
    if (selectedVariantPrice > 0) {
      return selectedVariantPrice;
    }

    return baseUnitPrice;
  }

  double get addOnsUnitTotal {
    return selectedAddOns.fold<double>(
      0,
      (
        double currentTotal,
        SelectedAddOnModel addOn,
      ) {
        return currentTotal + addOn.totalPrice;
      },
    );
  }

  double get unitTotal {
    return unitBasePrice + addOnsUnitTotal;
  }

  double get totalPrice {
    return unitTotal * quantity;
  }

  bool get hasVariant {
    return selectedVariantId.trim().isNotEmpty;
  }

  bool get hasAddOns {
    return selectedAddOns.isNotEmpty;
  }

  bool get hasSpecialInstructions {
    return specialInstructions.trim().isNotEmpty;
  }

  bool get canIncreaseQuantity {
    return isAvailable &&
        quantity < maximumAllowedQuantity;
  }

  bool get canDecreaseQuantity {
    return quantity > 1;
  }

  String get unitPriceText {
    return 'Rs. ${unitTotal.toStringAsFixed(0)}';
  }

  String get totalPriceText {
    return 'Rs. ${totalPrice.toStringAsFixed(0)}';
  }

  String get selectedOptionsText {
    final List<String> options = <String>[];

    if (selectedVariantName.trim().isNotEmpty) {
      options.add(selectedVariantName);
    }

    if (selectedAddOns.isNotEmpty) {
      options.addAll(
        selectedAddOns.map(
          (SelectedAddOnModel addOn) {
            if (addOn.quantity > 1) {
              return '${addOn.name} x${addOn.quantity}';
            }

            return addOn.name;
          },
        ),
      );
    }

    return options.join(' • ');
  }

  // ===========================================================
  // QUANTITY CHANGES
  // ===========================================================

  CartItemModel increaseQuantity() {
    if (!canIncreaseQuantity) {
      return this;
    }

    return copyWith(
      quantity: quantity + 1,
      updatedAt: DateTime.now(),
    );
  }

  CartItemModel decreaseQuantity() {
    if (!canDecreaseQuantity) {
      return this;
    }

    return copyWith(
      quantity: quantity - 1,
      updatedAt: DateTime.now(),
    );
  }

  CartItemModel setQuantity(int newQuantity) {
    int safeQuantity = newQuantity;

    if (safeQuantity < 1) {
      safeQuantity = 1;
    }

    if (safeQuantity > maximumAllowedQuantity) {
      safeQuantity = maximumAllowedQuantity;
    }

    return copyWith(
      quantity: safeQuantity,
      updatedAt: DateTime.now(),
    );
  }

  // ===========================================================
  // CART MATCHING
  // ===========================================================

  bool matchesConfiguration({
    required String menuItemId,
    required String variantId,
    required List<SelectedAddOnModel> addOns,
    required String instructions,
  }) {
    if (this.menuItemId != menuItemId) {
      return false;
    }

    if (selectedVariantId != variantId) {
      return false;
    }

    if (specialInstructions.trim() != instructions.trim()) {
      return false;
    }

    final List<String> currentAddOns =
        _normalizedAddOnKeys(selectedAddOns);

    final List<String> requestedAddOns =
        _normalizedAddOnKeys(addOns);

    if (currentAddOns.length != requestedAddOns.length) {
      return false;
    }

    for (int index = 0;
        index < currentAddOns.length;
        index++) {
      if (currentAddOns[index] != requestedAddOns[index]) {
        return false;
      }
    }

    return true;
  }

  // ===========================================================
  // COPY WITH
  // ===========================================================

  CartItemModel copyWith({
    String? cartItemId,
    String? restaurantId,
    String? restaurantName,
    String? menuItemId,
    String? menuItemName,
    String? menuItemImageUrl,
    String? menuItemLocalImagePath,
    double? baseUnitPrice,
    String? selectedVariantId,
    String? selectedVariantName,
    double? selectedVariantPrice,
    List<SelectedAddOnModel>? selectedAddOns,
    int? quantity,
    String? specialInstructions,
    bool? isAvailable,
    int? maximumAllowedQuantity,
    DateTime? addedAt,
    DateTime? updatedAt,
  }) {
    return CartItemModel(
      cartItemId: cartItemId ?? this.cartItemId,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName:
          restaurantName ?? this.restaurantName,
      menuItemId: menuItemId ?? this.menuItemId,
      menuItemName: menuItemName ?? this.menuItemName,
      menuItemImageUrl:
          menuItemImageUrl ?? this.menuItemImageUrl,
      menuItemLocalImagePath:
          menuItemLocalImagePath ??
          this.menuItemLocalImagePath,
      baseUnitPrice: baseUnitPrice ?? this.baseUnitPrice,
      selectedVariantId:
          selectedVariantId ?? this.selectedVariantId,
      selectedVariantName:
          selectedVariantName ?? this.selectedVariantName,
      selectedVariantPrice:
          selectedVariantPrice ?? this.selectedVariantPrice,
      selectedAddOns: selectedAddOns == null
          ? this.selectedAddOns
          : List<SelectedAddOnModel>.unmodifiable(
              selectedAddOns,
            ),
      quantity: quantity ?? this.quantity,
      specialInstructions:
          specialInstructions ?? this.specialInstructions,
      isAvailable: isAvailable ?? this.isAvailable,
      maximumAllowedQuantity:
          maximumAllowedQuantity ??
          this.maximumAllowedQuantity,
      addedAt: addedAt ?? this.addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ===========================================================
  // MAP CONVERSION
  // ===========================================================

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'cartItemId': cartItemId,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'menuItemId': menuItemId,
      'menuItemName': menuItemName,
      'menuItemImageUrl': menuItemImageUrl,
      'menuItemLocalImagePath': menuItemLocalImagePath,
      'baseUnitPrice': baseUnitPrice,
      'selectedVariantId': selectedVariantId,
      'selectedVariantName': selectedVariantName,
      'selectedVariantPrice': selectedVariantPrice,
      'selectedAddOns': selectedAddOns
          .map(
            (SelectedAddOnModel addOn) => addOn.toMap(),
          )
          .toList(),
      'quantity': quantity,
      'specialInstructions': specialInstructions,
      'isAvailable': isAvailable,
      'maximumAllowedQuantity': maximumAllowedQuantity,
      'unitTotal': unitTotal,
      'totalPrice': totalPrice,
      'addedAt': addedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory CartItemModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return CartItemModel(
      cartItemId:
          _CartParser.stringValue(map['cartItemId']),
      restaurantId:
          _CartParser.stringValue(map['restaurantId']),
      restaurantName:
          _CartParser.stringValue(map['restaurantName']),
      menuItemId:
          _CartParser.stringValue(map['menuItemId']),
      menuItemName:
          _CartParser.stringValue(map['menuItemName']),
      menuItemImageUrl:
          _CartParser.stringValue(map['menuItemImageUrl']),
      menuItemLocalImagePath: _CartParser.stringValue(
        map['menuItemLocalImagePath'],
      ),
      baseUnitPrice:
          _CartParser.doubleValue(map['baseUnitPrice']),
      selectedVariantId: _CartParser.stringValue(
        map['selectedVariantId'],
      ),
      selectedVariantName: _CartParser.stringValue(
        map['selectedVariantName'],
      ),
      selectedVariantPrice: _CartParser.doubleValue(
        map['selectedVariantPrice'],
      ),
      selectedAddOns: _CartParser.mapList(
        map['selectedAddOns'],
      )
          .map(SelectedAddOnModel.fromMap)
          .toList(),
      quantity: _CartParser.intValue(
        map['quantity'],
        fallback: 1,
      ),
      specialInstructions: _CartParser.stringValue(
        map['specialInstructions'],
      ),
      isAvailable: _CartParser.boolValue(
        map['isAvailable'],
        fallback: true,
      ),
      maximumAllowedQuantity: _CartParser.intValue(
        map['maximumAllowedQuantity'],
        fallback: 99,
      ),
      addedAt:
          _CartParser.dateTimeValue(map['addedAt']) ??
          DateTime.now(),
      updatedAt:
          _CartParser.dateTimeValue(map['updatedAt']) ??
          DateTime.now(),
    );
  }

  // ===========================================================
  // INTERNAL HELPERS
  // ===========================================================

  static int _calculateMaximumAllowedQuantity(
    MenuItemModel menuItem,
  ) {
    if (!menuItem.hasLimitedStock) {
      return 99;
    }

    if (menuItem.remainingStockQuantity <= 0) {
      return 1;
    }

    return menuItem.remainingStockQuantity;
  }

  static String _buildCartItemId({
    required String menuItemId,
    required String variantId,
    required List<SelectedAddOnModel> addOns,
    required String instructions,
  }) {
    final List<String> addOnKeys =
        _normalizedAddOnKeys(addOns);

    final String rawKey = <String>[
      menuItemId,
      variantId,
      addOnKeys.join(','),
      instructions.trim().toLowerCase(),
    ].join('|');

    return '${menuItemId}_${rawKey.hashCode.abs()}';
  }

  static List<String> _normalizedAddOnKeys(
    List<SelectedAddOnModel> addOns,
  ) {
    final List<String> keys = addOns
        .map(
          (SelectedAddOnModel addOn) =>
              '${addOn.id}:${addOn.quantity}',
        )
        .toList();

    keys.sort();

    return keys;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is CartItemModel &&
        other.cartItemId == cartItemId;
  }

  @override
  int get hashCode => cartItemId.hashCode;

  @override
  String toString() {
    return 'CartItemModel('
        'cartItemId: $cartItemId, '
        'menuItemName: $menuItemName, '
        'quantity: $quantity, '
        'totalPrice: $totalPrice'
        ')';
  }
}

// =============================================================
// INTERNAL SAFE CART PARSER
// =============================================================

class _CartParser {
  const _CartParser._();

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
      // Supports Firestore Timestamp without direct import.
    }

    return DateTime.tryParse(value.toString());
  }
}