// lib/food/services/food_order_dispute_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/food_order_dispute_model.dart';

class FoodOrderDisputeService {
  FoodOrderDisputeService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String collectionName = 'food_order_disputes';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  // ==========================================================
  // CREATE DISPUTE
  // ==========================================================

  Future<String> createDispute({
    required String orderId,
    required String customerId,
    required String restaurantId,
    String riderId = '',
    required FoodOrderDisputeRaisedBy raisedBy,
    required String raisedById,
    required FoodOrderDisputeReason reason,
    required String description,
    bool refundRequested = false,
    double requestedRefundAmount = 0,
  }) async {
    final String cleanOrderId = orderId.trim();
    final String cleanRaisedById = raisedById.trim();
    final String cleanDescription = description.trim();

    if (cleanOrderId.isEmpty) {
      throw ArgumentError('Food order ID is required.');
    }

    if (cleanRaisedById.isEmpty) {
      throw ArgumentError('Dispute creator ID is required.');
    }

    if (cleanDescription.isEmpty) {
      throw ArgumentError('Dispute description is required.');
    }

    if (requestedRefundAmount < 0) {
      throw ArgumentError('Requested refund amount cannot be negative.');
    }

    final QuerySnapshot<Map<String, dynamic>> existingOpenDisputes =
        await _collection.where('orderId', isEqualTo: cleanOrderId).get();

    for (final QueryDocumentSnapshot<Map<String, dynamic>> document
        in existingOpenDisputes.docs) {
      final FoodOrderDisputeModel existing = _fromDocument(document);

      if (!existing.status.isClosed) {
        throw StateError('An open dispute already exists for this food order.');
      }
    }

    final DocumentReference<Map<String, dynamic>> document = _collection.doc();

    final DateTime now = DateTime.now();

    final FoodOrderDisputeModel dispute = FoodOrderDisputeModel(
      disputeId: document.id,
      orderId: cleanOrderId,
      customerId: customerId.trim(),
      restaurantId: restaurantId.trim(),
      riderId: riderId.trim(),
      raisedBy: raisedBy,
      raisedById: cleanRaisedById,
      reason: reason,
      description: cleanDescription,
      status: FoodOrderDisputeStatus.open,
      refundRequested: refundRequested,
      requestedRefundAmount: refundRequested ? requestedRefundAmount : 0,
      refundApproved: false,
      approvedRefundAmount: 0,
      resolutionNote: '',
      resolvedBy: '',
      createdAt: now,
      updatedAt: now,
    );

    final Map<String, dynamic> data = dispute.toMap();

    data['createdAt'] = Timestamp.fromDate(now);
    data['updatedAt'] = Timestamp.fromDate(now);
    data['resolvedAt'] = null;

    await document.set(data);

    return document.id;
  }

  // ==========================================================
  // GET SINGLE DISPUTE
  // ==========================================================

  Future<FoodOrderDisputeModel?> getDispute(String disputeId) async {
    final String cleanId = disputeId.trim();

    if (cleanId.isEmpty) {
      return null;
    }

    final DocumentSnapshot<Map<String, dynamic>> document = await _collection
        .doc(cleanId)
        .get();

    if (!document.exists || document.data() == null) {
      return null;
    }

    return _fromDocument(document);
  }

  // ==========================================================
  // WATCH SINGLE DISPUTE
  // ==========================================================

  Stream<FoodOrderDisputeModel?> watchDispute(String disputeId) {
    final String cleanId = disputeId.trim();

    if (cleanId.isEmpty) {
      return Stream<FoodOrderDisputeModel?>.value(null);
    }

    return _collection.doc(cleanId).snapshots().map((
      DocumentSnapshot<Map<String, dynamic>> document,
    ) {
      if (!document.exists || document.data() == null) {
        return null;
      }

      return _fromDocument(document);
    });
  }

  // ==========================================================
  // GET DISPUTES FOR ORDER
  // ==========================================================

