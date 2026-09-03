// =============================================================
// SWAT RIDE - GLOBAL LOYALTY, REWARDS & PROMO ENGINE
// File: lib/rewards/services/reward_expiry_service.dart
//
// Global reward-points expiry service.
//
// Supports:
// - Never expiry
// - Admin-defined custom days: 30, 90, 180, 365 or any value
// - FIFO expiry calculation
// - Expiring-points preview
// - Reminder candidates
// - Wallet deduction
// - Expiry transaction history
// - Duplicate expiry protection
// - Batch Admin processing
// - Real Firestore and testing bypass
//
// IMPORTANT:
// This service only expires reward points.
// It never expires cash/payment-wallet money.
// =============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/reward_point_model.dart';
import '../models/reward_settings_model.dart';
import '../config/reward_production_gate.dart';
import '../models/reward_transaction_model.dart';
import '../models/reward_wallet_model.dart';

class RewardExpiryPreview {
  final String userId;
  final int currentAvailablePoints;
  final int expiredPoints;
  final int expiringSoonPoints;

  final DateTime? nearestExpiryDate;

  final Map<String, int> expiredPointsByModule;
  final Map<String, int> expiringSoonPointsByModule;

  final List<String> expiredSourceTransactionIds;
  final List<String> expiringSourceTransactionIds;

  const RewardExpiryPreview({
    required this.userId,
    required this.currentAvailablePoints,
    required this.expiredPoints,
    required this.expiringSoonPoints,
    this.nearestExpiryDate,
    this.expiredPointsByModule = const {},
    this.expiringSoonPointsByModule = const {},
    this.expiredSourceTransactionIds = const [],
    this.expiringSourceTransactionIds = const [],
  });

  bool get hasExpiredPoints => expiredPoints > 0;

  bool get hasExpiringSoonPoints => expiringSoonPoints > 0;
}

class RewardExpiryResult {
  final bool success;
  final String message;

  final String userId;
  final int expiredPoints;

  final int balanceBefore;
  final int balanceAfter;

  final String? expiryTransactionId;
  final bool duplicate;
  final bool skipped;

  const RewardExpiryResult({
    required this.success,
    required this.message,
    required this.userId,
    this.expiredPoints = 0,
    this.balanceBefore = 0,
    this.balanceAfter = 0,
    this.expiryTransactionId,
    this.duplicate = false,
    this.skipped = false,
  });

  factory RewardExpiryResult.failed({
    required String userId,
    required String message,
  }) {
    return RewardExpiryResult(
      success: false,
      message: message,
      userId: userId,
    );
  }

  factory RewardExpiryResult.skipped({
    required String userId,
    required String message,
    int balance = 0,
  }) {
    return RewardExpiryResult(
      success: true,
      message: message,
      userId: userId,
      balanceBefore: balance,
      balanceAfter: balance,
      skipped: true,
    );
  }
}

class RewardExpiryBatchResult {
  final int checkedWallets;
  final int processedWallets;
  final int skippedWallets;
  final int failedWallets;
  final int totalExpiredPoints;

  final List<RewardExpiryResult> results;

  const RewardExpiryBatchResult({
    required this.checkedWallets,
    required this.processedWallets,
    required this.skippedWallets,
    required this.failedWallets,
    required this.totalExpiredPoints,
    required this.results,
  });
}

class _RewardPointLot {
  final RewardTransactionModel transaction;
  int remainingPoints;

  _RewardPointLot({
    required this.transaction,
    required this.remainingPoints,
  });
}

class _ExpiryAllocation {
  final String sourceTransactionId;
  final RewardModule module;
  final DateTime expiryDate;
  final int points;

  const _ExpiryAllocation({
    required this.sourceTransactionId,
    required this.module,
    required this.expiryDate,
    required this.points,
  });
}

class RewardExpiryService {
  final FirebaseFirestore _firestore;

  /// Keep true during local/testing development.
  ///
  /// Set false when real Firebase processing is required.
  final bool useTestingBypass;

  RewardSettingsModel? _testingSettings;

  final Map<String, RewardWalletModel> _testingWallets = {};
  final Map<String, RewardTransactionModel>
      _testingTransactions = {};
  final Set<String> _testingProcessedExpiryKeys = {};

