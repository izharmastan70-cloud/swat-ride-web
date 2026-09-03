// lib/food/services/food_order_service.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Food Order Firestore Service
//
// Scope:
// - Real Firestore order creation
// - Customer, restaurant, and rider live order streams
// - Restaurant accept/reject and preparation status
// - Rider assignment and live location updates
// - Delivery OTP verification
// - Cancellation and SOS event recording
//
// Bypassed for now:
// - Online payment gateway charging/refunds
// - Paid map SDK rendering
//
// Firestore order and location data remain real.
// =============================================================

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cart_item_model.dart';
import '../models/food_cancellation_model.dart';
import '../models/delivery_address_model.dart';
import '../models/food_order_model.dart';
import 'food_notification_service.dart';
import 'food_service_control_service.dart';

class FoodOrderService {
  FoodOrderService({
    FirebaseFirestore? firestore,
    FoodNotificationService? notificationService,
    FoodServiceControlService? serviceControlService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _notificationService =
           notificationService ??
           FoodNotificationService(
             firestore: firestore ?? FirebaseFirestore.instance,
           ),
       _serviceControlService =
           serviceControlService ??
           FoodServiceControlService(
             firestore: firestore ?? FirebaseFirestore.instance,
           );

  final FirebaseFirestore _firestore;
  final FoodNotificationService _notificationService;
  final FoodServiceControlService _serviceControlService;

  static const String ordersCollection = 'food_orders';
  static const String sosEventsCollection = 'food_sos_events';

  static const String partnersCollection = 'food_restaurant_partners';

  static const String restaurantsCollection = 'food_restaurants';

  static const String adminSettingsCollection = 'food_admin_settings';

  static const String adminWalletDocument = 'admin_wallet';

  static const String commissionLedgerCollection =
      'food_commission_settlements';

  CollectionReference<Map<String, dynamic>> get _ordersRef =>
      _firestore.collection(ordersCollection);

  CollectionReference<Map<String, dynamic>> get _sosEventsRef =>
      _firestore.collection(sosEventsCollection);

  CollectionReference<Map<String, dynamic>> get _partnersRef =>
      _firestore.collection(partnersCollection);

  CollectionReference<Map<String, dynamic>> get _restaurantsRef =>
      _firestore.collection(restaurantsCollection);

  DocumentReference<Map<String, dynamic>> get _adminWalletRef =>
      _firestore.collection(adminSettingsCollection).doc(adminWalletDocument);

  CollectionReference<Map<String, dynamic>> get _commissionLedgerRef =>
      _firestore.collection(commissionLedgerCollection);

  // ===========================================================
  // CREATE ORDER
  // ===========================================================

  Future<String> createOrder({
    required String customerId,
    required String restaurantId,
    required String restaurantName,
    required List<CartItemModel> items,
    required DeliveryAddressModel deliveryAddress,
    required FoodPaymentMethod paymentMethod,
    required double deliveryFee,
    double discount = 0,
    double serviceFee = 0,
  }) async {
    if (customerId.trim().isEmpty) {
      throw const FoodOrderServiceException(
        message: 'Customer ID is required.',
      );
    }

    if (restaurantId.trim().isEmpty) {
      throw const FoodOrderServiceException(
        message: 'Restaurant ID is required.',
      );
    }

    if (items.isEmpty) {
      throw const FoodOrderServiceException(message: 'Cart is empty.');
    }

    final bool sameRestaurant = items.every(
      (CartItemModel item) => item.restaurantId == restaurantId,
    );

    if (!sameRestaurant) {
      throw const FoodOrderServiceException(
        message: 'All food items must belong to the same restaurant.',
      );
    }

    final bool unavailableItem = items.any(
      (CartItemModel item) => !item.isAvailable,
    );

    if (unavailableItem) {
      throw const FoodOrderServiceException(
        message: 'One or more cart items are currently unavailable.',
      );
    }

    // Master Food control blocks only new orders.
    // Existing active orders continue normally.
    await _serviceControlService.assertCanCreateNewOrder();

    try {
      final DocumentReference<Map<String, dynamic>> document = _ordersRef.doc();

      final DateTime now = DateTime.now();

      final double itemsTotal = items.fold<double>(
        0,
        (double currentTotal, CartItemModel item) =>
            currentTotal + item.totalPrice,
      );

      final double safeDeliveryFee = deliveryFee < 0 ? 0 : deliveryFee;

      final double safeDiscount = discount < 0 ? 0 : discount;

      final double safeServiceFee = serviceFee < 0 ? 0 : serviceFee;

      final FoodOrderModel order = FoodOrderModel(
        orderId: document.id,
        customerId: customerId,
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        riderId: '',
        items: List<CartItemModel>.unmodifiable(items),
        deliveryAddress: deliveryAddress,
        status: FoodOrderStatus.pending,
        paymentMethod: paymentMethod,
        itemsTotal: itemsTotal,
        deliveryFee: safeDeliveryFee,
        discount: safeDiscount,
        serviceFee: safeServiceFee,
        riderLatitude: 0,
        riderLongitude: 0,
        customerOtp: _generateDeliveryOtp(),
        createdAt: now,
        updatedAt: now,
      );

      await document.set(<String, dynamic>{
        ...order.toMap(),

        // Extra fields used by restaurant, rider, admin,
        // timeline, cancellation, and tracking screens.
        'restaurantAcceptedAt': null,
        'preparingStartedAt': null,
        'readyForPickupAt': null,
        'riderAssignedAt': null,
        'pickedUpAt': null,
        'deliveredAt': null,
        'cancelledAt': null,
        'cancelledBy': '',
        'cancellationReason': '',
        'restaurantRejectionReason': '',
        'estimatedPreparationMinutes': 0,
        'estimatedDeliveryMinutes': 0,
        'paymentGatewayBypassed': paymentMethod != FoodPaymentMethod.cash,
        'paymentStatus': paymentMethod == FoodPaymentMethod.cash
            ? 'cash_due'
            : 'gateway_bypassed',
        'lastRiderLocationUpdatedAt': null,
      }, SetOptions(merge: false));

      await _notificationService.notifyOrderPlaced(
        customerId: customerId,
        restaurantName: restaurantName,
        orderId: document.id,
      );

      return document.id;
    } on FirebaseException catch (error) {
      throw FoodOrderServiceException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    } catch (error) {
      throw FoodOrderServiceException(
        message: 'Unable to create food order: $error',
      );
    }
  }

  // ===========================================================
  // GET / WATCH SINGLE ORDER
  // ===========================================================

  Future<FoodOrderModel?> getOrderById(String orderId) async {
    if (orderId.trim().isEmpty) {
      return null;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await _ordersRef
          .doc(orderId)
          .get();

      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }

      return _orderFromSnapshot(snapshot);
    } on FirebaseException catch (error) {
      throw FoodOrderServiceException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    } catch (error) {
      throw FoodOrderServiceException(
        message: 'Unable to load food order: $error',
      );
    }
  }

  Stream<FoodOrderModel?> watchOrderById(String orderId) {
    if (orderId.trim().isEmpty) {
      return Stream<FoodOrderModel?>.value(null);
    }

    return _ordersRef.doc(orderId).snapshots().map((
      DocumentSnapshot<Map<String, dynamic>> snapshot,
    ) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }

      return _orderFromSnapshot(snapshot);
    });
  }

  Stream<Map<String, dynamic>?> watchOrderRaw(String orderId) {
    if (orderId.trim().isEmpty) {
      return Stream<Map<String, dynamic>?>.value(null);
    }

    return _ordersRef.doc(orderId).snapshots().map((
      DocumentSnapshot<Map<String, dynamic>> snapshot,
    ) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }

      return Map<String, dynamic>.from(snapshot.data()!);
    });
  }

  // ===========================================================
  // CUSTOMER ORDERS
  // ===========================================================

  Stream<List<FoodOrderModel>> watchCustomerOrders(
    String customerId, {
    int limit = 50,
  }) {
    if (customerId.trim().isEmpty) {
      return Stream<List<FoodOrderModel>>.value(const <FoodOrderModel>[]);
    }

    return _ordersRef
        .where('customerId', isEqualTo: customerId)
        .limit(limit)
        .snapshots()
        .map(_orderListFromQuery);
  }

  Stream<List<FoodOrderModel>> watchCustomerActiveOrders(String customerId) {
    if (customerId.trim().isEmpty) {
      return Stream<List<FoodOrderModel>>.value(const <FoodOrderModel>[]);
    }

    return _ordersRef
        .where('customerId', isEqualTo: customerId)
        .where(
          'status',
          whereIn: <String>[
            FoodOrderStatus.pending.name,
            FoodOrderStatus.accepted.name,
            FoodOrderStatus.preparing.name,
            FoodOrderStatus.readyForPickup.name,
            FoodOrderStatus.pickedUp.name,
            FoodOrderStatus.onTheWay.name,
          ],
        )
        .snapshots()
        .map(_orderListFromQuery);
  }

  // ===========================================================
  // RESTAURANT ORDERS
  // ===========================================================

  Stream<List<FoodOrderModel>> watchRestaurantOrders(
    String restaurantId, {
    int limit = 100,
  }) {
    if (restaurantId.trim().isEmpty) {
      return Stream<List<FoodOrderModel>>.value(const <FoodOrderModel>[]);
    }

    return _ordersRef
        .where('restaurantId', isEqualTo: restaurantId)
        .limit(limit)
        .snapshots()
        .map(_orderListFromQuery);
  }

  Stream<List<FoodOrderModel>> watchRestaurantActiveOrders(
    String restaurantId,
  ) {
    if (restaurantId.trim().isEmpty) {
      return Stream<List<FoodOrderModel>>.value(const <FoodOrderModel>[]);
    }

    return _ordersRef
        .where('restaurantId', isEqualTo: restaurantId)
        .where(
          'status',
          whereIn: <String>[
            FoodOrderStatus.pending.name,
            FoodOrderStatus.accepted.name,
            FoodOrderStatus.preparing.name,
            FoodOrderStatus.readyForPickup.name,
            FoodOrderStatus.pickedUp.name,
            FoodOrderStatus.onTheWay.name,
          ],
        )
        .snapshots()
        .map(_orderListFromQuery);
  }

  // ===========================================================
  // RIDER ORDERS
  // ===========================================================

  Stream<List<FoodOrderModel>> watchRiderOrders(
    String riderId, {
    int limit = 100,
  }) {
    if (riderId.trim().isEmpty) {
      return Stream<List<FoodOrderModel>>.value(const <FoodOrderModel>[]);
    }

    return _ordersRef
        .where('riderId', isEqualTo: riderId)
        .limit(limit)
        .snapshots()
        .map(_orderListFromQuery);
  }

  Stream<List<FoodOrderModel>> watchRiderActiveOrders(String riderId) {
    if (riderId.trim().isEmpty) {
      return Stream<List<FoodOrderModel>>.value(const <FoodOrderModel>[]);
    }

    return _ordersRef
        .where('riderId', isEqualTo: riderId)
        .where(
          'status',
          whereIn: <String>[
            FoodOrderStatus.readyForPickup.name,
            FoodOrderStatus.pickedUp.name,
            FoodOrderStatus.onTheWay.name,
          ],
        )
        .snapshots()
        .map(_orderListFromQuery);
  }

  // ===========================================================
  // RESTAURANT STATUS ACTIONS
  // ===========================================================

  Future<void> acceptOrder({
    required String orderId,
    required int estimatedPreparationMinutes,
  }) async {
    final int safeMinutes = estimatedPreparationMinutes < 1
        ? 1
        : estimatedPreparationMinutes;

    await _updateOrderFields(
      orderId: orderId,
      fields: <String, dynamic>{
        'status': FoodOrderStatus.accepted.name,
        'restaurantAcceptedAt': DateTime.now().toIso8601String(),
        'estimatedPreparationMinutes': safeMinutes,
        'restaurantRejectionReason': '',
      },
    );

    final FoodOrderModel? order = await getOrderById(orderId);

    if (order != null) {
      await _notificationService.notifyRestaurantAccepted(
        customerId: order.customerId,
        restaurantName: order.restaurantName,
        orderId: order.orderId,
        preparationMinutes: safeMinutes,
      );
    }
  }

  Future<void> rejectOrder({
    required String orderId,
    required String reason,
  }) async {
    await _updateOrderFields(
      orderId: orderId,
      fields: <String, dynamic>{
        'status': FoodOrderStatus.cancelled.name,
        'cancelledAt': DateTime.now().toIso8601String(),
        'cancelledBy': 'restaurant',
        'cancellationReason': reason.trim(),
        'restaurantRejectionReason': reason.trim(),
      },
    );
  }

  Future<void> startPreparing(String orderId) async {
    await _updateOrderFields(
      orderId: orderId,
      fields: <String, dynamic>{
        'status': FoodOrderStatus.preparing.name,
        'preparingStartedAt': DateTime.now().toIso8601String(),
      },
    );

    final FoodOrderModel? order = await getOrderById(orderId);

    if (order != null) {
      await _notificationService.notifyPreparing(
        customerId: order.customerId,
        restaurantName: order.restaurantName,
        orderId: order.orderId,
      );
    }
  }

  Future<void> markReadyForPickup(String orderId) async {
    await _updateOrderFields(
      orderId: orderId,
      fields: <String, dynamic>{
        'status': FoodOrderStatus.readyForPickup.name,
        'readyForPickupAt': DateTime.now().toIso8601String(),
      },
    );

    final FoodOrderModel? order = await getOrderById(orderId);

    if (order != null) {
      await _notificationService.notifyReadyForPickup(
        customerId: order.customerId,
        restaurantName: order.restaurantName,
        orderId: order.orderId,
      );
    }
  }

  // ===========================================================
  // RIDER ASSIGNMENT AND DELIVERY STATUS
  // ===========================================================

  Future<void> assignRider({
    required String orderId,
    required String riderId,
    int estimatedDeliveryMinutes = 0,
  }) async {
    if (riderId.trim().isEmpty) {
      throw const FoodOrderServiceException(message: 'Rider ID is required.');
    }

    await _updateOrderFields(
      orderId: orderId,
      fields: <String, dynamic>{
        'riderId': riderId,
        'riderAssignedAt': DateTime.now().toIso8601String(),
        'estimatedDeliveryMinutes': estimatedDeliveryMinutes < 0
            ? 0
            : estimatedDeliveryMinutes,
      },
    );
  }

  Future<void> markPickedUp(String orderId) async {
    await _updateOrderFields(
      orderId: orderId,
      fields: <String, dynamic>{
        'status': FoodOrderStatus.pickedUp.name,
        'pickedUpAt': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> markOnTheWay(String orderId) async {
    await _updateOrderFields(
      orderId: orderId,
      fields: <String, dynamic>{'status': FoodOrderStatus.onTheWay.name},
    );
  }

  Future<void> updateRiderLiveLocation({
    required String orderId,
    required String riderId,
    required double latitude,
    required double longitude,
  }) async {
    if (riderId.trim().isEmpty) {
      throw const FoodOrderServiceException(message: 'Rider ID is required.');
    }

    try {
      await _firestore.runTransaction((Transaction transaction) async {
        final DocumentReference<Map<String, dynamic>> document = _ordersRef.doc(
          orderId,
        );

        final DocumentSnapshot<Map<String, dynamic>> snapshot =
            await transaction.get(document);

        if (!snapshot.exists || snapshot.data() == null) {
          throw const FoodOrderServiceException(
            message: 'Food order was not found.',
          );
        }

        final Map<String, dynamic> data = snapshot.data()!;

        final String assignedRiderId = data['riderId']?.toString() ?? '';

        if (assignedRiderId != riderId) {
          throw const FoodOrderServiceException(
            message: 'This rider is not assigned to the order.',
          );
        }

        transaction.update(document, <String, dynamic>{
          'riderLatitude': latitude,
          'riderLongitude': longitude,
          'lastRiderLocationUpdatedAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });
      });
    } on FoodOrderServiceException {
      rethrow;
    } on FirebaseException catch (error) {
      throw FoodOrderServiceException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    } catch (error) {
      throw FoodOrderServiceException(
        message: 'Unable to update rider location: $error',
      );
    }
  }

  Future<bool> verifyDeliveryOtp({
    required String orderId,
    required String enteredOtp,
  }) async {
    if (orderId.trim().isEmpty || enteredOtp.trim().isEmpty) {
      return false;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await _ordersRef
          .doc(orderId)
          .get();

      if (!snapshot.exists || snapshot.data() == null) {
        return false;
      }

      final String savedOtp =
          snapshot.data()!['customerOtp']?.toString().trim() ?? '';

      return savedOtp.isNotEmpty && savedOtp == enteredOtp.trim();
    } on FirebaseException catch (error) {
      throw FoodOrderServiceException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    }
  }

  Future<void> markDelivered({
    required String orderId,
    required String enteredOtp,
  }) async {
    final bool validOtp = await verifyDeliveryOtp(
      orderId: orderId,
      enteredOtp: enteredOtp,
    );

    if (!validOtp) {
      throw const FoodOrderServiceException(message: 'Invalid delivery OTP.');
    }

    await _updateOrderFields(
      orderId: orderId,
      fields: <String, dynamic>{
        'status': FoodOrderStatus.delivered.name,
        'ratingPromptDismissed': false,
        'ratingPromptDismissedAt': null,
        'deliveredAt': DateTime.now().toIso8601String(),
        'paymentStatus': 'completed',
      },
    );

    await processRestaurantSettlementForDeliveredOrder(orderId: orderId);
  }

  // ===========================================================
  // RESTAURANT WALLET / COMMISSION SETTLEMENT
  // ===========================================================

  Future<void> processRestaurantSettlementForDeliveredOrder({
    required String orderId,
  }) async {
    if (orderId.trim().isEmpty) {
      throw const FoodOrderServiceException(message: 'Order ID is required.');
    }

    final DocumentReference<Map<String, dynamic>> orderDocument = _ordersRef
        .doc(orderId);

    final DocumentSnapshot<Map<String, dynamic>> initialOrderSnapshot =
        await orderDocument.get();

    if (!initialOrderSnapshot.exists || initialOrderSnapshot.data() == null) {
      throw const FoodOrderServiceException(
        message: 'Food order was not found.',
      );
    }

    final Map<String, dynamic> initialOrderData = initialOrderSnapshot.data()!;

    if (initialOrderData['restaurantSettlementProcessed'] == true) {
      return;
    }

    final String restaurantId = _stringValue(initialOrderData['restaurantId']);

    if (restaurantId.isEmpty) {
      throw const FoodOrderServiceException(
        message: 'Restaurant ID is missing from this order.',
      );
    }

    QuerySnapshot<Map<String, dynamic>> partnerQuery = await _partnersRef
        .where('restaurantId', isEqualTo: restaurantId)
        .limit(1)
        .get();

    if (partnerQuery.docs.isEmpty) {
      partnerQuery = await _firestore
          .collection('restaurant_partners')
          .where('restaurantId', isEqualTo: restaurantId)
          .limit(1)
          .get();
    }

    if (partnerQuery.docs.isEmpty) {
      throw const FoodOrderServiceException(
        message: 'Approved restaurant partner record was not found.',
      );
    }

    final DocumentReference<Map<String, dynamic>> partnerDocument =
        partnerQuery.docs.first.reference;

    final DocumentReference<Map<String, dynamic>> restaurantDocument =
        _restaurantsRef.doc(restaurantId);

    final DocumentReference<Map<String, dynamic>> ledgerDocument =
        _commissionLedgerRef.doc('restaurant_$orderId');

    try {
      await _firestore.runTransaction((Transaction transaction) async {
        final DocumentSnapshot<Map<String, dynamic>> orderSnapshot =
            await transaction.get(orderDocument);

        final DocumentSnapshot<Map<String, dynamic>> partnerSnapshot =
            await transaction.get(partnerDocument);

        final DocumentSnapshot<Map<String, dynamic>> restaurantSnapshot =
            await transaction.get(restaurantDocument);

        final DocumentSnapshot<Map<String, dynamic>> adminWalletSnapshot =
            await transaction.get(_adminWalletRef);

        final DocumentSnapshot<Map<String, dynamic>> ledgerSnapshot =
            await transaction.get(ledgerDocument);

        if (!orderSnapshot.exists || orderSnapshot.data() == null) {
          throw const FoodOrderServiceException(
            message: 'Food order was not found.',
          );
        }

        if (!partnerSnapshot.exists || partnerSnapshot.data() == null) {
          throw const FoodOrderServiceException(
            message: 'Restaurant partner record was not found.',
          );
        }

        final Map<String, dynamic> orderData = orderSnapshot.data()!;

        final Map<String, dynamic> partnerData = partnerSnapshot.data()!;

        if (orderData['restaurantSettlementProcessed'] == true) {
          return;
        }

        if (ledgerSnapshot.exists) {
          transaction.update(orderDocument, <String, dynamic>{
            'restaurantSettlementProcessed': true,
            'restaurantSettlementId': ledgerDocument.id,
            'updatedAt': DateTime.now().toIso8601String(),
          });
          return;
        }

        final FoodOrderStatus status = _foodOrderStatusFromValue(
          orderData['status'],
        );

        if (status != FoodOrderStatus.delivered) {
          throw const FoodOrderServiceException(
            message: 'Restaurant settlement can only run after delivery.',
          );
        }

        final FoodPaymentMethod paymentMethod = _paymentMethodFromValue(
          orderData['paymentMethod'],
        );

        final bool cashOrder = paymentMethod == FoodPaymentMethod.cash;

        final double itemsTotal = _doubleValue(orderData['itemsTotal']);

        final double discount = _doubleValue(orderData['discount']);

        final double grossRestaurantSale = max(0, itemsTotal - discount);

        final double commissionRate = _doubleValue(
          partnerData['commissionPercentage'],
        ).clamp(0, 100).toDouble();

        final double commissionAmount =
            grossRestaurantSale * (commissionRate / 100);

        final double netRestaurantEarning =
            grossRestaurantSale - commissionAmount;

        final double currentPartnerWallet = _doubleValue(
          partnerData['walletBalance'],
        );

        final double currentOutstanding = _doubleValue(
          partnerData['outstandingCommission'],
        );

        final double currentPartnerEarnings = _doubleValue(
          partnerData['totalEarnings'],
        );

        final double currentCommissionPaid = _doubleValue(
          partnerData['totalCommissionPaid'],
        );

        final Map<String, dynamic> adminData =
            adminWalletSnapshot.data() ?? const <String, dynamic>{};

        final double currentAdminBalance = _doubleValue(
          adminData['walletBalance'],
        );

        final double currentAdminReceived = _doubleValue(
          adminData['totalCommissionReceived'],
        );

        final double currentAdminReceivable = _doubleValue(
          adminData['totalOutstandingReceivable'],
        );

        double partnerWalletAfter;
        double adminCreditNow;
        double remainingOutstanding;

        if (cashOrder) {
          adminCreditNow = currentPartnerWallet >= commissionAmount
              ? commissionAmount
              : currentPartnerWallet;

          remainingOutstanding = commissionAmount - adminCreditNow;

          partnerWalletAfter = currentPartnerWallet - adminCreditNow;
        } else {
          adminCreditNow = commissionAmount;
          remainingOutstanding = 0;

          partnerWalletAfter = currentPartnerWallet + netRestaurantEarning;
        }

        final DateTime now = DateTime.now();

        transaction.set(partnerDocument, <String, dynamic>{
          'walletBalance': partnerWalletAfter,
          'outstandingCommission': currentOutstanding + remainingOutstanding,
          'totalEarnings': currentPartnerEarnings + netRestaurantEarning,
          'totalCommissionPaid': currentCommissionPaid + adminCreditNow,
          'totalOrders': _intValue(partnerData['totalOrders']) + 1,
          'completedOrders': _intValue(partnerData['completedOrders']) + 1,
          'updatedAt': now.toIso8601String(),
        }, SetOptions(merge: true));

        if (restaurantSnapshot.exists) {
          final Map<String, dynamic> restaurantData =
              restaurantSnapshot.data() ?? const <String, dynamic>{};

          transaction.set(restaurantDocument, <String, dynamic>{
            'totalOrders': _intValue(restaurantData['totalOrders']) + 1,
            'updatedAt': now.toIso8601String(),
          }, SetOptions(merge: true));
        }

        transaction.set(_adminWalletRef, <String, dynamic>{
          'walletBalance': currentAdminBalance + adminCreditNow,
          'totalCommissionReceived': currentAdminReceived + adminCreditNow,
          'totalOutstandingReceivable':
              currentAdminReceivable + remainingOutstanding,
          'lastTransactionAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        }, SetOptions(merge: true));

        transaction.set(ledgerDocument, <String, dynamic>{
          'settlementId': ledgerDocument.id,
          'serviceType': 'food_delivery',
          'sourceType': 'restaurant',
          'sourceId': partnerDocument.id,
          'restaurantId': restaurantId,
          'orderId': orderId,
          'paymentMode': cashOrder ? 'cash' : 'digital',
          'grossAmount': grossRestaurantSale,
          'commissionRate': commissionRate,
          'commissionAmount': commissionAmount,
          'autoDeductedAmount': adminCreditNow,
          'outstandingAmount': remainingOutstanding,
          'netEarning': netRestaurantEarning,
          'status': remainingOutstanding > 0 ? 'partially_settled' : 'settled',
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        });

        transaction.update(orderDocument, <String, dynamic>{
          'restaurantGrossSale': grossRestaurantSale,
          'restaurantCommissionRate': commissionRate,
          'restaurantCommissionAmount': commissionAmount,
          'restaurantNetEarning': netRestaurantEarning,
          'restaurantCommissionAutoDeducted': adminCreditNow,
          'restaurantCommissionOutstanding': remainingOutstanding,
          'restaurantSettlementProcessed': true,
          'restaurantSettlementId': ledgerDocument.id,
          'updatedAt': now.toIso8601String(),
        });
      });
    } on FoodOrderServiceException {
      rethrow;
    } on FirebaseException catch (error) {
      throw FoodOrderServiceException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    } catch (error) {
      throw FoodOrderServiceException(
        message: 'Unable to process restaurant settlement: $error',
      );
    }
  }

  // ===========================================================
  // CANCELLATION
  // ===========================================================

  Future<void> cancelOrderByCustomer({
    required String orderId,
    required String customerId,
    required FoodCancellationReason reason,
    String customReason = '',
  }) async {
    if (customerId.trim().isEmpty) {
      throw const FoodOrderServiceException(
        message: 'Customer ID is required.',
      );
    }

    if (orderId.trim().isEmpty) {
      throw const FoodOrderServiceException(message: 'Order ID is required.');
    }

    try {
      await _firestore.runTransaction((Transaction transaction) async {
        final DocumentReference<Map<String, dynamic>> document = _ordersRef.doc(
          orderId,
        );

        final DocumentSnapshot<Map<String, dynamic>> snapshot =
            await transaction.get(document);

        if (!snapshot.exists || snapshot.data() == null) {
          throw const FoodOrderServiceException(
            message: 'Food order was not found.',
          );
        }

        final Map<String, dynamic> data = snapshot.data()!;

        final String savedCustomerId = _stringValue(data['customerId']);

        if (savedCustomerId != customerId) {
          throw const FoodOrderServiceException(
            message: 'You cannot cancel another customerâ€™s order.',
          );
        }

        final FoodOrderStatus status = _foodOrderStatusFromValue(
          data['status'],
        );

        if (status == FoodOrderStatus.cancelled) {
          return;
        }

        if (status == FoodOrderStatus.preparing ||
            status == FoodOrderStatus.readyForPickup ||
            status == FoodOrderStatus.pickedUp ||
            status == FoodOrderStatus.onTheWay ||
            status == FoodOrderStatus.delivered) {
          throw const FoodOrderServiceException(
            message: 'This order can no longer be cancelled by the customer.',
          );
        }

        final DateTime createdAt =
            _dateTimeValue(data['createdAt']) ?? DateTime.now();

        final bool allowed = FoodCancellationModel.canCustomerCancel(
          orderCreatedAt: createdAt,
          now: DateTime.now(),
        );

        if (!allowed) {
          throw const FoodOrderServiceException(
            message: 'The 5-minute customer cancellation period has ended.',
          );
        }

        final String reasonText =
            reason == FoodCancellationReason.other &&
                customReason.trim().isNotEmpty
            ? customReason.trim()
            : reason.displayName;

        transaction.update(document, <String, dynamic>{
          'status': FoodOrderStatus.cancelled.name,
          'cancelledAt': DateTime.now().toIso8601String(),
          'cancelledBy': 'customer',
          'cancellationReason': reasonText,
          'customerCancellationReason': reason.name,
          'customerCanCancel': false,
          'customerCancellationAllowed': false,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      });
    } on FoodOrderServiceException {
      rethrow;
    } on FirebaseException catch (error) {
      throw FoodOrderServiceException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    } catch (error) {
      throw FoodOrderServiceException(
        message: 'Unable to cancel food order: $error',
      );
    }
  }

  Future<void> cancelOrder({
    required String orderId,
    required String cancelledBy,
    required String reason,
  }) async {
    final FoodOrderModel? order = await getOrderById(orderId);

    if (order == null) {
      throw const FoodOrderServiceException(
        message: 'Food order was not found.',
      );
    }

    if (order.status == FoodOrderStatus.delivered) {
      throw const FoodOrderServiceException(
        message: 'A delivered order cannot be cancelled.',
      );
    }

    if (order.status == FoodOrderStatus.cancelled) {
      return;
    }

    await _updateOrderFields(
      orderId: orderId,
      fields: <String, dynamic>{
        'status': FoodOrderStatus.cancelled.name,
        'cancelledAt': DateTime.now().toIso8601String(),
        'cancelledBy': cancelledBy.trim(),
        'cancellationReason': reason.trim(),
      },
    );
  }

  // ===========================================================
  // CUSTOMER RATING PROMPT
  // ===========================================================

  Future<void> dismissCustomerRatingPrompt({
    required String orderId,
    required String customerId,
  }) async {
    final String cleanOrderId = orderId.trim();
    final String cleanCustomerId = customerId.trim();

    if (cleanOrderId.isEmpty || cleanCustomerId.isEmpty) {
      throw const FoodOrderServiceException(
        message: 'Order ID and customer ID are required.',
      );
    }

    final DocumentReference<Map<String, dynamic>> document = _ordersRef.doc(
      cleanOrderId,
    );

    try {
      await FirebaseFirestore.instance.runTransaction((
        Transaction transaction,
      ) async {
        final DocumentSnapshot<Map<String, dynamic>> snapshot =
            await transaction.get(document);

        final Map<String, dynamic>? data = snapshot.data();

        if (!snapshot.exists || data == null) {
          throw const FoodOrderServiceException(
            message: 'Food order was not found.',
          );
        }

        final String savedCustomerId = _stringValue(data['customerId']);

        if (savedCustomerId != cleanCustomerId) {
          throw const FoodOrderServiceException(
            message:
                'You cannot dismiss the rating prompt for another customer order.',
          );
        }

        final FoodOrderStatus status = _foodOrderStatusFromValue(
          data['status'],
        );

        if (status != FoodOrderStatus.delivered) {
          throw const FoodOrderServiceException(
            message: 'The rating prompt can only be dismissed after delivery.',
          );
        }

        if (data['ratingPromptDismissed'] == true) {
          return;
        }

        final String now = DateTime.now().toIso8601String();

        transaction.update(document, <String, dynamic>{
          'ratingPromptDismissed': true,
          'ratingPromptDismissedAt': now,
          'updatedAt': now,
        });
      });
    } on FoodOrderServiceException {
      rethrow;
    } on FirebaseException catch (error) {
      throw FoodOrderServiceException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    } catch (error) {
      throw FoodOrderServiceException(
        message: 'Unable to dismiss Food rating prompt: $error',
      );
    }
  }
  // ===========================================================
  // SOS SUPPORT
  // ===========================================================

  Future<String> createSosEvent({
    required String orderId,
    required String userId,
    required String userRole,
    required String reason,
    required double latitude,
    required double longitude,
  }) async {
    if (orderId.trim().isEmpty || userId.trim().isEmpty) {
      throw const FoodOrderServiceException(
        message: 'Order ID and user ID are required for SOS.',
      );
    }

    try {
      final DocumentReference<Map<String, dynamic>> document = _sosEventsRef
          .doc();

      await document.set(<String, dynamic>{
        'id': document.id,
        'orderId': orderId,
        'userId': userId,
        'userRole': userRole.trim(),
        'reason': reason.trim(),
        'latitude': latitude,
        'longitude': longitude,
        'status': 'open',
        'createdAt': DateTime.now().toIso8601String(),
        'resolvedAt': null,
        'resolvedBy': '',
        'resolutionNote': '',
      });

      await _updateOrderFields(
        orderId: orderId,
        fields: <String, dynamic>{
          'hasOpenSosEvent': true,
          'latestSosEventId': document.id,
        },
      );

      return document.id;
    } on FirebaseException catch (error) {
      throw FoodOrderServiceException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    } catch (error) {
      throw FoodOrderServiceException(
        message: 'Unable to create SOS event: $error',
      );
    }
  }

  // ===========================================================
  // INTERNAL UPDATE
  // ===========================================================

  Future<void> _updateOrderFields({
    required String orderId,
    required Map<String, dynamic> fields,
  }) async {
    if (orderId.trim().isEmpty) {
      throw const FoodOrderServiceException(message: 'Order ID is required.');
    }

    try {
      await _ordersRef.doc(orderId).update(<String, dynamic>{
        ...fields,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } on FirebaseException catch (error) {
      throw FoodOrderServiceException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    } catch (error) {
      throw FoodOrderServiceException(
        message: 'Unable to update food order: $error',
      );
    }
  }

  // ===========================================================
  // MODEL MAPPING
  // ===========================================================

  FoodOrderModel _orderFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(
      snapshot.data() ?? const <String, dynamic>{},
    );

    return FoodOrderModel(
      orderId: snapshot.id,
      customerId: _stringValue(data['customerId']),
      restaurantId: _stringValue(data['restaurantId']),
      restaurantName: _stringValue(data['restaurantName']),
      riderId: _stringValue(data['riderId']),
      items: _mapList(data['items']).map(CartItemModel.fromMap).toList(),
      deliveryAddress: DeliveryAddressModel.fromMap(
        _mapValue(data['deliveryAddress']),
      ),
      status: _foodOrderStatusFromValue(data['status']),
      paymentMethod: _paymentMethodFromValue(data['paymentMethod']),
      itemsTotal: _doubleValue(data['itemsTotal']),
      deliveryFee: _doubleValue(data['deliveryFee']),
      discount: _doubleValue(data['discount']),
      serviceFee: _doubleValue(data['serviceFee']),
      riderLatitude: _doubleValue(data['riderLatitude']),
      riderLongitude: _doubleValue(data['riderLongitude']),
      customerOtp: _stringValue(data['customerOtp']),
      createdAt: _dateTimeValue(data['createdAt']) ?? DateTime.now(),
      updatedAt: _dateTimeValue(data['updatedAt']) ?? DateTime.now(),
    );
  }

  List<FoodOrderModel> _orderListFromQuery(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final List<FoodOrderModel> orders = snapshot.docs
        .map(_orderFromSnapshot)
        .toList();

    orders.sort(
      (FoodOrderModel first, FoodOrderModel second) =>
          second.createdAt.compareTo(first.createdAt),
    );

    return orders;
  }

  // ===========================================================
  // SAFE PARSING
  // ===========================================================

  static String _stringValue(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  static int _intValue(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _doubleValue(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static Map<String, dynamic> _mapValue(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return <String, dynamic>{};
  }

  static List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) {
      return const <Map<String, dynamic>>[];
    }

    return value
        .whereType<Map>()
        .map((Map item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static DateTime? _dateTimeValue(dynamic value) {
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
      // Firestore Timestamp support without direct dependency.
    }

    return DateTime.tryParse(value.toString());
  }

  static FoodOrderStatus _foodOrderStatusFromValue(dynamic value) {
    final String normalized = value?.toString().trim().toLowerCase() ?? '';

    for (final FoodOrderStatus status in FoodOrderStatus.values) {
      if (status.name.toLowerCase() == normalized) {
        return status;
      }
    }

    return FoodOrderStatus.pending;
  }

  static FoodPaymentMethod _paymentMethodFromValue(dynamic value) {
    final String normalized = value?.toString().trim().toLowerCase() ?? '';

    for (final FoodPaymentMethod method in FoodPaymentMethod.values) {
      if (method.name.toLowerCase() == normalized) {
        return method;
      }
    }

    return FoodPaymentMethod.cash;
  }

  static String _generateDeliveryOtp() {
    final Random random = Random.secure();
    final int value = 1000 + random.nextInt(9000);

    return value.toString();
  }

  String _firebaseMessage(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'You do not have permission to perform this food order action.';
      case 'unavailable':
        return 'Firebase is temporarily unavailable. Please try again.';
      case 'not-found':
        return 'The requested food order was not found.';
      case 'failed-precondition':
        return 'Firebase requires an index or another condition before this action can run.';
      case 'aborted':
        return 'The order update was interrupted. Please try again.';
      default:
        return error.message ?? 'A Firebase error occurred (${error.code}).';
    }
  }
}

class FoodOrderServiceException implements Exception {
  const FoodOrderServiceException({required this.message, this.code = ''});

  final String message;
  final String code;

  @override
  String toString() {
    if (code.trim().isEmpty) {
      return message;
    }

    return 'FoodOrderServiceException($code): $message';
  }
}
