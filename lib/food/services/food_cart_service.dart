// lib/food/services/food_cart_service.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// In-memory Cart Service
//
// Scope:
// - Add, update, and remove food cart items
// - Enforce one restaurant per cart
// - Calculate totals
// - Expose live cart updates to screens
//
// This file touches only the Food module.
// =============================================================

import 'dart:async';

import '../models/cart_item_model.dart';

class FoodCartService {
  FoodCartService._();

  static final FoodCartService instance =
      FoodCartService._();

  final List<CartItemModel> _items =
      <CartItemModel>[];

  final StreamController<List<CartItemModel>>
      _cartController =
      StreamController<List<CartItemModel>>.broadcast();

  Stream<List<CartItemModel>> get cartStream =>
      _cartController.stream;

  List<CartItemModel> get items =>
      List<CartItemModel>.unmodifiable(_items);

  bool get isEmpty => _items.isEmpty;

  bool get isNotEmpty => _items.isNotEmpty;

  int get totalQuantity {
    return _items.fold<int>(
      0,
      (
        int total,
        CartItemModel item,
      ) =>
          total + item.quantity,
    );
  }

  double get subtotal {
    return _items.fold<double>(
      0,
      (
        double total,
        CartItemModel item,
      ) =>
          total + item.totalPrice,
    );
  }

  String get restaurantId {
    if (_items.isEmpty) {
      return '';
    }

    return _items.first.restaurantId;
  }

  String get restaurantName {
    if (_items.isEmpty) {
      return '';
    }

    return _items.first.restaurantName;
  }

  // ===========================================================
  // ADD ITEM
  // ===========================================================

  FoodCartResult addItem(
    CartItemModel item, {
    bool replaceOtherRestaurantCart = false,
  }) {
    if (!item.isAvailable) {
      return const FoodCartResult.failure(
        'This food item is currently unavailable.',
      );
    }

    if (_items.isNotEmpty &&
        restaurantId != item.restaurantId) {
      if (!replaceOtherRestaurantCart) {
        return FoodCartResult.restaurantConflict(
          currentRestaurantName: restaurantName,
          requestedRestaurantName: item.restaurantName,
        );
      }

      _items.clear();
    }

    final int existingIndex =
        _items.indexWhere(
      (CartItemModel existing) =>
          existing.cartItemId == item.cartItemId,
    );

    if (existingIndex >= 0) {
      final CartItemModel existing =
          _items[existingIndex];

      final int requestedQuantity =
          existing.quantity + item.quantity;

      _items[existingIndex] =
          existing.setQuantity(requestedQuantity);
    } else {
      _items.add(item);
    }

    _emit();

    return const FoodCartResult.success(
      'Item added to cart.',
    );
  }

  // ===========================================================
  // UPDATE QUANTITY
  // ===========================================================

  FoodCartResult increaseQuantity(
    String cartItemId,
  ) {
    final int index = _findIndex(cartItemId);

    if (index < 0) {
      return const FoodCartResult.failure(
        'Cart item was not found.',
      );
    }

    final CartItemModel updated =
        _items[index].increaseQuantity();

    if (updated.quantity ==
        _items[index].quantity) {
      return const FoodCartResult.failure(
        'Maximum allowed quantity reached.',
      );
    }

    _items[index] = updated;
    _emit();

    return const FoodCartResult.success(
      'Quantity increased.',
    );
  }

  FoodCartResult decreaseQuantity(
    String cartItemId,
  ) {
    final int index = _findIndex(cartItemId);

    if (index < 0) {
      return const FoodCartResult.failure(
        'Cart item was not found.',
      );
    }

    final CartItemModel current =
        _items[index];

    if (current.quantity <= 1) {
      _items.removeAt(index);
      _emit();

      return const FoodCartResult.success(
        'Item removed from cart.',
      );
    }

    _items[index] =
        current.decreaseQuantity();

    _emit();

    return const FoodCartResult.success(
      'Quantity decreased.',
    );
  }

  FoodCartResult setQuantity({
    required String cartItemId,
    required int quantity,
  }) {
    final int index = _findIndex(cartItemId);

    if (index < 0) {
      return const FoodCartResult.failure(
        'Cart item was not found.',
      );
    }

    if (quantity <= 0) {
      _items.removeAt(index);
      _emit();

      return const FoodCartResult.success(
        'Item removed from cart.',
      );
    }

    _items[index] =
        _items[index].setQuantity(quantity);

    _emit();

    return const FoodCartResult.success(
      'Quantity updated.',
    );
  }

  // ===========================================================
  // UPDATE ITEM DETAILS
  // ===========================================================

