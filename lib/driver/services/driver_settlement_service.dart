import 'package:cloud_firestore/cloud_firestore.dart';

class DriverSettlementService {
  DriverSettlementService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // =========================================================
  // TESTING / PRODUCTION SWITCH
  // =========================================================
  // true:
  //   Withdrawal request Firestore mein pending status ke saath
  //   create hogi. Real bank/wallet payout execute nahi hoga.
  // false:
  //   Production backend/admin payout flow required hoga.
  // =========================================================

  static const bool testingSettlementBypassEnabled = false;
  static const double minimumWithdrawalAmount = 500;

  CollectionReference<Map<String, dynamic>> get _drivers =>
      _firestore.collection('drivers');

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection('driver_withdrawal_requests');

  // =========================================================
  // WATCH DRIVER SETTLEMENT SUMMARY
  // =========================================================

  Stream<DriverSettlementSummary> watchSettlementSummary(
    String driverId,
  ) {
    final String id = driverId.trim();
    if (id.isEmpty) {
      return Stream<DriverSettlementSummary>.value(
        const DriverSettlementSummary.empty(),
      );
    }

    return _drivers.doc(id).snapshots().map((snapshot) {
      final Map<String, dynamic> data =
          snapshot.data() ?? <String, dynamic>{};
      return DriverSettlementSummary.fromMap(data);
    });
  }

  // =========================================================
  // WATCH WITHDRAWAL REQUESTS
  // =========================================================

  Stream<List<DriverWithdrawalRequest>> watchRequests(
    String driverId,
  ) {
    final String id = driverId.trim();
    if (id.isEmpty) {
      return Stream<List<DriverWithdrawalRequest>>.value(
        const <DriverWithdrawalRequest>[],
      );
    }

    return _requests
        .where('driverId', isEqualTo: id)
        .snapshots()
        .map((snapshot) {
      final List<DriverWithdrawalRequest> items = snapshot.docs
          .map(DriverWithdrawalRequest.fromDocument)
          .toList()
        ..sort((first, second) =>
            second.createdAt.compareTo(first.createdAt));
      return items;
    });
  }

  // =========================================================
  // CREATE WITHDRAWAL REQUEST
  // =========================================================

