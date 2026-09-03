// lib/food/restaurant_partner/services/food_category_service.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Restaurant Partner Menu Category Firestore Service
//
// Connected with:
// - RestaurantMenuCategoryModel
//
// Firestore structure:
// food_restaurants/{restaurantId}/menu_categories/{categoryId}
//
// This service touches only the Food module.
// Firebase Storage image upload remains bypassed.
// =============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/food_category_model.dart';

class FoodCategoryService {
  FoodCategoryService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String restaurantsCollection =
      'food_restaurants';

  static const String categoriesSubcollection =
      'menu_categories';

  CollectionReference<Map<String, dynamic>> _categoriesRef(
    String restaurantId,
  ) {
    return _firestore
        .collection(restaurantsCollection)
        .doc(restaurantId)
        .collection(categoriesSubcollection);
  }

  // ===========================================================
  // CREATE CATEGORY
  // ===========================================================

  Future<String> createCategory(
    RestaurantMenuCategoryModel category,
  ) async {
    _validateRestaurantId(category.restaurantId);

    if (category.name.trim().isEmpty) {
      throw const FoodCategoryServiceException(
        message: 'Category name is required.',
      );
    }

    try {
      final CollectionReference<Map<String, dynamic>> reference =
          _categoriesRef(category.restaurantId);

      final DocumentReference<Map<String, dynamic>> document =
          category.id.trim().isEmpty
              ? reference.doc()
              : reference.doc(category.id);

      final DateTime now = DateTime.now();

      final RestaurantMenuCategoryModel data =
          category.copyWith(
        id: document.id,
        name: category.name.trim(),
        description: category.description.trim(),
        createdAt: category.createdAt,
        updatedAt: now,
      );

      await document.set(
        data.toMap(),
        SetOptions(merge: false),
      );

      return document.id;
    } on FirebaseException catch (error) {
      throw FoodCategoryServiceException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    } catch (error) {
      throw FoodCategoryServiceException(
        message: 'Unable to create category: $error',
      );
    }
  }

  // ===========================================================
  // GET SINGLE CATEGORY
  // ===========================================================