  FoodCartResult updateSpecialInstructions({
    required String cartItemId,
    required String instructions,
  }) {
    final int index = _findIndex(cartItemId);

    if (index < 0) {
      return const FoodCartResult.failure(
        'Cart item was not found.',
      );
    }

    _items[index] =
        _items[index].copyWith(
      specialInstructions:
          instructions.trim(),
      updatedAt: DateTime.now(),
    );

    _emit();

    return const FoodCartResult.success(
      'Instructions updated.',
    );
  }

  FoodCartResult updateAvailability({
    required String cartItemId,
    required bool isAvailable,
  }) {
    final int index = _findIndex(cartItemId);

    if (index < 0) {
      return const FoodCartResult.failure(
        'Cart item was not found.',
      );
    }

    _items[index] =
        _items[index].copyWith(
      isAvailable: isAvailable,
      updatedAt: DateTime.now(),
    );

    _emit();

    return const FoodCartResult.success(
      'Availability updated.',
    );
  }

  // ===========================================================
  // REMOVE / CLEAR
  // ===========================================================

  FoodCartResult removeItem(
    String cartItemId,
  ) {
    final int index = _findIndex(cartItemId);

    if (index < 0) {
      return const FoodCartResult.failure(
        'Cart item was not found.',
      );
    }

    _items.removeAt(index);
    _emit();

    return const FoodCartResult.success(
      'Item removed from cart.',
    );
  }

  void clearCart() {
    if (_items.isEmpty) {
      return;
    }

    _items.clear();
    _emit();
  }

  // ===========================================================
  // VALIDATION
  // ===========================================================

  FoodCartValidation validateForCheckout() {
    if (_items.isEmpty) {
      return const FoodCartValidation.invalid(
        'Your cart is empty.',
      );
    }

    final bool hasUnavailableItems =
        _items.any(
      (CartItemModel item) =>
          !item.isAvailable,
    );

    if (hasUnavailableItems) {
      return const FoodCartValidation.invalid(
        'One or more items are unavailable.',
      );
    }

    final String expectedRestaurantId =
        _items.first.restaurantId;

    final bool multipleRestaurants =
        _items.any(
      (CartItemModel item) =>
          item.restaurantId !=
          expectedRestaurantId,
    );

    if (multipleRestaurants) {
      return const FoodCartValidation.invalid(
        'Cart contains items from multiple restaurants.',
      );
    }

    return const FoodCartValidation.valid();
  }

  // ===========================================================
  // RESTORE CART
  // ===========================================================

  void restoreItems(
    List<CartItemModel> items,
  ) {
    _items
      ..clear()
      ..addAll(items);

    _emit();
  }

  // ===========================================================
  // INTERNAL
  // ===========================================================

  int _findIndex(
    String cartItemId,
  ) {
    return _items.indexWhere(
      (CartItemModel item) =>
          item.cartItemId == cartItemId,
    );
  }

  void _emit() {
    if (_cartController.isClosed) {
      return;
    }

    _cartController.add(
      List<CartItemModel>.unmodifiable(
        _items,
      ),
    );
  }

  void dispose() {
    _cartController.close();
  }
}

// =============================================================
// CART ACTION RESULT
// =============================================================

enum FoodCartResultType {
  success,
  failure,
  restaurantConflict,
}

class FoodCartResult {
  final FoodCartResultType type;
  final String message;

  final String currentRestaurantName;
  final String requestedRestaurantName;

  const FoodCartResult._({
    required this.type,
    required this.message,
    this.currentRestaurantName = '',
    this.requestedRestaurantName = '',
  });

  const FoodCartResult.success(
    String message,
  ) : this._(
          type: FoodCartResultType.success,
          message: message,
        );

  const FoodCartResult.failure(
    String message,
  ) : this._(
          type: FoodCartResultType.failure,
          message: message,
        );

  factory FoodCartResult.restaurantConflict({
    required String currentRestaurantName,
    required String requestedRestaurantName,
  }) {
    return FoodCartResult._(
      type:
          FoodCartResultType.restaurantConflict,
      message:
          'Your cart already contains items from $currentRestaurantName.',
      currentRestaurantName:
          currentRestaurantName,
      requestedRestaurantName:
          requestedRestaurantName,
    );
  }

  bool get isSuccess =>
      type == FoodCartResultType.success;

  bool get isFailure =>
      type == FoodCartResultType.failure;

  bool get hasRestaurantConflict =>
      type ==
      FoodCartResultType.restaurantConflict;
}

// =============================================================
// CHECKOUT VALIDATION RESULT
// =============================================================

class FoodCartValidation {
  final bool isValid;
  final String message;

  const FoodCartValidation._({
    required this.isValid,
    required this.message,
  });

  const FoodCartValidation.valid()
      : this._(
          isValid: true,
          message: '',
        );

  const FoodCartValidation.invalid(
    String message,
  ) : this._(
          isValid: false,
          message: message,
        );
}
