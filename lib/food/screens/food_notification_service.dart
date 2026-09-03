// lib/food/services/food_notification_service.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Central Food Notification Service
//
// Handles notifications for:
// - Customer
// - Restaurant Partner
// - Food Delivery Rider
// - Food Admin
//
// SOS is intentionally excluded.
// =============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/food_order_model.dart';

class FoodNotificationService {
  FoodNotificationService({
    FirebaseFirestore? firestore,
  }) : _firestore =
            firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String customerCollection =
      'food_customer_notifications';

  static const String partnerCollection =
      'food_partner_notifications';

  static const String riderCollection =
      'food_rider_notifications';

  static const String adminCollection =
      'food_admin_notifications';

  CollectionReference<Map<String, dynamic>>
      get _customerRef =>
          _firestore.collection(customerCollection);

  CollectionReference<Map<String, dynamic>>
      get _partnerRef =>
          _firestore.collection(partnerCollection);

  CollectionReference<Map<String, dynamic>>
      get _riderRef =>
          _firestore.collection(riderCollection);

  CollectionReference<Map<String, dynamic>>
      get _adminRef =>
          _firestore.collection(adminCollection);

  // ===========================================================
  // CUSTOMER NOTIFICATIONS
  // ===========================================================

  Future<String> notifyCustomer({
    required String customerId,
    required String title,
    required String message,
    String orderId = '',
    String type = 'general',
    Map<String, dynamic> extraData =
        const <String, dynamic>{},
  }) {
    return _createNotification(
      collection: _customerRef,
      audienceIdField: 'customerId',
      audienceId: customerId,
      title: title,
      message: message,
      orderId: orderId,
      type: type,
      extraData: extraData,
    );
  }

  Stream<List<FoodNotificationRecord>>
      watchCustomerNotifications(
    String customerId, {
    int limit = 100,
  }) {
    return _watchNotifications(
      collection: _customerRef,
      audienceIdField: 'customerId',
      audienceId: customerId,
      limit: limit,
    );
  }

  // ===========================================================
  // RESTAURANT PARTNER NOTIFICATIONS
  // ===========================================================

  Future<String> notifyPartner({
    required String partnerId,
    required String restaurantId,
    required String title,
    required String message,
    String orderId = '',
    String type = 'general',
    Map<String, dynamic> extraData =
        const <String, dynamic>{},
  }) {
    return _createNotification(
      collection: _partnerRef,
      audienceIdField: 'partnerId',
      audienceId: partnerId,
      title: title,
      message: message,
      orderId: orderId,
      type: type,
      extraData: <String, dynamic>{
        'restaurantId': restaurantId,
        ...extraData,
      },
    );
  }

  Stream<List<FoodNotificationRecord>>
      watchPartnerNotifications(
    String partnerId, {
    int limit = 100,
  }) {
    return _watchNotifications(
      collection: _partnerRef,
      audienceIdField: 'partnerId',
      audienceId: partnerId,
      limit: limit,
    );
  }

  // ===========================================================
  // FOOD RIDER NOTIFICATIONS
  // ===========================================================

  Future<String> notifyRider({
    required String riderId,
    required String title,
    required String message,
    String orderId = '',
    String type = 'general',
    Map<String, dynamic> extraData =
        const <String, dynamic>{},
  }) {
    return _createNotification(
      collection: _riderRef,
      audienceIdField: 'riderId',
      audienceId: riderId,
      title: title,
      message: message,
      orderId: orderId,
      type: type,
      extraData: extraData,
    );
  }

  Stream<List<FoodNotificationRecord>>
      watchRiderNotifications(
    String riderId, {
    int limit = 100,
  }) {
    return _watchNotifications(
      collection: _riderRef,
      audienceIdField: 'riderId',
      audienceId: riderId,
      limit: limit,
    );
  }

  // ===========================================================
  // FOOD ADMIN NOTIFICATIONS
  // ===========================================================

