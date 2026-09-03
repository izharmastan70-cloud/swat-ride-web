// lib/food/restaurant_partner/services/restaurant_partner_settlement_service.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Restaurant Partner Settlement Firestore Service
//
// Production responsibilities:
// - Watch settlement history
// - Request settlements from available restaurant wallet balance
// - Reserve pending settlement amounts
// - Prevent duplicate/overlapping settlement requests
// - Approve/pay or reject settlements in Firestore transactions
// - Update restaurant wallet totals
// - Update admin payout summary
//
// Firestore collections:
// - food_restaurant_partners/{partnerId}
// - food_partner_settlements/{settlementId}
// - food_admin_settings/admin_wallet
//
// Real bank/payment-gateway payout is bypassed for now.
// Admin approval records the payout as paid in Firestore.
// =============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

class RestaurantPartnerSettlementService {
  RestaurantPartnerSettlementService({
    FirebaseFirestore? firestore,
  }) : _firestore =
            firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String partnersCollection =
      'food_restaurant_partners';

  static const String settlementsCollection =
      'food_partner_settlements';

  static const String adminSettingsCollection =
      'food_admin_settings';

  static const String adminWalletDocument =
      'admin_wallet';

  CollectionReference<Map<String, dynamic>>
      get _partnersRef =>
          _firestore.collection(partnersCollection);

  CollectionReference<Map<String, dynamic>>
      get _settlementsRef =>
          _firestore.collection(
            settlementsCollection,
          );

  DocumentReference<Map<String, dynamic>>
      get _adminWalletRef => _firestore
          .collection(adminSettingsCollection)
          .doc(adminWalletDocument);

