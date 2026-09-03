import 'package:cloud_firestore/cloud_firestore.dart';

class RideCommissionSettlementService {
  static const double highValueAdjustmentThreshold = 10000;
  RideCommissionSettlementService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _drivers =>
      _firestore.collection('drivers');

  CollectionReference<Map<String, dynamic>> get _settlements =>
      _firestore.collection('normal_ride_commission_settlements');

  DocumentReference<Map<String, dynamic>> get _adminWallet =>
      _firestore.collection('admin_wallets').doc('normal_ride');

  Stream<QuerySnapshot<Map<String, dynamic>>> watchSettlements({
    int limit = 200,
  }) {
    return _settlements
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchDriver(String driverId) {
    final id = driverId.trim();

    if (id.isEmpty) {
      throw ArgumentError('Driver ID is required.');
    }

    return _drivers.doc(id).snapshots();
  }

  Future<String> settleOutstandingCommission({
    required String driverId,
    required double amount,
    required String adminId,
    String adminName = '',
    required String reason,
    String? reference,
    String? idempotencyKey,
  }) async {
    final normalizedDriverId = driverId.trim();
    final normalizedAdminId = adminId.trim();
    final normalizedAdminName = adminName.trim();
    final normalizedReason = reason.trim();
    final normalizedReference = reference?.trim();
    final normalizedKey = idempotencyKey?.trim();

    if (normalizedDriverId.isEmpty) {
      throw ArgumentError('Driver ID is required.');
    }

    if (normalizedAdminId.isEmpty) {
      throw ArgumentError('Admin ID is required.');
    }

    if (!amount.isFinite || amount <= 0) {
      throw ArgumentError('Settlement amount must be greater than zero.');
    }

    if (normalizedReason.length < 5) {
      throw ArgumentError(
        'A clear settlement reason of at least 5 characters is required.',
      );
    }

    final settlementRef = normalizedKey != null && normalizedKey.isNotEmpty
        ? _settlements.doc(normalizedKey)
        : _settlements.doc();

    final driverRef = _drivers.doc(normalizedDriverId);

    await _firestore.runTransaction((transaction) async {
      final settlementSnapshot = await transaction.get(settlementRef);

      if (settlementSnapshot.exists) {
        throw StateError('This settlement request has already been processed.');
      }

      final driverSnapshot = await transaction.get(driverRef);

      if (!driverSnapshot.exists || driverSnapshot.data() == null) {
        throw StateError('Driver was not found.');
      }

      final driverData = driverSnapshot.data()!;

      final walletBefore =
          (driverData['walletBalance'] as num?)?.toDouble() ?? 0;

      final outstandingBefore =
          (driverData['outstandingCommission'] as num?)?.toDouble() ?? 0;

      final totalCommissionPaidBefore =
          (driverData['totalCommissionPaid'] as num?)?.toDouble() ?? 0;

      if (outstandingBefore <= 0) {
        throw StateError('This Driver has no outstanding commission.');
      }

      if (amount > outstandingBefore) {
        throw StateError(
          'Settlement amount cannot exceed outstanding commission.',
        );
      }

      if (amount > walletBefore) {
        throw StateError(
          'Driver Wallet does not have enough balance for this settlement.',
        );
      }

      final walletAfter = walletBefore - amount;
      final outstandingAfter = outstandingBefore - amount;

      transaction.update(driverRef, <String, dynamic>{
        'walletBalance': walletAfter,
        'outstandingCommission': outstandingAfter,
        'totalCommissionPaid': totalCommissionPaidBefore + amount,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final adminWalletSnapshot = await transaction.get(_adminWallet);
      final adminWalletData = adminWalletSnapshot.data() ?? <String, dynamic>{};

      final adminBalanceBefore =
          (adminWalletData['walletBalance'] as num?)?.toDouble() ?? 0;

      final commissionReceivedBefore =
          (adminWalletData['totalCommissionReceived'] as num?)?.toDouble() ?? 0;

      final outstandingReceivableBefore =
          (adminWalletData['totalOutstandingReceivable'] as num?)?.toDouble() ??
          0;

      final outstandingReceivableAfter = (outstandingReceivableBefore - amount)
          .clamp(0, double.infinity);

      transaction.set(_adminWallet, <String, dynamic>{
        'walletBalance': adminBalanceBefore + amount,
        'totalCommissionReceived': commissionReceivedBefore + amount,
        'totalOutstandingReceivable': outstandingReceivableAfter,
        'lastTransactionAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.set(settlementRef, <String, dynamic>{
        'settlementId': settlementRef.id,
        'serviceType': 'normal_ride',
        'type': 'outstanding_commission_settlement',
        'driverId': normalizedDriverId,
        'amount': amount,
        'reason': normalizedReason,
        'reference': normalizedReference,
        'adminId': normalizedAdminId,
        'adminName': normalizedAdminName,
        'walletAfter': walletAfter,
        'outstandingBefore': outstandingBefore,
        'outstandingAfter': outstandingAfter,
        'status': 'completed',
        'idempotencyKey': normalizedKey != null && normalizedKey.isNotEmpty
            ? normalizedKey
            : settlementRef.id,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    return settlementRef.id;
  }

  Future<String> recordManualAdjustment({
    required String driverId,
    required double amount,
    required bool isCredit,
    required String adminId,
    String adminName = '',
    required String reason,
    String? reference,
    String? idempotencyKey,
    String? superAdminApprovedBy,
  }) async {
    final normalizedDriverId = driverId.trim();
    final normalizedAdminId = adminId.trim();
    final normalizedAdminName = adminName.trim();
    final normalizedReason = reason.trim();
    final normalizedReference = reference?.trim();
    final normalizedKey = idempotencyKey?.trim();
    final normalizedSuperAdmin = superAdminApprovedBy?.trim() ?? '';

    if (normalizedDriverId.isEmpty) {
      throw ArgumentError('Driver ID is required.');
    }

    if (normalizedAdminId.isEmpty) {
      throw ArgumentError('Admin ID is required.');
    }

    if (!amount.isFinite || amount <= 0) {
      throw ArgumentError('Adjustment amount must be greater than zero.');
    }

    if (normalizedReason.length < 5) {
      throw ArgumentError(
        'A clear adjustment reason of at least 5 characters is required.',
      );
    }

    if (normalizedReference == null || normalizedReference.isEmpty) {
      throw ArgumentError('A unique adjustment reference is required.');
    }

    final bool highValueAdjustment = amount >= highValueAdjustmentThreshold;

    if (highValueAdjustment && normalizedSuperAdmin.isEmpty) {
      throw StateError(
        'High-value wallet adjustment requires Super Admin authorization.',
      );
    }

    final String automaticKey =
        'wallet_adjustment_'
        '${normalizedDriverId}_'
        '${isCredit ? 'credit' : 'debit'}_'
        '${_safeDocumentKey(normalizedReference)}';

    final String effectiveKey =
        normalizedKey != null && normalizedKey.isNotEmpty
        ? normalizedKey
        : automaticKey;

    final adjustmentRef = _settlements.doc(effectiveKey);

    final driverRef = _drivers.doc(normalizedDriverId);

    await _firestore.runTransaction((transaction) async {
      final existingAdjustment = await transaction.get(adjustmentRef);

      if (existingAdjustment.exists) {
        throw StateError('This adjustment request has already been processed.');
      }

      final driverSnapshot = await transaction.get(driverRef);

      if (!driverSnapshot.exists || driverSnapshot.data() == null) {
        throw StateError('Driver was not found.');
      }

      final driverData = driverSnapshot.data()!;

      final walletBefore =
          (driverData['walletBalance'] as num?)?.toDouble() ?? 0;

      final walletAfter = isCredit
          ? walletBefore + amount
          : walletBefore - amount;

      if (walletAfter < 0) {
        throw StateError(
          'Debit adjustment cannot make Driver Wallet negative.',
        );
      }

      transaction.update(driverRef, <String, dynamic>{
        'walletBalance': walletAfter,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.set(adjustmentRef, <String, dynamic>{
        'settlementId': adjustmentRef.id,
        'serviceType': 'normal_ride',
        'type': 'manual_wallet_adjustment',
        'adjustmentType': isCredit ? 'credit' : 'debit',
        'driverId': normalizedDriverId,
        'amount': amount,
        'reason': normalizedReason,
        'reference': normalizedReference,
        'adminId': normalizedAdminId,
        'adminName': normalizedAdminName,
        'highValueAdjustment': highValueAdjustment,
        'highValueThreshold': highValueAdjustmentThreshold,
        'superAdminApprovedBy': highValueAdjustment ? normalizedSuperAdmin : '',
        'walletBefore': walletBefore,
        'walletAfter': walletAfter,
        'status': 'completed',
        'idempotencyKey': effectiveKey,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    return adjustmentRef.id;
  }

  String _safeDocumentKey(String value) {
    final String cleaned = value.trim().replaceAll(
      RegExp(r'[^a-zA-Z0-9_-]'),
      '_',
    );

    if (cleaned.length <= 80) {
      return cleaned;
    }

    return cleaned.substring(0, 80);
  }
}
