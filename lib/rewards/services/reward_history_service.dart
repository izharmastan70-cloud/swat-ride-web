// =============================================================
// SWAT RIDE - GLOBAL LOYALTY, REWARDS & PROMO ENGINE
// File: lib/rewards/services/reward_history_service.dart
//
// Global reward history for:
// Ride, Driver, Student Ride, Food, Hotel, Tourism,
// Cargo, Parcel, Wallet and future SWAT RIDE modules.
//
// Supports:
// - User reward history
// - Admin global history
// - Credit/debit filtering
// - Module/type/status/date filtering
// - Search and pagination
// - Reward summaries and Admin reports
// - Real Firestore and testing bypass
// =============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/reward_production_gate.dart';

import '../models/reward_point_model.dart';
import '../models/reward_transaction_model.dart';

class RewardHistoryFilter {
  final String? userId;
  final RewardModule? module;
  final RewardTransactionType? type;
  final RewardTransactionStatus? status;

  final bool? creditOnly;
  final bool? debitOnly;

  final DateTime? startDate;
  final DateTime? endDate;

  final String searchText;

  const RewardHistoryFilter({
    this.userId,
    this.module,
    this.type,
    this.status,
    this.creditOnly,
    this.debitOnly,
    this.startDate,
    this.endDate,
    this.searchText = '',
  });
}

class RewardHistoryPage {
  final List<RewardTransactionModel> transactions;

  /// Offset used to load the next page.
  final int? nextOffset;

  final bool hasMore;
  final int totalMatchingRecords;

  const RewardHistoryPage({
    required this.transactions,
    required this.nextOffset,
    required this.hasMore,
    required this.totalMatchingRecords,
  });
}

class RewardHistorySummary {
  final int totalRecords;

  final int totalEarnedPoints;
  final int totalRedeemedPoints;
  final int totalExpiredPoints;
  final int totalReversedPoints;

  final int totalCreditPoints;
  final int totalDebitPoints;

  final int pendingTransactions;
  final int completedTransactions;
  final int failedTransactions;

  final Map<RewardModule, int> pointsByModule;
  final Map<RewardTransactionType, int> pointsByType;

  const RewardHistorySummary({
    required this.totalRecords,
    required this.totalEarnedPoints,
    required this.totalRedeemedPoints,
    required this.totalExpiredPoints,
    required this.totalReversedPoints,
    required this.totalCreditPoints,
    required this.totalDebitPoints,
    required this.pendingTransactions,
    required this.completedTransactions,
    required this.failedTransactions,
    required this.pointsByModule,
    required this.pointsByType,
  });

  factory RewardHistorySummary.empty() {
    return const RewardHistorySummary(
      totalRecords: 0,
      totalEarnedPoints: 0,
      totalRedeemedPoints: 0,
      totalExpiredPoints: 0,
      totalReversedPoints: 0,
      totalCreditPoints: 0,
      totalDebitPoints: 0,
      pendingTransactions: 0,
      completedTransactions: 0,
      failedTransactions: 0,
      pointsByModule: {},
      pointsByType: {},
    );
  }
}

class RewardHistoryService {
  final FirebaseFirestore _firestore;

  /// Keep true during local/testing development.
  ///
  /// Change to false when real Firebase history is required.
  final bool useTestingBypass;

  final Map<String, RewardTransactionModel>
      _testingTransactions = {};

