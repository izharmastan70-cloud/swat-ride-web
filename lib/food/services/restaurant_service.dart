// lib/food/services/restaurant_service.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Restaurant Firestore Service
//
// Real Firestore CRUD and live streams.
// Firebase Storage uploads remain bypassed for now.
// =============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/restaurant_model.dart';

class RestaurantService {
  RestaurantService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String restaurantsCollection = 'food_restaurants';

  CollectionReference<Map<String, dynamic>>
      get _restaurantsRef =>
          _firestore.collection(restaurantsCollection);

  // ===========================================================
  // CREATE RESTAURANT
  // ===========================================================

  Future<String> createRestaurant(
    RestaurantModel restaurant,
  ) async {
    try {
      final DocumentReference<Map<String, dynamic>> document =
          restaurant.id.trim().isEmpty
              ? _restaurantsRef.doc()
              : _restaurantsRef.doc(restaurant.id);

      final DateTime now = DateTime.now();

      final RestaurantModel data = restaurant.copyWith(
        id: document.id,
        createdAt: restaurant.createdAt,
        updatedAt: now,
      );

      await document.set(
        data.toMap(),
        SetOptions(merge: false),
      );

      return document.id;
    } on FirebaseException catch (error) {
      throw RestaurantServiceException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    } catch (error) {
      throw RestaurantServiceException(
        message: 'Unable to create restaurant: $error',
      );
    }
  }

  // ===========================================================
  // GET SINGLE RESTAURANT
  // ===========================================================

