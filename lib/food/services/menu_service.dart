// lib/food/services/menu_service.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Menu Firestore Service
//
// Scope:
// - Real Firestore CRUD for digital menu items
// - Restaurant owner menu management
// - Customer live menu streams
// - Availability, price, stock, and approval updates
//
// Firebase Storage upload remains bypassed for now.
// Image fields can temporarily hold local paths or future URLs.
// =============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/menu_item_model.dart';

class MenuService {
  MenuService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String restaurantsCollection = 'food_restaurants';
  static const String menuItemsSubcollection = 'menu_items';

  CollectionReference<Map<String, dynamic>> _menuRef(
    String restaurantId,
  ) {
    return _firestore
        .collection(restaurantsCollection)
        .doc(restaurantId)
        .collection(menuItemsSubcollection);
  }

  // ===========================================================
  // CREATE MENU ITEM
  // ===========================================================

  Future<String> createMenuItem(
    MenuItemModel menuItem,
  ) async {
    _validateRestaurantId(menuItem.restaurantId);

    try {
      final CollectionReference<Map<String, dynamic>> reference =
          _menuRef(menuItem.restaurantId);

      final DocumentReference<Map<String, dynamic>> document =
          menuItem.id.trim().isEmpty
              ? reference.doc()
              : reference.doc(menuItem.id);

      final DateTime now = DateTime.now();

      final MenuItemModel data = menuItem.copyWith(
        id: document.id,
        createdAt: menuItem.createdAt,
        updatedAt: now,
      );

      await document.set(
        data.toMap(),
        SetOptions(merge: false),
      );

      return document.id;
    } on FirebaseException catch (error) {
      throw MenuServiceException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    } catch (error) {
      throw MenuServiceException(
        message: 'Unable to create menu item: $error',
      );
    }
  }

  // ===========================================================
  // GET SINGLE MENU ITEM
  // ===========================================================

