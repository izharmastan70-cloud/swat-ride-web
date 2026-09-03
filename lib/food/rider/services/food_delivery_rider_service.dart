// lib/food/rider/services/food_delivery_rider_service.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Food Delivery Rider Firestore Service
//
// Connected with:
// - FoodDeliveryRiderModel
// - FoodOrderModel
//
// Firestore collections:
// food_delivery_riders/{riderId}
// food_orders/{orderId}
//
// Real Firestore logic is enabled.
// Firebase Storage and paid map rendering remain bypassed.
// =============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/food_order_model.dart';
import '../models/food_delivery_rider_model.dart';
import '../../services/food_notification_service.dart';

class FoodDeliveryRiderService {
  FoodDeliveryRiderService({
    FirebaseFirestore? firestore,
    FoodNotificationService? notificationService,
  })  : _firestore =
            firestore ?? FirebaseFirestore.instance,
        _notificationService =
            notificationService ??
                FoodNotificationService(
                  firestore:
                      firestore ??
                          FirebaseFirestore.instance,
                );

  final FirebaseFirestore _firestore;
  final FoodNotificationService _notificationService;

  static const String ridersCollection =
      'food_delivery_riders';

  static const String ordersCollection =
      'food_orders';

  static const String adminSettingsCollection =
      'food_admin_settings';

  static const String adminWalletDocument =
      'admin_wallet';

  static const String commissionLedgerCollection =
      'food_commission_settlements';

  CollectionReference<Map<String, dynamic>>
      get _ridersRef =>
          _firestore.collection(ridersCollection);

  CollectionReference<Map<String, dynamic>>
      get _ordersRef =>
          _firestore.collection(ordersCollection);

  DocumentReference<Map<String, dynamic>>
      get _adminWalletRef => _firestore
          .collection(adminSettingsCollection)
          .doc(adminWalletDocument);

  CollectionReference<Map<String, dynamic>>
      get _commissionLedgerRef =>
          _firestore.collection(
            commissionLedgerCollection,
          );

  // ===========================================================
  // RIDER APPLICATION
  // ===========================================================

  Future<String> submitApplication(
    FoodDeliveryRiderModel rider,
  ) async {
    _validateApplication(rider);

    try {
      final DocumentReference<Map<String, dynamic>>
          document = rider.riderId.trim().isEmpty
              ? _ridersRef.doc()
              : _ridersRef.doc(rider.riderId);

      final DateTime now = DateTime.now();

      final FoodDeliveryRiderModel data =
          rider.copyWith(
        riderId: document.id,
        status: FoodDeliveryRiderStatus.pending,
        isApproved: false,
        isRejected: false,
        isSuspended: false,
        isActive: false,
        isOnline: false,
        isAvailable: false,
        isOnDelivery: false,
        currentOrderId: '',
        rejectionReason: '',
        suspensionReason: '',
        clearApprovedAt: true,
        createdAt: rider.riderId.trim().isEmpty
            ? now
            : rider.createdAt,
        updatedAt: now,
      );

      await document.set(
        data.toMap(),
        SetOptions(merge: false),
      );

      return document.id;
    } on FirebaseException catch (error) {
      throw FoodDeliveryRiderServiceException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    } catch (error) {
      throw FoodDeliveryRiderServiceException(
        message:
            'Unable to submit rider application: $error',
      );
    }
  }

  Future<void> updateApplication(
    FoodDeliveryRiderModel rider,
  ) async {
    if (rider.riderId.trim().isEmpty) {
      throw const FoodDeliveryRiderServiceException(
        message: 'Rider ID is required.',
      );
    }

    _validateApplication(rider);

    try {
      await _ridersRef
          .doc(rider.riderId)
          .set(
            rider
                .copyWith(
                  updatedAt: DateTime.now(),
                )
                .toMap(),
            SetOptions(merge: true),
          );
    } on FirebaseException catch (error) {
      throw FoodDeliveryRiderServiceException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    } catch (error) {
      throw FoodDeliveryRiderServiceException(
        message:
            'Unable to update rider application: $error',
      );
    }
  }

  // ===========================================================
  // RIDER LOOKUP
  // ===========================================================

  Future<FoodDeliveryRiderModel?> getRiderById(
    String riderId,
  ) async {
    if (riderId.trim().isEmpty) {
      return null;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>>
          snapshot =
          await _ridersRef.doc(riderId).get();

      if (!snapshot.exists ||
          snapshot.data() == null) {
        return null;
      }

      return _riderFromSnapshot(snapshot);
    } on FirebaseException catch (error) {
      throw FoodDeliveryRiderServiceException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    }
  }

  Stream<FoodDeliveryRiderModel?>
      watchRiderById(
    String riderId,
  ) {
    if (riderId.trim().isEmpty) {
      return Stream<
          FoodDeliveryRiderModel?>.value(null);
    }

    return _ridersRef
        .doc(riderId)
        .snapshots()
        .map(
      (
        DocumentSnapshot<Map<String, dynamic>>
            snapshot,
      ) {
        if (!snapshot.exists ||
            snapshot.data() == null) {
          return null;
        }

        return _riderFromSnapshot(snapshot);
      },
    );
  }