  RewardHistoryService({
    FirebaseFirestore? firestore,
    this.useTestingBypass = false,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>>
      get _transactionsCollection {
    return _firestore.collection('reward_transactions');
  }

  // =============================================================
  // STORE / FETCH SINGLE TRANSACTION
  // =============================================================

  Future<void> saveTransaction(
    RewardTransactionModel transaction,
  ) async {
    if (!RewardProductionGate.financialMutationsEnabled) {
      throw StateError(
        'Reward transaction mutations are disabled until the trusted backend is ready.',
      );
    }

    _validateTransaction(transaction);

    if (useTestingBypass) {
      _testingTransactions[transaction.id] = transaction;
      return;
    }

    await _transactionsCollection.doc(transaction.id).set(
          transaction.toMap(),
          SetOptions(merge: true),
        );
  }

  Future<void> createTransaction(
    RewardTransactionModel transaction,
  ) async {
    if (!RewardProductionGate.financialMutationsEnabled) {
      throw StateError(
        'Reward transaction mutations are disabled until the trusted backend is ready.',
      );
    }

    _validateTransaction(transaction);

    if (useTestingBypass) {
      if (_testingTransactions.containsKey(transaction.id)) {
        throw StateError(
          'Reward transaction already exists.',
        );
      }

      if (transaction.idempotencyKey != null &&
          _hasTestingIdempotencyKey(
            transaction.idempotencyKey!,
          )) {
        throw StateError(
          'Reward transaction was already processed.',
        );
      }

      _testingTransactions[transaction.id] = transaction;
      return;
    }

    final reference =
        _transactionsCollection.doc(transaction.id);

    final existing = await reference.get();

    if (existing.exists) {
      throw StateError(
        'Reward transaction already exists.',
      );
    }

    if (transaction.idempotencyKey != null &&
        transaction.idempotencyKey!.trim().isNotEmpty) {
      final duplicate = await _transactionsCollection
          .where(
            'idempotencyKey',
            isEqualTo: transaction.idempotencyKey,
          )
          .limit(1)
          .get();

      if (duplicate.docs.isNotEmpty) {
        throw StateError(
          'Reward transaction was already processed.',
        );
      }
    }

    await reference.set(transaction.toMap());
  }

  Future<RewardTransactionModel?> getTransactionById(
    String transactionId,
  ) async {
    if (useTestingBypass) {
      return _testingTransactions[transactionId];
    }

    final document =
        await _transactionsCollection.doc(transactionId).get();

    if (!document.exists || document.data() == null) {
      return null;
    }

    final data = Map<String, dynamic>.from(document.data()!);
    data['id'] = data['id']?.toString().isNotEmpty == true
        ? data['id']
        : document.id;

    return RewardTransactionModel.fromMap(data);
  }

  Future<RewardTransactionModel?>
      getTransactionByIdempotencyKey(
    String idempotencyKey,
  ) async {
    if (idempotencyKey.trim().isEmpty) {
      return null;
    }

    if (useTestingBypass) {
      for (final transaction
          in _testingTransactions.values) {
        if (transaction.idempotencyKey == idempotencyKey) {
          return transaction;
        }
      }

      return null;
    }

    final query = await _transactionsCollection
        .where(
          'idempotencyKey',
          isEqualTo: idempotencyKey,
        )
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      return null;
    }

    return RewardTransactionModel.fromMap(
      query.docs.first.data(),
    );
  }

  void _validateTransaction(
    RewardTransactionModel transaction,
  ) {
    if (transaction.id.trim().isEmpty) {
      throw ArgumentError(
        'Reward transaction ID cannot be empty.',
      );
    }

    if (transaction.userId.trim().isEmpty) {
      throw ArgumentError('User ID cannot be empty.');
    }

    if (transaction.title.trim().isEmpty) {
      throw ArgumentError(
        'Transaction title cannot be empty.',
      );
    }

    if (transaction.balanceBefore < 0 ||
        transaction.balanceAfter < 0) {
      throw ArgumentError(
        'Reward wallet balance cannot be negative.',
      );
    }
  }

  bool _hasTestingIdempotencyKey(String key) {
    return _testingTransactions.values.any(
      (transaction) => transaction.idempotencyKey == key,
    );
  }

  // =============================================================
  // USER HISTORY
  // =============================================================

  Future<List<RewardTransactionModel>> getUserHistory({
    required String userId,
    RewardModule? module,
    RewardTransactionType? type,
    RewardTransactionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    bool includeExpired = true,
    int? limit,
  }) async {
    final filter = RewardHistoryFilter(
      userId: userId,
      module: module,
      type: type,
      status: status,
      startDate: startDate,
      endDate: endDate,
    );

    var transactions = await getFilteredHistory(filter);

    if (!includeExpired) {
      transactions = transactions
          .where((transaction) => !transaction.isExpired)
          .toList();
    }

    if (limit != null &&
        limit > 0 &&
        transactions.length > limit) {
      return transactions.take(limit).toList();
    }

    return transactions;
  }

  Stream<List<RewardTransactionModel>> watchUserHistory({
    required String userId,
    RewardModule? module,
    RewardTransactionType? type,
    RewardTransactionStatus? status,
  }) {
    if (useTestingBypass) {
      var transactions = _testingTransactions.values
          .where(
            (transaction) => transaction.userId == userId,
          )
          .toList();

      transactions = _applyFilter(
        transactions,
        RewardHistoryFilter(
          userId: userId,
          module: module,
          type: type,
          status: status,
        ),
      );

      return Stream<List<RewardTransactionModel>>.value(
        transactions,
      );
    }

    return _transactionsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((query) {
      final transactions = query.docs.map((document) {
        final data =
            Map<String, dynamic>.from(document.data());

        data['id'] =
            data['id']?.toString().isNotEmpty == true
                ? data['id']
                : document.id;

        return RewardTransactionModel.fromMap(data);
      }).toList();

      return _applyFilter(
        transactions,
        RewardHistoryFilter(
          userId: userId,
          module: module,
          type: type,
          status: status,
        ),
      );
    });
  }

  // =============================================================
  // ADMIN GLOBAL HISTORY
  // =============================================================

  Future<List<RewardTransactionModel>>
      getFilteredHistory(
    RewardHistoryFilter filter,
  ) async {
    final allTransactions =
        await _loadAllTransactions(filter.userId);

    return _applyFilter(allTransactions, filter);
  }

  Future<RewardHistoryPage> getHistoryPage({
    required RewardHistoryFilter filter,
    int offset = 0,
    int pageSize = 20,
  }) async {
    if (offset < 0) {
      offset = 0;
    }

    if (pageSize <= 0) {
      pageSize = 20;
    }

    final matching = await getFilteredHistory(filter);
    final total = matching.length;

    if (offset >= total) {
      return RewardHistoryPage(
        transactions: const [],
        nextOffset: null,
        hasMore: false,
        totalMatchingRecords: total,
      );
    }

    final end = (offset + pageSize) > total
        ? total
        : offset + pageSize;

    final page = matching.sublist(offset, end);
    final hasMore = end < total;

    return RewardHistoryPage(
      transactions: page,
      nextOffset: hasMore ? end : null,
      hasMore: hasMore,
      totalMatchingRecords: total,
    );
  }

  Future<List<RewardTransactionModel>>
      _loadAllTransactions(
    String? userId,
  ) async {
    if (useTestingBypass) {
      return _testingTransactions.values.toList();
    }

    Query<Map<String, dynamic>> query =
        _transactionsCollection;

    if (userId != null && userId.trim().isNotEmpty) {
      query = query.where(
        'userId',
        isEqualTo: userId,
      );
    }

    final snapshot = await query.get();

    return snapshot.docs.map((document) {
      final data =
          Map<String, dynamic>.from(document.data());

      data['id'] =
          data['id']?.toString().isNotEmpty == true
              ? data['id']
              : document.id;

      return RewardTransactionModel.fromMap(data);
    }).toList();
  }

  List<RewardTransactionModel> _applyFilter(
    List<RewardTransactionModel> source,
    RewardHistoryFilter filter,
  ) {
    final search = filter.searchText.trim().toLowerCase();

    final filtered = source.where((transaction) {
      if (filter.userId != null &&
          filter.userId!.trim().isNotEmpty &&
          transaction.userId != filter.userId) {
        return false;
      }

      if (filter.module != null &&
          filter.module != RewardModule.all &&
          transaction.module != filter.module) {
        return false;
      }

      if (filter.type != null &&
          transaction.type != filter.type) {
        return false;
      }

      if (filter.status != null &&
          transaction.status != filter.status) {
        return false;
      }

      if (filter.creditOnly == true &&
          !transaction.isCredit) {
        return false;
      }

      if (filter.debitOnly == true &&
          !transaction.isDebit) {
        return false;
      }

      if (filter.startDate != null &&
          transaction.createdAt.isBefore(
            filter.startDate!,
          )) {
        return false;
      }

      if (filter.endDate != null &&
          transaction.createdAt.isAfter(
            filter.endDate!,
          )) {
        return false;
      }

      if (search.isNotEmpty) {
        final searchableText = [
          transaction.id,
          transaction.userId,
          transaction.title,
          transaction.description,
          transaction.sourceId ?? '',
          transaction.rewardRuleId ?? '',
          transaction.idempotencyKey ?? '',
          transaction.type.name,
          transaction.status.name,
          transaction.module.name,
        ].join(' ').toLowerCase();

        if (!searchableText.contains(search)) {
          return false;
        }
      }

      return true;
    }).toList();

    filtered.sort(
      (first, second) =>
          second.createdAt.compareTo(first.createdAt),
    );

    return filtered;
  }

  // =============================================================
  // SUMMARIES AND ADMIN REPORTS
  // =============================================================

  Future<RewardHistorySummary> getHistorySummary({
    RewardHistoryFilter filter =
        const RewardHistoryFilter(),
  }) async {
    final transactions = await getFilteredHistory(filter);

    if (transactions.isEmpty) {
      return RewardHistorySummary.empty();
    }

    var totalEarnedPoints = 0;
    var totalRedeemedPoints = 0;
    var totalExpiredPoints = 0;
    var totalReversedPoints = 0;

    var totalCreditPoints = 0;
    var totalDebitPoints = 0;

    var pendingTransactions = 0;
    var completedTransactions = 0;
    var failedTransactions = 0;

    final pointsByModule = <RewardModule, int>{};
    final pointsByType = <RewardTransactionType, int>{};

    for (final transaction in transactions) {
      final absolutePoints = transaction.points.abs();

      if (transaction.isCredit) {
        totalCreditPoints += transaction.points;
      }

      if (transaction.isDebit) {
        totalDebitPoints += absolutePoints;
      }

      switch (transaction.type) {
        case RewardTransactionType.earned:
        case RewardTransactionType.signupBonus:
        case RewardTransactionType.firstBookingBonus:
        case RewardTransactionType.referralBonus:
        case RewardTransactionType.campaignBonus:
        case RewardTransactionType.manualCredit:
          totalEarnedPoints += absolutePoints;
          break;

        case RewardTransactionType.redeemed:
        case RewardTransactionType.manualDebit:
          totalRedeemedPoints += absolutePoints;
          break;

        case RewardTransactionType.expired:
          totalExpiredPoints += absolutePoints;
          break;

        case RewardTransactionType.reversed:
        case RewardTransactionType.refundAdjustment:
          totalReversedPoints += absolutePoints;
          break;
      }

      switch (transaction.status) {
        case RewardTransactionStatus.pending:
          pendingTransactions++;
          break;

        case RewardTransactionStatus.completed:
          completedTransactions++;
          break;

        case RewardTransactionStatus.failed:
          failedTransactions++;
          break;

        case RewardTransactionStatus.cancelled:
        case RewardTransactionStatus.reversed:
        case RewardTransactionStatus.expired:
          break;
      }

      pointsByModule[transaction.module] =
          (pointsByModule[transaction.module] ?? 0) +
              transaction.points;

      pointsByType[transaction.type] =
          (pointsByType[transaction.type] ?? 0) +
              transaction.points;
    }

    return RewardHistorySummary(
      totalRecords: transactions.length,
      totalEarnedPoints: totalEarnedPoints,
      totalRedeemedPoints: totalRedeemedPoints,
      totalExpiredPoints: totalExpiredPoints,
      totalReversedPoints: totalReversedPoints,
      totalCreditPoints: totalCreditPoints,
      totalDebitPoints: totalDebitPoints,
      pendingTransactions: pendingTransactions,
      completedTransactions: completedTransactions,
      failedTransactions: failedTransactions,
      pointsByModule: pointsByModule,
      pointsByType: pointsByType,
    );
  }

  Future<Map<String, dynamic>> generateAdminReport({
    DateTime? startDate,
    DateTime? endDate,
    RewardModule? module,
  }) async {
    final filter = RewardHistoryFilter(
      module: module,
      startDate: startDate,
      endDate: endDate,
    );

    final transactions = await getFilteredHistory(filter);
    final summary = await getHistorySummary(filter: filter);

    final uniqueUsers = transactions
        .map((transaction) => transaction.userId)
        .toSet()
        .length;

    return {
      'generatedAt': DateTime.now().millisecondsSinceEpoch,
      'startDate': startDate?.millisecondsSinceEpoch,
      'endDate': endDate?.millisecondsSinceEpoch,
      'module': module?.name,
      'uniqueUsers': uniqueUsers,
      'totalRecords': summary.totalRecords,
      'totalEarnedPoints': summary.totalEarnedPoints,
      'totalRedeemedPoints': summary.totalRedeemedPoints,
      'totalExpiredPoints': summary.totalExpiredPoints,
      'totalReversedPoints': summary.totalReversedPoints,
      'totalCreditPoints': summary.totalCreditPoints,
      'totalDebitPoints': summary.totalDebitPoints,
      'pendingTransactions': summary.pendingTransactions,
      'completedTransactions':
          summary.completedTransactions,
      'failedTransactions': summary.failedTransactions,
      'pointsByModule': summary.pointsByModule.map(
        (key, value) => MapEntry(key.name, value),
      ),
      'pointsByType': summary.pointsByType.map(
        (key, value) => MapEntry(key.name, value),
      ),
    };
  }

  // =============================================================
  // EXPORT HELPERS
  // =============================================================

  Future<List<Map<String, dynamic>>> exportHistory({
    RewardHistoryFilter filter =
        const RewardHistoryFilter(),
  }) async {
    final transactions = await getFilteredHistory(filter);

    return transactions.map((transaction) {
      return {
        'transactionId': transaction.id,
        'userId': transaction.userId,
        'module': transaction.module.name,
        'type': transaction.type.name,
        'status': transaction.status.name,
        'points': transaction.points,
        'balanceBefore': transaction.balanceBefore,
        'balanceAfter': transaction.balanceAfter,
        'sourceId': transaction.sourceId,
        'rewardRuleId': transaction.rewardRuleId,
        'title': transaction.title,
        'description': transaction.description,
        'createdAt': transaction.createdAt.toIso8601String(),
        'completedAt':
            transaction.completedAt?.toIso8601String(),
        'expiresAt':
            transaction.expiresAt?.toIso8601String(),
        'reversedTransactionId':
            transaction.reversedTransactionId,
        'idempotencyKey': transaction.idempotencyKey,
      };
    }).toList();
  }

  // =============================================================
  // TESTING HELPERS
  // =============================================================

  void addTestingTransaction(
    RewardTransactionModel transaction,
  ) {
    _testingTransactions[transaction.id] = transaction;
  }

  void clearTestingData() {
    _testingTransactions.clear();
  }
}