  Future<String> notifyAdmin({
    required String title,
    required String message,
    String orderId = '',
    String type = 'general',
    String restaurantId = '',
    String riderId = '',
    String customerId = '',
    Map<String, dynamic> extraData =
        const <String, dynamic>{},
  }) async {
    try {
      final DocumentReference<Map<String, dynamic>>
          document = _adminRef.doc();

      await document.set(
        <String, dynamic>{
          'notificationId': document.id,
          'title': title.trim(),
          'message': message.trim(),
          'orderId': orderId.trim(),
          'restaurantId': restaurantId.trim(),
          'riderId': riderId.trim(),
          'customerId': customerId.trim(),
          'type': type.trim().isEmpty
              ? 'general'
              : type.trim(),
          'isRead': false,
          'createdAt':
              FieldValue.serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
          ...extraData,
        },
      );

      return document.id;
    } on FirebaseException catch (error) {
      throw FoodNotificationServiceException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    } catch (error) {
      throw FoodNotificationServiceException(
        message:
            'Unable to create Food admin notification: $error',
      );
    }
  }

  Stream<List<FoodNotificationRecord>>
      watchAdminNotifications({
    int limit = 100,
  }) {
    return _adminRef
        .limit(limit)
        .snapshots()
        .map(_notificationListFromQuery);
  }

  // ===========================================================
  // ORDER STATUS NOTIFICATIONS
  // ===========================================================

  Future<void> notifyOrderPlaced({
    required String customerId,
    required String restaurantName,
    required String orderId,
  }) async {
    await notifyCustomer(
      customerId: customerId,
      orderId: orderId,
      title: 'Order Placed',
      message:
          'Your order from $restaurantName has been placed successfully.',
      type: 'order_placed',
    );
  }

  Future<void> notifyRestaurantAccepted({
    required String customerId,
    required String restaurantName,
    required String orderId,
    required int preparationMinutes,
  }) async {
    await notifyCustomer(
      customerId: customerId,
      orderId: orderId,
      title: 'Order Accepted',
      message:
          '$restaurantName accepted your order. Estimated preparation time is $preparationMinutes minute(s).',
      type: 'order_accepted',
      extraData: <String, dynamic>{
        'estimatedPreparationMinutes':
            preparationMinutes,
      },
    );
  }

  Future<void> notifyPreparing({
    required String customerId,
    required String restaurantName,
    required String orderId,
  }) async {
    await notifyCustomer(
      customerId: customerId,
      orderId: orderId,
      title: 'Food Is Being Prepared',
      message:
          '$restaurantName has started preparing your food.',
      type: 'order_preparing',
    );
  }

  Future<void> notifyReadyForPickup({
    required String customerId,
    required String restaurantName,
    required String orderId,
  }) async {
    await notifyCustomer(
      customerId: customerId,
      orderId: orderId,
      title: 'Order Ready for Pickup',
      message:
          'Your order from $restaurantName is ready for rider pickup.',
      type: 'ready_for_pickup',
    );

    await notifyAdmin(
      orderId: orderId,
      title: 'Food Order Ready',
      message:
          'A Food order is ready for rider pickup.',
      type: 'ready_for_pickup',
    );
  }

  Future<void> notifyRiderAssigned({
    required String customerId,
    required String partnerId,
    required String restaurantId,
    required String riderId,
    required String orderId,
  }) async {
    final WriteBatch batch = _firestore.batch();

    _batchNotification(
      batch: batch,
      collection: _customerRef,
      audienceIdField: 'customerId',
      audienceId: customerId,
      title: 'Rider Assigned',
      message:
          'A delivery rider has been assigned to your Food order.',
      orderId: orderId,
      type: 'rider_assigned',
      extraData: <String, dynamic>{
        'riderId': riderId,
      },
    );

    _batchNotification(
      batch: batch,
      collection: _partnerRef,
      audienceIdField: 'partnerId',
      audienceId: partnerId,
      title: 'Rider Assigned',
      message:
          'A delivery rider has accepted the Food order.',
      orderId: orderId,
      type: 'rider_assigned',
      extraData: <String, dynamic>{
        'restaurantId': restaurantId,
        'riderId': riderId,
      },
    );

    _batchNotification(
      batch: batch,
      collection: _riderRef,
      audienceIdField: 'riderId',
      audienceId: riderId,
      title: 'Order Assigned',
      message:
          'The Food delivery order has been assigned to you.',
      orderId: orderId,
      type: 'order_assigned',
    );

    await batch.commit();
  }