  Future<FoodDeliveryRiderModel?> getRiderByUserId(
    String userId,
  ) async {
    if (userId.trim().isEmpty) {
      return null;
    }

    try {
      final QuerySnapshot<Map<String, dynamic>>
          snapshot = await _ridersRef
              .where(
                'userId',
                isEqualTo: userId,
              )
              .limit(1)
              .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return _riderFromSnapshot(
        snapshot.docs.first,
      );
    } on FirebaseException catch (error) {
      throw FoodDeliveryRiderServiceException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    }
  }

  Stream<FoodDeliveryRiderModel?>
      watchRiderByUserId(
    String userId,
  ) {
    if (userId.trim().isEmpty) {
      return Stream<
          FoodDeliveryRiderModel?>.value(null);
    }

    return _ridersRef
        .where(
          'userId',
          isEqualTo: userId,
        )
        .limit(1)
        .snapshots()
        .map(
      (
        QuerySnapshot<Map<String, dynamic>>
            snapshot,
      ) {
        if (snapshot.docs.isEmpty) {
          return null;
        }

        return _riderFromSnapshot(
          snapshot.docs.first,
        );
      },
    );
  }

  Stream<List<FoodDeliveryRiderModel>>
      watchAllApplications() {
    return _ridersRef.snapshots().map(
      (
        QuerySnapshot<Map<String, dynamic>>
            snapshot,
      ) {
        final List<FoodDeliveryRiderModel>
            riders = snapshot.docs
                .map(_riderFromSnapshot)
                .toList();

        riders.sort(
          (
            FoodDeliveryRiderModel first,
            FoodDeliveryRiderModel second,
          ) =>
              second.createdAt.compareTo(
            first.createdAt,
          ),
        );

        return riders;
      },
    );
  }

  Stream<List<FoodDeliveryRiderModel>>
      watchApprovedAvailableRiders({
    String city = '',
  }) {
    Query<Map<String, dynamic>> query =
        _ridersRef
            .where(
              'status',
              isEqualTo:
                  FoodDeliveryRiderStatus
                      .approved.value,
            )
            .where(
              'isApproved',
              isEqualTo: true,
            )
            .where(
              'isActive',
              isEqualTo: true,
            )
            .where(
              'isOnline',
              isEqualTo: true,
            )
            .where(
              'isAvailable',
              isEqualTo: true,
            )
            .where(
              'isOnDelivery',
              isEqualTo: false,
            );

    if (city.trim().isNotEmpty) {
      query = query.where(
        'city',
        isEqualTo: city.trim(),
      );
    }

    return query.snapshots().map(
      (
        QuerySnapshot<Map<String, dynamic>>
            snapshot,
      ) =>
          snapshot.docs
              .map(_riderFromSnapshot)
              .toList(),
    );
  }

  // ===========================================================
  // ADMIN APPROVAL
  // ===========================================================

  Future<void> markUnderReview(
    String riderId,
  ) {
    return updateRiderFields(
      riderId: riderId,
      fields: <String, dynamic>{
        'status':
            FoodDeliveryRiderStatus
                .underReview.value,
      },
    );
  }