  RewardExpiryService({
    FirebaseFirestore? firestore,
    this.useTestingBypass = false,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _walletsCollection {
    return _firestore.collection('reward_wallets');
  }

  CollectionReference<Map<String, dynamic>>
      get _transactionsCollection {
    return _firestore.collection('reward_transactions');
  }

  CollectionReference<Map<String, dynamic>>
      get _expiryRunsCollection {
    return _firestore.collection('reward_expiry_runs');
  }

  DocumentReference<Map<String, dynamic>> get _settingsDocument {
    return _firestore
        .collection('reward_settings')
        .doc('global_rewards');
  }

  // =============================================================
  // ADMIN EXPIRY SETTINGS
  // =============================================================

  Future<RewardSettingsModel?> getRewardSettings() async {
    if (useTestingBypass) {
      return _testingSettings;
    }

    final document = await _settingsDocument.get();

    if (!document.exists || document.data() == null) {
      return null;
    }

    return RewardSettingsModel.fromMap(document.data()!);
  }

  Future<void> updateExpiryPolicy({
    required RewardExpiryPolicy policy,
    int? customDays,
    required int reminderDays,
    required String updatedBy,
  }) async {
    if (reminderDays < 0) {
      throw ArgumentError(
        'Expiry reminder days cannot be negative.',
      );
    }

    if (policy == RewardExpiryPolicy.customDays &&
        (customDays == null || customDays <= 0)) {
      throw ArgumentError(
        'Custom expiry days must be greater than zero.',
      );
    }

    final now = DateTime.now();

    if (useTestingBypass) {
      final current = _testingSettings;

      if (current == null) {
        _testingSettings = RewardSettingsModel(
          id: 'global_rewards',
          rewardsEnabled: true,
          moduleRewardEnabled: const {'all': true},
          expiryPolicy: policy,
          rewardExpiryDays: policy ==
                  RewardExpiryPolicy.customDays
              ? customDays
              : null,
          expiryReminderDays: reminderDays,
          updatedBy: updatedBy,
          createdAt: now,
          updatedAt: now,
          version: 1,
        );

        return;
      }

      final map = current.toMap();

      map['expiryPolicy'] = policy.name;
      map['rewardExpiryDays'] =
          policy == RewardExpiryPolicy.customDays
              ? customDays
              : null;
      map['expiryReminderDays'] = reminderDays;
      map['updatedBy'] = updatedBy;
      map['updatedAt'] = now.millisecondsSinceEpoch;
      map['version'] = current.version + 1;

      _testingSettings = RewardSettingsModel.fromMap(map);
      return;
    }

    await _settingsDocument.set({
      'id': 'global_rewards',
      'expiryPolicy': policy.name,
      'rewardExpiryDays':
          policy == RewardExpiryPolicy.customDays
              ? customDays
              : null,
      'expiryReminderDays': reminderDays,
      'updatedBy': updatedBy,
      'updatedAt': now.millisecondsSinceEpoch,
      'version': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  Future<void> setNeverExpire({
    required String updatedBy,
  }) async {
    await updateExpiryPolicy(
      policy: RewardExpiryPolicy.never,
      reminderDays: 7,
      updatedBy: updatedBy,
    );
  }

  Future<void> setThirtyDayExpiry({
    required String updatedBy,
    int reminderDays = 7,
  }) async {
    await updateExpiryPolicy(
      policy: RewardExpiryPolicy.customDays,
      customDays: 30,
      reminderDays: reminderDays,
      updatedBy: updatedBy,
    );
  }

  Future<void> setNinetyDayExpiry({
    required String updatedBy,
    int reminderDays = 7,
  }) async {
    await updateExpiryPolicy(
      policy: RewardExpiryPolicy.customDays,
      customDays: 90,
      reminderDays: reminderDays,
      updatedBy: updatedBy,
    );
  }

  Future<void> setOneHundredEightyDayExpiry({
    required String updatedBy,
    int reminderDays = 7,
  }) async {
    await updateExpiryPolicy(
      policy: RewardExpiryPolicy.customDays,
      customDays: 180,
      reminderDays: reminderDays,
      updatedBy: updatedBy,
    );
  }

  Future<void> setOneYearExpiry({
    required String updatedBy,
    int reminderDays = 7,
  }) async {
    await updateExpiryPolicy(
      policy: RewardExpiryPolicy.customDays,
      customDays: 365,
      reminderDays: reminderDays,
      updatedBy: updatedBy,
    );
  }

  // =============================================================
  // WALLET AND TRANSACTION FETCHING
  // =============================================================

  Future<RewardWalletModel?> getWallet(
    String userId,
  ) async {
    if (useTestingBypass) {
      return _testingWallets[userId];
    }

    final document = await _walletsCollection.doc(userId).get();

    if (!document.exists || document.data() == null) {
      return null;
    }

    return RewardWalletModel.fromMap(document.data()!);
  }

  Future<List<RewardTransactionModel>>
      getUserTransactions(
    String userId,
  ) async {
    if (useTestingBypass) {
      final transactions = _testingTransactions.values
          .where(
            (transaction) => transaction.userId == userId,
          )
          .toList();

      transactions.sort(
        (first, second) =>
            first.createdAt.compareTo(second.createdAt),
      );

      return transactions;
    }

    final query = await _transactionsCollection
        .where('userId', isEqualTo: userId)
        .get();

    final transactions = query.docs.map((document) {
      final data =
          Map<String, dynamic>.from(document.data());

      data['id'] =
          data['id']?.toString().isNotEmpty == true
              ? data['id']
              : document.id;

      return RewardTransactionModel.fromMap(data);
    }).toList();

    transactions.sort(
      (first, second) =>
          first.createdAt.compareTo(second.createdAt),
    );

    return transactions;
  }

  // =============================================================
  // FIFO POINT-LOT CALCULATION
  // =============================================================

  List<_RewardPointLot> _calculateOutstandingLots(
    List<RewardTransactionModel> transactions,
  ) {
    final sorted = List<RewardTransactionModel>.from(
      transactions,
    )..sort(
        (first, second) =>
            first.createdAt.compareTo(second.createdAt),
      );

    final lots = <_RewardPointLot>[];

    for (final transaction in sorted) {
      if (transaction.status !=
          RewardTransactionStatus.completed) {
        continue;
      }

      if (transaction.points > 0) {
        lots.add(
          _RewardPointLot(
            transaction: transaction,
            remainingPoints: transaction.points,
          ),
        );

        continue;
      }

      if (transaction.points >= 0) {
        continue;
      }

      var debitToAllocate = transaction.points.abs();

      for (final lot in lots) {
        if (debitToAllocate <= 0) {
          break;
        }

        if (lot.remainingPoints <= 0) {
          continue;
        }

        final consumed =
            debitToAllocate < lot.remainingPoints
                ? debitToAllocate
                : lot.remainingPoints;

        lot.remainingPoints -= consumed;
        debitToAllocate -= consumed;
      }
    }

    return lots
        .where((lot) => lot.remainingPoints > 0)
        .toList();
  }

  List<_ExpiryAllocation> _calculateExpiredAllocations({
    required List<RewardTransactionModel> transactions,
    required DateTime now,
    required int maximumPoints,
  }) {
    if (maximumPoints <= 0) {
      return [];
    }

    final lots = _calculateOutstandingLots(transactions);
    final allocations = <_ExpiryAllocation>[];

    var remainingAllowed = maximumPoints;

    for (final lot in lots) {
      if (remainingAllowed <= 0) {
        break;
      }

      final expiryDate = lot.transaction.expiresAt;

      if (expiryDate == null || expiryDate.isAfter(now)) {
        continue;
      }

      final points = lot.remainingPoints < remainingAllowed
          ? lot.remainingPoints
          : remainingAllowed;

      if (points <= 0) {
        continue;
      }

      allocations.add(
        _ExpiryAllocation(
          sourceTransactionId: lot.transaction.id,
          module: lot.transaction.module,
          expiryDate: expiryDate,
          points: points,
        ),
      );

      remainingAllowed -= points;
    }

    return allocations;
  }

  // =============================================================
  // EXPIRY PREVIEW
  // =============================================================

  Future<RewardExpiryPreview> getExpiryPreview({
    required String userId,
    DateTime? currentDate,
    int? reminderDays,
  }) async {
    final wallet = await getWallet(userId);

    if (wallet == null) {
      return RewardExpiryPreview(
        userId: userId,
        currentAvailablePoints: 0,
        expiredPoints: 0,
        expiringSoonPoints: 0,
      );
    }

    final settings = await getRewardSettings();

    if (settings == null ||
        settings.expiryPolicy == RewardExpiryPolicy.never) {
      return RewardExpiryPreview(
        userId: userId,
        currentAvailablePoints: wallet.availablePoints,
        expiredPoints: 0,
        expiringSoonPoints: 0,
      );
    }

    final now = currentDate ?? DateTime.now();
    final reminderWindow = reminderDays ??
        settings.expiryReminderDays;

    final reminderEnd =
        now.add(Duration(days: reminderWindow));

    final transactions = await getUserTransactions(userId);
    final lots = _calculateOutstandingLots(transactions);

    var expiredPoints = 0;
    var expiringSoonPoints = 0;

    DateTime? nearestExpiryDate;

    final expiredByModule = <String, int>{};
    final expiringByModule = <String, int>{};

    final expiredSources = <String>[];
    final expiringSources = <String>[];

    for (final lot in lots) {
      final expiryDate = lot.transaction.expiresAt;

      if (expiryDate == null || lot.remainingPoints <= 0) {
        continue;
      }

      final moduleName = lot.transaction.module.name;

      if (!expiryDate.isAfter(now)) {
        expiredPoints += lot.remainingPoints;

        expiredByModule[moduleName] =
            (expiredByModule[moduleName] ?? 0) +
                lot.remainingPoints;

        expiredSources.add(lot.transaction.id);
        continue;
      }

      if (!expiryDate.isAfter(reminderEnd)) {
        expiringSoonPoints += lot.remainingPoints;

        expiringByModule[moduleName] =
            (expiringByModule[moduleName] ?? 0) +
                lot.remainingPoints;

        expiringSources.add(lot.transaction.id);

        if (nearestExpiryDate == null ||
            expiryDate.isBefore(nearestExpiryDate)) {
          nearestExpiryDate = expiryDate;
        }
      }
    }

    if (expiredPoints > wallet.availablePoints) {
      expiredPoints = wallet.availablePoints;
    }

    final remainingAfterExpired =
        wallet.availablePoints - expiredPoints;

    if (expiringSoonPoints > remainingAfterExpired) {
      expiringSoonPoints = remainingAfterExpired;
    }

    return RewardExpiryPreview(
      userId: userId,
      currentAvailablePoints: wallet.availablePoints,
      expiredPoints: expiredPoints,
      expiringSoonPoints: expiringSoonPoints,
      nearestExpiryDate: nearestExpiryDate,
      expiredPointsByModule: expiredByModule,
      expiringSoonPointsByModule: expiringByModule,
      expiredSourceTransactionIds: expiredSources,
      expiringSourceTransactionIds: expiringSources,
    );
  }

  Future<List<RewardExpiryPreview>>
      getExpiryReminderCandidates({
    DateTime? currentDate,
  }) async {
    final settings = await getRewardSettings();

    if (settings == null ||
        settings.expiryPolicy == RewardExpiryPolicy.never ||
        !settings.expiryNotificationsEnabled) {
      return [];
    }

    final wallets = await _getAllWallets();
    final candidates = <RewardExpiryPreview>[];

    for (final wallet in wallets) {
      final preview = await getExpiryPreview(
        userId: wallet.userId,
        currentDate: currentDate,
        reminderDays: settings.expiryReminderDays,
      );

      if (preview.hasExpiringSoonPoints) {
        candidates.add(preview);
      }
    }

    candidates.sort((first, second) {
      final firstDate = first.nearestExpiryDate;
      final secondDate = second.nearestExpiryDate;

      if (firstDate == null && secondDate == null) {
        return 0;
      }

      if (firstDate == null) {
        return 1;
      }

      if (secondDate == null) {
        return -1;
      }

      return firstDate.compareTo(secondDate);
    });

    return candidates;
  }

  // =============================================================
  // PROCESS USER EXPIRY
  // =============================================================

  Future<RewardExpiryResult> processUserExpiry({
    required String userId,
    DateTime? currentDate,
    String processedBy = 'system',
  }) async {
    if (!useTestingBypass &&
        !RewardProductionGate.financialMutationsEnabled) {
      return RewardExpiryResult.skipped(
        userId: userId,
        message:
            'Reward expiry financial mutations are disabled until the trusted backend is ready.',
      );
    }
    final settings = await getRewardSettings();

    if (settings == null) {
      return RewardExpiryResult.skipped(
        userId: userId,
        message: 'Reward settings not found.',
      );
    }

    if (settings.expiryPolicy == RewardExpiryPolicy.never) {
      final wallet = await getWallet(userId);

      return RewardExpiryResult.skipped(
        userId: userId,
        message: 'Reward points never expire.',
        balance: wallet?.availablePoints ?? 0,
      );
    }

    if (!settings.hasValidConfiguration) {
      return RewardExpiryResult.failed(
        userId: userId,
        message: 'Reward expiry settings are invalid.',
      );
    }

    final wallet = await getWallet(userId);

    if (wallet == null) {
      return RewardExpiryResult.skipped(
        userId: userId,
        message: 'Reward wallet not found.',
      );
    }

    if (!wallet.isActive) {
      return RewardExpiryResult.skipped(
        userId: userId,
        message: 'Reward wallet is inactive.',
        balance: wallet.availablePoints,
      );
    }

    if (wallet.isFrozen) {
      return RewardExpiryResult.skipped(
        userId: userId,
        message: 'Reward wallet is frozen.',
        balance: wallet.availablePoints,
      );
    }

    if (wallet.availablePoints <= 0) {
      return RewardExpiryResult.skipped(
        userId: userId,
        message: 'No available reward points.',
        balance: wallet.availablePoints,
      );
    }

    final now = currentDate ?? DateTime.now();
    final transactions = await getUserTransactions(userId);

    final allocations = _calculateExpiredAllocations(
      transactions: transactions,
      now: now,
      maximumPoints: wallet.availablePoints,
    );

    if (allocations.isEmpty) {
      return RewardExpiryResult.skipped(
        userId: userId,
        message: 'No reward points are due for expiry.',
        balance: wallet.availablePoints,
      );
    }

    final totalExpiredPoints = allocations.fold<int>(
      0,
      (total, allocation) => total + allocation.points,
    );

    if (totalExpiredPoints <= 0) {
      return RewardExpiryResult.skipped(
        userId: userId,
        message: 'No reward points are due for expiry.',
        balance: wallet.availablePoints,
      );
    }

    final expiryKey = _buildExpiryKey(
      userId: userId,
      allocations: allocations,
    );

    final transactionId =
        'reward_expiry_${_stableHash(expiryKey)}';

    if (useTestingBypass) {
      if (_testingProcessedExpiryKeys.contains(expiryKey)) {
        return RewardExpiryResult(
          success: true,
          message: 'Reward expiry was already processed.',
          userId: userId,
          balanceBefore: wallet.availablePoints,
          balanceAfter: wallet.availablePoints,
          expiryTransactionId: transactionId,
          duplicate: true,
        );
      }

      final pointsToExpire =
          totalExpiredPoints > wallet.availablePoints
              ? wallet.availablePoints
              : totalExpiredPoints;

      final updatedModulePoints = _deductModulePoints(
        currentModulePoints: wallet.modulePoints,
        allocations: allocations,
        maximumDeduction: pointsToExpire,
      );

      final updatedWallet = wallet.copyWith(
        availablePoints:
            wallet.availablePoints - pointsToExpire,
        lifetimeExpiredPoints:
            wallet.lifetimeExpiredPoints + pointsToExpire,
        modulePoints: updatedModulePoints,
        version: wallet.version + 1,
        updatedAt: now,
      );

      final expiryTransaction = RewardTransactionModel(
        id: transactionId,
        userId: userId,
        module: RewardModule.all,
        type: RewardTransactionType.expired,
        status: RewardTransactionStatus.completed,
        points: -pointsToExpire,
        balanceBefore: wallet.availablePoints,
        balanceAfter: updatedWallet.availablePoints,
        sourceId: allocations
            .map(
              (allocation) =>
                  allocation.sourceTransactionId,
            )
            .join(','),
        title: 'Reward points expired',
        description:
            '$pointsToExpire reward points expired according '
            'to the Admin expiry policy.',
        createdAt: now,
        completedAt: now,
        idempotencyKey: expiryKey,
        metadata: {
          'processedBy': processedBy,
          'expiryPolicy': settings.expiryPolicy.name,
          'rewardExpiryDays': settings.rewardExpiryDays,
          'sourceAllocations':
              _allocationsToMap(allocations),
        },
      );

      _testingWallets[userId] = updatedWallet;
      _testingTransactions[transactionId] =
          expiryTransaction;
      _testingProcessedExpiryKeys.add(expiryKey);

      return RewardExpiryResult(
        success: true,
        message: '$pointsToExpire reward points expired.',
        userId: userId,
        expiredPoints: pointsToExpire,
        balanceBefore: wallet.availablePoints,
        balanceAfter: updatedWallet.availablePoints,
        expiryTransactionId: transactionId,
      );
    }

    final walletReference = _walletsCollection.doc(userId);
    final transactionReference =
        _transactionsCollection.doc(transactionId);
    final expiryRunReference =
        _expiryRunsCollection.doc(transactionId);

    try {
      var duplicate = false;
      var processedPoints = 0;
      var balanceBefore = wallet.availablePoints;
      var balanceAfter = wallet.availablePoints;

      await _firestore.runTransaction((transaction) async {
        final runDocument =
            await transaction.get(expiryRunReference);

        if (runDocument.exists) {
          duplicate = true;
          return;
        }

        final walletDocument =
            await transaction.get(walletReference);

        if (!walletDocument.exists ||
            walletDocument.data() == null) {
          throw StateError('Reward wallet not found.');
        }

        final latestWallet = RewardWalletModel.fromMap(
          walletDocument.data()!,
        );

        if (!latestWallet.isActive ||
            latestWallet.isFrozen) {
          throw StateError(
            'Reward wallet is inactive or frozen.',
          );
        }

        balanceBefore = latestWallet.availablePoints;

        processedPoints =
            totalExpiredPoints > latestWallet.availablePoints
                ? latestWallet.availablePoints
                : totalExpiredPoints;

        if (processedPoints <= 0) {
          throw StateError(
            'No available points can be expired.',
          );
        }

        balanceAfter =
            latestWallet.availablePoints - processedPoints;

        if (settings.preventNegativeRewardBalance &&
            balanceAfter < 0) {
          throw StateError(
            'Reward wallet cannot have a negative balance.',
          );
        }

        final updatedModulePoints = _deductModulePoints(
          currentModulePoints: latestWallet.modulePoints,
          allocations: allocations,
          maximumDeduction: processedPoints,
        );

        final updatedWallet = latestWallet.copyWith(
          availablePoints: balanceAfter,
          lifetimeExpiredPoints:
              latestWallet.lifetimeExpiredPoints +
                  processedPoints,
          modulePoints: updatedModulePoints,
          version: latestWallet.version + 1,
          updatedAt: now,
        );

        final expiryTransaction = RewardTransactionModel(
          id: transactionId,
          userId: userId,
          module: RewardModule.all,
          type: RewardTransactionType.expired,
          status: RewardTransactionStatus.completed,
          points: -processedPoints,
          balanceBefore: balanceBefore,
          balanceAfter: balanceAfter,
          sourceId: allocations
              .map(
                (allocation) =>
                    allocation.sourceTransactionId,
              )
              .join(','),
          title: 'Reward points expired',
          description:
              '$processedPoints reward points expired '
              'according to the Admin expiry policy.',
          createdAt: now,
          completedAt: now,
          idempotencyKey: expiryKey,
          metadata: {
            'processedBy': processedBy,
            'expiryPolicy': settings.expiryPolicy.name,
            'rewardExpiryDays': settings.rewardExpiryDays,
            'sourceAllocations':
                _allocationsToMap(allocations),
          },
        );

        transaction.update(
          walletReference,
          updatedWallet.toMap(),
        );

        transaction.set(
          transactionReference,
          expiryTransaction.toMap(),
        );

        transaction.set(expiryRunReference, {
          'id': transactionId,
          'userId': userId,
          'expiredPoints': processedPoints,
          'balanceBefore': balanceBefore,
          'balanceAfter': balanceAfter,
          'expiryKey': expiryKey,
          'processedBy': processedBy,
          'processedAt': now.millisecondsSinceEpoch,
          'sourceAllocations':
              _allocationsToMap(allocations),
        });
      });

      if (duplicate) {
        return RewardExpiryResult(
          success: true,
          message: 'Reward expiry was already processed.',
          userId: userId,
          balanceBefore: balanceBefore,
          balanceAfter: balanceAfter,
          expiryTransactionId: transactionId,
          duplicate: true,
        );
      }

      return RewardExpiryResult(
        success: true,
        message: '$processedPoints reward points expired.',
        userId: userId,
        expiredPoints: processedPoints,
        balanceBefore: balanceBefore,
        balanceAfter: balanceAfter,
        expiryTransactionId: transactionId,
      );
    } catch (error) {
      return RewardExpiryResult.failed(
        userId: userId,
        message:
            error.toString().replaceFirst('Bad state: ', ''),
      );
    }
  }

  // =============================================================
  // ADMIN BATCH EXPIRY PROCESSING
  // =============================================================

  Future<RewardExpiryBatchResult> processAllDueExpiries({
    DateTime? currentDate,
    String processedBy = 'system',
  }) async {
    final wallets = await _getAllWallets();
    final results = <RewardExpiryResult>[];

    var processedWallets = 0;
    var skippedWallets = 0;
    var failedWallets = 0;
    var totalExpiredPoints = 0;

    for (final wallet in wallets) {
      final result = await processUserExpiry(
        userId: wallet.userId,
        currentDate: currentDate,
        processedBy: processedBy,
      );

      results.add(result);

      if (!result.success) {
        failedWallets++;
        continue;
      }

      if (result.skipped || result.duplicate) {
        skippedWallets++;
        continue;
      }

      processedWallets++;
      totalExpiredPoints += result.expiredPoints;
    }

    return RewardExpiryBatchResult(
      checkedWallets: wallets.length,
      processedWallets: processedWallets,
      skippedWallets: skippedWallets,
      failedWallets: failedWallets,
      totalExpiredPoints: totalExpiredPoints,
      results: results,
    );
  }

  Future<List<RewardWalletModel>> _getAllWallets() async {
    if (useTestingBypass) {
      return _testingWallets.values.toList();
    }

    final query = await _walletsCollection.get();

    return query.docs
        .map(
          (document) =>
              RewardWalletModel.fromMap(document.data()),
        )
        .toList();
  }

  // =============================================================
  // INTERNAL HELPERS
  // =============================================================

  Map<String, int> _deductModulePoints({
    required Map<String, int> currentModulePoints,
    required List<_ExpiryAllocation> allocations,
    required int maximumDeduction,
  }) {
    final updated = Map<String, int>.from(
      currentModulePoints,
    );

    var remainingDeduction = maximumDeduction;

    for (final allocation in allocations) {
      if (remainingDeduction <= 0) {
        break;
      }

      final moduleName = allocation.module.name;

      final deduction =
          allocation.points < remainingDeduction
              ? allocation.points
              : remainingDeduction;

      final currentModuleBalance =
          updated[moduleName] ?? 0;

      final safeDeduction =
          deduction < currentModuleBalance
              ? deduction
              : currentModuleBalance;

      updated[moduleName] =
          currentModuleBalance - safeDeduction;

      remainingDeduction -= deduction;
    }

    return updated;
  }

  String _buildExpiryKey({
    required String userId,
    required List<_ExpiryAllocation> allocations,
  }) {
    final allocationText = allocations.map((allocation) {
      return '${allocation.sourceTransactionId}:'
          '${allocation.points}:'
          '${allocation.expiryDate.millisecondsSinceEpoch}';
    }).join('|');

    return 'reward-expiry:$userId:$allocationText';
  }

  int _stableHash(String value) {
    var hash = 2166136261;

    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 16777619) & 0x7fffffff;
    }

    return hash;
  }

  List<Map<String, dynamic>> _allocationsToMap(
    List<_ExpiryAllocation> allocations,
  ) {
    return allocations.map((allocation) {
      return {
        'sourceTransactionId':
            allocation.sourceTransactionId,
        'module': allocation.module.name,
        'expiryDate':
            allocation.expiryDate.millisecondsSinceEpoch,
        'points': allocation.points,
      };
    }).toList();
  }

  // =============================================================
  // TESTING HELPERS
  // =============================================================

  void setTestingSettings(
    RewardSettingsModel settings,
  ) {
    _testingSettings = settings;
  }

  void addTestingWallet(
    RewardWalletModel wallet,
  ) {
    _testingWallets[wallet.userId] = wallet;
  }

  void addTestingTransaction(
    RewardTransactionModel transaction,
  ) {
    _testingTransactions[transaction.id] = transaction;
  }

  void clearTestingData() {
    _testingSettings = null;
    _testingWallets.clear();
    _testingTransactions.clear();
    _testingProcessedExpiryKeys.clear();
  }
}