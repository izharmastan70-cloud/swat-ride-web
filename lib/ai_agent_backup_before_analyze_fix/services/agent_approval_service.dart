import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/agent_approval_request.dart';

// =========================================================
// AI AGENT — APPROVAL SERVICE
// =========================================================
//
// Firestore collection: agent_approvals
//
// One approval = one action only.
// Approval can be consumed exactly once.
// Expired/rejected/cancelled/consumed approvals can never execute.
// This phase does not execute business tools; it only manages approval
// lifecycle safely.

class AgentApprovalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _collectionPath = 'agent_approvals';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(_collectionPath);

  Future<AgentApprovalRequest> createRequest({
    required String roleId,
    required String actionId,
    required String module,
    required String reason,
    required String risk,
    required String requestedBy,
    required Map<String, dynamic> actionScope,
    Duration validity = const Duration(minutes: 15),
  }) async {
    final DateTime now = DateTime.now();
    final DocumentReference<Map<String, dynamic>> doc = _collection.doc();

    final AgentApprovalRequest request = AgentApprovalRequest(
      approvalId: doc.id,
      roleId: roleId,
      actionId: actionId,
      module: module,
      reason: reason,
      risk: risk,
      requestedBy: requestedBy,
      actionScope: Map<String, dynamic>.from(actionScope),
      status: AgentApprovalStatus.pending,
      createdAt: now,
      expiresAt: now.add(validity),
    );

    request.validate();
    await doc.set(request.toMap());
    return request;
  }

  Future<AgentApprovalRequest?> getRequest(String approvalId) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _collection.doc(approvalId).get();

    if (!snapshot.exists) return null;

    final AgentApprovalRequest request =
        AgentApprovalRequest.fromSnapshot(snapshot);

    request.validate();

    if (request.isPending && request.isExpiredNow) {
      await _expireIfStillPending(approvalId);
      final DocumentSnapshot<Map<String, dynamic>> refreshed =
          await _collection.doc(approvalId).get();

      if (!refreshed.exists) return null;
      final AgentApprovalRequest expired =
          AgentApprovalRequest.fromSnapshot(refreshed);
      expired.validate();
      return expired;
    }

    return request;
  }

  Stream<List<AgentApprovalRequest>> watchPendingRequests() {
    return _collection
        .where('status', isEqualTo: AgentApprovalStatus.pending)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
      (QuerySnapshot<Map<String, dynamic>> snapshot) {
        return snapshot.docs
            .map(
              (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                  AgentApprovalRequest.fromSnapshot(doc),
            )
            .where((AgentApprovalRequest item) => !item.isExpiredNow)
            .toList(growable: false);
      },
    );
  }

  Future<void> approve({
    required String approvalId,
    required String decidedBy,
    String? note,
  }) async {
    final DocumentReference<Map<String, dynamic>> ref =
        _collection.doc(approvalId);

    await _firestore.runTransaction((Transaction transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await transaction.get(ref);

      if (!snapshot.exists) {
        throw Exception('Approval "$approvalId" not found.');
      }

      final AgentApprovalRequest request =
          AgentApprovalRequest.fromSnapshot(snapshot);
      request.validate();

      if (!request.isPending) {
        throw AgentApprovalValidationException(
          'Only PENDING approvals can be approved. '
          'Current status: ${request.status}.',
        );
      }

      if (request.isExpiredNow) {
        transaction.update(ref, <String, dynamic>{
          'status': AgentApprovalStatus.expired,
          'decidedAt': FieldValue.serverTimestamp(),
          'decidedBy': decidedBy,
          'decisionNote': 'Expired before approval.',
        });

        throw const AgentApprovalValidationException(
          'Approval expired before it could be approved.',
        );
      }

      transaction.update(ref, <String, dynamic>{
        'status': AgentApprovalStatus.approved,
        'decidedAt': FieldValue.serverTimestamp(),
        'decidedBy': decidedBy,
        'decisionNote': note,
      });
    });
  }

  Future<void> reject({
    required String approvalId,
    required String decidedBy,
    String? note,
  }) async {
    final DocumentReference<Map<String, dynamic>> ref =
        _collection.doc(approvalId);

    await _firestore.runTransaction((Transaction transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await transaction.get(ref);

      if (!snapshot.exists) {
        throw Exception('Approval "$approvalId" not found.');
      }

      final AgentApprovalRequest request =
          AgentApprovalRequest.fromSnapshot(snapshot);
      request.validate();

      if (!request.isPending) {
        throw AgentApprovalValidationException(
          'Only PENDING approvals can be rejected. '
          'Current status: ${request.status}.',
        );
      }

      transaction.update(ref, <String, dynamic>{
        'status': AgentApprovalStatus.rejected,
        'decidedAt': FieldValue.serverTimestamp(),
        'decidedBy': decidedBy,
        'decisionNote': note,
      });
    });
  }

  Future<void> cancelRequest({
    required String approvalId,
    required String cancelledBy,
    String? note,
  }) async {
    final DocumentReference<Map<String, dynamic>> ref =
        _collection.doc(approvalId);

    await _firestore.runTransaction((Transaction transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await transaction.get(ref);

      if (!snapshot.exists) {
        throw Exception('Approval "$approvalId" not found.');
      }

      final AgentApprovalRequest request =
          AgentApprovalRequest.fromSnapshot(snapshot);
      request.validate();

      if (!request.isPending) {
        throw AgentApprovalValidationException(
          'Only PENDING approvals can be cancelled. '
          'Current status: ${request.status}.',
        );
      }

      transaction.update(ref, <String, dynamic>{
        'status': AgentApprovalStatus.cancelled,
        'decidedAt': FieldValue.serverTimestamp(),
        'decidedBy': cancelledBy,
        'decisionNote': note,
      });
    });
  }

  /// Atomically consumes an APPROVED request.
  ///
  /// The caller must provide the same role/action/module/scope that the
  /// owner approved. Any mismatch denies execution.
  ///
  /// Returns the consumed approval if successful.
  Future<AgentApprovalRequest> consumeApprovedRequest({
    required String approvalId,
    required String expectedRoleId,
    required String expectedActionId,
    required String expectedModule,
    required Map<String, dynamic> expectedActionScope,
  }) async {
    final DocumentReference<Map<String, dynamic>> ref =
        _collection.doc(approvalId);

    return _firestore.runTransaction<AgentApprovalRequest>(
      (Transaction transaction) async {
        final DocumentSnapshot<Map<String, dynamic>> snapshot =
            await transaction.get(ref);

        if (!snapshot.exists) {
          throw Exception('Approval "$approvalId" not found.');
        }

        final AgentApprovalRequest request =
            AgentApprovalRequest.fromSnapshot(snapshot);
        request.validate();

        if (!request.isApproved) {
          throw AgentApprovalValidationException(
            'Approval is not APPROVED. Current status: ${request.status}.',
          );
        }

        if (request.isExpiredNow) {
          transaction.update(ref, <String, dynamic>{
            'status': AgentApprovalStatus.expired,
            'consumedAt': FieldValue.serverTimestamp(),
          });
          throw const AgentApprovalValidationException(
            'Approved request expired before use.',
          );
        }

        if (request.consumedAt != null || request.isConsumed) {
          throw const AgentApprovalValidationException(
            'Approval has already been consumed.',
          );
        }

        if (request.roleId != expectedRoleId ||
            request.actionId != expectedActionId ||
            request.module != expectedModule ||
            !_deepMapEquals(request.actionScope, expectedActionScope)) {
          throw const AgentApprovalValidationException(
            'Approval scope does not match the requested action. '
            'A new approval is required.',
          );
        }

        transaction.update(ref, <String, dynamic>{
          'status': AgentApprovalStatus.consumed,
          'consumedAt': FieldValue.serverTimestamp(),
        });

        return request.copyWith(
          status: AgentApprovalStatus.consumed,
          consumedAt: DateTime.now(),
        );
      },
    );
  }

  Future<void> _expireIfStillPending(String approvalId) async {
    final DocumentReference<Map<String, dynamic>> ref =
        _collection.doc(approvalId);

    await _firestore.runTransaction((Transaction transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await transaction.get(ref);

      if (!snapshot.exists) return;

      final AgentApprovalRequest request =
          AgentApprovalRequest.fromSnapshot(snapshot);

      if (request.isPending && request.isExpiredNow) {
        transaction.update(ref, <String, dynamic>{
          'status': AgentApprovalStatus.expired,
          'decidedAt': FieldValue.serverTimestamp(),
          'decisionNote': 'Expired automatically.',
        });
      }
    });
  }

  static bool _deepMapEquals(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    if (a.length != b.length) return false;

    for (final String key in a.keys) {
      if (!b.containsKey(key)) return false;
      if (!_deepEquals(a[key], b[key])) return false;
    }

    return true;
  }

  static bool _deepEquals(dynamic a, dynamic b) {
    if (a is Map && b is Map) {
      final Map<String, dynamic> mapA = a.map(
        (dynamic key, dynamic value) =>
            MapEntry<String, dynamic>(key.toString(), value),
      );
      final Map<String, dynamic> mapB = b.map(
        (dynamic key, dynamic value) =>
            MapEntry<String, dynamic>(key.toString(), value),
      );
      return _deepMapEquals(mapA, mapB);
    }

    if (a is Iterable && b is Iterable) {
      final List<dynamic> listA = a.toList(growable: false);
      final List<dynamic> listB = b.toList(growable: false);

      if (listA.length != listB.length) return false;

      for (int i = 0; i < listA.length; i++) {
        if (!_deepEquals(listA[i], listB[i])) return false;
      }

      return true;
    }

    return a == b;
  }
}