  Future<RestaurantModel?> getRestaurantById(
    String restaurantId,
  ) async {
    if (restaurantId.trim().isEmpty) {
      return null;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _restaurantsRef.doc(restaurantId).get();

      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }

      return _restaurantFromSnapshot(snapshot);
    } on FirebaseException catch (error) {
      throw RestaurantServiceException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    } catch (error) {
      throw RestaurantServiceException(
        message: 'Unable to load restaurant: $error',
      );
    }
  }

  Stream<RestaurantModel?> watchRestaurantById(
    String restaurantId,
  ) {
    if (restaurantId.trim().isEmpty) {
      return Stream<RestaurantModel?>.value(null);
    }

    return _restaurantsRef
        .doc(restaurantId)
        .snapshots()
        .map((DocumentSnapshot<Map<String, dynamic>> snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }

      return _restaurantFromSnapshot(snapshot);
    });
  }

  // ===========================================================
  // CUSTOMER RESTAURANT LISTS
  // ===========================================================

  Stream<List<RestaurantModel>> watchApprovedRestaurants({
    int limit = 50,
  }) {
    return _restaurantsRef
        .where('isApproved', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .where('isSuspended', isEqualTo: false)
        .limit(limit)
        .snapshots()
        .map(_restaurantListFromQuery);
  }

  Stream<List<RestaurantModel>> watchOpenRestaurants({
    int limit = 50,
  }) {
    return _restaurantsRef
        .where('isApproved', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .where('isSuspended', isEqualTo: false)
        .where('isOpen', isEqualTo: true)
        .limit(limit)
        .snapshots()
        .map(_restaurantListFromQuery);
  }

  Stream<List<RestaurantModel>> watchFeaturedRestaurants({
    int limit = 20,
  }) {
    return _restaurantsRef
        .where('isApproved', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .where('isFeatured', isEqualTo: true)
        .limit(limit)
        .snapshots()
        .map(_restaurantListFromQuery);
  }

  Stream<List<RestaurantModel>> watchPopularRestaurants({
    int limit = 20,
  }) {
    return _restaurantsRef
        .where('isApproved', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .where('isPopular', isEqualTo: true)
        .limit(limit)
        .snapshots()
        .map(_restaurantListFromQuery);
  }

  // ===========================================================
  // OWNER RESTAURANT LIST
  // ===========================================================

  Stream<List<RestaurantModel>> watchOwnerRestaurants(
    String ownerId,
  ) {
    if (ownerId.trim().isEmpty) {
      return Stream<List<RestaurantModel>>.value(
        const <RestaurantModel>[],
      );
    }

    return _restaurantsRef
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map(_restaurantListFromQuery);
  }

  Future<List<RestaurantModel>> getOwnerRestaurants(
    String ownerId,
  ) async {
    if (ownerId.trim().isEmpty) {
      return const <RestaurantModel>[];
    }

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _restaurantsRef
              .where('ownerId', isEqualTo: ownerId)
              .get();

      return _restaurantListFromQuery(snapshot);
    } on FirebaseException catch (error) {
      throw RestaurantServiceException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    } catch (error) {
      throw RestaurantServiceException(
        message: 'Unable to load owner restaurants: $error',
      );
    }
  }

  // ===========================================================
  // SEARCH AND FILTER
  // ===========================================================

  Future<List<RestaurantModel>> searchRestaurants(
    String query, {
    int limit = 100,
  }) async {
    final String normalizedQuery =
        query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return getApprovedRestaurants(limit: limit);
    }

    final List<RestaurantModel> restaurants =
        await getApprovedRestaurants(limit: limit);

    return restaurants.where((RestaurantModel restaurant) {
      final String searchableText = <String>[
        restaurant.name,
        restaurant.description,
        restaurant.address,
        restaurant.area,
        restaurant.city,
        ...restaurant.categories,
        ...restaurant.foodTypes,
      ].join(' ').toLowerCase();

      return searchableText.contains(normalizedQuery);
    }).toList();
  }

  Future<List<RestaurantModel>>
      getRestaurantsByCategory(
    String category, {
    int limit = 100,
  }) async {
    final String normalizedCategory =
        category.trim().toLowerCase();

    if (normalizedCategory.isEmpty) {
      return getApprovedRestaurants(limit: limit);
    }

    final List<RestaurantModel> restaurants =
        await getApprovedRestaurants(limit: limit);

    return restaurants.where((RestaurantModel restaurant) {
      return restaurant.categories.any(
            (String item) =>
                item.trim().toLowerCase() ==
                normalizedCategory,
          ) ||
          restaurant.foodTypes.any(
            (String item) =>
                item.trim().toLowerCase() ==
                normalizedCategory,
          );
    }).toList();
  }

  Future<List<RestaurantModel>> getApprovedRestaurants({
    int limit = 100,
  }) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _restaurantsRef
              .where('isApproved', isEqualTo: true)
              .where('isActive', isEqualTo: true)
              .where('isSuspended', isEqualTo: false)
              .limit(limit)
              .get();

      return _restaurantListFromQuery(snapshot);
    } on FirebaseException catch (error) {
      throw RestaurantServiceException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    } catch (error) {
      throw RestaurantServiceException(
        message: 'Unable to load restaurants: $error',
      );
    }
  }

  // ===========================================================
  // UPDATE RESTAURANT
  // ===========================================================

  Future<void> updateRestaurant(
    RestaurantModel restaurant,
  ) async {
    if (restaurant.id.trim().isEmpty) {
      throw const RestaurantServiceException(
        message: 'Restaurant ID is required.',
      );
    }

    try {
      await _restaurantsRef.doc(restaurant.id).set(
            restaurant
                .copyWith(updatedAt: DateTime.now())
                .toMap(),
            SetOptions(merge: true),
          );
    } on FirebaseException catch (error) {
      throw RestaurantServiceException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    } catch (error) {
      throw RestaurantServiceException(
        message: 'Unable to update restaurant: $error',
      );
    }
  }

  Future<void> updateRestaurantFields({
    required String restaurantId,
    required Map<String, dynamic> fields,
  }) async {
    if (restaurantId.trim().isEmpty) {
      throw const RestaurantServiceException(
        message: 'Restaurant ID is required.',
      );
    }

    try {
      await _restaurantsRef.doc(restaurantId).update(
        <String, dynamic>{
          ...fields,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    } on FirebaseException catch (error) {
      throw RestaurantServiceException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    } catch (error) {
      throw RestaurantServiceException(
        message: 'Unable to update restaurant fields: $error',
      );
    }
  }

  // ===========================================================
  // OWNER OPERATIONS
  // ===========================================================

  Future<void> setRestaurantOpenStatus({
    required String restaurantId,
    required bool isOpen,
  }) {
    return updateRestaurantFields(
      restaurantId: restaurantId,
      fields: <String, dynamic>{
        'isOpen': isOpen,
      },
    );
  }

  Future<void> setRestaurantBusyStatus({
    required String restaurantId,
    required bool isBusy,
  }) {
    return updateRestaurantFields(
      restaurantId: restaurantId,
      fields: <String, dynamic>{
        'isBusy': isBusy,
      },
    );
  }

  Future<void> setTemporaryClosure({
    required String restaurantId,
    required bool isClosed,
    String reason = '',
  }) {
    return updateRestaurantFields(
      restaurantId: restaurantId,
      fields: <String, dynamic>{
        'isTemporarilyClosed': isClosed,
        'temporaryClosingReason':
            isClosed ? reason.trim() : '',
        'isOpen': isClosed ? false : true,
      },
    );
  }

  Future<void> updateOriginalMenuImages({
    required String restaurantId,
    required List<String> imagePathsOrUrls,
  }) {
    // Firebase Storage is bypassed for now.
    // These values may temporarily be local paths or future URLs.
    return updateRestaurantFields(
      restaurantId: restaurantId,
      fields: <String, dynamic>{
        'originalMenuImageUrls': imagePathsOrUrls,
        'hasOriginalMenuImages':
            imagePathsOrUrls.isNotEmpty,
        'menuLastUpdatedAt':
            DateTime.now().toIso8601String(),
      },
    );
  }

  // ===========================================================
  // ADMIN OPERATIONS
  // ===========================================================

  Future<void> approveRestaurant(
    String restaurantId,
  ) {
    final DateTime now = DateTime.now();

    return updateRestaurantFields(
      restaurantId: restaurantId,
      fields: <String, dynamic>{
        'approvalStatus':
            RestaurantApprovalStatus.approved.name,
        'isApproved': true,
        'isActive': true,
        'isSuspended': false,
        'rejectionReason': '',
        'suspensionReason': '',
        'approvedAt': now.toIso8601String(),
      },
    );
  }

  Future<void> rejectRestaurant({
    required String restaurantId,
    required String reason,
  }) {
    return updateRestaurantFields(
      restaurantId: restaurantId,
      fields: <String, dynamic>{
        'approvalStatus':
            RestaurantApprovalStatus.rejected.name,
        'isApproved': false,
        'isActive': false,
        'rejectionReason': reason.trim(),
      },
    );
  }

  Future<void> suspendRestaurant({
    required String restaurantId,
    required String reason,
  }) {
    return updateRestaurantFields(
      restaurantId: restaurantId,
      fields: <String, dynamic>{
        'approvalStatus':
            RestaurantApprovalStatus.suspended.name,
        'isSuspended': true,
        'isActive': false,
        'isOpen': false,
        'suspensionReason': reason.trim(),
      },
    );
  }

  Future<void> restoreRestaurant(
    String restaurantId,
  ) {
    return updateRestaurantFields(
      restaurantId: restaurantId,
      fields: <String, dynamic>{
        'approvalStatus':
            RestaurantApprovalStatus.approved.name,
        'isApproved': true,
        'isActive': true,
        'isSuspended': false,
        'suspensionReason': '',
      },
    );
  }

  Future<void> updateCommission({
    required String restaurantId,
    required double commissionPercentage,
  }) {
    final double safeCommission =
        commissionPercentage.clamp(0, 100).toDouble();

    return updateRestaurantFields(
      restaurantId: restaurantId,
      fields: <String, dynamic>{
        'commissionPercentage': safeCommission,
      },
    );
  }

  // ===========================================================
  // DELETE
  // ===========================================================

  Future<void> deleteRestaurant(
    String restaurantId,
  ) async {
    if (restaurantId.trim().isEmpty) {
      throw const RestaurantServiceException(
        message: 'Restaurant ID is required.',
      );
    }

    try {
      await _restaurantsRef.doc(restaurantId).delete();
    } on FirebaseException catch (error) {
      throw RestaurantServiceException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    } catch (error) {
      throw RestaurantServiceException(
        message: 'Unable to delete restaurant: $error',
      );
    }
  }

  // ===========================================================
  // INTERNAL MAPPERS
  // ===========================================================

  RestaurantModel _restaurantFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final Map<String, dynamic> data =
        Map<String, dynamic>.from(
      snapshot.data() ?? const <String, dynamic>{},
    );

    data['id'] = snapshot.id;

    return RestaurantModel.fromMap(data);
  }

  List<RestaurantModel> _restaurantListFromQuery(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final List<RestaurantModel> restaurants =
        snapshot.docs
            .map(_restaurantFromSnapshot)
            .toList();

    restaurants.sort(
      (
        RestaurantModel first,
        RestaurantModel second,
      ) {
        if (first.isFeatured != second.isFeatured) {
          return first.isFeatured ? -1 : 1;
        }

        if (first.isOpen != second.isOpen) {
          return first.isOpen ? -1 : 1;
        }

        return second.rating.compareTo(first.rating);
      },
    );

    return restaurants;
  }

  String _firebaseMessage(
    FirebaseException error,
  ) {
    switch (error.code) {
      case 'permission-denied':
        return 'You do not have permission to perform this action.';
      case 'unavailable':
        return 'Firebase is temporarily unavailable. Please try again.';
      case 'not-found':
        return 'Restaurant record was not found.';
      case 'already-exists':
        return 'This restaurant record already exists.';
      case 'failed-precondition':
        return 'Firebase requires an index or another condition before this action can run.';
      default:
        return error.message ??
            'A Firebase error occurred (${error.code}).';
    }
  }
}

class RestaurantServiceException implements Exception {
  const RestaurantServiceException({
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

    return 'RestaurantServiceException($code): $message';
  }
}
