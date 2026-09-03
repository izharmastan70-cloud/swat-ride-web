// lib/food/restaurant_partner/services/restaurant_partner_notification_service.dart
// =============================================================
// SWAT RIDE - Restaurant Partner Notification Service
// Firebase Storage independent
// =============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

class RestaurantPartnerNotificationService {
  RestaurantPartnerNotificationService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String collection =
      'food_partner_notifications';

  CollectionReference<Map<String, dynamic>>
      get _ref => _firestore.collection(collection);

  Stream<QuerySnapshot<Map<String, dynamic>>>
      watchNotifications(String partnerId) {
    return _ref
        .where('partnerId', isEqualTo: partnerId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>
      watchUnreadNotifications(String partnerId) {
    return _ref
        .where('partnerId', isEqualTo: partnerId)
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> sendNotification({
    required String partnerId,
    required String title,
    required String message,
    String type = 'general',
  }) async {
    await _ref.add({
      'partnerId': partnerId,
      'title': title,
      'message': message,
      'type': type,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendOrderNotification({
    required String partnerId,
    required String orderId,
  }) async {
    await sendNotification(
      partnerId: partnerId,
      title: 'New Order',
      message: 'New order received. Order ID: $orderId',
      type: 'order',
    );
  }

  Future<void> sendSettlementNotification({
    required String partnerId,
    required String amount,
  }) async {
    await sendNotification(
      partnerId: partnerId,
      title: 'Settlement',
      message: 'Settlement processed: Rs. $amount',
      type: 'settlement',
    );
  }

  Future<void> sendAdminNotification({
    required String partnerId,
    required String title,
    required String message,
  }) async {
    await sendNotification(
      partnerId: partnerId,
      title: title,
      message: message,
      type: 'admin',
    );
  }

  Future<void> markAsRead(String id) async {
    await _ref.doc(id).update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAllAsRead(String partnerId) async {
    final data = await _ref
        .where('partnerId', isEqualTo: partnerId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();

    for (final doc in data.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<void> deleteNotification(String id) async {
    await _ref.doc(id).delete();
  }

  Future<void> clearAll(String partnerId) async {
    final data = await _ref
        .where('partnerId', isEqualTo: partnerId)
        .get();

    final batch = _firestore.batch();

    for (final doc in data.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