  Future<List<FoodOrderDisputeModel>> getOrderDisputes(String orderId) async {
    final String cleanOrderId = orderId.trim();

    if (cleanOrderId.isEmpty) {
      return <FoodOrderDisputeModel>[];
    }

    final QuerySnapshot<Map<String, dynamic>> snapshot = await _collection
        .where('orderId', isEqualTo: cleanOrderId)
        .get();

    final List<FoodOrderDisputeModel> disputes = snapshot.docs
        .map(_fromDocument)
        .toList();

    disputes.sort(
      (FoodOrderDisputeModel a, FoodOrderDisputeModel b) =>
          b.createdAt.compareTo(a.createdAt),
    );

    return disputes;
  }

  // ==========================================================
  // WATCH CUSTOMER DISPUTES
  // ==========================================================

  Stream<List<FoodOrderDisputeModel>> watchCustomerDisputes(String customerId) {
    final String cleanCustomerId = customerId.trim();

    if (cleanCustomerId.isEmpty) {
      return Stream<List<FoodOrderDisputeModel>>.value(
        <FoodOrderDisputeModel>[],
      );
    }

    return _collection
        .where('customerId', isEqualTo: cleanCustomerId)
        .snapshots()
        .map(_sortedDisputes);
  }

  // ==========================================================
  // WATCH RESTAURANT DISPUTES
  // ==========================================================

  Stream<List<FoodOrderDisputeModel>> watchRestaurantDisputes(
    String restaurantId,
  ) {
    final String cleanRestaurantId = restaurantId.trim();

    if (cleanRestaurantId.isEmpty) {
      return Stream<List<FoodOrderDisputeModel>>.value(
        <FoodOrderDisputeModel>[],
      );
    }

    return _collection
        .where('restaurantId', isEqualTo: cleanRestaurantId)
        .snapshots()
        .map(_sortedDisputes);
  }

  // ==========================================================
  // WATCH RIDER DISPUTES
  // ==========================================================

  Stream<List<FoodOrderDisputeModel>> watchRiderDisputes(String riderId) {
    final String cleanRiderId = riderId.trim();

    if (cleanRiderId.isEmpty) {
      return Stream<List<FoodOrderDisputeModel>>.value(
        <FoodOrderDisputeModel>[],
      );
    }

    return _collection
        .where('riderId', isEqualTo: cleanRiderId)
        .snapshots()
        .map(_sortedDisputes);
  }

  // ==========================================================
  // WATCH ALL DISPUTES - ADMIN
  // ==========================================================

  Stream<List<FoodOrderDisputeModel>> watchAllDisputes() {
    return _collection.snapshots().map(_sortedDisputes);
  }

  // ==========================================================
  // MARK UNDER REVIEW
  // ==========================================================

  Future<void> markUnderReview({
    required String disputeId,
    required String adminId,
  }) async {
    await _updateOpenDisputeStatus(
      disputeId: disputeId,
      adminId: adminId,
      status: FoodOrderDisputeStatus.underReview,
    );
  }

  // ==========================================================
  // REQUEST CUSTOMER RESPONSE
  // ==========================================================

  Future<void> requestCustomerResponse({
    required String disputeId,
    required String adminId,
  }) async {
    await _updateOpenDisputeStatus(
      disputeId: disputeId,
      adminId: adminId,
      status: FoodOrderDisputeStatus.awaitingCustomer,
    );
  }

  // ==========================================================
  // REQUEST RESTAURANT RESPONSE
  // ==========================================================

  Future<void> requestRestaurantResponse({
    required String disputeId,
    required String adminId,
  }) async {
    await _updateOpenDisputeStatus(
      disputeId: disputeId,
      adminId: adminId,
      status: FoodOrderDisputeStatus.awaitingRestaurant,
    );
  }

  // ==========================================================
  // REQUEST RIDER RESPONSE
  // ==========================================================