  Future<void> notifyPickedUp({
    required String customerId,
    required String partnerId,
    required String restaurantId,
    required String riderId,
    required String orderId,
  }) async {
    final WriteBatch batch = _firestore.batch();

    _batchNotification(
      batch: batch,
      collection: _customerRef,
      audienceIdField: 'customerId',
      audienceId: customerId,
      title: 'Food Picked Up',
      message:
          'Your rider has collected the Food order from the restaurant.',
      orderId: orderId,
      type: 'picked_up',
      extraData: <String, dynamic>{
        'riderId': riderId,
      },
    );

    _batchNotification(
      batch: batch,
      collection: _partnerRef,
      audienceIdField: 'partnerId',
      audienceId: partnerId,
      title: 'Order Picked Up',
      message:
          'The rider has collected the Food order.',
      orderId: orderId,
      type: 'picked_up',
      extraData: <String, dynamic>{
        'restaurantId': restaurantId,
        'riderId': riderId,
      },
    );

    await batch.commit();
  }

  Future<void> notifyOnTheWay({
    required String customerId,
    required String riderId,
    required String orderId,
  }) async {
    await notifyCustomer(
      customerId: customerId,
      orderId: orderId,
      title: 'Order On The Way',
      message:
          'Your Food order is on the way. Keep your delivery OTP ready.',
      type: 'on_the_way',
      extraData: <String, dynamic>{
        'riderId': riderId,
      },
    );
  }