  Future<RestaurantMenuCategoryModel?> getCategoryById({
    required String restaurantId,
    required String categoryId,
  }) async {
    if (restaurantId.trim().isEmpty ||
        categoryId.trim().isEmpty) {
      return null;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _categoriesRef(restaurantId)
              .doc(categoryId)
              .get();

      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }

      return _categoryFromSnapshot(
        snapshot,
        restaurantId: restaurantId,
      );
    } on FirebaseException catch (error) {
      throw FoodCategoryServiceException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    } catch (error) {
      throw FoodCategoryServiceException(
        message: 'Unable to load category: $error',
      );
    }
  }

  Stream<RestaurantMenuCategoryModel?> watchCategoryById({
    required String restaurantId,
    required String categoryId,
  }) {
    if (restaurantId.trim().isEmpty ||
        categoryId.trim().isEmpty) {
      return Stream<RestaurantMenuCategoryModel?>.value(
        null,
      );
    }

    return _categoriesRef(restaurantId)
        .doc(categoryId)
        .snapshots()
        .map(
      (DocumentSnapshot<Map<String, dynamic>> snapshot) {
        if (!snapshot.exists || snapshot.data() == null) {
          return null;
        }

        return _categoryFromSnapshot(
          snapshot,
          restaurantId: restaurantId,
        );
      },
    );
  }

  // ===========================================================
  // OWNER CATEGORY LIST
  // ===========================================================

  Stream<List<RestaurantMenuCategoryModel>>
      watchOwnerCategories(
    String restaurantId,
  ) {
    if (restaurantId.trim().isEmpty) {
      return Stream<
          List<RestaurantMenuCategoryModel>>.value(
        const <RestaurantMenuCategoryModel>[],
      );
    }

    return _categoriesRef(restaurantId)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) =>
              _categoryListFromQuery(
            snapshot,
            restaurantId: restaurantId,
            customerOnly: false,
          ),
        );
  }

  Future<List<RestaurantMenuCategoryModel>>
      getOwnerCategories(
    String restaurantId,
  ) async {
    _validateRestaurantId(restaurantId);

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _categoriesRef(restaurantId).get();

      return _categoryListFromQuery(
        snapshot,
        restaurantId: restaurantId,
        customerOnly: false,
      );
    } on FirebaseException catch (error) {
      throw FoodCategoryServiceException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    } catch (error) {
      throw FoodCategoryServiceException(
        message: 'Unable to load categories: $error',
      );
    }
  }

  // ===========================================================
  // CUSTOMER CATEGORY LIST
  // ===========================================================

  Stream<List<RestaurantMenuCategoryModel>>
      watchCustomerCategories(
    String restaurantId,
  ) {
    if (restaurantId.trim().isEmpty) {
      return Stream<
          List<RestaurantMenuCategoryModel>>.value(
        const <RestaurantMenuCategoryModel>[],
      );
    }

    return _categoriesRef(restaurantId)
        .where('isActive', isEqualTo: true)
        .where('isVisible', isEqualTo: true)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) =>
              _categoryListFromQuery(
            snapshot,
            restaurantId: restaurantId,
            customerOnly: true,
          ),
        );
  }

  Stream<List<RestaurantMenuCategoryModel>>
      watchFeaturedCategories(
    String restaurantId, {
    int limit = 20,
  }) {
    if (restaurantId.trim().isEmpty) {
      return Stream<
          List<RestaurantMenuCategoryModel>>.value(
        const <RestaurantMenuCategoryModel>[],
      );
    }

    return _categoriesRef(restaurantId)
        .where('isActive', isEqualTo: true)
        .where('isVisible', isEqualTo: true)
        .where('isFeatured', isEqualTo: true)
        .limit(limit)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) =>
              _categoryListFromQuery(
            snapshot,
            restaurantId: restaurantId,
            customerOnly: true,
          ),
        );
  }

  // ===========================================================
  // SEARCH
  // ===========================================================

  Future<List<RestaurantMenuCategoryModel>>
      searchCategories({
    required String restaurantId,
    required String query,
  }) async {
    final List<RestaurantMenuCategoryModel> categories =
        await getOwnerCategories(restaurantId);

    final String normalized =
        query.trim().toLowerCase();

    if (normalized.isEmpty) {
      return categories;
    }

    return categories.where(
      (RestaurantMenuCategoryModel category) {
        final String searchable = <String>[
          category.name,
          category.description,
        ].join(' ').toLowerCase();

        return searchable.contains(normalized);
      },
    ).toList();
  }

  // ===========================================================
  // UPDATE CATEGORY
  // ===========================================================

  Future<void> updateCategory(
    RestaurantMenuCategoryModel category,
  ) async {
    _validateRestaurantId(category.restaurantId);

    if (category.id.trim().isEmpty) {
      throw const FoodCategoryServiceException(
        message: 'Category ID is required.',
      );
    }

    if (category.name.trim().isEmpty) {
      throw const FoodCategoryServiceException(
        message: 'Category name is required.',
      );
    }

    try {
      await _categoriesRef(category.restaurantId)
          .doc(category.id)
          .set(
            category
                .copyWith(
                  name: category.name.trim(),
                  description:
                      category.description.trim(),
                  updatedAt: DateTime.now(),
                )
                .toMap(),
            SetOptions(merge: true),
          );
    } on FirebaseException catch (error) {
      throw FoodCategoryServiceException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    } catch (error) {
      throw FoodCategoryServiceException(
        message: 'Unable to update category: $error',
      );
    }
  }

  Future<void> updateCategoryFields({
    required String restaurantId,
    required String categoryId,
    required Map<String, dynamic> fields,
  }) async {
    _validateRestaurantId(restaurantId);

    if (categoryId.trim().isEmpty) {
      throw const FoodCategoryServiceException(
        message: 'Category ID is required.',
      );
    }

    try {
      await _categoriesRef(restaurantId)
          .doc(categoryId)
          .update(
        <String, dynamic>{
          ...fields,
          'updatedAt':
              DateTime.now().toIso8601String(),
        },
      );
    } on FirebaseException catch (error) {
      throw FoodCategoryServiceException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    } catch (error) {
      throw FoodCategoryServiceException(
        message:
            'Unable to update category fields: $error',
      );
    }
  }

  // ===========================================================
  // OWNER CONTROLS
  // ===========================================================

  Future<void> setActiveStatus({
    required String restaurantId,
    required String categoryId,
    required bool isActive,
  }) {
    return updateCategoryFields(
      restaurantId: restaurantId,
      categoryId: categoryId,
      fields: <String, dynamic>{
        'isActive': isActive,
      },
    );
  }

  Future<void> setVisibility({
    required String restaurantId,
    required String categoryId,
    required bool isVisible,
  }) {
    return updateCategoryFields(
      restaurantId: restaurantId,
      categoryId: categoryId,
      fields: <String, dynamic>{
        'isVisible': isVisible,
      },
    );
  }

  Future<void> setFeaturedStatus({
    required String restaurantId,
    required String categoryId,
    required bool isFeatured,
  }) {
    return updateCategoryFields(
      restaurantId: restaurantId,
      categoryId: categoryId,
      fields: <String, dynamic>{
        'isFeatured': isFeatured,
      },
    );
  }

  Future<void> updateSortOrder({
    required String restaurantId,
    required String categoryId,
    required int sortOrder,
  }) {
    return updateCategoryFields(
      restaurantId: restaurantId,
      categoryId: categoryId,
      fields: <String, dynamic>{
        'sortOrder': sortOrder,
      },
    );
  }

  Future<void> updateLocalImagePath({
    required String restaurantId,
    required String categoryId,
    required String localImagePath,
  }) {
    // Firebase Storage remains bypassed.
    return updateCategoryFields(
      restaurantId: restaurantId,
      categoryId: categoryId,
      fields: <String, dynamic>{
        'localImagePath': localImagePath.trim(),
      },
    );
  }

  Future<void> updateItemCount({
    required String restaurantId,
    required String categoryId,
    required int totalItems,
  }) {
    return updateCategoryFields(
      restaurantId: restaurantId,
      categoryId: categoryId,
      fields: <String, dynamic>{
        'totalItems':
            totalItems < 0 ? 0 : totalItems,
      },
    );
  }

  // ===========================================================
  // REORDER CATEGORIES
  // ===========================================================

  Future<void> reorderCategories({
    required String restaurantId,
    required List<RestaurantMenuCategoryModel>
        categories,
  }) async {
    _validateRestaurantId(restaurantId);

    if (categories.isEmpty) {
      return;
    }

    try {
      final WriteBatch batch = _firestore.batch();
      final DateTime now = DateTime.now();

      for (int index = 0;
          index < categories.length;
          index++) {
        final RestaurantMenuCategoryModel category =
            categories[index];

        if (category.id.trim().isEmpty) {
          continue;
        }

        batch.update(
          _categoriesRef(restaurantId)
              .doc(category.id),
          <String, dynamic>{
            'sortOrder': index,
            'updatedAt': now.toIso8601String(),
          },
        );
      }

      await batch.commit();
    } on FirebaseException catch (error) {
      throw FoodCategoryServiceException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    } catch (error) {
      throw FoodCategoryServiceException(
        message: 'Unable to reorder categories: $error',
      );
    }
  }

  // ===========================================================
  // DELETE CATEGORY
  // ===========================================================

  Future<void> deleteCategory({
    required String restaurantId,
    required String categoryId,
    bool allowWhenItemsExist = false,
  }) async {
    _validateRestaurantId(restaurantId);

    if (categoryId.trim().isEmpty) {
      throw const FoodCategoryServiceException(
        message: 'Category ID is required.',
      );
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _categoriesRef(restaurantId)
              .doc(categoryId)
              .get();

      if (!snapshot.exists) {
        return;
      }

      final int totalItems =
          _intValue(
        snapshot.data()?['totalItems'],
      );

      if (!allowWhenItemsExist && totalItems > 0) {
        throw const FoodCategoryServiceException(
          message:
              'Move or delete the food items inside this category first.',
        );
      }

      await snapshot.reference.delete();
    } on FoodCategoryServiceException {
      rethrow;
    } on FirebaseException catch (error) {
      throw FoodCategoryServiceException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    } catch (error) {
      throw FoodCategoryServiceException(
        message: 'Unable to delete category: $error',
      );
    }
  }

  // ===========================================================
  // INTERNAL MAPPERS
  // ===========================================================

  RestaurantMenuCategoryModel _categoryFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot, {
    required String restaurantId,
  }) {
    final Map<String, dynamic> data =
        Map<String, dynamic>.from(
      snapshot.data() ?? const <String, dynamic>{},
    );

    data['id'] = snapshot.id;
    data['restaurantId'] = restaurantId;

    return RestaurantMenuCategoryModel.fromMap(data);
  }

  List<RestaurantMenuCategoryModel>
      _categoryListFromQuery(
    QuerySnapshot<Map<String, dynamic>> snapshot, {
    required String restaurantId,
    required bool customerOnly,
  }) {
    final List<RestaurantMenuCategoryModel> categories =
        snapshot.docs
            .map(
              (
                DocumentSnapshot<Map<String, dynamic>>
                    document,
              ) =>
                  _categoryFromSnapshot(
                document,
                restaurantId: restaurantId,
              ),
            )
            .where(
              (
                RestaurantMenuCategoryModel category,
              ) =>
                  !customerOnly ||
                  category.canShowToCustomer,
            )
            .toList();

    categories.sort(
      (
        RestaurantMenuCategoryModel first,
        RestaurantMenuCategoryModel second,
      ) {
        if (first.isFeatured != second.isFeatured) {
          return first.isFeatured ? -1 : 1;
        }

        final int sortComparison =
            first.sortOrder.compareTo(
          second.sortOrder,
        );

        if (sortComparison != 0) {
          return sortComparison;
        }

        return first.name.toLowerCase().compareTo(
              second.name.toLowerCase(),
            );
      },
    );

    return categories;
  }

  void _validateRestaurantId(
    String restaurantId,
  ) {
    if (restaurantId.trim().isEmpty) {
      throw const FoodCategoryServiceException(
        message: 'Restaurant ID is required.',
      );
    }
  }

  static int _intValue(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  String _firebaseMessage(
    FirebaseException error,
  ) {
    switch (error.code) {
      case 'permission-denied':
        return 'You do not have permission to manage these menu categories.';
      case 'unavailable':
        return 'Firebase is temporarily unavailable. Please try again.';
      case 'not-found':
        return 'The requested menu category was not found.';
      case 'already-exists':
        return 'This menu category already exists.';
      case 'failed-precondition':
        return 'Firebase requires an index or another condition before this action can run.';
      default:
        return error.message ??
            'A Firebase error occurred (${error.code}).';
    }
  }
}

class FoodCategoryServiceException implements Exception {
  const FoodCategoryServiceException({
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

    return 'FoodCategoryServiceException($code): $message';
  }
}