  Future<void> approveRider({
    required String riderId,
    double commissionPercentage = 0,
    required String reviewedBy,
    String adminNote = '',
  }) async {
    final String reviewerId = reviewedBy.trim();
    if (reviewerId.isEmpty) {
      throw const FoodDeliveryRiderServiceException(
        message: 'Authenticated Food Admin is required.',
      );
    }

    final double safeCommission =
        commissionPercentage.clamp(0, 100);

    await updateRiderFields(
      riderId: riderId,
      fields: <String, dynamic>{
        'status':
            FoodDeliveryRiderStatus
                .approved.value,
        'isApproved': true,
        'isRejected': false,
        'isSuspended': false,
        'isActive': true,
        'rejectionReason': '',
        'suspensionReason': '',
        'commissionPercentage':
            safeCommission,
        'approvedAt':
            DateTime.now().toIso8601String(),
        'adminNote': adminNote.trim(),
        'reviewedBy': reviewerId,
        'reviewedAt': FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> rejectRider({
    required String riderId,
    required String reason,
    required String reviewedBy,
  }) {
    final String reviewerId = reviewedBy.trim();
    if (reviewerId.isEmpty) {
      throw const FoodDeliveryRiderServiceException(
        message: 'Authenticated Food Admin is required.',
      );
    }

    if (reason.trim().isEmpty) {
      throw const FoodDeliveryRiderServiceException(
        message: 'Rejection reason is required.',
      );
    }

    return updateRiderFields(
      riderId: riderId,
      fields: <String, dynamic>{
        'status':
            FoodDeliveryRiderStatus
                .rejected.value,
        'isApproved': false,
        'isRejected': true,
        'isSuspended': false,
        'isActive': false,
        'isOnline': false,
        'isAvailable': false,
        'rejectionReason': reason.trim(),
        'adminNote': reason.trim(),
        'reviewedBy': reviewerId,
        'reviewedAt': FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> requestRiderApplicationCorrection({
    required String riderId,
    required String correctionNote,
    required String reviewedBy,
  }) async {
    final String note = correctionNote.trim();
    final String reviewerId = reviewedBy.trim();

    if (note.isEmpty) {
      throw const FoodDeliveryRiderServiceException(
        message: 'Correction instructions are required.',
      );
    }

    if (reviewerId.isEmpty) {
      throw const FoodDeliveryRiderServiceException(
        message: 'Authenticated Food Admin is required.',
      );
    }

    await updateRiderFields(
      riderId: riderId,
      fields: <String, dynamic>{
        'status': FoodDeliveryRiderStatus.underReview.value,
        'isApproved': false,
        'isRejected': false,
        'isSuspended': false,
        'isActive': false,
        'isOnline': false,
        'isAvailable': false,
        'rejectionReason': '',
        'adminNote': note,
        'reviewedBy': reviewerId,
        'reviewedAt': FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> resetRiderApplicationForReview({
    required String riderId,
    required String reviewedBy,
    String adminNote = 'Rider application reset for review.',
  }) async {
    final String reviewerId = reviewedBy.trim();
    if (reviewerId.isEmpty) {
      throw const FoodDeliveryRiderServiceException(
        message: 'Authenticated Food Admin is required.',
      );
    }

    await updateRiderFields(
      riderId: riderId,
      fields: <String, dynamic>{
        'status': FoodDeliveryRiderStatus.pending.value,
        'isApproved': false,
        'isRejected': false,
        'isSuspended': false,
        'isActive': false,
        'isOnline': false,
        'isAvailable': false,
        'rejectionReason': '',
        'suspensionReason': '',
        'adminNote': adminNote.trim(),
        'reviewedBy': reviewerId,
        'reviewedAt': FieldValue.serverTimestamp(),
      },
    );
  }
  Future<void> suspendRider({
    required String riderId,
    required String reason,
    required String reviewedBy,
  }) async {
    final String reviewerId = reviewedBy.trim();
    if (reviewerId.isEmpty) {
      throw const FoodDeliveryRiderServiceException(
        message: 'Authenticated Food Admin is required.',
      );
    }

    if (reason.trim().isEmpty) {
      throw const FoodDeliveryRiderServiceException(
        message: 'Suspension reason is required.',
      );
    }

    final FoodDeliveryRiderModel? rider =
        await getRiderById(riderId);

    if (rider == null) {
      throw const FoodDeliveryRiderServiceException(
        message: 'Food delivery rider was not found.',
      );
    }

    if (rider.isOnDelivery ||
        rider.currentOrderId.trim().isNotEmpty) {
      throw const FoodDeliveryRiderServiceException(
        message:
            'Rider cannot be suspended during an active delivery.',
      );
    }

    await updateRiderFields(
      riderId: riderId,
      fields: <String, dynamic>{
        'status':
            FoodDeliveryRiderStatus
                .suspended.value,
        'isSuspended': true,
        'isActive': false,
        'isOnline': false,
        'isAvailable': false,
        'suspensionReason': reason.trim(),
        'adminNote': reason.trim(),
        'reviewedBy': reviewerId,
        'reviewedAt': FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> restoreRider(
    String riderId, {
    required String reviewedBy,
    String adminNote = 'Food Rider access restored.',
  }) {
    final String reviewerId = reviewedBy.trim();
    if (reviewerId.isEmpty) {
      throw const FoodDeliveryRiderServiceException(
        message: 'Authenticated Food Admin is required.',
      );
    }

    return updateRiderFields(
      riderId: riderId,
      fields: <String, dynamic>{
        'status':
            FoodDeliveryRiderStatus
                .approved.value,
        'isApproved': true,
        'isRejected': false,
        'isSuspended': false,
        'isActive': true,
        'suspensionReason': '',
        'adminNote': adminNote.trim(),
        'reviewedBy': reviewerId,
        'reviewedAt': FieldValue.serverTimestamp(),
      },
    );
  }

  // ===========================================================
  // ONLINE / AVAILABILITY
  // ===========================================================

  Future<void> setOnlineStatus({
    required String riderId,
    required bool isOnline,
  }) async {
    final FoodDeliveryRiderModel? rider =
        await getRiderById(riderId);

    if (rider == null) {
      throw const FoodDeliveryRiderServiceException(
        message: 'Food delivery rider was not found.',
      );
    }

    if (isOnline &&
        !rider.canAccessRiderDashboard) {
      throw const FoodDeliveryRiderServiceException(
        message:
            'Admin approval is required before going online.',
      );
    }

    await updateRiderFields(
      riderId: riderId,
      fields: <String, dynamic>{
        'isOnline': isOnline,
        'isAvailable':
            isOnline &&
                !rider.isOnDelivery &&
                rider.currentOrderId
                    .trim()
                    .isEmpty,
      },
    );
  }

  Future<void> setAvailability({
    required String riderId,
    required bool isAvailable,
  }) async {
    final FoodDeliveryRiderModel? rider =
        await getRiderById(riderId);

    if (rider == null) {
      throw const FoodDeliveryRiderServiceException(
        message: 'Food delivery rider was not found.',
      );
    }

    if (isAvailable &&
        (!rider.canAccessRiderDashboard ||
            !rider.isOnline ||
            rider.isOnDelivery ||
            rider.currentOrderId
                .trim()
                .isNotEmpty)) {
      throw const FoodDeliveryRiderServiceException(
        message:
            'Rider cannot become available right now.',
      );
    }

    await updateRiderFields(
      riderId: riderId,
      fields: <String, dynamic>{
        'isAvailable': isAvailable,
      },
    );
  }

  // ===========================================================
  // LIVE LOCATION
  // ===========================================================

  Future<void> updateLiveLocation({
    required String riderId,
    required double latitude,
    required double longitude,
    double heading = 0,
    double speed = 0,
  }) async {
    if (latitude < -90 || latitude > 90) {
      throw const FoodDeliveryRiderServiceException(
        message: 'Invalid latitude.',
      );
    }

    if (longitude < -180 ||
        longitude > 180) {
      throw const FoodDeliveryRiderServiceException(
        message: 'Invalid longitude.',
      );
    }

    final DateTime now = DateTime.now();

    await updateRiderFields(
      riderId: riderId,
      fields: <String, dynamic>{
        'currentLatitude': latitude,
        'currentLongitude': longitude,
        'currentHeading': heading,
        'currentSpeed': speed,
        'lastLocationUpdate':
            now.toIso8601String(),
      },
    );

    final FoodDeliveryRiderModel? rider =
        await getRiderById(riderId);

    final String orderId =
        rider?.currentOrderId.trim() ?? '';

    if (orderId.isNotEmpty) {
      await _ordersRef
          .doc(orderId)
          .set(
        <String, dynamic>{
          'riderLatitude': latitude,
          'riderLongitude': longitude,
          'riderLocationUpdatedAt':
              now.toIso8601String(),
          'updatedAt':
              now.toIso8601String(),
        },
        SetOptions(merge: true),
      );
    }
  }

  // ===========================================================
  // AVAILABLE FOOD ORDERS
  // ===========================================================

  Future<FoodOrderModel?> getOrderById(
    String orderId,
  ) async {
    if (orderId.trim().isEmpty) {
      return null;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>>
          snapshot =
          await _ordersRef.doc(orderId).get();

      if (!snapshot.exists ||
          snapshot.data() == null) {
        return null;
      }

      return _orderFromSnapshot(snapshot);
    } on FirebaseException catch (error) {
      throw FoodDeliveryRiderServiceException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    } catch (error) {
      throw FoodDeliveryRiderServiceException(
        message:
            'Unable to load food order: $error',
      );
    }
  }

  Stream<List<FoodOrderModel>>
      watchAvailableOrders() {
    return _ordersRef
        .where(
          'status',
          isEqualTo:
              FoodOrderStatus
                  .readyForPickup.name,
        )
        .snapshots()
        .map(
      (
        QuerySnapshot<Map<String, dynamic>>
            snapshot,
      ) {
        final List<FoodOrderModel> orders =
            snapshot.docs
                .map(_orderFromSnapshot)
                .where(
          (FoodOrderModel order) =>
              order.riderId.trim().isEmpty,
        )
                .toList();

        orders.sort(
          (
            FoodOrderModel first,
            FoodOrderModel second,
          ) =>
              first.createdAt.compareTo(
            second.createdAt,
          ),
        );

        return orders;
      },
    );
  }

  Stream<List<FoodOrderModel>>
      watchRiderActiveOrders(
    String riderId,
  ) {
    if (riderId.trim().isEmpty) {
      return Stream<
          List<FoodOrderModel>>.value(
        const <FoodOrderModel>[],
      );
    }

    return _ordersRef
        .where(
          'riderId',
          isEqualTo: riderId,
        )
        .snapshots()
        .map(
      (
        QuerySnapshot<Map<String, dynamic>>
            snapshot,
      ) {
        final List<FoodOrderModel> orders =
            snapshot.docs
                .map(_orderFromSnapshot)
                .where(
          (FoodOrderModel order) =>
              order.status !=
                  FoodOrderStatus.delivered &&
              order.status !=
                  FoodOrderStatus.cancelled,
        )
                .toList();

        orders.sort(
          (
            FoodOrderModel first,
            FoodOrderModel second,
          ) =>
              second.updatedAt.compareTo(
            first.updatedAt,
          ),
        );

        return orders;
      },
    );
  }

  Stream<List<FoodOrderModel>>
      watchDeliveryHistory(
    String riderId,
  ) {
    if (riderId.trim().isEmpty) {
      return Stream<
          List<FoodOrderModel>>.value(
        const <FoodOrderModel>[],
      );
    }

    return _ordersRef
        .where(
          'riderId',
          isEqualTo: riderId,
        )
        .snapshots()
        .map(
      (
        QuerySnapshot<Map<String, dynamic>>
            snapshot,
      ) {
        final List<FoodOrderModel> orders =
            snapshot.docs
                .map(_orderFromSnapshot)
                .where(
          (FoodOrderModel order) =>
              order.status ==
                  FoodOrderStatus.delivered ||
              order.status ==
                  FoodOrderStatus.cancelled,
        )
                .toList();

        orders.sort(
          (
            FoodOrderModel first,
            FoodOrderModel second,
          ) =>
              second.updatedAt.compareTo(
            first.updatedAt,
          ),
        );

        return orders;
      },
    );
  }

  // ===========================================================
  // DELIVERY ASSIGNMENT
  // ===========================================================

  Future<void> acceptOrder({
    required String riderId,
    required String orderId,
  }) async {
    if (riderId.trim().isEmpty ||
        orderId.trim().isEmpty) {
      throw const FoodDeliveryRiderServiceException(
        message:
            'Rider ID and order ID are required.',
      );
    }

    final DocumentReference<Map<String, dynamic>>
        riderDocument =
        _ridersRef.doc(riderId);

    final DocumentReference<Map<String, dynamic>>
        orderDocument =
        _ordersRef.doc(orderId);

    try {
      await _firestore.runTransaction(
        (Transaction transaction) async {
          final DocumentSnapshot<
                  Map<String, dynamic>>
              riderSnapshot =
              await transaction.get(
            riderDocument,
          );

          final DocumentSnapshot<
                  Map<String, dynamic>>
              orderSnapshot =
              await transaction.get(
            orderDocument,
          );

          if (!riderSnapshot.exists ||
              riderSnapshot.data() == null) {
            throw const FoodDeliveryRiderServiceException(
              message:
                  'Food delivery rider was not found.',
            );
          }

          if (!orderSnapshot.exists ||
              orderSnapshot.data() == null) {
            throw const FoodDeliveryRiderServiceException(
              message: 'Food order was not found.',
            );
          }

          final FoodDeliveryRiderModel rider =
              _riderFromSnapshot(
            riderSnapshot,
          );

          final FoodOrderModel order =
              _orderFromSnapshot(
            orderSnapshot,
          );

          if (!rider.canReceiveOrders) {
            throw const FoodDeliveryRiderServiceException(
              message:
                  'Rider is not available to accept an order.',
            );
          }

          if (order.riderId.trim().isNotEmpty) {
            throw const FoodDeliveryRiderServiceException(
              message:
                  'This order is already assigned to another rider.',
            );
          }

          if (order.status !=
              FoodOrderStatus.readyForPickup) {
            throw const FoodDeliveryRiderServiceException(
              message:
                  'This order is not ready for rider pickup.',
            );
          }

          final DateTime now = DateTime.now();

          transaction.update(
            riderDocument,
            <String, dynamic>{
              'isAvailable': false,
              'isOnDelivery': true,
              'currentOrderId': orderId,
              'totalDeliveries':
                  rider.totalDeliveries + 1,
              'updatedAt':
                  now.toIso8601String(),
            },
          );

          transaction.update(
            orderDocument,
            <String, dynamic>{
              'riderId': riderId,
              'updatedAt':
                  now.toIso8601String(),
            },
          );
        },
      );

      final FoodOrderModel? assignedOrder =
          await getOrderById(orderId);

      if (assignedOrder != null) {
        final String partnerId =
            await _partnerIdForRestaurant(
          assignedOrder.restaurantId,
        );

        await _notificationService
            .notifyRiderAssigned(
          customerId: assignedOrder.customerId,
          partnerId: partnerId,
          restaurantId:
              assignedOrder.restaurantId,
          riderId: riderId,
          orderId: assignedOrder.orderId,
        );
      }

    } on FoodDeliveryRiderServiceException {
      rethrow;
    } on FirebaseException catch (error) {
      throw FoodDeliveryRiderServiceException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    } catch (error) {
      throw FoodDeliveryRiderServiceException(
        message:
            'Unable to accept food order: $error',
      );
    }
  }

  Future<void> rejectOrderRequest({
    required String riderId,
    required String orderId,
  }) async {
    final FoodDeliveryRiderModel? rider =
        await getRiderById(riderId);

    if (rider == null) {
      throw const FoodDeliveryRiderServiceException(
        message: 'Food delivery rider was not found.',
      );
    }

    await updateRiderFields(
      riderId: riderId,
      fields: <String, dynamic>{
        'rejectedRequests':
            rider.rejectedRequests + 1,
      },
    );
  }

  Future<void> confirmPickup({
    required String riderId,
    required String orderId,
  }) async {
    await _updateOrderAndRider(
      riderId: riderId,
      orderId: orderId,
      requiredOrderStatus:
          FoodOrderStatus.readyForPickup,
      nextOrderStatus:
          FoodOrderStatus.pickedUp,
      riderFields: const <String, dynamic>{},
    );

    final FoodOrderModel? order =
        await getOrderById(orderId);

    if (order != null) {
      final String partnerId =
          await _partnerIdForRestaurant(
        order.restaurantId,
      );

      await _notificationService.notifyPickedUp(
        customerId: order.customerId,
        partnerId: partnerId,
        restaurantId: order.restaurantId,
        riderId: riderId,
        orderId: order.orderId,
      );
    }
  }

  Future<void> startDelivery({
    required String riderId,
    required String orderId,
  }) async {
    await _updateOrderAndRider(
      riderId: riderId,
      orderId: orderId,
      requiredOrderStatus:
          FoodOrderStatus.pickedUp,
      nextOrderStatus:
          FoodOrderStatus.onTheWay,
      riderFields: const <String, dynamic>{},
    );

    final FoodOrderModel? order =
        await getOrderById(orderId);

    if (order != null) {
      await _notificationService.notifyOnTheWay(
        customerId: order.customerId,
        riderId: riderId,
        orderId: order.orderId,
      );
    }
  }

  Future<void> completeDelivery({
    required String riderId,
    required String orderId,
    required String enteredOtp,
    required String expectedOtp,
    required double riderEarning,
    required bool cashOrder,
  }) async {
    if (enteredOtp.trim().isEmpty ||
        expectedOtp.trim().isEmpty ||
        enteredOtp.trim() != expectedOtp.trim()) {
      throw const FoodDeliveryRiderServiceException(
        message: 'Invalid delivery OTP.',
      );
    }

    final DocumentReference<Map<String, dynamic>>
        riderDocument =
        _ridersRef.doc(riderId);

    final DocumentReference<Map<String, dynamic>>
        orderDocument =
        _ordersRef.doc(orderId);

    final DocumentReference<Map<String, dynamic>>
        ledgerDocument =
        _commissionLedgerRef.doc();

    try {
      await _firestore.runTransaction(
        (Transaction transaction) async {
          final DocumentSnapshot<
                  Map<String, dynamic>>
              riderSnapshot =
              await transaction.get(
            riderDocument,
          );

          final DocumentSnapshot<
                  Map<String, dynamic>>
              orderSnapshot =
              await transaction.get(
            orderDocument,
          );

          final DocumentSnapshot<
                  Map<String, dynamic>>
              adminWalletSnapshot =
              await transaction.get(
            _adminWalletRef,
          );

          if (!riderSnapshot.exists ||
              riderSnapshot.data() == null) {
            throw const FoodDeliveryRiderServiceException(
              message:
                  'Food delivery rider was not found.',
            );
          }

          if (!orderSnapshot.exists ||
              orderSnapshot.data() == null) {
            throw const FoodDeliveryRiderServiceException(
              message: 'Food order was not found.',
            );
          }

          final FoodDeliveryRiderModel rider =
              _riderFromSnapshot(
            riderSnapshot,
          );

          final FoodOrderModel order =
              _orderFromSnapshot(
            orderSnapshot,
          );

          if (order.riderId != riderId) {
            throw const FoodDeliveryRiderServiceException(
              message:
                  'This order is not assigned to this rider.',
            );
          }

          if (order.status !=
                  FoodOrderStatus.onTheWay &&
              order.status !=
                  FoodOrderStatus.pickedUp) {
            throw const FoodDeliveryRiderServiceException(
              message:
                  'Order cannot be completed from its current status.',
            );
          }

          final double safeGrossEarning =
              riderEarning < 0
                  ? 0
                  : riderEarning;

          final double commissionRate =
              rider.commissionPercentage
                  .clamp(0, 100)
                  .toDouble();

          final double commissionAmount =
              safeGrossEarning *
                  (commissionRate / 100);

          final double netEarning =
              safeGrossEarning -
                  commissionAmount;

          final Map<String, dynamic> adminData =
              adminWalletSnapshot.data() ??
                  const <String, dynamic>{};

          final double currentAdminBalance =
              _doubleValue(
            adminData['walletBalance'],
          );

          final double currentAdminReceived =
              _doubleValue(
            adminData['totalCommissionReceived'],
          );

          final double currentAdminReceivable =
              _doubleValue(
            adminData['totalOutstandingReceivable'],
          );

          double riderWalletAfter;
          double autoDeductedCommission;
          double remainingOutstanding;
          double adminCreditNow;

          if (cashOrder) {
            autoDeductedCommission =
                rider.walletBalance >=
                        commissionAmount
                    ? commissionAmount
                    : rider.walletBalance;

            remainingOutstanding =
                commissionAmount -
                    autoDeductedCommission;

            riderWalletAfter =
                rider.walletBalance -
                    autoDeductedCommission;

            adminCreditNow =
                autoDeductedCommission;
          } else {
            autoDeductedCommission =
                commissionAmount;

            remainingOutstanding = 0;

            riderWalletAfter =
                rider.walletBalance +
                    netEarning;

            adminCreditNow =
                commissionAmount;
          }

          final DateTime now = DateTime.now();

          transaction.update(
            orderDocument,
            <String, dynamic>{
              'status':
                  FoodOrderStatus.delivered.name,
              'deliveredAt':
                  now.toIso8601String(),
              'riderGrossEarning':
                  safeGrossEarning,
              'riderCommissionRate':
                  commissionRate,
              'riderCommissionAmount':
                  commissionAmount,
              'riderNetEarning':
                  netEarning,
              'riderCommissionAutoDeducted':
                  autoDeductedCommission,
              'riderCommissionOutstanding':
                  remainingOutstanding,
              'cashOrder': cashOrder,
              'updatedAt':
                  now.toIso8601String(),
            },
          );

          transaction.update(
            riderDocument,
            <String, dynamic>{
              'isOnDelivery': false,
              'isAvailable': rider.isOnline,
              'currentOrderId': '',
              'completedDeliveries':
                  rider.completedDeliveries + 1,
              'totalEarnings':
                  rider.totalEarnings +
                      netEarning,
              'walletBalance':
                  riderWalletAfter,
              'outstandingCommission':
                  rider.outstandingCommission +
                      remainingOutstanding,
              'totalCommissionPaid':
                  _doubleValue(
                        riderSnapshot.data()?[
                            'totalCommissionPaid'],
                      ) +
                      adminCreditNow,
              'updatedAt':
                  now.toIso8601String(),
            },
          );

          transaction.set(
            _adminWalletRef,
            <String, dynamic>{
              'walletBalance':
                  currentAdminBalance +
                      adminCreditNow,
              'totalCommissionReceived':
                  currentAdminReceived +
                      adminCreditNow,
              'totalOutstandingReceivable':
                  currentAdminReceivable +
                      remainingOutstanding,
              'lastTransactionAt':
                  now.toIso8601String(),
              'updatedAt':
                  now.toIso8601String(),
            },
            SetOptions(merge: true),
          );

          transaction.set(
            ledgerDocument,
            <String, dynamic>{
              'settlementId':
                  ledgerDocument.id,
              'serviceType': 'food_delivery',
              'sourceType': 'rider',
              'sourceId': riderId,
              'orderId': orderId,
              'paymentMode':
                  cashOrder ? 'cash' : 'digital',
              'grossAmount':
                  safeGrossEarning,
              'commissionRate':
                  commissionRate,
              'commissionAmount':
                  commissionAmount,
              'autoDeductedAmount':
                  adminCreditNow,
              'outstandingAmount':
                  remainingOutstanding,
              'netEarning':
                  netEarning,
              'status':
                  remainingOutstanding > 0
                      ? 'partially_settled'
                      : 'settled',
              'createdAt':
                  now.toIso8601String(),
              'updatedAt':
                  now.toIso8601String(),
            },
          );
        },
      );

      final FoodOrderModel? deliveredOrder =
          await getOrderById(orderId);

      if (deliveredOrder != null) {
        final String partnerId =
            await _partnerIdForRestaurant(
          deliveredOrder.restaurantId,
        );

        await _notificationService.notifyDelivered(
          customerId: deliveredOrder.customerId,
          partnerId: partnerId,
          restaurantId:
              deliveredOrder.restaurantId,
          riderId: riderId,
          orderId: deliveredOrder.orderId,
        );
      }
    } on FoodDeliveryRiderServiceException {
      rethrow;
    } on FirebaseException catch (error) {
      throw FoodDeliveryRiderServiceException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    } catch (error) {
      throw FoodDeliveryRiderServiceException(
        message:
            'Unable to complete delivery: $error',
      );
    }
  }

  Future<void> cancelAssignedDelivery({
    required String riderId,
    required String orderId,
    required String reason,
  }) async {
    if (reason.trim().isEmpty) {
      throw const FoodDeliveryRiderServiceException(
        message:
            'Cancellation reason is required.',
      );
    }

    final FoodDeliveryRiderModel? rider =
        await getRiderById(riderId);

    final FoodOrderModel? orderBefore =
        await getOrderById(orderId);

    if (rider == null) {
      throw const FoodDeliveryRiderServiceException(
        message: 'Food delivery rider was not found.',
      );
    }

    final DateTime now = DateTime.now();

    final WriteBatch batch =
        _firestore.batch();

    batch.update(
      _ridersRef.doc(riderId),
      <String, dynamic>{
        'isOnDelivery': false,
        'isAvailable': rider.isOnline,
        'currentOrderId': '',
        'cancelledDeliveries':
            rider.cancelledDeliveries + 1,
        'updatedAt':
            now.toIso8601String(),
      },
    );

    batch.update(
      _ordersRef.doc(orderId),
      <String, dynamic>{
        'riderId': '',
        'riderCancellationReason':
            reason.trim(),
        'status':
            FoodOrderStatus
                .readyForPickup.name,
        'updatedAt':
            now.toIso8601String(),
      },
    );

    await batch.commit();

    if (orderBefore != null) {
      final String partnerId =
          await _partnerIdForRestaurant(
        orderBefore.restaurantId,
      );

      await _notificationService.notifyCancelled(
        customerId: orderBefore.customerId,
        orderId: orderBefore.orderId,
        cancelledBy: 'rider',
        reason: reason.trim(),
        partnerId: partnerId,
        restaurantId:
            orderBefore.restaurantId,
        riderId: riderId,
      );
    }
  }

  // ===========================================================
  // WALLET / EARNINGS
  // ===========================================================

  Future<void> addWalletBalance({
    required String riderId,
    required double amount,
  }) async {
    if (amount <= 0) {
      throw const FoodDeliveryRiderServiceException(
        message:
            'Wallet amount must be greater than zero.',
      );
    }

    final FoodDeliveryRiderModel? rider =
        await getRiderById(riderId);

    if (rider == null) {
      throw const FoodDeliveryRiderServiceException(
        message: 'Food delivery rider was not found.',
      );
    }

    await updateRiderFields(
      riderId: riderId,
      fields: <String, dynamic>{
        'walletBalance':
            rider.walletBalance + amount,
      },
    );
  }

  Future<void> settleOutstandingCommission({
    required String riderId,
    required double amount,
  }) async {
    if (amount <= 0) {
      throw const FoodDeliveryRiderServiceException(
        message:
            'Settlement amount must be greater than zero.',
      );
    }

    final FoodDeliveryRiderModel? rider =
        await getRiderById(riderId);

    if (rider == null) {
      throw const FoodDeliveryRiderServiceException(
        message: 'Food delivery rider was not found.',
      );
    }

    if (amount >
        rider.outstandingCommission) {
      throw const FoodDeliveryRiderServiceException(
        message:
            'Settlement amount exceeds outstanding commission.',
      );
    }

    await updateRiderFields(
      riderId: riderId,
      fields: <String, dynamic>{
        'outstandingCommission':
            rider.outstandingCommission -
                amount,
      },
    );
  }

  Future<String> _partnerIdForRestaurant(
    String restaurantId,
  ) async {
    if (restaurantId.trim().isEmpty) {
      return '';
    }

    QuerySnapshot<Map<String, dynamic>> snapshot =
        await _firestore
            .collection(
              'food_restaurant_partners',
            )
            .where(
              'restaurantId',
              isEqualTo: restaurantId,
            )
            .limit(1)
            .get();

    if (snapshot.docs.isEmpty) {
      snapshot = await _firestore
          .collection('restaurant_partners')
          .where(
            'restaurantId',
            isEqualTo: restaurantId,
          )
          .limit(1)
          .get();
    }

    if (snapshot.docs.isEmpty) {
      return '';
    }

    final Map<String, dynamic> data =
        snapshot.docs.first.data();

    final String savedPartnerId =
        data['partnerId']?.toString().trim() ?? '';

    return savedPartnerId.isNotEmpty
        ? savedPartnerId
        : snapshot.docs.first.id;
  }

  // ===========================================================
  // GENERIC UPDATE
  // ===========================================================

  Future<void> updateRiderFields({
    required String riderId,
    required Map<String, dynamic> fields,
  }) async {
    if (riderId.trim().isEmpty) {
      throw const FoodDeliveryRiderServiceException(
        message: 'Rider ID is required.',
      );
    }

    try {
      await _ridersRef
          .doc(riderId)
          .set(
        <String, dynamic>{
          ...fields,
          'updatedAt':
              DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );
    } on FirebaseException catch (error) {
      throw FoodDeliveryRiderServiceException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    } catch (error) {
      throw FoodDeliveryRiderServiceException(
        message:
            'Unable to update rider: $error',
      );
    }
  }

  Future<void> _updateOrderAndRider({
    required String riderId,
    required String orderId,
    required FoodOrderStatus
        requiredOrderStatus,
    required FoodOrderStatus nextOrderStatus,
    required Map<String, dynamic> riderFields,
  }) async {
    final DocumentReference<Map<String, dynamic>>
        riderDocument =
        _ridersRef.doc(riderId);

    final DocumentReference<Map<String, dynamic>>
        orderDocument =
        _ordersRef.doc(orderId);

    try {
      await _firestore.runTransaction(
        (Transaction transaction) async {
          final DocumentSnapshot<
                  Map<String, dynamic>>
              orderSnapshot =
              await transaction.get(
            orderDocument,
          );

          if (!orderSnapshot.exists ||
              orderSnapshot.data() == null) {
            throw const FoodDeliveryRiderServiceException(
              message: 'Food order was not found.',
            );
          }

          final FoodOrderModel order =
              _orderFromSnapshot(
            orderSnapshot,
          );

          if (order.riderId != riderId) {
            throw const FoodDeliveryRiderServiceException(
              message:
                  'This order is not assigned to this rider.',
            );
          }

          if (order.status !=
              requiredOrderStatus) {
            throw FoodDeliveryRiderServiceException(
              message:
                  'Order must be ${requiredOrderStatus.name} before this action.',
            );
          }

          final DateTime now = DateTime.now();

          transaction.update(
            orderDocument,
            <String, dynamic>{
              'status': nextOrderStatus.name,
              'updatedAt':
                  now.toIso8601String(),
            },
          );

          transaction.update(
            riderDocument,
            <String, dynamic>{
              ...riderFields,
              'updatedAt':
                  now.toIso8601String(),
            },
          );
        },
      );
    } on FoodDeliveryRiderServiceException {
      rethrow;
    } on FirebaseException catch (error) {
      throw FoodDeliveryRiderServiceException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    } catch (error) {
      throw FoodDeliveryRiderServiceException(
        message:
            'Unable to update delivery: $error',
      );
    }
  }

  // ===========================================================
  // MAPPERS / VALIDATION
  // ===========================================================

  FoodDeliveryRiderModel _riderFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>>
        snapshot,
  ) {
    final Map<String, dynamic> data =
        Map<String, dynamic>.from(
      snapshot.data() ??
          const <String, dynamic>{},
    );

    data['riderId'] = snapshot.id;

    return FoodDeliveryRiderModel.fromMap(
      data,
    );
  }

  FoodOrderModel _orderFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>>
        snapshot,
  ) {
    final Map<String, dynamic> data =
        Map<String, dynamic>.from(
      snapshot.data() ??
          const <String, dynamic>{},
    );

    data['orderId'] = snapshot.id;

    return FoodOrderModel.fromMap(data);
  }

  void _validateApplication(
    FoodDeliveryRiderModel rider,
  ) {
    if (rider.userId.trim().isEmpty) {
      throw const FoodDeliveryRiderServiceException(
        message: 'User ID is required.',
      );
    }

    if (rider.fullName.trim().isEmpty) {
      throw const FoodDeliveryRiderServiceException(
        message: 'Rider full name is required.',
      );
    }

    if (rider.phoneNumber.trim().isEmpty) {
      throw const FoodDeliveryRiderServiceException(
        message: 'Phone number is required.',
      );
    }

    if (rider.cnicNumber.trim().isEmpty) {
      throw const FoodDeliveryRiderServiceException(
        message: 'CNIC number is required.',
      );
    }

    if (rider.city.trim().isEmpty ||
        rider.completeAddress.trim().isEmpty) {
      throw const FoodDeliveryRiderServiceException(
        message:
            'Complete rider address is required.',
      );
    }

    if (rider.registrationNumber
        .trim()
        .isEmpty) {
      throw const FoodDeliveryRiderServiceException(
        message:
            'Vehicle registration number is required.',
      );
    }
  }

  double _doubleValue(
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

  String _firebaseMessage(
    FirebaseException error,
  ) {
    switch (error.code) {
      case 'permission-denied':
        return 'You do not have permission to perform this food rider action.';
      case 'unavailable':
        return 'Firebase is temporarily unavailable. Please try again.';
      case 'not-found':
        return 'The requested rider or food order was not found.';
      case 'already-exists':
        return 'This rider application already exists.';
      case 'failed-precondition':
        return 'Firebase requires an index or another condition before this action can run.';
      case 'aborted':
        return 'The operation was interrupted. Please try again.';
      default:
        return error.message ??
            'A Firebase error occurred (${error.code}).';
    }
  }
}

class FoodDeliveryRiderServiceException
    implements Exception {
  const FoodDeliveryRiderServiceException({
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

    return 'FoodDeliveryRiderServiceException($code): $message';
  }
}