  Future<String> requestWithdrawal({
    required String driverId,
    required String driverName,
    required double amount,
    required DriverPayoutMethod payoutMethod,
    required String accountTitle,
    required String accountNumber,
    String? bankName,
  }) async {
    final String id = driverId.trim();
    final String name = driverName.trim();
    final String title = accountTitle.trim();
    final String number = accountNumber.trim();
    final String normalizedBank = bankName?.trim() ?? '';

    if (id.isEmpty) throw Exception('Driver ID is required.');
    if (name.isEmpty) throw Exception('Driver name is required.');
    if (amount < minimumWithdrawalAmount) {
      throw Exception(
        'Minimum withdrawal is Rs ${minimumWithdrawalAmount.toStringAsFixed(0)}.',
      );
    }
    if (title.length < 3) {
      throw Exception('Enter a valid account title.');
    }
    if (number.length < 8) {
      throw Exception('Enter a valid account or mobile number.');
    }
    if (payoutMethod == DriverPayoutMethod.bank &&
        normalizedBank.isEmpty) {
      throw Exception('Please select or enter bank name.');
    }

    final DocumentReference<Map<String, dynamic>> driverReference =
        _drivers.doc(id);
    final DocumentReference<Map<String, dynamic>> requestReference =
        _requests.doc();

    await _firestore.runTransaction((transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> driverSnapshot =
          await transaction.get(driverReference);
      if (!driverSnapshot.exists) {
        throw Exception('Driver account was not found.');
      }

      final DriverSettlementSummary summary =
          DriverSettlementSummary.fromMap(driverSnapshot.data()!);
      if (summary.pendingWithdrawalAmount > 0) {
        throw Exception(
          'You already have a pending withdrawal request.',
        );
      }
      if (summary.outstandingCommission > 0) {
        throw Exception(
          'Please settle your cash commission before withdrawal.',
        );
      }
      if (amount > summary.availableBalance) {
        throw Exception('Insufficient available earnings.');
      }

      transaction.set(requestReference, <String, dynamic>{
        'requestId': requestReference.id,
        'driverId': id,
        'driverName': name,
        'amount': amount,
        'payoutMethod': payoutMethod.name,
        'accountTitle': title,
        'accountNumber': number,
        'bankName': normalizedBank.isEmpty ? null : normalizedBank,
        'status': DriverWithdrawalStatus.pending.name,
        'adminNote': null,
        'testingBypassActive': testingSettlementBypassEnabled,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.set(
        driverReference,
        <String, dynamic>{
          'pendingWithdrawalAmount': amount,
          'lastWithdrawalRequestId': requestReference.id,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });

    // =======================================================
    // REAL PAYOUT CODE - PRODUCTION BACKEND ONLY
    // =======================================================
    // Never place JazzCash/Easypaisa/Bank secret keys in Flutter.
    // Production flow:
    // 1. Admin approves this pending request.
    // 2. Secure backend rechecks balance and commission.
    // 3. Backend calls the selected payout provider.
    // 4. Provider webhook verifies success/failure.
    // 5. Firestore transaction updates request and Driver totals.
    // =======================================================

    return requestReference.id;
  }

  // =========================================================
  // CANCEL OWN PENDING REQUEST
  // =========================================================

  Future<void> cancelPendingRequest({
    required String requestId,
    required String driverId,
  }) async {
    final String normalizedRequestId = requestId.trim();
    final String normalizedDriverId = driverId.trim();
    if (normalizedRequestId.isEmpty || normalizedDriverId.isEmpty) {
      throw Exception('Request and Driver are required.');
    }

    final DocumentReference<Map<String, dynamic>> requestReference =
        _requests.doc(normalizedRequestId);
    final DocumentReference<Map<String, dynamic>> driverReference =
        _drivers.doc(normalizedDriverId);

    await _firestore.runTransaction((transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> requestSnapshot =
          await transaction.get(requestReference);
      if (!requestSnapshot.exists) {
        throw Exception('Withdrawal request was not found.');
      }
      final Map<String, dynamic> data = requestSnapshot.data()!;
      if (data['driverId'] != normalizedDriverId) {
        throw Exception('This request does not belong to this Driver.');
      }
      if (data['status'] != DriverWithdrawalStatus.pending.name) {
        throw Exception('Only a pending request can be cancelled.');
      }

      transaction.update(requestReference, <String, dynamic>{
        'status': DriverWithdrawalStatus.cancelled.name,
        'cancelledBy': 'driver',
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(
        driverReference,
        <String, dynamic>{
          'pendingWithdrawalAmount': 0,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }
}

enum DriverPayoutMethod {
  jazzCash,
  easypaisa,
  bank,
}

enum DriverWithdrawalStatus {
  pending,
  approved,
  processing,
  paid,
  rejected,
  failed,
  cancelled,
}

class DriverSettlementSummary {
  const DriverSettlementSummary({
    required this.walletBalance,
    required this.lifetimeNetEarnings,
    required this.totalWithdrawn,
    required this.pendingWithdrawalAmount,
    required this.outstandingCommission,
  });

  const DriverSettlementSummary.empty()
      : walletBalance = 0,
        lifetimeNetEarnings = 0,
        totalWithdrawn = 0,
        pendingWithdrawalAmount = 0,
        outstandingCommission = 0;

  final double walletBalance;
  final double lifetimeNetEarnings;
  final double totalWithdrawn;
  final double pendingWithdrawalAmount;
  final double outstandingCommission;

  double get availableBalance {
    // walletBalance is already the real withdrawable Driver balance.
    // Cash commission is deducted from it during ride completion and
    // digital rides credit only the net Driver earning.
    final double value = walletBalance - pendingWithdrawalAmount;
    return value < 0 ? 0 : value;
  }

  factory DriverSettlementSummary.fromMap(Map<String, dynamic> map) {
    return DriverSettlementSummary(
      walletBalance:
          (map['walletBalance'] as num?)?.toDouble() ?? 0,
      lifetimeNetEarnings:
          (map['lifetimeNetEarnings'] as num?)?.toDouble() ?? 0,
      totalWithdrawn:
          (map['totalWithdrawn'] as num?)?.toDouble() ?? 0,
      pendingWithdrawalAmount:
          (map['pendingWithdrawalAmount'] as num?)?.toDouble() ?? 0,
      outstandingCommission:
          (map['outstandingCommission'] as num?)?.toDouble() ?? 0,
    );
  }
}

class DriverWithdrawalRequest {
  const DriverWithdrawalRequest({
    required this.requestId,
    required this.amount,
    required this.payoutMethod,
    required this.accountTitle,
    required this.accountNumber,
    required this.bankName,
    required this.status,
    required this.adminNote,
    required this.createdAt,
  });

  final String requestId;
  final double amount;
  final DriverPayoutMethod payoutMethod;
  final String accountTitle;
  final String accountNumber;
  final String? bankName;
  final DriverWithdrawalStatus status;
  final String? adminNote;
  final DateTime createdAt;

  factory DriverWithdrawalRequest.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final Map<String, dynamic> data = document.data();
    return DriverWithdrawalRequest(
      requestId: data['requestId'] as String? ?? document.id,
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      payoutMethod: _payoutMethod(data['payoutMethod']),
      accountTitle: data['accountTitle'] as String? ?? '',
      accountNumber: data['accountNumber'] as String? ?? '',
      bankName: data['bankName'] as String?,
      status: _status(data['status']),
      adminNote: data['adminNote'] as String?,
      createdAt: _date(data['createdAt']) ?? DateTime.now(),
    );
  }

  static DriverPayoutMethod _payoutMethod(dynamic value) {
    return DriverPayoutMethod.values.firstWhere(
      (item) => item.name == value,
      orElse: () => DriverPayoutMethod.jazzCash,
    );
  }

  static DriverWithdrawalStatus _status(dynamic value) {
    return DriverWithdrawalStatus.values.firstWhere(
      (item) => item.name == value,
      orElse: () => DriverWithdrawalStatus.pending,
    );
  }

  static DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
