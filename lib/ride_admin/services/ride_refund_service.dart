import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ride_refund_request_model.dart';

class RideRefundService {
  RideRefundService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String collectionName = 'ride_refund_requests';

  CollectionReference<Map<String, dynamic>> get _refunds =>
      _firestore.collection(collectionName);

  Stream<List<RideRefundRequestModel>> watchRefundRequests({
    RideRefundStatus? status,
  }) {
    return _refunds
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map(
                (document) => RideRefundRequestModel.fromMap(
                  document.data(),
                  documentId: document.id,
                ),
              )
              .toList(growable: false);

          if (status == null) {
            return items;
          }

          return items
              .where((item) => item.status == status)
              .toList(growable: false);
        });
  }

  Future<String> createRefundRequest({
    required String rideId,
    required String paymentId,
    required String userId,
    required double originalAmount,
    required double refundAmount,
    required String reason,
    String paymentMethod = '',
    String providerTransactionId = '',
  }) async {
    final normalizedRideId = rideId.trim();
    final normalizedPaymentId = paymentId.trim();
    final normalizedUserId = userId.trim();
    final normalizedReason = reason.trim();

    if (normalizedRideId.isEmpty) {
      throw ArgumentError('Ride ID is required.');
    }

    if (normalizedPaymentId.isEmpty) {
      throw ArgumentError('Payment ID is required.');
    }

    if (normalizedUserId.isEmpty) {
      throw ArgumentError('User ID is required.');
    }

    if (originalAmount <= 0) {
      throw ArgumentError('Original payment amount must be greater than zero.');
    }

    if (refundAmount <= 0) {
      throw ArgumentError('Refund amount must be greater than zero.');
    }

    if (refundAmount > originalAmount) {
      throw ArgumentError(
        'Refund amount cannot exceed the original payment amount.',
      );
    }

    if (normalizedReason.isEmpty) {
      throw ArgumentError('Refund reason is required.');
    }

    final existing = await _refunds
        .where('paymentId', isEqualTo: normalizedPaymentId)
        .where(
          'status',
          whereIn: <String>[
            RideRefundStatus.pending.name,
            RideRefundStatus.approved.name,
            RideRefundStatus.refunded.name,
          ],
        )
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw StateError(
        'An active or completed refund request already exists for this payment.',
      );
    }

    final reference = _refunds.doc();

    await reference.set(<String, dynamic>{
      'rideId': normalizedRideId,
      'paymentId': normalizedPaymentId,
      'userId': normalizedUserId,
      'originalAmount': originalAmount,
      'refundAmount': refundAmount,
      'paymentMethod': paymentMethod.trim(),
      'providerTransactionId': providerTransactionId.trim(),
      'reason': normalizedReason,
      'status': RideRefundStatus.pending.name,
      'adminNote': '',
      'reviewedBy': '',
      'reviewedByName': '',
      'createdAt': FieldValue.serverTimestamp(),
      'reviewedAt': null,
      'refundedAt': null,

      // Real gateway refund must remain explicit.
      // JazzCash / Easypaisa / card provider APIs connect later.
      'gatewayRefundExecuted': false,
      'gatewayRefundReference': '',
    });

    return reference.id;
  }

  Future<void> approveRefund({
    required String refundId,
    required String adminId,
    String adminName = '',
    required String adminNote,
  }) async {
    await _review(
      refundId: refundId,
      adminId: adminId,
      adminName: adminName,
      adminNote: adminNote,
      newStatus: RideRefundStatus.approved,
    );
  }

  Future<void> rejectRefund({
    required String refundId,
    required String adminId,
    String adminName = '',
    required String adminNote,
  }) async {
    await _review(
      refundId: refundId,
      adminId: adminId,
      adminName: adminName,
      adminNote: adminNote,
      newStatus: RideRefundStatus.rejected,
    );
  }

  Future<void> _review({
    required String refundId,
    required String adminId,
    required String adminName,
    required String adminNote,
    required RideRefundStatus newStatus,
  }) async {
    final normalizedRefundId = refundId.trim();
    final normalizedAdminId = adminId.trim();
    final normalizedNote = adminNote.trim();

    if (normalizedRefundId.isEmpty) {
      throw ArgumentError('Refund request ID is required.');
    }

    if (normalizedAdminId.isEmpty) {
      throw ArgumentError('Admin ID is required.');
    }

    if (normalizedNote.isEmpty) {
      throw ArgumentError('Admin reason/note is required.');
    }

    if (newStatus != RideRefundStatus.approved &&
        newStatus != RideRefundStatus.rejected) {
      throw ArgumentError('Invalid refund review status.');
    }

    final reference = _refunds.doc(normalizedRefundId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);

      if (!snapshot.exists) {
        throw StateError('Refund request does not exist.');
      }

      final data = snapshot.data() ?? <String, dynamic>{};
      final currentStatus = RideRefundRequestModel.statusFromValue(
        data['status'],
      );

      if (currentStatus != RideRefundStatus.pending) {
        throw StateError('Only pending refund requests can be reviewed.');
      }

      transaction.update(reference, <String, dynamic>{
        'status': newStatus.name,
        'adminNote': normalizedNote,
        'reviewedBy': normalizedAdminId,
        'reviewedByName': adminName.trim(),
        'reviewedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> markRefunded({
    required String refundId,
    required String adminId,
    required String gatewayRefundReference,
    required bool gatewayRefundExecuted,
  }) async {
    final normalizedRefundId = refundId.trim();
    final normalizedAdminId = adminId.trim();
    final normalizedReference = gatewayRefundReference.trim();

    if (normalizedRefundId.isEmpty) {
      throw ArgumentError('Refund request ID is required.');
    }

    if (normalizedAdminId.isEmpty) {
      throw ArgumentError('Admin ID is required.');
    }

    if (!gatewayRefundExecuted) {
      throw StateError(
        'Refund cannot be marked refunded until payment execution is confirmed.',
      );
    }

    if (normalizedReference.isEmpty) {
      throw ArgumentError('Gateway refund reference is required.');
    }

    final reference = _refunds.doc(normalizedRefundId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);

      if (!snapshot.exists) {
        throw StateError('Refund request does not exist.');
      }

      final data = snapshot.data() ?? <String, dynamic>{};
      final currentStatus = RideRefundRequestModel.statusFromValue(
        data['status'],
      );

      if (currentStatus != RideRefundStatus.approved) {
        throw StateError('Only an approved refund can be marked refunded.');
      }

      transaction.update(reference, <String, dynamic>{
        'status': RideRefundStatus.refunded.name,
        'gatewayRefundExecuted': true,
        'gatewayRefundReference': normalizedReference,
        'refundedBy': normalizedAdminId,
        'refundedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