  Future<void> requestRiderResponse({
    required String disputeId,
    required String adminId,
  }) async {
    await _updateOpenDisputeStatus(
      disputeId: disputeId,
      adminId: adminId,
      status: FoodOrderDisputeStatus.awaitingRider,
    );
  }

  // ==========================================================
  // RESTAURANT RESPONSE
  // ==========================================================

  Future<void> submitRestaurantResponse({
    required String disputeId,
    required String restaurantId,
    required String response,
  }) async {
    await _submitRequestedResponse(
      disputeId: disputeId,
      actorId: restaurantId,
      response: response,
      expectedStatus: FoodOrderDisputeStatus.awaitingRestaurant,
      actorType: FoodOrderDisputeRaisedBy.restaurant,
    );
  }

  // ==========================================================
  // RIDER RESPONSE
  // ==========================================================

  Future<void> submitRiderResponse({
    required String disputeId,
    required String riderId,
    required String response,
  }) async {
    await _submitRequestedResponse(
      disputeId: disputeId,
      actorId: riderId,
      response: response,
      expectedStatus: FoodOrderDisputeStatus.awaitingRider,
      actorType: FoodOrderDisputeRaisedBy.rider,
    );
  }

  // ==========================================================
  // INTERNAL REQUESTED RESPONSE SUBMISSION
  // ==========================================================

  Future<void> _submitRequestedResponse({
    required String disputeId,
    required String actorId,
    required String response,
    required FoodOrderDisputeStatus expectedStatus,
    required FoodOrderDisputeRaisedBy actorType,
  }) async {
    final String cleanDisputeId = disputeId.trim();

    final String cleanActorId = actorId.trim();

    final String cleanResponse = response.trim();

    if (cleanDisputeId.isEmpty) {
      throw ArgumentError('Dispute ID is required.');
    }

    if (cleanActorId.isEmpty) {
      throw ArgumentError('Response actor ID is required.');
    }

    if (cleanResponse.isEmpty) {
      throw ArgumentError('Dispute response cannot be empty.');
    }

    if (cleanResponse.length > 2000) {
      throw ArgumentError('Dispute response is too long.');
    }

    final DocumentReference<Map<String, dynamic>> reference = _collection.doc(
      cleanDisputeId,
    );

    await _firestore.runTransaction((Transaction transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await transaction
          .get(reference);

      if (!snapshot.exists || snapshot.data() == null) {
        throw StateError('Food dispute not found.');
      }

      final FoodOrderDisputeModel dispute = _fromDocument(snapshot);

      if (dispute.status.isClosed) {
        throw StateError('Closed food dispute cannot receive a response.');
      }

      if (dispute.status != expectedStatus) {
        if (actorType == FoodOrderDisputeRaisedBy.restaurant) {
          throw StateError(
            'Food Admin has not requested a restaurant response for this dispute.',
          );
        }

        if (actorType == FoodOrderDisputeRaisedBy.rider) {
          throw StateError(
            'Food Admin has not requested a rider response for this dispute.',
          );
        }

        throw StateError('A response is not currently requested.');
      }

      if (actorType == FoodOrderDisputeRaisedBy.restaurant) {
        if (dispute.restaurantId.trim().isEmpty ||
            dispute.restaurantId.trim() != cleanActorId) {
          throw StateError('This restaurant cannot respond to this dispute.');
        }
      }

      if (actorType == FoodOrderDisputeRaisedBy.rider) {
        if (dispute.riderId.trim().isEmpty ||
            dispute.riderId.trim() != cleanActorId) {
          throw StateError('This rider cannot respond to this dispute.');
        }
      }

      final Timestamp now = Timestamp.now();

      final Map<String, dynamic> updates = <String, dynamic>{
        'status': FoodOrderDisputeStatus.underReview.name,
        'lastResponseType': actorType.name,
        'lastResponseBy': cleanActorId,
        'lastResponse': cleanResponse,
        'lastResponseAt': now,
        'updatedAt': now,
      };

      if (actorType == FoodOrderDisputeRaisedBy.restaurant) {
        updates.addAll(<String, dynamic>{
          'restaurantResponse': cleanResponse,
          'restaurantRespondedBy': cleanActorId,
          'restaurantRespondedAt': now,
        });
      }

      if (actorType == FoodOrderDisputeRaisedBy.rider) {
        updates.addAll(<String, dynamic>{
          'riderResponse': cleanResponse,
          'riderRespondedBy': cleanActorId,
          'riderRespondedAt': now,
        });
      }

      transaction.update(reference, updates);
    });
  }
  // ==========================================================
  // RESOLVE DISPUTE
  // ==========================================================
  //
  // IMPORTANT:
  // This only records Admin refund approval.
  // It DOES NOT execute Wallet / JazzCash / Easypaisa /
  // card gateway refunds.
  // ==========================================================