  Future<void> notifyDelivered({
    required String customerId,
    required String partnerId,
    required String restaurantId,
    required String riderId,
    required String orderId,
  }) async {
    final WriteBatch batch = _firestore.batch();

    _batchNotification(
      batch: batch,
      collection: _customerRef,
      audienceIdField: 'customerId',
      audienceId: customerId,
      title: 'Order Delivered',
      message:
          'Your Food order was delivered successfully.',
      orderId: orderId,
      type: 'delivered',
      extraData: <String, dynamic>{
        'riderId': riderId,
      },
    );

    _batchNotification(
      batch: batch,
      collection: _partnerRef,
      audienceIdField: 'partnerId',
      audienceId: partnerId,
      title: 'Delivery Completed',
      message:
          'The Food order was delivered successfully.',
      orderId: orderId,
      type: 'delivered',
      extraData: <String, dynamic>{
        'restaurantId': restaurantId,
        'riderId': riderId,
      },
    );

    _batchNotification(
      batch: batch,
      collection: _riderRef,
      audienceIdField: 'riderId',
      audienceId: riderId,
      title: 'Delivery Completed',
      message:
          'The Food delivery was completed and earnings were updated.',
      orderId: orderId,
      type: 'delivered',
    );

    final DocumentReference<Map<String, dynamic>>
        adminDocument = _adminRef.doc();

    batch.set(
      adminDocument,
      <String, dynamic>{
        'notificationId': adminDocument.id,
        'title': 'Food Delivery Completed',
        'message':
            'A Food order was delivered successfully.',
        'orderId': orderId,
        'restaurantId': restaurantId,
        'riderId': riderId,
        'customerId': customerId,
        'type': 'delivered',
        'isRead': false,
        'createdAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
  }

  Future<void> notifyCancelled({
    required String customerId,
    required String orderId,
    required String cancelledBy,
    required String reason,
    String partnerId = '',
    String restaurantId = '',
    String riderId = '',
  }) async {
    final WriteBatch batch = _firestore.batch();

    if (cancelledBy != 'customer') {
      _batchNotification(
        batch: batch,
        collection: _customerRef,
        audienceIdField: 'customerId',
        audienceId: customerId,
        title: 'Order Cancelled',
        message: reason.trim().isEmpty
            ? 'Your Food order was cancelled.'
            : 'Your Food order was cancelled: ${reason.trim()}',
        orderId: orderId,
        type: 'cancelled',
        extraData: <String, dynamic>{
          'cancelledBy': cancelledBy,
          'reason': reason.trim(),
        },
      );
    }

    if (partnerId.trim().isNotEmpty &&
        cancelledBy != 'restaurant') {
      _batchNotification(
        batch: batch,
        collection: _partnerRef,
        audienceIdField: 'partnerId',
        audienceId: partnerId,
        title: 'Order Cancelled',
        message:
            'Food order #${_shortId(orderId)} was cancelled.',
        orderId: orderId,
        type: 'cancelled',
        extraData: <String, dynamic>{
          'restaurantId': restaurantId,
          'cancelledBy': cancelledBy,
          'reason': reason.trim(),
        },
      );
    }

    if (riderId.trim().isNotEmpty &&
        cancelledBy != 'rider') {
      _batchNotification(
        batch: batch,
        collection: _riderRef,
        audienceIdField: 'riderId',
        audienceId: riderId,
        title: 'Order Cancelled',
        message:
            'Assigned Food order #${_shortId(orderId)} was cancelled.',
        orderId: orderId,
        type: 'cancelled',
        extraData: <String, dynamic>{
          'cancelledBy': cancelledBy,
          'reason': reason.trim(),
        },
      );
    }

    final DocumentReference<Map<String, dynamic>>
        adminDocument = _adminRef.doc();

    batch.set(
      adminDocument,
      <String, dynamic>{
        'notificationId': adminDocument.id,
        'title': 'Food Order Cancelled',
        'message':
            'Food order #${_shortId(orderId)} was cancelled by $cancelledBy.',
        'orderId': orderId,
        'restaurantId': restaurantId,
        'riderId': riderId,
        'customerId': customerId,
        'type': 'cancelled',
        'cancelledBy': cancelledBy,
        'reason': reason.trim(),
        'isRead': false,
        'createdAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
  }

  Future<void> notifyStatusChanged({
    required FoodOrderStatus status,
    required String customerId,
    required String orderId,
    required String restaurantName,
    String partnerId = '',
    String restaurantId = '',
    String riderId = '',
    int preparationMinutes = 0,
  }) async {
    switch (status) {
      case FoodOrderStatus.pending:
        await notifyOrderPlaced(
          customerId: customerId,
          restaurantName: restaurantName,
          orderId: orderId,
        );
      case FoodOrderStatus.accepted:
        await notifyRestaurantAccepted(
          customerId: customerId,
          restaurantName: restaurantName,
          orderId: orderId,
          preparationMinutes: preparationMinutes,
        );
      case FoodOrderStatus.preparing:
        await notifyPreparing(
          customerId: customerId,
          restaurantName: restaurantName,
          orderId: orderId,
        );
      case FoodOrderStatus.readyForPickup:
        await notifyReadyForPickup(
          customerId: customerId,
          restaurantName: restaurantName,
          orderId: orderId,
        );
      case FoodOrderStatus.pickedUp:
        if (partnerId.trim().isNotEmpty &&
            riderId.trim().isNotEmpty) {
          await notifyPickedUp(
            customerId: customerId,
            partnerId: partnerId,
            restaurantId: restaurantId,
            riderId: riderId,
            orderId: orderId,
          );
        }
      case FoodOrderStatus.onTheWay:
        await notifyOnTheWay(
          customerId: customerId,
          riderId: riderId,
          orderId: orderId,
        );
      case FoodOrderStatus.delivered:
        if (partnerId.trim().isNotEmpty &&
            riderId.trim().isNotEmpty) {
          await notifyDelivered(
            customerId: customerId,
            partnerId: partnerId,
            restaurantId: restaurantId,
            riderId: riderId,
            orderId: orderId,
          );
        }
      case FoodOrderStatus.cancelled:
        return;
    }
  }

  // ===========================================================
  // READ / DELETE
  // ===========================================================

  Future<void> markCustomerNotificationRead(
    String notificationId,
  ) {
    return _markRead(
      _customerRef,
      notificationId,
    );
  }

  Future<void> markPartnerNotificationRead(
    String notificationId,
  ) {
    return _markRead(
      _partnerRef,
      notificationId,
    );
  }

  Future<void> markRiderNotificationRead(
    String notificationId,
  ) {
    return _markRead(
      _riderRef,
      notificationId,
    );
  }

  Future<void> markAdminNotificationRead(
    String notificationId,
  ) {
    return _markRead(
      _adminRef,
      notificationId,
    );
  }

  Future<void> markAllCustomerNotificationsRead(
    String customerId,
  ) {
    return _markAllRead(
      collection: _customerRef,
      audienceIdField: 'customerId',
      audienceId: customerId,
    );
  }

  Future<void> markAllPartnerNotificationsRead(
    String partnerId,
  ) {
    return _markAllRead(
      collection: _partnerRef,
      audienceIdField: 'partnerId',
      audienceId: partnerId,
    );
  }

  Future<void> markAllRiderNotificationsRead(
    String riderId,
  ) {
    return _markAllRead(
      collection: _riderRef,
      audienceIdField: 'riderId',
      audienceId: riderId,
    );
  }

  Future<void> deleteCustomerNotification(
    String notificationId,
  ) {
    return _deleteNotification(
      _customerRef,
      notificationId,
    );
  }

  Future<void> deletePartnerNotification(
    String notificationId,
  ) {
    return _deleteNotification(
      _partnerRef,
      notificationId,
    );
  }

  Future<void> deleteRiderNotification(
    String notificationId,
  ) {
    return _deleteNotification(
      _riderRef,
      notificationId,
    );
  }

  Future<void> deleteAdminNotification(
    String notificationId,
  ) {
    return _deleteNotification(
      _adminRef,
      notificationId,
    );
  }

  // ===========================================================
  // INTERNAL HELPERS
  // ===========================================================

  Future<String> _createNotification({
    required CollectionReference<Map<String, dynamic>>
        collection,
    required String audienceIdField,
    required String audienceId,
    required String title,
    required String message,
    required String orderId,
    required String type,
    required Map<String, dynamic> extraData,
  }) async {
    if (audienceId.trim().isEmpty) {
      throw const FoodNotificationServiceException(
        message: 'Notification recipient ID is required.',
      );
    }

    try {
      final DocumentReference<Map<String, dynamic>>
          document = collection.doc();

      await document.set(
        <String, dynamic>{
          'notificationId': document.id,
          audienceIdField: audienceId.trim(),
          'title': title.trim(),
          'message': message.trim(),
          'orderId': orderId.trim(),
          'type': type.trim().isEmpty
              ? 'general'
              : type.trim(),
          'isRead': false,
          'createdAt':
              FieldValue.serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
          ...extraData,
        },
      );

      return document.id;
    } on FirebaseException catch (error) {
      throw FoodNotificationServiceException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    } catch (error) {
      throw FoodNotificationServiceException(
        message:
            'Unable to create Food notification: $error',
      );
    }
  }

  void _batchNotification({
    required WriteBatch batch,
    required CollectionReference<Map<String, dynamic>>
        collection,
    required String audienceIdField,
    required String audienceId,
    required String title,
    required String message,
    required String orderId,
    required String type,
    Map<String, dynamic> extraData =
        const <String, dynamic>{},
  }) {
    if (audienceId.trim().isEmpty) {
      return;
    }

    final DocumentReference<Map<String, dynamic>>
        document = collection.doc();

    batch.set(
      document,
      <String, dynamic>{
        'notificationId': document.id,
        audienceIdField: audienceId.trim(),
        'title': title.trim(),
        'message': message.trim(),
        'orderId': orderId.trim(),
        'type': type.trim().isEmpty
            ? 'general'
            : type.trim(),
        'isRead': false,
        'createdAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
        ...extraData,
      },
    );
  }

  Stream<List<FoodNotificationRecord>>
      _watchNotifications({
    required CollectionReference<Map<String, dynamic>>
        collection,
    required String audienceIdField,
    required String audienceId,
    required int limit,
  }) {
    if (audienceId.trim().isEmpty) {
      return Stream<List<FoodNotificationRecord>>.value(
        const <FoodNotificationRecord>[],
      );
    }

    return collection
        .where(
          audienceIdField,
          isEqualTo: audienceId.trim(),
        )
        .limit(limit)
        .snapshots()
        .map(_notificationListFromQuery);
  }

  List<FoodNotificationRecord>
      _notificationListFromQuery(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final List<FoodNotificationRecord> values =
        snapshot.docs.map(
      (
        QueryDocumentSnapshot<Map<String, dynamic>>
            document,
      ) {
        return FoodNotificationRecord.fromMap(
          <String, dynamic>{
            ...document.data(),
            'notificationId': document.id,
          },
        );
      },
    ).toList();

    values.sort(
      (
        FoodNotificationRecord first,
        FoodNotificationRecord second,
      ) =>
          second.createdAt.compareTo(
        first.createdAt,
      ),
    );

    return values;
  }

  Future<void> _markRead(
    CollectionReference<Map<String, dynamic>>
        collection,
    String notificationId,
  ) async {
    if (notificationId.trim().isEmpty) {
      return;
    }

    try {
      await collection.doc(notificationId).update(
        <String, dynamic>{
          'isRead': true,
          'readAt':
              FieldValue.serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
      );
    } on FirebaseException catch (error) {
      throw FoodNotificationServiceException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    }
  }

  Future<void> _markAllRead({
    required CollectionReference<Map<String, dynamic>>
        collection,
    required String audienceIdField,
    required String audienceId,
  }) async {
    if (audienceId.trim().isEmpty) {
      return;
    }

    try {
      final QuerySnapshot<Map<String, dynamic>>
          snapshot = await collection
              .where(
                audienceIdField,
                isEqualTo: audienceId.trim(),
              )
              .where(
                'isRead',
                isEqualTo: false,
              )
              .get();

      if (snapshot.docs.isEmpty) {
        return;
      }

      final WriteBatch batch =
          _firestore.batch();

      for (final QueryDocumentSnapshot<
              Map<String, dynamic>>
          document in snapshot.docs) {
        batch.update(
          document.reference,
          <String, dynamic>{
            'isRead': true,
            'readAt':
                FieldValue.serverTimestamp(),
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );
      }

      await batch.commit();
    } on FirebaseException catch (error) {
      throw FoodNotificationServiceException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    }
  }

  Future<void> _deleteNotification(
    CollectionReference<Map<String, dynamic>>
        collection,
    String notificationId,
  ) async {
    if (notificationId.trim().isEmpty) {
      return;
    }

    try {
      await collection.doc(notificationId).delete();
    } on FirebaseException catch (error) {
      throw FoodNotificationServiceException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    }
  }

  static String _shortId(String value) {
    if (value.length <= 8) {
      return value;
    }

    return value.substring(0, 8);
  }

  String _firebaseMessage(
    FirebaseException error,
  ) {
    switch (error.code) {
      case 'permission-denied':
        return 'You do not have permission to access Food notifications.';
      case 'unavailable':
        return 'Food notifications are temporarily unavailable.';
      case 'not-found':
        return 'The Food notification was not found.';
      case 'failed-precondition':
        return 'Firebase requires an index or another condition before this notification action can run.';
      default:
        return error.message ??
            'A Firebase notification error occurred (${error.code}).';
    }
  }
}

class FoodNotificationRecord {
  const FoodNotificationRecord({
    required this.notificationId,
    required this.title,
    required this.message,
    required this.type,
    required this.orderId,
    required this.isRead,
    required this.createdAt,
    required this.data,
  });

  final String notificationId;
  final String title;
  final String message;
  final String type;
  final String orderId;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic> data;

  factory FoodNotificationRecord.fromMap(
    Map<String, dynamic> map,
  ) {
    return FoodNotificationRecord(
      notificationId:
          map['notificationId']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      type: map['type']?.toString() ?? 'general',
      orderId: map['orderId']?.toString() ?? '',
      isRead: map['isRead'] == true,
      createdAt: _dateValue(map['createdAt']),
      data: Map<String, dynamic>.from(map),
    );
  }

  static DateTime _dateValue(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    try {
      final dynamic converted = value.toDate();

      if (converted is DateTime) {
        return converted;
      }
    } catch (_) {}

    return DateTime.tryParse(
          value?.toString() ?? '',
        ) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }
}

class FoodNotificationServiceException
    implements Exception {
  const FoodNotificationServiceException({
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

    return 'FoodNotificationServiceException($code): $message';
  }
}