  Future<MenuItemModel?> getMenuItemById({
    required String restaurantId,
    required String menuItemId,
  }) async {
    if (restaurantId.trim().isEmpty ||
        menuItemId.trim().isEmpty) {
      return null;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _menuRef(restaurantId)
              .doc(menuItemId)
              .get();

      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }

      return _menuItemFromSnapshot(
        snapshot,
        restaurantId: restaurantId,
      );
    } on FirebaseException catch (error) {
      throw MenuServiceException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    } catch (error) {
      throw MenuServiceException(
        message: 'Unable to load menu item: $error',
      );
    }
  }

  Stream<MenuItemModel?> watchMenuItemById({
    required String restaurantId,
    required String menuItemId,
  }) {
    if (restaurantId.trim().isEmpty ||
        menuItemId.trim().isEmpty) {
      return Stream<MenuItemModel?>.value(null);
    }

    return _menuRef(restaurantId)
        .doc(menuItemId)
        .snapshots()
        .map(
      (DocumentSnapshot<Map<String, dynamic>> snapshot) {
        if (!snapshot.exists || snapshot.data() == null) {
          return null;
        }

        return _menuItemFromSnapshot(
          snapshot,
          restaurantId: restaurantId,
        );
      },
    );
  }

  // ===========================================================
  // CUSTOMER MENU STREAMS
  // ===========================================================

  Stream<List<MenuItemModel>> watchCustomerMenu(
    String restaurantId,
  ) {
    if (restaurantId.trim().isEmpty) {
      return Stream<List<MenuItemModel>>.value(
        const <MenuItemModel>[],
      );
    }

    return _menuRef(restaurantId)
        .where('isVisible', isEqualTo: true)
        .where('isAvailable', isEqualTo: true)
        .where('verifiedByOwner', isEqualTo: true)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) =>
              _menuListFromQuery(
            snapshot,
            restaurantId: restaurantId,
            customerOnly: true,
          ),
        );
  }

  Stream<List<MenuItemModel>> watchMenuByCategory({
    required String restaurantId,
    required String categoryId,
  }) {
    if (restaurantId.trim().isEmpty) {
      return Stream<List<MenuItemModel>>.value(
        const <MenuItemModel>[],
      );
    }

    Query<Map<String, dynamic>> query =
        _menuRef(restaurantId)
            .where('isVisible', isEqualTo: true)
            .where('isAvailable', isEqualTo: true)
            .where('verifiedByOwner', isEqualTo: true);

    if (categoryId.trim().isNotEmpty) {
      query = query.where(
        'categoryId',
        isEqualTo: categoryId,
      );
    }

    return query.snapshots().map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) =>
              _menuListFromQuery(
            snapshot,
            restaurantId: restaurantId,
            customerOnly: true,
          ),
        );
  }

  Stream<List<MenuItemModel>> watchPopularMenuItems(
    String restaurantId, {
    int limit = 20,
  }) {
    if (restaurantId.trim().isEmpty) {
      return Stream<List<MenuItemModel>>.value(
        const <MenuItemModel>[],
      );
    }

    return _menuRef(restaurantId)
        .where('isVisible', isEqualTo: true)
        .where('isAvailable', isEqualTo: true)
        .where('isPopular', isEqualTo: true)
        .limit(limit)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) =>
              _menuListFromQuery(
            snapshot,
            restaurantId: restaurantId,
            customerOnly: true,
          ),
        );
  }

  Stream<List<MenuItemModel>> watchFeaturedMenuItems(
    String restaurantId, {
    int limit = 20,
  }) {
    if (restaurantId.trim().isEmpty) {
      return Stream<List<MenuItemModel>>.value(
        const <MenuItemModel>[],
      );
    }

    return _menuRef(restaurantId)
        .where('isVisible', isEqualTo: true)
        .where('isAvailable', isEqualTo: true)
        .where('isFeatured', isEqualTo: true)
        .limit(limit)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) =>
              _menuListFromQuery(
            snapshot,
            restaurantId: restaurantId,
            customerOnly: true,
          ),
        );
  }

  // ===========================================================
  // OWNER MENU STREAM
  // ===========================================================

  Stream<List<MenuItemModel>> watchOwnerMenu(
    String restaurantId,
  ) {
    if (restaurantId.trim().isEmpty) {
      return Stream<List<MenuItemModel>>.value(
        const <MenuItemModel>[],
      );
    }

    return _menuRef(restaurantId)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) =>
              _menuListFromQuery(
            snapshot,
            restaurantId: restaurantId,
            customerOnly: false,
          ),
        );
  }

  Future<List<MenuItemModel>> getOwnerMenu(
    String restaurantId,
  ) async {
    _validateRestaurantId(restaurantId);

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _menuRef(restaurantId).get();

      return _menuListFromQuery(
        snapshot,
        restaurantId: restaurantId,
        customerOnly: false,
      );
    } on FirebaseException catch (error) {
      throw MenuServiceException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    } catch (error) {
      throw MenuServiceException(
        message: 'Unable to load restaurant menu: $error',
      );
    }
  }

  // ===========================================================
  // SEARCH
  // ===========================================================

  Future<List<MenuItemModel>> searchMenuItems({
    required String restaurantId,
    required String query,
  }) async {
    final String normalizedQuery =
        query.trim().toLowerCase();

    final List<MenuItemModel> items =
        await getOwnerMenu(restaurantId);

    if (normalizedQuery.isEmpty) {
      return items
          .where((MenuItemModel item) => item.canBeOrdered)
          .toList();
    }

    return items.where((MenuItemModel item) {
      if (!item.canBeOrdered) {
        return false;
      }

      final String searchable = <String>[
        item.name,
        item.description,
        item.spicyLevel,
        ...item.ingredients,
        ...item.allergens,
      ].join(' ').toLowerCase();

      return searchable.contains(normalizedQuery);
    }).toList();
  }

  // ===========================================================
  // UPDATE COMPLETE ITEM
  // ===========================================================

  Future<void> updateMenuItem(
    MenuItemModel menuItem,
  ) async {
    _validateRestaurantId(menuItem.restaurantId);

    if (menuItem.id.trim().isEmpty) {
      throw const MenuServiceException(
        message: 'Menu item ID is required.',
      );
    }

    try {
      await _menuRef(menuItem.restaurantId)
          .doc(menuItem.id)
          .set(
            menuItem
                .copyWith(updatedAt: DateTime.now())
                .toMap(),
            SetOptions(merge: true),
          );
    } on FirebaseException catch (error) {
      throw MenuServiceException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    } catch (error) {
      throw MenuServiceException(
        message: 'Unable to update menu item: $error',
      );
    }
  }

  Future<void> updateMenuItemFields({
    required String restaurantId,
    required String menuItemId,
    required Map<String, dynamic> fields,
  }) async {
    _validateRestaurantId(restaurantId);

    if (menuItemId.trim().isEmpty) {
      throw const MenuServiceException(
        message: 'Menu item ID is required.',
      );
    }

    try {
      await _menuRef(restaurantId)
          .doc(menuItemId)
          .update(
        <String, dynamic>{
          ...fields,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    } on FirebaseException catch (error) {
      throw MenuServiceException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    } catch (error) {
      throw MenuServiceException(
        message: 'Unable to update menu item fields: $error',
      );
    }
  }

  // ===========================================================
  // OWNER OPERATIONS
  // ===========================================================

  Future<void> setAvailability({
    required String restaurantId,
    required String menuItemId,
    required bool isAvailable,
  }) {
    return updateMenuItemFields(
      restaurantId: restaurantId,
      menuItemId: menuItemId,
      fields: <String, dynamic>{
        'isAvailable': isAvailable,
        'availabilityStatus': isAvailable
            ? MenuItemAvailabilityStatus.available.value
            : MenuItemAvailabilityStatus.outOfStock.value,
      },
    );
  }

  Future<void> setVisibility({
    required String restaurantId,
    required String menuItemId,
    required bool isVisible,
  }) {
    return updateMenuItemFields(
      restaurantId: restaurantId,
      menuItemId: menuItemId,
      fields: <String, dynamic>{
        'isVisible': isVisible,
        'availabilityStatus': isVisible
            ? MenuItemAvailabilityStatus.available.value
            : MenuItemAvailabilityStatus.hidden.value,
      },
    );
  }

  Future<void> updatePrice({
    required String restaurantId,
    required String menuItemId,
    required double basePrice,
    double discountedPrice = 0,
    bool hasDiscount = false,
    double discountPercentage = 0,
  }) {
    final double safeBasePrice =
        basePrice < 0 ? 0 : basePrice;

    final double safeDiscountedPrice =
        discountedPrice < 0 ? 0 : discountedPrice;

    final double safeDiscountPercentage =
        discountPercentage.clamp(0, 100).toDouble();

    return updateMenuItemFields(
      restaurantId: restaurantId,
      menuItemId: menuItemId,
      fields: <String, dynamic>{
        'basePrice': safeBasePrice,
        'discountedPrice': safeDiscountedPrice,
        'hasDiscount': hasDiscount &&
            safeDiscountedPrice > 0 &&
            safeDiscountedPrice < safeBasePrice,
        'discountPercentage':
            safeDiscountPercentage,
      },
    );
  }

  Future<void> updateStock({
    required String restaurantId,
    required String menuItemId,
    required int remainingStockQuantity,
  }) {
    final bool outOfStock =
        remainingStockQuantity == 0;

    return updateMenuItemFields(
      restaurantId: restaurantId,
      menuItemId: menuItemId,
      fields: <String, dynamic>{
        'remainingStockQuantity':
            remainingStockQuantity,
        'isAvailable': !outOfStock,
        'availabilityStatus': outOfStock
            ? MenuItemAvailabilityStatus.outOfStock.value
            : MenuItemAvailabilityStatus.available.value,
      },
    );
  }

  Future<void> updateDisplayOrder({
    required String restaurantId,
    required String menuItemId,
    required int displayOrder,
  }) {
    return updateMenuItemFields(
      restaurantId: restaurantId,
      menuItemId: menuItemId,
      fields: <String, dynamic>{
        'displayOrder': displayOrder,
      },
    );
  }

  Future<void> markOwnerVerified({
    required String restaurantId,
    required String menuItemId,
    required bool verified,
  }) {
    return updateMenuItemFields(
      restaurantId: restaurantId,
      menuItemId: menuItemId,
      fields: <String, dynamic>{
        'verifiedByOwner': verified,
        'availabilityStatus': verified
            ? MenuItemAvailabilityStatus.available.value
            : MenuItemAvailabilityStatus.pendingApproval.value,
      },
    );
  }

  Future<void> updateLocalImagePath({
    required String restaurantId,
    required String menuItemId,
    required String localImagePath,
  }) {
    // Firebase Storage is bypassed.
    // This path is only usable on the same device.
    return updateMenuItemFields(
      restaurantId: restaurantId,
      menuItemId: menuItemId,
      fields: <String, dynamic>{
        'localImagePath': localImagePath.trim(),
      },
    );
  }

  // ===========================================================
  // ADMIN OPERATIONS
  // ===========================================================

  Future<void> approveMenuItem({
    required String restaurantId,
    required String menuItemId,
  }) {
    return updateMenuItemFields(
      restaurantId: restaurantId,
      menuItemId: menuItemId,
      fields: <String, dynamic>{
        'approvedByAdmin': true,
        'rejectionReason': '',
        'availabilityStatus':
            MenuItemAvailabilityStatus.available.value,
      },
    );
  }

  Future<void> rejectMenuItem({
    required String restaurantId,
    required String menuItemId,
    required String reason,
  }) {
    return updateMenuItemFields(
      restaurantId: restaurantId,
      menuItemId: menuItemId,
      fields: <String, dynamic>{
        'approvedByAdmin': false,
        'rejectionReason': reason.trim(),
        'isVisible': false,
        'availabilityStatus':
            MenuItemAvailabilityStatus.rejected.value,
      },
    );
  }

  // ===========================================================
  // DELETE
  // ===========================================================

  Future<void> deleteMenuItem({
    required String restaurantId,
    required String menuItemId,
  }) async {
    _validateRestaurantId(restaurantId);

    if (menuItemId.trim().isEmpty) {
      throw const MenuServiceException(
        message: 'Menu item ID is required.',
      );
    }

    try {
      await _menuRef(restaurantId)
          .doc(menuItemId)
          .delete();
    } on FirebaseException catch (error) {
      throw MenuServiceException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    } catch (error) {
      throw MenuServiceException(
        message: 'Unable to delete menu item: $error',
      );
    }
  }

  // ===========================================================
  // BATCH CREATE / UPDATE
  // Useful after owner verifies menu-photo extracted items.
  // ===========================================================

  Future<void> saveMenuItemsBatch({
    required String restaurantId,
    required List<MenuItemModel> items,
  }) async {
    _validateRestaurantId(restaurantId);

    if (items.isEmpty) {
      return;
    }

    try {
      final WriteBatch batch = _firestore.batch();
      final DateTime now = DateTime.now();

      for (final MenuItemModel item in items) {
        final DocumentReference<Map<String, dynamic>> document =
            item.id.trim().isEmpty
                ? _menuRef(restaurantId).doc()
                : _menuRef(restaurantId).doc(item.id);

        final MenuItemModel data = item.copyWith(
          id: document.id,
          restaurantId: restaurantId,
          updatedAt: now,
        );

        batch.set(
          document,
          data.toMap(),
          SetOptions(merge: true),
        );
      }

      await batch.commit();
    } on FirebaseException catch (error) {
      throw MenuServiceException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    } catch (error) {
      throw MenuServiceException(
        message: 'Unable to save menu items: $error',
      );
    }
  }

  // ===========================================================
  // INTERNAL HELPERS
  // ===========================================================

  MenuItemModel _menuItemFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot, {
    required String restaurantId,
  }) {
    final Map<String, dynamic> data =
        Map<String, dynamic>.from(
      snapshot.data() ?? const <String, dynamic>{},
    );

    data['id'] = snapshot.id;
    data['restaurantId'] = restaurantId;

    return MenuItemModel.fromMap(data);
  }

  List<MenuItemModel> _menuListFromQuery(
    QuerySnapshot<Map<String, dynamic>> snapshot, {
    required String restaurantId,
    required bool customerOnly,
  }) {
    final List<MenuItemModel> items = snapshot.docs
        .map(
          (DocumentSnapshot<Map<String, dynamic>> document) =>
              _menuItemFromSnapshot(
            document,
            restaurantId: restaurantId,
          ),
        )
        .where(
          (MenuItemModel item) =>
              !customerOnly || item.canBeOrdered,
        )
        .toList();

    items.sort(
      (MenuItemModel first, MenuItemModel second) {
        if (first.isFeatured != second.isFeatured) {
          return first.isFeatured ? -1 : 1;
        }

        if (first.isPopular != second.isPopular) {
          return first.isPopular ? -1 : 1;
        }

        final int orderComparison =
            first.displayOrder.compareTo(
          second.displayOrder,
        );

        if (orderComparison != 0) {
          return orderComparison;
        }

        return first.name.toLowerCase().compareTo(
              second.name.toLowerCase(),
            );
      },
    );

    return items;
  }

  void _validateRestaurantId(
    String restaurantId,
  ) {
    if (restaurantId.trim().isEmpty) {
      throw const MenuServiceException(
        message: 'Restaurant ID is required.',
      );
    }
  }

  String _firebaseMessage(
    FirebaseException error,
  ) {
    switch (error.code) {
      case 'permission-denied':
        return 'You do not have permission to manage this restaurant menu.';
      case 'unavailable':
        return 'Firebase is temporarily unavailable. Please try again.';
      case 'not-found':
        return 'The requested menu item was not found.';
      case 'already-exists':
        return 'This menu item already exists.';
      case 'failed-precondition':
        return 'Firebase requires an index or another condition before this action can run.';
      default:
        return error.message ??
            'A Firebase error occurred (${error.code}).';
    }
  }
}

class MenuServiceException implements Exception {
  const MenuServiceException({
    required this.message,
    this.code = '',
  });

  final String message;
  final String code;

  @override
  String toString() {
    if (code.trim().isEmpty) {
      return message;
    }

    return 'MenuServiceException($code): $message';
  }
}