  Future<void> resolveDispute({
    required String disputeId,
    required String adminId,
    required String resolutionNote,
    bool approveRefund = false,
    double approvedRefundAmount = 0,
  }) async {
    final String cleanDisputeId = disputeId.trim();

    final String cleanAdminId = adminId.trim();

    final String cleanResolutionNote = resolutionNote.trim();

    if (cleanDisputeId.isEmpty) {
      throw ArgumentError('Dispute ID is required.');
    }

    if (cleanAdminId.isEmpty) {
      throw ArgumentError('Admin ID is required.');
    }

    if (cleanResolutionNote.isEmpty) {
      throw ArgumentError('Resolution note is required.');
    }

    if (approvedRefundAmount < 0) {
      throw ArgumentError('Approved refund amount cannot be negative.');
    }

    final DocumentReference<Map<String, dynamic>> reference = _collection.doc(
      cleanDisputeId,
    );

    await _firestore.runTransaction((Transaction transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await transaction
          .get(reference);

      if (!snapshot.exists || snapshot.data() == null) {
        throw StateError('Food dispute not found.');
      }

      final FoodOrderDisputeModel dispute = _fromDocument(snapshot);

      if (dispute.status.isClosed) {
        throw StateError('This food dispute is already closed.');
      }

      double safeRefundAmount = 0;

      if (approveRefund) {
        safeRefundAmount = approvedRefundAmount;

        if (safeRefundAmount <= 0) {
          throw ArgumentError(
            'Approved refund amount must be greater than zero.',
          );
        }

        if (dispute.requestedRefundAmount > 0 &&
            safeRefundAmount > dispute.requestedRefundAmount) {
          throw ArgumentError(
            'Approved refund cannot exceed the requested refund amount.',
          );
        }
      }

      final Timestamp now = Timestamp.now();

      transaction.update(reference, <String, dynamic>{
        'status': FoodOrderDisputeStatus.resolved.name,
        'refundApproved': approveRefund,
        'approvedRefundAmount': approveRefund ? safeRefundAmount : 0,
        'resolutionNote': cleanResolutionNote,
        'resolvedBy': cleanAdminId,
        'resolvedAt': now,
        'updatedAt': now,

        // Refund execution is intentionally pending.
        'refundExecutionStatus': approveRefund
            ? 'approved_pending_execution'
            : 'not_required',
      });
    });
  }

  // ==========================================================
  // REJECT DISPUTE
  // ==========================================================

  Future<void> rejectDispute({
    required String disputeId,
    required String adminId,
    required String resolutionNote,
  }) async {
    final String cleanNote = resolutionNote.trim();

    if (cleanNote.isEmpty) {
      throw ArgumentError('Rejection reason is required.');
    }

    await _closeDispute(
      disputeId: disputeId,
      adminId: adminId,
      status: FoodOrderDisputeStatus.rejected,
      resolutionNote: cleanNote,
    );
  }

  // ==========================================================
  // CANCEL DISPUTE
  // ==========================================================