  // ===========================================================
  // WATCH / LOAD
  // ===========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      watchSettlements(
    String partnerId,
  ) {
    _requireId(
      partnerId,
      message: 'Partner ID is required.',
    );

    return _settlementsRef
        .where(
          'partnerId',
          isEqualTo: partnerId.trim(),
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>
      watchPendingSettlements(
    String partnerId,
  ) {
    _requireId(
      partnerId,
      message: 'Partner ID is required.',
    );

    return _settlementsRef
        .where(
          'partnerId',
          isEqualTo: partnerId.trim(),
        )
        .where(
          'status',
          isEqualTo: 'pending',
        )
        .snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?>
      getSettlementById(
    String settlementId,
  ) async {
    if (settlementId.trim().isEmpty) {
      return null;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>>
          snapshot = await _settlementsRef
              .doc(settlementId.trim())
              .get();

      return snapshot.exists ? snapshot : null;
    } on FirebaseException catch (error) {
      throw RestaurantPartnerSettlementException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    }
  }

  // ===========================================================
  // REQUEST SETTLEMENT
  // ===========================================================

  Future<String> requestSettlement({
    required String partnerId,
    required double amount,
    String paymentMethod = 'manual',
    String accountTitle = '',
    String accountNumber = '',
    String bankName = '',
    String note = '',
  }) async {
    _requireId(
      partnerId,
      message: 'Partner ID is required.',
    );

    if (amount <= 0) {
      throw const RestaurantPartnerSettlementException(
        message:
            'Settlement amount must be greater than zero.',
      );
    }

    final String safePartnerId =
        partnerId.trim();

    final DocumentReference<Map<String, dynamic>>
        partnerDocument =
        _partnersRef.doc(safePartnerId);

    final DocumentReference<Map<String, dynamic>>
        settlementDocument =
        _settlementsRef.doc();

    try {
      await _firestore.runTransaction(
        (Transaction transaction) async {
          final DocumentSnapshot<Map<String, dynamic>>
              partnerSnapshot =
              await transaction.get(
            partnerDocument,
          );

          if (!partnerSnapshot.exists ||
              partnerSnapshot.data() == null) {
            throw const RestaurantPartnerSettlementException(
              message:
                  'Restaurant partner account was not found.',
            );
          }

          final Map<String, dynamic> partnerData =
              partnerSnapshot.data()!;

          final bool isApproved =
              _boolValue(
            partnerData['isApproved'],
          );

          final bool isBlocked =
              _boolValue(
            partnerData['isBlocked'],
          );

          final bool isActive =
              _boolValue(
            partnerData['isActive'],
          );

          if (!isApproved ||
              isBlocked ||
              !isActive) {
            throw const RestaurantPartnerSettlementException(
              message:
                  'Only an active approved restaurant can request settlement.',
            );
          }

          final double walletBalance =
              _doubleValue(
            partnerData['walletBalance'],
          );

          final double reservedAmount =
              _doubleValue(
            partnerData[
                'reservedSettlementAmount'],
          );

          final double availableBalance =
              walletBalance - reservedAmount;

          if (amount > availableBalance) {
            throw RestaurantPartnerSettlementException(
              message:
                  'Requested amount exceeds available balance of Rs. ${availableBalance.toStringAsFixed(0)}.',
            );
          }

          final DateTime now = DateTime.now();

          transaction.set(
            settlementDocument,
            <String, dynamic>{
              'settlementId':
                  settlementDocument.id,
              'partnerId': safePartnerId,
              'restaurantId':
                  _stringValue(
                partnerData['restaurantId'],
              ),
              'restaurantName':
                  _stringValue(
                partnerData['restaurantName'],
              ),
              'ownerName':
                  _stringValue(
                partnerData['ownerName'],
              ),
              'amount': amount,
              'status': 'pending',
              'paymentMethod':
                  paymentMethod.trim().isEmpty
                      ? 'manual'
                      : paymentMethod.trim(),
              'accountTitle':
                  accountTitle.trim(),
              'accountNumber':
                  accountNumber.trim(),
              'bankName': bankName.trim(),
              'partnerNote': note.trim(),
              'adminNote': '',
              'reference': '',
              'requestedAt':
                  now.toIso8601String(),
              'createdAt':
                  now.toIso8601String(),
              'updatedAt':
                  now.toIso8601String(),
              'approvedAt': null,
              'paidAt': null,
              'rejectedAt': null,
              'rejectedReason': '',
              'processedBy': '',
              'paymentGatewayBypassed': true,
            },
            SetOptions(merge: false),
          );

          transaction.set(
            partnerDocument,
            <String, dynamic>{
              'reservedSettlementAmount':
                  reservedAmount + amount,
              'pendingSettlementAmount':
                  _doubleValue(
                        partnerData[
                            'pendingSettlementAmount'],
                      ) +
                      amount,
              'updatedAt':
                  now.toIso8601String(),
            },
            SetOptions(merge: true),
          );
        },
      );

      return settlementDocument.id;
    } on RestaurantPartnerSettlementException {
      rethrow;
    } on FirebaseException catch (error) {
      throw RestaurantPartnerSettlementException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    } catch (error) {
      throw RestaurantPartnerSettlementException(
        message:
            'Unable to request restaurant settlement: $error',
      );
    }
  }

  // ===========================================================
  // ADMIN APPROVE / PAY
  // ===========================================================

  Future<void> approveSettlement(
    String settlementId, {
    String processedBy = '',
    String paymentReference = '',
    String adminNote = '',
  }) async {
    _requireId(
      settlementId,
      message: 'Settlement ID is required.',
    );

    final DocumentReference<Map<String, dynamic>>
        settlementDocument =
        _settlementsRef.doc(
      settlementId.trim(),
    );

    try {
      await _firestore.runTransaction(
        (Transaction transaction) async {
          final DocumentSnapshot<Map<String, dynamic>>
              settlementSnapshot =
              await transaction.get(
            settlementDocument,
          );

          if (!settlementSnapshot.exists ||
              settlementSnapshot.data() == null) {
            throw const RestaurantPartnerSettlementException(
              message:
                  'Restaurant settlement request was not found.',
            );
          }

          final Map<String, dynamic> settlementData =
              settlementSnapshot.data()!;

          final String currentStatus =
              _stringValue(
            settlementData['status'],
          ).toLowerCase();

          if (_isPaidStatus(currentStatus)) {
            return;
          }

          if (currentStatus == 'rejected') {
            throw const RestaurantPartnerSettlementException(
              message:
                  'A rejected settlement cannot be approved.',
            );
          }

          if (currentStatus != 'pending' &&
              currentStatus != 'approved' &&
              currentStatus != 'processing') {
            throw RestaurantPartnerSettlementException(
              message:
                  'Settlement cannot be paid from status "$currentStatus".',
            );
          }

          final String partnerId =
              _stringValue(
            settlementData['partnerId'],
          );

          if (partnerId.isEmpty) {
            throw const RestaurantPartnerSettlementException(
              message:
                  'Settlement partner ID is missing.',
            );
          }

          final double amount =
              _doubleValue(
            settlementData['amount'],
          );

          if (amount <= 0) {
            throw const RestaurantPartnerSettlementException(
              message:
                  'Settlement amount is invalid.',
            );
          }

          final DocumentReference<Map<String, dynamic>>
              partnerDocument =
              _partnersRef.doc(partnerId);

          final DocumentSnapshot<Map<String, dynamic>>
              partnerSnapshot =
              await transaction.get(
            partnerDocument,
          );

          if (!partnerSnapshot.exists ||
              partnerSnapshot.data() == null) {
            throw const RestaurantPartnerSettlementException(
              message:
                  'Restaurant partner account was not found.',
            );
          }

          final DocumentSnapshot<Map<String, dynamic>>
              adminWalletSnapshot =
              await transaction.get(
            _adminWalletRef,
          );

          final Map<String, dynamic> partnerData =
              partnerSnapshot.data()!;

          final Map<String, dynamic> adminData =
              adminWalletSnapshot.data() ??
                  const <String, dynamic>{};

          final double walletBalance =
              _doubleValue(
            partnerData['walletBalance'],
          );

          final double reservedAmount =
              _doubleValue(
            partnerData[
                'reservedSettlementAmount'],
          );

          final double pendingAmount =
              _doubleValue(
            partnerData[
                'pendingSettlementAmount'],
          );

          if (amount > walletBalance) {
            throw RestaurantPartnerSettlementException(
              message:
                  'Restaurant wallet balance is only Rs. ${walletBalance.toStringAsFixed(0)}.',
            );
          }

          final DateTime now = DateTime.now();

          transaction.set(
            settlementDocument,
            <String, dynamic>{
              'status': 'paid',
              'approvedAt':
                  now.toIso8601String(),
              'paidAt':
                  now.toIso8601String(),
              'processedBy':
                  processedBy.trim(),
              'reference':
                  paymentReference.trim(),
              'adminNote':
                  adminNote.trim(),
              'updatedAt':
                  now.toIso8601String(),
            },
            SetOptions(merge: true),
          );

          transaction.set(
            partnerDocument,
            <String, dynamic>{
              'walletBalance':
                  walletBalance - amount,
              'reservedSettlementAmount':
                  (reservedAmount - amount)
                      .clamp(0, double.infinity),
              'pendingSettlementAmount':
                  (pendingAmount - amount)
                      .clamp(0, double.infinity),
              'totalSettledAmount':
                  _doubleValue(
                        partnerData[
                            'totalSettledAmount'],
                      ) +
                      amount,
              'lastSettlementAt':
                  now.toIso8601String(),
              'updatedAt':
                  now.toIso8601String(),
            },
            SetOptions(merge: true),
          );

          transaction.set(
            _adminWalletRef,
            <String, dynamic>{
              'totalRestaurantPayouts':
                  _doubleValue(
                        adminData[
                            'totalRestaurantPayouts'],
                      ) +
                      amount,
              'lastRestaurantPayoutAt':
                  now.toIso8601String(),
              'updatedAt':
                  now.toIso8601String(),
            },
            SetOptions(merge: true),
          );
        },
      );
    } on RestaurantPartnerSettlementException {
      rethrow;
    } on FirebaseException catch (error) {
      throw RestaurantPartnerSettlementException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    } catch (error) {
      throw RestaurantPartnerSettlementException(
        message:
            'Unable to approve restaurant settlement: $error',
      );
    }
  }

  // ===========================================================
  // ADMIN REJECT
  // ===========================================================

  Future<void> rejectSettlement(
    String settlementId, {
    String reason = '',
    String processedBy = '',
  }) async {
    _requireId(
      settlementId,
      message: 'Settlement ID is required.',
    );

    if (reason.trim().isEmpty) {
      throw const RestaurantPartnerSettlementException(
        message: 'Rejection reason is required.',
      );
    }

    final DocumentReference<Map<String, dynamic>>
        settlementDocument =
        _settlementsRef.doc(
      settlementId.trim(),
    );

    try {
      await _firestore.runTransaction(
        (Transaction transaction) async {
          final DocumentSnapshot<Map<String, dynamic>>
              settlementSnapshot =
              await transaction.get(
            settlementDocument,
          );

          if (!settlementSnapshot.exists ||
              settlementSnapshot.data() == null) {
            throw const RestaurantPartnerSettlementException(
              message:
                  'Restaurant settlement request was not found.',
            );
          }

          final Map<String, dynamic> settlementData =
              settlementSnapshot.data()!;

          final String status =
              _stringValue(
            settlementData['status'],
          ).toLowerCase();

          if (status == 'rejected') {
            return;
          }

          if (_isPaidStatus(status)) {
            throw const RestaurantPartnerSettlementException(
              message:
                  'A paid settlement cannot be rejected.',
            );
          }

          final String partnerId =
              _stringValue(
            settlementData['partnerId'],
          );

          final double amount =
              _doubleValue(
            settlementData['amount'],
          );

          if (partnerId.isEmpty ||
              amount <= 0) {
            throw const RestaurantPartnerSettlementException(
              message:
                  'Settlement partner or amount is invalid.',
            );
          }

          final DocumentReference<Map<String, dynamic>>
              partnerDocument =
              _partnersRef.doc(partnerId);

          final DocumentSnapshot<Map<String, dynamic>>
              partnerSnapshot =
              await transaction.get(
            partnerDocument,
          );

          final Map<String, dynamic> partnerData =
              partnerSnapshot.data() ??
                  const <String, dynamic>{};

          final double reservedAmount =
              _doubleValue(
            partnerData[
                'reservedSettlementAmount'],
          );

          final double pendingAmount =
              _doubleValue(
            partnerData[
                'pendingSettlementAmount'],
          );

          final DateTime now = DateTime.now();

          transaction.set(
            settlementDocument,
            <String, dynamic>{
              'status': 'rejected',
              'rejectedReason':
                  reason.trim(),
              'reason': reason.trim(),
              'processedBy':
                  processedBy.trim(),
              'rejectedAt':
                  now.toIso8601String(),
              'updatedAt':
                  now.toIso8601String(),
            },
            SetOptions(merge: true),
          );

          if (partnerSnapshot.exists) {
            transaction.set(
              partnerDocument,
              <String, dynamic>{
                'reservedSettlementAmount':
                    (reservedAmount - amount)
                        .clamp(0, double.infinity),
                'pendingSettlementAmount':
                    (pendingAmount - amount)
                        .clamp(0, double.infinity),
                'updatedAt':
                    now.toIso8601String(),
              },
              SetOptions(merge: true),
            );
          }
        },
      );
    } on RestaurantPartnerSettlementException {
      rethrow;
    } on FirebaseException catch (error) {
      throw RestaurantPartnerSettlementException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    } catch (error) {
      throw RestaurantPartnerSettlementException(
        message:
            'Unable to reject restaurant settlement: $error',
      );
    }
  }

  // ===========================================================
  // TOTALS
  // ===========================================================

  Future<double> pendingAmount(
    String partnerId,
  ) async {
    return _sumByStatuses(
      partnerId: partnerId,
      statuses: const <String>[
        'pending',
        'processing',
        'approved',
      ],
    );
  }

  Future<double> paidAmount(
    String partnerId,
  ) async {
    return _sumByStatuses(
      partnerId: partnerId,
      statuses: const <String>[
        'paid',
        'completed',
        'settled',
      ],
    );
  }

  Future<double> rejectedAmount(
    String partnerId,
  ) async {
    return _sumByStatuses(
      partnerId: partnerId,
      statuses: const <String>[
        'rejected',
      ],
    );
  }

  Future<double> _sumByStatuses({
    required String partnerId,
    required List<String> statuses,
  }) async {
    _requireId(
      partnerId,
      message: 'Partner ID is required.',
    );

    try {
      final QuerySnapshot<Map<String, dynamic>>
          snapshot = await _settlementsRef
              .where(
                'partnerId',
                isEqualTo: partnerId.trim(),
              )
              .where(
                'status',
                whereIn: statuses,
              )
              .get();

      return snapshot.docs.fold<double>(
        0,
        (
          double total,
          QueryDocumentSnapshot<
                  Map<String, dynamic>>
              document,
        ) =>
            total +
            _doubleValue(
              document.data()['amount'],
            ),
      );
    } on FirebaseException catch (error) {
      throw RestaurantPartnerSettlementException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    }
  }

  // ===========================================================
  // CALCULATION HELPERS
  // ===========================================================

  double calculateCommission({
    required double grossAmount,
    required double commissionPercentage,
  }) {
    final double safeGross =
        grossAmount < 0 ? 0 : grossAmount;

    final double safeRate =
        commissionPercentage
            .clamp(0, 100)
            .toDouble();

    return safeGross * (safeRate / 100);
  }

  double netAmount({
    required double grossAmount,
    required double commissionPercentage,
  }) {
    final double safeGross =
        grossAmount < 0 ? 0 : grossAmount;

    return safeGross -
        calculateCommission(
          grossAmount: safeGross,
          commissionPercentage:
              commissionPercentage,
        );
  }

  // ===========================================================
  // INTERNAL
  // ===========================================================

  static bool _isPaidStatus(
    String value,
  ) {
    final String normalized =
        value.trim().toLowerCase();

    return normalized == 'paid' ||
        normalized == 'completed' ||
        normalized == 'settled';
  }

  static void _requireId(
    String value, {
    required String message,
  }) {
    if (value.trim().isEmpty) {
      throw RestaurantPartnerSettlementException(
        message: message,
      );
    }
  }

  static String _stringValue(
    dynamic value,
  ) {
    return value?.toString().trim() ?? '';
  }

  static double _doubleValue(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  static bool _boolValue(
    dynamic value,
  ) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final String normalized =
        value?.toString().trim().toLowerCase() ??
            '';

    return normalized == 'true' ||
        normalized == '1' ||
        normalized == 'yes';
  }

  String _firebaseMessage(
    FirebaseException error,
  ) {
    switch (error.code) {
      case 'permission-denied':
        return 'You do not have permission to perform this restaurant settlement action.';
      case 'unavailable':
        return 'Firebase is temporarily unavailable. Please try again.';
      case 'not-found':
        return 'The requested restaurant settlement was not found.';
      case 'failed-precondition':
        return 'Firebase requires an index or another condition before this settlement action can run.';
      case 'aborted':
        return 'The settlement transaction was interrupted. Please try again.';
      default:
        return error.message ??
            'A Firebase error occurred (${error.code}).';
    }
  }
}

class RestaurantPartnerSettlementException
    implements Exception {
  const RestaurantPartnerSettlementException({
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

    return 'RestaurantPartnerSettlementException($code): $message';
  }
}