  Future<void> cancelDispute({
    required String disputeId,
    required String actorId,
    required String reason,
  }) async {
    final String cleanReason = reason.trim();

    if (cleanReason.isEmpty) {
      throw ArgumentError('Cancellation reason is required.');
    }

    await _closeDispute(
      disputeId: disputeId,
      adminId: actorId,
      status: FoodOrderDisputeStatus.cancelled,
      resolutionNote: cleanReason,
    );
  }

  // ==========================================================
  // INTERNAL STATUS UPDATE
  // ==========================================================

  Future<void> _updateOpenDisputeStatus({
    required String disputeId,
    required String adminId,
    required FoodOrderDisputeStatus status,
  }) async {
    final String cleanDisputeId = disputeId.trim();

    final String cleanAdminId = adminId.trim();

    if (cleanDisputeId.isEmpty) {
      throw ArgumentError('Dispute ID is required.');
    }

    if (cleanAdminId.isEmpty) {
      throw ArgumentError('Admin ID is required.');
    }

    final DocumentReference<Map<String, dynamic>> reference = _collection.doc(
      cleanDisputeId,
    );

    await _firestore.runTransaction((Transaction transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await transaction
          .get(reference);

      if (!snapshot.exists || snapshot.data() == null) {
        throw StateError('Food dispute not found.');
      }

      final FoodOrderDisputeModel dispute = _fromDocument(snapshot);

      if (dispute.status.isClosed) {
        throw StateError('Closed food dispute cannot be updated.');
      }

      transaction.update(reference, <String, dynamic>{
        'status': status.name,
        'lastReviewedBy': cleanAdminId,
        'updatedAt': Timestamp.now(),
      });
    });
  }

  // ==========================================================
  // INTERNAL CLOSE
  // ==========================================================

  Future<void> _closeDispute({
    required String disputeId,
    required String adminId,
    required FoodOrderDisputeStatus status,
    required String resolutionNote,
  }) async {
    final String cleanDisputeId = disputeId.trim();

    final String cleanAdminId = adminId.trim();

    if (cleanDisputeId.isEmpty) {
      throw ArgumentError('Dispute ID is required.');
    }

    if (cleanAdminId.isEmpty) {
      throw ArgumentError('Actor/Admin ID is required.');
    }

    final DocumentReference<Map<String, dynamic>> reference = _collection.doc(
      cleanDisputeId,
    );

    await _firestore.runTransaction((Transaction transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await transaction
          .get(reference);

      if (!snapshot.exists || snapshot.data() == null) {
        throw StateError('Food dispute not found.');
      }

      final FoodOrderDisputeModel dispute = _fromDocument(snapshot);

      if (dispute.status.isClosed) {
        throw StateError('This food dispute is already closed.');
      }

      final Timestamp now = Timestamp.now();

      transaction.update(reference, <String, dynamic>{
        'status': status.name,
        'refundApproved': false,
        'approvedRefundAmount': 0,
        'resolutionNote': resolutionNote,
        'resolvedBy': cleanAdminId,
        'resolvedAt': now,
        'updatedAt': now,
        'refundExecutionStatus': 'not_required',
      });
    });
  }

  // ==========================================================
  // DOCUMENT CONVERSION
  // ==========================================================

  FoodOrderDisputeModel _fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(
      document.data() ?? <String, dynamic>{},
    );

    data['disputeId'] =
        (data['disputeId']?.toString().trim().isNotEmpty ?? false)
        ? data['disputeId']
        : document.id;

    return FoodOrderDisputeModel.fromMap(data);
  }

  List<FoodOrderDisputeModel> _sortedDisputes(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final List<FoodOrderDisputeModel> disputes = snapshot.docs
        .map(_fromDocument)
        .toList();

    disputes.sort(
      (FoodOrderDisputeModel a, FoodOrderDisputeModel b) =>
          b.createdAt.compareTo(a.createdAt),
    );

    return disputes;
  }
}
